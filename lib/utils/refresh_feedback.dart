import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../providers/auth_provider.dart';
import '../providers/library_provider.dart';
import '../l10n/app_localizations.dart';

/// 执行刷新并按结果弹提示（成功数字 / 本地重载 / 离线缓存 / 失败）。
///
/// **离线模式下「刷新」先尝试重新连接**：用户换到能连服务器的网络后，刷新
/// 的直觉就是"重连"；此前这里只重读本地缓存并弹「0 张专辑 0 首歌曲」，
/// 看起来既没连上、又像本地是空的。
///
/// 已在同步中的合并请求（[RefreshResult.merged]）静默，避免重复弹窗；
/// 按钮自身的 loading 态由 [LibraryProvider.refreshStatus] 驱动。
Future<void> refreshLibraryWithFeedback(
  BuildContext context,
  LibraryProvider libraryProvider,
) async {
  // 离线态：先重连。连上后 MainScreen 会以在线态重建并自行加载曲库，
  // 这里不再重复 refresh（否则和它刚发起的初始化打架）。
  AuthProvider? auth;
  try {
    auth = Provider.of<AuthProvider>(context, listen: false);
  } catch (_) {
    // 测试 harness 可能没有 AuthProvider —— 退化为纯曲库刷新。
  }
  if (auth != null && auth.state == AuthState.offlineMode) {
    // 重连最长要走 3 次 ping + 重试间隔（约 30s），期间必须让用户知道
    // 「这次刷新真的在连服务器」，否则又变成点了没反应。
    final connectingL10n = AppLocalizations.of(context);
    if (connectingL10n != null) {
      showCenteredToast(context, connectingL10n.startupConnecting);
    }
    final connected = await auth.reconnect();
    if (!context.mounted) return;
    if (connected) return;
    final offlineL10n = AppLocalizations.of(context);
    if (offlineL10n == null) return;
    showCenteredToast(context, offlineL10n.reconnectFailed);
    return;
  }

  final result = await libraryProvider.refresh();
  if (!context.mounted || result.merged) return;
  final l10n = AppLocalizations.of(context)!;
  final message = result.success
      ? (result.isLocal
          ? l10n.refreshLocalComplete
          : result.isOffline
              ? l10n.refreshOfflineComplete(result.songCount)
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
