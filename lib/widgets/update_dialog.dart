import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/update_service.dart';
import '../theme/app_theme.dart';

/// 统一的"有新版本"对话框 —— 冷启自动检查（MainScreen）与设置页主动检查
/// （关于页）共用，保证两处外观与下载行为一致。
///
/// Android 点「下载更新」会把匹配机型的 split APK 直链交给浏览器下载；
/// 其他平台或选包失败回退 GitHub release 页。
void showUpdateDialog(BuildContext context, ReleaseInfo release) {
  final l10n = AppLocalizations.of(context)!;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final changelog = UpdateService.stripMarkdown(release.body);

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.appleMusicRed, AppTheme.appleMusicPink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    CupertinoIcons.arrow_up_circle_fill,
                    color: Colors.white,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.updateAvailable,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.updateAvailableSubtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Flexible(
                        child: _VersionBadge(
                          label: l10n.updateCurrentVersion(
                            UpdateService.currentVersion,
                          ),
                          color: Colors.white24,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        CupertinoIcons.arrow_right,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: _VersionBadge(
                          label: l10n.updateLatestVersion(release.version),
                          color: Colors.white.withValues(alpha: 0.3),
                          bold: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (changelog.isNotEmpty)
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.whatsNew,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white54 : Colors.black45,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: Scrollbar(
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            child: Text(
                              changelog,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l10n.remindLater),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        await _openDownload(release);
                      },
                      icon: const Icon(CupertinoIcons.cloud_download, size: 18),
                      label: Text(l10n.downloadUpdate),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: AppTheme.appleMusicRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<void> _openDownload(ReleaseInfo release) async {
  var url = release.htmlUrl;
  if (!kIsWeb && Platform.isAndroid) {
    final apk = await UpdateService.pickBestApk(release);
    if (apk != null) url = apk.browserDownloadUrl;
  }
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _VersionBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool bold;

  const _VersionBadge({
    required this.label,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      // 窄屏下两个版本徽标会超出弹窗宽度，FittedBox 等比缩字保证版本号完整。
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 1,
          softWrap: false,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
