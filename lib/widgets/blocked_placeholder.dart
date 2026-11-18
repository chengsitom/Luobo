import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';

/// 被「彻底屏蔽」的对象详情页占位。
///
/// 正常入口（列表、搜索、推荐）都已被过滤，只有"从正在播放的队列点进来"
/// 这类残留路径能到详情页。与其照常展示内容（用户会以为屏蔽没生效），
/// 不如明确告知，并给出**唯一出口**：解除屏蔽。
class BlockedPlaceholder extends StatelessWidget {
  const BlockedPlaceholder({super.key, required this.onUnblock});

  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off_rounded,
              size: 56,
              color: c.fg3,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.contentBlockedTitle,
              textAlign: TextAlign.center,
              style: LuoboType.navTitle.copyWith(color: c.fg),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.blockModeHideDesc,
              textAlign: TextAlign.center,
              style: LuoboType.caption.copyWith(color: c.fg2),
            ),
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: onUnblock,
              icon: const Icon(Icons.undo_rounded, size: 18),
              label: Text(l10n.unblockAction),
            ),
          ],
        ),
      ),
    );
  }
}
