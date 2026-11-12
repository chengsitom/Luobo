import 'package:shared_preferences/shared_preferences.dart';

import '../utils/song_sort.dart';

/// 列表页排序偏好（字段 + 方向）的本地持久化。
///
/// 背景：`all_songs_screen` 原来的排序是 `State` 内存态，**退出页面即重置**，
/// 每次进来都要重选。这里把「字段 + 方向」落到 SharedPreferences。
///
/// 按 [scope] 分域（`all_songs` / 将来的 `albums` `artists` `playlist:<id>`），
/// 这样一张表能服务所有列表页，互不干扰。
///
/// 字段用**枚举 name 字符串**存，不存 index —— 将来枚举增删或调序不会让老用户
/// 的偏好错位；读到不认识的值一律当「没有偏好」，退回默认排序。
class ListSortPreference {
  ListSortPreference._();

  static const String _prefix = 'list_sort_';

  /// 歌曲全库列表的 scope。
  static const String scopeAllSongs = 'all_songs';

  /// 收藏（歌曲）页。
  static const String scopeFavorites = 'favorites';

  /// 歌手详情页的歌曲列表（**所有歌手共用一个偏好**，符合「列表类型一致」的预期）。
  static const String scopeArtist = 'artist';

  /// 歌单详情页的歌曲列表（同上，按类型共享而不是按歌单各存一份）。
  static const String scopePlaylist = 'playlist';

  static const String scopeAlbums = 'albums';

  static String _fieldKey(String scope) => '$_prefix${scope}_field';

  static String _ascKey(String scope) => '$_prefix${scope}_asc';

  /// 读取某列表的排序偏好；从未保存过、或存的值不可识别 → 返回 null。
  ///
  /// 返回 null 时由调用方使用自己的默认值，**不要**在这里硬编码默认字段，
  /// 否则各列表的默认排序会被悄悄统一。
  static Future<({SongSortField field, bool ascending})?> load(
    String scope,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_fieldKey(scope));
      final field = _decodeField(raw);
      if (field == null) return null;
      return (field: field, ascending: prefs.getBool(_ascKey(scope)) ?? true);
    } catch (_) {
      // 偏好读失败绝不能影响列表可用性。
      return null;
    }
  }

  /// 保存排序偏好（字段变化、方向翻转时调用）。
  static Future<void> save(
    String scope,
    SongSortField field, {
    required bool ascending,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fieldKey(scope), field.name);
      await prefs.setBool(_ascKey(scope), ascending);
    } catch (_) {}
  }

  static SongSortField? _decodeField(String? raw) {
    if (raw == null) return null;
    for (final field in SongSortField.values) {
      if (field.name == raw) return field;
    }
    return null;
  }
}
