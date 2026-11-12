/// 有声书进度「上云」的节流判定（纯函数，无 Flutter 依赖，可单测）。
///
/// 背景：本地进度每 5s 就写一次（离线/车机要 0 延迟），但直接照搬到云端会把
/// 5s 一次变成每分钟十几次 PATCH。所以非强制路径要合并写：**同一章 ≥45s 且
/// 位移 ≥60s** 才发一次；而「可能要换设备」的时刻（暂停 / 切章 / 切书 /
/// 退后台 / 停止）用 `force: true` 无条件发。
///
/// 另一个约束是慢网：一个 PATCH 还没回来时不再叠新的（`inFlight`），否则弱网
/// 下会积压一串几乎相同的请求，乱序到达时还可能把旧位置盖上去。force 例外
/// —— 这些时刻不发的代价（丢进度）比多发一次更大。
library;

/// 非 force 时的最小发送间隔。
const Duration kAudiobookProgressPushInterval = Duration(seconds: 45);

/// 非 force 时的最小位置变化（同一章内）。
const int kAudiobookProgressPushMinDeltaMs = 60 * 1000;

/// 是否应把这条进度推到云端。
///
/// [key] 形如 `bookId|episodeId`，用于判断是否换章；[lastKey]/[lastPosMs]/
/// [lastAt] 是上一次**发起**上报时的状态（失败也算，避免失败后每条都重试）。
bool shouldPushAudiobookProgress({
  required String key,
  required int positionMs,
  required String lastKey,
  required int lastPosMs,
  required DateTime? lastAt,
  required DateTime now,
  bool force = false,
  bool inFlight = false,
}) {
  if (force) return true;
  // 在途未完成：等它回来，别叠请求。
  if (inFlight) return false;
  // 从未发过（首章起播 / 冷启动）：立刻发一版，让云端尽快有位置。
  if (lastAt == null) return true;
  // 换章了：立刻发（跨端续播最在意的就是「听到第几章」）。
  if (key != lastKey) return true;
  final elapsed = now.difference(lastAt);
  if (elapsed < kAudiobookProgressPushInterval) return false;
  return (positionMs - lastPosMs).abs() >= kAudiobookProgressPushMinDeltaMs;
}
