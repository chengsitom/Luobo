import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/local_music_service.dart';

/// 「使用本地音乐文件」的**公共流程**：权限 → 选文件（iOS）/ 扫描目录 →
/// 切到**本地音乐模式**。
///
/// ⚠️ 这段逻辑原先内联在 `screens/server_gateway_screen.dart` 里，而设计稿
/// B3「添加服务器 → 其他方式」也要这一项 —— 抽到这里，两处共用，
/// 避免出现第二份实现。
///
/// **副作用（调用方须知）**：成功后会 `setLocalOnlyMode(true)`，
/// 即**断开当前服务器、改用本地曲库**。因此 B3 那边调用前会先弹确认框。
///
/// - 返回 `true` 表示已切到本地模式（调用方自行决定 pop / 刷新）
/// - 失败或用户没选到文件时返回 `false`，并已就地给出提示
/// - [onProgress] 用于驱动调用方的扫描进度 UI（登录网关页有进度条）
Future<bool> launchLocalLibrary(
  BuildContext context, {
  void Function(double progress, String status)? onProgress,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final localService = Provider.of<LocalMusicService>(context, listen: false);

  final granted = await localService.requestPermission();
  if (!granted) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.storagePermissionRequired),
          backgroundColor: Colors.red,
        ),
      );
    }
    return false;
  }

  // iOS：系统文件选择器（沙盒里拿不到任意目录）。
  if (Platform.isIOS) {
    onProgress?.call(0.0, l10n.selectMusicFiles);
    final added = await localService.pickAndAddFiles();
    if (!context.mounted) return false;
    if (localService.songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            added == 0 ? l10n.noFilesSelected : l10n.noMusicFilesFound,
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    await _switchToLocalOnly(context);
    return true;
  }

  // Android / 桌面：扫目录。
  onProgress?.call(0.0, l10n.startingScan);
  void onScanTick() =>
      onProgress?.call(localService.scanProgress, localService.scanStatus);

  localService.addListener(onScanTick);
  try {
    await localService.scanForMusic();
    if (!context.mounted) return false;
    if (localService.songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.noMusicFilesFound),
          backgroundColor: Colors.orange,
        ),
      );
      return false;
    }
    await _switchToLocalOnly(context);
    return true;
  } finally {
    localService.removeListener(onScanTick);
  }
}

Future<void> _switchToLocalOnly(BuildContext context) async {
  await Provider.of<AuthProvider>(context, listen: false)
      .setLocalOnlyMode(true);
}
