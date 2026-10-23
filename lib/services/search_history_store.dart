import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史（本地持久化，C7；fnos v5_0016：搜索历史 chips 流式换行 + 垃圾桶清空）。
///
/// 最多保留 [maxEntries] 条，去重（新词置顶）。
class SearchHistoryStore {
  static const _key = 'search_history_v1';
  static const int maxEntries = 20;

  Future<List<String>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<String>();
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<String>> add(String term) async {
    final t = term.trim();
    if (t.isEmpty) return load();
    final list = await load();
    list.remove(t);
    list.insert(0, t);
    if (list.length > maxEntries) {
      list.removeRange(maxEntries, list.length);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(list));
    return list;
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}