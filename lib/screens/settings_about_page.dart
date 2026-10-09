import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/diagnostics/diagnostics_page.dart';
import '../services/update_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/settings_sub_page.dart';
import 'changelog_screen.dart';
import 'settings_mechanism_screen.dart';

/// 关于 Luobo（根页组 4 → 二级页）。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/03-设置二级页全量.png` A7
/// （参考 fnos「关于飞牛音乐」：图标 + 版本 + 信息卡 + 链接卡）。
///
/// ⚠️ **只保留当前真正生效的 6 项**（旧 `settings_about_tab.dart` 里的
/// 匿名分析 / 设备 ID / 开发者信息 / 反馈问题属于**死代码**——它只被不可达的
/// 旧 `settings_screen.dart` 引用，本次不复活，避免「多」）：
/// 版本 · 平台 · 更新日志 · 功能机制说明 · 诊断 · 开源仓库。
class SettingsAboutPage extends StatelessWidget {
  const SettingsAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);

    return SettingsSubPage(
      title: l10n.settingsGroupAbout,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuoboSpacing.pageX,
          LuoboSpacing.pageY,
          LuoboSpacing.pageX,
          LuoboSpacing.pageBottom,
        ),
        children: [
          // ── App 图标 + 版本 ────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                const SizedBox(height: 6),
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(LuoboRadius.appIcon),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [LuoboAccent.accentLight, LuoboAccent.accent],
                    ),
                  ),
                  child: const Icon(
                    AppIcons.music,
                    size: 38,
                    color: LuoboAccent.onAccent,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'v${UpdateService.currentVersion}',
                  style: LuoboType.versionTag.copyWith(color: c.fg2),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // ── 版本信息 ───────────────────────────────────────────────────
          LuoboCard(
            children: [
              LuoboRow(
                title: l10n.aboutVersion,
                value: 'v${UpdateService.currentVersion}',
                showChevron: false,
              ),
              const LuoboDivider(),
              LuoboRow(
                title: l10n.aboutPlatform,
                value: Theme.of(context).platform.name.toUpperCase(),
                showChevron: false,
              ),
            ],
          ),

          // ── 链接与工具 ─────────────────────────────────────────────────
          LuoboCard(
            children: [
              LuoboRow(
                icon: AppIcons.changelog,
                title: l10n.aboutLinkChangelog,
                onTap: () =>
                    NavigationHelper.push(context, const ChangelogScreen()),
              ),
              const LuoboDivider(indent: LuoboDivider.withIcon),
              LuoboRow(
                icon: AppIcons.help,
                title: l10n.settingsMechanicsEntry,
                onTap: () => NavigationHelper.push(
                  context,
                  const SettingsMechanismScreen(),
                ),
              ),
              const LuoboDivider(indent: LuoboDivider.withIcon),
              LuoboRow(
                icon: AppIcons.diagnostics,
                title: l10n.tabDiagnostics,
                onTap: () =>
                    NavigationHelper.push(context, const DiagnosticsPage()),
              ),
              const LuoboDivider(indent: LuoboDivider.withIcon),
              LuoboRow(
                icon: AppIcons.shield,
                title: l10n.aboutLinkGitHub,
                onTap: () => _openUrl('https://github.com/chengsitom/Luobo'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    try {
      if (!await canLaunchUrl(uri)) {
        debugPrint('[SettingsAbout] no handler for $url');
        return;
      }
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('[SettingsAbout] launch failed: $e');
    }
  }
}
