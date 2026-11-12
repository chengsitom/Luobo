/// 播放失败后的降级重试决策（纯函数，可单测）。
///
/// 现状问题：`playSong` 的 catch 只 `debugPrint` + 置 `_isPlaying = false`，
/// 用户看到的是「突然不播了」，没有任何兜底。而失败原因里最常见的两类都**可以
/// 自救**：
///   1. JWT 过期 —— 媒体流 URL 里的 token 播放器无法在 401 后重试，但我们可以
///      换票后重发同一条流；
///   2. 转码管线挂了 / 该格式不支持 —— 降码率或退回原码直出通常能播。
///
/// 所以这里定义一条**有限阶梯**（最多两次重试），不做无限重试：
///   换票重试 → 降码率 → 原码直出 → 放弃
///
/// 「换票」和「降级」是两类完全不同的动作：401 换票后**参数不变**（问题在鉴权），
/// 降级才是改参数（问题在转码）。混在一起会导致「401 时降了码率」这种无意义降级。
library;

/// 下一步该做什么。
enum PlaybackFallbackStep {
  /// 换一张 JWT 后按**原参数**重试（401/403 类鉴权失败）。
  refreshJwtAndRetry,

  /// 降码率重试（转码失败，通常是服务端 ffmpeg 对这个文件/格式吃力）。
  downgradeBitrate,

  /// 退回原码直出（`format=null` + `maxBitRate=null`）。局域网/可直连时最稳。
  fallbackToRaw,

  /// 阶梯走完，交给上层报错。
  giveUp,
}

/// 降级时的码率上限：128k 对「先能听」足够，且 ffmpeg 压 128k 几乎不会失败。
const int kPlaybackFallbackBitrate = 128000;

/// 降级时统一用的容器格式（mp3 是兼容性最好的兜底）。
const String kPlaybackFallbackFormat = 'mp3';

/// 阶梯上限（不含换票）。
const int kPlaybackFallbackMaxSteps = 2;

/// 计算下一步降级动作。
///
/// [attempt] 已重试次数（0 = 首次失败）；[wasTranscoded] 本次是否走了转码；
/// [maxBitRate]/[format] 本次用的转码参数；[authError] 错误是否疑似鉴权；
/// [jwtRefreshed] 本次播放是否已经换过票（换票只做一次，防止死循环）。
PlaybackFallbackStep nextPlaybackFallbackStep({
  required int attempt,
  required bool wasTranscoded,
  required int? maxBitRate,
  required String? format,
  bool authError = false,
  bool jwtRefreshed = false,
}) {
  if (attempt >= kPlaybackFallbackMaxSteps) return PlaybackFallbackStep.giveUp;

  // 鉴权问题优先换票：参数是对的，换票通常就好了。
  if (authError && !jwtRefreshed) {
    return PlaybackFallbackStep.refreshJwtAndRetry;
  }

  // 本来就没走转码（原码/本地/离线）→ 没有可降的档位。
  if (!wasTranscoded) return PlaybackFallbackStep.giveUp;

  // 已经是兜底码率/格式 → 直接退原码。
  final atLowestBitrate =
      maxBitRate == null || maxBitRate <= kPlaybackFallbackBitrate;
  if (atLowestBitrate &&
      (format == null || format == kPlaybackFallbackFormat)) {
    return PlaybackFallbackStep.fallbackToRaw;
  }

  return PlaybackFallbackStep.downgradeBitrate;
}

/// 错误信息是否疑似鉴权失败（不同平台/层次的文案不统一，只能宽松匹配）。
bool looksLikeAuthError(Object? error) {
  if (error == null) return false;
  final text = error.toString().toLowerCase();
  const markers = [
    '401',
    '403',
    'unauthorized',
    'forbidden',
    'token',
    'jwt',
    'auth',
  ];
  return markers.any(text.contains);
}
