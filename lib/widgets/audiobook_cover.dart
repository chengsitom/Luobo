import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/cover_palette.dart';

/// 有声书书封尺寸档位（docs/有声书接入技术方案.md §15.2）。
///
/// 服务端**没有任何封面字段**，因此所有封面位一律渲染「纯文字装帧」：
/// 低饱和纸色/墨色底 + 书名排版 + 书脊/内框/小字，同一本书处处一致。
enum AudiobookCoverSize {
  /// 章节页头部（132×176）。
  large(132, 176, 6),

  /// 「继续收听」卡片（56×74）。
  medium(56, 74, 5),

  /// 书架行首（48×64）。
  small(48, 64, 4);

  const AudiobookCoverSize(this.width, this.height, this.radius);

  final double width;
  final double height;
  final double radius;
}

/// 书封版式：长书名竖排（可多列、从右往左）/ 居中双行 / 上标题。
enum _CoverLayout { vertical, centered, topTitle }

/// 有声书纯文字书封。
///
/// - 底色：8 组低饱和纸色（浅）/ 墨色（深），`stableCoverHash(title)` 确定性取色；
/// - 版式：`stableCoverHash('$title#layout')` 取三种之一，与底色解耦；
/// - 装帧：书脊色带 + 折痕高光、1px 内框、底部「有声书 · 演播者」、类型角标（仅 large）；
/// - 小尺寸（small/medium）只显示书名首字，避免截断出歧义（「鬼吹灯」→「鬼吹」）。
class AudiobookCover extends StatelessWidget {
  final String title;
  final AudiobookCoverSize size;

  /// 演播者（底部小字，仅 large/medium）。
  final String? narrator;

  /// 类型（相声/评书/小说…，仅 large 右上角角标，取前两字竖排）。
  final String? category;

  /// 章节页头部需要投影；列表内不加（靠底色区分）。
  final bool elevated;

  const AudiobookCover({
    super.key,
    required this.title,
    this.size = AudiobookCoverSize.small,
    this.narrator,
    this.category,
    this.elevated = false,
  });

  /// 8 组浅色纸/装帧底色 → 文字色。
  static const List<List<Color>> _lightPalette = [
    [Color(0xFFEFE7D8), Color(0xFF3A342B)],
    [Color(0xFFDCE4E8), Color(0xFF2A3439)],
    [Color(0xFFE9DCDC), Color(0xFF3A2E31)],
    [Color(0xFFDFE5DC), Color(0xFF2E352C)],
    [Color(0xFFEFE2CC), Color(0xFF3B3125)],
    [Color(0xFFE0DCE7), Color(0xFF332E3A)],
    [Color(0xFFE4E1DB), Color(0xFF33312C)],
    [Color(0xFFD8DEE7), Color(0xFF28313D)],
  ];

  /// 深色墨/布面底色 → 文字色（与浅色一一对应）。
  static const List<List<Color>> _darkPalette = [
    [Color(0xFF232019), Color(0xFFE8E0D0)],
    [Color(0xFF1B2429), Color(0xFFD9E2E6)],
    [Color(0xFF2A2224), Color(0xFFE9DCDE)],
    [Color(0xFF1E2620), Color(0xFFDCE5DA)],
    [Color(0xFF2A2418), Color(0xFFEEE2CA)],
    [Color(0xFF24212B), Color(0xFFE2DDEC)],
    [Color(0xFF262521), Color(0xFFE6E2D9)],
    [Color(0xFF1E2834), Color(0xFFD9E1EC)],
  ];

  bool get _isLarge => size == AudiobookCoverSize.large;
  bool get _isSmall => size == AudiobookCoverSize.small;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final trimmed = title.trim();
    final text = trimmed.isEmpty ? l10n.audiobooks : trimmed;

    final palette = isDark ? _darkPalette : _lightPalette;
    final colors = palette[coverPaletteIndex(text, palette.length)];
    final bg = colors[0];
    final fg = colors[1];
    final layout =
        _CoverLayout.values[coverPaletteIndex('$text#layout', _CoverLayout.values.length)];

    final w = size.width;
    final h = size.height;
    final spineW = math.max(4.0, w * 0.05);
    final inset = math.max(6.0, w * 0.06);
    // 底部小字占位：large 26 / medium 16 / small 无。
    final footSpace = _isLarge ? 26.0 : (_isSmall ? 0.0 : 16.0);
    final contentLeft = spineW + (_isLarge ? 11 : 9);
    final availW = w - contentLeft - inset - 4;
    final availH = h - 10 - footSpace;

    return Container(
      width: w,
      height: h,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size.radius),
        // 纯色为主 + 极轻斜向明暗（模拟纸张受光），不做高饱和渐变跳色。
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [bg, Color.lerp(bg, Colors.black, 0.04)!],
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // 书脊：左侧色带 + 右缘 1px 白高光（折痕）。
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: spineW,
            child: ColoredBox(color: Color.lerp(bg, Colors.black, 0.12)!),
          ),
          Positioned(
            left: spineW - 1,
            top: 0,
            bottom: 0,
            width: 1,
            child: ColoredBox(color: Colors.white.withValues(alpha: 0.22)),
          ),
          // 内框。
          Positioned(
            left: inset,
            right: inset,
            top: inset,
            bottom: inset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.085),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          // 书名。
          if (_isSmall || size == AudiobookCoverSize.medium)
            _buildInitial(fg, text)
          else
            ..._buildLargeTitle(fg, text, layout, contentLeft, inset, availW, availH),
          // 底部小字（large/medium）。
          if (!_isSmall)
            Positioned(
              left: contentLeft,
              right: inset,
              bottom: _isLarge ? 10 : 6,
              child: Text(
                narrator == null || narrator!.isEmpty
                    ? l10n.audiobooks
                    : '${l10n.audiobooks} · $narrator',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: _isLarge ? 9.5 : 7,
                  height: 1.1,
                  letterSpacing: 0.5,
                  color: fg.withValues(alpha: 0.55),
                ),
              ),
            ),
          // 类型角标（仅 large）：两字竖排小方章。
          if (_isLarge && category != null && category!.trim().isNotEmpty)
            Positioned(
              top: inset + 2,
              right: inset + 2,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: fg.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                  borderRadius: BorderRadius.circular(1),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final ch in category!.trim().characters.take(2))
                        Text(
                          ch,
                          style: TextStyle(
                            fontSize: 7.5,
                            height: 1.05,
                            fontWeight: FontWeight.w600,
                            color: fg.withValues(alpha: 0.55),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 小/中尺寸：只放书名首字（居中；medium 略偏上给底部小字让位）。
  Widget _buildInitial(Color fg, String text) {
    final fs = _isSmall ? 25.0 : 22.0;
    return Positioned.fill(
      bottom: _isSmall ? 0 : 14,
      child: Center(
        child: Text(
          text.characters.first,
          style: TextStyle(
            fontSize: fs,
            height: 1,
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  /// large：三种版式。返回 Stack 的 Positioned 列表。
  List<Widget> _buildLargeTitle(
    Color fg,
    String text,
    _CoverLayout layout,
    double contentLeft,
    double inset,
    double availW,
    double availH,
  ) {
    switch (layout) {
      case _CoverLayout.centered:
        return [
          Positioned(
            left: contentLeft,
            right: inset + 6,
            top: 0,
            bottom: _isLarge ? 26 : 16,
            child: Center(
              child: Text(
                text,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 27,
                  height: 1.28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: fg,
                ),
              ),
            ),
          ),
        ];
      case _CoverLayout.topTitle:
        return [
          Positioned(
            left: contentLeft,
            right: inset + 6,
            top: inset + 8,
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 24,
                height: 1.28,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: fg,
              ),
            ),
          ),
        ];
      case _CoverLayout.vertical:
        return [_buildVerticalTitle(fg, text, contentLeft, inset, availW, availH)];
    }
  }

  /// 传统中文竖排：从右往左分列，字号/列数按可用宽高自适应。
  Widget _buildVerticalTitle(
    Color fg,
    String text,
    double contentLeft,
    double inset,
    double availW,
    double availH,
  ) {
    final chars = text.characters.toList();
    var fs = 26.0;
    var perCol = 1;
    var cols = 1;
    while (true) {
      perCol = math.max(1, (availH / (fs * 1.1)).floor());
      cols = (chars.length / perCol).ceil();
      final blockW = cols * fs * 1.1 + (cols - 1) * 4;
      if (blockW <= availW || fs <= 12) break;
      fs -= 1;
    }

    final groups = <List<String>>[];
    for (var i = 0; i < chars.length; i += perCol) {
      groups.add(chars.sublist(i, math.min(i + perCol, chars.length)));
    }
    final blockH = math.min(perCol, chars.length) * fs * 1.1;
    final top = 10.0 + math.max(0.0, (availH - blockH) / 2);

    return Positioned(
      left: contentLeft,
      right: inset + 4,
      top: top,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 反转后第一列落在最右（传统竖排从右往左读）。
          for (var i = groups.length - 1; i >= 0; i--) ...[
            if (i != groups.length - 1) const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final ch in groups[i])
                  Text(
                    ch,
                    style: TextStyle(
                      fontSize: fs,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
