/// 道理鱼 seek 策略的**决策表**——纯函数，无副作用。
///
/// 与副作用分离的原因与 [audio_interruption_policy.dart] 同构：seek 的坑全在
/// 「这一次该不该重建音频源」这层语义上；抽成纯函数后可逐条单测，
/// [PlayerProvider] 只执行结果。
///
/// 决策表出处：`docs/道理鱼接入技术方案.md` §13。
///
/// **2026-10-24 修订（真机实证）**：曾按「Web 端 `/stream` 返回 206」把默认改成
/// native seek，真机结果是**播放器位置落到目标、但音频从 0s 重放**——服务端
/// 的 Range 只对浏览器成立，ExoPlayer 拿不到真正的定位。因此：
/// - 位置校验无法证明「内容真的跳了」，不能作为开启 native 的依据；
/// - 道理鱼转码流默认回到 `restart`（由服务端按 timeOffset 重新起流），
///   `native` 仅在确认可 seek 的源上启用（目前只有非道理鱼 / 直出原码流）。
library;

/// 一次 seek 应采用的执行方式（互斥，单值）。
enum SeekPlan {
  /// 直接 `AudioPlayer.seek()`：依赖播放器与服务端的真实定位能力。
  native,

  /// 重发一次「从目标时间起播」的流：重新建源，播放器位置从 0 计起，
  /// 由 `_streamBaseOffsetMs` 补回真实位置。
  restart,
}

/// 根据服务端与当前流推导 seek 方式。
///
/// [nativeSeekSupported] 表示**已验证**当前源可以被播放器真正 seek（不是
/// 「位置属性变了」，而是音频内容确实跳转）。默认 `false`：道理鱼转码流的
/// 真机表现是「位置动了、声音从头」，不能据此开启。
SeekPlan decideSeekPlan({
  required bool isDaoliyu,
  required bool streamTranscoded,
  bool nativeSeekSupported = false,
}) {
  // 非道理鱼（或直出原码流）走常规 HTTP 源，保持零变化。
  if (!isDaoliyu || !streamTranscoded) return SeekPlan.native;
  return nativeSeekSupported ? SeekPlan.native : SeekPlan.restart;
}
