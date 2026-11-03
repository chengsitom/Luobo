import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/json_coerce.dart';

/// 单本有声书的客户端进度记忆（纯客户端，服务端无进度端点）。
///
/// 设计见 docs/有声书接入技术方案.md §9.1 / §15.6：
/// - `chapterOrder` 为服务端章节序（1-based），与章节的 order 字段一致；
/// - `completed` = 听完最后一章（**保留条目**，"已听完"由此显示；
///   `remove()` 仅用于书被删除/用户主动清除）；
/// - 恢复时按 `chapterOrder` 定位，`chapterId` 仅兜底；
/// - 2026-10-27 新增 `chapterTitle / durationMs / episodeCount / listenedOrders`：
///   用于全书百分比、剩多久、已听/未听筛选。**旧条目缺字段时全部可空**，
///   读取路径与旧行为完全一致（兼容第一批安装的用户数据）。
class AudiobookProgress {
  final String audiobookId; // abk_
  final int chapterOrder; // 1-based 服务端章节序
  final String? chapterId; // abe_ 兜底定位
  final int positionMs;
  final bool completed;
  final DateTime updatedAt;

  /// 当前章节标题（展示「第 X 章 · 标题」，去掉序号前缀由写入方负责）。
  final String? chapterTitle;

  /// 当前章节时长（毫秒），用于计算本章进度与剩余时长。
  final int? durationMs;

  /// 书的总章数（服务端可能变动；读时优先用最新的 `Audiobook.episodeCount`）。
  final int? episodeCount;

  /// 已听完的章节 order 集合（自然播完 / ≥95% / 手动标记）。
  /// 旧数据为空，此时按 `order < chapterOrder` 估算已听章数。
  final List<int> listenedOrders;

  const AudiobookProgress({
    required this.audiobookId,
    required this.chapterOrder,
    this.chapterId,
    required this.positionMs,
    this.completed = false,
    required this.updatedAt,
    this.chapterTitle,
    this.durationMs,
    this.episodeCount,
    this.listenedOrders = const [],
  });

  factory AudiobookProgress.fromJson(
      String audiobookId, Map<String, dynamic> json) {
    return AudiobookProgress(
      audiobookId: audiobookId,
      // 复用 json_coerce 宽容解析（R001 修复）：`as num?` 遇字符串数字抛
      // TypeError，jsonInt/jsonBool 与模型层一致。
      chapterOrder: jsonInt(json['chapterOrder']) ?? 1,
      chapterId: json['chapterId']?.toString(),
      positionMs: jsonInt(json['positionMs']) ?? 0,
      completed: jsonBool(json['completed']) ?? false,
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      chapterTitle: json['chapterTitle']?.toString(),
      durationMs: jsonInt(json['durationMs']),
      episodeCount: jsonInt(json['episodeCount']),
      listenedOrders: _intList(json['listenedOrders']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterOrder': chapterOrder,
      if (chapterId != null) 'chapterId': chapterId,
      'positionMs': positionMs,
      'completed': completed,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
      if (chapterTitle != null && chapterTitle!.isNotEmpty)
        'chapterTitle': chapterTitle,
      if (durationMs != null) 'durationMs': durationMs,
      if (episodeCount != null) 'episodeCount': episodeCount,
      if (listenedOrders.isNotEmpty) 'listenedOrders': listenedOrders,
    };
  }

  AudiobookProgress copyWith({
    int? chapterOrder,
    String? chapterId,
    int? positionMs,
    bool? completed,
    DateTime? updatedAt,
    String? chapterTitle,
    int? durationMs,
    int? episodeCount,
    List<int>? listenedOrders,
  }) {
    return AudiobookProgress(
      audiobookId: audiobookId,
      chapterOrder: chapterOrder ?? this.chapterOrder,
      chapterId: chapterId ?? this.chapterId,
      positionMs: positionMs ?? this.positionMs,
      completed: completed ?? this.completed,
      updatedAt: updatedAt ?? this.updatedAt,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      durationMs: durationMs ?? this.durationMs,
      episodeCount: episodeCount ?? this.episodeCount,
      listenedOrders: listenedOrders ?? this.listenedOrders,
    );
  }

  /// 云端进度条目 → [AudiobookProgress]（**容错解析**，非法返回 null）。
  ///
  /// 真实响应形态（2026-11-02 在本机 Chrome 里实测 `GET /api/library/audiobooks/progress`，
  /// 顶层是**数组**，每项）：
  /// ```json
  /// {"id":"abp_e657…",                     // 进度记录 id，不是书本 id
  ///  "audiobook":{"id":"abk_09dd…","title":"…","episodeCount":311,…},
  ///  "episode":{"id":"abe_833b…","title":"…","order":89,"durationSeconds":886},
  ///  "progressSeconds":630,"durationSeconds":886,
  ///  "completed":false,"lastPlayedAt":"2026-09-24T20:13:51Z","revision":440}
  /// ```
  /// 注意两个坑：① 书本 id 只在 `audiobook.id` 里（顶层 `id` 是 `abp_`）；
  /// ② 列表里时间字段叫 `lastPlayedAt`，单本读 `GET …/{abk}/progress` 叫 `updatedAt`。
  /// 另保留字段名候选，兼容服务端后续改名。
  static AudiobookProgress? fromServerJson(Map<String, dynamic> json) {
    final nestedBook = json['audiobook'] ?? json['book'];
    String? bookId = _firstString([
      json['audiobookId'],
      json['audiobook_id'],
      json['bookId'],
      json['book_id'],
      if (nestedBook is Map) nestedBook['id'],
      // 顶层 id 只在它本身是书本 id 时才用（进度条目自己的 id 前缀不同）
      if (json['id']?.toString().startsWith('abk_') ?? false) json['id'],
    ]);
    if (bookId == null || !bookId.startsWith('abk_')) return null;

    final nestedEpisode = json['episode'] ?? json['chapter'];
    final order = jsonInt(json['chapterOrder']) ??
        jsonInt(json['episodeOrder']) ??
        jsonInt(json['order']) ??
        (nestedEpisode is Map ? jsonInt(nestedEpisode['order']) : null) ??
        1;

    final positionMs = jsonInt(json['positionMs']) ??
        _secondsToMs(json['positionSeconds']) ??
        _secondsToMs(json['position']) ??
        _secondsToMs(
            nestedEpisode is Map ? nestedEpisode['positionSeconds'] : null) ??
        0;

    final updatedAt = DateTime.tryParse(
          (json['updatedAt'] ??
                  json['updated_at'] ??
                  json['lastPlayedAt'] ??
                  json['lastPlayedTime'] ??
                  '')
              .toString(),
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);

    final chapterId = _firstString([
      json['episodeId'],
      json['episode_id'],
      json['chapterId'],
      if (nestedEpisode is Map) nestedEpisode['id'],
    ]);

    return AudiobookProgress(
      audiobookId: bookId,
      chapterOrder: order < 1 ? 1 : order,
      chapterId: chapterId,
      positionMs: positionMs < 0 ? 0 : positionMs,
      completed: jsonBool(json['completed']) ??
          jsonBool(json['finished']) ??
          jsonBool(json['isCompleted']) ??
          false,
      updatedAt: updatedAt,
      // 章节标题真实位置是 `episode.title`（实测）；`episodeTitle/chapterTitle`
      // 是服务端可能改名的兜底。
      chapterTitle: _firstString([
        json['episodeTitle'],
        json['chapterTitle'],
        if (nestedEpisode is Map) nestedEpisode['title'],
      ]),
      // 本章时长优先用顶层 `durationSeconds`（实测 = 本章 886s，与 episode 内一致），
      // 其次是 `durationMs`，最后回退 episode 内字段。
      durationMs: jsonInt(json['durationMs']) ??
          _secondsToMs(json['durationSeconds'] ??
              (nestedEpisode is Map ? nestedEpisode['durationSeconds'] : null)),
      episodeCount: jsonInt(json['episodeCount']) ??
          jsonInt(nestedBook is Map ? nestedBook['episodeCount'] : null),
    );
  }

  static String? _firstString(List<Object?> candidates) {
    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString();
      if (s.isNotEmpty && s != 'null') return s;
    }
    return null;
  }

  static int? _secondsToMs(Object? seconds) {
    final s = jsonInt(seconds);
    if (s == null || s <= 0) return null;
    return s * 1000;
  }

  /// 全书进度 0–1（用于头部百分比与列表进度条）。
  /// - `completed` → 1；
  /// - 优先 `listenedOrders` 的真实已听章数（排除当前章，避免与当前章小数重复计）；
  /// - 旧数据无集合 → 按 `chapterOrder - 1` 估算；
  /// - 当前章小数 = `positionMs / durationMs`（缺时长时按 0）。
  double? progressRatio({int? totalEpisodes}) {
    final total = totalEpisodes ?? episodeCount;
    if (completed) return 1;
    if (total == null || total <= 0) return null;
    final listened = listenedOrders.isNotEmpty
        ? listenedOrders
            .where((o) => o >= 1 && o <= total && o != chapterOrder)
            .length
        : (chapterOrder - 1).clamp(0, total);
    final chapterFraction = (durationMs != null && durationMs! > 0)
        ? (positionMs / durationMs!).clamp(0.0, 1.0)
        : 0.0;
    return ((listened + chapterFraction) / total).clamp(0.0, 1.0);
  }

  /// 已听章数（不含当前章的小数部分），用于「共 N 章 · 已听 M 章」与 chip 计数。
  int listenedCount({int? totalEpisodes}) {
    final total = totalEpisodes ?? episodeCount;
    if (completed) return total ?? listenedOrders.length;
    if (listenedOrders.isNotEmpty) {
      return total == null
          ? listenedOrders.length
          : listenedOrders.where((o) => o >= 1 && o <= total).length;
    }
    final estimated = chapterOrder - 1;
    if (total != null) return estimated.clamp(0, total);
    return estimated < 0 ? 0 : estimated;
  }

  /// 读完一章：写入集合（去重、升序、上限 500 条）。
  AudiobookProgress withListenedChapter(int order) {
    if (order <= 0 || listenedOrders.contains(order)) return this;
    final next = [...listenedOrders, order]..sort();
    return copyWith(
      listenedOrders:
          next.length > 500 ? next.sublist(next.length - 500) : next,
    );
  }

  /// 手动「标记未听」：从集合移除。
  AudiobookProgress withoutListenedChapter(int order) {
    if (!listenedOrders.contains(order)) return this;
    return copyWith(
      listenedOrders:
          listenedOrders.where((o) => o != order).toList(growable: false),
    );
  }

  static List<int> _intList(dynamic value) {
    if (value is! List) return const [];
    final out = <int>[];
    for (final e in value) {
      final n = e is int ? e : int.tryParse(e?.toString() ?? '');
      if (n != null && n > 0 && !out.contains(n)) out.add(n);
    }
    return out;
  }
}

/// 有声书进度存储（SharedPreferences）。
///
/// key 带服务器维度（serverKey = sha256(serverUrl+localUrl+username)[0:12]），
/// 换服务器天然不串数据（§9.4）。
///
/// ⚠️ P2 实现注意：store 内维护**内存 map 缓存**（per serverKey），`save()`
/// 只改内存并异步序列化快照落盘——位置流 1s 写 / 切歌同步写 / 退后台写多路
/// 并发时避免读-改-写竞态丢更新。
class AudiobookProgressStore {
  /// 每服务器保留的进度条目上限，超出按 updatedAt 淘汰（§9.4）。
  static const int maxEntriesPerServer = 20;

  static const String _keyPrefix = 'audiobook_progress_v1_';

  /// 全局共享单例：PlayerProvider（写）、列表页/详情页（读）必须共用同一
  /// 内存缓存，否则各实例 ensureLoaded 各自读盘一次、互相看不到对方的写入
  /// （Meta-Review M001：UI 读到过期进度、播放器首写整键覆盖历史）。
  static final AudiobookProgressStore instance = AudiobookProgressStore();

  /// serverKey → (audiobookId → progress)，内存缓存。
  final Map<String, Map<String, AudiobookProgress>> _cache = {};

  /// serverKey → 已从磁盘加载过的标记。
  final Set<String> _loaded = {};

  /// 计算服务器维度 key：sha256(serverUrl + localUrl + username)[0:12]。
  /// 与 coverCacheServerId（md5）区分：进度 key 要求含 localUrl，换局域网地址
  /// 时同一服务器仍共享进度（LAN↔远程切换不丢）。
  static String computeServerKey({
    required String serverUrl,
    String? localUrl,
    required String username,
  }) {
    final digest = sha256
        .convert(utf8.encode('$serverUrl|${localUrl ?? ''}|$username'))
        .toString();
    return digest.substring(0, 12);
  }

  /// 确保某 serverKey 的内存缓存已从磁盘加载（UI 层进入页面时 await）。
  Future<void> ensureLoaded(String serverKey) async {
    if (_loaded.contains(serverKey)) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_keyPrefix$serverKey');
    final map = <String, AudiobookProgress>{};
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((key, value) {
            if (key is String && value is Map) {
              map[key] = AudiobookProgress.fromJson(
                  key, Map<String, dynamic>.from(value));
            }
          });
        }
      } catch (_) {
        // 损坏数据 → 丢弃（重建空缓存）
      }
    }
    _cache[serverKey] = map;
    _loaded.add(serverKey);
  }

  Map<String, AudiobookProgress> _for(String serverKey) {
    return _cache.putIfAbsent(serverKey, () => {});
  }

  AudiobookProgress? load(String serverKey, String audiobookId) {
    return _for(serverKey)[audiobookId];
  }

  void save(String serverKey, AudiobookProgress progress) {
    final map = _for(serverKey);
    map[progress.audiobookId] = progress;
    _trim(serverKey, map);
    _persist(serverKey, map);
  }

  /// 书被删除 / 用户主动清除（区别于"听完" completed）。
  void remove(String serverKey, String audiobookId) {
    final map = _for(serverKey);
    map.remove(audiobookId);
    _persist(serverKey, map);
  }

  /// 「继续收听」候选：排除 completed 的书，按 updatedAt 倒序。
  List<AudiobookProgress> recent(String serverKey, {int limit = 1}) {
    final entries = _for(serverKey).values.where((p) => !p.completed).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return entries.take(limit).toList();
  }

  /// 合并云端进度：**只在云端比本地新时才覆盖**（last-write-wins by updatedAt）。
  ///
  /// 设计见 `docs/有声书接入技术方案.md` §15.12。两条硬规则：
  /// 1. `skip` 里的书（正在播的那本）一律不覆盖 —— 否则云端旧值会把实时位置
  ///    拽回去，这是这类同步最常见的翻车点；
  /// 2. 云端没有 `listenedOrders`（已听集合是纯客户端字段），合并时与本地做
  ///    **并集**，不丢已听标记；标题/时长/章数云端缺就用本地兜底。
  ///
  /// 返回实际被覆盖的条目数（>0 时整键落盘一次）。
  int mergeRemote(
    String serverKey,
    Iterable<AudiobookProgress> remote, {
    Set<String> skip = const {},
  }) {
    final map = _for(serverKey);
    var applied = 0;
    for (final r in remote) {
      if (skip.contains(r.audiobookId)) continue;
      final local = map[r.audiobookId];
      if (local != null && !r.updatedAt.isAfter(local.updatedAt)) continue;
      final merged = local == null
          ? r
          : r.copyWith(
              listenedOrders:
                  ({...local.listenedOrders, ...r.listenedOrders}.toList()
                    ..sort()),
              durationMs: r.durationMs ?? local.durationMs,
              chapterTitle: r.chapterTitle ?? local.chapterTitle,
              episodeCount: r.episodeCount ?? local.episodeCount,
            );
      map[r.audiobookId] = merged;
      applied++;
    }
    if (applied > 0) {
      _trim(serverKey, map);
      _persist(serverKey, map);
    }
    return applied;
  }

  /// 超出上限按 updatedAt 淘汰最旧条目。
  void _trim(String serverKey, Map<String, AudiobookProgress> map) {
    if (map.length <= maxEntriesPerServer) return;
    final sorted = map.values.toList()
      ..sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
    final excess = sorted.length - maxEntriesPerServer;
    for (var i = 0; i < excess; i++) {
      map.remove(sorted[i].audiobookId);
    }
  }

  void _persist(String serverKey, Map<String, AudiobookProgress> map) {
    final json = {
      for (final e in map.entries) e.key: e.value.toJson(),
    };
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('$_keyPrefix$serverKey', jsonEncode(json));
    }).catchError((Object e) {
      debugPrint('AudiobookProgressStore: persist failed – $e');
    });
  }
}
