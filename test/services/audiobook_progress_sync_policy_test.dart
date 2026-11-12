import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/audiobook_progress_sync_policy.dart';

void main() {
  final t0 = DateTime(2026, 11, 12, 12, 0, 0);
  const book = 'abk_1';
  const ep1 = 'abe_1';
  const ep2 = 'abe_2';
  const key1 = '$book|$ep1';

  bool push({
    String key = key1,
    int posMs = 0,
    String lastKey = key1,
    int lastPosMs = 0,
    DateTime? lastAt,
    Duration after = Duration.zero,
    bool force = false,
    bool inFlight = false,
  }) =>
      shouldPushAudiobookProgress(
        key: key,
        positionMs: posMs,
        lastKey: lastKey,
        lastPosMs: lastPosMs,
        lastAt: lastAt,
        now: t0.add(after),
        force: force,
        inFlight: inFlight,
      );

  group('shouldPushAudiobookProgress', () {
    test('从未上报过 → 立刻发（冷启动/首章起播）', () {
      expect(push(lastAt: null), isTrue);
    });

    test('同一章 30s 内、位移 10min → 不发（未到 45s 窗口）', () {
      expect(
        push(lastAt: t0, after: const Duration(seconds: 30), posMs: 600000),
        isFalse,
      );
    });

    test('过了 45s 但只走了 20s → 不发（位移不足 60s）', () {
      expect(
        push(lastAt: t0, after: const Duration(seconds: 60), posMs: 20000),
        isFalse,
      );
    });

    test('过了 45s 且走了 60s → 发', () {
      expect(
        push(lastAt: t0, after: const Duration(seconds: 60), posMs: 60000),
        isTrue,
      );
    });

    test('换章 → 立刻发（哪怕刚发过 1s）', () {
      expect(
        push(
          key: '$book|$ep2',
          lastAt: t0,
          after: const Duration(seconds: 1),
          posMs: 0,
        ),
        isTrue,
      );
    });

    test('在途时不再叠加请求', () {
      expect(
        push(
            lastAt: t0,
            after: const Duration(minutes: 5),
            posMs: 300000,
            inFlight: true),
        isFalse,
      );
    });

    test('force 无视时间窗与在途（暂停/切章/退后台）', () {
      expect(push(lastAt: t0, after: Duration.zero, force: true), isTrue);
      expect(
          push(lastAt: t0, after: Duration.zero, force: true, inFlight: true),
          isTrue);
    });

    test('往回拖（位置变小）也算位移，不是只认前进', () {
      expect(
        push(
          lastAt: t0,
          after: const Duration(seconds: 50),
          lastPosMs: 300000,
          posMs: 200000,
        ),
        isTrue,
      );
    });
  });
}
