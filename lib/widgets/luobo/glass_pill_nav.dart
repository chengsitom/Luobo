import 'package:flutter/material.dart';

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
///
/// 布局：`[项][项][项][分隔线][专辑封面槽]`，**每一项都是 `flex: 1`**，
/// 因此三项严格等宽等距，专辑封面占一个等宽槽位（不是贴右边缘的小图标）。
///
/// - 选中态：玫红实心圆（[LuoboGlass.navBubbleSize]）+ 白色图标
/// - 未选中：42% 黑 / 白描边图标
/// - 最右：当前专辑圆封面（点击进播放页）；无播放时传 `art: null` 即不渲染该槽
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

  /// 当前专辑圆封面。为 null 时**不渲染**封面槽（分隔线也一并隐藏）。
  final Widget? art;
  final VoidCallback? onArtTap;

  final bool strongBorder;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final unselected = c.fg.withValues(alpha: 0.42);

    return LuoboGlassSurface(
      borderRadius: LuoboRadius.pillR,
      strongBorder: strongBorder,
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
                    child: SizedBox(
                      width: LuoboGlass.navArtSize,
                      height: LuoboGlass.navArtSize,
                      child: ClipOval(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LuoboAccent.onAccent.withValues(
                                alpha: 0.55,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: art,
                        ),
                      ),
                    ),
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

class _NavSlot extends StatelessWidget {
  const _NavSlot({
    required this.item,
    required this.selected,
    required this.unselectedColor,
    required this.onTap,
  });

  final GlassPillNavItem item;
  final bool selected;
  final Color unselectedColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (selected)
                Container(
                  width: LuoboGlass.navBubbleSize,
                  height: LuoboGlass.navBubbleSize,
                  decoration: const BoxDecoration(
                    color: LuoboAccent.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              Icon(
                item.icon,
                size: 20,
                color: selected ? LuoboAccent.onAccent : unselectedColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
