import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:safe_device/safe_device.dart';

import 'l10n/app_localizations.dart';
import 'models/server_config.dart';
import 'services/services.dart';
import 'services/audio_handler.dart';
import 'services/transcoding_service.dart';
import 'services/local_music_service.dart';
import 'services/analytics_service.dart';
import 'services/diagnostics/diagnostics.dart';
import 'services/favorite_playlists_service.dart';
import 'services/cover_cache_cleaner.dart';
import 'services/song_knowledge_cache.dart';
import 'widgets/glass_surface.dart';
import 'widgets/privacy_policy_dialog.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'screens/audiobook_detail_screen.dart' show audiobookRouteObserver;
import 'package:dynamic_color/dynamic_color.dart';
import 'theme/theme.dart';
import 'utils/image_cache.dart';

// Global instance for analytics (to be shown after auth)

/// 运行时上报的应用版本，写入诊断导出 meta.json；
/// 与 pubspec.yaml `version` 保持一致，发版时同步更新。
const String kAppVersion = '1.1.19+14';

/// Shows the privacy policy dialog on first launch
Future<void> _showPrivacyPolicyIfNeeded() async {
  if (await PrivacyPolicyDialog.shouldShow()) {
    // Small delay to ensure UI is fully loaded
    await Future.delayed(const Duration(milliseconds: 300));
    if (navigatorKey.currentContext != null) {
      final result = await showDialog<bool>(
        context: navigatorKey.currentContext!,
        builder: (context) => const PrivacyPolicyDialog(),
        barrierDismissible: false,
      );

      // If user declined, mark as accepted anyway to not show again
      // but we could handle this differently if needed
      if (result == false) {
        await PrivacyPolicyDialog.markAccepted();
      }
    }
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Checks if the app is running on an emulator/simulator
Future<bool> _isRunningOnEmulator() async {
  if (kDebugMode) return false;
  if (kIsWeb) return false;
  if (!Platform.isAndroid && !Platform.isIOS) return false;

  return !(await SafeDevice.isRealDevice);
}

/// Widget shown when app is running on emulator
class _EmulatorWarningScreen extends StatelessWidget {
  const _EmulatorWarningScreen();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.block_rounded,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      l10n.emulatorDetected,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.emulatorNotAllowed,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () {
                        // Exit the app
                        exit(0);
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: Text(l10n.exitApp),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() async {
  final startupSw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // ── 诊断系统：尽早初始化（runApp 前），保证启动早期日志不丢 ──
  final diag = DiagnosticsService.instance;
  diag.setAppVersion(kAppVersion); // 导出 meta 携带版本，否则恒为 unknown
  unawaited(diag.init());
  GlobalErrorHandler.install();
  GlobalErrorHandler.contextProvider = () => navigatorKey.currentContext;
  MetricsCollector.instance.start();
  MetricsCollector.milestone(
      'engineInitialized', startupSw.elapsedMilliseconds);

  // ── 流体背景包的事件 → 诊断系统 ──
  // 包本身不依赖任何日志系统，只抛结构化事件；在此接到 DiagnosticsService，
  // 这样 frame.jank / frame.slow 才能归属到实际渲染路径（流沙 / 回落）。
  FluidBackgroundEvents.onEvent = (event, payload) {
    DiagnosticsService.instance.record(
      EventType.animActive,
      LogLevel.info,
      {'anim': event, ...payload},
    );
  };

  // 进程退出前 flush 诊断缓冲（崩溃/被杀场景由 GlobalErrorHandler 兜底）
  AppLifecycleListener(onDetach: () => unawaited(diag.disposeAsync()));

  final isEmulator = await _isRunningOnEmulator();
  if (isEmulator) {
    runApp(const _EmulatorWarningScreen());
    return;
  }

  JustAudioMediaKit.ensureInitialized(linux: true, windows: false);

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions();
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  ImageCacheConfig.configure();

  // 封面磁盘缓存字节守护：启动时清理超限的最旧封面（512MB 阈值，见方案 P5）。
  unawaited(CoverCacheCleaner().prune());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final storageService = StorageService();
  final subsonicService = SubsonicService(storageService: storageService);
  final offlineService = OfflineService();
  final recommendationService = RecommendationService();
  final localMusicService = LocalMusicService();
  final castService = CastService();
  final localeService = LocaleService();
  final upnpService = UpnpService();
  final themeService = ThemeService();
  MetricsCollector.milestone('servicesCreated', startupSw.elapsedMilliseconds);

  BpmAnalyzerService().initialize().catchError((e) {
    debugPrint('Failed to initialize BPM analyzer: $e');
  });
  offlineService.initialize().catchError((e) {
    debugPrint('Failed to initialize offline service: $e');
  });
  recommendationService.initialize().catchError((e) {
    debugPrint('Failed to initialize recommendation service: $e');
  });

  // 新首页推荐编排服务（P3 图谱接入）：注入知识库缓存 + 跨天冷却记录，
  // 行为监听自动接线。
  final songKnowledgeCache = SongKnowledgeCache();
  songKnowledgeCache.initialize().catchError((e) {
    debugPrint('Failed to initialize song knowledge cache: $e');
  });
  // 每日推荐跨天冷却记录（`docs/每日推荐探索配额与冷却技术方案.md` §3.3）：
  // 需在首次生成 feed 前就绪，故 await（单次 prefs 读取）。
  final recommendedHistoryStore = RecommendedHistoryStore();
  await recommendedHistoryStore.initialize().catchError((e) {
    debugPrint('Failed to initialize recommended history store: $e');
  });
  final homeRecommendationService = HomeRecommendationService(
    behavior: recommendationService,
    knowledgeCache: songKnowledgeCache,
    history: recommendedHistoryStore,
  );

  // 播放来源追踪：最近播放的歌单/收藏列表（首页「最近播放」混合区）。
  final playbackContextTracker = PlaybackContextTracker();
  playbackContextTracker.initialize().catchError((e) {
    debugPrint('Failed to initialize playback context tracker: $e');
  });
  localMusicService.initialize().catchError((e) {
    debugPrint('Failed to initialize local music service: $e');
  });
  localeService.loadSavedLocale().catchError((e) {
    debugPrint('Failed to load saved locale: $e');
  });
  await themeService.initialize().catchError((e) {
    debugPrint('Failed to initialize theme service: $e');
  });

  // Initialize favorite playlists service
  FavoritePlaylistsService().initialize().catchError((e) {
    debugPrint('Failed to initialize favorite playlists service: $e');
  });

  // Initialize analytics service (privacy-first, anonymous)
  final analyticsService = AnalyticsService();
  analyticsService.initialize().catchError((e) {
    debugPrint('Failed to initialize analytics: $e');
  });

  // Analytics service is initialized and used via AnalyticsNavigatorObserver

  try {
    await PlayerUiSettingsService().initialize();
  } catch (e) {
    debugPrint('Failed to initialize player UI settings: $e');
  }

  // Initialise the audio service BEFORE runApp so the background audio engine
  // is ready and fully decoupled from the Flutter widget lifecycle on iOS.
  final audioHandler = await initAudioService();
  MetricsCollector.milestone('audioEngineReady', startupSw.elapsedMilliseconds);

  // Create TranscodingService instance to share across providers
  final transcodingService = TranscodingService();

  // 局域网转码规则：局域网连接强制原码（不转码），非局域网按设置判断。
  // 接线必须在 MultiProvider 创建 AuthProvider 之前——AuthProvider 构造时
  // _loadSavedConfig() 会触发首次 resolveActiveUrl，其地址变化需同步刷新
  // 转码层的 LAN 判定。
  transcodingService.setLanStateSource(() => subsonicService.isUsingLocalUrl);
  subsonicService.onActiveUrlChanged = transcodingService.onNetworkPathChanged;

  final Widget appWithProviders = MultiProvider(
    providers: [
      Provider<StorageService>.value(value: storageService),
      Provider<SubsonicService>.value(value: subsonicService),
      ChangeNotifierProvider<RecommendationService>.value(
        value: recommendationService,
      ),
      ChangeNotifierProvider<HomeRecommendationService>.value(
        value: homeRecommendationService,
      ),
      ChangeNotifierProvider<PlaybackContextTracker>.value(
        value: playbackContextTracker,
      ),
      ChangeNotifierProvider<TranscodingService>.value(
        value: transcodingService,
      ),
      ChangeNotifierProvider<LocalMusicService>.value(value: localMusicService),
      ChangeNotifierProvider(
        create: (_) => AuthProvider(subsonicService, storageService),
      ),
      ChangeNotifierProvider<CastService>.value(value: castService),
      ChangeNotifierProvider<LocaleService>.value(value: localeService),
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<UpnpService>.value(value: upnpService),
      ChangeNotifierProvider(
        create: (_) => PlayerProvider(
          subsonicService,
          storageService,
          castService,
          upnpService,
          audioHandler,
          transcodingService,
        ),
      ),
      ChangeNotifierProvider(
        create: (_) => LibraryProvider(subsonicService)
          ..recommendationService = recommendationService,
      ),
    ],
    child: const MuslyApp(),
  );

  // 首帧渲染完成后记录冷启动总时长
  WidgetsBinding.instance.addPostFrameCallback((_) {
    MetricsCollector.milestone('firstFrame', startupSw.elapsedMilliseconds);
    Log.i('App', '冷启动完成: ${startupSw.elapsedMilliseconds}ms');
  });

  // guarded zone：捕获未处理异步异常 + 拦截 print 兜底散落日志
  GlobalErrorHandler.runGuarded(() => runApp(appWithProviders));
}

class MuslyApp extends StatelessWidget {
  const MuslyApp({super.key});

  /// 一次性接线：AuthProvider.onServerSwitched → 清理旧服务器缓存。
  /// 切服务器后旧 Navidrome 的歌曲/专辑 ID 请求新道理鱼服务器会 404
  /// （诊断日志 confirmed），需清空播放队列持久化 + 首页推荐缓存。
  static bool _serverSwitchWired = false;

  @override
  Widget build(BuildContext context) {
    if (!_serverSwitchWired) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_serverSwitchWired) return;
        // 测试 harness 只提供部分 provider，捕获 ProviderNotFoundException
        // 跳过接线，保持 widget/integration 测试可运行（生产环境 providers 齐全）。
        final AuthProvider auth;
        final PlayerProvider player;
        final HomeRecommendationService homeRec;
        final LibraryProvider library;
        try {
          auth = context.read<AuthProvider>();
          player = context.read<PlayerProvider>();
          homeRec = context.read<HomeRecommendationService>();
          library = context.read<LibraryProvider>();
        } catch (_) {
          // 不置标记：provider 齐全时才算接线成功，否则下次重建再试。
          return;
        }
        _serverSwitchWired = true;
        auth.onServerSwitched = () {
          player.clearQueue(); // 清空播放队列 + persistent_queue 持久化
          homeRec.clearCaches(); // 清首页每日/探索缓存
          // 清 LibraryProvider 内存/prefs/DB 缓存并从新服务器重拉，
          // 消除「切服后旧专辑/艺人仍展示，点击用旧 ID 打新服务器 404」。
          // 回调是同步的，这里不能 await，失败只记日志避免未捕获异常。
          library.resetForServerChange().catchError(
                (e) => debugPrint('[Main] resetForServerChange failed: $e'),
              );
          debugPrint(
              '[Main] Server switched — cleared queue, home caches & library');
        };
      });
    }
    final localeService = Provider.of<LocaleService>(context);
    final themeService = Provider.of<ThemeService>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        final accent = themeService.accentColor.color;

        final ThemeData light;
        final ThemeData dark;

        if (lightDynamic != null && darkDynamic != null) {
          // Override dynamic color scheme with user-selected accent color
          final harmonisedLight = lightDynamic.harmonized().copyWith(
                primary: accent,
                secondary: accent.withAlpha(200),
              );
          final harmonisedDark = darkDynamic.harmonized().copyWith(
                primary: accent,
                secondary: accent.withAlpha(200),
              );
          light = AppTheme.lightThemeFromScheme(harmonisedLight);
          dark = AppTheme.darkThemeFromScheme(harmonisedDark);
        } else {
          light = AppTheme.lightThemeWith(accent);
          dark = AppTheme.darkThemeWith(accent);
        }

        return MaterialApp(
          title: 'Luobo',
          debugShowCheckedModeBanner: false,
          theme: light,
          darkTheme: dark,
          themeMode: themeService.themeMode,
          navigatorKey: navigatorKey,
          locale: localeService.currentLocale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AuthWrapper(),
          navigatorObservers: [
            AnalyticsNavigatorObserver(),
            DiagnosticsRouteObserver(),
            // 有声书详情页 RouteAware 依赖此全局实例收到路由事件（C004）。
            audiobookRouteObserver,
          ],
        );
      },
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  /// 最近一次非 authenticating 状态的稳定页面。authenticating 时保留它，
  /// 避免 MainScreen 被卸载 → 内层 Navigator（mobileNavigatorKey，含
  /// 设置页/登录页）销毁 → 登录页 mounted=false，错误/成功提示无法显示
  /// （真机日志 confirmed：「登录失败无提示 + 回首页」）。
  /// loading 由页面自身呈现（LoginScreen 按钮 isLoading 转圈）。
  Widget? _stableChild;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    switch (authProvider.state) {
      case AuthState.unknown:
        _stableChild = const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
        return _stableChild!;
      case AuthState.authenticated:
        // Show privacy policy first if needed
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _showPrivacyPolicyIfNeeded();
        });
        _stableChild = const MainScreen();
        return _stableChild!;
      case AuthState.offlineMode:
        _stableChild = const MainScreen(isOfflineMode: true);
        return _stableChild!;
      case AuthState.serverUnreachable:
        _stableChild = _ServerUnreachableScreen(
          hasOfflineContent: authProvider.hasOfflineContent,
          onEnterOfflineMode: () => authProvider.enterOfflineMode(),
          onDisconnect: () => authProvider.disconnect(),
        );
        return _stableChild!;
      case AuthState.authenticating:
        // 保留上一个页面（MainScreen 或 LoginScreen），不卸载导航栈。
        return _stableChild ??
            const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
      case AuthState.unauthenticated:
      case AuthState.error:
        _stableChild = const LoginScreen();
        return _stableChild!;
    }
  }
}

class _ServerUnreachableScreen extends StatelessWidget {
  final bool hasOfflineContent;
  final VoidCallback onEnterOfflineMode;
  final VoidCallback onDisconnect;

  const _ServerUnreachableScreen({
    required this.hasOfflineContent,
    required this.onEnterOfflineMode,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 72, color: Colors.grey),
              const SizedBox(height: 24),
              Text(
                AppLocalizations.of(context)!.serverUnreachableTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.serverUnreachableSubtitle,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => authProvider.retryConnection(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppLocalizations.of(context)!.retry),
                ),
              ),
              const SizedBox(height: 12),
              _buildSwitchProfileButton(context),
              const SizedBox(height: 12),
              if (hasOfflineContent) ...[
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onEnterOfflineMode,
                    icon: const Icon(Icons.offline_pin_rounded),
                    label: Text(AppLocalizations.of(context)!.openOfflineMode),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onDisconnect,
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(AppLocalizations.of(context)!.disconnect),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchProfileButton(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<List<ServerConfig>>(
      future: authProvider.getSavedProfiles(),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) return const SizedBox.shrink();

        final currentConfig = authProvider.config;
        final otherProfiles = profiles
            .where(
              (p) =>
                  p.serverUrl != currentConfig?.serverUrl ||
                  p.username != currentConfig?.username,
            )
            .toList();

        if (otherProfiles.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showSwitchProfileDialog(context, otherProfiles),
            icon: const Icon(Icons.swap_horiz_rounded),
            label: Text(l10n.switchServer),
          ),
        );
      },
    );
  }

  void _showSwitchProfileDialog(
      BuildContext context, List<ServerConfig> profiles) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    showGlassBottomSheet(
      context: context,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).brightness == Brightness.dark
              ? AppTheme.darkSurface
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).brightness == Brightness.dark
                      ? AppTheme.darkDivider
                      : AppTheme.lightDivider,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.switchServer,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...profiles.map((profile) {
                final label = profile.name?.isNotEmpty == true
                    ? profile.name!
                    : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
                return ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: Text(label),
                  subtitle: Text(profile.serverUrl,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await authProvider.switchProfile(profile);
                  },
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
