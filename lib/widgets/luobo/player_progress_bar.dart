import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/player_provider.dart';

/// 播放进度条（播放页与歌词页共用，2026-10-23 抽出）。
///
/// 行为要点（来自播放页原实现，歌词页原 Slider 已同步替换）：
/// - 拖动只更新本地显示，**松手才 seek**；
/// - seek 后进入「等待落点」态（最多 2.5s），避免条子回跳；
/// - 点击轨道也只在抬手时 seek。
///
/// [centerInfo] 放在时间行中间（音质/转码信息，fnos 同款）。

class LuoboProgressBar extends StatefulWidget {
  final double progress;
  final Duration position;
  final Duration duration;
  final String Function(Duration) formatDuration;

  /// 时间行中间的信息（音质/转码），与两个时间同一行、**贴着进度条**。
  final Widget? centerInfo;

  const LuoboProgressBar({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
    required this.formatDuration,
    this.centerInfo,
  });

  @override
  State<LuoboProgressBar> createState() => _LuoboProgressBarState();
}

class _LuoboProgressBarState extends State<LuoboProgressBar> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  /// 松手 / 点按后等待播放器落到目标位置期间的显示值（绝对时间）。
  ///
  /// 用「目标 Duration + 绝对容差」而非「progress 百分比 5%」：后者在 10 分钟
  /// 曲目上等于 30s，既可能过早消失（条子一跳），也可能因落点差超 5% 永不消失
  /// （条子冻在拖拽位置）。见 `docs/道理鱼接入技术方案.md` §13.6。
  Duration? _pendingSeekTarget;
  Timer? _pendingSeekTimeout;

  /// 落点判定容差：覆盖 native seek 的 400ms 校验窗口与少量时长偏差。
  static const Duration _settleTolerance = Duration(milliseconds: 1500);

  /// 超时兜底：seek 未生效 / 重建流久未回位时回到实时位置，绝不永久冻结。
  static const Duration _settleTimeout = Duration(milliseconds: 2500);

  @override
  void dispose() {
    _pendingSeekTimeout?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(LuoboProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.duration != widget.duration) {
      // 换曲 / 时长变化：拖动与待定位置都作废。
      _isDragging = false;
      _dragValue = 0.0;
      _clearPendingSeek();
      return;
    }

    final target = _pendingSeekTarget;
    if (target != null &&
        (widget.position - target).abs() <= _settleTolerance) {
      _clearPendingSeek();
    }
  }

  void _clearPendingSeek() {
    _pendingSeekTimeout?.cancel();
    _pendingSeekTimeout = null;
    _pendingSeekTarget = null;
  }

  /// 进入「等待落点」态；超时未回位就回到实时位置。
  void _startPendingSeek(Duration target) {
    _pendingSeekTimeout?.cancel();
    _pendingSeekTimeout = Timer(_settleTimeout, () {
      if (!mounted || _pendingSeekTarget == null) return;
      setState(_clearPendingSeek);
    });
    setState(() => _pendingSeekTarget = target);
  }

  void _updateProgressFromPosition(Offset localPosition, double width) {
    final newProgress = (localPosition.dx / width).clamp(0.0, 1.0);
    setState(() => _dragValue = newProgress);
  }

  @override
  Widget build(BuildContext context) {
    final Duration displayPosition;
    final double displayProgress;
    if (_isDragging) {
      displayProgress = _dragValue;
      displayPosition = Duration(
        milliseconds: (_dragValue * widget.duration.inMilliseconds).round(),
      );
    } else if (_pendingSeekTarget != null) {
      displayPosition = _pendingSeekTarget!;
      final totalMs = widget.duration.inMilliseconds;
      displayProgress =
          totalMs > 0 ? displayPosition.inMilliseconds / totalMs : 0.0;
    } else {
      displayPosition = widget.position;
      displayProgress = widget.progress;
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackWidth = constraints.maxWidth;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: (details) {
                  // 新拖动接管：上一次的待定落点作废。
                  _pendingSeekTimeout?.cancel();
                  _pendingSeekTimeout = null;
                  setState(() {
                    _isDragging = true;
                    _pendingSeekTarget = null;
                    _dragValue = widget.progress;
                  });
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragUpdate: (details) {
                  _updateProgressFromPosition(
                    details.localPosition,
                    trackWidth,
                  );
                },
                onHorizontalDragEnd: (details) {
                  if (widget.duration.inMilliseconds <= 0) {
                    setState(() => _isDragging = false);
                    return;
                  }
                  final target = Duration(
                    milliseconds:
                        (_dragValue * widget.duration.inMilliseconds).round(),
                  );
                  context.read<PlayerProvider>().seekToProgress(_dragValue);
                  _isDragging = false;
                  _startPendingSeek(target);
                },
                onHorizontalDragCancel: () {
                  // 手势被系统取消：不提交 seek，回到实时位置。
                  if (!_isDragging) return;
                  setState(() {
                    _isDragging = false;
                    _dragValue = 0.0;
                  });
                },
                onTapUp: (details) {
                  // 只在抬手时 seek：原 onTapDown 会在「按住稍久再拖动」时先
                  // seek 一次、松手再 seek 一次（道理鱼转码每次都是一条新流）。
                  if (widget.duration.inMilliseconds <= 0) return;
                  final newProgress =
                      (details.localPosition.dx / trackWidth).clamp(0.0, 1.0);
                  final target = Duration(
                    milliseconds:
                        (newProgress * widget.duration.inMilliseconds).round(),
                  );
                  _dragValue = newProgress;
                  context.read<PlayerProvider>().seekToProgress(newProgress);
                  _startPendingSeek(target);
                },
                child: SizedBox(
                  // fnos 实测：进度条与时间行间距 ≈9dp；原来 44dp 的命中盒让
                  // 时间/音质行看起来离条很远，收到 24dp（仍够拖拽）。
                  height: 24,
                  child: Center(
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Background track
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          height: _isDragging ? 5.0 : 3.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(
                              _isDragging ? 2.5 : 1.5,
                            ),
                          ),
                        ),
                        // Active track
                        FractionallySizedBox(
                          widthFactor: displayProgress.clamp(0.0, 1.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            height: _isDragging ? 5.0 : 3.0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                _isDragging ? 2.5 : 1.5,
                              ),
                              boxShadow: _isDragging
                                  ? [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                        // Thumb
                        Positioned(
                          left:
                              ((trackWidth * displayProgress.clamp(0.0, 1.0)) -
                                      (_isDragging ? 14 : 0))
                                  .clamp(
                            0.0,
                            trackWidth - (_isDragging ? 28 : 0),
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            curve: Curves.easeOut,
                            width: _isDragging ? 28 : 0,
                            height: _isDragging ? 28 : 0,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: _isDragging
                                  ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.25,
                                        ),
                                        blurRadius: 12,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // 向上提 7dp：Transform 不影响布局，只把时间/音质行视觉上拉近轨道
        // （拖拽命中盒仍保持 24dp，手感不变）。
        Transform.translate(
          offset: const Offset(0, -7),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.formatDuration(displayPosition),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
                Expanded(
                  child: Center(
                    child: widget.centerInfo ?? const SizedBox.shrink(),
                  ),
                ),
                Text(
                  widget.duration > Duration.zero
                      ? '-${widget.formatDuration(widget.duration - displayPosition)}'
                      : '',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
