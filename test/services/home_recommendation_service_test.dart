import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/services/home_recommendation_service.dart';
import 'package:luobo/services/recommendation_service.dart';
import 'package:luobo/services/recommended_history_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

Song _song(
  String id, {
  String? artist,
  String? albumId,
  String? genre,
}) =>
    Song(
      id: id,
      title: 'Song $id',
      artist: artist,
      albumId: albumId,
      genre: genre,
    );

Map<String, String> _tagsFor(Iterable<Song> songs, String tag) => {
      for (final s in songs) s.id: tag,
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecommendationService behavior;
  late HomeRecommendationService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    behavior = RecommendationService();
    await behavior.initialize();
    service = HomeRecommendationService(behavior: behavior);
  });

  Future<void> play(Song song, {bool completed = true}) =>
      behavior.trackSongPlay(song, completed: completed);

  group('HomeRecommendationService', () {
    test('refreshUserPref 从行为与收藏构建标签偏好', () async {
      service.rebuildKnowledge({'a': '摇滚,深夜', 'b': '摇滚,治愈'});
      await play(_song('a', artist: 'X', albumId: 'al1'));
      await behavior.trackStarred(_song('b', artist: 'Y'), true);
      service.refreshUserPref();

      final pref = service.engine.userTagPref;
      expect(pref, isNotEmpty);
      expect(pref['摇滚'], greaterThan(0.0)); // a 播放 + b 收藏都含摇滚
      expect(pref['深夜'], greaterThan(0.0));
      expect(pref['治愈'], greaterThan(0.0));
    });

    test('分层：每日推荐熟悉优先 + 未听过补足，探索发现只推未听过的', () async {
      final heard = List.generate(
          15, (i) => _song('h$i', artist: 'A${i % 3}', albumId: 'al$i'));
      final unheard = List.generate(
          10, (i) => _song('u$i', artist: 'B$i', albumId: 'bl$i'));
      for (final s in heard) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor([...heard, ...unheard], '摇滚,深夜'));
      service.refreshUserPref();

      final all = [...heard, ...unheard];
      final daily = service.dailyRecommendation(allSongs: all);
      final discover = service.discoverSongs(allSongs: all);

      expect(daily, isNotEmpty);
      // 熟悉优先：融合分（行为 0.7 权重）让听过的歌排在未听过之前。
      expect(daily.first.id.startsWith('h'), isTrue);
      // 去重上限卡满后由未听过的歌补足：听过的只占 6 首（3 歌手×≤2），
      // 未听过的 10 首全部进池。
      expect(daily.length, 16);
      expect(daily.any((s) => s.id.startsWith('u')), isTrue);
      expect(discover, isNotEmpty);
      expect(discover.every((s) => s.id.startsWith('u')), isTrue);
    });

    test('去重：同一歌手≤2 首、同一专辑≤1 首', () async {
      // 30 首全部来自歌手 X，其中每 3 首共享一个专辑。
      final songs = List.generate(
        30,
        (i) => _song('h$i', artist: 'X', albumId: 'al${i ~/ 3}'),
      );
      for (final s in songs) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final daily = service.dailyRecommendation(allSongs: songs, limit: 30);

      final artistX = daily.where((s) => s.artist == 'X').length;
      expect(artistX, lessThanOrEqualTo(2));

      final albumIds = daily.map((s) => s.albumId).toSet();
      expect(albumIds.length, daily.length); // 每专辑 ≤1
    });

    test('跨模块全局去重：generateFeed 各模块两两不重叠', () async {
      final songs = List.generate(
          40, (i) => _song('h$i', artist: 'A${i % 5}', albumId: 'al$i'));
      for (final s in songs) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final feed = service.generateFeed(allSongs: songs);
      final allIds = [
        ...feed.daily.map((s) => s.id),
        ...feed.commuteMix.map((s) => s.id),
        ...feed.studyMix.map((s) => s.id),
        ...feed.sleepMix.map((s) => s.id),
        ...feed.discover.map((s) => s.id),
      ];
      expect(allIds.toSet().length, allIds.length);
    });

    test('场景 Mix：只含匹配场景标签的歌', () async {
      final commute =
          List.generate(8, (i) => _song('c$i', artist: 'A', albumId: 'al$i'));
      final sleep =
          List.generate(8, (i) => _song('s$i', artist: 'B', albumId: 'bl$i'));
      final other =
          List.generate(8, (i) => _song('o$i', artist: 'C', albumId: 'cl$i'));
      for (final s in [...commute, ...sleep, ...other]) {
        await play(s);
      }
      service.rebuildKnowledge({
        ..._tagsFor(commute, '摇滚,高能量,快节奏'),
        ..._tagsFor(sleep, '治愈,舒缓,慢'),
        ..._tagsFor(other, '流行,快乐'),
      });
      service.refreshUserPref();

      final commuteMix = service.sceneMix(SceneMix.commute,
          allSongs: [...commute, ...sleep, ...other]);
      final sleepMix = service
          .sceneMix(SceneMix.sleep, allSongs: [...commute, ...sleep, ...other]);

      expect(commuteMix, isNotEmpty);
      expect(commuteMix.every((s) => s.id.startsWith('c')), isTrue);
      expect(sleepMix, isNotEmpty);
      expect(sleepMix.every((s) => s.id.startsWith('s')), isTrue);
    });

    test('每日推荐当日固定：同日返回同一批，次日重新生成', () async {
      final songs =
          List.generate(15, (i) => _song('h$i', artist: 'A', albumId: 'al$i'));
      for (final s in songs) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final now = DateTime(2026, 8, 4, 10);
      final first = service.dailyRecommendation(allSongs: songs, now: now);
      final second = service.dailyRecommendation(allSongs: songs, now: now);
      expect(second, same(first));

      final nextDay = service.dailyRecommendation(
        allSongs: songs,
        now: now.add(const Duration(days: 1)),
      );
      expect(nextDay, isNot(same(first)));
    });

    test('探索发现按日固定：同日返回同一批，次日重新生成', () async {
      final heard = List.generate(
          12, (i) => _song('h$i', artist: 'A${i % 3}', albumId: 'al$i'));
      final unheard = List.generate(
          10, (i) => _song('u$i', artist: 'B$i', albumId: 'bl$i'));
      for (final s in heard) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor([...heard, ...unheard], '摇滚,深夜'));
      service.refreshUserPref();

      final all = [...heard, ...unheard];
      final now = DateTime(2026, 8, 4, 10); // 周二
      final first = service.discoverSongs(allSongs: all, now: now);
      final second = service.discoverSongs(
          allSongs: all, now: now.add(const Duration(hours: 3)));
      expect(second, same(first));

      // 次日重新生成
      final nextDay = service.discoverSongs(
        allSongs: all,
        now: now.add(const Duration(days: 1)),
      );
      expect(nextDay, isNot(same(first)));
    });

    test('favoritesMix：你的最爱 = 熟悉层按行为分降序', () async {
      final songs = List.generate(
          15, (i) => _song('h$i', artist: 'A${i % 3}', albumId: 'al$i'));
      // 只给前 5 首完整播放（完成度满分），后 10 首跳过一次。
      for (final s in songs.take(5)) {
        await play(s, completed: true);
      }
      for (final s in songs.skip(5)) {
        await behavior.trackSkip(s);
      }
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final favorites = service.favoritesMix(allSongs: songs, limit: 10);
      expect(favorites, isNotEmpty);
      // 行为分最高的前 5 首应排在前面。
      final topIds = songs.take(5).map((s) => s.id).toSet();
      expect(topIds.contains(favorites.first.id), isTrue);
      // 每专辑 ≤1（去重生效）。
      expect(favorites.map((s) => s.albumId).toSet().length, favorites.length);
    });

    test('退化：无图谱时 α=1，纯行为排序', () async {
      final songs = List.generate(
          15, (i) => _song('h$i', artist: 'A${i % 3}', albumId: 'al$i'));
      for (final s in songs) {
        await play(s);
      }
      // 不 rebuildKnowledge → 无图谱
      service.refreshUserPref();

      final daily = service.dailyRecommendation(allSongs: songs);
      expect(daily, isNotEmpty);
      // 无图谱时行为分主导，日推全是听过的歌
      expect(daily.every((s) => s.id.startsWith('h')), isTrue);
    });

    test('退化：无行为时 α=0，内容分主导且不崩溃', () async {
      final songs = List.generate(
          20, (i) => _song('u$i', artist: 'B$i', albumId: 'bl$i'));
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final daily = service.dailyRecommendation(allSongs: songs);
      final discover = service.discoverSongs(allSongs: songs);

      expect(daily, isNotEmpty);
      expect(discover, isNotEmpty);
    });

    test('完全冷启动：无行为且无图谱时仍返回非空、不崩溃', () {
      final songs = List.generate(
          30, (i) => _song('u$i', artist: 'B$i', albumId: 'bl$i'));
      final daily = service.dailyRecommendation(allSongs: songs);
      expect(daily.length, 30);
      final feed = service.generateFeed(allSongs: songs);
      expect(feed.isEmpty, isFalse);
    });

    test('知识库重建后使每日缓存失效', () async {
      final songs =
          List.generate(15, (i) => _song('h$i', artist: 'A', albumId: 'al$i'));
      for (final s in songs) {
        await play(s);
      }
      final now = DateTime(2026, 8, 4, 10);
      service.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      service.refreshUserPref();

      final before = service.dailyRecommendation(allSongs: songs, now: now);
      service.rebuildKnowledge(_tagsFor(songs, '流行,快乐'));
      final after = service.dailyRecommendation(allSongs: songs, now: now);
      expect(after, isNot(same(before)));
    });

    // ──────────────────────────────────────────────────────────────────────
    // 探索配额 / 跨天冷却 / 收藏即时反馈
    // （`docs/每日推荐探索配额与冷却技术方案.md`）
    // ──────────────────────────────────────────────────────────────────────

    test('配额：每日推荐固定留出探索槽给未听过的歌', () async {
      // 听过的歌足够多且歌手分散 → 旧逻辑（单路融合分排序）会占满 30 个名额。
      final heard = List.generate(
          40, (i) => _song('h$i', artist: 'HA$i', albumId: 'hal$i'));
      final unheard = List.generate(
          10, (i) => _song('u$i', artist: 'UB$i', albumId: 'ubl$i'));
      for (final s in heard) {
        await play(s);
      }
      service.rebuildKnowledge(_tagsFor([...heard, ...unheard], '摇滚,深夜'));
      service.refreshUserPref();

      final daily = service.dailyRecommendation(
        allSongs: [...heard, ...unheard],
        limit: 30,
      );

      // 熟悉槽 20 + 探索槽 10（dailyDiscoverRatio = 1/3）。
      expect(daily.where((s) => s.id.startsWith('h')).length, 20);
      expect(daily.where((s) => s.id.startsWith('u')).length, 10);
      // 熟悉在前、探索在后。
      expect(daily.take(20).every((s) => s.id.startsWith('h')), isTrue);
      expect(daily.skip(20).every((s) => s.id.startsWith('u')), isTrue);
    });

    test('配额：探索槽数量随 limit 缩放', () {
      expect(HomeRecommendationService.dailyDiscoverQuota(30), 10);
      expect(HomeRecommendationService.dailyDiscoverQuota(3), 1);
      expect(HomeRecommendationService.dailyDiscoverQuota(0), 0);
    });

    test('冷却：次日推荐与首日无交集', () async {
      SharedPreferences.setMockInitialValues({});
      final history = RecommendedHistoryStore();
      await history.initialize();
      final svc = HomeRecommendationService(
        behavior: behavior,
        history: history,
      );

      // 库要足够大，否则冷却安全阀会整体忽略冷却（见下一条测试）。
      final heard = List.generate(
          200, (i) => _song('h$i', artist: 'HA$i', albumId: 'hal$i'));
      final unheard = List.generate(
          20, (i) => _song('u$i', artist: 'UB$i', albumId: 'ubl$i'));
      for (final s in heard) {
        await play(s);
      }
      svc.rebuildKnowledge(_tagsFor([...heard, ...unheard], '摇滚,深夜'));
      svc.refreshUserPref();

      final all = [...heard, ...unheard];
      final day1 = DateTime(2026, 9, 23, 10);
      final first = svc.dailyRecommendation(allSongs: all, now: day1);
      expect(first.length, 30);

      final second = svc.dailyRecommendation(
        allSongs: all,
        now: day1.add(const Duration(days: 1)),
      );
      expect(second.length, 30);
      final overlap = first
          .map((s) => s.id)
          .toSet()
          .intersection(second.map((s) => s.id).toSet());
      expect(overlap, isEmpty);
    });

    test('冷却安全阀：候选不足以凑满 limit 时忽略冷却（不推空）', () async {
      SharedPreferences.setMockInitialValues({});
      final history = RecommendedHistoryStore();
      await history.initialize();
      final svc = HomeRecommendationService(
        behavior: behavior,
        history: history,
      );

      // 小库：首日把大部分歌都推过了，次日必须仍能凑满而不是推空。
      final songs = List.generate(
          35, (i) => _song('h$i', artist: 'HA$i', albumId: 'hal$i'));
      for (final s in songs) {
        await play(s);
      }
      svc.rebuildKnowledge(_tagsFor(songs, '摇滚,深夜'));
      svc.refreshUserPref();

      final day1 = DateTime(2026, 9, 23, 10);
      final first = svc.dailyRecommendation(allSongs: songs, now: day1);
      expect(first.length, 30);

      final second = svc.dailyRecommendation(
        allSongs: songs,
        now: day1.add(const Duration(days: 1)),
      );
      expect(second.length, 30);
    });

    test('冷却：同日重算不整批换歌（当日已推荐的不算冷却）', () async {
      SharedPreferences.setMockInitialValues({});
      final history = RecommendedHistoryStore();
      await history.initialize();
      final svc = HomeRecommendationService(
        behavior: behavior,
        history: history,
      );

      final heard = List.generate(
          40, (i) => _song('h$i', artist: 'HA$i', albumId: 'hal$i'));
      for (final s in heard) {
        await play(s);
      }
      svc.rebuildKnowledge(_tagsFor(heard, '摇滚,深夜'));
      svc.refreshUserPref();

      final now = DateTime(2026, 9, 23, 10);
      final first = svc.dailyRecommendation(allSongs: heard, now: now);
      svc.clearCaches(); // 模拟收藏变化导致当日缓存失效
      final again = svc.dailyRecommendation(allSongs: heard, now: now);

      expect(again.map((s) => s.id).toList(), first.map((s) => s.id).toList());
    });

    test('收藏变化即时失效当日推荐；纯播放不重排', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = HomeRecommendationService(
        behavior: behavior,
        prefDebounce: const Duration(milliseconds: 1),
      );
      final heard = List.generate(
          40, (i) => _song('h$i', artist: 'HA$i', albumId: 'hal$i'));
      for (final s in heard) {
        await play(s);
      }
      svc.rebuildKnowledge(_tagsFor(heard, '摇滚,深夜'));
      svc.refreshUserPref();

      final now = DateTime(2026, 9, 23, 10);
      final before = svc.dailyRecommendation(allSongs: heard, now: now);
      final revBefore = svc.feedRevision;

      // 纯播放 → 不重排当日列表、feedRevision 不变。
      await play(heard.first);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.feedRevision, revBefore);
      expect(svc.dailyRecommendation(allSongs: heard, now: now), same(before));

      // 收藏变化 → feedRevision 自增 + 当日缓存失效。
      await behavior.trackStarred(heard.last, true);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(svc.feedRevision, greaterThan(revBefore));
      expect(
        svc.dailyRecommendation(allSongs: heard, now: now),
        isNot(same(before)),
      );
    });

    test('去重上限跨熟悉/探索两路共享：同歌手≤2、同专辑≤1', () async {
      // 歌手 X 同时有听过的和未听过的歌 → 若两路各自计数，X 会超过 2 首。
      final heard =
          List.generate(4, (i) => _song('h$i', artist: 'X', albumId: 'hal$i'));
      final unheard =
          List.generate(6, (i) => _song('u$i', artist: 'X', albumId: 'ubl$i'));
      final others = List.generate(
          20, (i) => _song('o$i', artist: 'O$i', albumId: 'ol$i'));
      for (final s in [...heard, ...others]) {
        await play(s);
      }
      service.rebuildKnowledge(
          _tagsFor([...heard, ...unheard, ...others], '摇滚,深夜'));
      service.refreshUserPref();

      final daily = service.dailyRecommendation(
        allSongs: [...heard, ...unheard, ...others],
        limit: 30,
      );

      expect(daily.where((s) => s.artist == 'X').length, lessThanOrEqualTo(2));
      expect(daily.map((s) => s.albumId).toSet().length, daily.length);
    });
  });
}
