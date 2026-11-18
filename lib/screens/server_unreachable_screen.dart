import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../theme/design_tokens.dart';
import '../theme/theme.dart';
import '../widgets/glass_surface.dart';

/// 服务器连不上时的兜底页：重试 / 切换服务器 / 进入离线模式 / 断开连接。
///
/// 独立成文件（原先是 main.dart 里的私有类）是为了能被 widget test 直接泵起来，
/// 锁住两件曾经出过事的东西：
/// 1. 离线入口**永远存在**且文案恒定（不能因为"没有下载"就改叫别的名字，
///    用户会以为在线记录被删了）；
/// 2. 小屏 + 大字号下不溢出（按钮最多 4 个 + 说明行）。
class ServerUnreachableScreen extends StatelessWidget {
  final bool hasOfflineContent;
  final VoidCallback onEnterOfflineMode;
  final VoidCallback onDisconnect;

  const ServerUnreachableScreen({
    super.key,
    required this.hasOfflineContent,
    required this.onEnterOfflineMode,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    // 重试期间必须给反馈：此前点了「重试」页面毫无变化（状态切到
    // authenticating 后本页仍是 _stableChild），用户以为按钮没响应。
    final isConnecting = authProvider.state == AuthState.authenticating;

    return Scaffold(
      // 可滚动：多了「切换服务器」按钮 + 一行说明后，363dp 高的小屏 + 大字号
      // 会整屏溢出（Column 不可滚 → 黄黑条）。
      //
      // ⚠️ `SingleChildScrollView` 给的是**无界高度**，里面直接放 `Center`
      // 只会得到"内容多高就多高"，垂直居中失效（内容会贴顶）。用
      // `ConstrainedBox(minHeight: 视口高)` 撑回一屏高，既保住居中，
      // 又能在内容超高时滚动。
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.cloud_off_rounded,
                          size: 72, color: Colors.grey),
                      const SizedBox(height: 24),
                      Text(
                        l10n.serverUnreachableTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        // 服务器只有 IPv6 地址、而当前网络没有公网 IPv6 时，
                        // 泛泛的「连接超时」帮不上忙 —— 换成能指导动作的归因。
                        authProvider.ipv6OnlyUnreachable
                            ? l10n.ipv6OnlyNetworkHint
                            : l10n.serverUnreachableSubtitle,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isConnecting
                              ? null
                              : () => authProvider.retryConnection(),
                          icon: isConnecting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.refresh_rounded),
                          label: Text(
                            isConnecting ? l10n.startupConnecting : l10n.retry,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSwitchProfileButton(context),
                      const SizedBox(height: 12),
                      // 离线入口**永远只有这一个**，文案不再随有没有下载而变成
                      // 「浏览本地音乐」—— 那会让用户以为「离线模式」这个选项被删了
                      // （真机反馈）。能进去看到什么，交给下面的说明行老实交代。
                      SizedBox(
                        width: double.infinity,
                        // 次强调（tonal）而不是又一个实心主按钮：本页真正的主动作是
                        // 「重试」，两个同权重实心按钮并排反而分不清主次。
                        child: FilledButton.tonalIcon(
                          onPressed: onEnterOfflineMode,
                          icon: const Icon(Icons.offline_pin_rounded),
                          label: Text(l10n.enterOfflineMode),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        hasOfflineContent
                            ? l10n.offlineModeHintWithCount(
                                authProvider.offlinePlayableCount,
                              )
                            : l10n.offlineModeHintNoDownloads,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.35,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onDisconnect,
                          icon: const Icon(Icons.logout_rounded),
                          label: Text(l10n.disconnect),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
              : LuoboColors.light.bg,
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
