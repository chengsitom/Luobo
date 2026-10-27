import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';

/// 悬浮圆钮（40dp；fnos v6_0060 实测：直径 ≈39dp、距左右边缘 16dp、
/// 浅色填充 ≈#FBFCFB（白 0.72 叠底色）、图标近黑；深色黑 0.45 + 白图标）。
class LuoboTopCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const LuoboTopCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          // 2026-10-23：浅色页底已统一 #F3F3F3 → 白 .72 圆自带对比，
          // 去掉描边（fnos：白圆无边框）；深色保留白 .12 高光边。
          border: isDark
              ? Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 0.8,
                )
              : null,
        ),
        child: Icon(
          icon,
          size: 17,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
    );
  }
}

/// 头图式详情页的头部（fnos v6_0060 / v5_0032 实测版式，收藏页与歌单详情共用）：
/// **inset 卡片**（左右 41dp、高 230、r16）→ 卡下居中标题 25/700 + 副题 →
/// 双胶囊（116×48、间距 12、居中、**主题取反**：浅色黑/深色白）→
/// 「共 N 首」行（右：排序 + 多选）。整块随滚动上移，顶栏圆钮在外层常驻。
class LuoboHeroCardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget card;
  final String countLabel;
  final VoidCallback? onPlay;
  final VoidCallback? onShuffle;
  final VoidCallback? onSort;
  final VoidCallback? onMultiSelect;

  /// 排序图标的锚点（锚定菜单用）。
  final GlobalKey? sortAnchorKey;

  const LuoboHeroCardHeader({
    super.key,
    required this.title,
    required this.subtitle,
    required this.card,
    required this.countLabel,
    this.onPlay,
    this.onShuffle,
    this.onSort,
    this.onMultiSelect,
    this.sortAnchorKey,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 52),
      child: Column(
        children: [
          // 封面卡（inset 41dp、高 230、r16）。
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 41),
            child: SizedBox(
              height: 230,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: card,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: LuoboType.navTitle.copyWith(fontSize: 25, color: c.fg),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: LuoboType.caption.copyWith(color: c.fg2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPlay != null)
                SizedBox(
                  width: 116,
                  child: LuoboHeroCapsule(
                    icon: AppIcons.play,
                    label: l10n.play,
                    onTap: onPlay!,
                  ),
                ),
              if (onPlay != null && onShuffle != null)
                const SizedBox(width: 12),
              if (onShuffle != null)
                SizedBox(
                  width: 116,
                  child: LuoboHeroCapsule(
                    icon: AppIcons.shuffle,
                    label: l10n.shuffle,
                    onTap: onShuffle!,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  countLabel,
                  style: LuoboType.caption.copyWith(color: c.fg2),
                ),
                const Spacer(),
                if (onSort != null)
                  GestureDetector(
                    key: sortAnchorKey,
                    onTap: onSort,
                    child: Icon(Icons.sort_rounded, size: 22, color: c.fg2),
                  ),
                if (onSort != null && onMultiSelect != null)
                  const SizedBox(width: 18),
                if (onMultiSelect != null)
                  GestureDetector(
                    onTap: onMultiSelect,
                    child: Icon(
                      Icons.checklist_rounded,
                      size: 22,
                      color: c.fg2,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

/// 头部胶囊（116×48；**主题取反**：浅色=黑底白字 / 深色=白底黑字）。
class LuoboHeroCapsule extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const LuoboHeroCapsule({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 8),
              Text(
                label,
                style: LuoboType.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}