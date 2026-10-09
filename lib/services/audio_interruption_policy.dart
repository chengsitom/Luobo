/// 音频打断（audio focus / interruption）的**决策表**——纯函数，无副作用。
///
/// 与副作用分离的原因：打断处理真正的坑全在「该不该暂停 / 该不该恢复」这层语义上，
/// 而它依赖 `audio_session` 的事件与播放器状态；把决策抽成纯函数后可以逐条单测
/// （见 `test/services/audio_interruption_policy_test.dart`），副作用只剩一个 switch。
///
/// 决策表出处：`docs/音频打断处理技术方案.md` §4.1（方案 B）。
library;

import 'package:audio_session/audio_session.dart';

/// 一次打断事件应执行的动作（互斥，单值）。
enum InterruptionAction {
  /// 不干预。
  ///
  /// 典型场景：打断结束，但打断前并没有在播放（例如用户在被叫停后手动暂停过）。
  none,

  /// 降音量（瞬时打断里「可 duck」的场景）。
  duck,

  /// 暂停（瞬时打断与永久抢焦点都走这里）。
  pause,

  /// 恢复播放（打断结束，且打断前确实在播）。
  resume,

  /// 把音量恢复到用户设定值。
  restoreVolume,
}

/// 决策结果。
class InterruptionDecision {
  const InterruptionDecision(this.action, this.wasPlayingBeforeInterruption);

  /// 本事件要执行的动作。
  final InterruptionAction action;

  /// 处理完本事件后应保存的「打断前是否在播」标记。
  ///
  /// 只在 `begin + pause`（瞬时打断）时置位：`unknown` 对应 `AUDIOFOCUS_LOSS`
  /// （永久抢焦点），`audio_session` 在收到 LOSS 时会先 `abandonAudioFocus()`
  /// 注销监听 ⇒ **永远不会再有结束事件**，置位只会让后续无关的结束事件误触发恢复播放。
  final bool wasPlayingBeforeInterruption;

  @override
  String toString() =>
      'InterruptionDecision(${action.name}, wasPlaying=$wasPlayingBeforeInterruption)';
}

/// 根据事件与当前状态推导动作。
///
/// [isPlaying] 是**事件到达时**播放器是否在播（用于决定打断结束后要不要恢复）。
InterruptionDecision decideInterruption({
  required bool begin,
  required AudioInterruptionType type,
  required bool isPlaying,
  required bool wasPlayingBeforeInterruption,
}) {
  if (begin) {
    switch (type) {
      case AudioInterruptionType.duck:
        // 只降音量，不动暂停/恢复语义。
        return InterruptionDecision(
          InterruptionAction.duck,
          wasPlayingBeforeInterruption,
        );
      case AudioInterruptionType.pause:
        // 瞬时打断（电话 / 导航播报 / 语音消息）：记住是否在播，结束后据此恢复。
        return InterruptionDecision(InterruptionAction.pause, isPlaying);
      case AudioInterruptionType.unknown:
        // 永久抢焦点：暂停且**不**自动恢复。
        return InterruptionDecision(InterruptionAction.pause, false);
    }
  }

  switch (type) {
    case AudioInterruptionType.duck:
      return InterruptionDecision(
        InterruptionAction.restoreVolume,
        wasPlayingBeforeInterruption,
      );
    case AudioInterruptionType.pause:
      return InterruptionDecision(
        wasPlayingBeforeInterruption
            ? InterruptionAction.resume
            : InterruptionAction.none,
        false,
      );
    case AudioInterruptionType.unknown:
      // Android 上结束事件只会是 duck / pause（audio_session 的映射），
      // 这里防御性清标记。
      return InterruptionDecision(InterruptionAction.none, false);
  }
}
