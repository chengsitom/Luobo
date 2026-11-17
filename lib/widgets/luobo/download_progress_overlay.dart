import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../services/offline_service.dart';
import 'luobo_toast.dart';

/// 全局下载进度监听 —— 常驻在所有页面之上（挂在 MaterialApp.builder）。
///
/// 只监听 [OfflineService.downloadState]，把状态翻译成进度卡；自己不重建
/// 任何页面树（listener 只操作 overlay，不 setState）。
///
/// 用 StatefulWidget 只为持有 listener 的生命周期（initState 注册 / dispose
/// 注销）；build 只返回 child，状态变化不会引起本 widget 重建。
class DownloadProgressOverlay extends StatefulWidget {
  final Widget child;

  const DownloadProgressOverlay({super.key, required this.child});

  @override
  State<DownloadProgressOverlay> createState() =>
      _DownloadProgressOverlayState();
}

class _DownloadProgressOverlayState extends State<DownloadProgressOverlay> {
  @override
  void initState() {
    super.initState();
    final service = OfflineService();
    service.downloadState.addListener(_onStateChanged);
    // 首帧同步一次（若冷启时正好有残留状态）。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncCard(service.downloadState.value);
    });
  }

  @override
  void dispose() {
    OfflineService().downloadState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() => _syncCard(OfflineService().downloadState.value);

  @override
  Widget build(BuildContext context) => widget.child;

  void _syncCard(DownloadState state) {
    if (!mounted) return;
    final context = this.context;
    final l10n = AppLocalizations.of(context);
    if (state.isDownloading && state.totalCount > 0) {
      final percent = (state.currentProgress / state.totalCount * 100).round();
      final failedSuffix = state.failedCount > 0
          ? ' · ${l10n != null ? l10n.downloadFailed : 'failed'} ${state.failedCount}'
          : '';
      showLuoboProgressCard(
        context,
        message: '${l10n != null ? l10n.downloading(percent) : 'Downloading $percent%'}'
            '$failedSuffix',
        progress: state.currentProgress / state.totalCount,
      );
      return;
    }

    // 下载刚结束：上一帧还在下载 → 弹终态卡；否则什么都不做（避免冷启时
    // 因为默认 DownloadState() 而弹一个"下载 0 首"）。
    if (!state.isDownloading && state.totalCount > 0) {
      final succeeded = state.successCount;
      final hasFailed = state.failedCount > 0;
      final message = hasFailed
          ? '${l10n != null ? l10n.downloadFailed : 'Download failed'} · '
              '${l10n != null ? l10n.downloadedSongsFrom(succeeded, '') : '$succeeded songs'}'
          : (l10n != null
              ? l10n.downloadedSongsFrom(succeeded, '')
              : 'Downloaded $succeeded songs');
      finishLuoboProgressCard(
        context,
        message: message,
        tone: hasFailed ? LuoboToastTone.error : LuoboToastTone.success,
      );
      // 下一帧再清 totalCount，避免在 notify listener 期间同步修改
      // 同一个 notifier（会触发重入）。清零后不会重复进终态分支。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) OfflineService().resetDownloadState();
      });
    }
  }
}
