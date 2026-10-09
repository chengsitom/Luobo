import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/services/lyrics/lrc_parser.dart';
import 'package:luobo/services/lyrics/lyrics_cache.dart';
import 'package:luobo/services/lyrics/lyrics_source.dart';
import 'package:luobo/services/storage_service.dart';
import 'package:luobo/services/subsonic_service.dart';

import '../bootstrap.dart';

/// 只覆写歌词相关入口的假服务，用于验证取源链的顺序与优先级。
class _FakeSubsonic extends SubsonicService {
  _FakeSubsonic({this.byId, this.byMeta, this.daoliyu = false});

  Map<String, dynamic>? byId;
  Map<String, dynamic>? byMeta;
  final bool daoliyu;

  int byIdCalls = 0;
  int byMetaCalls = 0;

  @override
  bool get isDaoliyu => daoliyu;

  @override
  Future<Map<String, dynamic>?> getLyricsBySongId(String songId) async {
    byIdCalls++;
    return byId;
  }

  @override
  Future<Map<String, dynamic>?> getLyrics({
    String? artist,
    String? title,
    String? id,
  }) async {
    byMetaCalls++;
    return byMeta;
  }
}

Song _song([String id = 's1']) =>
    Song(id: id, title: 'Title', artist: 'Artist', duration: 200);

void main() {
  initializeTestEnvironment();

  // OfflineService 走 path_provider 定位离线目录；测试里把它指到临时目录，
  // 让歌词缓存的读写（source 标记）能被真实验证。
  late Directory tempDir;
  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('luobo_lyrics_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      pathProviderChannel,
      (call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  // ── 1. lrc_parser：公共纯函数 ─────────────────────────────────────────────
  group('lrcToStructuredLines', () {
    test('标准 LRC → 行数组（毫秒正确）', () {
      final lines = lrcToStructuredLines('[00:05.30]第一行\n[01:02.05]第二行');
      expect(lines.length, 2);
      expect(lines[0], {'start': 5300, 'value': '第一行'});
      expect(lines[1], {'start': 62050, 'value': '第二行'});
    });

    test('3 位毫秒按毫秒解析', () {
      final lines = lrcToStructuredLines('[00:01.234]文本');
      expect(lines.single['start'], 1234);
    });

    test('双语同时间戳两行都保留', () {
      final lines = lrcToStructuredLines('[00:10.00]原文\n[00:10.00]译文');
      expect(lines.length, 2);
      expect(lines[0]['start'], lines[1]['start']);
      expect(lines[1]['value'], '译文');
    });

    test('无时间轴 / 空串 / 纯元数据行 → 空数组', () {
      expect(lrcToStructuredLines('就是一段纯文本\n没有时间戳'), isEmpty);
      expect(lrcToStructuredLines(''), isEmpty);
      expect(lrcToStructuredLines('[ti:歌名]\n[ar:歌手]'), isEmpty);
    });

    test('空文本行被过滤', () {
      final lines = lrcToStructuredLines('[00:01.00]有词\n[00:02.00]   ');
      expect(lines.length, 1);
    });
  });

  group('hasLrcTimeline', () {
    test('带时间轴 → true', () {
      expect(hasLrcTimeline('[00:01.00]词'), isTrue);
    });

    test('纯文本 / 只有标签行 → false', () {
      expect(hasLrcTimeline('作词 : 张三\n第一句歌词'), isFalse);
      expect(hasLrcTimeline('[ti:歌名]\n[ar:歌手]'), isFalse);
    });
  });

  group('linesToLrc', () {
    test('分钟数补足 2 位（否则 LyricsManager 的正则丢弃该行）', () {
      final lrc = linesToLrc([
        {'start': 5300, 'value': 'A'},
        {'start': 62050, 'value': 'B'},
      ]);
      expect(lrc, contains('[00:05.30]A'));
      expect(lrc, contains('[01:02.05]B'));
    });

    test('往返一致（毫秒精度到厘秒）', () {
      final lrc = '[00:05.30]A\n[01:02.05]B';
      expect(linesToLrc(lrcToStructuredLines(lrc)), contains('[00:05.30]A'));
      expect(hasLrcTimeline(linesToLrc(lrcToStructuredLines(lrc))), isTrue);
    });
  });

  group('plainTextToStaticLrc（§5.5 选项 A）', () {
    test('过滤元信息行后取首行，包装成 [00:00.00]', () {
      final lrc = plainTextToStaticLrc(
        '作词 : 张三\n作曲：李四\n\n第一句真正的歌词\n第二句',
      );
      expect(lrc, '[00:00.00]第一句真正的歌词');
    });

    test('跳过 LRC 标签行', () {
      expect(plainTextToStaticLrc('[ti:歌名]\n[ar:歌手]\n歌词首行'), '[00:00.00]歌词首行');
    });

    test('全是元信息 / 空 → null（退化为不推）', () {
      expect(plainTextToStaticLrc('作词 : 张三\n作曲 : 李四'), isNull);
      expect(plainTextToStaticLrc(''), isNull);
    });
  });

  // ── 2. lyrics_cache：来源标记 + 会话级复查 ────────────────────────────────
  group('lyrics_cache 来源标记', () {
    test('withLyricsCacheMeta / readLyricsCacheSource 往返', () {
      final payload = withLyricsCacheMeta(
        {'lyricsList': <String, dynamic>{}},
        LyricsCacheSource.netease,
      );
      expect(payload[kLyricsCacheVersionKey], kLyricsCacheVersion);
      expect(readLyricsCacheSource(payload), LyricsCacheSource.netease);
    });

    test('旧缓存无 source → null（视为来源可疑）', () {
      expect(
          readLyricsCacheSource({'lyricsList': <String, dynamic>{}}), isNull);
    });

    test('未知 source 值 → null', () {
      expect(
        readLyricsCacheSource({'source': 'unknown-source'}),
        isNull,
      );
    });

    test('toLyricsCacheShell：structuredLyrics 形状 → 产出 lyricsList（入口结构化分支直接可用）',
        () {
      final shell = toLyricsCacheShell({
        'structuredLyrics': [
          {
            'synced': true,
            'line': [
              {'start': 0, 'value': 'A'},
            ],
          },
        ],
      });
      expect(shell['lyricsList'], isA<Map<String, dynamic>>());
    });

    test('toLyricsCacheShell：双键形状（structuredLyrics + 顶层 lyrics 字符串）→ 两个键都产出',
        () {
      final shell = toLyricsCacheShell({
        'lyrics': '[00:01.00]A',
        'structuredLyrics': [
          {
            'synced': true,
            'line': [
              {'start': 1000, 'value': 'A'},
            ],
          },
        ],
      });
      expect(shell['lyricsList'], isA<Map<String, dynamic>>());
      expect((shell['lyrics'] as Map)['value'], '[00:01.00]A');
    });

    test('toLyricsCacheShell：顶层 lyrics 是字符串 → 规范成 value 外壳', () {
      final shell = toLyricsCacheShell({'lyrics': '[00:01.00]A'});
      expect(shell['lyricsList'], isNull);
      expect(shell['lyrics'], isA<Map<String, dynamic>>());
      expect((shell['lyrics'] as Map)['value'], '[00:01.00]A');
    });

    test('toLyricsCacheShell：value 形状 → 原样放进 lyrics', () {
      final shell = toLyricsCacheShell({'value': '纯文本'});
      expect((shell['lyrics'] as Map)['value'], '纯文本');
    });

    test('toLyricsCacheShell：形状无法识别 → 保持原样（不产出空壳）', () {
      final shell = toLyricsCacheShell({'unknownKey': 1});
      expect(shell, isNotEmpty);
      expect(shell['lyrics'], isA<Map<String, dynamic>>());
    });

    test('isFallback / isServerSide 分类', () {
      expect(LyricsCacheSource.netease.isFallback, isTrue);
      expect(LyricsCacheSource.lrclib.isFallback, isTrue);
      expect(LyricsCacheSource.daoliyu.isFallback, isFalse);
      expect(LyricsCacheSource.daoliyu.isServerSide, isTrue);
      expect(LyricsCacheSource.server.isServerSide, isTrue);
    });
  });

  group('resolveLyricsCache', () {
    setUp(resetLyricsRecheckState);

    test('无缓存 → payload 为 null（调用方走取源链），且不复查', () async {
      var fetched = 0;
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: null,
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async {
          fetched++;
          return null;
        },
        saveCache: (_) async {},
      );
      expect(outcome.usable, isFalse);
      expect(fetched, 0);
    });

    test('服务器来源缓存 → 直接用，零网络', () async {
      var fetched = 0;
      final cached = withLyricsCacheMeta(
        {
          'lyricsList': <String, dynamic>{'lyrics': '[00:01.00]A'}
        },
        LyricsCacheSource.daoliyu,
      );
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: cached,
        serverSource: LyricsCacheSource.daoliyu,
        fetchServerLyrics: () async {
          fetched++;
          return null;
        },
        saveCache: (_) async {},
      );
      expect(outcome.usable, isTrue);
      expect(outcome.source, LyricsCacheSource.daoliyu);
      expect(fetched, 0);
    });

    test('兜底来源 → 首次复查命中服务器：返回外壳化 payload 并覆盖缓存（带 source）', () async {
      Map<String, dynamic>? saved;
      final cached = withLyricsCacheMeta(
        {
          'lyricsList': <String, dynamic>{'value': '兜底歌词'}
        },
        LyricsCacheSource.netease,
      );
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: cached,
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async => {'lyrics': '[00:01.00]服务器歌词'},
        saveCache: (payload) async => saved = payload,
      );
      expect(outcome.source, LyricsCacheSource.server);
      // 回归 C1-C3：入口读 `payload['lyrics']` 并 `as Map<String, dynamic>` 强转，
      // 而服务器原始响应的顶层 `lyrics` 是 String ⇒ 必须被规范成 {'value': ...}
      // 外壳，否则强转抛 TypeError、被入口 catch 吞掉后歌词与兜底链一起失效。
      expect(outcome.payload!['lyrics'], isA<Map<String, dynamic>>());
      expect((outcome.payload!['lyrics'] as Map)['value'], '[00:01.00]服务器歌词');
      expect(saved, isNotNull);
      expect(readLyricsCacheSource(saved), LyricsCacheSource.server);
      expect(saved!['lyrics'], isA<Map<String, dynamic>>());
    });

    test('复查命中 structuredLyrics 形状 → 同时产出 lyricsList 与 lyrics 两个外壳键', () async {
      // 回归 R2：入口先读 lyricsList（结构化分支），读不到才会再打一次网络。
      // 双键同时产出即可避免那次重复请求。
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: withLyricsCacheMeta(
          {
            'lyrics': <String, dynamic>{'value': '旧兜底'}
          },
          LyricsCacheSource.lrclib,
        ),
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async => {
          'lyrics': '[00:01.00]服务器歌词',
          'structuredLyrics': [
            {
              'synced': true,
              'line': [
                {'start': 1000, 'value': '服务器歌词'},
              ],
            },
          ],
        },
        saveCache: (_) async {},
      );
      expect(outcome.payload!['lyricsList'], isA<Map<String, dynamic>>());
      expect(outcome.payload!['lyrics'], isA<Map<String, dynamic>>());
    });

    test('兜底来源 → 同会话第二次不再复查', () async {
      var fetched = 0;
      final cached = withLyricsCacheMeta(
        {
          'lyricsList': <String, dynamic>{'value': '兜底歌词'}
        },
        LyricsCacheSource.netease,
      );
      Future<LyricsCacheOutcome> run() => resolveLyricsCache(
            songId: 's1',
            cached: cached,
            serverSource: LyricsCacheSource.server,
            fetchServerLyrics: () async {
              fetched++;
              return null;
            },
            saveCache: (_) async {},
          );

      await run();
      await run();
      expect(fetched, 1, reason: '每进程每首最多复查一次');
    });

    test('复查拿不到服务器歌词 → 仍返回缓存且不写缓存（不删缓存）', () async {
      var saved = 0;
      final cached = withLyricsCacheMeta(
        {
          'lyricsList': <String, dynamic>{'value': '兜底歌词'}
        },
        LyricsCacheSource.lrclib,
      );
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: cached,
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async => null,
        saveCache: (_) async => saved++,
      );
      expect(outcome.usable, isTrue);
      expect(outcome.source, LyricsCacheSource.lrclib);
      expect(saved, 0);
    });

    test('旧缓存（无 source）→ 视为可疑并复查', () async {
      var fetched = 0;
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: {
          'lyricsList': <String, dynamic>{'value': '旧缓存'}
        },
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async {
          fetched++;
          return null;
        },
        saveCache: (_) async {},
      );
      expect(fetched, 1);
      expect(outcome.usable, isTrue);
    });

    test('复查抛错 → 安全退回缓存，不抛出', () async {
      final cached = withLyricsCacheMeta(
        {
          'lyricsList': <String, dynamic>{'value': '兜底歌词'}
        },
        LyricsCacheSource.netease,
      );
      final outcome = await resolveLyricsCache(
        songId: 's1',
        cached: cached,
        serverSource: LyricsCacheSource.server,
        fetchServerLyrics: () async => throw StateError('offline'),
        saveCache: (_) async {},
      );
      expect(outcome.usable, isTrue);
      expect(outcome.source, LyricsCacheSource.netease);
    });
  });

  // ── 3. lyrics_source：形状归一化 ─────────────────────────────────────────
  group('extractLyricsText（形状归一化）', () {
    test('lyrics 字符串优先', () {
      expect(
        extractLyricsText({'lyrics': '[00:01.00]A'}),
        '[00:01.00]A',
      );
    });

    test('value 字符串（LRC 或纯文本）', () {
      expect(extractLyricsText({'value': '纯文本歌词'}), '纯文本歌词');
    });

    test('structuredLyrics 的 Subsonic 形状 {start, value}', () {
      final raw = extractLyricsText({
        'structuredLyrics': [
          {
            'synced': true,
            'line': [
              {'start': 5300, 'value': 'A'},
            ],
          },
        ],
      });
      expect(raw, contains('[00:05.30]A'));
    });

    test('structuredLyrics 的 Jellyfin 形状 {startTicks, text}（§2.6b 回归）', () {
      // startTicks 单位 100ns：53_000_000 ticks = 5300 ms
      final raw = extractLyricsText({
        'structuredLyrics': [
          {
            'synced': true,
            'line': [
              {'startTicks': 53000000, 'text': 'A'},
            ],
          },
        ],
      });
      expect(raw, contains('[00:05.30]A'));
      expect(hasLrcTimeline(raw!), isTrue);
    });

    test('空 payload / 无可用字段 → null', () {
      expect(extractLyricsText(<String, dynamic>{}), isNull);
      expect(extractLyricsText({'structuredLyrics': <dynamic>[]}), isNull);
      expect(extractLyricsText({'value': '   '}), isNull);
    });

    test('非 synced 行被跳过', () {
      final raw = extractLyricsText({
        'structuredLyrics': [
          {
            'synced': false,
            'line': [
              {'start': 0, 'value': 'A'},
            ],
          },
        ],
      });
      expect(raw, isNull);
    });
  });

  group('fallbackCachePayload', () {
    test('structured 形状 → lyricsList；其余 → lyrics', () {
      expect(
        fallbackCachePayload({'structuredLyrics': <dynamic>[]}).keys,
        contains('lyricsList'),
      );
      expect(
        fallbackCachePayload({'value': 'x'}).keys,
        contains('lyrics'),
      );
    });
  });

  // ── 4. LyricsSourceService：取源顺序与开关 ───────────────────────────────
  group('LyricsSourceService.fetchForSong', () {
    setUp(() async {
      resetLyricsRecheckState();
      // 网易云兜底默认开：测试里关掉，避免真实外网请求。
      final storage = StorageService();
      await storage.saveNeteaseFallback(false);
      await storage.saveLrcLibFallback(false);
    });

    test('getLyricsBySongId 命中 → source=server，isLrc=true', () async {
      final fake = _FakeSubsonic(byId: {'lyrics': '[00:01.00]A'});
      final result = await LyricsSourceService(subsonic: fake)
          .fetchForSong(_song('srv-hit'));
      expect(result, isNotNull);
      expect(result!.source, LyricsCacheSource.server);
      expect(result.isLrc, isTrue);
      expect(fake.byMetaCalls, 0, reason: '第一级命中就不该再问下一级');
    });

    test('道理鱼服务器 → source=daoliyu', () async {
      final fake =
          _FakeSubsonic(byId: {'lyrics': '[00:01.00]A'}, daoliyu: true);
      final result = await LyricsSourceService(subsonic: fake)
          .fetchForSong(_song('daoliyu-hit'));
      expect(result!.source, LyricsCacheSource.daoliyu);
    });

    test('getLyricsBySongId 落空 → 退到 getLyrics(artist,title)', () async {
      final fake = _FakeSubsonic(byMeta: {'value': '纯文本歌词'});
      final result = await LyricsSourceService(subsonic: fake)
          .fetchForSong(_song('meta-hit'));
      expect(result, isNotNull);
      expect(result!.source, LyricsCacheSource.server);
      expect(result.isLrc, isFalse);
      expect(fake.byIdCalls, 1);
      expect(fake.byMetaCalls, 1);
    });

    test('服务器全空 + 两个兜底开关都关 → null', () async {
      final fake = _FakeSubsonic();
      final result = await LyricsSourceService(subsonic: fake)
          .fetchForSong(_song('nothing'));
      expect(result, isNull);
    });

    test('Jellyfin 形状 structuredLyrics → 归一化后 isLrc=true（§2.6b 回归）', () async {
      final fake = _FakeSubsonic(byId: {
        'structuredLyrics': [
          {
            'synced': true,
            'line': [
              {'startTicks': 53000000, 'text': 'A'},
            ],
          },
        ],
      });
      final result = await LyricsSourceService(subsonic: fake)
          .fetchForSong(_song('jellyfin'));
      expect(result, isNotNull);
      expect(result!.isLrc, isTrue);
      expect(result.raw, contains('[00:05.30]A'));
    });

    test('服务器命中会写缓存，且带 source 标记（下次不再请求）', () async {
      final fake = _FakeSubsonic(byId: {'lyrics': '[00:01.00]A'});
      final service = LyricsSourceService(subsonic: fake);
      await service.fetchForSong(_song('cache-write'));

      // 换一个「服务器已无歌词」的假服务：若缓存生效，仍应拿到歌词。
      final offlineFake = _FakeSubsonic();
      final cached = await LyricsSourceService(subsonic: offlineFake)
          .fetchForSong(_song('cache-write'));
      expect(cached, isNotNull);
      expect(cached!.isLrc, isTrue);
      expect(offlineFake.byIdCalls, 0, reason: '服务器来源缓存应直接用，零网络');
    });
  });
}
