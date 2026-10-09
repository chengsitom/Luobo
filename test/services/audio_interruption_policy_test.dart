import 'package:audio_session/audio_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/audio_interruption_policy.dart';

/// 打断决策表的逐条锁定（`docs/音频打断处理技术方案.md` §4.1 决策表 / §6.1 用例）。
///
/// 决策是纯函数，所以这里不需要播放器、不需要平台通道，也不会触发真实暂停。
void main() {
  InterruptionDecision decide({
    required bool begin,
    required AudioInterruptionType type,
    bool isPlaying = true,
    bool wasPlaying = false,
  }) =>
      decideInterruption(
        begin: begin,
        type: type,
        isPlaying: isPlaying,
        wasPlayingBeforeInterruption: wasPlaying,
      );

  group('打断开始（begin）', () {
    test('duck：只降音量，不动暂停/恢复语义', () {
      final d = decide(
        begin: true,
        type: AudioInterruptionType.duck,
        wasPlaying: true,
      );
      expect(d.action, InterruptionAction.duck);
      expect(d.wasPlayingBeforeInterruption, isTrue, reason: '标记不应被 duck 改写');
    });

    test('pause + 正在播放：暂停并记住「打断前在播」', () {
      final d = decide(
        begin: true,
        type: AudioInterruptionType.pause,
        isPlaying: true,
      );
      expect(d.action, InterruptionAction.pause);
      expect(d.wasPlayingBeforeInterruption, isTrue);
    });

    test('pause + 已经暂停：暂停（幂等）但不置恢复标记', () {
      final d = decide(
        begin: true,
        type: AudioInterruptionType.pause,
        isPlaying: false,
      );
      expect(d.action, InterruptionAction.pause);
      expect(d.wasPlayingBeforeInterruption, isFalse,
          reason: '打断前没在播，结束后不得自动播');
    });

    test('unknown（永久抢焦点）：暂停且不置恢复标记', () {
      final d = decide(
        begin: true,
        type: AudioInterruptionType.unknown,
        isPlaying: true,
      );
      expect(d.action, InterruptionAction.pause);
      expect(d.wasPlayingBeforeInterruption, isFalse,
          reason: 'AUDIOFOCUS_LOSS 不会再来结束事件，置位只会误触发恢复');
    });
  });

  group('打断结束（end）', () {
    test('pause + 标记为真：恢复播放', () {
      final d = decide(
        begin: false,
        type: AudioInterruptionType.pause,
        wasPlaying: true,
      );
      expect(d.action, InterruptionAction.resume);
      expect(d.wasPlayingBeforeInterruption, isFalse, reason: '用完即清');
    });

    test('pause + 标记为假：什么都不做（用户没在播，不得自动播）', () {
      final d = decide(
        begin: false,
        type: AudioInterruptionType.pause,
        wasPlaying: false,
      );
      expect(d.action, InterruptionAction.none);
      expect(d.wasPlayingBeforeInterruption, isFalse);
    });

    test('duck：恢复音量', () {
      final d = decide(
        begin: false,
        type: AudioInterruptionType.duck,
        wasPlaying: true,
      );
      expect(d.action, InterruptionAction.restoreVolume);
      expect(d.wasPlayingBeforeInterruption, isTrue, reason: '标记不应被 duck 改写');
    });

    test('unknown：防御性清标记、不恢复', () {
      final d = decide(
        begin: false,
        type: AudioInterruptionType.unknown,
        wasPlaying: true,
      );
      expect(d.action, InterruptionAction.none);
      expect(d.wasPlayingBeforeInterruption, isFalse);
    });
  });

  group('标记生命周期', () {
    test('一次完整的瞬时打断：暂停 → 恢复 → 不再重复恢复', () {
      // ① 打断开始
      final started = decide(
        begin: true,
        type: AudioInterruptionType.pause,
        isPlaying: true,
      );
      expect(started.action, InterruptionAction.pause);
      var flag = started.wasPlayingBeforeInterruption;
      expect(flag, isTrue);

      // ② 打断结束
      final ended = decide(
        begin: false,
        type: AudioInterruptionType.pause,
        wasPlaying: flag,
      );
      expect(ended.action, InterruptionAction.resume);
      flag = ended.wasPlayingBeforeInterruption;
      expect(flag, isFalse);

      // ③ 再来一次结束事件（不应恢复 —— 用户已手动干预/标记已清）
      final again = decide(
        begin: false,
        type: AudioInterruptionType.pause,
        isPlaying: true,
        wasPlaying: flag,
      );
      expect(again.action, InterruptionAction.none);
    });

    test('永久抢焦点后不会被后续无关的结束事件误恢复', () {
      // begin(unknown) → 不置位
      final loss = decide(
        begin: true,
        type: AudioInterruptionType.unknown,
        isPlaying: true,
      );
      expect(loss.wasPlayingBeforeInterruption, isFalse);

      // 之后的 end(pause) 不应恢复
      final laterEnd = decide(
        begin: false,
        type: AudioInterruptionType.pause,
        wasPlaying: loss.wasPlayingBeforeInterruption,
      );
      expect(laterEnd.action, InterruptionAction.none);
    });
  });
}
