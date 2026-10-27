import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/widgets/lyrics_visual_curve.dart';

/// 歌词视觉曲线单测：把 Apple Music 对齐后的常量值钉死，
/// 防止后续调参回归（见 docs/歌词页视觉对齐苹果设计技术方案.md §4.9）。
void main() {
  group('lyricBlur', () {
    test('任意距离恒为 0（无模糊，纯 alpha 淡出）', () {
      for (var distance = 0; distance <= 6; distance++) {
        expect(lyricBlur(10 + distance, 10), 0.0);
        expect(lyricBlur(10 - distance, 10), 0.0);
      }
      expect(lyricBlur(0, -1), 0.0);
    });
  });

  group('lyricScale', () {
    test('字号阶梯 1.0 / 0.85 / 0.74 / 0.64，上下对称', () {
      const active = 10;
      expect(lyricScale(10, active), 1.0);
      expect(lyricScale(9, active), 0.85);
      expect(lyricScale(11, active), 0.85);
      expect(lyricScale(8, active), 0.74);
      expect(lyricScale(12, active), 0.74);
      expect(lyricScale(7, active), 0.64);
      expect(lyricScale(13, active), 0.64);
      expect(lyricScale(0, active), 0.64);
    });

    test('无活动行兜底 0.90', () {
      expect(lyricScale(0, -1), 0.90);
    });
  });

  group('lyricOpacity', () {
    test('已播/待播完全对称，阶梯 1.0 / 0.5 / 0.28 / 0.16 / 0.08', () {
      const active = 10;
      expect(lyricOpacity(10, active), 1.0);
      for (var distance = 1; distance <= 4; distance++) {
        expect(
          lyricOpacity(active + distance, active),
          lyricOpacity(active - distance, active),
        );
      }
      expect(lyricOpacity(9, active), 0.5);
      expect(lyricOpacity(11, active), 0.5);
      expect(lyricOpacity(8, active), 0.28);
      expect(lyricOpacity(12, active), 0.28);
      expect(lyricOpacity(7, active), 0.16);
      expect(lyricOpacity(13, active), 0.16);
      expect(lyricOpacity(6, active), 0.08);
      expect(lyricOpacity(14, active), 0.08);
    });

    test('无活动行兜底 0.55', () {
      expect(lyricOpacity(0, -1), 0.55);
    });
  });
}
