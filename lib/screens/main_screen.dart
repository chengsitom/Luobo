import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/providers.dart';
import '../services/diagnostics/diagnostics.dart';
import '../services/local_music_service.dart';
import '../services/recommendation_service.dart';
import '../services/update_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/glass_pill_nav.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import 'home_v2_screen.dart';
import 'library_screen.dart';
import 'search_screen.dart';
import 'settings_root_screen.dart';
import 'now_playing_screen.dart';

class MainScreen extends StatefulWidget {
  final bool isOfflineMode;

  const MainScreen({super.key, this.isOfflineMode = false});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _showRightSidebar = true;

  /// 桌面端仍用「首页 / 音乐库 / 搜索」（**桌面端本轮不一起改**，见方案 §7 ⑫）。
  final List<Widget> _screens = const [
    HomeV2Screen(), // 首页重构：v2 新首页（旧 HomeScreen 保留未删，回退改回 HomeScreen()）
    LibraryScreen(),
    SearchScreen(),
  ];

  /// 移动端底栏（C2 改造）：首页 / 音乐库 / **设置**。
  /// 搜索不再占 tab，改由首页 + 音乐库的右上角圆钮进入。
  final List<Widget> _mobileScreens = const [
    HomeV2Screen(),
    LibraryScreen(),
    SettingsRootScreen(),
  ];

  /// 切换 tab 的**唯一入口**：既改本地状态，也向 `NavigationHelper.tabIndex`
  /// 广播。广播是给「订阅 tab 变化」的页面用的（首页靠它实现「每次回到首页换
  /// 漫游卡配色」）——桌面端与移动端的切换路径不同，统一走这里才不会漏。
  void _setTab(int index) {
    setState(() => _currentIndex = index);
    NavigationHelper.tabIndex.value = index;
  }

  @override
  void initState() {
    super.initState();

    NavigationHelper.registerTabChangeCallback(_setTab);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final playerProvider = Provider.of<PlayerProvider>(
        context,
        listen: false,
      );
      final recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );

      playerProvider.setLibraryProvider(libraryProvider);
      playerProvider.setRecommendationService(recommendationService);

      // 冷启动时队列可能在服务器配置就绪前被恢复（persistent_queue 全局键），
      // 此处补一次归属校验：队列属于旧服务器则清空，避免旧 songId 打新服务器。
      playerProvider.validateQueueForServer();

      if (authProvider.isLocalOnlyMode) {
        final localMusicService = Provider.of<LocalMusicService>(
          context,
          listen: false,
        );

        libraryProvider.setLocalMusicService(localMusicService);

        if (localMusicService.isEmpty && !localMusicService.isScanning) {
          localMusicService.scanForMusic();
        } else if (!localMusicService.isScanning) {
          libraryProvider.initialize();
        }
      } else {
        libraryProvider.setLocalOnlyMode(false);
        libraryProvider.setServerOfflineMode(widget.isOfflineMode);
        libraryProvider.initialize();
      }

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _checkForUpdate();
      });
    });
  }

  Future<void> _checkForUpdate() async {
    final release = await UpdateService.checkForUpdate();
    if (release == null || !mounted) return;
    _showUpdateDialog(release);
  }

  void _showUpdateDialog(ReleaseInfo release) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changelog = UpdateService.stripMarkdown(release.body);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.appleMusicRed, AppTheme.appleMusicPink],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      CupertinoIcons.arrow_up_circle_fill,
                      color: Colors.white,
                      size: 40,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.updateAvailable,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.updateAvailableSubtitle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Flexible(
                          child: _VersionBadge(
                            label: l10n.updateCurrentVersion(
                              UpdateService.currentVersion,
                            ),
                            color: Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.arrow_right,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: _VersionBadge(
                            label: l10n.updateLatestVersion(release.version),
                            color: Colors.white.withValues(alpha: 0.3),
                            bold: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (changelog.isNotEmpty)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.whatsNew,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white54 : Colors.black45,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Flexible(
                          child: Scrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              child: Text(
                                changelog,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.5,
                                  color:
                                      isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(l10n.remindLater),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          final uri = Uri.parse(release.htmlUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(
                          CupertinoIcons.cloud_download,
                          size: 18,
                        ),
                        label: Text(l10n.downloadUpdate),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: AppTheme.appleMusicRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openNowPlaying() {
    final transitionSw = Stopwatch()..start();
    final transitionMsSw = Stopwatch()..start();
    var transitionRecorded = false;
    Navigator.of(context)
        .push(
      PageRouteBuilder(
        opaque: true,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return const NowPlayingScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // 转场动画完成时记录实际耗时：掉帧会拖长动画完成时间（配置 400ms，
          // 卡顿则显著 >400ms），直接量化"进全屏页是否卡"。
          if (!transitionRecorded) {
            animation.addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                transitionRecorded = true;
                transitionMsSw.stop();
                DiagnosticsRouteObserver.transition(
                  from: 'MainScreen',
                  to: 'NowPlayingScreen',
                  transitionMs: transitionMsSw.elapsedMilliseconds,
                );
              }
            });
          }
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    )
        .then((_) async {
      if (!mounted) return;
      DiagnosticsRouteObserver.transition(
        from: 'MainScreen',
        to: 'NowPlayingScreen',
        dwellMs: transitionSw.elapsedMilliseconds,
      );
      if (Platform.isIOS) {
        // Wait longer for the transition to complete and audio session to stabilize
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        Provider.of<PlayerProvider>(context, listen: false)
            .reactivateAudioSession();
      }
    });
  }

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isLocalMode = authProvider.isLocalOnlyMode;

    if (_isDesktop) {
      return Scaffold(
        body: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  DesktopNavigationSidebar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: (index) {
                      _setTab(index);
                      NavigationHelper.desktopNavigatorKey.currentState
                          ?.popUntil((route) => route.isFirst);
                    },
                    navigatorKey: NavigationHelper.desktopNavigatorKey,
                  ),
                  Expanded(
                    child: Navigator(
                      key: NavigationHelper.desktopNavigatorKey,
                      onGenerateRoute: (settings) {
                        return PageRouteBuilder(
                          pageBuilder: (ctx, anim, _) => IndexedStack(
                            index: _currentIndex,
                            children: _screens,
                          ),
                          transitionsBuilder: (ctx, animation, _, child) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                        );
                      },
                    ),
                  ),
                  if (_showRightSidebar)
                    Selector<PlayerProvider, bool>(
                      selector: (_, p) =>
                          p.currentSong != null || p.isPlayingRadio,
                      builder: (context, hasCurrentSong, _) {
                        return hasCurrentSong
                            ? const RightSidebar()
                            : const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
            Selector<PlayerProvider, bool>(
              selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
              builder: (context, hasCurrentSong, _) {
                return hasCurrentSong
                    ? DesktopPlayerBar(
                        navigatorKey: NavigationHelper.desktopNavigatorKey,
                      )
                    : const SizedBox.shrink();
              },
            ),
          ],
        ),
      );
    }

    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null || p.isPlayingRadio,
      builder: (context, hasCurrentSong, _) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _handleBackButton();
          },
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            // 覆盖式（§6.1）：内容延伸到屏幕底，底栏 / 播放条**悬浮**其上
            // （飞牛首页的卡片会被底栏压住一半）。
            //
            // 用 `extendBody: true` + `bottomNavigationBar` 而不是手写 `Stack`：
            // Scaffold 会据此把 body 包进一个 MediaQuery，令
            // `padding.bottom = max(安全区, 条带高度)`（见 SDK 的 `_BodyBuilder`）——
            // 于是页面里 `ListView(padding: null)` 与 `SafeArea` **自动**留出净空，
            // 最后一条内容不会被永久压在玻璃下面。
            //
            // ⚠️ 因此**不再需要** `ColoredBox` 底色（§9.17.3 那个「色差带」的修法）——
            // 条带现在是真悬浮，玻璃自己负责模糊，内容从下方流过。
            extendBody: true,
            body: Column(
              children: [
                if (widget.isOfflineMode || isLocalMode)
                  Container(
                    width: double.infinity,
                    color: isLocalMode ? Colors.indigo : Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          Icon(
                            isLocalMode
                                ? CupertinoIcons.folder_fill
                                : CupertinoIcons.wifi_slash,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isLocalMode
                                  ? AppLocalizations.of(
                                      context,
                                    )!
                                      .localFilesModeBanner
                                  : AppLocalizations.of(
                                      context,
                                    )!
                                      .offlineModeBanner,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isLocalMode)
                  Selector<LocalMusicService, (bool, double, String)>(
                    selector: (_, s) =>
                        (s.isScanning, s.scanProgress, s.scanStatus),
                    builder: (context, data, _) {
                      final (isScanning, progress, status) = data;
                      if (!isScanning) return const SizedBox.shrink();
                      return Container(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.85),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            if (progress > 0)
                              Text(
                                '${(progress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                Expanded(
                  child: Navigator(
                    key: NavigationHelper.mobileNavigatorKey,
                    // 维护 `NavigationHelper.secondaryDepth` → 底部条带据此在
                    // 「底栏（一级页）」与「播放条（二级页）」之间二选一（§6.1）。
                    observers: [NavigationHelper.secondaryDepthObserver],
                    onGenerateRoute: (settings) {
                      return MaterialPageRoute(
                        builder: (_) => IndexedStack(
                          index: _currentIndex,
                          // IndexedStack 内部用 `Visibility(maintainAnimation:
                          // true)` 包住未选中项，TickerMode 不会被关掉——不额外
                          // 包一层的话，首页流体背景等动画在切走后仍会逐帧产帧。
                          children: [
                            for (var i = 0; i < _mobileScreens.length; i++)
                              TickerMode(
                                enabled: _currentIndex == i,
                                child: _mobileScreens[i],
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            bottomNavigationBar: ValueListenableBuilder<int>(
              valueListenable: NavigationHelper.secondaryDepth,
              builder: (context, depth, _) => _buildBottomStrip(
                context,
                isSecondary: depth > 0,
                hasSong: hasCurrentSong,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleBackButton() {
    final navigatorState = NavigationHelper.mobileNavigatorKey.currentState;
    if (navigatorState != null && navigatorState.canPop()) {
      navigatorState.pop();
      return;
    }

    if (_currentIndex != 0) {
      _setTab(0);
      return;
    }

    SystemNavigator.pop();
  }

  /// 底部条带（覆盖式，悬浮在内容之上）—— 见 `Scaffold.extendBody` 的注释。
  ///
  /// §6.1：**一级页只出底栏、二级页只出播放条**（互斥）。对齐飞牛：一级页的
  /// 「正在播放」入口是底栏的封面槽（带进度环），二级页没有底栏、才由播放条承担。
  ///
  /// ⚠️ **不加任何底色** —— 悬浮条带必须让内容从下方流过，玻璃自己负责模糊。
  /// 系统安全区统一在这里加（而不是各自加），条带高度 = 这里的总高度，
  /// 也正是 Scaffold 注入给 body 的 `padding.bottom`。
  Widget _buildBottomStrip(
    BuildContext context, {
    required bool isSecondary,
    required bool hasSong,
  }) {
    // 二级页且没有在播内容 → 条带整条不渲染（返回零高度，不挡点击）。
    if (isSecondary && !hasSong) return const SizedBox.shrink();

    // 飞牛实测条底边在屏幕底上方 **34.3dp**（§6.3）；部分机型上报的底部安全区
    // 只有 ~16dp，会让条看起来「贴着底」—— 取两者较大值。
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final bottom = safeBottom > LuoboGlass.stripBottomInset
        ? safeBottom
        : LuoboGlass.stripBottomInset;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSecondary) MiniPlayer(onTap: _openNowPlaying),
          if (!isSecondary) _buildBottomNav(context),
        ],
      ),
    );
  }

  /// 底栏（C2 改造）—— 3 项纯图标（首页 / 音乐库 / **设置**）均匀分布
  /// + 分隔线 + 专辑封面等宽槽。
  ///
  /// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ③ 节。
  /// 与旧版的差异：
  /// - 第 3 项由「搜索」改为「**设置**」（对齐 fnos：设置与音乐库平级）
  /// - **纯图标、无文字标签**
  /// - 搜索改由首页 / 音乐库右上角圆钮进入
  /// - **彩蛋页（连点搜索 11 次）已按用户要求移除**
  /// - 玻璃样式**固定为设计体系**（`liquidGlass` 用户开关已删除）
  Widget _buildBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Selector<PlayerProvider, bool>(
      selector: (_, p) => p.currentSong != null,
      builder: (context, hasSong, _) => Padding(
        // 底部安全区由 [_buildBottomStrip] 统一加，这里只管与播放条之间的间隔。
        padding: const EdgeInsets.only(top: 6),
        // §6.1：飞牛实测 **256dp 居中浮动**（两侧各留 52dp），单槽落到 64dp。
        // 用 `maxWidth` 而非固定宽 —— 窄屏不溢出，宽屏（平板）也保持 256dp 居中。
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: LuoboGlass.navWidth),
            child: GlassPillNav(
              currentIndex: _currentIndex,
              items: [
                GlassPillNavItem(icon: AppIcons.home, label: l10n.home),
                GlassPillNavItem(icon: AppIcons.library, label: l10n.library),
                GlassPillNavItem(
                  icon: AppIcons.settings,
                  label: l10n.settingsTitle,
                ),
              ],
              onTap: (index) {
                final navigatorState =
                    NavigationHelper.mobileNavigatorKey.currentState;
                navigatorState?.popUntil((route) => route.isFirst);
                _setTab(index);
              },
              art: hasSong ? const _NavAlbumArt() : null,
              onArtTap: _openNowPlaying,
            ),
          ),
        ),
      ),
    );
  }
}

/// 底栏最右的**当前专辑圆封面 + 外圈进度环**（点击进播放页）。
/// 无播放时由 [GlassPillNav] 的 `art == null` 决定不渲染该槽。
class _NavAlbumArt extends StatelessWidget {
  const _NavAlbumArt();

  @override
  Widget build(BuildContext context) {
    final song = context.watch<PlayerProvider>().currentSong;
    if (song == null) return const SizedBox.shrink();
    final coverArt = Provider.of<LibraryProvider>(context, listen: false)
        .effectiveCoverArt(song);
    // ⚠️ 进度订阅只落在这个环上（不是整条底栏）—— 否则底栏的毛玻璃会跟着每帧重建。
    return Selector<PlayerProvider, double>(
      selector: (_, p) => p.progress,
      builder: (context, progress, _) => LuoboNavArtRing(
        progress: progress,
        art: AlbumArtwork(coverArt: coverArt, size: LuoboGlass.navArtSize),
      ),
    );
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const _VersionBadge({
    required this.label,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      // 窄屏下「当前版本 / 最新版本」两个徽标会超出弹窗宽度，
      // 用 FittedBox 等比缩字而不是裁掉或换行，保证版本号始终完整可读。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
