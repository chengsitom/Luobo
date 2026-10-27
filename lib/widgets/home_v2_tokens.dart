import 'package:flutter/material.dart';

/// 新首页独立配色 token（Apple Music 对齐，§5.5）。
///
/// 仅作用于新首页组件，不污染 `AppTheme` 全局值（暗色仍为纯黑 `#000000`，
/// 亮色仍为 `#F2F2F7`；新首页暗色 `#1C1C1E` / 亮色纯白）。
class HomeV2Tokens {
  final Color background;
  final Color card;
  final Color cardBorder;
  final Color divider;
  final Color secondaryText;
  final Color tertiaryText;

  const HomeV2Tokens({
    required this.background,
    required this.card,
    required this.cardBorder,
    required this.divider,
    required this.secondaryText,
    required this.tertiaryText,
  });

  /// 按当前主题亮度取 token 组。
  factory HomeV2Tokens.of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? HomeV2Tokens.dark
          : HomeV2Tokens.light;

  /// 暗色：Apple Music 暗色观感（iOS secondarySystemBackground 系）。
  static const HomeV2Tokens dark = HomeV2Tokens(
    background: Color(0xFF1C1C1E),
    card: Color(0xFF2C2C2E),
    cardBorder: Color(0xFF38383A),
    divider: Color(0xFF38383A),
    secondaryText: Color(0xFF98989E),
    tertiaryText: Color(0xFF6B6B6B),
  );

  /// 亮色：Apple Music 亮色观感（纯白底 + 浅灰描边区分卡片）。
  static const HomeV2Tokens light = HomeV2Tokens(
    background: Color(0xFFF3F3F3), // fnos 浅色页底（原先纯白，玻璃圆钮无对比）
    card: Color(0xFFFFFFFF),
    cardBorder: Color(0xFFE5E5EA),
    divider: Color(0xFFE5E5EA),
    secondaryText: Color(0xFF8E8E93),
    tertiaryText: Color(0xFFC7C7CC),
  );
}
