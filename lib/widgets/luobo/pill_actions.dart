import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'glass.dart';

/// 右上「胶囊双钮」—— 2~3 个动作**合并进一个玻璃胶囊**，中间用细线分隔。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png` ② 节、
/// `03-设置二级页全量.png` A1（扫码 ＋ 新增）。
///
/// 与 [GlassCircleButton] 的关系：**两个以上动作合并时用本组件**（省宽度、
/// 视觉更稳）；单个动作用圆钮。深色纯底场景传 [strongBorder]。
class LuoboPillActions extends StatelessWidget {
  const LuoboPillActions({
    super.key,
    required this.actions,
    this.iconSize = 16,
    this.strongBorder = false,
  });

  final List<LuoboPillAction> actions;
  final double iconSize;
  final bool strongBorder;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return LuoboGlassSurface(
      strongBorder: strongBorder,
      child: SizedBox(
        height: LuoboGlass.circleButtonSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < actions.length; i++) ...[
              if (i > 0) Container(width: 0.5, height: 16, color: c.divider),
              _PillActionButton(action: actions[i], iconSize: iconSize),
            ],
          ],
        ),
      ),
    );
  }
}

/// [LuoboPillActions] 里的一个动作。
class LuoboPillAction {
  const LuoboPillAction({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({required this.action, required this.iconSize});

  final LuoboPillAction action;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final enabled = action.onPressed != null;

    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: action.onPressed,
        child: SizedBox(
          width: 48,
          height: LuoboGlass.circleButtonSize,
          child: Center(
            child: Icon(
              action.icon,
              size: iconSize,
              color: enabled ? c.fg : c.fg.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );

    if (action.tooltip == null) return button;
    return Tooltip(message: action.tooltip!, child: button);
  }
}
