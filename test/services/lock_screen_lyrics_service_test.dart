import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/lock_screen_lyrics_service.dart';

/// 车机/通知栏歌词推送回归测试。
///
/// 背景：Android 侧当前歌词行必须经 `com.devid.musly/lyrics` 通道推给原生，
/// 原生写入 `MediaMetadata.DISPLAY_SUBTITLE`（通知栏副标题），车机（蓝牙、
/// CarLife）读的就是该字段。该推送曾被上游重构删除，此测试用于防回归。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.devid.musly/lyrics');
  const lrc = '[00:00.00]第一行\n[00:10.00]第二行\n';
  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return <String, dynamic>{'ok': true};
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  List<MethodCall> callsOf(String method) =>
      calls.where((c) => c.method == method).toList();

  test('Android：播放位置推进时把当前歌词行推给原生（参数名 currentLine）', () async {
    final service = LockScreenLyricsService();
    await service.loadLyrics(lrc);

    service.startSync(Stream.value(const Duration(seconds: 11)));
    await pumpEventQueue();

    final updates = callsOf('updateLyrics');
    expect(updates, isNotEmpty, reason: 'Android 上必须把歌词行推给原生');
    expect(
      (updates.last.arguments as Map)['currentLine'],
      '第二行',
      reason: '参数名必须与原生 LyricsPlugin 约定一致（currentLine）',
    );
  });

  test('Android：换歌时先清掉上一首残留的歌词行', () async {
    final service = LockScreenLyricsService();
    await service.loadLyrics(lrc);

    expect(callsOf('clearLyrics'), isNotEmpty, reason: '换歌需先清原生副标题，避免旧歌词挂到新歌上');
  });

  test('Android：无歌词时清空原生歌词行', () async {
    final service = LockScreenLyricsService();
    await service.loadLyrics(lrc);
    calls.clear();

    await service.loadLyrics(null);

    expect(callsOf('clearLyrics'), isNotEmpty);
    expect(callsOf('updateLyrics'), isEmpty);
  });

  test('Android：相同歌词行不重复推送（节流去重）', () async {
    final service = LockScreenLyricsService();
    await service.loadLyrics(lrc);

    service.startSync(Stream.fromIterable(const [
      Duration(seconds: 11),
      Duration(seconds: 12),
      Duration(seconds: 13),
    ]));
    await pumpEventQueue();

    expect(callsOf('updateLyrics').length, 1, reason: '同一行只推一次，避免高频刷新通知/元数据');
  });

  test('非 Android 平台：不触碰原生歌词通道', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;

    final service = LockScreenLyricsService();
    await service.loadLyrics(lrc);
    service.startSync(Stream.value(const Duration(seconds: 11)));
    await pumpEventQueue();

    expect(calls, isEmpty, reason: '桌面端不应调用 Android 歌词通道');
  });
}
