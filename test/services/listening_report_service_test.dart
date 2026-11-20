import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/recommendation_service.dart';
import 'package:luobo/services/listening_report_service.dart';

void main() {
  // 固定「现在」，让所有窗口计算可确定。
  final now = DateTime(2026, 11, 20, 15);

  SongProfile mk({
    required String id,
    required String title,
    String? artist,
    String? genre,
    String? albumId,
    int plays = 0,
    int completed = 0,
    int skips = 0,
    Map<int, int> hourly = const {},
    Map<String, int> daily = const {},
    Map<String, int> monthly = const {},
    DateTime? lastPlayed,
  }) {
    return SongProfile(
      songId: id,
      title: title,
      artist: artist,
      genre: genre,
      albumId: albumId,
    )
      ..playCount = plays
      ..completedPlays = completed
      ..skipCount = skips
      ..totalListenTime = plays * 200
      ..hourlyPlays = Map.from(hourly)
      ..dailyPlays = Map.from(daily)
      ..monthlyPlays = Map.from(monthly)
      ..lastPlayed = lastPlayed ?? now;
  }

  ListeningInsight build(
    Map<String, SongProfile> profiles, {
    Set<String> starred = const {},
    Map<String, String> genreLookup = const {},
  }) =>
      ListeningInsightBuilder(profiles, now: now,
          starredSongIds: starred, genreLookup: genreLookup).build();

  group('ListeningInsightBuilder · 人格', () {
    test('深夜高频 + 高完播 → 深夜沉浸者，且钩子句带时段数字', () {
      final insight = build({
        'a': mk(
          id: 'a',
          title: 'A',
          artist: '甲',
          plays: 20,
          completed: 19,
          hourly: {23: 15, 1: 5},
          daily: {'2026-10-01': 20},
        ),
      });
      expect(insight.persona.title, '深夜沉浸者');
      expect(insight.persona.headline, contains('22 点之后'));
      expect(insight.persona.headline, contains('20 首'));
      expect(insight.persona.traits, contains('夜猫子'));
      expect(insight.persona.traits, contains('完播达人'));
    });

    test('深夜高频 + 低完播 → 深夜漫游者', () {
      final insight = build({
        'a': mk(
          id: 'a',
          title: 'A',
          artist: '甲',
          plays: 10,
          completed: 3,
          hourly: {23: 10},
          daily: {'2026-10-01': 10},
        ),
      });
      expect(insight.persona.title, '深夜漫游者');
      expect(insight.persona.traits, contains('挑剔耳朵'));
    });

    test('白天高频 + 歌手分散 → 通勤浏览者；歌手集中 → 白日循环控', () {
      // 5 位歌手各 2 次，头部占比 0.2，确实算「分散」。
      final scattered = build({
        for (var i = 0; i < 5; i++)
          's$i': mk(id: 's$i', title: 'S$i', artist: '歌手$i', plays: 2,
              hourly: {10: 2}, daily: {'2026-10-01': 2}),
      });
      expect(scattered.persona.title, '通勤浏览者');

      final focused = build({
        'a': mk(id: 'a', title: 'A', artist: '甲', plays: 9,
            hourly: {10: 9}, daily: {'2026-10-01': 9}),
        'b': mk(id: 'b', title: 'B', artist: '乙', plays: 1,
            hourly: {11: 1}, daily: {'2026-10-01': 1}),
      });
      expect(focused.persona.title, '白日循环控');
      expect(focused.persona.traits, contains('专一派'));
    });

    test('完全无时段数据时退化为「音乐探索者」，不报错', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', artist: '甲', plays: 2,
            daily: {'2026-10-01': 2}),
      });
      expect(insight.persona.title, '音乐探索者');
    });
  });

  group('ListeningInsightBuilder · 口味指纹', () {
    test('pop / 流行音乐 / 华语流行 归一为「流行」并累加', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', genre: 'pop', plays: 3,
            daily: {'2026-10-01': 3}),
        'b': mk(id: 'b', title: 'B', genre: '流行音乐', plays: 4,
            daily: {'2026-10-01': 4}),
        'c': mk(id: 'c', title: 'C', genre: '华语流行', plays: 3,
            daily: {'2026-10-01': 3}),
      });
      expect(insight.flavorPrint, hasLength(1));
      expect(insight.flavorPrint.first.name, '流行');
      expect(insight.flavorPrint.first.plays, 10);
      expect(insight.flavorPrint.first.percent, closeTo(100, 0.01));
    });

    test('占比按有效播放计算', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', genre: 'pop', plays: 3,
            daily: {'2026-10-01': 3}),
        'b': mk(id: 'b', title: 'B', genre: 'rock', plays: 1,
            daily: {'2026-10-01': 1}),
      });
      expect(insight.flavorPrint.first.percent, closeTo(75, 0.01));
      expect(insight.flavorPrint[1].percent, closeTo(25, 0.01));
    });
  });

  group('ListeningInsightBuilder · 口味变迁', () {
    test('近 30 天与之前头部歌手不同 → 产出变迁', () {
      final insight = build({
        'old': mk(id: 'old', title: '旧歌', artist: '甲', plays: 5,
            daily: {'2026-10-01': 5}),
        'new': mk(id: 'new', title: '新歌', artist: '乙', plays: 6,
            daily: {'2026-11-10': 6}),
      });
      final shift = insight.flavorShift;
      expect(shift, isNotNull);
      expect(shift!.hasArtistShift, isTrue);
      expect(shift.fromArtist, '甲');
      expect(shift.toArtist, '乙');
      expect(shift.fromPlays, 5);
      expect(shift.toPlays, 6);
    });

    test('两个窗口头部歌手相同 → 不产出变迁', () {
      final insight = build({
        'old': mk(id: 'old', title: '旧歌', artist: '甲', plays: 5,
            daily: {'2026-10-01': 5}),
        'new': mk(id: 'new', title: '新歌', artist: '甲', plays: 6,
            daily: {'2026-11-10': 6}),
      });
      expect(insight.flavorShift, isNull);
    });

    test('旧窗口无数据 → 不产出变迁', () {
      final insight = build({
        'new': mk(id: 'new', title: '新歌', artist: '乙', plays: 6,
            daily: {'2026-11-10': 6}),
      });
      expect(insight.flavorShift, isNull);
    });
  });

  group('ListeningInsightBuilder · 时光机', () {
    test('识别初见、最长陪伴与上头月', () {
      final insight = build({
        'loyal': mk(
          id: 'loyal',
          title: '老朋友',
          artist: '甲',
          plays: 8,
          daily: {'2026-01-10': 2, '2026-11-19': 6},
          monthly: {'2026-01': 2, '2026-11': 6},
        ),
        'other': mk(
          id: 'other',
          title: '别的歌',
          artist: '乙',
          plays: 2,
          daily: {'2026-03-01': 2},
          monthly: {'2026-03': 2},
        ),
      });
      final kinds = insight.timeCapsule.map((e) => e.kind).toList();
      expect(kinds, contains('初见'));
      expect(kinds, contains('最长陪伴'));
      expect(kinds, contains('上头月'));

      final first = insight.timeCapsule.firstWhere((e) => e.kind == '初见');
      expect(first.title, '老朋友');
      expect(first.detail, contains('2026'));

      final loyal = insight.timeCapsule.firstWhere((e) => e.kind == '最长陪伴');
      expect(loyal.title, '老朋友');

      final peak = insight.timeCapsule.firstWhere((e) => e.kind == '上头月');
      expect(peak.detail, contains('6 次'));
    });

    test('只有一天数据时不出「最长陪伴」', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', plays: 3,
            daily: {'2026-11-19': 3}, monthly: {'2026-11': 3}),
      });
      expect(insight.timeCapsule.map((e) => e.kind), isNot(contains('最长陪伴')));
    });
  });

  group('ListeningInsightBuilder · 建议', () {
    test('新发现只收最近 14 天内首次出现且至少播放 3 次的歌', () {
      final insight = build({
        'fresh': mk(id: 'fresh', title: '新宠', plays: 5,
            daily: {'2026-11-15': 5}),
        'barely': mk(id: 'barely', title: '只听两次', plays: 2,
            daily: {'2026-11-15': 2}),
        'old': mk(id: 'old', title: '老歌', plays: 9,
            daily: {'2026-05-01': 9}),
      });
      expect(insight.discoveries.map((d) => d.songId), ['fresh']);
    });

    test('最近一周播放高度集中 → 歌荒预警', () {
      final profiles = <String, SongProfile>{};
      for (var i = 0; i < 3; i++) {
        profiles['top$i'] = mk(
          id: 'top$i',
          title: 'Top $i',
          plays: 10,
          daily: {'2026-11-18': 10},
        );
      }
      for (var i = 0; i < 4; i++) {
        profiles['tail$i'] = mk(
          id: 'tail$i',
          title: 'Tail $i',
          plays: 1,
          daily: {'2026-11-18': 1},
        );
      }
      final insight = build(profiles);
      expect(insight.drought, isNotNull);
      expect(insight.drought!.concentration, greaterThanOrEqualTo(0.7));
    });

    test('播放分散时不误报歌荒', () {
      final profiles = <String, SongProfile>{};
      for (var i = 0; i < 8; i++) {
        profiles['s$i'] = mk(
          id: 's$i',
          title: 'Song $i',
          plays: 2,
          daily: {'2026-11-18': 2},
        );
      }
      expect(build(profiles).drought, isNull);
    });

  });

  group('ListeningInsightBuilder · 连续天数', () {
    test('相邻日期算连续，断档重新计数', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', plays: 4,
            daily: {
              '2026-11-17': 1,
              '2026-11-18': 1,
              '2026-11-19': 1,
              '2026-11-22': 1,
            }),
      });
      expect(insight.streakDays, 3);
      expect(insight.activeDays, 4);
    });
  });

  group('ListeningInsightBuilder · A 类新增维度', () {
    test('遗忘的宝藏：循环过 ≥5 次且 ≥60 天未听，按用力程度排序', () {
      final insight = build({
        'forgot': mk(
          id: 'forgot',
          title: '老朋友',
          plays: 20,
          lastPlayed: DateTime(2026, 8, 1), // 111 天前
        ),
        'recent': mk(
          id: 'recent',
          title: '最近常听',
          plays: 30,
          lastPlayed: DateTime(2026, 11, 19), // 1 天前，不该入选
        ),
        'light': mk(
          id: 'light',
          title: '只听两次',
          plays: 2,
          lastPlayed: DateTime(2026, 1, 1),
        ),
      });
      expect(insight.forgottenTreasures, hasLength(1));
      expect(insight.forgottenTreasures.first.songId, 'forgot');
      expect(insight.forgottenTreasures.first.daysSinceLastPlay, 111);
    });

    test('那一天：取单曲单日循环最高纪录，且至少 3 遍', () {
      final insight = build({
        'a': mk(id: 'a', title: '循环曲', plays: 12,
            daily: {'2026-05-01': 12}),
        'b': mk(id: 'b', title: '最多两次', plays: 2,
            daily: {'2026-06-01': 2}),
      });
      expect(insight.powerDay, isNotNull);
      expect(insight.powerDay!.songId, 'a');
      expect(insight.powerDay!.day, '2026-05-01');
      expect(insight.powerDay!.plays, 12);
    });

    test('没有 ≥3 遍的单日纪录时不出「那一天」', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', plays: 2,
            daily: {'2026-11-19': 2}),
      });
      expect(insight.powerDay, isNull);
    });

    test('口是心非：找出没收藏却反复听 与 收藏却总跳过', () {
      final insight = build({
        'gem': mk(id: 'gem', title: '宝藏', plays: 10, skips: 0),
        'fake': mk(id: 'fake', title: '装样子', plays: 5, skips: 4),
      }, starred: {'fake'});
      expect(insight.guiltyPleasure, isNotNull);
      expect(insight.guiltyPleasure!.hiddenGem?.songId, 'gem');
      expect(insight.guiltyPleasure!.pretender?.id, 'fake');
    });

    test('口是心非：无收藏时不误报「没收藏却反复听」之外的收藏项', () {
      final insight = build({
        'gem': mk(id: 'gem', title: '宝藏', plays: 10),
      });
      expect(insight.guiltyPleasure!.hiddenGem?.songId, 'gem');
      expect(insight.guiltyPleasure!.pretender, isNull);
    });

    test('生物钟：按实际听歌日期区分工作日与周末', () {
      // 2026-11-21 是周六，2026-11-18 是周三。
      final insight = build({
        'a': mk(id: 'a', title: 'A', artist: '甲', plays: 6,
            daily: {'2026-11-21': 6}),
        'b': mk(id: 'b', title: 'B', artist: '乙', plays: 4,
            daily: {'2026-11-18': 4}),
      });
      expect(insight.rhythm, isNotNull);
      expect(insight.rhythm!.weekendPlays, 6);
      expect(insight.rhythm!.weekdayPlays, 4);
      expect(insight.rhythm!.weekendArtist, '甲');
      expect(insight.rhythm!.weekdayArtist, '乙');
      expect(insight.rhythm!.isWeekendPerson, isTrue);
    });

    test('专辑情节：按 albumId 聚合播放与歌曲数', () {
      final insight = build({
        'a1': mk(id: 'a1', title: 'A1', albumId: 'alb', plays: 8),
        'a2': mk(id: 'a2', title: 'A2', albumId: 'alb', plays: 5),
        'b1': mk(id: 'b1', title: 'B1', albumId: 'other', plays: 3),
      });
      expect(insight.topAlbums.first.albumId, 'alb');
      expect(insight.topAlbums.first.plays, 13);
      expect(insight.topAlbums.first.songCount, 2);
    });

    test('无 albumId 的歌不进专辑榜', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', plays: 8),
      });
      expect(insight.topAlbums, isEmpty);
    });

    test('歌荒预警：最常听的 5 首才计入集中度（修复未排序 bug）', () {
      // 8 首歌：前 5 首各 10 次，后 3 首各 1 次 → 集中度 50/53 ≈ 94%
      // 若未排序而取到后 5 首，集中度会算成 34/53 ≈ 64%，漏报。
      final profiles = <String, SongProfile>{};
      for (var i = 0; i < 5; i++) {
        profiles['t$i'] = mk(id: 't$i', title: 'T$i', plays: 10,
            daily: {'2026-11-18': 10});
      }
      for (var i = 0; i < 3; i++) {
        profiles['s$i'] = mk(id: 's$i', title: 'S$i', plays: 1,
            daily: {'2026-11-18': 1});
      }
      final insight = build(profiles);
      expect(insight.drought, isNotNull);
      expect(insight.drought!.concentration, greaterThan(0.9));
    });
  });

  group('normalizeGenre · 脏标签清洗', () {
    test('真实歌单名标签归到隐含风格大类，不原样输出', () {
      // 这些是 2026-11-20 从道理鱼曲库实测抓到的 genres 值
      expect(normalizeGenre('摇滚拯救受伤小狗'), '摇滚');
      expect(normalizeGenre('哪有正经人爱听摇滚？'), '摇滚');
      expect(normalizeGenre('你所不知道的大张伟-花儿乐队朋克时期'), '朋克');
      expect(normalizeGenre('国内独立乐队合集'), '独立');
      expect(normalizeGenre('民谣-华语民谣'), '民谣');
      expect(normalizeGenre('生活不能没有摇滚乐'), '摇滚');
    });

    test('无风格含义的碎标签返回 null', () {
      expect(normalizeGenre('R'), isNull);
      expect(normalizeGenre('B'), isNull);
      expect(normalizeGenre(''), isNull);
      expect(normalizeGenre('x'), isNull);
    });

    test('脏标签不污染口味指纹：只产出标准风格名', () {
      final insight = build({
        'a': mk(id: 'a', title: 'A', genre: '摇滚拯救受伤小狗', plays: 5,
            daily: {'2026-10-01': 5}),
        'b': mk(id: 'b', title: 'B', genre: '哪有正经人爱听摇滚？', plays: 3,
            daily: {'2026-10-01': 3}),
        'c': mk(id: 'c', title: 'C', genre: 'R', plays: 9,
            daily: {'2026-10-01': 9}), // 碎标签应被丢弃
      });
      // 两条脏标签都归到「摇滚」并累加，R 被丢弃
      expect(insight.flavorPrint, hasLength(1));
      expect(insight.flavorPrint.first.name, '摇滚');
      expect(insight.flavorPrint.first.plays, 8);
      for (final g in insight.flavorPrint) {
        expect(g.name, isNot(contains('拯救')));
        expect(g.name, isNot(contains('爱听')));
      }
    });

    test('老画像缺 genre 时从曲库回填', () {
      final insight = build(
        {
          'a': mk(id: 'a', title: 'A', genre: null, plays: 6,
              daily: {'2026-10-01': 6}),
        },
        genreLookup: {'a': '华语流行'},
      );
      expect(insight.flavorPrint, hasLength(1));
      expect(insight.flavorPrint.first.name, '流行');
      expect(insight.flavorPrint.first.plays, 6);
    });

    test('画像已有 genre 时不被曲库回填覆盖', () {
      final insight = build(
        {
          'a': mk(id: 'a', title: 'A', genre: 'rock', plays: 6,
              daily: {'2026-10-01': 6}),
        },
        genreLookup: {'a': '华语流行'},
      );
      expect(insight.flavorPrint.first.name, '摇滚');
    });
  });
}
