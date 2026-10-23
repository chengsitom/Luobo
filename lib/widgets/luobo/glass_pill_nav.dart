import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/design_tokens.dart';
import 'glass.dart';

/// 底栏条目。**纯图标、无文字标签**（对齐 fnos）。
@immutable
class GlassPillNavItem {
  const GlassPillNavItem({required this.icon, required this.label});

  final IconData icon;

  /// 无障碍标签（视觉上不显示）。
  final String label;
}

/// 悬浮胶囊底栏 —— **仅一级页**（首页 / 音乐库 / 设置）使用。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ③ 节。
/// 实测对齐：`docs/视觉与交互对标飞牛音乐技术方案.md` §6.1。
///
/// 布局：`[项][项][项][分隔线][专辑封面槽]`，**每一项都是 `flex: 1`**，
/// 因此三项严格等宽等距，专辑封面占一个等宽槽位（不是贴右边缘的小图标）。
/// 宽度由外层约束到 [LuoboGlass.navWidth]（256dp，居中浮动）。
///
/// - 选中态：玫红淡底圆（[LuoboGlass.navBubbleSize]）+ 玫红图标；未选中：`fg @ .75`
/// - **深色**：胶囊用「浅色面纱」渐变（[LuoboGlass.navTintDark]）而不是黑纱 ——
///   飞牛的深色胶囊比页面**更亮**，黑纱会像在页面上挖了个洞。
/// - 点击**未选中**的前三项时给一次轻触感（飞牛的同款反馈）；点已选中项 / 封面槽不震。
/// - 最右：当前专辑圆封面（点击进播放页）；无播放时传 `art: null` 即不渲染该槽。
///   进度环由调用方用 [LuoboNavArtRing] 包好再传进来 —— 这样进度每帧变化时
///   **只有那个环重建**，不会把整条毛玻璃底栏拖进每帧重建（§5 性能红线）。
class GlassPillNav extends StatelessWidget {
  const GlassPillNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.art,
    this.onArtTap,
    this.strongBorder = false,
  });

  final List<GlassPillNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  /// 当前专辑圆封面（通常已由 [LuoboNavArtRing] 包好）。
  /// 为 null 时**不渲染**封面槽（分隔线也一并隐藏）。
  final Widget? art;
  final VoidCallback? onArtTap;

  final bool strongBorder;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final unselected = c.fg.withValues(alpha: LuoboGlass.navUnselectedAlpha);
    final selectedBubble = LuoboAccent.soft(
      c.isDark ? LuoboGlass.navBubbleAlphaDark : LuoboGlass.navBubbleAlphaLight,
    );

    return LuoboGlassSurface(
      borderRadius: LuoboRadius.pillR,
      strongBorder: strongBorder,
      // 深色：浅色面纱渐变 + 稍强的描边（飞牛实测，见 token 注释）。
      // 浅色沿用默认的白 .65 实色，与飞牛浅色 `#FBFBFB` 一致。
      tintGradient: c.isDark ? LuoboGlass.navTintDark : null,
      borderColor: c.isDark ? LuoboGlass.navBorderDark : null,
      child: SizedBox(
        height: LuoboGlass.navHeight,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavSlot(
                  item: items[i],
                  selected: i == currentIndex,
                  unselectedColor: unselected,
                  selectedBubbleColor: selectedBubble,
                  onTap: () => onTap(i),
                ),
              ),
            if (art != null) ...[
              Container(
                width: 0.5,
                height: 22,
                color: c.fg.withValues(alpha: 0.12),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onArtTap,
                    child: art,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 底栏封面槽的**「静态灰轨道 + 进度填充」环**（§6.1）。
///
/// 飞牛实测：封面 **45dp**、环外径 **52dp**、笔画 **1.67dp**、环与封面之间留
/// **1.8dp 间隙**（**不贴封面**）；轨道整圈常驻，进度在轨道内推进，起笔 12 点、顺时针。
///
/// **纯展示**：`progress` 由调用方订阅后传入 —— 这样进度每帧变化时**只有本组件重建**，
/// 不会把整条毛玻璃底栏拖进每帧重建（§5 性能红线）。
///
/// **暂停时不做任何变化**（用户 2026-10-09 明确）：环与进度冻结在原位，
/// 不变暗、不隐藏、不归零 —— 所以这里不需要「是否在播」这个入参。
class LuoboNavArtRing extends StatelessWidget {
  const LuoboNavArtRing({super.key, required this.art, this.progress});

  /// 专辑封面（会被裁成圆形）。
  final Widget art;

  /// 播放进度 0~1。null / 0 = 只画灰轨道。
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return SizedBox(
      width: LuoboGlass.navArtRingSize,
      height: LuoboGlass.navArtRingSize,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _NavArtRingPainter(
            progress: progress,
            track: c.fg.withValues(alpha: LuoboGlass.ringTrackAlpha),
            fill: c.fg.withValues(alpha: LuoboGlass.ringProgressAlpha),
          ),
          // 封面比环小一圈 → 两者之间自然留出「不贴封面」的间隙。
          child: Center(
            child: SizedBox(
              width: LuoboGlass.navArtSize,
              height: LuoboGlass.navArtSize,
              child: ClipOval(child: art),
            ),
          ),
        ),
      ),
    );
  }
}

/// 封面槽外圈的「静态灰轨道 + 进度填充」。
class _NavArtRingPainter extends CustomPainter {
  const _NavArtRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
  });

  final double? progress;
  final Color track;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    const w = LuoboGlass.navArtRingWidth;
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - w / 2;

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = track,
    );

    final p = (progress ?? 0).clamp(0.0, 1.0);
    if (p <= 0) return;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      -math.pi / 2, // 起笔 12 点
      math.pi * 2 * p, // 顺时针
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..color = fill,
    );
  }

  @override
  bool shouldRepaint(_NavArtRingPainter old) =>
      old.progress != progress || old.track != track || old.fill != fill;
}

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.unselectedColor,
    required this.selectedBubbleColor,
    required this.onTap,
  });

  final GlassPillNavItem item;
  final bool selected;
  final Color unselectedColor;
  final Color selectedBubbleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // 只在「未选中 → 选中」时给触感：重复点当前项、点封面槽都不震（对齐飞牛）。
          if (!selected) HapticFeedback.lightImpact();
          onTap();
        },
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Container(
                  width: LuoboGlass.navBubbleSize,
                  height: LuoboGlass.navBubbleSize,
                  decoration: BoxDecoration(
                    // 对标飞牛：选中态是「淡玫红圆底 + 玫红图标」，而非「饱和实心圆 +
                    // 白图标」（用户 2026-10-20：配色向飞牛看齐、审美更轻盈）。
                    color: selectedBubbleColor,
                    shape: BoxShape.circle,
                  ),
                ),
              Icon(
                item.icon,
                size: LuoboGlass.navIconSize,
                color: selected ? LuoboAccent.accent : unselectedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
