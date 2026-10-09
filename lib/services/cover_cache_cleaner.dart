import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/image_cache.dart';
import 'diagnostics/diagnostics.dart';

/// Prunes the cover-art disk cache (`<tempDir>/coverCache`) so its total size
/// stays under [maxBytes]. Oldest files (by last-modified time) are deleted
/// first. Run once at startup; it complements the 10000-object cap on
/// [coverCacheManager] by bounding *bytes* — covers are small (tens of KB), so
/// a very large library could otherwise grow into hundreds of MB. Manual
/// clearing remains available in Settings > Storage.
///
/// NOTE: flutter_cache_manager's default `IOFileSystem` stores files under
/// `getTemporaryDirectory()/coverCache` (NOT the app-cache dir) — the cleaner
/// must scan the same location or it never finds anything to delete.
class CoverCacheCleaner {
  static const int _defaultMaxBytes = 512 * 1024 * 1024; // 512 MB
  static const String _cacheDirName = 'coverCache';

  final int _maxBytes;

  CoverCacheCleaner({int maxBytes = _defaultMaxBytes}) : _maxBytes = maxBytes;

  /// Scan the cover-cache directory and remove oldest files until the total
  /// size is ≤ [_maxBytes].  Fire-and-forget at startup.
  ///
  /// Fully async (no `listSync`/`lastModifiedSync`/`lengthSync`): at 10000
  /// files, synchronous stat calls on the main isolate would stall startup by
  /// hundreds of ms. Metadata is collected up-front via async stat calls.
  ///
  /// Deletion goes through [CacheManager.removeFile] (not a raw `deleteSync`):
  /// the cache file name IS the cache key (`CacheObject.relativePath`), and
  /// `removeFile` also drops the matching SQLite record — otherwise we'd leave
  /// stale index entries whose files are gone, making CachedNetworkImage fail
  /// to load those covers without ever re-downloading them.
  Future<void> prune() async {
    try {
      final base = await getTemporaryDirectory();
      final cacheDir = Directory('${base.path}/$_cacheDirName');
      if (!await cacheDir.exists()) return;

      final entries = <({File file, DateTime mtime, int size})>[];
      await for (final entity in cacheDir.list()) {
        if (entity is File) {
          try {
            final mtime = await entity.lastModified();
            final size = await entity.length();
            entries.add((file: entity, mtime: mtime, size: size));
          } catch (_) {
            // File vanished mid-scan (concurrent cleanup); skip it.
          }
        }
      }
      if (entries.isEmpty) return;

      // Sort oldest-first (same strategy as StreamingCacheCleaner).
      entries.sort((a, b) => a.mtime.compareTo(b.mtime));

      var totalSize = entries.fold<int>(0, (s, e) => s + e.size);
      var deletedBytes = 0;
      var deletedCount = 0;
      for (final entry in entries) {
        if (totalSize <= _maxBytes) break;
        final key = entry.file.path.split(Platform.pathSeparator).last;
        await coverCacheManager.removeFile(key);
        totalSize -= entry.size;
        deletedBytes += entry.size;
        deletedCount++;
      }
      if (deletedCount > 0) {
        DiagnosticsService.instance.record(
          EventType.cachePrune,
          LogLevel.info,
          {
            'source': 'coverCache',
            'deletedCount': deletedCount,
            'deletedBytes': deletedBytes,
            'remainingBytes': totalSize,
          },
        );
      }
    } catch (e) {
      debugPrint('[CoverCache] Prune error: $e');
      Log.e('CoverCache', 'prune error', error: e);
    }
  }
}
