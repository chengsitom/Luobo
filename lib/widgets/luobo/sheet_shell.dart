import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';
import 'capsule_button.dart';

/// Sheet 壳 —— **5 种浮层共用这一个外壳**：
/// 歌曲 `⋮` 上下文面板 / 单选面板 / 胶囊叠面板 / 确认弹窗 / 选择器。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ⑦ 节。
/// 特征：顶部圆角 20 · 把手 36×4 · 遮罩 `rgba(0,0,0,.42)` · 内边距 14。
///
/// ⚠️ 这里**不用** `BackdropFilter` —— 大面积毛玻璃是本项目的性能红线
/// （见 `widgets/luobo/glass.dart` 的说明）。
Future<T?> showLuoboSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  String? title,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showHandle = true,
  EdgeInsetsGeometry? padding,
}) {
  return showModalBottomSheet<T>(
    context: context,
    // ⚠️ 必须走 **root navigator**：设置页都在 `main_screen` 的**嵌套 Navigator**
    // 里，而迷你播放条与底栏在嵌套区**之外**（外层 Column）。默认 useRootNavigator:
    // false 会让弹窗只盖住嵌套区 → 播放条与底栏压在弹窗**上面**、遮罩也盖不住它们
    // （真机截图实测过）。
    useRootNavigator: true,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: LuoboMotion.scrim,
    builder: (ctx) => LuoboSheetShell(
      title: title,
      showHandle: showHandle,
      padding: padding,
      child: builder(ctx),
    ),
  );
}

/// **单选 Sheet**（设计稿 §9.7 范式，参考 fnos「音质偏好」）：
/// 底部升起 + 居中标题 + 每项一张**独立白卡** + 选中项打**玫红勾**。
///
/// ⚠️ 未选中项**什么都不带**（不带 chevron）—— 带 chevron 会让人以为「点进去还有一层」。
///
/// 返回值：用户选中的值；点遮罩/下滑取消时返回 null。
Future<T?> showLuoboPickerSheet<T>({
  required BuildContext context,
  required String title,
  required List<({T value, String label})> options,
  required T? selected,
}) {
  return showLuoboSheet<T>(
    context: context,
    title: title,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final opt in options)
          LuoboSheetRow(
            title: opt.label,
            selected: opt.value == selected,
            showChevron: false,
            onTap: () => Navigator.of(ctx).pop(opt.value),
          ),
      ],
    ),
  );
}

/// **确认弹窗**（设计稿/08 §4，规格见 `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.2）：
/// 底部升起 · **无把手**（fnos 确认卡没有拖拽把手，与多选/选择器不同，
/// 故 `showHandle: false`）· 居中标题 + 灰字说明 + 左右双胶囊
/// （取消=灰底 [LuoboCapsuleStyle.normal] / 确认=玫红实心 [LuoboCapsuleStyle.primary]，
/// **含删除类**——fnos 全站确认键统一玫红，不另设红色变体）。
///
/// 返回值：`true`=用户确认；点遮罩/下滑取消时返回 `null`。
Future<bool?> showLuoboConfirmSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
}) {
  return showLuoboSheet<bool>(
    context: context,
    title: title,
    showHandle: false,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: LuoboType.caption.copyWith(
              fontSize: 13,
              color: LuoboColors.of(ctx).fg2,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: LuoboCapsuleButton(
                label: AppLocalizations.of(ctx)!.cancel,
                onPressed: () => Navigator.of(ctx).pop(false),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: LuoboCapsuleButton(
                label: confirmLabel,
                style: LuoboCapsuleStyle.primary,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

/// Sheet 内容外壳（也可直接用于自定义浮层）。
class LuoboSheetShell extends StatelessWidget {
  const LuoboSheetShell({
    super.key,
    required this.child,
    this.title,
    this.showHandle = true,
    this.padding,
  });

  final Widget child;

  /// 居中标题（可选）。传了才渲染。
  final String? title;

  final bool showHandle;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: LuoboRadius.sheetTop,
      ),
      padding: padding ?? const EdgeInsets.fromLTRB(14, 14, 14, 20),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHandle)
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(LuoboRadius.handle),
                  ),
                ),
              ),
            if (showHandle) const SizedBox(height: 12),
            if (title != null) ...[
              Center(
                child: Text(
                  title!,
                  style: LuoboType.navTitle.copyWith(
                    fontSize: 15,
                    color: c.fg,
                  ),
                ),
              ),
              const SizedBox(height: 13),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

/// Sheet 内的一行（独立白卡）。
///
/// 用于：单选面板的每个选项、胶囊叠面板的每个动作、`⋮` 面板的次操作行。
///
/// [contentPadding] / [gap] 可调：歌曲 `⋮` 竖列行按方案 §9 的量值
/// （行高 52 = 文字 20 + 上下 16；卡间 gap 12）传入，默认值保持
/// 设置页既有规格（~46 / gap 8）不变，避免影响已落地页面。
class LuoboSheetRow extends StatelessWidget {
  const LuoboSheetRow({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.onTap,
    this.danger = false,
    this.selected = false,
    this.showChevron = true,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: 14,
      vertical: 12,
    ),
    this.gap = 8,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final VoidCallback? onTap;
  final bool danger;

  /// 单选面板：选中打勾。
  final bool selected;

  final bool showChevron;

  final EdgeInsetsGeometry contentPadding;

  /// 行与下一行之间的间距。
  final double gap;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final fg = danger ? LuoboAccent.accent : c.fg;

    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(LuoboRadius.sheetRow),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(LuoboRadius.sheetRow),
          child: Padding(
            padding: contentPadding,
            child: Row(
              children: [
                if (leading != null) ...[leading!, const SizedBox(width: 10)],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: LuoboType.body.copyWith(color: fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: LuoboType.caption.copyWith(color: c.fg2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 8), trailing!],
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(
                      AppIcons.check,
                      size: 16,
                      color: LuoboAccent.accent,
                    ),
                  )
                else if (showChevron && onTap != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      AppIcons.forward,
                      size: 15,
                      color: c.fg3,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
