import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import '../utils/local_library_launcher.dart';
import '../utils/navigation_helper.dart';
import '../utils/screen_helper.dart';
import 'qr_scanner_screen.dart';
import 'server_form_screen.dart';
import '../widgets/server_profile_card.dart';

/// 登录网关页（登录第 1 步）：我的服务器卡片列表 + 添加入口。
///
/// - 有已保存配置：顶部小品牌区 + 卡片列表 + 「＋ 添加服务器」虚线卡；
///   点当前连接卡片进编辑表单，点其他卡片确认切换。
/// - 无配置（首次启动）：居中大品牌区 + 全宽「添加服务器」主按钮。
/// - 底部始终提供 扫码添加 / 使用本地文件 两个替代入口。
class ServerGatewayScreen extends StatefulWidget {
  const ServerGatewayScreen({super.key});

  @override
  State<ServerGatewayScreen> createState() => _ServerGatewayScreenState();
}

class _ServerGatewayScreenState extends State<ServerGatewayScreen> {
  Future<List<ServerConfig>>? _profilesFuture;
  bool _loaded = false;

  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = '';

  /// 防连点：添加/扫码的页面转场期间置位。
  bool _opening = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _reload();
    }
  }

  void _reload() {
    _profilesFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).getSavedProfiles();
  }

  // ── 交互 ────────────────────────────────────────────────────────────

  Future<void> _openAddServer() async {
    if (_opening) return;
    _opening = true;
    try {
      await NavigationHelper.push(context, const ServerFormScreen());
    } finally {
      _opening = false;
    }
    if (mounted) setState(_reload);
  }

  Future<void> _onProfileTap(ServerConfig profile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final isActive = authProvider.config?.serverUrl == profile.serverUrl &&
        authProvider.config?.username == profile.username;

    if (isActive) {
      // 当前连接：直接进编辑表单，保存后 pop 回本页。
      await NavigationHelper.push(
        context,
        ServerFormScreen(initialConfig: profile),
      );
      if (mounted) setState(_reload);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.switchProfile),
        content: Text(l10n.switchProfileConfirmation(_label(profile))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // 切换会走 _verifyConnection（网络等待可能数秒）：阻塞式进度框防止
    // 重复点击，失败时给出提示。
    BuildContext? dialogCtx;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        dialogCtx = ctx;
        return const _ConnectingDialog();
      },
    );
    try {
      final playerProvider =
          Provider.of<PlayerProvider>(context, listen: false);
      await playerProvider.stop();
      await authProvider.switchProfile(profile);
    } catch (e) {
      // switchProfile 内部 configure 等无兜底，异常会逃逸：关框后给出与
      // 正常失败路径一致的提示，避免静默无反馈。
      debugPrint('[Gateway] switchProfile threw: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authProvider.error ?? l10n.failedToConnectToServer,
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    } finally {
      // 用弹窗自身的 context 关闭（挂在弹窗所在 Navigator 上），不依赖页面
      // mounted / Navigator.of(context) 的解析结果——切换成功触发页面重建或
      // 导航时序变化时也能可靠关闭，避免「连接中」弹窗残留。
      final ctx = dialogCtx;
      if (ctx != null && ctx.mounted) {
        Navigator.of(ctx).pop();
      }
    }
    if (!mounted) return;

    // 切换失败时 switchProfile 已回滚旧配置：比对目标是否生效，未生效则
    // 提示并停留在当前页（成功时 AuthWrapper 会把根路由换成 MainScreen）。
    final applied = authProvider.config?.serverUrl == profile.serverUrl &&
        authProvider.config?.username == profile.username;
    if (!applied) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ?? l10n.failedToConnectToServer,
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    // 成功：若本页是被 push 进入的（防御），pop 回上一页避免叠层。
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _scanQrCode() async {
    // 防连点：扫码页转场期间忽略重复点击。
    if (_opening) return;
    _opening = true;
    try {
      await _scanQrCodeInner();
    } finally {
      _opening = false;
    }
  }

  Future<void> _scanQrCodeInner() async {
    final config = await Navigator.push<ServerConfig>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (config == null || !mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      serverUrl: config.serverUrl,
      localUrl: config.localUrl,
      username: config.username,
      password: config.password,
      useLegacyAuth: config.useLegacyAuth || config.serverFamily == 'daoliyu',
      allowSelfSignedCertificates: config.allowSelfSignedCertificates,
      profileName: config.name,
      serverFamily: config.serverFamily,
    );

    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.qrConfigImported),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // 与表单登录一致：弹到根路由显示首页。
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      // 失败：不再丢弃扫描配置——push 预填表单，用户可直接修正凭据重试
      // （对齐旧登录页「扫码填表单、失败可编辑重试」的行为）。
      if (!mounted) return;
      await NavigationHelper.push(
        context,
        ServerFormScreen(initialConfig: config),
      );
      if (mounted) setState(_reload);
    }
  }

  Future<void> _useLocalFiles() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatus = l10n.startingScan;
    });
    try {
      // 公共流程（utils/local_library_launcher.dart）——「添加服务器」页
      // 的「其他方式」也用同一个实现，避免两份。
      final switched = await launchLocalLibrary(
        context,
        onProgress: (progress, status) {
          if (mounted) {
            setState(() {
              _scanProgress = progress;
              _scanStatus = status;
            });
          }
        },
      );
      if (switched) _popIfPushed();
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _popIfPushed() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  String _label(ServerConfig profile) {
    if (profile.name?.isNotEmpty == true) return profile.name!;
    return '${profile.username}@'
        '${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor:
          _isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ScreenHelper.loginPadding(context)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: FutureBuilder<List<ServerConfig>>(
                      future: _profilesFuture,
                      builder: (context, snap) {
                        // 读盘异常：展示错误 + 重试，避免永久 spinner。
                        if (snap.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    l10n.failedToLoadProfiles,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: _isDark
                                          ? AppTheme.darkSecondaryText
                                          : AppTheme.lightSecondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () => setState(_reload),
                                    child: Text(l10n.retry),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        // 数据未就绪时避免闪现空态：先显示轻量 loading，
                        // 有已保存配置的用户不会先看到「大 logo + 添加按钮」。
                        if (!snap.hasData) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 64),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final profiles = snap.data!;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (profiles.isEmpty)
                              ..._buildEmptyState(theme, l10n)
                            else ...[
                              _buildHeader(theme, l10n),
                              const SizedBox(height: 24),
                              Text(
                                l10n.myServers,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: _isDark
                                      ? AppTheme.darkSecondaryText
                                      : AppTheme.lightSecondaryText,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 8),
                              for (final profile in profiles) ...[
                                ServerProfileCard(
                                  profile: profile,
                                  isActive: authProvider.config?.serverUrl ==
                                          profile.serverUrl &&
                                      authProvider.config?.username ==
                                          profile.username,
                                  onTap: () => _onProfileTap(profile),
                                ),
                                const SizedBox(height: 12),
                              ],
                              AddServerCard(onTap: _openAddServer),
                              const SizedBox(height: 24),
                              _buildSecondaryEntries(theme, l10n),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (Navigator.of(context).canPop())
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  tooltip: l10n.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 无配置（首次启动）：大品牌区 + 主按钮 + 替代入口。
  List<Widget> _buildEmptyState(ThemeData theme, AppLocalizations l10n) {
    return [
      const SizedBox(height: 40),
      Center(
        child: Container(
          width: ScreenHelper.loginLogoSize(context),
          height: ScreenHelper.loginLogoSize(context),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.appleMusicRed.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Transform.translate(
              offset: const Offset(0, 8),
              child: Image.asset(
                'assets/logobig.png',
                width: ScreenHelper.loginLogoSize(context),
                height: ScreenHelper.loginLogoSize(context),
                fit: BoxFit.fill,
              ),
            ),
          ),
        ),
      ),
      const SizedBox(height: 32),
      Text(
        l10n.appName,
        textAlign: TextAlign.center,
        style: theme.textTheme.displayMedium?.copyWith(
          fontSize: ScreenHelper.isSmallScreen(context) ? 28 : null,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        l10n.connectToServerSubtitle,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: AppTheme.lightSecondaryText,
        ),
      ),
      const SizedBox(height: 32),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _openAddServer,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.appleMusicRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.addServer,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
        ),
      ),
      const SizedBox(height: 24),
      _buildSecondaryEntries(theme, l10n),
      const SizedBox(height: 24),
    ];
  }

  /// 有配置时顶部的紧凑品牌区。
  Widget _buildHeader(ThemeData theme, AppLocalizations l10n) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/logobig.png',
            width: 40,
            height: 40,
            fit: BoxFit.fill,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.appName,
          style: theme.textTheme.headlineMedium,
        ),
      ],
    );
  }

  Widget _buildSecondaryEntries(ThemeData theme, AppLocalizations l10n) {
    final isBusy = _isScanning;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.or,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.lightSecondaryText,
                ),
              ),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : _scanQrCode,
            icon: const Icon(CupertinoIcons.qrcode_viewfinder),
            label: Text(
              l10n.scanQrCode,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.appleMusicRed,
              side: const BorderSide(color: AppTheme.appleMusicRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ),
        if (!Platform.isIOS) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: isBusy ? null : _useLocalFiles,
              icon: _isScanning
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.appleMusicRed,
                        ),
                      ),
                    )
                  : const Icon(CupertinoIcons.folder),
              label: Text(
                _isScanning ? _scanStatus : l10n.useLocalFiles,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.appleMusicRed,
                side: const BorderSide(color: AppTheme.appleMusicRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ),
        ],
        if (!Platform.isIOS && _isScanning) ...[
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _scanProgress > 0 ? _scanProgress : null,
            backgroundColor: AppTheme.appleMusicRed.withValues(alpha: 0.2),
            color: AppTheme.appleMusicRed,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ],
    );
  }
}

/// 切换服务器时的阻塞式进度框（不可点穿，防重复切换）。
class _ConnectingDialog extends StatelessWidget {
  const _ConnectingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 16),
            Text(AppLocalizations.of(context)!.connecting),
          ],
        ),
      ),
    );
  }
}
