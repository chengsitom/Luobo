import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/artist.dart';
import '../providers/library_provider.dart';
import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import 'artist_screen.dart';
import 'search_screen.dart';

/// 艺术家列表（2026-10-23）—— 对齐 fnos「歌手」列表：
/// 圆形头像 + 名字 + 「N 首歌 · M 张专辑」的行式列表。
///
/// 2026-10-23 二次调整：**去掉右侧 A–Z 字母检索条**（用户要求），列表就是一条
/// 纯滚动列表；排序仍在「共 N 位歌手」行右侧的图标里。
class ArtistsListScreen extends StatefulWidget {
  const ArtistsListScreen({super.key});

  @override
  State<ArtistsListScreen> createState() => _ArtistsListScreenState();
}

enum _ArtistSortField { name, songs, albums }

class _ArtistsListScreenState extends State<ArtistsListScreen> {
  static const double _rowHeight = 64;
  static const double _countRowHeight = 44;

  // 排序（fnos v12_0025：歌手名 / 歌曲数 / 专辑数，可切换方向）。
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

          final songCounts = _songCountsByArtist(source, libraryProvider);
          final albumCounts = _albumCountsByArtist(source, libraryProvider);
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
                  _ArtistRow(
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

  /// 每位歌手的歌曲数。
  ///
  /// ⚠️ 只按 `song.artistId` 统计会缺两类：①服务端 artists 与 tracks 的 id
  /// 体系不一致（道理鱼）；②合唱曲里非第一顺位的歌手（`artistId` 只存主艺人）。
  /// 所以同时按「歌手名」统计，最终取两者较大值。
  Map<String, int> _songCountsByArtist(
    List<Artist> artists,
    LibraryProvider libraryProvider,
  ) {
    final idCounts = <String, int>{};
    final nameCounts = <String, int>{};
    final albumIdSums = <String, int>{};
    final albumNameSums = <String, int>{};

    void addName(String name) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty) return;
      nameCounts[key] = (nameCounts[key] ?? 0) + 1;
    }

    for (final song in libraryProvider.cachedAllSongs) {
      final id = song.artistId;
      if (id != null && id.isNotEmpty) {
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
      final participants = song.artistParticipants;
      if (participants != null && participants.isNotEmpty) {
        for (final p in participants) {
          addName(p.name);
        }
      } else {
        final artistName = song.artist;
        if (artistName != null && artistName.isNotEmpty) {
          for (final part
              in artistName.split(RegExp(r'\s*(?:/|,|&|、|;)\s*'))) {
            addName(part);
          }
        }
      }
    }

    // 另一路口径：把该歌手各专辑的 `songCount` 累加（服务端索引的权威值，
    // 曲库只同步了部分歌曲时比逐曲统计更准）。
    for (final album in libraryProvider.cachedAllAlbums) {
      final count = album.songCount ?? 0;
      if (count <= 0) continue;
      final id = album.artistId;
      if (id != null && id.isNotEmpty) {
        albumIdSums[id] = (albumIdSums[id] ?? 0) + count;
      }
      final name = album.artist?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        albumNameSums[name] = (albumNameSums[name] ?? 0) + count;
      }
    }

    return {
      for (final artist in artists)
        artist.id: _max4(
          idCounts[artist.id] ?? 0,
          nameCounts[artist.name.trim().toLowerCase()] ?? 0,
          albumIdSums[artist.id] ?? 0,
          albumNameSums[artist.name.trim().toLowerCase()] ?? 0,
        ),
    };
  }

  /// 每位歌手的专辑数：优先用服务端给的 `albumCount`，否则按 id / 名字统计。
  Map<String, int> _albumCountsByArtist(
    List<Artist> artists,
    LibraryProvider libraryProvider,
  ) {
    final idCounts = <String, int>{};
    final nameCounts = <String, int>{};
    for (final album in libraryProvider.cachedAllAlbums) {
      final id = album.artistId;
      if (id != null && id.isNotEmpty) {
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
      final name = album.artist?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        nameCounts[name] = (nameCounts[name] ?? 0) + 1;
      }
    }
    return {
      for (final artist in artists)
        artist.id: artist.albumCount ??
            _max(idCounts[artist.id] ?? 0,
                nameCounts[artist.name.trim().toLowerCase()] ?? 0),
    };
  }

  static int _max(int a, int b) => a > b ? a : b;

  static int _max4(int a, int b, int c, int d) =>
      _max(_max(a, b), _max(c, d));

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

/// 计数行（44dp）：与 fnos 一致，顶部「共 N 位歌手」+ 右侧排序图标。
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

/// 歌手行（64dp）：圆形头像 48 + 名字 16/600 + 「N 首歌 · M 张专辑」12 + chevron。
/// 分割线左缩 76（= 16 + 48 + 12，从名字起点开始），与 fnos 一致。
class _ArtistRow extends StatelessWidget {
  final Artist artist;
  final int songCount;
  final int albumCount;

  const _ArtistRow({
    required this.artist,
    required this.songCount,
    required this.albumCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return InkWell(
      onTap: () =>
          NavigationHelper.push(context, ArtistScreen(artistId: artist.id)),
      child: SizedBox(
        height: _ArtistsListScreenState._rowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ArtistAvatar(artist: artist),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
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
                      AppLocalizations.of(context)!
                          .artistStats(songCount, albumCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18, color: c.fg3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆形头像 48：网络图（artistImageUrl / coverArt / 专辑封面）→ 首字母占位。
class _ArtistAvatar extends StatelessWidget {
  final Artist artist;

  const _ArtistAvatar({required this.artist});

  @override
  Widget build(BuildContext context) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final cover = libraryProvider.resolveArtistCover(artist);
    final url = cover.hasImage
        ? cover.imageUrl
        : (cover.hasFallback ? cover.fallbackImageUrl : null);

    Widget placeholder() => _LetterAvatar(name: artist.name);

    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                cacheManager: coverCacheManager,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => placeholder(),
                errorWidget: (_, __, ___) {
                  if (cover.hasFallback && cover.fallbackImageUrl != url) {
                    return CachedNetworkImage(
                      imageUrl: cover.fallbackImageUrl!,
                      cacheManager: coverCacheManager,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 120),
                      placeholder: (_, __) => placeholder(),
                      errorWidget: (_, __, ___) => placeholder(),
                    );
                  }
                  return placeholder();
                },
              ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;

  const _LetterAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final letter = name.isEmpty ? '#' : name[0].toUpperCase();
    return Container(
      color: c.card,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: LuoboType.body.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.fg2,
        ),
      ),
    );
  }
}
