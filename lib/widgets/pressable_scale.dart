import 'package:flutter/material.dart';

/// Wraps [child] with a subtle press-down scale feedback (Apple-like).
/// Shrinks slightly while the pointer is down, springs back on release.
///
/// Uses [Listener] (raw pointer events) for the scale feedback so it never
/// competes with the child's own gestures; [onTap] (if given) is handled by
/// an inner [GestureDetector].
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final Duration duration;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.duration = const Duration(milliseconds: 150),
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    Widget content = Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
    final onTap = widget.onTap;
    if (onTap != null || widget.onLongPress != null) {
      content = GestureDetector(
        onTap: onTap,
        onLongPress: widget.onLongPress,
        child: content,
      );
    }
    return content;
  }
}
