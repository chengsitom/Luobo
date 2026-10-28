import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import 'list_top_bar.dart';

/// 顶栏标题随滚动出现的 Scaffold 壳。
///
/// 用于设置二级页 / 机制说明 / 更新日志这类「页面顶部没有大标题、正文直接是
/// 列表」的页面：
/// - 初始只有返回圆钮，**不带标题**；
/// - 正文上滑超过 [threshold] 后，才切换成「返回 + 标题」40dp 胶囊；
/// - 8dp 回滞，阈值附近来回滚动不闪烁；
/// - 内容不满一屏（`maxScrollExtent == 0`）时没有上滑机会，保留标题，
///   避免短页面完全看不到页名。
///
/// 滚动监听用 `ScrollNotification` / `ScrollMetricsNotification`，不要求调用方
/// 暴露 `ScrollController`；任何垂直 ListView / CustomScrollView 都能用。
class ScrollRevealScaffold extends StatefulWidget {
  const ScrollRevealScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.trailing,
    this.backgroundColor,
    this.threshold = 64,
    this.keepTitleWhenNotScrollable = true,
    this.resizeToAvoidBottomInset = true,
  });

  final String title;
  final Widget body;

  /// 右上角动作钮。会排在 [trailing] 左边。
  final List<Widget>? actions;

  /// 右上角单个动作钮（便捷）。
  final Widget? trailing;

  /// 默认 `LuoboColors.of(context).bg`。
  final Color? backgroundColor;

  /// 上滑超过这个距离后显示标题。
  final double threshold;

  /// 内容不满一屏时是否保留标题（默认 true）。
  final bool keepTitleWhenNotScrollable;

  /// 透传给 [Scaffold.resizeToAvoidBottomInset]（表单页通常传 false）。
  final bool resizeToAvoidBottomInset;

  @override
  State<ScrollRevealScaffold> createState() => _ScrollRevealScaffoldState();
}

class _ScrollRevealScaffoldState extends State<ScrollRevealScaffold> {
  final ValueNotifier<bool> _showTitle = ValueNotifier(false);
  bool _scrollable = false;

  @override
  void initState() {
    super.initState();
    // 短页面 / 加载中 / 空态可能根本没有垂直 Scrollable，也就不会发
    // ScrollMetricsNotification。首帧结束后若仍未发现可滚动内容，保留标题，
    // 避免页面完全看不到页名；等真正出现可滚动列表时再由 _onMetrics 收起。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_scrollable && widget.keepTitleWhenNotScrollable) {
        _showTitle.value = true;
      }
    });
  }

  @override
  void dispose() {
    _showTitle.dispose();
    super.dispose();
  }

  bool _onMetrics(ScrollMetricsNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final scrollable = notification.metrics.maxScrollExtent > 0;
    if (scrollable != _scrollable) {
      _scrollable = scrollable;
      if (!scrollable) {
        if (widget.keepTitleWhenNotScrollable) _showTitle.value = true;
      } else {
        // 从「短页面」变成可滚动：回到顶部时重新隐藏标题。
        _showTitle.value = notification.metrics.pixels > widget.threshold;
      }
    }
    return false;
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    if (notification.metrics.maxScrollExtent <= 0) return false;
    final offset = notification.metrics.pixels;
    // 8dp 回滞：阈值附近来回滚动时不闪烁。
    final show = _showTitle.value
        ? offset > widget.threshold - 8
        : offset > widget.threshold;
    if (show != _showTitle.value) _showTitle.value = show;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Scaffold(
      backgroundColor: widget.backgroundColor ?? c.bg,
      resizeToAvoidBottomInset: widget.resizeToAvoidBottomInset,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ValueListenableBuilder<bool>(
          valueListenable: _showTitle,
          builder: (context, showTitle, _) => LuoboListTopBar(
            title: showTitle ? widget.title : null,
            actions: [
              ...?widget.actions,
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),
      ),
      body: NotificationListener<ScrollMetricsNotification>(
        onNotification: _onMetrics,
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: widget.body,
        ),
      ),
    );
  }
}
