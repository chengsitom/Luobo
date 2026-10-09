import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../services/transcoding_service.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';

/// 音质与流媒体（转码设置）二级页。
/// 内容自 `settings_playback_tab.dart:609-897`（_buildTranscodingSection +
/// _showSmartTranscodingHelp）整体搬移，逻辑零改动；仅把状态类成员
/// （_isDark / _buildSection / _buildDivider）改写为入参传递。
class SettingsStreamingTab extends StatelessWidget {
  const SettingsStreamingTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TranscodingService>(
      builder: (context, ts, _) {
        final secondaryText = LuoboColors.of(context).fg2;

        Widget connectionBadge() {
          final isWifi = ts.currentConnectionType == ConnectionType.wifi;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (isWifi ? Colors.green : Colors.orange)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWifi ? Icons.wifi_rounded : Icons.signal_cellular_alt,
                  size: 12,
                  color: isWifi ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 4),
                Text(
                  isWifi
                      ? AppLocalizations.of(context)!.networkWifi
                      : AppLocalizations.of(context)!.networkMobile,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isWifi ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            _buildSection(
              title: AppLocalizations.of(context)!.sectionStreamingQuality,
              children: [
                LuoboRow(
                  icon: CupertinoIcons.waveform,
                  title: AppLocalizations.of(context)!.transcodingEnable,
                  subtitle:
                      AppLocalizations.of(context)!.transcodingEnableSubtitle,
                  showChevron: false,
                  trailing: LuoboSwitch(
                    value: ts.enabled,
                    onChanged: (v) => ts.setEnabled(v),
                  ),
                ),
                // 局域网连接时强制原码（规则 1）：即便设置了转码码率也
                // 不生效，这里显式提示，避免用户以为设置失效。
                if (ts.isLanOverrideActive) ...[
                  _buildDivider(),
                  _infoRow(
                    context,
                    icon: Icons.lan_rounded,
                    iconColor: LuoboAccent.ok,
                    text: AppLocalizations.of(context)!
                        .transcodingLanForceOriginal,
                  ),
                ],
                if (ts.enabled) ...[
                  _buildDivider(),
                  LuoboRow(
                    icon: Icons.auto_fix_high_rounded,
                    title: AppLocalizations.of(context)!.smartTranscoding,
                    titleSuffix: GestureDetector(
                      onTap: () => _showSmartTranscodingHelp(context),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: secondaryText,
                        ),
                      ),
                    ),
                    subtitle:
                        AppLocalizations.of(context)!.smartTranscodingSubtitle,
                    showChevron: false,
                    trailing: LuoboSwitch(
                      value: ts.smartEnabled,
                      onChanged: (v) => ts.setSmartEnabled(v),
                    ),
                  ),
                  if (ts.smartEnabled)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            AppLocalizations.of(context)!
                                .smartTranscodingDetectedNetwork,
                            style:
                                TextStyle(fontSize: 12, color: secondaryText),
                          ),
                          connectionBadge(),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              ts.getCurrentBitrate() != null
                                  ? '${ts.getCurrentBitrate()} kbps'
                                  : AppLocalizations.of(context)!
                                      .transcodingFormatOriginal,
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.end,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (ts.smartEnabled) ...[
                    _buildDivider(),
                    _bitrateRow(
                      context,
                      icon: Icons.wifi_rounded,
                      title:
                          AppLocalizations.of(context)!.transcodingWifiQuality,
                      subtitle: AppLocalizations.of(context)!
                          .transcodingWifiQualitySubtitleSmart,
                      value: ts.wifiBitrate,
                      onChanged: (v) => ts.setWifiBitrate(v),
                    ),
                    _buildDivider(),
                    _bitrateRow(
                      context,
                      icon: Icons.signal_cellular_alt_rounded,
                      title: AppLocalizations.of(context)!
                          .transcodingMobileQuality,
                      subtitle: AppLocalizations.of(context)!
                          .transcodingMobileQualitySubtitleSmart,
                      value: ts.mobileBitrate,
                      onChanged: (v) => ts.setMobileBitrate(v),
                    ),
                  ] else ...[
                    _buildDivider(),
                    _bitrateRow(
                      context,
                      icon: Icons.speed_rounded,
                      title: AppLocalizations.of(context)!
                          .transcodingManualBitrate,
                      subtitle: AppLocalizations.of(context)!
                          .transcodingManualBitrateSubtitle,
                      value: ts.manualBitrate,
                      onChanged: (v) => ts.setManualBitrate(v),
                    ),
                  ],
                  _buildDivider(),
                  LuoboRow(
                    icon: Icons.audio_file_rounded,
                    title: AppLocalizations.of(context)!.transcodingFormat,
                    subtitle:
                        AppLocalizations.of(context)!.transcodingFormatSubtitle,
                    value: _formatLabel(context, ts.format),
                    showChevron: true,
                    onTap: () async {
                      final title =
                          AppLocalizations.of(context)!.transcodingFormat;
                      final picked = await showLuoboPickerSheet<String>(
                        context: context,
                        title: title,
                        options: [
                          for (final f in TranscodeFormat.options)
                            (value: f, label: _formatLabel(context, f)),
                        ],
                        selected: ts.format,
                      );
                      if (picked == null || !context.mounted) return;
                      ts.setFormat(picked);
                    },
                  ),
                ],
              ],
            ),
            const SizedBox(height: 40),
          ],
        );
      },
    );
  }

  void _showSmartTranscodingHelp(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.smartTranscodingHelpTitle),
        content: Text(l10n.smartTranscodingHelpBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LuoboSectionHeader(title),
        LuoboCard(children: children),
      ],
    );
  }

  Widget _buildDivider() => const LuoboDivider(indent: LuoboDivider.withIcon);

  /// 卡内的「说明 / 状态」提示行（无 chevron、不可点）。
  Widget _infoRow(
    BuildContext context, {
    required IconData icon,
    required String text,
    Color? iconColor,
  }) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        LuoboSpacing.rowX,
        10,
        LuoboSpacing.rowX,
        10,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor ?? c.fg2),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: LuoboType.caption.copyWith(
                color: c.fg2,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 码率选择行：标题 + 副标题 + **状态值 + chevron**，点开是**单选 Sheet**
  /// （不再用 `DropdownButton` —— 它的 Material 弹窗是方角白面板，与设计体系差太远）。
  Widget _bitrateRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return LuoboRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      value: _bitrateLabel(context, value),
      showChevron: true,
      onTap: () async {
        final picked = await showLuoboPickerSheet<int>(
          context: context,
          title: title,
          options: [
            for (final b in TranscodeBitrate.options)
              (value: b, label: _bitrateLabel(context, b)),
          ],
          selected: value,
        );
        if (picked == null || !context.mounted) return;
        onChanged(picked);
      },
    );
  }

  String _formatLabel(BuildContext context, String format) =>
      format == TranscodeFormat.original
          ? AppLocalizations.of(context)!.transcodingFormatOriginal
          : format.toUpperCase();

  String _bitrateLabel(BuildContext context, int bitrate) =>
      bitrate == TranscodeBitrate.original
          ? AppLocalizations.of(context)!.transcodingBitrateOriginal
          : '$bitrate kbps';
}
