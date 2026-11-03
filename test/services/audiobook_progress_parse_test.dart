import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/audiobook_progress_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 云端进度解析的契约锁定。
///
/// 样本来自 **2026-11-02 真机实测**：在已登录的 Web 端执行
/// `GET /api/library/audiobooks/progress`（本机 Chrome + CDP），
/// 仅把书名/章节名替换成占位文本，**字段结构与值保持原样**。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  /// 列表接口的一项（顶层数组元素）。
  Map<String, dynamic> listItem() => {
        'id': 'abp_e657e1ce1b3e19a1', // 进度记录 id（abp_），不是书本 id
        'audiobook': {
          'id': 'abk_09ddbbf474ef3230',
          'title': '示例有声书',
          'baseTitle': '示例有声书',
          'slug': 'audiobook-09ddbbf4',
          'status': 'PUBLISHED',
          'isSerializing': false,
          'narratorDisplayName': '示例演播',
          'narrators': ['示例演播'],
          'categories': <dynamic>[],
          'tags': <dynamic>[],
          'episodeCount': 311,
          'totalDurationSeconds': 0,
          'lastEpisodePublishedAt': '2026-07-23T10:34:26Z',
          'updatedAt': '2026-08-07T09:01:04Z',
          'playCount': 0,
          'favoriteCount': 0,
          'sourcePath': '/Music2/示例有声书',
        },
        'episode': {
          'id': 'abe_833b2e24e75ac46e',
          'title': '示例章节标题',
          'order': 89,
          'durationSeconds': 886,
        },
        'progressSeconds': 630,
        'durationSeconds': 886,
        'completed': false,
        'lastPlayedAt': '2026-09-24T20:13:51Z',
        'revision': 440,
      };

  group('AudiobookProgress.fromServerJson（真实响应）', () {
    test('列表形态：字段全部落到正确槽位', () {
      final p = AudiobookProgress.fromServerJson(listItem());
      expect(p, isNotNull);
      expect(p!.audiobookId, 'abk_09ddbbf474ef3230'); // 取自 audiobook.id
      expect(p.chapterOrder, 89); // episode.order
      expect(p.chapterId, 'abe_833b2e24e75ac46e'); // episode.id
      expect(p.positionMs, 630000); // progressSeconds*1000
      expect(p.durationMs, 886000); // durationSeconds*1000
      expect(p.chapterTitle, '示例章节标题'); // episode.title ← 本轮修正点
      expect(p.completed, isFalse);
      expect(p.episodeCount, 311); // 顶层缺，回退 audiobook.episodeCount
      expect(p.updatedAt.toUtc().toIso8601String(), '2026-09-24T20:13:51.000Z');
    });

    test('单本读形态：时间字段是 updatedAt（不是 lastPlayedAt）', () {
      final item = listItem()
        ..remove('lastPlayedAt')
        ..['updatedAt'] = '2026-11-02T08:32:38Z';
      final p = AudiobookProgress.fromServerJson(item);
      expect(
          p!.updatedAt.toUtc().toIso8601String(), '2026-11-02T08:32:38.000Z');
    });

    test('顶层 id 是 abp_ 时不会误当成书本 id', () {
      final item = listItem()..remove('audiobook');
      // 没有 audiobook.id → 无法定位书本，必须丢弃而不是拿 abp_ 顶上
      expect(AudiobookProgress.fromServerJson(item), isNull);
    });

    test('缺 episode.order 时退回第 1 章，不崩', () {
      final item = listItem();
      (item['episode'] as Map).remove('order');
      final p = AudiobookProgress.fromServerJson(item);
      expect(p!.chapterOrder, 1);
    });
  });

  group('AudiobookProgressStore.mergeRemote 语义', () {
    AudiobookProgress local() => AudiobookProgress(
          audiobookId: 'abk_09ddbbf474ef3230',
          chapterOrder: 89,
          positionMs: 500000,
          updatedAt: DateTime.utc(2026, 9, 24, 20, 0),
          listenedOrders: const [88],
        );

    test('云端更新 → 覆盖，且 listenedOrders 取并集', () {
      final store = AudiobookProgressStore.instance;
      const key = 'test-server-key';
      store.save(key, local());
      final remote = AudiobookProgress.fromServerJson(listItem())!;
      final applied = store.mergeRemote(key, [remote]);
      expect(applied, 1);
      final merged = store.load(key, 'abk_09ddbbf474ef3230')!;
      expect(merged.positionMs, 630000);
      expect(merged.listenedOrders, contains(88)); // 本地已听标记不丢
      store.remove(key, 'abk_09ddbbf474ef3230');
    });

    test('云端更旧 → 不覆盖', () {
      final store = AudiobookProgressStore.instance;
      const key = 'test-server-key-old';
      final newer = local().copyWith(updatedAt: DateTime.utc(2026, 10, 1));
      store.save(key, newer);
      final remote = AudiobookProgress.fromServerJson(listItem())!; // 9/24 更旧
      expect(store.mergeRemote(key, [remote]), 0);
      expect(store.load(key, 'abk_09ddbbf474ef3230')!.positionMs, 500000);
      store.remove(key, 'abk_09ddbbf474ef3230');
    });

    test('skip 里的书（正在播）一律不覆盖', () {
      final store = AudiobookProgressStore.instance;
      const key = 'test-server-key-skip';
      store.save(key, local());
      final remote = AudiobookProgress.fromServerJson(listItem())!;
      final applied = store.mergeRemote(
        key,
        [remote],
        skip: {'abk_09ddbbf474ef3230'},
      );
      expect(applied, 0);
      expect(store.load(key, 'abk_09ddbbf474ef3230')!.positionMs, 500000);
      store.remove(key, 'abk_09ddbbf474ef3230');
    });
  });
}
