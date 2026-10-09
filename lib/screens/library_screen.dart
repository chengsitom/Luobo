import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lpinyin/lpinyin.dart';
import '../models/song.dart';
import '../models/album.dart';
import '../models/artist.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/local_music_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_surface.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/artist_grid_card.dart';
import '../utils/navigation_helper.dart';
import '../utils/image_cache.dart';
import '../utils/refresh_feedback.dart';
import 'album_screen.dart';
import 'package:luobo/screens/playlist_screen.dart';
import 'favorites_screen.dart';
import 'playlists_screen.dart';
import 'ai_playlist_screen.dart';
import 'settings_root_screen.dart';
import 'library_search_delegate.dart';
import 'artist_screen.dart';
import 'radio_screen.dart';
import 'audiobook_list_screen.dart';
import 'all_songs_screen.dart';
import '../l10n/app_localizations.dart';
import '../widgets/album_artwork.dart' show isLocalFilePath;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  /// 顶部 TabBar 控制器：与 TabBarView 共享；可空 + `_tabInited` 首帧防护，
  /// 本地模式 4⇄6 tab 时由 `_ensureTabController` 重建。
  TabController? _tabController;
  bool _tabInited = false;

  /// 显式监听 LibraryProvider 以感知本地/服务端模式切换（State 层全用
  /// listen: false，didChangeDependencies 不会被 notify 触发）。
  LibraryProvider? _libraryProvider;

  // 每页一个常驻 ScrollController：TabBarView 会回收视口外页面，
  // controller 挂在 State 上常驻，滚动位置不随页面重建丢失。
  final ScrollController _artistsScrollController = ScrollController();
  final ScrollController _albumsScrollController = ScrollController();
  final ScrollController _songsScrollController = ScrollController();
  final ScrollController _favesScrollController = ScrollController();
  final ScrollController _genresScrollController = ScrollController();
  final ScrollController _yearsScrollController = ScrollController();

  // Artists tab scrubber
  String? _selectedLetter;
  Map<String, int> _letterIndexMap = {};

  /// 是否处于 Artists tab：从别的 tab 切回 Artists 时预热当前屏
  /// 封面（磁盘命中→解码进内存），避免首屏逐格异步读盘"一张张冒出来"。
  bool _wasArtistsTab = false;

  @override
  void initState() {
    super.initState();
    _libraryProvider = Provider.of<LibraryProvider>(context, listen: false);
    _libraryProvider!.addListener(_onLibraryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _ensureTabController();
  }

  void _ensureTabController() {
    final filters = _getFilters(context);
    if (!_tabInited || _tabController!.length != filters.length) {
      final oldIndex = _tabController?.index ?? 0;
      final index = oldIndex.clamp(0, filters.length - 1);
      _tabController?.dispose();
      _tabController = TabController(
        length: filters.length,
        vsync: this,
        initialIndex: index,
      )..addListener(_onTabIndexChanged);
      _tabInited = true;
    }
  }

  /// LibraryProvider 通知：本地模式 4⇄6 切换后重建 TabController。
  void _onLibraryChanged() {
    final filters = _getFilters(context);
    if (_tabController == null || _tabController!.length != filters.length) {
      setState(_ensureTabController);
    }
  }

  /// Tab 落定后同步预热逻辑：切回 Artists 时预载当前屏封面。
  void _onTabIndexChanged() {
    if (_tabController!.indexIsChanging) return;
    final filters = _getFilters(context);
    final isArtists = filters[_tabController!.index] == 'Artists';
    if (!isArtists) {
      _wasArtistsTab = false;
      return;
    }
    if (_wasArtistsTab) return;
    _wasArtistsTab = true;
    _maybePreloadArtistCovers(
      Provider.of<LibraryProvider>(context, listen: false),
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _libraryProvider?.removeListener(_onLibraryChanged);
    _artistsScrollController.dispose();
    _albumsScrollController.dispose();
    _songsScrollController.dispose();
    _favesScrollController.dispose();
    _genresScrollController.dispose();
    _yearsScrollController.dispose();
    super.dispose();
  }

  // Reuse generated cover URLs across rebuilds (stable per server+coverArt+size).
  static final Map<String, String> _coverUrlCache = {};

  static String _coverUrl(SubsonicService service, String coverArt) {
    final key = '${service.activeBaseUrl}_${coverArt}_$kCoverArtRequestSize';
    return _coverUrlCache.putIfAbsent(
      key,
      () => service.getCoverArtUrl(coverArt, size: kCoverArtRequestSize),
    );
  }

  /// First letter grouping for the Artists tab index. Uses pinyin for
  /// Chinese characters so 周杰伦 → Z, 韩红 → H, etc. ASCII A-Z stay as
  /// themselves. Everything else (numbers, symbols) goes to '#'.
  static String _firstLetter(String name) {
    if (name.isEmpty) return '#';
    final first = name[0];
    final code = first.codeUnitAt(0);
    // ASCII A-Z / a-z
    if ((code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A)) {
      return first.toUpperCase();
    }
    // Chinese → pinyin first letter (getShortPinyin returns lowercase)
    if (RegExp(r'[\u4e00-\u9fff]').hasMatch(first)) {
      try {
        final py = PinyinHelper.getShortPinyin(first);
        if (py.isNotEmpty) {
          final letter = py[0].toUpperCase();
          if (letter.codeUnitAt(0) >= 0x41 && letter.codeUnitAt(0) <= 0x5A) {
            return letter;
          }
        }
      } catch (_) {}
    }
    return '#';
  }

  List<String> _getFilters(BuildContext context) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    if (libraryProvider.isLocalOnlyMode) {
      return ['Artists', 'Albums', 'Songs', 'Faves', 'Genres', 'Years'];
    }
    return ['Artists', 'Albums', 'Songs', 'Faves'];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final filters = _getFilters(context);
    final l10n = AppLocalizations.of(context)!;
    final filterLabels = {
      'Faves': l10n.faves,
      'Albums': l10n.filterAlbums,
      'Artists': l10n.filterArtists,
      'Songs': l10n.songs,
      'Genres': l10n.genres,
      'Years': l10n.years,
    };

    return Scaffold(
      body: Column(
        children: [
          // ── 共享固定头部：标题栏（原 SliverAppBar pinned+floating 实为常驻）──
          AppBar(
            toolbarHeight: 56,
            centerTitle: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            surfaceTintColor: Colors.transparent,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: Text(
              l10n.yourLibrary,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            actions: [
              Consumer<LibraryProvider>(
                builder: (context, lp, _) {
                  final running = lp.refreshStatus == RefreshStatus.running;
                  return IconButton(
                    icon: running
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            CupertinoIcons.refresh,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                    tooltip: AppLocalizations.of(context)!.refresh,
                    onPressed: () => _handleRefresh(context),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.search,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showLibrarySearch(context),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.plus,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showAddPlaylistMenu(context),
              ),
              IconButton(
                icon: Icon(
                  CupertinoIcons.gear,
                  color: isDark ? Colors.white : Colors.black,
                ),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),
          // ── 共享固定头部：顶部 TabBar（网易新闻式：文字标签 + 下划线指示器）──
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.black38,
            labelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: const TextStyle(fontSize: 15),
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(
                color: theme.colorScheme.primary,
                width: 2.5,
              ),
              borderRadius: BorderRadius.circular(3),
            ),
            dividerColor:
                isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            tabs: [for (final f in filters) Tab(text: filterLabels[f])],
          ),
          // ── 内容：左右滑动切换的页面（每页独立滚动，ValueKey 防错位复用）──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                for (final f in filters)
                  KeyedSubtree(key: ValueKey(f), child: _buildPage(f)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(String filter) {
    switch (filter) {
      case 'Artists':
        return _buildArtistsPage();
      case 'Faves':
        return _buildFavesPage();
      default:
        return _buildItemsPage(filter);
    }
  }

  ScrollController _controllerFor(String filter) {
    switch (filter) {
      case 'Albums':
        return _albumsScrollController;
      case 'Songs':
        return _songsScrollController;
      case 'Faves':
        return _favesScrollController;
      case 'Genres':
        return _genresScrollController;
      case 'Years':
        return _yearsScrollController;
      default:
        return _artistsScrollController;
    }
  }

  /// Artists 页：常听 shelf + 字母分组方形网格 + 右缘字母索引。
  /// 数据来自 LibraryProvider（Consumer 监听），滚动位置由常驻的
  /// `_artistsScrollController` 保留；切换回本页的封面预热在
  /// `_onTabIndexChanged` 中触发。
  Widget _buildArtistsPage() {
    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, _) {
        final artists = libraryProvider.artists.toList()
          ..sort((a, b) => a.name.compareTo(b.name));
        if (artists.isEmpty) {
          return _LibraryEmptyState(
            isLocalMode: libraryProvider.isLocalOnlyMode,
          );
        }
        final isDark = Theme.of(context).brightness == Brightness.dark;
        // 常听 TopN（本地播放统计，无历史则为空 → 不渲染 shelf）。
        final topArtists = libraryProvider.topArtists;
        final groups = <String, List<Artist>>{};
        for (final a in artists) {
          final letter = _firstLetter(a.name);
          groups.putIfAbsent(letter, () => []).add(a);
        }
        final letters = groups.keys.toList()..sort();
        final l10n = AppLocalizations.of(context)!;
        // Grid metrics: 列数由视口宽度推导，行高 = 卡宽 + 封面下
        // 8 + 固定 44px 文本区（ArtistGridCard 内文本区固定高度，
        // 与字体行高无关）。同时用于布局和右侧字母索引的偏移估算。
        final availWidth = MediaQuery.sizeOf(context).width - 16 * 2 - 28;
        final colCount = (availWidth / 140).floor().clamp(2, 6).toInt();
        final cardWidth = (availWidth - (colCount - 1) * 12) / colCount;
        final rowHeight = cardWidth + 52;
        const headerH = 30.0;
        // shelf 实际高：分组头(12+20+8) + 两排网格 168 + 尾间距 12 ≈ 220。
        const shelfH = 184.0;
        _letterIndexMap = {};
        double offset = topArtists.isEmpty ? 0 : shelfH + 36;
        for (final letter in letters) {
          _letterIndexMap[letter] = offset.round();
          offset += headerH;
          final rows = (groups[letter]!.length / colCount).ceil();
          offset += rows * rowHeight + 12;
        }
        return Stack(
          children: [
            ListView(
              controller: _artistsScrollController,
              // 右侧留 44 给字母索引条；左 16 对齐网格 padding；
              // 底部 150 避让迷你播放器。
              padding: const EdgeInsets.only(
                left: 16,
                right: 44,
                bottom: 150,
              ),
              children: [
                if (topArtists.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                    child: Text(
                      l10n.topArtistsTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                  SizedBox(
                    // 两排横滑：每排高 (168-8)/2 = 80，卡宽 170。
                    height: 168,
                    child: GridView.builder(
                      scrollDirection: Axis.horizontal,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 8,
                        mainAxisExtent: 170,
                      ),
                      itemCount: topArtists.length,
                      itemBuilder: (context, index) {
                        final top = topArtists[index];
                        return ArtistShelfCard(
                          artist: top.artist,
                          playCount: top.playCount,
                          onTap: () => _openArtist(top.artist),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                for (final letter in letters) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
                    child: Text(
                      letter,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: colCount,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                      childAspectRatio: cardWidth / rowHeight,
                    ),
                    itemCount: groups[letter]!.length,
                    itemBuilder: (context, index) {
                      final a = groups[letter]![index];
                      return ArtistGridCard(
                        artist: a,
                        onTap: () => _openArtist(a),
                        onPlayPressed: () => _playArtist(a),
                      );
                    },
                  ),
                ],
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _ArtistScrubber(
                letters: letters,
                selectedLetter: _selectedLetter,
                onLetterDown: (letter) {
                  final idx = _letterIndexMap[letter];
                  if (idx != null && _artistsScrollController.hasClients) {
                    _artistsScrollController.jumpTo(
                      idx.toDouble().clamp(
                            0.0,
                            _artistsScrollController.position.maxScrollExtent,
                          ),
                    );
                  }
                  setState(() => _selectedLetter = letter);
                },
                onLetterUp: () => setState(() => _selectedLetter = null),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Faves 页：文件夹磁贴 + 歌单/最近专辑列表。
  Widget _buildFavesPage() {
    return CustomScrollView(
      controller: _favesScrollController,
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              // Playlists folder
              _SpotifyLibraryTile(
                icon: CupertinoIcons.list_bullet,
                iconColor: const Color(0xFF3B82F6),
                title: AppLocalizations.of(context)!.playlists,
                subtitle: AppLocalizations.of(context)!.yourPlaylists,
                isGradient: false,
                onTap: () => _navigate(context, const PlaylistsScreen()),
              ),
              // Liked Songs folder
              _SpotifyLibraryTile(
                icon: CupertinoIcons.heart_fill,
                iconColor: const Color(0xFF8B5CF6),
                title: AppLocalizations.of(context)!.likedSongs,
                subtitle: AppLocalizations.of(context)!.playlist,
                isGradient: true,
                onTap: () => _navigate(context, const FavoritesScreen()),
              ),
              // All Songs folder
              _SpotifyLibraryTile(
                icon: CupertinoIcons.music_note_list,
                iconColor: const Color(0xFF34C759),
                title: AppLocalizations.of(context)!.songs,
                subtitle: AppLocalizations.of(context)!.songs,
                isGradient: false,
                onTap: () => _navigate(context, const AllSongsScreen()),
              ),
              // Liked Albums folder — 2026-10-08 删除（收藏专辑全删，见
              // `docs/首页快捷入口与漫游技术方案.md` §12.1）
              // Radio Stations folder — 道理鱼下换成「有声书」入口（§7.1）。
              Selector<AuthProvider, bool>(
                selector: (_, auth) => auth.config?.serverFamily == 'daoliyu',
                builder: (context, isDaoliyu, _) => _SpotifyLibraryTile(
                  icon: isDaoliyu
                      ? CupertinoIcons.book
                      : CupertinoIcons.antenna_radiowaves_left_right,
                  iconColor: const Color(0xFF34C759),
                  title: isDaoliyu
                      ? AppLocalizations.of(context)!.audiobooks
                      : AppLocalizations.of(context)!.radioStations,
                  subtitle: isDaoliyu
                      ? AppLocalizations.of(context)!.audiobooks
                      : AppLocalizations.of(context)!.internetRadio,
                  isGradient: false,
                  onTap: () => _navigate(
                    context,
                    isDaoliyu
                        ? const AudiobookListScreen()
                        : const RadioScreen(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Consumer<LibraryProvider>(
          builder: (context, libraryProvider, _) {
            final items = _getFilteredItems(context, libraryProvider, 'Faves');
            if (items.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _LibraryEmptyState(
                  isLocalMode: libraryProvider.isLocalOnlyMode,
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return _buildLibraryItem(context, item);
              }, childCount: items.length),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ],
    );
  }

  /// 通用列表页（Albums / Songs / Genres / Years 共用）。
  Widget _buildItemsPage(String filter) {
    return CustomScrollView(
      controller: _controllerFor(filter),
      slivers: [
        Consumer<LibraryProvider>(
          builder: (context, libraryProvider, _) {
            final items = _getFilteredItems(context, libraryProvider, filter);
            if (items.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: _LibraryEmptyState(
                  isLocalMode: libraryProvider.isLocalOnlyMode,
                ),
              );
            }
            return SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                return _buildLibraryItem(context, item);
              }, childCount: items.length),
            );
          },
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 150)),
      ],
    );
  }

  List<_LibraryItem> _getFilteredItems(
    BuildContext context,
    LibraryProvider provider,
    String filter,
  ) {
    final l10n = AppLocalizations.of(context)!;
    List<_LibraryItem> items = [];

    // Faves tab: show Playlists and Recent Albums
    if (filter == 'Faves') {
      // Add playlists
      items.addAll(
        provider.playlists.map(
          (p) => _LibraryItem(
            type: 'Playlist',
            id: p.id,
            name: p.name,
            subtitle: l10n.songsCount(p.songCount ?? 0),
            coverArt: p.coverArt,
          ),
        ),
      );
      // Add recent albums (limited to 10)
      final recent = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums.take(10).toList()
          : provider.recentAlbums.take(10).toList();
      items.addAll(
        recent.map(
          (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle:
                a.artistParticipants != null && a.artistParticipants!.isNotEmpty
                    ? a.artistParticipants!.map((r) => r.name).join(', ')
                    : (a.artist ?? ''),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    // Albums tab: show all albums
    if (filter == 'Albums') {
      final albums = provider.isLocalOnlyMode
          ? provider.cachedAllAlbums
          : (provider.cachedAllAlbums.isNotEmpty
              ? provider.cachedAllAlbums
              : provider.recentAlbums);
      items.addAll(
        albums.map(
          (a) => _LibraryItem(
            type: 'Album',
            id: a.id,
            name: a.name,
            subtitle: () {
              final artistStr = a.artistParticipants != null &&
                      a.artistParticipants!.isNotEmpty
                  ? a.artistParticipants!.map((r) => r.name).join(', ')
                  : (a.artist ?? '');
              if (a.year != null && artistStr.isNotEmpty) {
                return '$artistStr • ${a.year}';
              }
              return artistStr.isNotEmpty
                  ? artistStr
                  : (a.year?.toString() ?? '');
            }(),
            coverArt: a.coverArt,
          ),
        ),
      );
    }

    if (filter == 'Songs') {
      items.addAll(
        provider.cachedAllSongs.map(
          (s) => _LibraryItem(
            type: 'Song',
            id: s.id,
            name: s.title,
            subtitle: s.artist ?? '',
            coverArt: s.coverArt,
          ),
        ),
      );
    }

    if (filter == 'Genres') {
      final genreMap = <String, List<Song>>{};
      for (final s in provider.cachedAllSongs) {
        final g = (s.genre ?? 'Unknown').trim();
        if (g.isEmpty) continue;
        genreMap.putIfAbsent(g, () => []).add(s);
      }
      final sortedGenres = genreMap.keys.toList()..sort();
      items.addAll(
        sortedGenres.map(
          (g) => _LibraryItem(
            type: 'Genre',
            id: 'genre_$g',
            name: g,
            subtitle: l10n.songsCount(genreMap[g]!.length),
            coverArt: genreMap[g]!
                    .firstWhere(
                      (s) => s.coverArt != null,
                      orElse: () => genreMap[g]!.first,
                    )
                    .coverArt ??
                '',
          ),
        ),
      );
    }

    if (filter == 'Years') {
      final yearMap = <int, List<Album>>{};
      for (final a in provider.cachedAllAlbums) {
        if (a.year != null) {
          yearMap.putIfAbsent(a.year!, () => []).add(a);
        }
      }
      final sortedYears = yearMap.keys.toList()..sort((a, b) => b.compareTo(a));
      items.addAll(
        sortedYears.map(
          (y) => _LibraryItem(
            type: 'Year',
            id: 'year_$y',
            name: y.toString(),
            subtitle: l10n.albumsCount(yearMap[y]!.length),
            coverArt: yearMap[y]!
                    .firstWhere(
                      (a) => a.coverArt != null,
                      orElse: () => yearMap[y]!.first,
                    )
                    .coverArt ??
                '',
          ),
        ),
      );
    }

    return items;
  }

  Widget _buildLibraryItem(BuildContext context, _LibraryItem item) {
    // Alphabetical section header (Artists tab).
    if (item.type == 'SectionHeader') {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          item.name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDark
                ? AppTheme.darkSecondaryText
                : AppTheme.lightSecondaryText,
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    // Artist rows: text-only (icons all grey placeholders).
    if (item.type == 'Artist') {
      return InkWell(
        onTap: () => _openItem(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // All other item types: standard artwork + text layout.
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final coverArtUrl = item.coverArt != null
        ? (isLocalFilePath(item.coverArt)
            ? item.coverArt!
            : _coverUrl(subsonicService, item.coverArt!))
        : null;

    final String typeLabel = switch (item.type) {
      'Playlist' => l10n.filterPlaylists,
      'Album' => l10n.filterAlbums,
      'Song' => l10n.songs,
      _ => item.type,
    };

    final Widget artwork = ClipRRect(
      borderRadius: BorderRadius.circular(item.type == 'Artist' ? 28 : 4),
      child: SizedBox(
        width: 56,
        height: 56,
        child: coverArtUrl != null
            ? (isLocalFilePath(coverArtUrl)
                ? Image.file(
                    File(coverArtUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) =>
                        _buildPlaceholder(item.type, isDark),
                  )
                : CachedNetworkImage(
                    cacheManager: coverCacheManager,
                    imageUrl: coverArtUrl,
                    cacheKey: coverArtCacheKeyFromUrl(coverArtUrl),
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) =>
                        Container(color: Colors.grey[800]),
                    errorWidget: (ctx, url, err) =>
                        _buildPlaceholder(item.type, isDark),
                  ))
            : _buildPlaceholder(item.type, isDark),
      ),
    );

    return PressableScale(
      onTap: () => _openItem(context, item),
      child: InkWell(
        onTap: () => _openItem(context, item),
        onLongPress: item.type == 'Playlist'
            ? () => _showDeletePlaylistDialog(context, item)
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              artwork,
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$typeLabel • ${item.subtitle}',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(String type, bool isDark) {
    IconData icon;
    switch (type) {
      case 'Playlist':
        icon = Icons.queue_music;
        break;
      case 'Album':
        icon = Icons.album;
        break;
      case 'Artist':
        icon = Icons.person;
        break;
      case 'Song':
        icon = Icons.music_note;
        break;
      case 'Genre':
        icon = Icons.local_offer;
        break;
      case 'Year':
        icon = Icons.calendar_today;
        break;
      default:
        icon = Icons.music_note;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2C2C2E), const Color(0xFF1C1C1E)]
              : [const Color(0xFFF2F2F7), const Color(0xFFE5E5EA)],
        ),
        borderRadius: BorderRadius.circular(type == 'Artist' ? 28 : 4),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 24,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

  void _openItem(BuildContext context, _LibraryItem item) {
    switch (item.type) {
      case 'Playlist':
        NavigationHelper.push(
          context,
          PlaylistScreen(playlistId: item.id, playlistName: item.name),
        );
        break;
      case 'Album':
        NavigationHelper.push(context, AlbumScreen(albumId: item.id));
        break;
      case 'Artist':
        NavigationHelper.push(context, ArtistScreen(artistId: item.id));
        break;
      case 'Song':
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final playerProvider = Provider.of<PlayerProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs;
        final index = songs.indexWhere((s) => s.id == item.id);
        if (index >= 0) {
          playerProvider.playSong(
            songs[index],
            playlist: songs,
            startIndex: index,
          );
        }
        break;
      case 'Genre':
        final genreName = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final songs = libraryProvider.cachedAllSongs
            .where((s) => s.genre == genreName)
            .toList();
        if (songs.isNotEmpty) {
          final playerProvider = Provider.of<PlayerProvider>(
            context,
            listen: false,
          );
          playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
        }
        break;
      case 'Year':
        final yearStr = item.name;
        final libraryProvider = Provider.of<LibraryProvider>(
          context,
          listen: false,
        );
        final albums = libraryProvider.cachedAllAlbums
            .where((a) => a.year?.toString() == yearStr)
            .toList();
        if (albums.isNotEmpty) {
          NavigationHelper.push(context, AlbumScreen(albumId: albums.first.id));
        }
        break;
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    NavigationHelper.push(context, screen);
  }

  /// 打开歌手详情页（网格卡 / 常听 shelf 共用）。
  void _openArtist(Artist artist) {
    NavigationHelper.push(context, ArtistScreen(artistId: artist.id));
  }

  /// 切回 Artists 时，后台预热当前屏封面：磁盘命中 → 解码进
  /// 内存 ImageCache。专辑封面已全量在磁盘（<1000 张不会 LRU 淘汰），
  /// 首屏慢的原因是冷内存批量读盘，预热后秒开。
  /// 调用时机：`_onTabIndexChanged`（tab 落定为 Artists 且 `_wasArtistsTab`
  /// 为 false 时）；首次进入 Artists 页不预热（正在展示，无需预热）。
  void _maybePreloadArtistCovers(LibraryProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final urls = <String>[];
      final seen = <String>{};
      void addUrl(String? url) {
        if (url != null && url.isNotEmpty && seen.add(url)) urls.add(url);
      }

      // 前 24 位艺术家（首屏）：主图 + fallback + 拼贴各专辑封面。
      for (final artist in provider.artists.take(24)) {
        final cover = provider.resolveArtistCover(artist);
        addUrl(cover.imageUrl);
        addUrl(cover.fallbackImageUrl);
        for (final c in cover.collageCovers) {
          addUrl(provider.getCoverArtUrl(c));
        }
      }
      if (urls.isEmpty) return;
      ImagePreloader.preloadImages(context, urls);
    });
  }

  /// 播放该艺人的全部歌曲（本地缓存按 artistId 过滤，无则忽略）。
  void _playArtist(Artist artist) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final playerProvider = Provider.of<PlayerProvider>(
      context,
      listen: false,
    );
    final songs = libraryProvider.cachedAllSongs
        .where((s) => s.artistId == artist.id)
        .toList();
    if (songs.isEmpty) return;
    playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  void _showDeletePlaylistDialog(BuildContext context, _LibraryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deletePlaylist),
        content: Text(
          AppLocalizations.of(context)!.deletePlaylistConfirmation(item.name),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final libraryProvider = Provider.of<LibraryProvider>(
                context,
                listen: false,
              );
              try {
                await libraryProvider.deletePlaylist(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(
                          context,
                        )!
                            .playlistDeleted(item.name),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.errorDeletingPlaylist(e),
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  /// 刷新音乐库：等待结果后按成功/失败/本地模式弹提示。
  Future<void> _handleRefresh(BuildContext context) {
    return refreshLibraryWithFeedback(
      context,
      Provider.of<LibraryProvider>(context, listen: false),
    );
  }

  void _showAddPlaylistMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outerContext = context;
    showGlassBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(
                CupertinoIcons.music_note_list,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                '新建歌单',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                '手动创建一个空白歌单',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                // Wait for bottom sheet dismiss animation to complete
                await Future.delayed(const Duration(milliseconds: 300));
                if (outerContext.mounted) {
                  _showCreatePlaylistDialog(outerContext);
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.auto_awesome,
                color: isDark ? Colors.white : Colors.black,
              ),
              title: Text(
                'AI 智能生成',
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
              ),
              subtitle: Text(
                '根据听歌习惯、场景或描述自动生成歌单',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Future.delayed(const Duration(milliseconds: 300));
                if (outerContext.mounted) {
                  Navigator.push(
                    outerContext,
                    MaterialPageRoute(builder: (_) => const AiPlaylistScreen()),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    // Capture provider from outer context before entering dialog
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.newPlaylist),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.playlistName,
              filled: true,
              fillColor:
                  isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                final name = controller.text.trim();
                Navigator.pop(dialogContext);
                try {
                  await libraryProvider.createPlaylist(name);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.playlistCreated(name)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorCreatingPlaylist(e)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              }
            },
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  void _showLibrarySearch(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showSearch(
      context: context,
      delegate: LibrarySearchDelegate(
        libraryProvider: libraryProvider,
        isDark: isDark,
        searchFieldLabel: AppLocalizations.of(context)!.searchInLibrary,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    NavigationHelper.push(context, const SettingsRootScreen());
  }
}

class _LibraryEmptyState extends StatelessWidget {
  final bool isLocalMode;

  const _LibraryEmptyState({required this.isLocalMode});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.library_music_outlined,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            isLocalMode ? l10n.localLibraryEmpty : l10n.libraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isLocalMode
                ? l10n.localLibraryEmptySubtitle
                : l10n.libraryEmptySubtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          if (isLocalMode) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final localService = Provider.of<LocalMusicService>(
                  context,
                  listen: false,
                );
                if (!localService.isScanning) {
                  localService.scanForMusic();
                }
              },
              icon: const Icon(Icons.refresh),
              label: Text(l10n.scanForMusic),
              style: ElevatedButton.styleFrom(
                foregroundColor: isDark ? Colors.black : Colors.white,
                backgroundColor: isDark ? Colors.white : Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Right-edge letter scrubber for the Artists tab.
class _ArtistScrubber extends StatelessWidget {
  final List<String> letters;
  final String? selectedLetter;
  final ValueChanged<String> onLetterDown;
  final VoidCallback onLetterUp;

  const _ArtistScrubber({
    required this.letters,
    required this.selectedLetter,
    required this.onLetterDown,
    required this.onLetterUp,
  });

  @override
  Widget build(BuildContext context) {
    if (letters.length <= 1) return const SizedBox.shrink();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      onVerticalDragDown: (d) =>
          _onPos(d.localPosition, context.size?.height ?? 1),
      onVerticalDragUpdate: (d) =>
          _onPos(d.localPosition, context.size?.height ?? 1),
      onVerticalDragEnd: (_) => onLetterUp(),
      onLongPressMoveUpdate: (d) =>
          _onPos(d.localPosition, context.size?.height ?? 1),
      child: Container(
        width: 28,
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: letters.map((l) {
            final isSelected = l == selectedLetter;
            return Expanded(
              child: Center(
                child: Text(
                  l,
                  style: TextStyle(
                    fontSize: isSelected ? 12 : 10,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? AppTheme.appleMusicRed
                        : (isDark ? Colors.white54 : Colors.black45),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onPos(Offset local, double height) {
    final fraction = (local.dy / height).clamp(0.0, 1.0);
    final idx =
        (fraction * letters.length).floor().clamp(0, letters.length - 1);
    onLetterDown(letters[idx]);
  }
}

class _LibraryItem {
  final String type;
  final String id;
  final String name;
  final String subtitle;
  final String? coverArt;

  _LibraryItem({
    required this.type,
    required this.id,
    required this.name,
    required this.subtitle,
    this.coverArt,
  });
}

class _SpotifyLibraryTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool isGradient;
  final VoidCallback? onTap;

  const _SpotifyLibraryTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.isGradient = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                gradient: isGradient
                    ? LinearGradient(
                        colors: [iconColor.withValues(alpha: 0.8), iconColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isGradient ? null : iconColor.withValues(alpha: 0.15),
              ),
              child: Icon(
                icon,
                color: isGradient ? Colors.white : iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
