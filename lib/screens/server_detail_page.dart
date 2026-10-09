import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/server_profile_card.dart';
import '../widgets/settings_sub_page.dart';

/// 服务器详情（设计稿 B4）—— 二级页。
///
/// ⚠️ **只画有真实数据来源的项**（本文档 §9.9 的「三轮被否的杜撰项」教训）：
///
/// | 设计稿里的项 | 处置 | 原因 |
/// |---|---|---|
/// | 服务端名称 / 广域网 / 局域网 / 服务端类型 / 服务端版本号 | ✅ 画 | `ServerConfig.name/serverUrl/localUrl/serverType/serverVersion` 全都有 |
/// | 专辑 / 歌曲 / 艺术家 三列统计 | ✅ 画（仅当前服务器） | `LibraryProvider.cachedAllAlbums / cachedAllSongs / artists` |
/// | 服务端状态 | ✅ 画（仅当前服务器） | `SubsonicService.ping()`；**非当前服务器不能 ping**（它按当前登录态发请求，会误报） |
/// | 有声书数 | ❌ 不画 | 全仓无「有声书计数」数据源 |
/// | 最后扫描时间 | ❌ 不画 | Subsonic `getScanStatus` 未接入，无任何「扫描时间」字段 |
class ServerDetailPage extends StatefulWidget {
  const ServerDetailPage({
    super.key,
    required this.profile,
    this.isActive = false,
  });

  final ServerConfig profile;

  /// 是否为当前连接：只有当前服务器才有实时统计与状态。
  final bool isActive;

  @override
  State<ServerDetailPage> createState() => _ServerDetailPageState();
}

class _ServerDetailPageState extends State<ServerDetailPage> {
  /// null = 检测中。
  bool? _online;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _checkStatus();
  }

  Future<void> _checkStatus() async {
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final ok = await subsonic.ping();
    if (!mounted) return;
    setState(() => _online = ok);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final profile = widget.profile;
    final info = ServerFamilyInfo.of(profile);

    final library = Provider.of<LibraryProvider>(context);

    return SettingsSubPage(
      title: l10n.serverDetail,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuoboSpacing.pageX,
          LuoboSpacing.pageY,
          LuoboSpacing.pageX,
          LuoboSpacing.pageBottom,
        ),
        children: [
          // ── 头图：服务器色渐变 + 徽标 + 名称 ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: LuoboSpacing.headerY,
            ),
            decoration: BoxDecoration(
              borderRadius: LuoboRadius.cardR,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  info.color.withValues(alpha: 0.85),
                  info.color.withValues(alpha: 0.45),
                ],
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: LuoboAccent.onAccent.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(LuoboRadius.card),
                  ),
                  child: Icon(
                    info.icon,
                    color: LuoboAccent.onAccent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  profile.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuoboType.headerTitle.copyWith(
                    color: LuoboAccent.onAccent,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  info.label,
                  style: LuoboType.headerCaption.copyWith(
                    color: LuoboAccent.onAccent.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: LuoboSpacing.cardGap),

          // ── 统计卡（仅当前服务器有实时数据） ──────────────────────────
          if (widget.isActive)
            LuoboCard(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: LuoboSpacing.cardPadY,
                  ),
                  child: Row(
                    children: [
                      _stat(
                        context,
                        icon: AppIcons.album,
                        label: l10n.albums,
                        value: '${library.cachedAllAlbums.length}',
                      ),
                      _stat(
                        context,
                        icon: AppIcons.music,
                        label: l10n.songs,
                        value: '${library.cachedAllSongs.length}',
                      ),
                      _stat(
                        context,
                        icon: AppIcons.artist,
                        label: l10n.artists,
                        value: '${library.artists.length}',
                      ),
                    ],
                  ),
                ),
                const LuoboDivider(indent: LuoboSpacing.rowX),
                LuoboRow(
                  title: l10n.serverStatus,
                  showChevron: false,
                  trailing: _statusValue(context, c),
                ),
              ],
            ),

          // ── 服务器信息卡 ───────────────────────────────────────────────
          LuoboCard(
            children: [
              LuoboRow(
                title: l10n.nameLabel,
                value: profile.displayName,
                showChevron: false,
              ),
              const LuoboDivider(indent: LuoboSpacing.rowX),
              LuoboRow(
                title: l10n.serverUrl,
                value: profile.serverUrl,
                showChevron: false,
              ),
              if (profile.hasLocalUrl) ...[
                const LuoboDivider(indent: LuoboSpacing.rowX),
                LuoboRow(
                  title: l10n.lanUrl,
                  value: profile.localUrl!,
                  showChevron: false,
                ),
              ],
              const LuoboDivider(indent: LuoboSpacing.rowX),
              LuoboRow(
                title: l10n.serverType,
                value: info.label,
                showChevron: false,
              ),
              const LuoboDivider(indent: LuoboSpacing.rowX),
              LuoboRow(
                title: l10n.version,
                value: (profile.serverVersion?.isNotEmpty ?? false)
                    ? profile.serverVersion!
                    : '—',
                showChevron: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final c = LuoboColors.of(context);
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 17, color: LuoboAccent.accent),
          const SizedBox(height: 6),
          Text(value, style: LuoboType.body.copyWith(color: c.fg)),
          const SizedBox(height: 2),
          Text(label, style: LuoboType.caption.copyWith(color: c.fg2)),
        ],
      ),
    );
  }

  Widget _statusValue(BuildContext context, LuoboColors c) {
    if (_online == null) {
      return const SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final l10n = AppLocalizations.of(context)!;
    final ok = _online!;
    final color = ok ? LuoboAccent.ok : LuoboAccent.warn(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          ok ? l10n.connected : l10n.notConnected,
          style: LuoboType.value.copyWith(color: color),
        ),
      ],
    );
  }
}
