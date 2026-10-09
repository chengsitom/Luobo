import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';

/// 空态 —— 所有列表页共用。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ⑧ 节。
/// 取自 fnos「歌单详情-空态」：**灰色插画 + 一句口语化文案**。
///
/// ⚠️ **不要**用「大图标 + 长说明文字」（那太重）。文案可以口语化，甚至带「~」。
///
/// 现状对比：`favorites_screen.dart` 等用的是 `Icon(size: 64, color: grey)` +
/// 正式文案 —— 统一走本组件。
class LuoboEmptyState extends StatelessWidget {
  const LuoboEmptyState({
    super.key,
    required this.message,
    this.icon = AppIcons.emptyDoc,
    this.action,
  });

  /// 口语化文案，如「空空如也~」「还没有收藏的歌」。
  final String message;

  final IconData icon;

  /// 可选的操作按钮（如「扫描音乐」）。
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 74,
              color: c.fg3.withValues(alpha: c.isDark ? 0.5 : 0.75),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: LuoboType.caption.copyWith(
                fontSize: 11.5,
                color: c.fg2,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
