/// 有声书章节「是否真的播完了」的**判定表**——纯函数，无副作用。
///
/// 为什么需要它：转码流（道理鱼 `/api/tracks/{id}/stream?token=`、以及
/// Subsonic `stream?maxBitRate=&format=`）都是 **无 Content-Length 的 chunked
/// 管道**，播放器拿不到真实总长。服务端一关连接（JWT 到期、转码管线中断、
/// 读超时、缓存淘汰），ExoPlayer/AVPlayer 只会报「到流末尾了」= `completed`。
/// 有声书章节动辄 30~60 分钟，而 `_onSongComplete` 的有声书分支此前没有任何
/// 位置校验 —— 于是「流断了」被当成「这一章听完了」，直接跳下一章。
/// 用户 2026-10-30 真机复现：转码下有声书播到一半，音频+UI 一起进下一章。
///
/// 判定口径（与 `_recordSongEnd` 的 80% 统计口径无关，别混用）：
/// - 时长未知 → 无法判定，**按播完处理**（否则正常结束也会被当成断流去重试）；
/// - 位置已到/超过章末 → 播完；
/// - 距离章末在容差内 → 播完；否则判为**断流**。
///
/// 容差取 `min(章长 × 5%, 30s)`、下限 5s：40 分钟的章节留 30s 余量（转码流
/// 常在片尾差几秒），1 分钟的短章只留 5s，避免短章被 30s 容差整段吞掉。
library;

/// 容差上限：章节越长，片尾允许的秒数差越多。
const int kChapterEndMaxToleranceMs = 30000;

/// 容差下限：短章节也要留出一点片尾余量（编码/容器尾部）。
const int kChapterEndMinToleranceMs = 5000;

/// 章末容差（毫秒）——`min(章长 × 5%, 30s)`，夹在 [5s, 30s] 之间。
int chapterEndToleranceMs(int durationMs) {
  if (durationMs <= 0) return 0;
  return (durationMs * 0.05)
      .round()
      .clamp(kChapterEndMinToleranceMs, kChapterEndMaxToleranceMs);
}

/// [positionMs] 处收到的 `completed` 是否真的代表「这一章播完了」。
///
/// [positionMs] 是**本章内**位置（不是整本书序列位置），[durationMs] 是**本章**
/// 时长；两者都由 `PlayerProvider.chapterProgressSnapshot` 统一口径给出。
bool isGenuineChapterEnd({
  required int positionMs,
  required int durationMs,
}) {
  // 时长未知（chunked 转码流解析不出总长、章节元数据缺失）：无从判定，
  // 信任播放器，按播完处理。
  if (durationMs <= 0) return true;
  if (positionMs >= durationMs) return true;
  return durationMs - positionMs <= chapterEndToleranceMs(durationMs);
}
