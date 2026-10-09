import 'dart:io';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Single request size for cover art across the whole app. Every screen asks
/// the server for the same pixels, so one cover = one URL = one server-side
/// resize entry + one client disk entry + one memory decode, regardless of
/// where it's shown. 300px is indistinguishable from larger sizes on a phone
/// screen (see docs/图片缓存与播放性能优化技术文档.md §4.2).
const int kCoverArtRequestSize = 300;

/// Shared HTTP client for cover downloads. Lazily created on first use so it
/// inherits the global [HttpOverrides] installed by
/// `SubsonicService._configureCertificateValidation` (self-signed / custom CA)
/// at login — a top-level `final` would be created before that and miss the
/// certificate settings. Sharing one client gives keep-alive connection reuse
/// across all cover downloads instead of a fresh TCP+TLS handshake per image.
http.Client get coverHttpClient => _coverHttpClient ??= http.Client();
http.Client? _coverHttpClient;

/// File service that hands every cover download the shared [coverHttpClient].
/// Wrapped lazily so the underlying `http.Client` (and its dart:io HttpClient
/// underneath, which honours the global HttpOverrides) is created only when
/// the first cover is actually fetched — i.e. after login has configured
/// certificate validation.
class _CoverFileService extends FileService {
  HttpFileService? _delegate;

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) {
    return (_delegate ??= HttpFileService(httpClient: coverHttpClient))
        .get(url, headers: headers);
  }
}

/// Shared disk-cache manager for cover art, keyed by a semantic
/// `coverArt-<serverId>-<id>-<size>` key (see [coverArtCacheKey]) instead of
/// the raw URL, so password changes / server re-configuration don't invalidate
/// the whole cache. 10000 objects ≈ a 10000-cover library without eviction;
/// the 60-day staleness window doubles as the only automatic refresh for
/// covers whose artwork changed server-side (the URL carries no version).
final CacheManager coverCacheManager = CacheManager(
  Config(
    'coverCache',
    stalePeriod: const Duration(days: 60),
    maxNrOfCacheObjects: 10000,
    fileService: _CoverFileService(),
  ),
);

/// Scopes cover-cache keys per (server, account) so switching servers /
/// accounts never collides. Registered on login. Deliberately excludes the
/// password — changing it must not invalidate cached covers.
String _coverCacheServerId = '';
void registerCoverCacheServerId(String serverId) {
  _coverCacheServerId = serverId;
}

String get coverCacheServerId => _coverCacheServerId;

/// 封面磁盘缓存的字节数（与 [coverCacheManager] 同一口径）。
///
/// `flutter_cache_manager` 的默认 IOFileSystem 落在**临时目录**而不是
/// app-cache 目录，所以按 `<tempDir>/coverCache` 递归求和。
/// App 设置页与「下载与存储」页共用，避免同一目录两处各算一遍。
Future<int> coverCacheDirSize() async {
  try {
    final base = await getTemporaryDirectory();
    final dir = Directory('${base.path}/coverCache');
    if (!await dir.exists()) return 0;
    var total = 0;
    await for (final f in dir.list(recursive: true, followLinks: false)) {
      if (f is File) total += await f.length();
    }
    return total;
  } catch (_) {
    return 0;
  }
}

/// Semantic disk-cache key for a cover: stable across password changes
/// (serverId excludes the password), per-server isolated, and queryable by id
/// (e.g. `player_provider` looks up the 600px variant by id).
String coverArtCacheKey(String coverArtId, {int size = kCoverArtRequestSize}) {
  return 'coverArt-$_coverCacheServerId-$coverArtId-$size';
}

/// URL-based variant for call sites that only hold the built cover URL.
/// Parses id/size back out of the getCoverArtUrl query string so it yields the
/// exact same key as [coverArtCacheKey]; falls back to the URL itself when
/// parsing fails (non-Subsonic families like Jellyfin/YouTube).
String coverArtCacheKeyFromUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final id = uri.queryParameters['id'];
    if (id == null || id.isEmpty) return url;
    final size = int.tryParse(uri.queryParameters['size'] ?? '');
    return coverArtCacheKey(id, size: size ?? kCoverArtRequestSize);
  } catch (_) {
    return url;
  }
}

class ImageCacheConfig {
  static void configure() {
    // Large enough to hold several screens of covers in memory so fast
    // scrolling doesn't repeatedly re-decode images from disk.
    PaintingBinding.instance.imageCache.maximumSize = 300;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20;
  }
}

class ImagePreloader {
  static Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      if (url.isNotEmpty) {
        try {
          await precacheImage(
              CachedNetworkImageProvider(url,
                  cacheManager: coverCacheManager,
                  cacheKey: coverArtCacheKeyFromUrl(url)),
              context);
        } catch (_) {}
      }
    }
  }

  static Future<void> preloadImage(
    BuildContext context,
    String imageUrl,
  ) async {
    if (imageUrl.isEmpty) return;

    try {
      await precacheImage(
          CachedNetworkImageProvider(imageUrl,
              cacheManager: coverCacheManager,
              cacheKey: coverArtCacheKeyFromUrl(imageUrl)),
          context);
    } catch (_) {}
  }
}
