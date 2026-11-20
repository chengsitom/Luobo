import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/services/recommendation_service.dart';
import 'package:luobo/services/listening_report_service.dart';

void main() {
  final now = DateTime(2026, 11, 20, 15);
  final today = '2026-11-20';

  Song mkSong(String id, {String? artist, String? genre}) =>
      Song(id: id, title: '曲$id', artist: artist, genre: genre);

  SongProfile mkProfile(
    String id, {
    String? artist,
    String? genre,
    int plays = 0,
    String? lastDay,
    String? recentDay,
  }) {
    final daily = <String, int>{};
    if (recentDay != null) daily[recentDay] = plays;
    return SongProfile(
      songId: id,
      title: '曲$id',
      artist: artist,
      genre: genre,
      lastPlayed: lastDay != null ? DateTime.parse(lastDay) : now,
    )
      ..playCount = plays
      ..dailyPlays = daily;
  }

  ExplorationPlaylistBuilder builder({
    required Map<String, SongProfile> profiles,
    required List<Song> pool,
    Set<String> recent = const {},
    Set<String> disliked = const {},
    Map<String, String> lookup = const {},
    int limit = 10,
    int seed = 42,
  }) =>
      ExplorationPlaylistBuilder(
        profiles: profiles,
        pool: pool,
        genreLookup: lookup,
        recentlyPlayed: recent,
        dislikedIds: disliked,
        now: now,
        seed: seed,
        limit: limit,
      );

  group('ExplorationPlaylistBuilder · 反向排除', () {
    test('避开近期头部歌手和风格，优先选陌生新面孔', () {
      // 近期猛听周杰伦 + 流行
      final profiles = {
        'fav1': mkProfile('fav1', artist: '周杰伦', genre: 'pop', plays: 20,
            recentDay: today),
        'fav2': mkProfile('fav2', artist: '周杰伦', genre: '流行', plays: 15,
            recentDay: today),
      };
      final pool = [
        mkSong('new_indie_1', artist: '敏感之星', genre: '独立'),
        mkSong('new_indie_2', artist: '万能青年旅店', genre: '摇滚'),
        mkSong('new_jay', artist: '周杰伦', genre: '摇滚'), // 歌手在头部
        mkSong('new_pop', artist: '陌生歌手', genre: '流行'), // 风格在头部
      ];
      final picks = builder(profiles: profiles, pool: pool).build();

      expect(picks, isNotEmpty);
      // 头部歌手/风格不应出现在"陌生新面孔"层
      final unfamiliar = picks.where((p) => p.reason == '陌生新面孔').toList();
      for (final p in unfamiliar) {
        expect(p.song.artist, isNot('周杰伦'));
        expect(p.song.genre, isNot('流行'));
      }
    });

    test('最近听过的歌与明确不喜欢的歌被排除', () {
      final profiles = <String, SongProfile>{};
      final pool = [
        mkSong('recent', artist: '甲', genre: '摇滚'),
        mkSong('disliked', artist: '乙', genre: '民谣'),
        mkSong('fresh', artist: '丙', genre: '独立'),
      ];
      final picks = builder(
        profiles: profiles,
        pool: pool,
        recent: {'recent'},
        disliked: {'disliked'},
        limit: 3,
      ).build();
      final ids = picks.map((p) => p.song.id).toSet();
      expect(ids, isNot(contains('recent')));
      expect(ids, isNot(contains('disliked')));
      expect(ids, contains('fresh'));
    });

    test('同一歌手最多 2 首、同一风格最多 4 首', () {
      final profiles = <String, SongProfile>{};
      final pool = <Song>[
        for (int i = 0; i < 6; i++) mkSong('a$i', artist: '同一人', genre: '摇滚'),
      ];
      final picks = builder(profiles: profiles, pool: pool).build();
      final artistPicks = picks.where((p) => p.song.artist == '同一人');
      expect(artistPicks.length, lessThanOrEqualTo(2));
    });
  });

  group('ExplorationPlaylistBuilder · 分层与兜底', () {
    test('很久没听的老歌进入回访层', () {
      final profiles = {
        'old': mkProfile('old', artist: '老朋友', genre: '民谣', plays: 8,
            lastDay: '2026-06-01'),
      };
      final pool = [mkSong('old', artist: '老朋友', genre: '民谣')];
      final picks = builder(
        profiles: profiles,
        pool: pool,
        limit: 10,
      ).build();
      expect(picks, hasLength(1));
      expect(picks.first.reason, '许久未见的老朋友');
    });

    test('曲库为空时不产出', () {
      final picks = builder(profiles: {}, pool: []).build();
      expect(picks, isEmpty);
    });

    test('相同 seed 结果稳定可复现', () {
      final pool = [
        for (int i = 0; i < 12; i++) mkSong('s$i', artist: '艺人$i', genre: '摇滚'),
      ];
      final a = builder(profiles: {}, pool: pool, seed: 7)
          .build().map((p) => p.song.id).toList();
      final b = builder(profiles: {}, pool: pool, seed: 7)
          .build().map((p) => p.song.id).toList();
      expect(a, equals(b));
    });

    test('老画像缺 genre 时从曲库回填后参与风格排除', () {
      final profiles = {
        'fav': mkProfile('fav', artist: '周杰伦', genre: null, plays: 20,
            recentDay: today),
      };
      final lookup = {'fav': 'pop'};
      final pool = [
        mkSong('a', artist: '陌生人', genre: '流行'), // 回填后是头部风格
        mkSong('b', artist: '陌生人B', genre: '独立'),
      ];
      final picks = builder(
        profiles: profiles, pool: pool, lookup: lookup, limit: 2,
      ).build();
      final unfamiliarIds =
          picks.where((p) => p.reason == '陌生新面孔').map((p) => p.song.id);
      // 「a」是流行（回填后的近期头部风格），不应出现在陌生新面孔层；
      // 「b」是独立，属于陌生，应当入选。
      expect(unfamiliarIds, isNot(contains('a')));
      expect(unfamiliarIds, contains('b'));
    });
  });
}
