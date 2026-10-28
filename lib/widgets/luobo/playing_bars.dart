import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 播放中的动态音柱（3 根跳动小条）。
///
/// 用于：书库页当前书的播放钮、章节页当前播放行的状态列 —— 静态 ▶ 无法
/// 告诉用户「正在播的到底是哪一本/哪一章」（用户 2026-10-27）。
class PlayingBars extends StatefulWidget {
  /// 整体边长（宽高相同）。
  final double size;

  final Color color;

  /// 条数。
  final int barCount;

  const PlayingBars({
    super.key,
    this.size = 12,
    required this.color,
    this.barCount = 3,
  });

  @override
  State<PlayingBars> createState() => _PlayingBarsState();
}

class _PlayingBarsState extends State<PlayingBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barWidth = (widget.size * 0.16).clamp(1.5, 4.0);
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.barCount; i++)
                Container(
                  width: barWidth,
                  height: widget.size *
                      (0.35 +
                          0.55 *
                              ((math.sin(
                                        _controller.value * 2 * math.pi +
                                            i * 1.15,
                                      ) +
                                      1) /
                                  2)),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(barWidth),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
