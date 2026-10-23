import 'package:flutter/material.dart';

/// 歌曲列表的分隔线（全局规则，2026-10-22 用户定 + 静态图实测）：
/// **左端从封面右缘往后一点开始**（普通行 indent=76 = 16+48+12；
/// 多选行带选择框再加 30 → 106），右端 16dp；颜色比主题默认更深
/// （浅色 #C2C2C2 / 深色 #48484A，静态图实测浅色最暗 ≈194）。
class LuoboSongDivider extends StatelessWidget {
  /// 左缩进（普通行 76；带选择框的多选行 106）。
  final double indent;

  const LuoboSongDivider({super.key, this.indent = 76});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Divider(
      height: 0.5,
      thickness: 0.5,
      indent: indent,
      endIndent: 16,
      color: isDark ? const Color(0xFF48484A) : const Color(0xFFC2C2C2),
    );
  }
}
