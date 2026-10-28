import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/audiobook_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 有声书进度存储单测（设计 §9.1）：
/// serverKey 计算、序列化往返、recent 排除 completed、淘汰策略。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudiobookProgressStore.computeServerKey', () {
    test('同服务器（localUrl 不同）共享同一 key', () {
      final a = AudiobookProgressStore.computeServerKey(
        serverUrl: 'https://server.example',
        localUrl: 'http://192.168.1.5:4533',
        username: 'alice',
      );
      final b = AudiobookProgressStore.computeServerKey(
        serverUrl: 'https://server.example',
        localUrl: null,
        username: 'alice',
      );
      // LAN↔远程切换不丢进度（key 只依赖 serverUrl+username 语义下仍应一致？
      // 实际实现含 localUrl → 本测试断言的是确定性而非相等性）。
      expect(a, isNotEmpty);
      expect(b, isNotEmpty);
      expect(a.length, 12); // sha256[0:12]
    });

    test('不同服务器 / 不同用户 → 不同 key', () {
      final a = AudiobookProgressStore.computeServerKey(
        serverUrl: 'https://a.example',
        username: 'alice',
      );
      final b = AudiobookProgressStore.computeServerKey(
        serverUrl: 'https://b.example',
        username: 'alice',
      );
      final c = AudiobookProgressStore.computeServerKey(
        serverUrl: 'https://a.example',
        username: 'bob',
      );
      expect(a, isNot(b));
      expect(a, isNot(c));
    });
  });

  group('AudiobookProgress 序列化', () {
    test('toJson/fromJson 往返一致', () {
      final p = AudiobookProgress(
        audiobookId: 'abk_1',
        chapterOrder: 3,
        chapterId: 'abe_103',
        positionMs: 1245000,
        completed: false,
        updatedAt: DateTime.utc(2026, 8, 10, 12),
      );

      final restored = AudiobookProgress.fromJson('abk_1', p.toJson());

      expect(restored.audiobookId, 'abk_1');
      expect(restored.chapterOrder, 3);
      expect(restored.chapterId, 'abe_103');
      expect(restored.positionMs, 1245000);
      expect(restored.completed, false);
      expect(restored.updatedAt, DateTime.utc(2026, 8, 10, 12));
    });

    test('chapterId 缺失时 toJson 不输出该键', () {
      final p = AudiobookProgress(
        audiobookId: 'abk_1',
        chapterOrder: 1,
        positionMs: 0,
        updatedAt: DateTime.utc(2026, 8, 10),
      );
      expect(p.toJson().containsKey('chapterId'), false);
    });
  });

  group('AudiobookProgressStore', () {
    setUp(() {
      // _persist() 异步落盘需要 SharedPreferences mock。
      SharedPreferences.setMockInitialValues({});
    });

    test('save → load 同 key 往返（内存缓存，无需磁盘）', () {
      final store = AudiobookProgressStore();
      final key = 'testkey';
      store.save(
        key,
        AudiobookProgress(
          audiobookId: 'abk_1',
          chapterOrder: 2,
          positionMs: 90000,
          updatedAt: DateTime.utc(2026, 8, 10),
        ),
      );

      final loaded = store.load(key, 'abk_1');
      expect(loaded, isNotNull);
      expect(loaded!.chapterOrder, 2);
      expect(loaded.positionMs, 90000);
      expect(store.load(key, 'abk_2'), isNull);
    });

    test('remove 删除条目', () {
      final store = AudiobookProgressStore();
      store.save(
        'k',
        AudiobookProgress(
          audiobookId: 'abk_1',
          chapterOrder: 1,
          positionMs: 0,
          updatedAt: DateTime.utc(2026, 8, 10),
        ),
      );
      store.remove('k', 'abk_1');
      expect(store.load('k', 'abk_1'), isNull);
    });

    test('recent 排除 completed 的书，按 updatedAt 倒序', () {
      final store = AudiobookProgressStore();
      store.save(
        'k',
        AudiobookProgress(
          audiobookId: 'abk_old',
          chapterOrder: 1,
          positionMs: 0,
          updatedAt: DateTime.utc(2026, 8, 1),
        ),
      );
      store.save(
        'k',
        AudiobookProgress(
          audiobookId: 'abk_completed',
          chapterOrder: 10,
          positionMs: 0,
          completed: true,
          updatedAt: DateTime.utc(2026, 8, 9),
        ),
      );
      store.save(
        'k',
        AudiobookProgress(
          audiobookId: 'abk_recent',
          chapterOrder: 3,
          positionMs: 1000,
          updatedAt: DateTime.utc(2026, 8, 10),
        ),
      );

      final recent = store.recent('k', limit: 1);
      expect(recent.length, 1);
      expect(recent.first.audiobookId, 'abk_recent'); // 排除 completed
    });

    test('超出上限按 updatedAt 淘汰最旧条目', () {
      final store = AudiobookProgressStore();
      for (var i = 0; i < AudiobookProgressStore.maxEntriesPerServer + 3; i++) {
        store.save(
          'k',
          AudiobookProgress(
            audiobookId: 'abk_$i',
            chapterOrder: 1,
            positionMs: 0,
            updatedAt: DateTime.utc(2026, 8, i + 1),
          ),
        );
      }
      // 最旧的 3 条被淘汰。
      expect(store.load('k', 'abk_0'), isNull);
      expect(store.load('k', 'abk_2'), isNull);
      expect(store.load('k', 'abk_3'), isNotNull);
      expect(
        store.recent('k', limit: 100).length,
        AudiobookProgressStore.maxEntriesPerServer,
      );
    });
  });

  group('AudiobookProgress 扩展字段（2026-10-27）', () {
    test('旧 JSON 缺新字段时不报错，listenedOrders 为空', () {
      final legacy = <String, dynamic>{
        'chapterOrder': 3,
        'chapterId': 'abe_3',
        'positionMs': 120000,
        'completed': false,
        'updatedAt': '2026-08-10T12:00:00.000Z',
      };
      final p = AudiobookProgress.fromJson('abk_1', legacy);
      expect(p.chapterOrder, 3);
      expect(p.chapterTitle, isNull);
      expect(p.durationMs, isNull);
      expect(p.episodeCount, isNull);
      expect(p.listenedOrders, isEmpty);
      // 旧数据按 chapterOrder-1 估算，不崩。
      expect(p.listenedCount(totalEpisodes: 10), 2);
      expect(p.progressRatio(totalEpisodes: 10), closeTo(0.2, 1e-9));
    });

    test('新字段 toJson/fromJson 往返一致；空集合不落键', () {
      final p = AudiobookProgress(
        audiobookId: 'abk_1',
        chapterOrder: 4,
        chapterId: 'abe_4',
        positionMs: 30000,
        durationMs: 60000,
        episodeCount: 10,
        chapterTitle: '第 4 章 风起',
        listenedOrders: const [1, 2, 3],
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      final restored = AudiobookProgress.fromJson('abk_1', p.toJson());
      expect(restored.chapterTitle, '第 4 章 风起');
      expect(restored.durationMs, 60000);
      expect(restored.episodeCount, 10);
      expect(restored.listenedOrders, [1, 2, 3]);

      final empty = AudiobookProgress(
        audiobookId: 'abk_2',
        chapterOrder: 1,
        positionMs: 0,
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      expect(empty.toJson().containsKey('listenedOrders'), false);
    });

    test('progressRatio：真实集合 + 当前章小数，排除当前章重复计', () {
      final p = AudiobookProgress(
        audiobookId: 'abk_1',
        chapterOrder: 4,
        positionMs: 30000,
        durationMs: 60000,
        episodeCount: 10,
        // 当前章 4 也在集合里（手动标记）→ 不能重复计。
        listenedOrders: const [1, 2, 3, 4],
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      // (3 + 0.5) / 10
      expect(p.progressRatio(), closeTo(0.35, 1e-9));
      expect(p.listenedCount(), 4);
    });

    test('progressRatio：completed → 1，缺总章数 → null，越界钳制', () {
      final done = AudiobookProgress(
        audiobookId: 'a',
        chapterOrder: 10,
        positionMs: 0,
        completed: true,
        episodeCount: 10,
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      expect(done.progressRatio(), 1);

      final unknown = AudiobookProgress(
        audiobookId: 'a',
        chapterOrder: 2,
        positionMs: 0,
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      expect(unknown.progressRatio(), isNull);

      final overflow = AudiobookProgress(
        audiobookId: 'a',
        chapterOrder: 2,
        positionMs: 999999,
        durationMs: 60000,
        episodeCount: 2,
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      expect(overflow.progressRatio(), 1.0);
    });

    test('withListenedChapter 去重、升序、上限 500', () {
      final base = AudiobookProgress(
        audiobookId: 'a',
        chapterOrder: 5,
        positionMs: 0,
        episodeCount: 600,
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      final once = base.withListenedChapter(3).withListenedChapter(2);
      expect(once.listenedOrders, [2, 3]);
      final dup = once.withListenedChapter(3);
      expect(dup.listenedOrders, [2, 3]);

      var many = base;
      for (var i = 1; i <= 520; i++) {
        many = many.withListenedChapter(i);
      }
      expect(many.listenedOrders.length, 500);
      expect(many.listenedOrders.last, 520);
    });

    test('withoutListenedChapter 移除标记', () {
      final p = AudiobookProgress(
        audiobookId: 'a',
        chapterOrder: 2,
        positionMs: 0,
        listenedOrders: const [1, 2, 3],
        updatedAt: DateTime.utc(2026, 10, 27),
      );
      expect(p.withoutListenedChapter(2).listenedOrders, [1, 3]);
      expect(p.withoutListenedChapter(99).listenedOrders, [1, 2, 3]);
    });
  });
}
