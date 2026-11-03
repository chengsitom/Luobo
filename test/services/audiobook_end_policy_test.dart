import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/audiobook_end_policy.dart';

/// 章末判定表的逐条锁定。
///
/// 背景：转码流无 Content-Length，服务端断流会被播放器报成 `completed`，
/// 有声书分支必须用「本章位置 vs 本章时长」兜底，否则没播完就跳下一章
/// （用户 2026-10-30 真机复现）。
void main() {
  bool genuine(int positionMs, int durationMs) =>
      isGenuineChapterEnd(positionMs: positionMs, durationMs: durationMs);

  group('isGenuineChapterEnd', () {
    test('时长未知 → 按播完处理（不能把正常结束当断流重试）', () {
      expect(genuine(0, 0), isTrue);
      expect(genuine(120000, 0), isTrue);
    });

    test('40 分钟章节：播到 12:30 判为断流', () {
      expect(genuine(750000, 2400000), isFalse);
    });

    test('40 分钟章节：还剩 2 分钟判为断流，剩 30s 内判为播完', () {
      expect(genuine(2280000, 2400000), isFalse); // 剩 2:00
      expect(genuine(2370000, 2400000), isTrue); // 剩 0:30
      expect(genuine(2395000, 2400000), isTrue); // 剩 0:05
    });

    test('位置到达或超过章末 → 播完（元数据偏短时不乱救）', () {
      expect(genuine(2400000, 2400000), isTrue);
      expect(genuine(2450000, 2400000), isTrue);
    });

    test('60s 短章：容差收窄到 5s，不被 30s 上限吞掉', () {
      expect(chapterEndToleranceMs(60000), 5000);
      expect(genuine(50000, 60000), isFalse); // 剩 10s > 5s
      expect(genuine(55000, 60000), isTrue); // 剩 5s
    });

    test('容差夹取：短章下限 5s、长章上限 30s', () {
      expect(chapterEndToleranceMs(0), 0);
      expect(chapterEndToleranceMs(30000), 5000); // 5% = 1.5s → 抬到 5s
      expect(chapterEndToleranceMs(600000), 30000); // 5% = 30s
      expect(chapterEndToleranceMs(3600000), 30000); // 5% = 3min → 压到 30s
    });
  });
}
