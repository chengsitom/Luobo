import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/capsule_button.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/pill_actions.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/server_profile_card.dart' show ServerFamilyInfo;
import '../widgets/server_qr_dialog.dart';
import '../widgets/settings_sub_page.dart';
import 'qr_scanner_screen.dart';
import 'server_detail_page.dart';
import 'server_form_screen.dart';

/// 「已连接的服务器」（设计稿 A1）—— 根页组 1 的入口。
///
/// 结构：右上**胶囊双钮**（扫码 / 新增）＋ **单卡多行**（徽标 + 名称/类型 + `⋮`）
/// ＋ 行下灰字说明。点击行 = 切换当前服务器；点 `⋮` = 打开**服务器操作面板**
/// （设计稿 B1）。
///
/// ⚠️ **不再复用 `ServerProfileCard`** —— 那张卡是「一服务器一卡」，与设计稿的
/// 「单卡多行」不符；而它同时被**登录网关页**（`server_gateway_screen.dart`）使用，
/// 不能就地改。所以本页自带行组件 [ServerRow]，`ServerProfileCard` 原样保留给网关页。
/// 家族徽标逻辑仍共用 [ServerFamilyInfo]（单一来源）。
class SavedProfilesScreen extends StatefulWidget {
  const SavedProfilesScreen({super.key});

  @override
  State<SavedProfilesScreen> createState() => _SavedProfilesScreenState();
}

/// `⋮` 面板的五个出口。
enum _ProfileAction { edit, detail, rescan, share, remove }

class _SavedProfilesScreenState extends State<SavedProfilesScreen> {
  Future<List<ServerConfig>>? _profilesFuture;
  bool _loaded = false;

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

  bool _isActive(AuthProvider auth, ServerConfig profile) =>
      auth.config?.serverUrl == profile.serverUrl &&
      auth.config?.username == profile.username;

  Future<void> _openAddServer() async {
    await NavigationHelper.push(context, const ServerFormScreen());
    if (mounted) setState(_reload);
  }

  /// 扫码添加：把扫到的配置交给**添加流程**的表单预填（而不是丢掉），
  /// 用户可以核对地址与账号后再连接。
  Future<void> _openScanner() async {
    final config = await NavigationHelper.push<ServerConfig>(
      context,
      const QrScannerScreen(),
    );
    if (!mounted) return;
    if (config == null) {
      setState(_reload);
      return;
    }
    await NavigationHelper.push(
      context,
      ServerFormScreen(prefillConfig: config),
    );
    if (mounted) setState(_reload);
  }

  Future<void> _openEdit(ServerConfig profile) async {
    // 编辑保存成功后表单会 pop(true)，据此刷新列表。
    final changed = await NavigationHelper.push(
      context,
      ServerFormScreen(initialConfig: profile),
    );
    if (changed == true && mounted) setState(_reload);
  }

  Future<void> _openDetail(ServerConfig profile, bool isActive) async {
    await NavigationHelper.push(
      context,
      ServerDetailPage(profile: profile, isActive: isActive),
    );
  }

  Future<void> _shareQr(ServerConfig profile) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ServerQrDialog(config: profile),
    );
  }

  /// 「重新扫描曲库」—— 走既有的 `LibraryProvider.refresh()`，不新写扫描逻辑。
  Future<void> _rescanLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final result = await libraryProvider.refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text(result.success ? l10n.libraryRefreshed : l10n.refreshFailed),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteProfile(ServerConfig profile) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProfileTitle),
        content: Text(l10n.deleteProfileConfirm(profile.displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.delete,
              style: const TextStyle(color: Color(0xFFFF3B30)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await Provider.of<AuthProvider>(context, listen: false)
        .deleteProfile(profile);
    if (mounted) setState(_reload);
  }

  /// 服务器操作面板（设计稿 B1）。
  Future<void> _showProfileActions(ServerConfig profile, bool isActive) async {
    final action = await showLuoboSheet<_ProfileAction>(
      context: context,
      builder: (ctx) => _buildActionsSheet(ctx, profile, isActive),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case _ProfileAction.edit:
        await _openEdit(profile);
      case _ProfileAction.detail:
        await _openDetail(profile, isActive);
      case _ProfileAction.rescan:
        await _rescanLibrary();
      case _ProfileAction.share:
        await _shareQr(profile);
      case _ProfileAction.remove:
        await _deleteProfile(profile);
    }
  }

  Widget _buildActionsSheet(
    BuildContext ctx,
    ServerConfig profile,
    bool isActive,
  ) {
    final l10n = AppLocalizations.of(ctx)!;
    final c = LuoboColors.of(ctx);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 头部：服务器名 + ✕
        Row(
          children: [
            Expanded(
              child: Text(
                profile.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuoboType.navTitle.copyWith(color: c.fg),
              ),
            ),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(AppIcons.close, size: 18, color: c.fg2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        LuoboSheetRow(
          title: l10n.editServer,
          onTap: () => Navigator.pop(ctx, _ProfileAction.edit),
        ),
        LuoboSheetRow(
          title: l10n.serverStatus,
          onTap: () => Navigator.pop(ctx, _ProfileAction.detail),
        ),
        // 「重新扫描」只对**当前服务器**有意义（refresh 拉的是当前登录的曲库）。
        if (isActive)
          LuoboSheetRow(
            title: l10n.rescanLibrary,
            onTap: () => Navigator.pop(ctx, _ProfileAction.rescan),
          ),
        LuoboSheetRow(
          title: l10n.shareQrCode,
          onTap: () => Navigator.pop(ctx, _ProfileAction.share),
        ),
        const SizedBox(height: 4),
        // 危险操作**单独一张卡**（§9.7 独立操作卡）。
        LuoboSheetRow(
          title: l10n.removeConnection,
          danger: true,
          onTap: () => Navigator.pop(ctx, _ProfileAction.remove),
        ),
        const SizedBox(height: 12),
        LuoboCapsuleButton(
          label: l10n.cancel,
          style: LuoboCapsuleStyle.primary,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    );
  }

  Future<void> _onProfileTap(ServerConfig profile) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_isActive(authProvider, profile)) {
      await _openEdit(profile);
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.switchProfile),
        content: Text(l10n.switchProfileConfirmation(profile.displayName)),
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
      debugPrint('[SavedProfiles] switchProfile threw: $e');
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
    // 提示并停留在当前页（成功时根路由已换成 MainScreen）。
    final applied = _isActive(authProvider, profile);
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
    // 成功：pop 回设置页避免叠层。
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsSubPage(
      title: l10n.connectedServers,
      actions: [
        LuoboPillActions(
          actions: [
            LuoboPillAction(
              icon: AppIcons.scan,
              onPressed: _openScanner,
            ),
            LuoboPillAction(
              icon: AppIcons.plus,
              onPressed: _openAddServer,
              tooltip: l10n.addServer,
            ),
          ],
        ),
      ],
      body: FutureBuilder<List<ServerConfig>>(
        future: _profilesFuture,
        builder: (context, snap) {
          // 读盘异常：展示错误 + 重试，避免永久 spinner。
          if (snap.hasError) {
            return LuoboEmptyState(
              icon: AppIcons.offline,
              message: l10n.failedToLoadProfiles,
              action: LuoboCapsuleButton(
                label: l10n.retry,
                expand: false,
                onPressed: () => setState(_reload),
              ),
            );
          }
          // 数据未就绪时避免闪现空态。
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profiles = snap.data!;
          if (profiles.isEmpty) {
            return LuoboEmptyState(
              icon: AppIcons.server,
              message: l10n.noSavedProfiles,
              action: SizedBox(
                width: 200,
                child: LuoboCapsuleButton(
                  label: l10n.addServer,
                  style: LuoboCapsuleStyle.primary,
                  onPressed: _openAddServer,
                ),
              ),
            );
          }

          final authProvider = Provider.of<AuthProvider>(context);
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              LuoboSpacing.pageX,
              LuoboSpacing.pageY,
              LuoboSpacing.pageX,
              LuoboSpacing.pageBottom,
            ),
            children: [
              LuoboCard(
                children: [
                  for (var i = 0; i < profiles.length; i++) ...[
                    if (i > 0) const LuoboDivider(indent: LuoboSpacing.rowX),
                    ServerRow(
                      profile: profiles[i],
                      isActive: _isActive(authProvider, profiles[i]),
                      onTap: () => _onProfileTap(profiles[i]),
                      onMore: () => _showProfileActions(
                        profiles[i],
                        _isActive(authProvider, profiles[i]),
                      ),
                    ),
                  ],
                ],
              ),
              LuoboHint(l10n.serversHint),
            ],
          );
        },
      ),
    );
  }
}

/// 服务器行（设计稿 A1）：徽标 + 名称（当前服务器带「已连接」徽标）+ 类型 + `⋮`。
class ServerRow extends StatelessWidget {
  const ServerRow({
    super.key,
    required this.profile,
    required this.isActive,
    this.onTap,
    this.onMore,
  });

  final ServerConfig profile;
  final bool isActive;
  final VoidCallback? onTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = ServerFamilyInfo.of(profile);

    final content = ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: LuoboSpacing.rowHeightTwoLine,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LuoboSpacing.rowX,
          vertical: LuoboSpacing.rowY,
        ),
        child: Row(
          children: [
            // 实心品牌色 + 白图标：与参考物（箭头音乐「已连接的平台」）一致 ——
            // 服务器徽标在这里是「一眼区分是哪个服务器」的**标识**，
            // 15% 淡底 + 彩色图标对比度太低，两块看着都是灰的。
            // 尺寸取参考实测 96px @3x = 32dp。
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: info.color,
                shape: BoxShape.circle,
              ),
              child: Icon(info.icon, color: LuoboAccent.onAccent, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          profile.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LuoboType.body.copyWith(
                            fontWeight: FontWeight.w500,
                            color: isActive ? LuoboAccent.accent : c.fg,
                          ),
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 6),
                        _ActiveBadge(label: l10n.connected),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    info.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: LuoboType.caption.copyWith(color: c.fg2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // 行内「更多」用**纵向 ⋮**（§2.3）。
            GestureDetector(
              onTap: onMore,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(AppIcons.moreV, size: 18, color: c.fg2),
              ),
            ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(onTap: onTap, child: content);
  }
}

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: LuoboAccent.ok.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(LuoboRadius.badge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(
              color: LuoboAccent.ok,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: LuoboType.badge.copyWith(color: LuoboAccent.ok),
          ),
        ],
      ),
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
