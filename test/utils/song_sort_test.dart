import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/utils/song_sort.dart';

/// 排序单测（`docs/锚定浮层与列表页排序技术方案.md` §6.1）。
///
/// 重点不是"新模型能排"，而是 **「字段 + 方向」与旧 7 个扁平枚举值的结果逐一等价**
/// —— 防的是「重构把排序改坏」。
Song _s(
  String id,
  String title, {
  String? artist,
  String? album,
  DateTime? created,
}) =>
    Song(id: id, title: title, artist: artist, album: album, created: created);

List<String> _ids(List<Song> songs) => songs.map((s) => s.id).toList();

void main() {
  // 故意混合大小写（验证 toLowerCase）、混合空值（验证 ?? ''）、
  // 以及 created 的 null（验证排最后）。
  final sample = [
    _s('b', 'banana', artist: 'Zed', album: 'Beta', created: DateTime(2024, 5)),
    _s('a', 'Apple', artist: 'amy', album: 'alpha', created: DateTime(2023, 1)),
    _s('c', 'cherry', artist: 'Bob', album: 'Gamma'),
    _s('d', 'Durian', album: 'Beta', created: DateTime(2025, 9)),
  ];

  group('字段 + 方向', () {
    test('标题 升/降（大小写不敏感）', () {
      expect(
        _ids(sortSongs(sample, SongSortField.title)),
        ['a', 'b', 'c', 'd'], // Apple, banana, cherry, Durian
      );
      expect(
        _ids(sortSongs(sample, SongSortField.title, ascending: false)),
        ['d', 'c', 'b', 'a'],
      );
    });

    test('艺术家 升/降（空值当空串）', () {
      expect(
        _ids(sortSongs(sample, SongSortField.artist)),
        ['d', 'a', 'c', 'b'], // '', amy, Bob, Zed
      );
      expect(
        _ids(sortSongs(sample, SongSortField.artist, ascending: false)),
        ['b', 'c', 'a', 'd'],
      );
    });

    test('专辑 升/降（空值当空串）', () {
      expect(
        _ids(sortSongs(sample, SongSortField.album)),
        ['a', 'b', 'd', 'c'], // alpha, Beta, Beta, Gamma
      );
      expect(
        _ids(sortSongs(sample, SongSortField.album, ascending: false)),
        ['c', 'b', 'd', 'a'],
      );
    });
  });

  group('recentlyAdded：自带方向，ascending 无效', () {
    test('新的在前，created 为 null 的排最后', () {
      expect(
        _ids(sortSongs(sample, SongSortField.recentlyAdded)),
        ['d', 'b', 'a', 'c'], // 2025, 2024, 2023, null
      );
    });

    test('传 ascending: false 结果不变（该字段不吃方向）', () {
      expect(
        _ids(sortSongs(sample, SongSortField.recentlyAdded, ascending: false)),
        _ids(sortSongs(sample, SongSortField.recentlyAdded)),
      );
    });

    test('不显示方向箭头', () {
      expect(songSortShowsDirection(SongSortField.recentlyAdded), isFalse);
      for (final f in [
        SongSortField.title,
        SongSortField.artist,
        SongSortField.album,
      ]) {
        expect(songSortShowsDirection(f), isTrue);
      }
    });
  });

  group('回归等价性：与旧 7 个扁平枚举值逐一对照', () {
    // 旧实现的 7 个 case 逐条抄下来（含 recentlyAdded 的 null 兜底），
    // 断言新模型能复现完全相同的顺序。
    List<String> oldTitleAsc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
            ),
        );
    List<String> oldTitleDesc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()),
            ),
        );
    List<String> oldArtistAsc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => (a.artist ?? '')
                  .toLowerCase()
                  .compareTo((b.artist ?? '').toLowerCase()),
            ),
        );
    List<String> oldArtistDesc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => (b.artist ?? '')
                  .toLowerCase()
                  .compareTo((a.artist ?? '').toLowerCase()),
            ),
        );
    List<String> oldAlbumAsc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => (a.album ?? '')
                  .toLowerCase()
                  .compareTo((b.album ?? '').toLowerCase()),
            ),
        );
    List<String> oldAlbumDesc() => _ids(
          List<Song>.from(sample)
            ..sort(
              (a, b) => (b.album ?? '')
                  .toLowerCase()
                  .compareTo((a.album ?? '').toLowerCase()),
            ),
        );
    List<String> oldRecentlyAdded() => _ids(
          List<Song>.from(sample)
            ..sort((a, b) {
              final aCreated = a.created;
              final bCreated = b.created;
              if (aCreated == null && bCreated == null) return 0;
              if (aCreated == null) return 1;
              if (bCreated == null) return -1;
              return bCreated.compareTo(aCreated);
            }),
        );

    test('titleAsc / titleDesc', () {
      expect(_ids(sortSongs(sample, SongSortField.title)), oldTitleAsc());
      expect(
        _ids(sortSongs(sample, SongSortField.title, ascending: false)),
        oldTitleDesc(),
      );
    });

    test('artistAsc / artistDesc', () {
      expect(_ids(sortSongs(sample, SongSortField.artist)), oldArtistAsc());
      expect(
        _ids(sortSongs(sample, SongSortField.artist, ascending: false)),
        oldArtistDesc(),
      );
    });

    test('albumAsc / albumDesc', () {
      expect(_ids(sortSongs(sample, SongSortField.album)), oldAlbumAsc());
      expect(
        _ids(sortSongs(sample, SongSortField.album, ascending: false)),
        oldAlbumDesc(),
      );
    });

    test('recentlyAdded', () {
      expect(
        _ids(sortSongs(sample, SongSortField.recentlyAdded)),
        oldRecentlyAdded(),
      );
    });
  });

  test('不改动入参列表', () {
    final before = _ids(sample);
    sortSongs(sample, SongSortField.title, ascending: false);
    expect(_ids(sample), before);
  });
}
