import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../models/audiobook.dart';
import '../providers/player_provider.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/duration_format.dart';
import 'luobo/sleep_timer_sheet.dart';
import 'luobo/sheet_shell.dart';

/// 有声书吸底播放条（章节页 + 书库页共用）。
///
/// 2026-10-27：从 `audiobook_detail_screen.dart` 抽出 —— 只要有声书在播放，
/// 进入任何有声书页面（书库/章节）底部都要有它（用户要求）。
///
/// 两行布局：
/// ```
/// 第 3 章 · 省省吧…   ⏪15  ▶  ⏩15   1.0×   ⏱
/// ▬▬▬▬▬●░░░░░░░░░░   05:20 / 26:05
/// ```
/// 第二行进度条**可点按/拖动 seek**；三颗控制按钮带轻触震动。
class AudiobookDock extends StatelessWidget {
  final PlayerProvider player;
  final Audiobook book;

  /// 点击左侧书名/章节信息（章节页：滚到播放章；书库页：进入章节页）。
  final VoidCallback? onTitleTap;

  const AudiobookDock({
    super.key,
    required this.player,
    required this.book,
    this.onTitleTap,
  });

  /// dock 总高（不含安全区）：8 + 40 + 6 + 20 + 8。
  static const double contentHeight = 82;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final isDark = c.isDark;
    final chapterTitle = player.currentSong?.title ?? '';
    final order = player.audiobookChapterOrder;
    final duration = player.chapterDuration;
    final position = player.chapterPosition;

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 14,
        top: 8,
        bottom: MediaQuery.paddingOf(context).bottom + 8,
      ),
      decoration: BoxDecoration(
        color: c.card,
        border: Border(top: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTitleTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chapterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.body.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: c.fg,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order != null
                            ? l10n.chapterOfTotal(order, book.episodeCount)
                            : l10n.chapterCount(book.episodeCount),
                        style: LuoboType.caption.copyWith(
                          fontSize: 10,
                          color: c.fg2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _SkipButton(
                seconds: 15,
                forward: false,
                onTap: () => _seekRelative(player, -15),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  player.togglePlayPause();
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white : Colors.black,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    player.isPlaying ? AppIcons.pause : AppIcons.play,
                    size: 15,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _SkipButton(
                seconds: 15,
                forward: true,
                onTap: () => _seekRelative(player, 15),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _showSpeedSheet(context, player, l10n),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    border: Border.all(color: c.fg2, width: 0.8),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '${player.playbackSpeed}x',
                    style: LuoboType.caption.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: c.fg,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => showSleepTimerSheet(context, player),
                padding: const EdgeInsets.only(left: 6),
                constraints:
                    const BoxConstraints(minWidth: 30, minHeight: 30),
                icon: Icon(
                  CupertinoIcons.moon_zzz,
                  size: 17,
                  color: player.hasSleepTimer ? LuoboAccent.accent : c.fg2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _SeekableProgressBar(
            position: position,
            duration: duration,
            onSeek: (d) => player.seek(d),
            timeStyle: LuoboType.caption.copyWith(
              fontSize: 10,
              color: c.fg2,
            ),
          ),
        ],
      ),
    );
  }

  void _seekRelative(PlayerProvider player, int seconds) {
    final target = player.chapterPosition + Duration(seconds: seconds);
    player.seek(target < Duration.zero ? Duration.zero : target);
  }

  Future<void> _showSpeedSheet(
    BuildContext context,
    PlayerProvider player,
    AppLocalizations l10n,
  ) async {
    const speeds = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0];
    final selected = await showLuoboPickerSheet<double>(
      context: context,
      title: l10n.playbackSpeed,
      // 8 个档位默认会被 9/16 屏高截断 → 放开高度，全部可见（用户 2026-10-27）。
      isScrollControlled: true,
      options: [
        for (final s in speeds) (value: s, label: '${s}x'),
      ],
      selected: player.playbackSpeed,
    );
    if (selected != null) await player.setPlaybackSpeed(selected);
  }
}

/// ±15 秒按钮（图标 + 数字），点击带轻触震动。
class _SkipButton extends StatelessWidget {
  final int seconds;
  final bool forward;
  final VoidCallback onTap;

  const _SkipButton({
    required this.seconds,
    required this.forward,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: SizedBox(
        width: 32,
        height: 40,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              forward
                  ? CupertinoIcons.arrow_clockwise
                  : CupertinoIcons.arrow_counterclockwise,
              size: 16,
              color: c.fg,
            ),
            const SizedBox(height: 1),
            Text(
              '$seconds',
              style: LuoboType.caption.copyWith(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: c.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 可拖动的章节进度条：点按定位、横向拖动 seek。
///
/// 拖动中用本地 `_dragRatio` 显示（时间文字同步跟手），**松手才真正 seek**。
/// 末端带滑钮（非拖动 8dp / 拖动 12dp），让「可拖动」这件事一眼可见。
class _SeekableProgressBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final ValueChanged<Duration> onSeek;
  final TextStyle timeStyle;

  const _SeekableProgressBar({
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.timeStyle,
  });

  @override
  State<_SeekableProgressBar> createState() => _SeekableProgressBarState();
}

class _SeekableProgressBarState extends State<_SeekableProgressBar> {
  double? _dragRatio;

  /// 松手 / 点按后等待播放器落到目标位置期间的显示值（章节内绝对时间）。
  ///
  /// 为什么需要：松手即 `_dragRatio = null` 会让条子立刻回读 `widget.position`
  /// （= `player.chapterPosition`）。转码流走「重起流」，`_position` 在 seek 调用里
  /// 被同步写成目标值，条子当帧就对；但**非转码走 native seek**，目标位置要等
  /// `_audioPlayer.seek()` 绕一圈经位置流回来才生效——这中间 `chapterPosition`
  /// 还是旧值，条子就「没动」（音频已快进）。这里按目标值把条子**钉住**直到真实
  /// 位置落点，与播放页 `LuoboProgressBar` 的 `_pendingSeekTarget` 同构。
  Duration? _pendingTarget;
  Timer? _pendingTimeout;

  /// 落点判定容差：覆盖 native seek 校验窗口与少量偏差。
  static const Duration _settleTolerance = Duration(milliseconds: 1500);

  /// 超时兜底：seek 未落点也绝不永久冻结，回到真实位置。
  static const Duration _settleTimeout = Duration(milliseconds: 2500);

  @override
  void didUpdateWidget(_SeekableProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      // 换章：拖动与待定落点都作废。
      _dragRatio = null;
      _clearPending();
      return;
    }
    final target = _pendingTarget;
    if (target != null &&
        (widget.position - target).abs() <= _settleTolerance) {
      _clearPending();
    }
  }

  @override
  void dispose() {
    _pendingTimeout?.cancel();
    super.dispose();
  }

  void _clearPending() {
    _pendingTimeout?.cancel();
    _pendingTimeout = null;
    _pendingTarget = null;
  }

  void _startPending(Duration target) {
    _pendingTimeout?.cancel();
    _pendingTimeout = Timer(_settleTimeout, () {
      if (!mounted || _pendingTarget == null) return;
      setState(_clearPending);
    });
    _pendingTarget = target;
  }

  double get _ratio {
    if (_dragRatio != null) return _dragRatio!;
    if (widget.duration.inMilliseconds <= 0) return 0;
    final pos = _pendingTarget ?? widget.position;
    return (pos.inMilliseconds / widget.duration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Duration get _shownPosition {
    if (_dragRatio != null) {
      return Duration(
        milliseconds: (widget.duration.inMilliseconds * _dragRatio!).round(),
      );
    }
    return _pendingTarget ?? widget.position;
  }

  void _updateDrag(double dx, double width) {
    if (width <= 0) return;
    setState(() => _dragRatio = (dx / width).clamp(0.0, 1.0));
  }

  void _commit() {
    final ratio = _dragRatio;
    if (ratio == null) return;
    HapticFeedback.selectionClick();
    final target = Duration(
      milliseconds: (widget.duration.inMilliseconds * ratio).round(),
    );
    widget.onSeek(target);
    setState(() {
      _dragRatio = null;
      _startPending(target);
    });
  }

  void _seekTap(double dx, double width) {
    if (width <= 0 || widget.duration.inMilliseconds <= 0) return;
    final ratio = (dx / width).clamp(0.0, 1.0);
    final target = Duration(
      milliseconds: (widget.duration.inMilliseconds * ratio).round(),
    );
    widget.onSeek(target);
    setState(() => _startPending(target));
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final timeText = widget.duration.inMilliseconds > 0
        ? '${formatDurationMs(_shownPosition.inMilliseconds)} / '
            '${formatDurationMs(widget.duration.inMilliseconds)}'
        : '';
    final dragging = _dragRatio != null;

    return Row(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final thumbSize = dragging ? 12.0 : 8.0;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (d) => _seekTap(d.localPosition.dx, width),
                onHorizontalDragStart: (d) {
                  _clearPending(); // 新拖动接管：上次待定落点作废。
                  _updateDrag(d.localPosition.dx, width);
                },
                onHorizontalDragUpdate: (d) =>
                    _updateDrag(d.localPosition.dx, width),
                onHorizontalDragEnd: (_) => _commit(),
                onHorizontalDragCancel: () {
                  if (mounted) setState(() => _dragRatio = null);
                },
                child: SizedBox(
                  // 3dp 细条太难点，命中区扩到 20dp。
                  height: 20,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      // ⚠️ 轨道必须**先占满整行**，红色再按比例覆盖。
                      // 之前把「灰+红」放进一个由 FractionallySizedBox 决定宽度的
                      // Stack 里，整个组件宽度只剩 ratio 那一截，灰色轨道不存在
                      // （用户 2026-10-27：每本书都看不到未播放部分）。
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 7.5,
                        bottom: 7.5,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2.5),
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: ColoredBox(color: c.fg3),
                              ),
                              FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: _ratio,
                                child: ColoredBox(
                                  color: LuoboAccent.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: (width * _ratio - thumbSize / 2)
                            .clamp(0.0, (width - thumbSize).clamp(0.0, width)),
                        top: (20 - thumbSize) / 2,
                        child: Container(
                          width: thumbSize,
                          height: thumbSize,
                          decoration: BoxDecoration(
                            color: LuoboAccent.accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: c.card,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        Text(timeText, style: widget.timeStyle),
      ],
    );
  }
}
