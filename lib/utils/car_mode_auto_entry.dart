/// 判断"播放页停留 30s 自动进入车载页"的倒计时是否应该运行。
///
/// 仅普通歌曲播放中计时；任一条件成立即禁止 —— 电台播放、**有声书播放**、
/// 应用退后台、车载页已展示、歌词页展示。抽成纯函数以便单测钉死守卫逻辑
/// （test/utils/car_mode_auto_entry_test.dart），防止后续调参回归。
bool shouldRunAutoCarModeTimer({
  required bool isPlaying,
  required bool isPlayingRadio,
  required bool isPlayingAudiobook,
  required bool appBackgrounded,
  required bool carModeOpen,
  required bool lyricsShowing,
  bool autoEntryEnabled = true,
}) {
  // 设置里关掉「自动进入车载模式」→ 计时器不运行（只能手动进入）。
  if (!autoEntryEnabled) return false;
  if (appBackgrounded || carModeOpen || lyricsShowing) return false;
  // 有声书不自动进入车载模式（§10：无歌词 → 无歌词页联动需求）。
  return isPlaying && !isPlayingRadio && !isPlayingAudiobook;
}
