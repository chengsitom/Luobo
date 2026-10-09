import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 玻璃层的统一构造：**tint + backdrop-blur + 描边 + 阴影**。
///
/// ⚠️ **性能红线**：本项目曾**特意移除**大面积毛玻璃——
/// `widgets/glass_surface.dart` 的注释明说旧毛玻璃包装被换成实色
/// （"BackdropFilter-free solid bottom sheet"），`widgets/mini_player.dart`
/// 也把 sigma 从 24 降到 12 并注明是为省 GPU。
///
/// 因此玻璃**只允许用于小面积固定元素**：
/// 底栏 / 迷你播放条 / 悬浮圆钮 / 锚定菜单 / sheet 壳。
/// **禁止**用于：列表项、滚动中的大卡片、整页背景。
///
/// ⚠️ 深色下 tint 是**黑 .50**，本身几乎不可见；可见性来自
/// 「模糊 + 白 .10 描边 + 阴影」。所以**深色玻璃不能放在纯色深底上**——
/// 那种场景请传 [strongBorder] = true（描边提到白 .20）。
class LuoboGlassSurface extends StatelessWidget {
  const LuoboGlassSurface({
    super.key,
    required this.child,
    this.borderRadius,
    this.blur,
    this.tint,
    this.borderColor,
    this.shadows,
    this.padding,
    this.strongBorder = false,
  });

  final Widget child;

  /// 默认胶囊圆角（[LuoboRadius.pill]）。
  final BorderRadius? borderRadius;

  /// 默认 [LuoboGlass.blur]（24）；迷你播放条传 [LuoboGlass.blurBar]（12）。
  final double? blur;

  final Color? tint;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry? padding;

  /// 纯色深底场景：把描边提到白 .20，避免按钮「消失」。
  final bool strongBorder;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final br = borderRadius ?? LuoboRadius.pillR;
    final sigma = blur ?? LuoboGlass.blur;
    final border = borderColor ??
        (strongBorder && c.isDark
            ? LuoboGlass.strongBorderDark
            : c.glassBorder);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        boxShadow: shadows ?? c.glassShadow,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: tint ?? c.glassTint,
              borderRadius: br,
              border: Border.all(
                color: border,
                width: LuoboGlass.borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
