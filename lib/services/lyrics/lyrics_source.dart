import 'package:flutter/foundation.dart';

import '../../models/song.dart';
import '../lrclib_service.dart';
import '../netease_lyrics_service.dart';
import '../offline_service.dart';
import '../storage_service.dart';
import '../subsonic_service.dart';
import 'lrc_parser.dart';
import 'lyrics_cache.dart';

/// 一次取源的结果（已归一化，不含任何「服务器返回形状」的痕迹）。
class LyricsFetchResult {
  const LyricsFetchResult({
    required this.source,
    required this.raw,
    required this.isLrc,
  });

  /// 实际命中的来源。
  final LyricsCacheSource source;

  /// 原始歌词文本（LRC 或纯文本）。
  final String raw;

  /// [raw] 是否含可被时间轴消费的歌词行。
  final bool isLrc;

  @override
  String toString() => 'LyricsFetchResult(${source.wireName}, isLrc=$isLrc)';
}

/// 歌词取源链的**唯一实现**（`docs/歌词源优先级修复技术方案.md` §4.1 / §5.4 第 12 项）。
///
/// 顺序以 App 内歌词页现有顺序为准（作为全项目唯一顺序）：
///
/// ```
/// 本地缓存（含来源判定与会话级复查）
///   → getLyricsBySongId   → getLyrics(artist, title, id)
///     → LRCLIB 兜底（开关，默认关）
///       → 网易云兜底（开关，默认开）
/// ```
///
/// 服务器与兜底命中后写回本地缓存（带 `source` 标记）；拿不到返回 null。
///
/// P0 仅车机链（`PlayerProvider._loadAndSyncLyrics`）接入；P1 再把三个 UI 入口
/// 迁到同一实现（§8.1）。
class LyricsSourceService {
  LyricsSourceService({
    required SubsonicService subsonic,
    OfflineService? offline,
    StorageService? storage,
  })  : _subsonic = subsonic,
        _offline = offline ?? OfflineService(),
        _storage = storage ?? StorageService();

  final SubsonicService _subsonic;
  final OfflineService _offline;
  final StorageService _storage;

  /// 服务器歌词的来源标记（道理鱼自研接口与其它服务器分开记录，便于排查）。
  LyricsCacheSource get _serverSource => _subsonic.isDaoliyu
      ? LyricsCacheSource.daoliyu
      : LyricsCacheSource.server;

  /// 取这首歌的歌词；返回 null 表示「确实没有歌词」（调用方应清空）。
  Future<LyricsFetchResult?> fetchForSong(Song song) async {
    // ① 缓存（含「服务器来源直接信任」与「兜底来源会话级复查」）
    final cached = await _offline.getLocalLyrics(song.id);
    final outcome = await resolveLyricsCache(
      songId: song.id,
      cached: cached,
      serverSource: _serverSource,
      fetchServerLyrics: () => _subsonic.getLyricsBySongId(song.id),
      saveCache: (payload) => _offline.saveLyrics(song.id, payload),
    );
    final fromCache = outcome.payload == null
        ? null
        : _resultFromPayload(
            outcome.payload!,
            outcome.source ?? _serverSource,
          );
    if (fromCache != null) return fromCache;

    // ② 服务器：getLyricsBySongId
    final byId = await _subsonic.getLyricsBySongId(song.id);
    final byIdResult =
        byId == null ? null : _resultFromPayload(byId, _serverSource);
    if (byIdResult != null) {
      await _offline.saveLyrics(
        song.id,
        withLyricsCacheMeta({'lyricsList': byId}, _serverSource),
      );
      return byIdResult;
    }

    // ③ 服务器：getLyrics(artist, title, id)（普通歌词接口，UI 侧一直在用）
    final byMeta = await _subsonic.getLyrics(
      artist: song.artist,
      title: song.title,
      id: song.id,
    );
    final byMetaResult =
        byMeta == null ? null : _resultFromPayload(byMeta, _serverSource);
    if (byMetaResult != null) {
      await _offline.saveLyrics(
        song.id,
        withLyricsCacheMeta({'lyrics': byMeta}, _serverSource),
      );
      return byMetaResult;
    }

    // ④ LRCLIB 兜底（开关默认关）
    final lrclib = await _tryFallback(
      song,
      enabled: await _storage.getLrcLibFallback(),
      source: LyricsCacheSource.lrclib,
      fetch: (artist) => LrcLibService().searchLyrics(
        artist: artist,
        title: song.title,
        durationSeconds: song.duration,
      ),
    );
    if (lrclib != null) return lrclib;

    // ⑤ 网易云兜底（开关默认开）
    return _tryFallback(
      song,
      enabled: await _storage.getNeteaseFallback(),
      source: LyricsCacheSource.netease,
      fetch: (artist) => NeteaseLyricsService().searchLyrics(
        artist: artist,
        title: song.title,
        durationSeconds: song.duration,
      ),
    );
  }

  /// 兜底源统一处理：开关 + artist 守卫 + 命中后写缓存（带 source 标记）。
  Future<LyricsFetchResult?> _tryFallback(
    Song song, {
    required bool enabled,
    required LyricsCacheSource source,
    required Future<Map<String, dynamic>?> Function(String artist) fetch,
  }) async {
    final artist = song.artist;
    if (!enabled || artist == null || artist.isEmpty) return null;

    try {
      final payload = await fetch(artist);
      if (payload == null) return null;

      final result = _resultFromPayload(payload, source);
      if (result == null) return null;

      await _offline.saveLyrics(
        song.id,
        withLyricsCacheMeta(fallbackCachePayload(payload), source),
      );
      return result;
    } catch (e) {
      // 兜底失败不阻塞、不抛出（与既有 UI 侧行为一致）。
      debugPrint('[LyricsSource] $source fallback failed: $e');
      return null;
    }
  }

  LyricsFetchResult? _resultFromPayload(
    Map<String, dynamic> payload,
    LyricsCacheSource source,
  ) {
    final raw = extractLyricsText(payload);
    if (raw == null) return null;
    return LyricsFetchResult(
      source: source,
      raw: raw,
      isLrc: hasLrcTimeline(raw),
    );
  }
}

/// 把服务器/兜底返回的 payload 归一化成**歌词文本**（消灭形状差异）。
///
/// 支持全部已知形状：
///   • `{'lyrics': '<LRC 文本>'}` —— Subsonic `getLyricsBySongId` / 道理鱼自研
///   • `{'structuredLyrics': [{'synced': true, 'line': [...]}]}` —— 其中每行
///     同时兼容 Subsonic 的 `{start, value}` 与 Jellyfin 的 `{startTicks, text}`
///   • `{'value': '<LRC 或纯文本>'}` —— Subsonic `getLyrics` / LRCLIB / 网易云
///   • **缓存外壳** `{'lyricsList': <上面任一种>}` / `{'lyrics': <上面任一种>}`
///     —— 从本地缓存文件读回来的是这一层，必须能继续往里剥
///
/// 返回 null 表示该 payload 不含可用歌词。
String? extractLyricsText(Map<String, dynamic> payload, {int depth = 0}) {
  // 深度上限：缓存外壳 → 内层，最多剥两层，避免异常数据导致无限递归。
  if (depth > 2) return null;

  // ① 缓存外壳（{'lyricsList': {...}} 或 {'lyrics': {...}}）→ 递归剥内层
  for (final key in const ['lyricsList', 'lyrics']) {
    final nested = payload[key];
    if (nested is Map) {
      final inner = extractLyricsText(
        Map<String, dynamic>.from(nested),
        depth: depth + 1,
      );
      if (inner != null) return inner;
    }
  }

  // ② 原始 LRC 字符串（无损优先）
  final direct = payload['lyrics'];
  if (direct is String && direct.trim().isNotEmpty) return direct;

  // ③ 行数组 → 重建 LRC
  final structured = payload['structuredLyrics'];
  if (structured is List && structured.isNotEmpty) {
    final lines = structuredToLines(structured);
    if (lines.isNotEmpty) return linesToLrc(lines);
  }

  // ④ value（可能是 LRC，也可能是纯文本）
  final value = payload['value'];
  if (value is String && value.trim().isNotEmpty) return value;

  return null;
}

/// `structuredLyrics` → 统一行数组，**同时兼容两种字段命名**：
/// Subsonic 的 `{start(ms), value}` 与 Jellyfin 的 `{startTicks(100ns), text}`。
///
/// 这是 `docs/歌词源优先级修复技术方案.md` §2.6(b) 的修复点：此前车机链只认
/// `{startTicks, text}`、三个 UI 入口只认 `{start, value}`，同一份响应必有一边
/// 解析成空行。
List<Map<String, dynamic>> structuredToLines(List<dynamic> structured) {
  for (final entry in structured) {
    if (entry is! Map) continue;
    if (entry['synced'] != true) continue;

    final rawLines = entry['line'];
    if (rawLines is! List) continue;

    final lines = <Map<String, dynamic>>[];
    for (final raw in rawLines) {
      if (raw is! Map) continue;

      final text = (raw['value'] ?? raw['text'])?.toString().trim() ?? '';
      if (text.isEmpty) continue;

      final int? startMs;
      if (raw['start'] is num) {
        startMs = (raw['start'] as num).toInt();
      } else if (raw['startTicks'] is num) {
        // Jellyfin 的 startTicks 单位为 100 纳秒
        startMs = (raw['startTicks'] as num).toInt() ~/ 10000;
      } else {
        startMs = null;
      }
      if (startMs == null || startMs < 0) continue;

      lines.add({'start': startMs, 'value': text});
    }
    if (lines.isNotEmpty) return lines;
  }
  return const [];
}

/// 兜底结果写入缓存时使用的 payload 形状（沿用既有约定）：
/// structured 形状放 `lyricsList`，其余（含 `value`）放 `lyrics`。
Map<String, dynamic> fallbackCachePayload(Map<String, dynamic> payload) {
  return payload.containsKey('structuredLyrics')
      ? {'lyricsList': payload}
      : {'lyrics': payload};
}
