import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'glass.dart';

/// 轻提示锚点：`mini_player.dart` 把播放条的外层 [RepaintBoundary]
/// 挂到这个 key 上，[showLuoboToast] 据此把提示条**锚定在播放条上方 8dp**
/// （与 `_showTranscodeToast` 的锚定思路一致，设计稿/08 §6）。
/// key 定义在这里而非 mini_player，方向是「播放条 → 组件」，避免反向依赖
/// 造成 mini_player 被 luobo 组件层反引。
final GlobalKey luoboToastAnchorKey = GlobalKey();

/// 当前轻提示的 overlay 单例：重触发时**替换而非叠加**（同转码卡
/// `_transcodeToastEntry` 的模式）。
OverlayEntry? _toastEntry;

/// 轻提示 —— 统一反馈组件（设计稿/08 §6，2026-10-21 已拍板）：
///
/// - 玻璃卡 r20（与转码卡同一材质，`LuoboGlassSurface`）
/// - 三态：成功=玫红✓ / 错误=橙`warn` / 信息=灰 i
/// - 可选「撤销」动作（**仅可逆操作**：加歌单/收藏类；错误、信息态不传）
/// - **锚定播放条上方 8dp 居中**（无播放条时回落屏幕中下部）
/// - 淡入 180ms + 停留 2s + 淡出；点卡片可提前关
/// - 挂在 **root overlay**（同转码卡），**不依赖 Scaffold 存在** —— 与
///   `ScaffoldMessenger` 的 SnackBar 不同（本组件是它的替代品）
///
/// ⚠️ 必须包一层透明 `Material`：挂在 root overlay 上时祖先里没有
/// `Material`，不包的话 `Text` 会落成「无样式文本」（黄字+双下划线）。
void showLuoboToast(
  BuildContext context, {
  required String message,
  LuoboToastTone tone = LuoboToastTone.info,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  _toastEntry?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  final overlayBox = overlay.context.findRenderObject() as RenderBox?;
  final anchorBox =
      luoboToastAnchorKey.currentContext?.findRenderObject() as RenderBox?;
  final anchorTopLeft = (anchorBox != null && overlayBox != null)
      ? anchorBox.localToGlobal(Offset.zero, ancestor: overlayBox)
      : null;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final card = _LuoboToastCard(
        message: message,
        tone: tone,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismiss: () {
          if (_toastEntry == entry) _toastEntry = null;
          if (entry.mounted) entry.remove();
        },
      );

      // 锚点拿不到（还没播放 / 播放条未布局）时，回落到屏幕中下部。
      if (anchorTopLeft == null || overlayBox == null) {
        return Align(alignment: const Alignment(0, 0.6), child: card);
      }

      const gap = 8.0;
      // 提示条**底边**贴播放条**顶边**再往上留 gap（设计稿/08 §6）。
      final bottom = overlayBox.size.height - anchorTopLeft.dy + gap;
      return Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            bottom: bottom,
            child: Center(child: card),
          ),
        ],
      );
    },
  );
  _toastEntry = entry;
  overlay.insert(entry);
}

/// 轻提示三态（设计稿/08 §6）。
enum LuoboToastTone {
  /// 成功：玫红 ✓
  success,

  /// 错误：橙 `LuoboAccent.warn`
  error,

  /// 信息：灰 i
  info,
}

class _LuoboToastCard extends StatefulWidget {
  final String message;
  final LuoboToastTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismiss;

  const _LuoboToastCard({
    required this.message,
    required this.tone,
    this.actionLabel,
    this.onAction,
    required this.onDismiss,
  });

  @override
  State<_LuoboToastCard> createState() => _LuoboToastCardState();
}

class _LuoboToastCardState extends State<_LuoboToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final curved = CurvedAnimation(
      parent: _controller,
      curve: LuoboMotion.enter,
      reverseCurve: LuoboMotion.exit,
    );

    final (icon, color) = switch (widget.tone) {
      LuoboToastTone.success => (Icons.check_rounded, LuoboAccent.accent),
      LuoboToastTone.error => (Icons.error_outline_rounded, LuoboAccent.warn(context)),
      LuoboToastTone.info => (Icons.info_outline_rounded, c.fg2),
    };

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(curved),
        child: GestureDetector(
          onTap: () {
            _controller.reverse().whenComplete(() {
              if (mounted) _dismiss();
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Material(
              type: MaterialType.transparency,
              child: LuoboGlassSurface(
                // 与转码卡同材质（圆角 20）；14/20 的差异以转码卡为准，
                // 保证 Type 家族统一（设计稿/08 的 14 是稿面值）。
                borderRadius: LuoboRadius.groupR,
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 16, color: color),
                    const SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        widget.message,
                        style: LuoboType.caption.copyWith(height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.actionLabel != null) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onAction,
                        child: Text(
                          widget.actionLabel!,
                          style: LuoboType.caption.copyWith(
                            color: LuoboAccent.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}