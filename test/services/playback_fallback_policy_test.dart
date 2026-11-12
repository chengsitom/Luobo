import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/playback_fallback_policy.dart';

void main() {
  PlaybackFallbackStep step({
    int attempt = 0,
    bool wasTranscoded = true,
    int? maxBitRate = 320000,
    String? format = 'mp3',
    bool authError = false,
    bool jwtRefreshed = false,
  }) =>
      nextPlaybackFallbackStep(
        attempt: attempt,
        wasTranscoded: wasTranscoded,
        maxBitRate: maxBitRate,
        format: format,
        authError: authError,
        jwtRefreshed: jwtRefreshed,
      );

  group('nextPlaybackFallbackStep', () {
    test('转码 320k 失败 → 先降码率', () {
      expect(step(), PlaybackFallbackStep.downgradeBitrate);
    });

    test('已经是 128k mp3 还失败 → 退原码', () {
      expect(
        step(
            maxBitRate: kPlaybackFallbackBitrate,
            format: kPlaybackFallbackFormat),
        PlaybackFallbackStep.fallbackToRaw,
      );
    });

    test('只设了 format、没设码率 → 退原码（没有可降的码率）', () {
      expect(step(maxBitRate: null, format: 'mp3'),
          PlaybackFallbackStep.fallbackToRaw);
    });

    test('本来就没转码（原码/本地/有声书章节）→ 不重试', () {
      expect(
        step(wasTranscoded: false, maxBitRate: null, format: null),
        PlaybackFallbackStep.giveUp,
      );
    });

    test('401 且没换过票 → 换票重试（参数不变）', () {
      expect(step(authError: true), PlaybackFallbackStep.refreshJwtAndRetry);
    });

    test('401 但已经换过票 → 不再换，走降级', () {
      expect(
        step(authError: true, jwtRefreshed: true),
        PlaybackFallbackStep.downgradeBitrate,
      );
    });

    test('阶梯上限：两次重试后放弃（即使还没到位）', () {
      expect(step(attempt: kPlaybackFallbackMaxSteps),
          PlaybackFallbackStep.giveUp);
    });
  });

  group('looksLikeAuthError', () {
    test('识别 401 / 403 / token / jwt / unauthorized', () {
      expect(looksLikeAuthError('DioException 401'), isTrue);
      expect(looksLikeAuthError('HTTP 403 Forbidden'), isTrue);
      expect(looksLikeAuthError('invalid token'), isTrue);
      expect(looksLikeAuthError('jwt expired'), isTrue);
      expect(looksLikeAuthError(Exception('Unauthorized')), isTrue);
    });

    test('普通网络/解码错误不算鉴权', () {
      expect(looksLikeAuthError('Connection refused'), isFalse);
      expect(looksLikeAuthError('Decoder init failed'), isFalse);
      expect(looksLikeAuthError(null), isFalse);
    });
  });
}
