import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/blocklist_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/block_sheet.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/settings_sub_page.dart';

/// 设置 → 内容过滤：已屏蔽内容的唯一管理入口。
///
/// 为什么它是硬需求：被「彻底屏蔽」的艺人/专辑在普通列表里点不进去，
/// 这里是用户**唯一**能解除屏蔽的地方（见方案 R4.4）。
class BlocklistScreen extends StatelessWidget {
  const BlocklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 与 SettingsSubPage 同一个 build → 用 listTopInset（自己加 56）；
    // listScrollTopInset 是给"body 内部再构造滚动视图"的场景用的。
    final topInset = listTopInset(context);

    return SettingsSubPage(
      title: l10n.blocklistTitle,
      body: AnimatedBuilder(
        animation: BlocklistService.instance,
        builder: (context, _) {
          final blocklist = BlocklistService.instance;
          final entries = blocklist.entries;

          if (entries.isEmpty) {
            return Padding(
              padding: EdgeInsets.only(top: topInset + 80),
              child:
                  Center(child: LuoboEmptyState(message: l10n.blocklistEmpty)),
            );
          }

          // 规则指向的歌单可能在别的设备被删了：标出来，否则用户会疑惑
          // "为什么这条规则还在"。列表为空（还没加载）时不做判断。
          final rawPlaylistIds = context
              .watch<LibraryProvider>()
              .rawPlaylists
              .map((p) => p.id)
              .toSet();
          final canJudgePlaylists = rawPlaylistIds.isNotEmpty;

          final artists = entries.where((e) => e.kind == BlockKind.artist);
          final albums = entries.where((e) => e.kind == BlockKind.album);
          final playlists = entries.where((e) => e.kind == BlockKind.playlist);

          return ListView(
            padding: EdgeInsets.only(top: topInset + 8, bottom: 40),
            children: [
              if (artists.isNotEmpty) ...[
                _sectionHeader(context, l10n.artists, artists.length),
                for (final e in artists) _tile(context, e),
              ],
              if (albums.isNotEmpty) ...[
                _sectionHeader(context, l10n.albums, albums.length),
                for (final e in albums) _tile(context, e),
              ],
              if (playlists.isNotEmpty) ...[
                _sectionHeader(context, l10n.playlists, playlists.length),
                for (final e in playlists)
                  _tile(
                    context,
                    e,
                    playlistGone: canJudgePlaylists &&
                        !rawPlaylistIds.contains(e.targetId),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String label, int count) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        '$label · $count',
        style: LuoboType.caption.copyWith(color: c.fg2),
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    BlockEntry entry, {
    bool playlistGone = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final blocklist = BlocklistService.instance;
    final isHidden = entry.mode == BlockMode.hidden;
    final members = blocklist.membersOf(entry.targetId);

    // 歌单额外标出"排除了多少首"，让用户能判断规则是否生效。
    var subtitle = entry.kind == BlockKind.playlist && members != null
        ? '${isHidden ? l10n.blockModeHide : l10n.blockModeMute} · '
            '${l10n.songsCount(members.length)}'
        : (isHidden ? l10n.blockModeHide : l10n.blockModeMute);
    if (playlistGone) {
      subtitle = '$subtitle · ${l10n.blocklistPlaylistGone}';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Icon(
        isHidden ? Icons.visibility_off_rounded : Icons.shuffle_rounded,
        size: 20,
        color: c.fg2,
      ),
      title: Text(
        entry.name.isEmpty ? entry.targetId : entry.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: LuoboType.caption.copyWith(color: c.fg2),
      ),
      onTap: () => showBlockSheet(
        context,
        kind: entry.kind,
        targetId: entry.targetId,
        name: entry.name,
        // 带上已知成员：在管理页切档时不要丢掉已展开的名单、也别再重拉一次。
        members: members,
        songCount: entry.memberCount,
      ),
    );
  }
}
