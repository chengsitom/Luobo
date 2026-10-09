import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/offline_service.dart';
import '../services/transcoding_service.dart';
import '../services/update_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/byte_format.dart';
import '../utils/connection_status.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/glass_circle_button.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/settings_sub_page.dart';
import 'settings_about_page.dart';
import 'settings_ai_playlist_tab.dart';
import 'settings_app_page.dart';
import 'settings_display_tab.dart';
import 'settings_playback_tab.dart';
import 'settings_server_tab.dart';
import 'settings_storage_tab.dart';
import 'settings_streaming_tab.dart';

/// 设置根页（C2 改造后）—— **4 组**：
/// 账号与服务器 / 播放与音质 / AI 智能 / 关于 Luobo。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/02-设置根页.png`
/// 结构说明：`docs/设置页重构技术方案.md` §9.2。
///
/// 与旧版的差异：
/// - 删除底部独立的 `Luobo vX.Y.Z` footer —— 版本号移到「关于 Luobo」行右侧
/// - 账号卡副标题由「已连接」改为**连接状态**（`服务器类型 · 网络 · 短转码状态`，§9.2.1）
/// - **不设**「用户管理」（道理鱼无此概念）、**不设**独立「音乐库管理」（并入服务器管理）
/// - **不设**「播放页主题」「封面样式」（随自定义主题功能整体删除）
/// - 右上角新增悬浮圆钮 → App 设置（外观 / 语言 / 缓存 / 匿名分析 / 导出日志 / 退出登录）
class SettingsRootScreen extends StatelessWidget {
  const SettingsRootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            // ── 大标题 + 右上圆钮 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                LuoboSpacing.pageX,
                4,
                LuoboSpacing.pageX,
                12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.settingsTitle,
                      style: LuoboType.display.copyWith(color: c.fg),
                    ),
                  ),
                  GlassCircleButton(
                    icon: AppIcons.settings,
                    tooltip: l10n.settingsTitle,
                    onPressed: () => NavigationHelper.push(
                      context,
                      const SettingsAppPage(),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: LuoboSpacing.pageX),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── 组 1：账号与服务器 ────────────────────────────────────
                  LuoboGroup(
                    title: l10n.settingsGroupServer,
                    rows: [
                      const _AccountCard(),
                      LuoboRow(
                        icon: AppIcons.server,
                        title: l10n.serverManagement,
                        onTap: () => _openSubPage(
                          context,
                          l10n.serverManagement,
                          const SettingsServerTab(),
                        ),
                      ),
                    ],
                  ),

                  // ── 组 2：播放与音质 ──────────────────────────────────────
                  LuoboGroup(
                    title: l10n.settingsGroupPlayback,
                    rows: [
                      LuoboRow(
                        icon: AppIcons.playback,
                        title: l10n.settingsPlaybackSettings,
                        onTap: () => _openSubPage(
                          context,
                          l10n.settingsPlaybackSettings,
                          const SettingsPlaybackTab(),
                        ),
                      ),
                      LuoboRow(
                        icon: AppIcons.streaming,
                        title: l10n.settingsStreamingEntry,
                        onTap: () => _openSubPage(
                          context,
                          l10n.settingsStreamingEntry,
                          const SettingsStreamingTab(),
                        ),
                      ),
                      LuoboRow(
                        icon: AppIcons.playerUi,
                        title: l10n.settingsDisplayEntry,
                        onTap: () => _openSubPage(
                          context,
                          l10n.settingsDisplayEntry,
                          const SettingsDisplayTab(),
                        ),
                      ),
                      const _StorageEntryRow(),
                    ],
                  ),

                  // ── 组 3：AI 智能 ────────────────────────────────────────
                  LuoboGroup(
                    title: l10n.settingsGroupAi,
                    rows: [
                      LuoboRow(
                        icon: AppIcons.ai,
                        title: l10n.settingsAiEntry,
                        onTap: () => _openSubPage(
                          context,
                          l10n.settingsAiEntry,
                          const SettingsAiPlaylistTab(),
                        ),
                      ),
                    ],
                  ),

                  // ── 组 4：关于 Luobo ─────────────────────────────────────
                  LuoboGroup(
                    title: l10n.settingsGroupAbout,
                    rows: [
                      LuoboRow(
                        icon: AppIcons.info,
                        title: l10n.settingsGroupAbout,
                        value: 'v${UpdateService.currentVersion}',
                        onTap: () => NavigationHelper.push(
                          context,
                          const SettingsAboutPage(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openSubPage(BuildContext context, String title, Widget body) {
    NavigationHelper.push(context, SettingsSubPage(title: title, body: body));
  }
}

/// 「下载与存储」入口行 —— **状态值外显**（§9.2 根页图）。
///
/// 取**离线下载占用**而不是封面缓存：后者已在 App 设置页的「清除 App 缓存」
/// 外显，不重复。值为 0 时不显示，避免「0 B」噪音；读不到也不阻塞根页。
class _StorageEntryRow extends StatefulWidget {
  const _StorageEntryRow();

  @override
  State<_StorageEntryRow> createState() => _StorageEntryRowState();
}

class _StorageEntryRowState extends State<_StorageEntryRow> {
  final _offline = OfflineService();
  String? _sizeLabel;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _offline.initialize();
      final bytes = await _offline.getDownloadedSize();
      if (!mounted) return;
      setState(() => _sizeLabel = bytes > 0 ? formatBytes(bytes) : null);
    } catch (_) {
      // 读不到就不显示值。
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: AppIcons.storage,
      title: l10n.settingsStorageEntry,
      value: _sizeLabel,
      onTap: () => NavigationHelper.push(
        context,
        SettingsSubPage(
          title: l10n.settingsStorageEntry,
          body: const SettingsStorageTab(),
        ),
      ),
    );
  }
}

/// 账号卡：头像 + 用户名 + **连接状态**（服务器类型 · 网络 · 短转码状态）。
class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final config = context.watch<AuthProvider>().config;

    // ⚠️ 只 `select` 真正用到的两个子状态，不要 `watch` 整个 provider：
    // `PlayerProvider` 在播放期间每 ~250ms 通知一次（进度更新），而设置根页在
    // `IndexedStack` 里**常驻**（切走仍挂载）→ 整个账号卡会被白白重建 4 次/秒。
    final (connectionType, isTranscodingNow) =
        context.select<TranscodingService, (ConnectionType, bool)>(
      (t) => (t.currentConnectionType, t.getCurrentBitrate() != null),
    );
    final isActiveStreamTranscoded = context.select<PlayerProvider, bool>(
      (p) => p.isActiveStreamTranscoded,
    );
    final info = ConnectionStatus.fromValues(
      l10n: l10n,
      isWifi: connectionType == ConnectionType.wifi,
      isActiveStreamTranscoded: isActiveStreamTranscoded,
      isTranscodingNow: isTranscodingNow,
      isDark: c.isDark,
    );

    final username = config?.username ?? '';
    final initial = username.isNotEmpty ? username.characters.first : '?';

    final subtitle = config == null
        ? l10n.notConnected
        : ConnectionStatus.accountSubtitle(context, info: info);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LuoboSpacing.rowX,
        vertical: LuoboSpacing.cardPadY,
      ),
      child: Row(
        children: [
          Container(
            // 飞牛实测 131px @3x ≈ 44dp（原来写死 50，偏大 6dp）。
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: LuoboAccent.avatarGradient,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: LuoboType.avatarInitial.copyWith(
                color: LuoboAccent.onAccent,
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  config == null ? l10n.notConnected : username,
                  style: LuoboType.accountName.copyWith(color: c.fg),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (config != null) ...[
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: info.networkColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
