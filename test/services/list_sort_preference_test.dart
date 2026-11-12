import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luobo/services/list_sort_preference.dart';
import 'package:luobo/utils/song_sort.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ListSortPreference', () {
    test('从未保存过 → null（由调用方用自己的默认值）', () async {
      expect(await ListSortPreference.load('all_songs'), isNull);
    });

    test('保存后能读回字段与方向', () async {
      await ListSortPreference.save(
        ListSortPreference.scopeAllSongs,
        SongSortField.artist,
        ascending: false,
      );
      final saved = await ListSortPreference.load(
        ListSortPreference.scopeAllSongs,
      );
      expect(saved, isNotNull);
      expect(saved!.field, SongSortField.artist);
      expect(saved.ascending, isFalse);
    });

    test('方向缺省为升序', () async {
      await ListSortPreference.save(
        ListSortPreference.scopeAllSongs,
        SongSortField.album,
        ascending: true,
      );
      final saved = await ListSortPreference.load(
        ListSortPreference.scopeAllSongs,
      );
      expect(saved!.ascending, isTrue);
    });

    test('不同 scope 互不影响', () async {
      await ListSortPreference.save(
        ListSortPreference.scopeAllSongs,
        SongSortField.artist,
        ascending: false,
      );
      expect(await ListSortPreference.load('albums'), isNull);
    });

    test('字段值是枚举 name（不是 index）—— 将来调序不会错位', () async {
      await ListSortPreference.save(
        ListSortPreference.scopeAllSongs,
        SongSortField.recentlyAdded,
        ascending: true,
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('list_sort_all_songs_field'), 'recentlyAdded');
    });

    test('存了不认识的值（老版本/脏数据）→ null，退回默认排序', () async {
      SharedPreferences.setMockInitialValues({
        'list_sort_all_songs_field': 'bitrate',
      });
      expect(await ListSortPreference.load('all_songs'), isNull);
    });
  });
}
