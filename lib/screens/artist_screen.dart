import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';
import '../utils/song_sort.dart';
import '../widgets/album_artwork.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/song_tile.dart';
import 'album_screen.dart';

/// 歌手详情页 —— **1:1 对齐 fnos（设计稿：视觉 doc §8.2，2026-10-23）**。
///
/// 版式（`fn_frames_all` v8_0011 / v6_0210 帧实测，720px ÷2 = dp）：
/// 全幅照片头（底部渐隐到底色）→ 居中歌手名 25/700 → 「N 首歌 · M 张专辑」12
/// → 黑色「▶ 播放全部」胶囊 109×48 + 分段控件（白容器 135×40，选中=灰药丸）
/// → 「共 N 首」行（右：排序 + 多选）→ 歌曲列表 / 专辑网格。
///
/// 折叠（v8_0012 / v6_0216 实测）：顶栏**保持透明**，圆形返回钮随滚动**横向
/// 长成胶囊**（仍 h40/r20，内含 `‹` + 歌手名），分段控件同时迁入右上
/// （白容器 118×40）。内容从胶囊/分段下方流过。
class ArtistScreen extends StatefulWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Artist? _artist;
  List<Song> _topSongs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  /// 0 = 歌曲，1 = 专辑（fnos 分段控件默认「歌曲」）。
  int _tab = 0;

  // 歌曲排序（与歌单/收藏同款：标题/歌手/专辑/最近添加 + 方向）。
  SongSortField _sortField = SongSortField.title;
  bool _sortAscending = true;
  final _sortAnchor = GlobalKey();

  final _scrollController = ScrollController();

  // ── 折叠参数（dp）──
  /// 照片头高度（fnos 实测 ≈375；Luobo 用方形专辑封面裁切，取 340）。
  static const double _photoHeight = 340;
  /// 折叠起点/终点（滚动偏移，dp）：照片滚出后开始，标题块在「共 N 首」行
  /// 抵达顶栏下方（≈95dp）时完成——此时名字/分段控件已完全迁入顶栏。
  static const double _collapseStart = 240;
  static const double _collapseEnd = 410;

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistDetails() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    if (libraryProvider.isLocalOnlyMode) {
      try {
        final artist = libraryProvider.artists.firstWhere(
          (a) => a.id == widget.artistId,
          orElse: () => Artist(id: widget.artistId, name: 'Unknown Artist'),
        );
        final albums = await libraryProvider.getArtistAlbums(widget.artistId);

        final topSongs = libraryProvider.cachedAllSongs
            .where((s) => s.artistId == widget.artistId)
            .toList();

        if (mounted) {
          setState(() {
            _artist = artist;
            _topSongs = topSongs;
            _albums = albums;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    // ── Server mode: cache-first ──
    // Render immediately from the local library cache (artists / albums /
    // songs synced into SQLite), then refresh from the server in the
    // background so repeated entries don't block on the network.
    final cachedArtist = libraryProvider.artists.firstWhere(
      (a) => a.id == widget.artistId,
      orElse: () => Artist(id: widget.artistId, name: ''),
    );
    final cachedAlbums = libraryProvider.cachedAllAlbums
        .where((a) => a.artistId == widget.artistId)
        .toList();
    final cachedSongs = libraryProvider.cachedAllSongs
        .where((s) => s.artistId == widget.artistId)
        .toList();

    final hasCache = cachedArtist.name.isNotEmpty ||
        cachedAlbums.isNotEmpty ||
        cachedSongs.isNotEmpty;

    if (hasCache && mounted) {
      var artist = cachedArtist;
      if (artist.name.isEmpty) {
        final nameFromAlbum =
            cachedAlbums.isNotEmpty ? (cachedAlbums.first.artist ?? '') : '';
        artist = Artist(
          id: widget.artistId,
          name: nameFromAlbum.isNotEmpty
              ? nameFromAlbum
              : (cachedSongs.isNotEmpty
                  ? (cachedSongs.first.artist ?? '')
                  : ''),
        );
      }
      setState(() {
        _artist = artist;
        _albums = cachedAlbums;
        _topSongs = cachedSongs;
        _isLoading = false;
      });
    }

    // Background refresh with fresh server data; never blocks the UI.
    await _loadArtistFromServer();
  }

  Future<void> _loadArtistFromServer() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = libraryProvider.subsonicService;

    Artist? artist;
    List<Song> topSongs = [];
    List<Album> albums = [];

    try {
      artist = await subsonicService.getArtist(widget.artistId);
    } catch (e) {
      debugPrint('Error loading artist ${widget.artistId}: $e');
    }

    try {
      topSongs = await subsonicService.getArtistTopSongs(
        widget.artistId,
        artist: artist,
      );
    } catch (e) {
      debugPrint('Error loading top songs for ${widget.artistId}: $e');
    }

    try {
      albums = await subsonicService.getArtistAlbums(
        widget.artistId,
        artist: artist,
      );
    } catch (e) {
      debugPrint('Error loading albums for ${widget.artistId}: $e');
    }

    if (albums.isEmpty) {
      albums = libraryProvider.cachedAllAlbums
          .where((a) => a.artistId == widget.artistId)
          .toList();
    }
    // 歌曲列表要**该歌手全部歌曲**（fnos：共 202 首）。`getArtistTopSongs`
    // 只给热门 N 首，所以只要有本地曲库缓存就优先用缓存的全量列表。
    final cachedAll = libraryProvider.cachedAllSongs
        .where((s) => s.artistId == widget.artistId)
        .toList();
    if (cachedAll.isNotEmpty) {
      topSongs = cachedAll;
    } else if (topSongs.isEmpty) {
      topSongs = libraryProvider.cachedAllSongs
          .where((s) => s.artistId == widget.artistId)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      if (artist != null) _artist = artist;
      _topSongs = topSongs;
      _albums = albums;
      _isLoading = false;
    });
  }

  List<Song> get _displaySongs {
    if (_topSongs.length < 2) return _topSongs;
    return sortSongs(_topSongs, _sortField, ascending: _sortAscending);
  }

  Future<void> _addArtistToQueue() async {
    if (_albums.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = libraryProvider.subsonicService;

    final loc = AppLocalizations.of(context);

    try {
      final songsToQueue = <Song>[];
      for (final album in _albums) {
        final albumSongs = libraryProvider.isLocalOnlyMode
            ? libraryProvider.cachedAllSongs
                .where((s) => s.albumId == album.id)
                .toList()
            : await subsonicService.getAlbumSongs(album.id);

        songsToQueue.addAll(albumSongs);
      }

      if (songsToQueue.isNotEmpty) {
        playerProvider.addAllToQueue(songsToQueue);
      }

      if (!mounted) return;

      final addedToQueueMessage =
          loc?.addedArtistToQueue ?? 'Added artist to Queue';
      showLuoboToast(
        context,
        message: addedToQueueMessage,
        tone: LuoboToastTone.info,
      );
    } catch (e) {
      if (!mounted) return;

      final addedToQueueErrorMessage =
          loc?.addedArtistToQueueError ?? 'Failed adding artist to Queue';
      showLuoboToast(
        context,
        message: addedToQueueErrorMessage,
        tone: LuoboToastTone.info,
      );
    }
  }

  void _playTopSongs({bool shuffle = false}) {
    if (_topSongs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    var songs = List<Song>.from(_topSongs);
    if (shuffle) {
      songs.shuffle();
    }

    playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  void _openMultiSelect() {
    final songs = _displaySongs;
    if (songs.isEmpty) return;
    showMultiSelectSheet(context, songs: songs);
  }

  Future<void> _showSortMenu(GlobalKey anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final field = await showLuoboAnchoredMenu<SongSortField>(
      context: context,
      anchorKey: anchor,
      selected: _sortField,
      items: [
        for (final f in SongSortField.values)
          LuoboAnchoredMenuItem(
            value: f,
            label: _fieldLabel(l10n, f),
            trailing: (f == _sortField && songSortShowsDirection(f))
                ? Icon(
                    _sortAscending ? AppIcons.arrowUp : AppIcons.arrowDown,
                    size: 15,
                    color: LuoboAccent.accent,
                  )
                : null,
          ),
      ],
    );
    if (field == null || !mounted) return;
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  String _fieldLabel(AppLocalizations l10n, SongSortField field) {
    switch (field) {
      case SongSortField.title:
        return l10n.sortFieldTitle;
      case SongSortField.artist:
        return l10n.artists;
      case SongSortField.album:
        return l10n.albums;
      case SongSortField.recentlyAdded:
        return l10n.recentlyAdded;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Stack(
          children: [
            const Center(child: CircularProgressIndicator()),
            _buildFloatingBar(context),
          ],
        ),
      );
    }

    if (_artist == null) {
      return Scaffold(
        body: Stack(
          children: [
            Center(
              child: Text(AppLocalizations.of(context)!.artistDataNotFound),
            ),
            _buildFloatingBar(context),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              if (_tab == 0)
                _buildSongSliver()
              else
                _buildAlbumSliver(),
              SliverToBoxAdapter(child: SizedBox(height: LuoboSpacing.pageBottomWithStrip(context))),
            ],
          ),
          _buildFloatingBar(context),
        ],
      ),
    );
  }

  // ── 头部（随滚动整块上移）─────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    // 5 级封面解析（artistImageUrl → coverArt → 专辑封面 → 2×2 拼贴 → 占位）。
    final cover = libraryProvider.resolveArtistCover(_artist!);

    return Column(
      children: [
        SizedBox(
          height: _photoHeight,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildHeroImage(context, cover),
              // 底部渐隐到页面底色（fnos：照片下缘没有硬边）。
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [
                        c.bg.withValues(alpha: 0),
                        c.bg.withValues(alpha: 0.85),
                        c.bg,
                      ],
                      stops: const [0.35, 0.9, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // 标题块随折叠淡出（fnos：大字名淡出、顶栏胶囊里的名字淡入）。
        AnimatedBuilder(
          animation: _scrollController,
          builder: (context, child) {
            final opacity = (1 - _collapseT * 1.6).clamp(0.0, 1.0);
            return Opacity(opacity: opacity, child: child);
          },
          child: Column(
            children: [
              Text(
                _artist!.name,
                style: LuoboType.navTitle.copyWith(fontSize: 25, color: c.fg),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 5),
              Text(
                l10n.artistStats(_topSongs.length, _albums.length),
                style: LuoboType.caption.copyWith(color: c.fg2),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 长按 = 整个歌手加入播放队列（fnos 无此入口，保留原能力且不占视觉）。
                  GestureDetector(
                    onLongPress: _addArtistToQueue,
                    child: SizedBox(
                      width: 109,
                      child: LuoboHeroCapsule(
                        icon: AppIcons.play,
                        label: l10n.playAll,
                        onTap: () => _playTopSongs(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  _ArtistTabBar(
                    width: 135,
                    value: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),
                ],
              ),
            ],
          ),
        ),
        // fnos 实测：按钮行与「共 N 首」行之间留 36dp（折叠后计数行正好落在
        // 顶栏胶囊下方，不被遮住）。
        const SizedBox(height: 30),
        _buildCountRow(context, l10n, c),
        const SizedBox(height: 4),
      ],
    );
  }

  /// 头图：真实歌手图（服务端有则用）→ 专辑封面 → 中性占位
  /// （fnos 无照片歌手 = 底色 + 音符，不用彩色渐变）。
  Widget _buildHeroImage(BuildContext context, ArtistCover cover) {
    final c = LuoboColors.of(context);
    final url = cover.hasImage
        ? cover.imageUrl
        : (cover.hasFallback ? cover.fallbackImageUrl : null);
    if (url == null || url.isEmpty) return _buildHeroPlaceholder(c);
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: coverCacheManager,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _buildHeroPlaceholder(c),
      errorWidget: (_, __, ___) {
        if (cover.hasFallback && cover.fallbackImageUrl != url) {
          return CachedNetworkImage(
            imageUrl: cover.fallbackImageUrl!,
            cacheManager: coverCacheManager,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (_, __) => _buildHeroPlaceholder(c),
            errorWidget: (_, __, ___) => _buildHeroPlaceholder(c),
          );
        }
        return _buildHeroPlaceholder(c);
      },
    );
  }

  /// 无艺人图时的占位：**流体渐变 + 音符**（用户 2026-10-23：不要死板底色）。
  /// seed 由 artist id 派生 —— 同一个歌手每次进页面配色一致。
  Widget _buildHeroPlaceholder(LuoboColors c) {
    return Stack(
      fit: StackFit.expand,
      children: [
        FluidBackground(
          colors: const [
            Color(0xFF3D6BFF),
            Color(0xFF7A4DFF),
            Color(0xFF2FBBDD),
          ],
          borderRadius: 0,
          seed: FluidBackground.seedForIndex(_artist!.id.hashCode % 7),
        ),
        Center(
          child: Icon(
            Icons.music_note_rounded,
            size: 72,
            color: Colors.white.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildCountRow(
    BuildContext context,
    AppLocalizations l10n,
    LuoboColors c,
  ) {
    final isSongs = _tab == 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            isSongs
                ? l10n.songsCount(_displaySongs.length)
                : l10n.albumsCount(_albums.length),
            style: LuoboType.caption.copyWith(color: c.fg2),
          ),
          const Spacer(),
          if (isSongs) ...[
            GestureDetector(
              key: _sortAnchor,
              onTap: () => _showSortMenu(_sortAnchor),
              child: Icon(Icons.sort_rounded, size: 22, color: c.fg2),
            ),
            const SizedBox(width: 18),
            GestureDetector(
              onTap: _openMultiSelect,
              child: Icon(Icons.checklist_rounded, size: 22, color: c.fg2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSongSliver() {
    final songs = _displaySongs;
    if (songs.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Column(
            children: [
              SongTile(song: songs[index], playlist: songs, index: index),
              if (index < songs.length - 1) const LuoboSongDivider(),
            ],
          );
        },
        childCount: songs.length,
      ),
    );
  }

  Widget _buildAlbumSliver() {
    if (_albums.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 13,
          mainAxisSpacing: 18,
          childAspectRatio: 0.72,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final album = _albums[index];
            return _ArtistAlbumTile(
              album: album,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AlbumScreen(albumId: album.id),
                ),
              ),
            );
          },
          childCount: _albums.length,
        ),
      ),
    );
  }

  // ── 折叠顶栏（透明；圆钮 → 胶囊 + 分段控件迁入）──────────────────────

  double get _collapseT {
    if (!_scrollController.hasClients) return 0;
    final offset = _scrollController.offset;
    return ((offset - _collapseStart) / (_collapseEnd - _collapseStart))
        .clamp(0.0, 1.0);
  }

  /// 胶囊里名字的可用宽度：最宽不超过屏宽 42%（超长名字由 Text 省略号截断，
  /// 不会把胶囊顶到分段控件上）。
  double _nameWidth(BuildContext context, String name) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.42;
    final painter = TextPainter(
      text: TextSpan(
        text: name,
        style: LuoboType.body.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: Directionality.of(context),
    )..layout(maxWidth: maxWidth);
    return painter.width.clamp(0.0, maxWidth);
  }

  Widget _buildFloatingBar(BuildContext context) {
    final name = _artist?.name ?? '';
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: AnimatedBuilder(
            animation: _scrollController,
            builder: (context, _) {
              final t = _collapseT;
              // 名字 45% 起淡入；分段控件 60% 起淡入（此前内容里的控件仍在视野内）。
              final nameT = ((t - 0.45) / 0.55).clamp(0.0, 1.0);
              final segT = ((t - 0.6) / 0.4).clamp(0.0, 1.0);
              // 固定内距合计 40 + 14t（左 10+2t / 图标 20 / 间距 6t / 右 10+6t），
              // 留 8dp 余量 —— 之前按 +10 算少了 4dp，两个字的名字也会被裁。
              final width =
                  40 + (name.isEmpty ? 0 : _nameWidth(context, name) + 22) * nameT;

              return Stack(
                children: [
                  Positioned(
                    left: 16,
                    top: 8,
                    child: _buildBackPill(context, name, width, nameT),
                  ),
                  if (name.isNotEmpty && _artist != null)
                    Positioned(
                      right: 16,
                      top: 8,
                      child: IgnorePointer(
                        ignoring: segT < 0.5,
                        child: Opacity(
                          opacity: segT,
                          child: _ArtistTabBar(
                            width: 118,
                            value: _tab,
                            onChanged: (v) => setState(() => _tab = v),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackPill(
    BuildContext context,
    String name,
    double width,
    double nameT,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        width: width,
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            // 收起时左侧内距让 17dp 图标居中于 40dp 圆（10 + 20 + 10）。
            SizedBox(width: 10 + 2 * nameT),
            SizedBox(
              width: 20,
              child: Center(
                child: Icon(AppIcons.back, size: 17, color: fg),
              ),
            ),
            SizedBox(width: 6 * nameT),
            if (name.isNotEmpty && nameT > 0)
              Expanded(
                child: Opacity(
                  opacity: nameT,
                  child: Text(
                    name,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: LuoboType.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: fg,
                    ),
                  ),
                ),
              ),
            SizedBox(width: 10 + 6 * nameT),
          ],
        ),
      ),
    );
  }
}

/// 分段控件（fnos 歌手详情）：白容器 + 选中灰药丸（`#E6E7E6`）。
/// 内容里 135×40、折叠进顶栏后 118×40（同一控件，只改宽度）。
class _ArtistTabBar extends StatelessWidget {
  final double width;
  final int value;
  final ValueChanged<int> onChanged;

  const _ArtistTabBar({
    required this.width,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final isDark = c.isDark;
    final container = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white;
    final selectedFill = isDark
        ? Colors.white.withValues(alpha: 0.24)
        : const Color(0xFFE6E7E6);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: width,
      height: 40,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: container,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _tabItem(l10n.songs, 0, selectedFill, c),
          _tabItem(l10n.albums, 1, selectedFill, c),
        ],
      ),
    );
  }

  Widget _tabItem(
    String label,
    int index,
    Color selectedFill,
    LuoboColors c,
  ) {
    final selected = value == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(index),
        child: Container(
          decoration: BoxDecoration(
            color: selected ? selectedFill : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Center(
            child: Text(
              label,
              style: LuoboType.body.copyWith(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? c.fg : c.fg2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 专辑网格单元（fnos：封面 + 名称 + 年份，左对齐）。
class _ArtistAlbumTile extends StatelessWidget {
  final Album album;
  final VoidCallback onTap;

  const _ArtistAlbumTile({required this.album, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AlbumArtwork(
                coverArt: album.coverArt,
                size: width,
                borderRadius: 12,
              ),
              const SizedBox(height: 8),
              Text(
                album.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: LuoboType.body.copyWith(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: c.fg,
                ),
              ),
              if (album.year != null) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.albumYear(album.year!),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuoboType.caption.copyWith(color: c.fg2),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
