import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';
import 'glass.dart';

/// 悬浮玻璃圆钮 —— 二级页骨架 / 大标题页右上角 / 模态页右上角**共用这一个组件**。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ② 节。
///
/// | 形态 | 用途 | 实例 |
/// |---|---|---|
/// | [GlassCircleButtonStyle.glass] | 返回 / 搜索 / 扫码 / 更多 | 二级页左上、大标题页右上 |
/// | [GlassCircleButtonStyle.tinted] | 保存（淡底） | 浅色底上的确认 |
/// | [GlassCircleButtonStyle.solid] | 保存（实心玫红） | 模态页右上 ✓ |
///
/// ⚠️ **「更多」用哪个图标**：圆钮内用 [AppIcons.moreH]（横向 `···`）；
/// **行内右侧**用 [AppIcons.moreV]（纵向 `⋮`）。别混（§2.3）。
///
/// ⚠️ 深色下若页面是**纯色深底**（如全屏播放页纯色态），传 [strongBorder] = true。
class GlassCircleButton extends StatelessWidget {
  const GlassCircleButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.style = GlassCircleButtonStyle.glass,
    this.tooltip,
    this.size = LuoboGlass.circleButtonSize,
    this.iconSize = 17,
    this.strongBorder = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final GlassCircleButtonStyle style;
  final String? tooltip;
  final double size;
  final double iconSize;

  /// 纯色深底场景：加强描边。
  final bool strongBorder;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final enabled = onPressed != null;

    final Color iconColor;
    final Color? tint;
    final Color? border;
    final List<BoxShadow>? shadow;
    final bool useGlass;

    switch (style) {
      case GlassCircleButtonStyle.glass:
        iconColor = c.fg;
        tint = null;
        border = null;
        shadow = null;
        useGlass = true;
      case GlassCircleButtonStyle.tinted:
        iconColor = LuoboAccent.accent;
        tint = LuoboAccent.soft(0.14);
        border = LuoboAccent.soft(0.20);
        shadow = const [];
        useGlass = true;
      case GlassCircleButtonStyle.solid:
        iconColor = LuoboAccent.onAccent;
        tint = null;
        border = null;
        shadow = [
          BoxShadow(
            color: LuoboAccent.accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ];
        useGlass = false;
    }

    final child = SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Icon(
          icon,
          size: iconSize,
          color: enabled ? iconColor : iconColor.withValues(alpha: 0.4),
        ),
      ),
    );

    final Widget visual = useGlass
        ? LuoboGlassSurface(
            borderRadius: BorderRadius.circular(LuoboRadius.full),
            tint: tint,
            borderColor: border,
            shadows: shadow,
            strongBorder: strongBorder,
            child: child,
          )
        : DecoratedBox(
            decoration: BoxDecoration(
              color: LuoboAccent.accent,
              shape: BoxShape.circle,
              boxShadow: shadow,
            ),
            child: child,
          );

    final tappable = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: visual,
      ),
    );

    if (tooltip == null) return tappable;
    return Tooltip(message: tooltip!, child: tappable);
  }
}

enum GlassCircleButtonStyle { glass, tinted, solid }

/// 便捷：二级页左上的返回钮。
class GlassBackButton extends StatelessWidget {
  const GlassBackButton({super.key, this.onPressed, this.strongBorder = false});

  final VoidCallback? onPressed;
  final bool strongBorder;

  @override
  Widget build(BuildContext context) => GlassCircleButton(
        icon: AppIcons.back,
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        strongBorder: strongBorder,
      );
}
