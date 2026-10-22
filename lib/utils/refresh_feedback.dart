import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';

/// 执行刷新并按结果弹提示（成功数字 / 本地重载 / 失败）。
///
/// 已在同步中的合并请求（[RefreshResult.merged]）静默，避免重复弹窗；
/// 按钮自身的 loading 态由 [LibraryProvider.refreshStatus] 驱动。
/// 提示用原生 SnackBar（floating）经 margin 垂直居中到屏幕中部。
Future<void> refreshLibraryWithFeedback(
  BuildContext context,
  LibraryProvider libraryProvider,
) async {
  final result = await libraryProvider.refresh();
  if (!context.mounted || result.merged) return;
  final l10n = AppLocalizations.of(context)!;
  final message = result.success
      ? (result.isLocal
            ? l10n.refreshLocalComplete
            : l10n.refreshComplete(result.albumCount, result.songCount))
      : l10n.refreshFailed;
  showCenteredToast(context, message);
}

/// 轻提示（showLuoboToast）：玻璃卡 + 单例替换 + 锚定播放条上方。
/// 原为原生 SnackBar（floating）经 margin 垂直居中到屏幕中部，
/// 已随「统一轻提示」批次替换。
void showCenteredToast(BuildContext context, String message) {
  showLuoboToast(
    context,
    message: message,
    tone: LuoboToastTone.info,
  );
}
