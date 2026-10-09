import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'luobo_tile.dart' show LuoboDivider;

/// 分组白卡：白底（深色 `#1C1C1E`）+ 圆角 16，组内用 [LuoboDivider] 分隔。
///
/// 用法：
/// ```dart
/// LuoboSectionHeader('播放与音质'),
/// LuoboCard(children: [
///   LuoboRow(title: '播放设置', onTap: ...),
///   LuoboDivider(indent: LuoboDivider.withIcon),
///   LuoboRow(title: '音质与流媒体', onTap: ...),
/// ]),
/// LuoboHint('说明文字'),
/// ```
class LuoboCard extends StatelessWidget {
  const LuoboCard({
    super.key,
    required this.children,
    this.padding,
    this.clip = true,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    // ⚠️ 必须用 Material 作卡体（不是 DecoratedBox + ClipRRect）：
    // 组内行的 InkWell 水波绘制在最近的 Material 上，若中间隔着不透明卡底，
    // 水波会被遮住 —— 点击分组行将没有任何按压反馈（旧 `_groupCard` 注释
    // 记载过同一个坑）。
    return Padding(
      padding: const EdgeInsets.only(bottom: LuoboSpacing.cardGap),
      child: Material(
        color: c.card,
        borderRadius: LuoboRadius.cardR,
        clipBehavior: clip ? Clip.antiAlias : Clip.none,
        child: padding == null
            ? content
            : Padding(padding: padding!, child: content),
      ),
    );
  }
}

/// 小节标题 —— **在卡外**，10.5px 灰字。
class LuoboSectionHeader extends StatelessWidget {
  const LuoboSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 4,
        right: 4,
        bottom: LuoboSpacing.sectionGap,
      ),
      child: Text(title, style: LuoboType.section.copyWith(color: c.fg2)),
    );
  }
}

/// 行下灰字说明 —— **在卡外**，视觉上贴紧上方那张卡。
class LuoboHint extends StatelessWidget {
  const LuoboHint(this.text,
      {super.key, this.bottomGap = LuoboSpacing.cardGap});

  final String text;

  /// 与下一张卡的距离。
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 4,
        right: 4,
        top: 0,
        bottom: bottomGap,
      ),
      child: Text(text, style: LuoboType.caption.copyWith(color: c.fg2)),
    );
  }
}

/// 便捷组合：小节标题 + 一张卡（内部自动插分隔线）。
///
/// 分隔线缩进按「本组行是否有图标」自动判断。
class LuoboGroup extends StatelessWidget {
  const LuoboGroup({
    super.key,
    this.title,
    required this.rows,
    this.hasIcon = true,
    this.hint,
  });

  final String? title;
  final List<Widget> rows;

  /// 本组行是否带左侧图标（决定分隔线缩进 43 / 14）。
  final bool hasIcon;

  /// 卡下方说明。
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      if (i > 0) {
        children.add(
          LuoboDivider(indent: hasIcon ? LuoboDivider.withIcon : null),
        );
      }
      children.add(rows[i]);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null) LuoboSectionHeader(title!),
        LuoboCard(
          children: children,
          // 有说明时让卡的下间距交给说明控制
        ),
        if (hint != null) LuoboHint(hint!),
      ],
    );
  }
}
