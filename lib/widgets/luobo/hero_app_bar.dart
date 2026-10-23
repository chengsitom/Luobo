import 'package:flutter/material.dart';

/// 折叠大标题页顶栏（**已拍板 §7⑪，2026-10-20**：大标题/内容头随折叠淡出、
/// 顶栏背景**保持透明**、内容从下方流过、悬浮圆钮**常驻**；全局适用）。
///
/// ⚠️ **2026-10-22 依据抓帧图修正**（`fn_frames_all`：收藏页滚动段 v5_0084-0100、
/// 歌单详情 v6_0060-0072）：飞牛详情页滚动后**不会出现实色常驻栏 + 居中标题**——
/// 顶栏区域全程保持透明（深色 ≈40 / 浅色 ≈204，即页面底/玻璃透出），只有悬浮
/// 圆钮常驻。早期实现的「收起后实色底 + 标题淡入」是错误理解，已移除。
///
/// 用法：`CustomScrollView` 的第一个 sliver（`pinned: true`）。
///
/// - [header]：展开态内容（流体头 + 居中标题 + 胶囊等），随滚动上移消失
/// - [leading] / [actions]：悬浮圆钮（**常驻**）
/// - [foregroundColor]：悬浮钮颜色（默认随主题：深色白 / 浅色黑 87）
class LuoboHeroAppBar extends StatelessWidget {
  const LuoboHeroAppBar({
    super.key,
    required this.expandedHeight,
    required this.header,
    this.leading,
    this.actions,
    this.foregroundColor,
  });

  /// 展开态总高（含状态栏）。
  final double expandedHeight;

  /// 展开态内容（随滚动上移裁切）。
  final Widget header;

  /// 悬浮圆钮（左）。
  final Widget? leading;

  /// 悬浮圆钮（右，横向排）。
  final List<Widget>? actions;

  /// 悬浮钮颜色（默认随主题）。
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = foregroundColor ?? (isDark ? Colors.white : Colors.black87);
    final statusBar = MediaQuery.of(context).padding.top;
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeroHeaderDelegate(
        minExtent: statusBar + 56,
        maxExtent: expandedHeight,
        header: header,
        leading: leading,
        actions: actions,
        foregroundColor: fg,
      ),
    );
  }
}

class _HeroHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _HeroHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.header,
    required this.leading,
    required this.actions,
    required this.foregroundColor,
  });

  final double minExtent;
  final double maxExtent;
  final Widget header;
  final Widget? leading;
  final List<Widget>? actions;
  final Color foregroundColor;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 展开内容：随滚动上移（剩余高度由 delegate 布局给出）。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SizedBox(
            height: (maxExtent - shrinkOffset).clamp(0.0, maxExtent),
            child: header,
          ),
        ),
        // 悬浮圆钮（常驻）：左 leading + 右 actions；**无实色栏、无标题**。
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                if (leading != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 14),
                    child: IconTheme(
                      data: IconThemeData(color: foregroundColor),
                      child: leading!,
                    ),
                  ),
                const Spacer(),
                if (actions != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final action in actions!)
                          Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: IconTheme(
                              data: IconThemeData(color: foregroundColor),
                              child: action,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool shouldRebuild(covariant _HeroHeaderDelegate oldDelegate) =>
      oldDelegate.header != header ||
      oldDelegate.leading != leading ||
      oldDelegate.actions != actions ||
      oldDelegate.foregroundColor != foregroundColor ||
      oldDelegate.maxExtent != maxExtent ||
      oldDelegate.minExtent != minExtent;
}
