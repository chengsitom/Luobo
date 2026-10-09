import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/json_coerce.dart';

/// 单本有声书的客户端进度记忆（纯客户端，服务端无进度端点）。
///
/// 设计见 docs/有声书接入技术方案.md §9.1：
/// - `chapterOrder` 为服务端章节序（1-based），与章节的 order 字段一致；
/// - `completed` = 听完最后一章（**保留条目**，"已听完"由此显示；
///   `remove()` 仅用于书被删除/用户主动清除）；
/// - 恢复时按 `chapterOrder` 定位，`chapterId` 仅兜底。
class AudiobookProgress {
  final String audiobookId; // abk_
  final int chapterOrder; // 1-based 服务端章节序
  final String? chapterId; // abe_ 兜底定位
  final int positionMs;
  final bool completed;
  final DateTime updatedAt;

  const AudiobookProgress({
    required this.audiobookId,
    required this.chapterOrder,
    this.chapterId,
    required this.positionMs,
    this.completed = false,
    required this.updatedAt,
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chapterOrder': chapterOrder,
      if (chapterId != null) 'chapterId': chapterId,
      'positionMs': positionMs,
      'completed': completed,
      'updatedAt': updatedAt.toUtc().toIso8601String(),
    };
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
