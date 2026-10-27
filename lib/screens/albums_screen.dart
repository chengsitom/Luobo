import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/album.dart';
import '../providers/library_provider.dart';
import '../services/subsonic_service.dart';
import '../widgets/widgets.dart';
import '../utils/navigation_helper.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import '../l10n/app_localizations.dart';
import 'album_screen.dart';
import 'search_screen.dart';

class AlbumsScreen extends StatefulWidget {
  const AlbumsScreen({super.key});

  @override
  State<AlbumsScreen> createState() => _AlbumsScreenState();
}

enum _AlbumSortField { name, artist, year }

class _AlbumsScreenState extends State<AlbumsScreen> {
  final List<Album> _albums = [];
  bool _isLoading = true;
  bool _hasMore = false;
  int _offset = 0;
  static const int _pageSize = 100;

  final ScrollController _scrollController = ScrollController();

  _AlbumSortField _sortField = _AlbumSortField.name;
  bool _sortAscending = true;
  final _sortAnchor = GlobalKey();

  List<Album> get _sortedAlbums {
    int compare(Album a, Album b) {
      switch (_sortField) {
        case _AlbumSortField.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _AlbumSortField.artist:
          return (a.artist ?? '').toLowerCase().compareTo(
                (b.artist ?? '').toLowerCase(),
              );
        case _AlbumSortField.year:
          return (a.year ?? 0).compareTo(b.year ?? 0);
      }
    }

    final list = List<Album>.from(_albums);
    list.sort((a, b) => _sortAscending ? compare(a, b) : compare(b, a));
    return list;
  }

  Future<void> _showSortMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboAnchoredMenu<_AlbumSortField>(
      context: context,
      anchorKey: _sortAnchor,
      selected: _sortField,
      items: [
        LuoboAnchoredMenuItem(
          value: _AlbumSortField.name,
          label: l10n.sortByName,
        ),
        LuoboAnchoredMenuItem(
          value: _AlbumSortField.artist,
          label: l10n.sortByArtist,
        ),
        LuoboAnchoredMenuItem(
          value: _AlbumSortField.year,
          label: l10n.year,
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

  @override
  void initState() {
    super.initState();
    _loadAlbums();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 500) {
      _loadMore();
    }
  }

  /// 2026-10-23：**缓存优先**。
  ///
  /// 旧实现每次进页面都 `getArtists()` 后**串行**对前 20 位歌手逐个
  /// `getArtistAlbums()`（20 次网络往返）才开始渲染 —— 这就是「每次都要等几秒」。
  /// 曲库本身已全量同步进 SQLite（`cachedAllAlbums`），直接同步读缓存即可
  /// 首帧出图；只有缓存为空（首次同步前）才走网络。
  Future<void> _loadAlbums() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final cached = libraryProvider.cachedAllAlbums.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    if (cached.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _albums
          ..clear()
          ..addAll(cached);
        _isLoading = false;
        _hasMore = false;
      });
      return;
    }

    await _loadFromServer(reset: true);
  }

  /// 服务端兜底：`getAlbumList2(alphabeticalByName)` 分页 —— 一次请求拿 100 张，
  /// 比「逐歌手」快一个量级。
  Future<void> _loadFromServer({required bool reset}) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      if (reset) _offset = 0;
      final page = await subsonicService.getAlbumList(
        type: 'alphabeticalByName',
        size: _pageSize,
        offset: _offset,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _albums.clear();
        _albums.addAll(page);
        _offset += page.length;
        _hasMore = page.length == _pageSize;
        _isLoading = false;
      });
      if (reset && page.isEmpty) await _loadFromArtists();
    } catch (e) {
      debugPrint('Error loading album list: $e');
      if (reset) await _loadFromArtists();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 最后兜底（服务端不支持 getAlbumList2 时）：逐歌手取专辑，但**并发分批**
  /// （每批 8 个），不再串行 20 次。
  Future<void> _loadFromArtists() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      final artists = await subsonicService.getArtists();
      final collected = <String, Album>{};
      for (var i = 0; i < artists.length; i += 8) {
        final chunk = artists.skip(i).take(8);
        final results = await Future.wait(
          chunk.map(
            (a) => subsonicService
                .getArtistAlbums(a.id)
                .catchError((_) => <Album>[]),
          ),
        );
        for (final list in results) {
          for (final album in list) {
            collected[album.id] = album;
          }
        }
        if (!mounted) return;
        setState(() {
          _albums
            ..clear()
            ..addAll(collected.values.toList()
              ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
              ));
          _isLoading = false;
          _hasMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading albums per artist: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;
    setState(() => _isLoading = true);
    await _loadFromServer(reset: false);
  }

  @override
  Widget build(BuildContext context) {
    // ⚠️ 必须在 Scaffold 之前算：body 内的 MediaQuery.padding 已被叠加
    // AppBar 高度，在 Builder/Consumer 里算会多出 56dp（专辑计数行下沉的根因）。
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
      body: _albums.isEmpty && _isLoading
          ? ListView.builder(
              padding: EdgeInsets.only(top: topInset, bottom: 100),
              itemCount: 10,
              itemBuilder: (context, index) => const SongTileShimmer(),
            )
          : Builder(
              builder: (context) {
                final sorted = _sortedAlbums;
                // 整页滚动：计数行作为第 0 项，随列表一起滚（与歌手/全部歌曲
                // 一致，内容从悬浮圆钮下方流过）。
                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(top: topInset, bottom: 100),
                  itemCount: sorted.length + 1 + (_hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!
                                    .albumsTotal(_albums.length),
                                style: LuoboType.body.copyWith(
                                  fontSize: 14,
                                  color: LuoboColors.of(context).fg2,
                                ),
                              ),
                            ),
                            GestureDetector(
                              key: _sortAnchor,
                              onTap: _showSortMenu,
                              child: Icon(
                                Icons.sort_rounded,
                                size: 22,
                                color: LuoboColors.of(context).fg2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    final i = index - 1;
                    if (i >= sorted.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: [
                        _AlbumRow(album: sorted[i]),
                        if (i < sorted.length - 1) const LuoboSongDivider(),
                      ],
                    );
                  },
                );
              },
            ),
    );
  }
}


/// 专辑行（64dp，与歌手列表同款）：方形封面 48 + 名称 + 「歌手 · 年份」+ chevron。
class _AlbumRow extends StatelessWidget {
  final Album album;

  const _AlbumRow({required this.album});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      if ((album.artist ?? '').isNotEmpty) album.artist!,
      if (album.year != null) l10n.albumYear(album.year!),
    ].join(' · ');

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AlbumScreen(albumId: album.id)),
      ),
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AlbumArtwork(
                coverArt: album.coverArt,
                size: 48,
                borderRadius: 6,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                    ],
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
