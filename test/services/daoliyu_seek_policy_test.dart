import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/daoliyu_seek_policy.dart';

/// seek 决策表的逐条锁定（`docs/道理鱼接入技术方案.md` §13）。
///
/// 决策是纯函数，所以这里不需要播放器、不需要平台通道，也不会触发真实 seek。
void main() {
  SeekPlan decide({
    bool isDaoliyu = true,
    bool streamTranscoded = true,
    bool nativeSeekSupported = false,
  }) =>
      decideSeekPlan(
        isDaoliyu: isDaoliyu,
        streamTranscoded: streamTranscoded,
        nativeSeekSupported: nativeSeekSupported,
      );

  group('decideSeekPlan', () {
    test('非道理鱼：始终 native（零行为变化）', () {
      expect(decide(isDaoliyu: false), SeekPlan.native);
      expect(
        decide(isDaoliyu: false, nativeSeekSupported: false),
        SeekPlan.native,
      );
    });

    test('道理鱼直出原码流（format=raw）：native', () {
      expect(decide(streamTranscoded: false), SeekPlan.native);
    });

    test('道理鱼转码流：默认 restart（真机 Range 不生效，位置校验会骗人）', () {
      expect(decide(), SeekPlan.restart);
    });

    test('道理鱼转码流 + 已验证可 seek：native', () {
      expect(decide(nativeSeekSupported: true), SeekPlan.native);
    });
  });
}
