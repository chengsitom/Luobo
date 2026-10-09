import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 最近播放的集合（歌单 / 收藏列表），用于首页「最近播放」混合区。
class RecentlyPlayedCollection {
  /// 'playlist'（手动歌单）| 'starred'（收藏列表）。
  final String kind;
  final String id;
  final String name;

  /// 2×2 拼图封面（≤4 张；歌单有服务端封面时可为单张）。
  final List<String> coverArts;
  final DateTime playedAt;

  const RecentlyPlayedCollection({
    required this.kind,
    required this.id,
    required this.name,
    required this.coverArts,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'id': id,
        'name': name,
        'coverArts': coverArts,
        'playedAt': playedAt.millisecondsSinceEpoch,
      };

  factory RecentlyPlayedCollection.fromJson(Map<String, dynamic> json) =>
      RecentlyPlayedCollection(
        kind: json['kind'] as String,
        id: json['id'] as String,
        name: json['name'] as String,
        coverArts:
            (json['coverArts'] as List?)?.map((e) => e as String).toList() ??
                const [],
        playedAt: DateTime.fromMillisecondsSinceEpoch(json['playedAt'] as int),
      );
}

/// 播放来源追踪：记录「最近播放的手动歌单 / 收藏列表」。
///
/// 首页「最近播放」模块据此展示 2×2 拼图歌单卡（§5.1）。SharedPreferences
/// 持久化，上限 10 条，同一歌单/收藏重复播放只刷新时间并置顶。
class PlaybackContextTracker extends ChangeNotifier {
  static const String _prefsKey = 'recently_played_collections';
  static const int maxEntries = 10;

  final List<RecentlyPlayedCollection> _items = [];

  /// 最近播放的歌单/收藏（最新在前）。
  List<RecentlyPlayedCollection> get items => List.unmodifiable(_items);

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      _items
        ..clear()
        ..addAll(
          decoded.map((e) =>
              RecentlyPlayedCollection.fromJson(e as Map<String, dynamic>)),
        );
    } catch (_) {
      // 数据损坏时忽略，从空列表开始。
    }
    notifyListeners();
  }

  /// 记录一次歌单/收藏列表播放（去重 + 置顶 + 上限裁剪 + 持久化）。
  Future<void> record({
    required String kind,
    required String id,
    required String name,
    List<String> coverArts = const [],
  }) async {
    _items.removeWhere((e) => e.kind == kind && e.id == id);
    _items.insert(
      0,
      RecentlyPlayedCollection(
        kind: kind,
        id: id,
        name: name,
        coverArts: coverArts.take(4).toList(),
        playedAt: DateTime.now(),
      ),
    );
    if (_items.length > maxEntries) {
      _items.removeRange(maxEntries, _items.length);
    }
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((e) => e.toJson()).toList()),
    );
  }
}
