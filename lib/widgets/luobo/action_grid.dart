import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 单个动作项。
class LuoboActionItem {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const LuoboActionItem({
    required this.icon,
    required this.label,
    this.onTap,
  });
}

/// 主操作横排方块（设计稿/09 §变体 A，规格见
/// `docs/歌曲列表弹窗对标飞牛技术方案.md` §9）：
/// 3 等分 · 高 72 · 圆角 14 · 间距 8 · 图标 20 + label 12/500（间距 9）。
///
/// 用于歌曲 `⋮` 菜单的「播放 / 下一首播放 / 加入播放列表」横排。
class LuoboActionGrid extends StatelessWidget {
  const LuoboActionGrid({super.key, required this.items});

  final List<LuoboActionItem> items;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Row(
      children: [
        for (final item in items) ...[
          if (items.indexOf(item) > 0) const SizedBox(width: 8),
          Expanded(
            child: Material(
              color: c.card,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  height: 72,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, size: 20, color: c.fg),
                      const SizedBox(height: 9),
                      Text(
                        item.label,
                        style: LuoboType.caption.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.fg2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}