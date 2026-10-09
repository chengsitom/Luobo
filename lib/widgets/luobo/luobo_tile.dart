import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';

/// 设置 / 列表的**行**组件。7 个变体共用这一个 Widget：
///
/// | 变体 | 用法 |
/// |---|---|
/// | 单行 + chevron | `LuoboRow(title: '播放设置', onTap: ...)` |
/// | 单行 + 状态值 + chevron | `LuoboRow(title: '下载与存储', value: '1.2 GB', onTap: ...)` |
/// | 单行 + 开关 | `LuoboRow(title: '智能转码', trailing: LuoboSwitch(...))` |
/// | 单行 + 动作按钮 | `LuoboRow(title: '导出知识库', trailing: LuoboTextAction(...))` |
/// | 双行（主 + 副） | `LuoboRow(title: ..., subtitle: ...)` |
/// | 带 ⓘ 帮助 | `LuoboRow(title: ..., titleSuffix: IconButton(...))` |
/// | 单选组 | [LuoboRadioRow] |
/// | 行内滑块 | [LuoboSliderRow] |
/// | 危险行 | `LuoboRow(title: '移除连接', danger: true, onTap: ...)` |
///
/// ⚠️ **右侧位一律贴右边缘**（§2.3）：chevron / 状态值 / 开关 / 动作按钮都靠右。
/// 实现上靠 `Expanded` 吃掉标题，右侧元素自然落在最右。
///
/// ⚠️ **单选组只有选中项打勾，其余项什么都不带** —— 带 chevron 会让人以为
/// 「点进去还有一层」。
class LuoboRow extends StatelessWidget {
  const LuoboRow({
    super.key,
    required this.title,
    this.icon,
    this.subtitle,
    this.subtitleExtra,
    this.titleSuffix,
    this.value,
    this.trailing,
    this.onTap,
    this.showChevron,
    this.danger = false,
    this.titleStyle,
    this.iconColor,
  });

  final String title;

  /// 左侧图标（默认玫红 [LuoboAccent.accent]）。
  final IconData? icon;

  /// 副标题 —— 传了就变双行（主 + 副）。
  final String? subtitle;

  /// 副标题下方追加的自定义内容（进度条等）。
  final Widget? subtitleExtra;

  /// 紧跟标题之后的组件（如「智能转码」的 ⓘ 帮助入口）。
  final Widget? titleSuffix;

  /// 右侧状态值（灰色，右对齐）。
  final String? value;

  /// 自定义右侧位（开关 / 动作按钮 / 勾）。
  final Widget? trailing;

  final VoidCallback? onTap;

  /// 是否显示 chevron。默认：有 [onTap] 且没有 [value]/[trailing] 时显示。
  final bool? showChevron;

  /// 危险行（整行文字变强调色）。
  final bool danger;

  final TextStyle? titleStyle;
  final Color? iconColor;

  bool get _chevron {
    if (showChevron != null) return showChevron!;
    return onTap != null && value == null && trailing == null;
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final twoLine = subtitle != null || subtitleExtra != null;
    final fg = danger ? LuoboAccent.accent : c.fg;
    final titleStyle0 = (titleStyle ?? LuoboType.body).copyWith(color: fg);

    final titleLine = titleSuffix == null
        ? Text(
            title,
            style: titleStyle0,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: titleStyle0,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              titleSuffix!,
            ],
          );

    final titleCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        titleLine,
        if (subtitle != null) ...[
          const SizedBox(height: 3),
          Text(
            subtitle!,
            style: LuoboType.caption.copyWith(color: c.fg2),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (subtitleExtra != null) ...[
          const SizedBox(height: 4),
          subtitleExtra!,
        ],
      ],
    );

    final content = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight:
            twoLine ? LuoboSpacing.rowHeightTwoLine : LuoboSpacing.rowHeight,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LuoboSpacing.rowX,
          vertical: LuoboSpacing.rowY,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: LuoboSpacing.iconSlot,
                child: Center(
                  child: Icon(
                    icon,
                    size: 17,
                    color: iconColor ?? LuoboAccent.accent,
                  ),
                ),
              ),
              const SizedBox(width: LuoboSpacing.iconGap),
            ],
            // 标题与状态值同处一个 `spaceBetween` 行：
            // - 标题 `Flexible(flex: 1)`、值 `Flexible(flex: 2)`，各自**封顶**于
            //   可用宽度的 1/3 与 2/3，超出省略号 —— 服务器地址这类长值
            //   （`https://music.example.com:4533`）不再溢出成黄黑条。
            // - `spaceBetween` 把「两者都没占满」的余量全部塞进中间的空隙，
            //   所以**值始终贴右边缘**，不会被标题的分配宽度顶到中间。
            //   （若改用 `Expanded(标题) + Flexible(值)`，标题是紧约束、会吃掉
            //   自己那一半，值就跟着落在半宽处 —— 那是错的。）
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: titleCol),
                  if (value != null) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 2,
                      child: Text(
                        value!,
                        style: LuoboType.value.copyWith(color: c.fg2),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
            if (_chevron) ...[
              const SizedBox(width: 6),
              Icon(AppIcons.forward, size: 15, color: c.fg3),
            ],
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

/// 单选行：选中打勾，**未选中什么都不带**。
class LuoboRadioRow extends StatelessWidget {
  const LuoboRadioRow({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return LuoboRow(
      title: title,
      onTap: onTap,
      showChevron: false,
      trailing: selected
          ? const Icon(AppIcons.check, size: 16, color: LuoboAccent.accent)
          : null,
      titleStyle: LuoboType.body.copyWith(color: c.fg),
    );
  }
}

/// 行内滑块：标题在左、滑块贴右（设计稿 A2「每次加歌数」）。
///
/// 标题文案**自带当前值**（如 `预增益 +3.0 dB`），因此不再单独占一个右侧值位。
class LuoboSliderRow extends StatelessWidget {
  const LuoboSliderRow({
    super.key,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.icon,
    this.sliderWidth = 118,
  });

  final String title;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final IconData? icon;
  final double sliderWidth;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final enabled = onChanged != null;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: LuoboSpacing.rowHeight),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: LuoboSpacing.rowX,
          vertical: LuoboSpacing.rowY,
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              SizedBox(
                width: LuoboSpacing.iconSlot,
                child: Center(
                  child: Icon(icon, size: 17, color: LuoboAccent.accent),
                ),
              ),
              const SizedBox(width: LuoboSpacing.iconGap),
            ],
            Expanded(
              child: Text(
                title,
                style: LuoboType.body.copyWith(color: c.fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: sliderWidth,
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  activeTrackColor: LuoboAccent.accent,
                  inactiveTrackColor: c.divider,
                  thumbColor: LuoboAccent.onAccent,
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                ),
                child: Slider(
                  value: value.clamp(min, max).toDouble(),
                  min: min,
                  max: max,
                  divisions: divisions,
                  onChanged: enabled ? onChanged : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 行内的文字动作按钮（「导出」「生成」…）。
class LuoboTextAction extends StatelessWidget {
  const LuoboTextAction({
    super.key,
    required this.label,
    this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: LuoboType.body.copyWith(
          fontSize: 13,
          color: enabled ? LuoboAccent.accent : LuoboColors.of(context).fg3,
        ),
      ),
    );
  }
}

/// 设计稿的开关：34×20 胶囊 + 16px 圆点，玫红填充。
class LuoboSwitch extends StatelessWidget {
  const LuoboSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final on = value;
    final enabled = onChanged != null;
    return Semantics(
      toggled: on,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!on) : null,
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: AnimatedContainer(
            duration: LuoboMotion.micro,
            curve: LuoboMotion.enter,
            width: 34,
            height: 20,
            decoration: BoxDecoration(
              color: on ? LuoboAccent.accent : c.fg3,
              borderRadius: BorderRadius.circular(LuoboRadius.switchTrack),
            ),
            child: AnimatedAlign(
              duration: LuoboMotion.micro,
              curve: LuoboMotion.enter,
              alignment: on ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: LuoboAccent.onAccent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 组内分隔线：**缩进到文字起点** —— 有图标 43px，无图标 14px。
class LuoboDivider extends StatelessWidget {
  const LuoboDivider({super.key, this.indent});

  /// 不传则按「无图标」= 14。
  final double? indent;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final inset = indent ?? LuoboSpacing.dividerInsetPlain;
    return Padding(
      padding: EdgeInsets.only(left: inset, right: inset),
      child: Container(height: 0.5, color: c.divider),
    );
  }

  /// 有左侧图标时的缩进。
  static const double withIcon = LuoboSpacing.dividerInsetWithIcon;
}
