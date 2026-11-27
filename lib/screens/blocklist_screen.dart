import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/library_provider.dart';
import '../services/blocklist_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/block_sheet.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/settings_sub_page.dart';

/// 设置 → 内容过滤：已屏蔽内容的唯一管理入口。
///
/// 为什么它是硬需求：被「彻底屏蔽」的艺人/专辑在普通列表里点不进去，
/// 这里是用户**唯一**能解除屏蔽的地方（见方案 R4.4）。
///
/// 样式对齐「资料库内容列表」（歌曲/专辑/艺术家/歌单）而非设置页：
/// 64dp 行 + 48px 类型图标块 + 16/600 标题 + 12px 副标题 + 行尾 ⋮，
/// 分组用内容页同款「计数行 + 分隔线」，不用 LuoboGroup 白卡。
/// 屏蔽条目的对象本质（歌曲/艺人/专辑/歌单）与资料库同类，观感应一致
///（2026-11-23 用户反馈：旧版 LuoboRow 太像设置页）。
///
/// 顶栏仍是 SettingsSubPage（全局渐显标题），只是列表 body 换了一套视觉。
class BlocklistScreen extends StatelessWidget {
  const BlocklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 与 SettingsSubPage 同一个 build → 用 listTopInset；body 自身就是滚动视图，
    // 顶部留白落在这里，内容才会从返回圆钮下方流过。
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

          final songs = entries.where((e) => e.kind == BlockKind.song);
          final artists = entries.where((e) => e.kind == BlockKind.artist);
          final albums = entries.where((e) => e.kind == BlockKind.album);
          final playlists = entries.where((e) => e.kind == BlockKind.playlist);

          return ListView(
            padding: LuoboSpacing.scrollPadding(
              context,
              top: topInset + LuoboSpacing.pageY,
              bottom: LuoboSpacing.pageBottomWithStrip(context),
            ),
            children: [
              if (songs.isNotEmpty)
                ..._section(
                  context,
                  '${l10n.songs} · ${songs.length}',
                  [for (final e in songs) _tile(context, e)],
                ),
              if (artists.isNotEmpty)
                ..._section(
                  context,
                  '${l10n.artists} · ${artists.length}',
                  [for (final e in artists) _tile(context, e)],
                ),
              if (albums.isNotEmpty)
                ..._section(
                  context,
                  '${l10n.albums} · ${albums.length}',
                  [for (final e in albums) _tile(context, e)],
                ),
              if (playlists.isNotEmpty)
                ..._section(
                  context,
                  '${l10n.playlists} · ${playlists.length}',
                  [
                    for (final e in playlists)
                      _tile(
                        context,
                        e,
                        playlistGone: canJudgePlaylists &&
                            !rawPlaylistIds.contains(e.targetId),
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  /// 内容页同款分组：卡外「计数行」+ 1px 分隔 + 行间 [LuoboSongDivider]。
  /// 不用 LuoboGroup 的白卡/圆角/玫红图标——那是设置页的视觉语言。
  List<Widget> _section(BuildContext context, String title, List<Widget> rows) {
    final c = LuoboColors.of(context);
    return [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Text(
          title,
          style: LuoboType.body.copyWith(fontSize: 14, color: c.fg2),
        ),
      ),
      const Divider(height: 1),
      for (var i = 0; i < rows.length; i++) ...[
        rows[i],
        if (i < rows.length - 1) const LuoboSongDivider(),
      ],
    ];
  }

  Widget _tile(
    BuildContext context,
    BlockEntry entry, {
    bool playlistGone = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
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

    return _BlockEntryTile(
      entry: entry,
      subtitle: subtitle,
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

/// 与资料库内容行同构的屏蔽条目行：
/// 48px 类型图标块 + 12 间距 + 16/600 标题 + 12px 副标题 + 行尾 ⋮，整行 64dp。
///
/// 不用封面：BlockEntry 无封面字段，反查库缓存会在条目被删时退化成占位；
/// 改用灰调类型图标块占住封面位，标题起点（16+48+12=76）与
/// [LuoboSongDivider] 的缩进严格对齐内容列表。
/// 档位靠副标题文案（彻底屏蔽 / 仅从漫游排除）区分，不再用玫红图标。
class _BlockEntryTile extends StatelessWidget {
  final BlockEntry entry;
  final String subtitle;
  final VoidCallback onTap;

  const _BlockEntryTile({
    required this.entry,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final isArtist = entry.kind == BlockKind.artist;
    final icon = switch (entry.kind) {
      BlockKind.artist => Icons.person_rounded,
      BlockKind.album => Icons.album_rounded,
      BlockKind.playlist => Icons.queue_music_rounded,
      BlockKind.song => Icons.music_note_rounded,
    };

    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.card,
                  // 艺人圆形头像、歌曲/专辑/歌单方形封面，沿用内容列表的形状约定。
                  borderRadius: BorderRadius.circular(isArtist ? 24 : 6),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 22, color: c.fg3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name.isEmpty ? entry.targetId : entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 行尾 ⋮ 与整行同效（都打开屏蔽设置 sheet），点击靠 opaque
              // 自身消费，不会冒泡触发整行 onTap 而弹两次。
              GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(AppIcons.moreV, size: 18, color: c.fg2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
