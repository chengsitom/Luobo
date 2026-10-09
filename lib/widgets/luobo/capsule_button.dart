import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// 胶囊按钮 —— **独立在卡外**，圆角 30，高 44。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ⑥ 节。
///
/// | 样式 | 底色 | 用途 |
/// |---|---|---|
/// | [LuoboCapsuleStyle.normal] | 灰 `#E5E5E7` / 深 `#2C2C2E` | 退出登录、取消 |
/// | [LuoboCapsuleStyle.primary] | 玫红实心 | 更新、添加、确认 |
/// | [LuoboCapsuleStyle.danger] | 玫红淡底 + 玫红字 | 移除连接、删除 |
class LuoboCapsuleButton extends StatelessWidget {
  const LuoboCapsuleButton({
    super.key,
    required this.label,
    this.onPressed,
    this.style = LuoboCapsuleStyle.normal,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final LuoboCapsuleStyle style;

  /// 是否撑满宽度（默认 true）。
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final enabled = onPressed != null;

    final Color bg;
    final Color fg;
    switch (style) {
      case LuoboCapsuleStyle.normal:
        bg = c.pillFill;
        fg = c.fg;
      case LuoboCapsuleStyle.primary:
        bg = LuoboAccent.accent;
        fg = LuoboAccent.onAccent;
      case LuoboCapsuleStyle.danger:
        bg = LuoboAccent.soft(0.12);
        fg = LuoboAccent.accent;
    }

    final button = Material(
      color: enabled ? bg : bg.withValues(alpha: 0.5),
      borderRadius: LuoboRadius.pillR,
      child: InkWell(
        onTap: onPressed,
        borderRadius: LuoboRadius.pillR,
        child: SizedBox(
          height: 44,
          child: Center(
            child: Text(
              label,
              style: LuoboType.button.copyWith(
                color: enabled ? fg : fg.withValues(alpha: 0.5),
              ),
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

enum LuoboCapsuleStyle { normal, primary, danger }
