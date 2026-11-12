/// 播放失败的**一次性通知**（给 UI 层弹提示用）。
///
/// 为什么不让 Provider 直接弹 toast：Provider 不持有 `BuildContext`，也不该依赖
/// 组件层。播放失败时 Provider 只负责「说一声」，具体怎么展示由壳层决定
/// （当前是 `main_screen` 收到后弹 `showLuoboToast`）。
///
/// 只在**降级全部失败**时发出（换票/降码率/原码直出都试过了）。中途降级成功
/// 不发 —— 用户不需要知道我们内部换过票。
class PlaybackNotice {
  const PlaybackNotice({required this.songTitle, this.reason});

  /// 展示用标题（曲名 / 章节名）。
  final String songTitle;

  /// 失败原因摘要（诊断用，不直接展示给用户）。
  final String? reason;

  @override
  String toString() => 'PlaybackNotice($songTitle, $reason)';
}
