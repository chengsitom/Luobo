import 'dart:convert';
import '../widgets/luobo/luobo_toast.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';

class ServerQrDialog extends StatefulWidget {
  final ServerConfig config;

  const ServerQrDialog({super.key, required this.config});

  @override
  State<ServerQrDialog> createState() => _ServerQrDialogState();
}

class _ServerQrDialogState extends State<ServerQrDialog> {
  final GlobalKey _qrKey = GlobalKey();

  String _buildQrData() {
    final data = {
      'type': 'luobo_server',
      'serverUrl': widget.config.serverUrl,
      'localUrl': widget.config.localUrl,
      'username': widget.config.username,
      'password': widget.config.password,
      'serverFamily': widget.config.serverFamily,
      'useLegacyAuth': widget.config.useLegacyAuth,
      'allowSelfSignedCertificates': widget.config.allowSelfSignedCertificates,
      'name': widget.config.name,
    };
    return jsonEncode(data);
  }

  Future<void> _saveToGallery() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(pngBytes),
        quality: 100,
        name: 'luobo_server_qr_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;
      final success = result['isSuccess'] == true;
      showLuoboToast(
      context,
      message: success ? l10n.savedToGallery : l10n.failedToSaveQr,
      tone: LuoboToastTone.info,
    );
    } catch (e) {
      if (!mounted) return;
      showLuoboToast(
      context,
      message: l10n.failedToSaveQr,
      tone: LuoboToastTone.error,
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final qrData = _buildQrData();

    final label = widget.config.name?.isNotEmpty == true
        ? widget.config.name!
        : '${widget.config.username}@${Uri.tryParse(widget.config.serverUrl)?.host ?? widget.config.serverUrl}';

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qrCodeTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.qrCodeSubtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _qrKey,
              child: Container(
                width: 300,
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFA243C), Color(0xFFA02E8C)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.asset(
                            'assets/logo.png',
                            width: 28,
                            height: 28,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '萝卜',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saveToGallery,
                icon: const Icon(CupertinoIcons.arrow_down_to_line, size: 18),
                label: Text(l10n.saveToGallery),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
