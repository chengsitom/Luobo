import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/artist.dart';
import '../providers/library_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';
import '../utils/artist_stats.dart';
import '../widgets/luobo/list_rows.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import 'search_screen.dart';

/// 艺术家列表（2026-10-23）—— 与**搜索结果「歌手」tab 同款**：
/// 复用 `ArtistTile`（圆形头像 + 名字 + chevron）行。
///
/// 排序仍在「共 N 位歌手」行右侧（名称 / 歌曲数 / 专辑数）；歌曲数/专辑数
/// 只用于排序，不在行内显示（搜索结果的行样式没有副题）。
class ArtistsListScreen extends StatefulWidget {
  const ArtistsListScreen({super.key});

  @override
  State<ArtistsListScreen> createState() => _ArtistsListScreenState();
}

enum _ArtistSortField { name, songs, albums }

class _ArtistsListScreenState extends State<ArtistsListScreen> {
  static const double _countRowHeight = 44;

  _ArtistSortField _sortField = _ArtistSortField.name;
  bool _sortAscending = true;
  final _sortAnchor = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // ⚠️ 在 Scaffold 之前算好：body 内的 MediaQuery.padding 已被叠加 AppBar 高度。
    final topInset = listTopInset(context);
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: LuoboListTopBar(
        actions: [
          LuoboTopSearchButton(
            onTap: () =>
                NavigationHelper.push(context, const SearchScreen()),
          ),
        ],
      ),
      body: Consumer<LibraryProvider>(
        builder: (context, libraryProvider, _) {
          final source = libraryProvider.artists;
          if (source.isEmpty) {
            return LuoboEmptyState(message: l10n.artists);
          }

          final songCounts = ArtistStats.songCounts(source, libraryProvider);
          final albumCounts = ArtistStats.albumCounts(source, libraryProvider);
          final artists = _sortedArtists(source, songCounts, albumCounts);

          return ListView.builder(
            padding: EdgeInsets.only(top: topInset, bottom: 100),
            itemCount: artists.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _CountRow(
                  count: artists.length,
                  sortAnchorKey: _sortAnchor,
                  onSort: _showSortMenu,
                );
              }
              final i = index - 1;
              final artist = artists[i];
              return Column(
                children: [
                  ArtistListTile(
                    artist: artist,
                    songCount: songCounts[artist.id] ?? 0,
                    albumCount: albumCounts[artist.id] ?? 0,
                  ),
                  if (i < artists.length - 1) const LuoboSongDivider(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Artist> _sortedArtists(
    List<Artist> source,
    Map<String, int> songCounts,
    Map<String, int> albumCounts,
  ) {
    int compare(Artist a, Artist b) {
      switch (_sortField) {
        case _ArtistSortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _ArtistSortField.songs:
          return (songCounts[a.id] ?? 0).compareTo(songCounts[b.id] ?? 0);
        case _ArtistSortField.albums:
          return (albumCounts[a.id] ?? 0).compareTo(albumCounts[b.id] ?? 0);
      }
    }

    final list = source.toList();
    list.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return list;
  }

  Future<void> _showSortMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboAnchoredMenu<_ArtistSortField>(
      context: context,
      anchorKey: _sortAnchor,
      selected: _sortField,
      items: [
        LuoboAnchoredMenuItem(
          value: _ArtistSortField.name,
          label: l10n.sortByName,
        ),
        LuoboAnchoredMenuItem(
          value: _ArtistSortField.songs,
          label: l10n.sortBySongCount,
        ),
        LuoboAnchoredMenuItem(
          value: _ArtistSortField.albums,
          label: l10n.sortByAlbumCount,
        ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == _sortField) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = picked;
        _sortAscending = true;
      }
    });
  }
}

/// 计数行（44dp）：「共 N 位歌手」+ 右侧排序图标。
class _CountRow extends StatelessWidget {
  final int count;
  final GlobalKey sortAnchorKey;
  final VoidCallback onSort;

  const _CountRow({
    required this.count,
    required this.sortAnchorKey,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: _ArtistsListScreenState._countRowHeight,
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                l10n.artistsTotal(count),
                style: LuoboType.body.copyWith(fontSize: 14, color: c.fg2),
              ),
            ),
            GestureDetector(
              key: sortAnchorKey,
              onTap: onSort,
              child: Icon(Icons.sort_rounded, size: 22, color: c.fg2),
            ),
          ],
        ),
      ),
    );
  }
}
