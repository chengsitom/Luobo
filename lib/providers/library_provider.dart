import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/image_cache.dart';
import '../services/services.dart';
import '../services/local_music_service.dart';

/// 刷新状态机：驱动音乐库/首页刷新按钮的 loading 态。
enum RefreshStatus { idle, running }

/// 一次刷新（显式点击或后台调度）的结果，供 UI 展示完成数字/失败原因。
class RefreshResult {
  const RefreshResult({
    required this.success,
    this.merged = false,
    this.isLocal = false,
    this.albumCount = 0,
    this.songCount = 0,
    this.error,
  });

  final bool success;

  /// 本次刷新与已在进行的刷新合并（点击不重复启动）。
  final bool merged;

  /// 本地模式：仅重读本地扫描结果，未走服务端全量同步。
  final bool isLocal;
  final int albumCount;
  final int songCount;
  final String? error;
}

class LibraryProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final AndroidAutoService _androidAutoService = AndroidAutoService();

  /// 行为画像（常听歌手 TopN 数据源），由 main.dart 注入。
  /// 可空：未注入时「常听」shelf 返回空列表，页面自然隐藏该区。
  RecommendationService? _recommendationService;
  RecommendationService? get recommendationService => _recommendationService;
  set recommendationService(RecommendationService? service) {
    _recommendationService?.removeListener(_onRecommendationChanged);
    _recommendationService = service;
    service?.addListener(_onRecommendationChanged);
    _topArtistsCache = null;
    notifyListeners();
  }

  /// 行为画像更新（播放/打分/收藏）时失效常听缓存，保证下次进艺术家
  /// tab 即展示最新 TopN，无需等曲库刷新（曲库刷新时 notifyListeners
  /// 同样会清缓存，见 :222-229）。
  void _onRecommendationChanged() {
    _topArtistsCache = null;
    notifyListeners();
  }

  bool _localOnlyMode = false;
  bool _serverOfflineMode = false;
  bool _mergeLocalLibrary = false;
  LocalMusicService? _localMusicService;
  final LibraryDatabaseService _db = LibraryDatabaseService();

  List<Artist> _artists = [];
  List<Album> _recentAlbums = [];
  List<Album> _frequentAlbums = [];
  List<Album> _newestAlbums = [];
  List<Album> _randomAlbums = [];
  List<Playlist> _playlists = [];
  List<Song> _randomSongs = [];
  List<String> _genres = [];
  List<Genre> _richGenres = [];
  SearchResult? _starred;

  List<Album> _cachedAllAlbums = [];
  List<Song> _cachedAllSongs = [];
  List<Playlist> _cachedPlaylists = [];
  DateTime? _lastCacheUpdate;

  /// 常听歌手 TopN（artistId + 播放次数），行为画像或曲库变化时失效。
  List<TopArtist>? _topArtistsCache;

  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  /// 刷新状态机：idle / running，UI 据此渲染按钮 loading 与结果提示。
  RefreshStatus _refreshStatus = RefreshStatus.idle;
  RefreshStatus get refreshStatus => _refreshStatus;
  Completer<RefreshResult>? _activeRefreshCompleter;

  static const String _playlistsCacheKey = 'cached_playlists';
  static const String _artistsCacheKey = 'cached_artists';
  static const String _lastUpdateKey = 'last_cache_update';

  /// 常听歌手置顶数量（可调 3~8，两排横滑最多展示 8 个，见
  /// docs/音乐库艺术家页改版技术方案.md §4.1）。
  static const int kTopArtistsCount = 8;

  LibraryProvider(this._subsonicService) {
    // Register callback to push library data when Android Auto service requests it
    _androidAutoService.onRequestLibraryData = _onRequestLibraryData;
  }
  SubsonicService get subsonicService => _subsonicService;

  void _onRequestLibraryData() {
    debugPrint('LibraryProvider: Android Auto requested library data');
    if (_isInitialized) {
      if (_serverOfflineMode) {
        _pushOfflineLibraryToAndroidAuto();
      } else {
        _pushLibraryToAndroidAuto();
      }
    } else {
      // If not initialized yet, try to initialize and then push
      if (!_isLoading) {
        initialize().then((_) {
          if (_serverOfflineMode) {
            _pushOfflineLibraryToAndroidAuto();
          } else {
            _pushLibraryToAndroidAuto();
          }
        });
      }
    }
  }

  void setLocalMusicService(LocalMusicService service,
      {bool mergeWithServer = false}) {
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    _localMusicService = service;
    _localOnlyMode = !mergeWithServer;
    _mergeLocalLibrary = mergeWithServer;
    _isInitialized = false;
    service.addListener(_onLocalMusicServiceChanged);
    if (mergeWithServer) {
      _onLocalMusicServiceChanged();
    }
  }

  void _onLocalMusicServiceChanged() {
    if (_localMusicService == null || _localMusicService!.isScanning) return;

    if (_localOnlyMode) {
      // Local only mode - use only local library
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      _isInitialized = true;
      _isLoading = false;
      notifyListeners();
    } else if (_mergeLocalLibrary) {
      // Merge mode - just notify that local library changed
      // The getters will handle the merging
      notifyListeners();
    }
  }

  /// Toggle merging local library with server library
  void setMergeLocalLibrary(bool enabled) {
    if (_mergeLocalLibrary == enabled) return;
    _mergeLocalLibrary = enabled;
    notifyListeners();
  }

  void setLocalOnlyMode(bool enabled) {
    if (!enabled && _localOnlyMode) {
      _localMusicService?.removeListener(_onLocalMusicServiceChanged);
      _localMusicService = null;
      _cachedAllSongs = [];
      _cachedAllAlbums = [];
      _artists = [];
      _randomSongs = [];
      _recentAlbums = [];
      _playlists = [];
      _cachedPlaylists = [];
    }
    _localOnlyMode = enabled;
    _isInitialized = false;
    notifyListeners();
  }

  bool get isLocalOnlyMode => _localOnlyMode;
  bool get isServerOfflineMode => _serverOfflineMode;
  bool get mergeLocalLibrary => _mergeLocalLibrary;

  void setServerOfflineMode(bool offline) {
    _serverOfflineMode = offline;
  }

  String getCoverArtUrl(String? coverArt) {
    return _subsonicService.getCoverArtUrl(coverArt,
        size: kCoverArtRequestSize);
  }

  /// Cover art for an artist, falling back to one of the artist's album
  /// covers when Navidrome has no artist image (no `artist.*` file or
  /// external service). Keeps artist lists/cards from showing a wall of
  /// placeholder icons.
  String? getArtistCoverArt(Artist artist) {
    if (artist.coverArt != null && artist.coverArt!.isNotEmpty) {
      return artist.coverArt;
    }
    for (final album in cachedAllAlbums) {
      final cover = album.coverArt;
      if (album.artistId == artist.id && cover != null && cover.isNotEmpty) {
        return cover;
      }
    }
    // Some servers omit artistId on album entries; match by artist name.
    final name = artist.name.toLowerCase();
    for (final album in cachedAllAlbums) {
      final cover = album.coverArt;
      if ((album.artist ?? '').toLowerCase() == name &&
          cover != null &&
          cover.isNotEmpty) {
        return cover;
      }
    }
    return null;
  }

  /// 艺术家封面统一解析入口（5 级优先级，见 docs/音乐库艺术家页改版技术方案.md §4.2）：
  /// 1. `artistImageUrl` 直链（Navidrome last.fm/deezer 大图）→ 2. `coverArt` id →
  /// 3. 专辑封面单图 → 4. 2×2 专辑封面拼贴 → 5. 渐变首字母占位。
  /// 组件按 `ArtistCover` 的字段择一渲染，保证无任何图源时页面也不素。
  ArtistCover resolveArtistCover(Artist artist) {
    // 级 1/2：外部直链（artistImageUrl，last.fm/deezer）或服务端 coverArt id。
    String? primaryUrl;
    final directUrl = artist.artistImageUrl;
    if (directUrl != null && directUrl.isNotEmpty) {
      primaryUrl = directUrl;
    } else {
      final coverArt = artist.coverArt;
      if (coverArt != null && coverArt.isNotEmpty) {
        primaryUrl = getCoverArtUrl(coverArt);
      }
    }
    // 级 3：专辑封面单图 —— 直链常有防盗链/网络失败，作为降级目标
    // （fallback）；没有 primary 时直接作为主图。
    String? fallbackUrl;
    final albumCover = getArtistCoverArt(artist);
    if (albumCover != null && albumCover.isNotEmpty) {
      final url = getCoverArtUrl(albumCover);
      if (primaryUrl == null || primaryUrl.isEmpty) {
        primaryUrl = url;
      } else if (url != primaryUrl) {
        fallbackUrl = url;
      }
    }
    // 级 4：2×2 拼贴（最终兜底，本地零网络）。
    final collage = _artistCollageCoverArt(artist);
    if ((primaryUrl == null || primaryUrl.isEmpty) && collage.isEmpty) {
      _logCoverFallback(artist);
    }
    return ArtistCover(
      imageUrl: primaryUrl,
      fallbackImageUrl: fallbackUrl,
      collageCovers: collage,
      name: artist.name,
    );
  }

  /// 一次性诊断：封面解析全落空时输出库内匹配样本，用于定位
  /// cachedAllAlbums 的 artistId/artist 是否与 artist 匹配得上。
  /// 只打印前 3 位落空艺术家，避免刷屏（配合全局 print 节流）。
  static int _coverFallbackLogCount = 0;
  void _logCoverFallback(Artist artist) {
    if (_coverFallbackLogCount >= 3) return;
    _coverFallbackLogCount++;
    final sample = cachedAllAlbums
        .take(3)
        .map(
          (a) => '${a.artistId ?? '∅'}|${a.artist ?? '∅'}|${a.coverArt ?? '∅'}',
        )
        .join(', ');
    debugPrint(
      '[ArtistCover] 全落空: id=${artist.id} name=${artist.name} '
      'albums=${cachedAllAlbums.length} sample=[$sample]',
    );
  }

  /// 该艺人最多 4 张专辑封面的 coverArt id（2×2 拼贴用）。全本地缓存，
  /// 零网络。先按 artistId 匹配，再按名字匹配（兼容服务端省略 artistId）。
  List<String> _artistCollageCoverArt(Artist artist) {
    return artistAlbumCoverArt(cachedAllAlbums, artist);
  }

  /// 常听歌手 TopN（本地播放加权亲和度降序，见方案文档 §4.1）。
  /// 无播放历史 / 未注入行为画像时返回空列表 → UI 不渲染「常听」shelf。
  List<TopArtist> get topArtists {
    final cached = _topArtistsCache;
    if (cached != null) return cached;
    final result = _computeTopArtists();
    _topArtistsCache = result;
    return result;
  }

  List<TopArtist> _computeTopArtists() {
    final service = _recommendationService;
    if (service == null) return const [];
    // 多取 3 倍名字以吸收「affinity 键是名字、库内同名合并」造成的过滤损耗。
    final names = service.topArtistsView(kTopArtistsCount * 3);
    if (names.isEmpty) return const [];
    // name → Artist 归一映射，防同名艺人合并（affinity 键是名字，非 artistId）。
    final byName = <String, Artist>{};
    for (final a in artists) {
      byName.putIfAbsent(a.name, () => a);
    }
    final result = <TopArtist>[];
    final seen = <String>{};
    for (final name in names) {
      final artist = byName[name];
      if (artist == null || !seen.add(artist.id)) continue;
      result
          .add(TopArtist(artist: artist, playCount: _artistPlayCount(artist)));
      if (result.length >= kTopArtistsCount) break;
    }
    return result;
  }

  /// 该艺人在本地的累计播放次数（SongProfile.playCount 按 artistId 聚合，
  /// 兜底按名字匹配）。用于「常听」卡下的小字。
  int _artistPlayCount(Artist artist) {
    final service = _recommendationService;
    if (service == null) return 0;
    var count = 0;
    for (final p in service.profiles.values) {
      if (p.artistId != null && p.artistId == artist.id) {
        count += p.playCount;
      }
    }
    if (count > 0) return count;
    final name = artist.name;
    for (final p in service.profiles.values) {
      if (p.artist == name) count += p.playCount;
    }
    return count;
  }

  /// Resolves the cover art id to use for a song. A song's cover is almost
  /// always its album's cover, so when the server omits `song.coverArt` we
  /// fall back to the album's cover (by albumId from the local library) —
  /// this keeps all songs of an album on the same cache key instead of
  /// generating one URL per song (`song.id`), which would download and
  /// transcode the same image N times.
  String? effectiveCoverArt(Song song) {
    if (song.coverArt != null && song.coverArt!.isNotEmpty) {
      return song.coverArt;
    }
    final albumId = song.albumId;
    if (albumId != null && albumId.isNotEmpty) {
      final album = _albumCoverById[albumId];
      if (album != null) return album;
    }
    return song.id;
  }

  /// albumId → coverArt cache, rebuilt lazily from the local album library.
  Map<String, String>? _albumCoverByIdCache;

  Map<String, String> get _albumCoverById {
    final cached = _albumCoverByIdCache;
    if (cached != null) return cached;
    final map = <String, String>{};
    for (final album in cachedAllAlbums) {
      final cover = album.coverArt;
      if (cover != null && cover.isNotEmpty) {
        map.putIfAbsent(album.id, () => cover);
      }
    }
    _albumCoverByIdCache = map;
    return map;
  }

  /// artistId → song count, computed once per library change instead of on
  /// every rebuild of the Artists tab.
  Map<String, int>? _artistSongCountsCache;

  Map<String, int> get artistSongCounts {
    final cached = _artistSongCountsCache;
    if (cached != null) return cached;
    final map = <String, int>{};
    for (final song in cachedAllSongs) {
      final artistId = song.artistId;
      if (artistId != null && artistId.isNotEmpty) {
        map[artistId] = (map[artistId] ?? 0) + 1;
      }
    }
    _artistSongCountsCache = map;
    return map;
  }

  @override
  void notifyListeners() {
    // Derived maps are invalidated on any library change so they never
    // return stale data.
    _albumCoverByIdCache = null;
    _artistSongCountsCache = null;
    _topArtistsCache = null;
    super.notifyListeners();
  }

  List<Album> get frequentAlbums => _frequentAlbums;
  List<Album> get newestAlbums => _newestAlbums;
  List<Album> get randomAlbums => _randomAlbums;
  List<Playlist> get playlists => _playlists;
  List<Album> get recentAlbums => _recentAlbums;
  List<Song> get randomSongs => _randomSongs;
  List<String> get genres => _genres;
  List<Genre> get richGenres => _richGenres;
  SearchResult? get starred => _starred;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  List<Album> get cachedAllAlbums {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _cachedAllAlbums;
    }
    // Merge server albums with local albums
    final localAlbums = _localMusicService!.albums;
    final merged = [..._cachedAllAlbums];
    for (final localAlbum in localAlbums) {
      // Avoid duplicates by checking ID
      if (!merged.any((a) => a.id == localAlbum.id)) {
        merged.add(localAlbum);
      }
    }
    return merged;
  }

  List<Song> get cachedAllSongs {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _cachedAllSongs;
    }
    // Merge server songs with local songs
    final localSongs = _localMusicService!.songs;
    final merged = [..._cachedAllSongs];
    for (final localSong in localSongs) {
      // Avoid duplicates by checking ID
      if (!merged.any((s) => s.id == localSong.id)) {
        merged.add(localSong);
      }
    }
    return merged;
  }

  List<Artist> get artists {
    if (!_mergeLocalLibrary ||
        _localMusicService == null ||
        _localMusicService!.isEmpty) {
      return _artists;
    }
    // Merge server artists with local artists
    final localArtists = _localMusicService!.artists;
    final merged = [..._artists];
    for (final localArtist in localArtists) {
      // Avoid duplicates by checking ID
      if (!merged.any((a) => a.id == localArtist.id)) {
        merged.add(localArtist);
      }
    }
    return merged;
  }

  Future<void> initialize(
      {bool force = false, bool scheduleBackground = true}) async {
    if (_isInitialized && !force) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (_localOnlyMode && _localMusicService != null) {
        _cachedAllSongs = List.from(_localMusicService!.songs);
        _cachedAllAlbums = List.from(_localMusicService!.albums);
        _artists = List.from(_localMusicService!.artists);
        _randomSongs = _cachedAllSongs.take(50).toList();
        _recentAlbums = _cachedAllAlbums.take(20).toList();
        _isInitialized = true;
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _loadCachedData(loadFullLibrary: true);

      if (_recentAlbums.isEmpty && _cachedAllAlbums.isNotEmpty) {
        _recentAlbums = _cachedAllAlbums.take(20).toList();
      }
      if (_randomSongs.isEmpty && _cachedAllSongs.isNotEmpty) {
        _randomSongs = _cachedAllSongs.take(50).toList();
      }
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
      }

      if (_serverOfflineMode) {
        await _pushOfflineLibraryToAndroidAuto();
      } else {
        _pushLibraryToAndroidAuto();
      }

      Future.delayed(const Duration(milliseconds: 800), () {
        if (_serverOfflineMode) {
          _pushOfflineLibraryToAndroidAuto();
        } else {
          _pushLibraryToAndroidAuto();
        }
      });

      if (!_serverOfflineMode) {
        // ⚠️ 冷启动必须加载一次收藏：`_starred` 此前**只在收藏/取消收藏动作**里
        // 被赋值（`star()` / `unstar()` / `PlayerProvider.toggleFavorite*`），
        // 冷启动链路里没有它 → `starred` 恒为 null → 首页「收藏」卡计数恒为 0、
        // 流体卡取不到色（看起来像"没获取到封面"）。见
        // `docs/首页快捷入口与漫游技术方案.md` §12.2。
        //
        // ⚠️ 但它**不进**下面那个 5s 超时窗口：它只服务首页那张卡的计数与取色，
        // 慢一点不该让整个「初始化完成」超时。它内部自带 try/catch，完成时会
        // `notifyListeners()`，首页自行重建。
        unawaited(loadStarred());
        try {
          await Future.wait([
            loadRecentAlbums(),
            loadRandomSongs(),
            loadPlaylists(),
            loadArtists(),
          ]).timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint(
                'Server initialization timed out - continuing in local mode',
              );
              throw TimeoutException('Server not responding');
            },
          );
        } catch (serverError) {
          debugPrint('Server initialization skipped: $serverError');
        }
      }

      _isInitialized = true;
      _preloadCoverArt();
      // 显式刷新（refresh()）已自行管理全量同步，不再排 5s 延迟任务，
      // 避免与立即启动的全量同步重复（见 refresh()）。
      if (scheduleBackground) {
        _scheduleBackgroundRefresh();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> ensureLibraryLoaded() async {
    if (_cachedAllSongs.isNotEmpty) return;

    if (_localOnlyMode && _localMusicService != null) {
      _cachedAllSongs = List.from(_localMusicService!.songs);
      _cachedAllAlbums = List.from(_localMusicService!.albums);
      _artists = List.from(_localMusicService!.artists);
      _randomSongs = _cachedAllSongs.take(50).toList();
      _recentAlbums = _cachedAllAlbums.take(20).toList();
      notifyListeners();
      return;
    }

    await _loadCachedData(loadFullLibrary: true);

    if (_cachedAllSongs.isEmpty) {
      // Kick off the full sync in the background without blocking the UI;
      // screens pick up the data via notifyListeners when it completes.
      _refreshAllDataInBackground();
    }
  }

  Future<void> _loadCachedData({bool loadFullLibrary = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final playlistsJson = prefs.getString(_playlistsCacheKey);
      if (playlistsJson != null) {
        final List<dynamic> playlistsList = json.decode(playlistsJson);
        _cachedPlaylists = playlistsList
            .map((p) => Playlist.fromJson(p as Map<String, dynamic>))
            .toList();
        _playlists = _cachedPlaylists;
      }

      final artistsJson = prefs.getString(_artistsCacheKey);
      if (artistsJson != null) {
        final List<dynamic> artistsList = json.decode(artistsJson);
        _artists = artistsList
            .map((a) => Artist.fromJson(a as Map<String, dynamic>))
            .toList();
      }

      if (loadFullLibrary) {
        try {
          _cachedAllAlbums = await _db.getAllAlbums();
          _cachedAllSongs = await _db.getAllSongs();
        } catch (e) {
          debugPrint('Error loading library from DB: $e');
        }
      }

      final lastUpdate = prefs.getInt(_lastUpdateKey);
      if (lastUpdate != null) {
        _lastCacheUpdate = DateTime.fromMillisecondsSinceEpoch(lastUpdate);
      }
    } catch (e) {
      debugPrint('Error loading cached data: $e');
    }
  }

  void _scheduleBackgroundRefresh() {
    // Always allow a refresh on first launch (empty cache) so the full
    // library sync runs automatically instead of waiting for the user to
    // open the "All Songs" screen.
    final shouldRefresh = _lastCacheUpdate == null ||
        DateTime.now().difference(_lastCacheUpdate!) > const Duration(hours: 6);

    if (shouldRefresh) {
      Future.delayed(const Duration(seconds: 2), () {
        _refreshAllDataInBackground();
      });
    }
  }

  bool _isRefreshing = false;

  Future<RefreshResult> _refreshAllDataInBackground() async {
    // 防重入：显式刷新与后台调度共用同一把锁；被跳过时返回 merged 结果。
    if (_isRefreshing) {
      return const RefreshResult(success: false, merged: true);
    }
    _isRefreshing = true;
    try {
      const pageSize = 500;
      int offset = 0;
      final List<Album> allAlbums = [];
      final seenSongIds = <String>{};

      // Clear DB before refresh so we don't accumulate stale data.
      await _db.clearServerData();

      while (true) {
        final page = await _subsonicService.getAlbumList(
          type: 'alphabeticalByName',
          size: pageSize,
          offset: offset,
        );
        if (page.isEmpty) break;
        allAlbums.addAll(page);
        await _db.insertAlbumsBatch(page);
        if (page.length < pageSize) break;
        offset += pageSize;
      }

      if (_subsonicService.isJellyfin) {
        // Jellyfin/Emby: fetch all songs in O(1) API call.
        try {
          final allSongs = await _subsonicService.getAllSongs();
          for (final song in allSongs) {
            seenSongIds.add(song.id);
          }
          await _db.insertSongsBatch(allSongs);
        } catch (e) {
          debugPrint(
              'Jellyfin getAllSongs failed, falling back to album traversal: $e');
        }
      }

      var failedAlbumLoads = 0;
      if (seenSongIds.isEmpty) {
        // Subsonic or Jellyfin fallback: iterate albums from DB
        // instead of holding the entire album list in RAM.
        final albumCount = await _db.getAlbumCount();
        const albumBatchSize = 50;
        const concurrentFetches = 8;
        for (int aOffset = 0; aOffset < albumCount; aOffset += albumBatchSize) {
          final albums = await _db.getAlbumsPaginated(
              limit: albumBatchSize, offset: aOffset);
          // Fetch songs for albums concurrently (bounded) instead of one
          // HTTP request at a time, which made large libraries take minutes.
          for (var i = 0; i < albums.length; i += concurrentFetches) {
            final chunk = albums.sublist(
              i,
              i + concurrentFetches > albums.length
                  ? albums.length
                  : i + concurrentFetches,
            );
            final results = await Future.wait(
              chunk.map((album) async {
                try {
                  return await _subsonicService.getAlbumSongs(album.id);
                } catch (e) {
                  failedAlbumLoads++;
                  debugPrint('Error loading album ${album.id}: $e');
                  return <Song>[];
                }
              }),
            );
            for (final songs in results) {
              final newSongs =
                  songs.where((s) => seenSongIds.add(s.id)).toList();
              if (newSongs.isNotEmpty) {
                await _db.insertSongsBatch(newSongs);
              }
            }
          }
        }
      }

      _cachedAllAlbums = allAlbums;
      _cachedAllSongs = await _db.getAllSongs();
      _lastCacheUpdate = DateTime.now();

      await _saveCachedData();
      notifyListeners();
      // 全量专辑拉到后必须补一次封面预热：initialize() 里的预热（:542）
      // 只覆盖 DB 恢复的少量数据，冷启后磁盘里大部分专辑封面还是空的，
      // 此时不预热会导致艺术家拼图/列表逐个下载（含服务端首次转码）很慢。
      _preloadCoverArt();
      debugPrint(
        'Background refresh complete: ${allAlbums.length} albums, '
        '${_cachedAllSongs.length} songs '
        '(${failedAlbumLoads > 0 ? "$failedAlbumLoads album(s) failed, " : ""}kept what succeeded).',
      );
      return RefreshResult(
        success: true,
        albumCount: allAlbums.length,
        songCount: _cachedAllSongs.length,
      );
    } catch (e) {
      debugPrint('Error refreshing all data: $e');
      return RefreshResult(success: false, error: e.toString());
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> _saveCachedData() async {
    try {
      // Persist large collections (songs/albums) to SQLite instead of
      // SharedPreferences JSON to avoid OutOfMemoryError with 100k+ tracks.
      await _db.insertAlbumsBatch(_cachedAllAlbums);
      await _db.insertSongsBatch(_cachedAllSongs);

      final prefs = await SharedPreferences.getInstance();

      // Playlists and artists are small enough to keep in SharedPreferences
      final playlistsJson = json.encode(
        _cachedPlaylists.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_playlistsCacheKey, playlistsJson);

      if (_artists.isNotEmpty) {
        final artistsJson = json.encode(
          _artists.map((a) => a.toJson()).toList(),
        );
        await prefs.setString(_artistsCacheKey, artistsJson);
      }

      await prefs.setInt(
        _lastUpdateKey,
        _lastCacheUpdate?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('Error saving cached data: $e');
    }
  }

  /// 服务器切换后全量重置：清空旧服务器的内存列表、prefs 缓存（歌单/艺人）
  /// 与曲库 DB，再从新服务器重拉。由 main.dart 的 onServerSwitched 回调调用，
  /// 消除「切服后首页/音乐库仍展示旧服务器专辑/艺人，点击用旧 ID 打新服务器
  /// 404」的问题（诊断日志 confirmed）。
  Future<void> resetForServerChange() async {
    debugPrint('[Library] resetForServerChange: clearing server data');
    _artists = [];
    _recentAlbums = [];
    _frequentAlbums = [];
    _newestAlbums = [];
    _randomAlbums = [];
    _playlists = [];
    _randomSongs = [];
    _genres = [];
    _richGenres = [];
    _starred = null;
    _cachedAllAlbums = [];
    _cachedAllSongs = [];
    _cachedPlaylists = [];
    _topArtistsCache = null;
    _lastCacheUpdate = null;
    _isInitialized = false;
    _error = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_playlistsCacheKey);
      await prefs.remove(_artistsCacheKey);
      await prefs.remove(_lastUpdateKey);
    } catch (e) {
      debugPrint('Error clearing library cache prefs: $e');
    }

    try {
      await _db.clearServerData();
    } catch (e) {
      debugPrint('Error clearing library DB: $e');
    }

    notifyListeners();
    await initialize(force: true);
  }

  void _pushLibraryToAndroidAuto() {
    if (_artists.isNotEmpty) {
      _androidAutoService.updateArtists(_artists);
    }
    if (_recentAlbums.isNotEmpty) {
      _androidAutoService.updateAlbums(_recentAlbums, getCoverArtUrl);
    }
    if (_playlists.isNotEmpty) {
      _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
    }
    if (_randomSongs.isNotEmpty) {
      _androidAutoService.updateRecentSongs(_randomSongs, getCoverArtUrl);
    }
  }

  Future<void> _pushOfflineLibraryToAndroidAuto() async {
    final offlineService = OfflineService();
    await offlineService.initialize();
    final downloadedIds = offlineService.getDownloadedSongIds().toSet();

    if (downloadedIds.isEmpty) {
      _pushLibraryToAndroidAuto();
      return;
    }

    final offlineSongs =
        _cachedAllSongs.where((s) => downloadedIds.contains(s.id)).toList();
    if (offlineSongs.isNotEmpty) {
      _androidAutoService.updateRecentSongs(offlineSongs, getCoverArtUrl);
    } else if (_randomSongs.isNotEmpty) {
      _androidAutoService.updateRecentSongs(_randomSongs, getCoverArtUrl);
    }

    final albumIdsWithDownloads =
        offlineSongs.map((s) => s.albumId).whereType<String>().toSet();
    final offlineAlbums = _cachedAllAlbums
        .where((a) => albumIdsWithDownloads.contains(a.id))
        .toList();
    if (offlineAlbums.isNotEmpty) {
      _androidAutoService.updateAlbums(offlineAlbums, getCoverArtUrl);
    } else if (_recentAlbums.isNotEmpty) {
      _androidAutoService.updateAlbums(_recentAlbums, getCoverArtUrl);
    }

    final artistIdsWithDownloads =
        offlineSongs.map((s) => s.artistId).whereType<String>().toSet();
    final offlineArtists =
        _artists.where((a) => artistIdsWithDownloads.contains(a.id)).toList();
    if (offlineArtists.isNotEmpty) {
      _androidAutoService.updateArtists(offlineArtists);
    } else if (_artists.isNotEmpty) {
      _androidAutoService.updateArtists(_artists);
    }

    if (_playlists.isNotEmpty) {
      _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
    }
  }

  /// Prefetches the first screen-worth of cover art into the shared image
  /// cache (coverCacheManager, the same one CachedNetworkImage reads), keyed
  /// by the same size=300 URL, throttled so we don't fire a transcode storm
  /// at the server.
  void _preloadCoverArt() {
    Future.microtask(() async {
      final urls = <String>[];
      final seen = <String>{};
      void addCover(String? coverArt) {
        if (coverArt == null || coverArt.isEmpty) return;
        final url = _subsonicService.getCoverArtUrl(
          coverArt,
          size: kCoverArtRequestSize,
        );
        if (url.isNotEmpty && seen.add(url)) urls.add(url);
      }

      // Artists tab icons. Prefetch the artist's effective cover (own artist
      // image, or the album-cover fallback) so the list doesn't wait for
      // on-demand first-hit transcodes.
      var prefetchedArtists = 0;
      for (final artist in _artists) {
        if (prefetchedArtists >= 20) break;
        final cover = getArtistCoverArt(artist);
        if (cover == null || cover.isEmpty) continue;
        addCover(cover);
        prefetchedArtists++;
        if (kDebugMode && prefetchedArtists == 1) {
          debugPrint(
            '[LuoboDebug] Artist cover sample: ${artist.name} '
            'coverArt=${artist.coverArt}',
          );
        }
      }
      if (kDebugMode && urls.isNotEmpty) {
        debugPrint('[LuoboDebug] First cover URL: ${urls.first}');
      }
      // Full library: every album cover (each album = one unique cover that
      // all of its songs share via effectiveCoverArt). downloadFile() skips
      // entries already in cache, so this only fetches what's missing.
      for (final album in _cachedAllAlbums) {
        addCover(album.coverArt);
      }
      // First screen of the All Songs list — the most common cold-start view.
      for (final song in _cachedAllSongs.take(20)) {
        addCover(effectiveCoverArt(song));
      }

      final cacheManager = coverCacheManager;
      const batchSize = 6;
      // 首批封面除落盘外同步预热内存：首屏滚动不再实时解码（方案 P2）。
      const memoryWarmCount = 24;
      var ok = 0;
      var failed = 0;
      for (var i = 0; i < urls.length; i += batchSize) {
        final end = i + batchSize > urls.length ? urls.length : i + batchSize;
        await Future.wait(
          urls.sublist(i, end).map((url) async {
            try {
              await cacheManager.downloadFile(
                url,
                key: coverArtCacheKeyFromUrl(url),
              );
              if (i < memoryWarmCount) {
                await _warmCoverMemoryCache(url);
              }
              ok++;
            } catch (e) {
              failed++;
              if (kDebugMode) {
                debugPrint('[LuoboDebug] Cover prefetch failed: $url → $e');
              }
            }
          }),
        );
        // Let the server breathe between batches: Navidrome resizes covers
        // on first request per (id, size), so a full-library preload would
        // otherwise hit it with a transcode storm.
        if (end < urls.length) {
          await Future.delayed(const Duration(milliseconds: 150));
        }
      }
      if (kDebugMode) {
        debugPrint(
          '[LuoboDebug] Cover prefetch done: ${urls.length} urls '
          '(artists=$prefetchedArtists), ok=$ok, failed=$failed',
        );
      }
    });
  }

  /// Decodes one cover into the memory ImageCache (same semantic cacheKey the
  /// UI uses) so the first screen of a cold start renders without a decode
  /// hitch on scroll. Background resolve — no BuildContext needed.
  Future<void> _warmCoverMemoryCache(String url) async {
    try {
      final provider = CachedNetworkImageProvider(
        url,
        cacheManager: coverCacheManager,
        cacheKey: coverArtCacheKeyFromUrl(url),
      );
      final stream = provider.resolve(const ImageConfiguration());
      final completer = Completer<void>();
      late final ImageStreamListener listener;
      listener = ImageStreamListener(
        (_, __) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
        onError: (Object e, StackTrace? s) {
          stream.removeListener(listener);
          if (!completer.isCompleted) completer.complete();
        },
      );
      stream.addListener(listener);
      await completer.future.timeout(const Duration(seconds: 8));
    } catch (_) {}
  }

  Future<RefreshResult> refresh() async {
    // 已在刷新中：合并到进行中的任务，不重复启动全量同步。
    if (_isRefreshing) {
      final active = _activeRefreshCompleter;
      if (active != null) return active.future;
      // 后台调度触发的同步在跑（无 completer）：不重复启动，返回 merged。
      return const RefreshResult(success: false, merged: true);
    }

    _lastCacheUpdate = null; // force full re-sync
    // Keep _isInitialized true so the UI does not flash a skeleton screen
    // when the user pulls to refresh while data is already shown.
    final completer = Completer<RefreshResult>();
    _activeRefreshCompleter = completer;
    _refreshStatus = RefreshStatus.running;
    notifyListeners();

    try {
      await initialize(force: true, scheduleBackground: false);

      if (_serverOfflineMode || _localOnlyMode) {
        // 本地/离线：仅重读缓存/本地扫描结果，不触发服务端全量同步。
        completer
            .complete(RefreshResult(success: true, isLocal: _localOnlyMode));
      } else {
        completer.complete(await _refreshAllDataInBackground());
      }
    } catch (e) {
      completer.complete(RefreshResult(success: false, error: e.toString()));
    } finally {
      _refreshStatus = RefreshStatus.idle;
      _activeRefreshCompleter = null;
      notifyListeners();
    }
    return completer.future;
  }

  Future<void> loadArtists() async {
    if (_serverOfflineMode) return;
    try {
      _artists = await _subsonicService.getArtists();
      notifyListeners();
      _androidAutoService.updateArtists(_artists);
      _saveCachedData();
    } catch (e) {
      debugPrint('Error loading artists: $e');

      if (_artists.isNotEmpty) {
        _androidAutoService.updateArtists(_artists);
      }
    }
  }

  Future<void> loadRecentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      final fetched = await _subsonicService.getAlbumList(
        type: 'recent',
        size: 20,
      );
      // Only replace the list when the server actually returned results.
      // On Navidrome, type=recent returns [] if nothing has been played
      // recently, which would wipe the cached albums shown in the UI.
      if (fetched.isNotEmpty) {
        _recentAlbums = fetched;
      }
      notifyListeners();
      _androidAutoService.updateAlbums(_recentAlbums, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading recent albums: $e');
    }
  }

  Future<void> loadFrequentAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _frequentAlbums = await _subsonicService.getAlbumList(
        type: 'frequent',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading frequent albums: $e');
    }
  }

  Future<void> loadNewestAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _newestAlbums = await _subsonicService.getAlbumList(
        type: 'newest',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading newest albums: $e');
    }
  }

  Future<void> loadRandomAlbums() async {
    if (_serverOfflineMode) return;
    try {
      _randomAlbums = await _subsonicService.getAlbumList(
        type: 'random',
        size: 20,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading random albums: $e');
    }
  }

  Future<void> loadPlaylists() async {
    if (_serverOfflineMode) return;
    try {
      final newPlaylists = await _subsonicService.getPlaylists();

      final List<Playlist> mergedPlaylists = [];

      for (final newPlaylist in newPlaylists) {
        final cachedIndex = _cachedPlaylists.indexWhere(
          (p) => p.id == newPlaylist.id,
        );
        if (cachedIndex != -1) {
          final cachedFn = _cachedPlaylists[cachedIndex];

          if (cachedFn.songs != null && cachedFn.songs!.isNotEmpty) {
            mergedPlaylists.add(newPlaylist.copyWith(songs: cachedFn.songs));
            continue;
          }
        }
        mergedPlaylists.add(newPlaylist);
      }

      _playlists = mergedPlaylists;
      _cachedPlaylists = _playlists;
      _saveCachedData();
      notifyListeners();
      _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading playlists: $e');
      if (_playlists.isEmpty && _cachedPlaylists.isNotEmpty) {
        _playlists = _cachedPlaylists;
        notifyListeners();
      }

      if (_playlists.isNotEmpty) {
        _androidAutoService.updatePlaylists(_playlists, getCoverArtUrl);
      }
    }
  }

  Future<void> loadRandomSongs() async {
    if (_serverOfflineMode) return;
    try {
      _randomSongs = await _subsonicService.getRandomSongs(size: 50);
      notifyListeners();
      _androidAutoService.updateRecentSongs(_randomSongs, getCoverArtUrl);
    } catch (e) {
      debugPrint('Error loading random songs: $e');

      if (_randomSongs.isNotEmpty) {
        _androidAutoService.updateRecentSongs(_randomSongs, getCoverArtUrl);
      }
    }
  }

  Future<void> loadGenres() async {
    if (_serverOfflineMode) return;
    try {
      _richGenres = await _subsonicService.getGenres();
      _genres = _richGenres.map((g) => g.value).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading genres: $e');
    }
  }

  Future<void> loadStarred() async {
    if (_serverOfflineMode) return;
    try {
      _starred = await _subsonicService.getStarred();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading starred: $e');
    }
  }

  Future<List<Album>> getArtistAlbums(String artistId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getAlbumsByArtist(artistId);
    }
    try {
      return await _subsonicService.getArtistAlbums(artistId);
    } catch (e) {
      debugPrint('Error loading artist albums: $e');
      return [];
    }
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_localOnlyMode && _localMusicService != null) {
      return _localMusicService!.getSongsByAlbum(albumId);
    }
    try {
      return await _subsonicService.getAlbumSongs(albumId);
    } catch (e) {
      debugPrint('Error loading album songs: $e');
      return [];
    }
  }

  Future<Playlist> getPlaylist(String playlistId) async {
    if (_serverOfflineMode) {
      final cached = _playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => _cachedPlaylists.firstWhere(
          (p) => p.id == playlistId,
          orElse: () => throw Exception('Playlist not available offline'),
        ),
      );
      return cached;
    }

    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);

      final index = _playlists.indexWhere((p) => p.id == playlistId);
      if (index != -1) {
        _playlists[index] = playlist;
      } else {
        _playlists.add(playlist);
      }

      _cachedPlaylists = List.from(_playlists);
      _saveCachedData();
      notifyListeners();

      return playlist;
    } catch (e) {
      debugPrint('Error loading playlist details: $e');

      final cachedPlaylist = _playlists.firstWhere(
        (p) => p.id == playlistId,
        orElse: () => throw e,
      );

      if (cachedPlaylist.songs != null && cachedPlaylist.songs!.isNotEmpty) {
        return cachedPlaylist;
      }

      rethrow;
    }
  }

  Future<void> createPlaylist(String name, {List<String>? songIds}) async {
    await _subsonicService.createPlaylist(name: name, songIds: songIds);
    await loadPlaylists();
  }

  Future<void> deletePlaylist(String playlistId) async {
    await _subsonicService.deletePlaylist(playlistId);
    await loadPlaylists();
  }

  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    await _subsonicService.updatePlaylist(
      playlistId: playlistId,
      songIdsToAdd: [songId],
    );
  }

  Future<SearchResult> search(String query) async {
    if (_localOnlyMode) {
      return _searchLocal(query);
    }
    return await _subsonicService.search(query);
  }

  SearchResult _searchLocal(String query) {
    final q = query.toLowerCase();
    final songs = _cachedAllSongs
        .where(
          (s) =>
              s.title.toLowerCase().contains(q) ||
              (s.artist?.toLowerCase().contains(q) ?? false) ||
              (s.album?.toLowerCase().contains(q) ?? false),
        )
        .take(50)
        .toList();
    final artists = _artists
        .where((a) => a.name.toLowerCase().contains(q))
        .take(20)
        .toList();
    final albums = _cachedAllAlbums
        .where(
          (a) =>
              a.name.toLowerCase().contains(q) ||
              (a.artist?.toLowerCase().contains(q) ?? false),
        )
        .take(20)
        .toList();
    return SearchResult(songs: songs, artists: artists, albums: albums);
  }

  Future<void> star({String? songId, String? albumId, String? artistId}) async {
    await _subsonicService.star(
      id: songId,
      albumId: albumId,
      artistId: artistId,
    );
    await loadStarred();
  }

  Future<void> unstar({
    String? songId,
    String? albumId,
    String? artistId,
  }) async {
    await _subsonicService.unstar(
      id: songId,
      albumId: albumId,
      artistId: artistId,
    );
    await loadStarred();
  }

  Future<List<Song>> getSongsByGenre(String genre) async {
    try {
      return await _subsonicService.getSongsByGenre(genre);
    } catch (e) {
      debugPrint('Error loading songs by genre: $e');
      return [];
    }
  }

  Future<List<Album>> getAlbumsByGenre(String genre) async {
    try {
      return await _subsonicService.getAlbumsByGenre(genre);
    } catch (e) {
      debugPrint('Error loading albums by genre: $e');
      return [];
    }
  }

  Future<List<Song>> getAllSongs() async {
    try {
      final allArtists = await _subsonicService.getArtists();

      final List<Song> allSongs = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums = await _subsonicService.getArtistAlbums(
            artist.id,
          );
          for (final album in artistAlbums) {
            try {
              final songs = await _subsonicService.getAlbumSongs(album.id);
              allSongs.addAll(songs);
            } catch (e) {
              debugPrint('Error loading album ${album.id}: $e');
            }
          }
        } catch (e) {
          debugPrint('Error loading albums for artist ${artist.name}: $e');
        }
      }

      return allSongs;
    } catch (e) {
      debugPrint('Error loading all songs: $e');
      return [];
    }
  }

  Future<List<Album>> getAllAlbums() async {
    try {
      final allArtists = await _subsonicService.getArtists();

      final List<Album> allAlbums = [];

      for (final artist in allArtists) {
        try {
          final artistAlbums = await _subsonicService.getArtistAlbums(
            artist.id,
          );
          allAlbums.addAll(artistAlbums);
        } catch (e) {
          debugPrint('Error loading albums for artist ${artist.name}: $e');
        }
      }

      return allAlbums;
    } catch (e) {
      debugPrint('Error loading all albums: $e');
      return [];
    }
  }

  @override
  void dispose() {
    _localMusicService?.removeListener(_onLocalMusicServiceChanged);
    super.dispose();
  }
}

/// 艺术家封面解析结果（`LibraryProvider.resolveArtistCover`）。
/// 渲染规则：`imageUrl` 非空 → 网络图（加载失败时依次尝试
/// `fallbackImageUrl` → 2×2 拼贴 → `name` 首字母渐变占位）；
/// `collageCovers` 非空 → 2×2 拼贴；两者皆空 → 渐变占位。
/// 外部直链（artistImageUrl）常有防盗链/网络失败，故 fallback 保证
/// 直链挂了也能落到本服务专辑封面，而不是直接变渐变。
class ArtistCover {
  final String? imageUrl;
  final String? fallbackImageUrl;
  final List<String> collageCovers;
  final String name;

  const ArtistCover({
    this.imageUrl,
    this.fallbackImageUrl,
    this.collageCovers = const [],
    required this.name,
  });

  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
  bool get hasFallback =>
      fallbackImageUrl != null &&
      fallbackImageUrl!.isNotEmpty &&
      fallbackImageUrl != imageUrl;
  bool get hasCollage => collageCovers.isNotEmpty;
}

/// 常听歌手条目：艺人 + 本地累计播放次数（shelf 卡下小字用）。
class TopArtist {
  final Artist artist;
  final int playCount;

  const TopArtist({required this.artist, required this.playCount});
}

/// 该艺人最多 4 张专辑封面的 coverArt id（2×2 拼贴数据源）。
/// 先按 artistId 匹配，再按名字匹配（兼容服务端省略 artistId）。
/// 纯逻辑顶层函数，便于单测（见 test/services/artist_top_test.dart）。
List<String> artistAlbumCoverArt(List<Album> albums, Artist artist) {
  final result = <String>[];
  for (final album in albums) {
    final cover = album.coverArt;
    if (album.artistId == artist.id && cover != null && cover.isNotEmpty) {
      result.add(cover);
      if (result.length >= 4) break;
    }
  }
  if (result.isNotEmpty) return result;
  final name = artist.name.toLowerCase();
  for (final album in albums) {
    final cover = album.coverArt;
    if ((album.artist ?? '').toLowerCase() == name &&
        cover != null &&
        cover.isNotEmpty) {
      result.add(cover);
      if (result.length >= 4) break;
    }
  }
  return result;
}
