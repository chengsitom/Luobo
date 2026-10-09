import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';
import 'glass.dart';

/// 锚定毛玻璃菜单的一项。
class LuoboAnchoredMenuItem<T> {
  const LuoboAnchoredMenuItem({
    required this.value,
    required this.label,
    this.trailing,
  });

  final T value;
  final String label;

  /// 右侧附加组件 —— **只在选中项上渲染**（排序场景：升/降方向箭头）。
  final Widget? trailing;
}

/// 锚定毛玻璃菜单 —— 贴在 [anchorKey] 所指元素**旁边**浮出的单个半透明面板。
///
/// 设计稿：`docs/视觉与交互对标飞牛音乐技术方案.md` §2.3 浮层范式①；
/// 实测规格见 `docs/锚定浮层与列表页排序技术方案.md` §2。
///
/// ⚠️ **与「单选 Sheet」的区别**（别混用）：
/// | | 锚定菜单（本组件） | 单选 Sheet（`showLuoboPickerSheet`） |
/// |---|---|---|
/// | 位置 | 贴**触发元素**旁边 | **底部升起** |
/// | 结构 | **一个面板**装所有项 | 每项**一张独立白卡** + 居中标题 |
/// | 动画 | 从锚点**淡入缩放** | 底部滑入 |
/// | 用途 | 列表页排序 / 顶部圆钮 `···` | 设置项选值 |
///
/// 返回用户点中的值；点遮罩 / 返回键取消时返回 null。
Future<T?> showLuoboAnchoredMenu<T>({
  required BuildContext context,
  required GlobalKey anchorKey,
  required List<LuoboAnchoredMenuItem<T>> items,
  T? selected,
  double width = 200,
}) {
  // ⚠️ 用 **root** overlay 算坐标：`showGeneralDialog` 默认落在 root navigator，
  // 而设置页在 `main_screen` 的**嵌套 Navigator** 里（区域比整屏矮，底部被播放条
  // 与底栏占掉）。按嵌套 overlay 算会导致「下方空间不足」误判 + 定位偏移。
  final overlay = Navigator.of(context, rootNavigator: true).overlay;
  final anchorBox = anchorKey.currentContext?.findRenderObject() as RenderBox?;
  // 安全阀：锚点未挂载 / 没有尺寸（页面已被 pop）→ 不弹。
  if (overlay == null || anchorBox == null || !anchorBox.hasSize) {
    return Future<T?>.value();
  }
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  if (overlayBox == null) return Future<T?>.value();

  final screen = overlayBox.size;
  final anchorRect =
      (anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox)) &
          anchorBox.size;

  final panelHeight =
      items.length * LuoboSpacing.menuItemHeight + LuoboSpacing.pageY * 2;
  const gap = 8.0;
  const edge = LuoboSpacing.pageX;

  // 垂直：默认在锚点下方 gap；放不下就**向上翻转**。
  final below = anchorRect.bottom + gap;
  final fitsBelow = below + panelHeight <= screen.height - edge;
  final top = fitsBelow
      ? below
      : (anchorRect.top - gap - panelHeight)
          .clamp(edge, screen.height - panelHeight - edge);

  // 水平：默认**右对齐锚点右缘**（飞牛贴的是右侧图标）；左边不够就左对齐。
  var left = anchorRect.right - width;
  if (left < edge) left = anchorRect.left;
  left =
      left.clamp(edge, (screen.width - width - edge).clamp(edge, screen.width));

  // 缩放的原点指向锚点 —— 面板从锚点方向「长出来」。
  final originX = ((anchorRect.center.dx - left) / width).clamp(0.0, 1.0);
  final originY = fitsBelow ? 0.0 : 1.0;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'menu',
    barrierColor: LuoboMotion.scrim,
    transitionDuration: LuoboMotion.sheet,
    pageBuilder: (ctx, _, __) => Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          width: width,
          child: _AnchoredMenuPanel<T>(items: items, selected: selected),
        ),
      ],
    ),
    transitionBuilder: (ctx, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: LuoboMotion.enter,
        reverseCurve: LuoboMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
          alignment: Alignment(originX * 2 - 1, originY * 2 - 1),
          child: child,
        ),
      );
    },
  );
}

class _AnchoredMenuPanel<T> extends StatelessWidget {
  const _AnchoredMenuPanel({required this.items, required this.selected});

  final List<LuoboAnchoredMenuItem<T>> items;
  final T? selected;

  @override
  Widget build(BuildContext context) {
    // 毛玻璃：小面积固定元素 ✅（性能红线只禁大面积）。
    // ⚠️ 深色下 tint 是黑 .50、本身几乎不可见，可见性来自描边+阴影+模糊 ——
    // 因此面板下面**必须有内容**（列表页有）。纯色深底场景要传 strongBorder。
    return LuoboGlassSurface(
      borderRadius: BorderRadius.circular(LuoboRadius.group),
      // Material 透明层：让行内的 InkWell 水波能画在玻璃之上
      // （`LuoboGlassSurface` 只有 DecoratedBox，没有 Material 祖先）。
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: LuoboSpacing.pageY),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in items)
                _AnchoredMenuRow<T>(
                    item: item, selected: item.value == selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnchoredMenuRow<T> extends StatelessWidget {
  const _AnchoredMenuRow({required this.item, required this.selected});

  final LuoboAnchoredMenuItem<T> item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(item.value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: LuoboSpacing.menuItemHeight,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: LuoboSpacing.rowX),
            child: Row(
              children: [
                // 勾位**永远占宽**：未选中项不画任何东西，但文字仍与选中项对齐。
                SizedBox(
                  width: 20,
                  child: selected
                      ? const Icon(
                          AppIcons.check,
                          size: 16,
                          color: LuoboAccent.accent,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    style: LuoboType.body.copyWith(color: c.fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 方向箭头等附加组件：**只在选中项**上出现。
                if (selected && item.trailing != null) ...[
                  const SizedBox(width: 8),
                  item.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
