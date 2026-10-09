import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as pkg_http;
import 'package:just_audio/just_audio.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import '../models/models.dart';
import 'subsonic_service.dart';

/// Proxies a YouTube audio stream through dart:io so the request carries the
/// same headers that were used to fetch the manifest. This avoids the 403 that
/// ExoPlayer/Media3 triggers when it requests the URL directly (wrong client).
class _YoutubeStreamAudioSource extends StreamAudioSource {
  final yt.YoutubeExplode _yt;
  final String _videoId;

  yt.AudioOnlyStreamInfo? _cachedInfo;
  DateTime? _cachedAt;

  static const _cacheAge = Duration(hours: 4);

  // Clients to try in order for manifest fetching.
  // mweb and android use /youtubei/v1/player (not the watch page).
  static final _clients = [
    [yt.YoutubeApiClient.mweb],
    null, // default android
    [yt.YoutubeApiClient.androidMusic],
  ];

  _YoutubeStreamAudioSource(this._yt, this._videoId) : super(tag: _videoId);

  /// Pre-warms the manifest cache so [request] returns instantly.
  Future<void> preload() => _fetchInfo();

  Future<yt.AudioOnlyStreamInfo> _fetchInfo() async {
    if (_cachedInfo != null &&
        _cachedAt != null &&
        DateTime.now().difference(_cachedAt!) < _cacheAge) {
      return _cachedInfo!;
    }

    Object? lastError;
    for (final clientList in _clients) {
      try {
        final manifest = await _yt.videos.streamsClient.getManifest(
          _videoId,
          ytClients: clientList,
        );
        final streams = manifest.audioOnly;
        if (streams.isEmpty) continue;
        _cachedInfo = streams.withHighestBitrate();
        _cachedAt = DateTime.now();
        debugPrint(
            '[YouTube] Stream info cached for $_videoId (client=$clientList)');
        return _cachedInfo!;
      } catch (e) {
        debugPrint('[YouTube] Manifest fetch failed (client=$clientList): $e');
        lastError = e;
      }
    }
    throw lastError ?? Exception('No audio streams available for $_videoId');
  }

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final info = await _fetchInfo();
    final total = info.size.totalBytes;
    final s = start ?? 0;

    // Use package:http directly — same library youtube_explode_dart uses
    // internally.  This bypasses _getStream's FatalFailureException retry
    // which re-fetches the watch page and triggers YouTube rate limiting.
    final client = pkg_http.Client();
    final req = pkg_http.Request('GET', info.url);
    req.headers['Range'] = 'bytes=$s-${total - 1}';

    final resp = await client.send(req);
    if (resp.statusCode == 403 || resp.statusCode == 429) {
      client.close();
      // URL is expired or rate-limited — clear cache so next call re-fetches
      _cachedInfo = null;
      _cachedAt = null;
      debugPrint(
          '[YouTube] Stream URL rejected (${resp.statusCode}) for $_videoId');
      throw Exception('YouTube stream URL rejected: ${resp.statusCode}');
    }

    return StreamAudioResponse(
      sourceLength: total,
      contentLength: total - s,
      offset: s,
      stream: resp.stream.cast<List<int>>(),
      contentType: info.codec.mimeType,
    );
  }
}

class YoutubeService {
  yt.YoutubeExplode? _yt;

  // Stream URL cache — YouTube URLs are valid for ~6 h
  final Map<String, String> _streamCache = {};
  final Map<String, DateTime> _streamCacheTime = {};
  static const _streamCacheMaxAge = Duration(hours: 5);

  yt.YoutubeExplode get _client {
    _yt ??= yt.YoutubeExplode();
    return _yt!;
  }

  void dispose() {
    _yt?.close();
    _yt = null;
  }

  // ── Connectivity ──────────────────────────────────────────────────────────

  Future<PingResult> pingWithError() async {
    try {
      final req = await HttpClient().getUrl(
        Uri.parse('https://music.youtube.com/'),
      );
      req.headers.set('User-Agent', 'Mozilla/5.0');
      final res = await req.close();
      await res.drain<void>();
      return PingResult(
        success: res.statusCode < 400,
        serverType: 'YouTube Music',
        serverVersion: '1.0',
      );
    } catch (e) {
      return PingResult(success: false, error: 'Cannot reach YouTube: $e');
    }
  }

  // ── Cover art & stream ────────────────────────────────────────────────────

  String getCoverArtUrl(String? id, {int size = 300}) {
    if (id == null || id.isEmpty) return '';
    return 'https://img.youtube.com/vi/$id/mqdefault.jpg';
  }

  /// Returns a lightweight placeholder URL synchronously.
  String getStreamUrl(String videoId) => 'ytmusic://$videoId';

  /// Builds and pre-warms a [StreamAudioSource] that proxies audio through
  /// youtube_explode_dart's authenticated HTTP client.
  /// The manifest is fetched here so [request()] returns immediately.
  Future<StreamAudioSource> buildAudioSource(String videoId) async {
    final source = _YoutubeStreamAudioSource(_client, videoId);
    await source.preload();
    return source;
  }

  /// Resolves the actual audio stream URL asynchronously (default android client).
  /// Used as a fallback for Cast / UPnP playback where a plain URL is needed.
  Future<String> resolveStreamUrl(String videoId) async {
    final cached = _streamCache[videoId];
    if (cached != null) {
      final age = DateTime.now().difference(_streamCacheTime[videoId]!);
      if (age < _streamCacheMaxAge) return cached;
    }

    final manifest = await _client.videos.streamsClient.getManifest(videoId);
    final audioOnly = manifest.audioOnly;
    if (audioOnly.isEmpty) {
      throw Exception('No audio streams available for video $videoId');
    }
    final best = audioOnly.withHighestBitrate();
    final url = best.url.toString();

    _streamCache[videoId] = url;
    _streamCacheTime[videoId] = DateTime.now();
    debugPrint('[YouTube] Resolved stream for $videoId → ${best.bitrate}');
    return url;
  }

  // ── Model mappers ─────────────────────────────────────────────────────────

  Song _videoToSong(yt.Video v) {
    final music = v.musicData.isNotEmpty ? v.musicData.first : null;
    return Song(
      id: v.id.value,
      title: music?.song ?? v.title,
      artist: music?.artist ?? v.author,
      album: music?.album,
      duration: v.duration?.inSeconds,
      coverArt: v.id.value,
    );
  }

  // ── Artists / Albums ──────────────────────────────────────────────────────

  Future<List<Artist>> getArtists() async => [];

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async =>
      [];

  Future<Album> getAlbum(String playlistId) async {
    final pl = await _client.playlists.get(playlistId);
    return Album(
      id: pl.id.value,
      name: pl.title,
      artist: pl.author,
      coverArt: pl.thumbnails.highResUrl.isNotEmpty ? playlistId : null,
      songCount: pl.videoCount,
    );
  }

  Future<List<Song>> getAlbumSongs(String playlistId) async {
    final videos =
        await _client.playlists.getVideos(playlistId).take(200).toList();
    return videos.map(_videoToSong).toList();
  }

  Future<List<Album>> getArtistAlbums(String channelId) async => [];

  // ── Playlists ─────────────────────────────────────────────────────────────

  Future<List<Playlist>> getPlaylists() async => [];

  Future<Playlist> getPlaylist(String id) async {
    final pl = await _client.playlists.get(id);
    final videos = await _client.playlists.getVideos(id).take(100).toList();
    return Playlist(
      id: pl.id.value,
      name: pl.title,
      comment: pl.description.isNotEmpty ? pl.description : null,
      owner: pl.author,
      songCount: pl.videoCount ?? videos.length,
      songs: videos.map(_videoToSong).toList(),
    );
  }

  Future<void> createPlaylist({
    required String name,
    String? comment,
    List<String>? songIds,
  }) async {
    throw UnsupportedError(
      'Creating playlists requires YouTube Music sign-in (not yet supported).',
    );
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    String? comment,
    List<String>? songIdsToAdd,
    List<int>? songIndexesToRemove,
  }) async {
    throw UnsupportedError(
      'Editing playlists requires YouTube Music sign-in (not yet supported).',
    );
  }

  Future<void> deletePlaylist(String id) async {
    throw UnsupportedError(
      'Deleting playlists requires YouTube Music sign-in (not yet supported).',
    );
  }

  // ── Search ────────────────────────────────────────────────────────────────

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    final results = await _client.search.search(
      query,
      filter: yt.TypeFilters.video,
    );
    final songs = results.take(songCount).map(_videoToSong).toList();
    return SearchResult(artists: [], albums: [], songs: songs);
  }

  // ── Random songs ──────────────────────────────────────────────────────────

  Future<List<Song>> getRandomSongs({int size = 20, String? genre}) async {
    final query = genre != null ? '$genre music' : 'music';
    final results = await _client.search.search(
      query,
      filter: yt.TypeFilters.video,
    );
    return results.take(size).map(_videoToSong).toList();
  }

  // ── Favorites / Scrobble (no-op in anonymous mode) ────────────────────────

  Future<void> star({String? id, String? albumId, String? artistId}) async {}
  Future<void> unstar({String? id, String? albumId, String? artistId}) async {}
  Future<void> scrobble(String id, {bool submission = true}) async {}

  Future<SearchResult> getStarred() async =>
      SearchResult(artists: [], albums: [], songs: []);

  // ── Genres ────────────────────────────────────────────────────────────────

  Future<List<Genre>> getGenres() async => [];

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    final results = await _client.search.search(
      '$genre music',
      filter: yt.TypeFilters.video,
    );
    return results.skip(offset).take(size).map(_videoToSong).toList();
  }

  Future<List<Album>> getAlbumsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async =>
      [];

  // ── Related / Top songs ───────────────────────────────────────────────────

  Future<List<Song>> getSimilarSongs(String videoId, {int count = 50}) async {
    try {
      final video = await _client.videos.get(videoId);
      final related = await _client.videos.getRelatedVideos(video);
      return related?.take(count).map(_videoToSong).toList() ?? [];
    } catch (e) {
      debugPrint('[YouTube] getSimilarSongs error: $e');
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(
    String channelId, {
    int count = 50,
  }) async {
    try {
      final channel = await _client.channels.get(channelId);
      final results = await _client.search.search(
        channel.title,
        filter: yt.TypeFilters.video,
      );
      return results.take(count).map(_videoToSong).toList();
    } catch (e) {
      debugPrint('[YouTube] getArtistTopSongs error: $e');
      return [];
    }
  }
}
