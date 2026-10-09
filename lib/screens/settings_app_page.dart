import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/analytics_service.dart';
import '../services/locale_service.dart';
import '../services/theme_service.dart';
import '../theme/design_tokens.dart';
import '../utils/byte_format.dart';
import '../utils/image_cache.dart';
import '../utils/navigation_helper.dart';
import '../widgets/luobo/capsule_button.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/settings_sub_page.dart';

/// App 设置（右上角圆钮 → 二级页）。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/02-设置根页.png` 第三屏
/// + 结构说明 `docs/设置页重构技术方案.md` §9.3。
///
/// 照 fnos 的三个细节：
/// 1. **标题就叫「设置」**，不叫「App 设置」
/// 2. **行内不带图标**（纯文字 + chevron），分隔线缩进 14px（无图标）
/// 3. **二级页无底栏**
///
/// ⚠️ 与 fnos 的有意差异：fnos 第二行是「FN Connect 连接偏好」（飞牛自家协议），
/// Luobo 无对应物 → 改为「语言」。
///
/// ⚠️ 文案纠正：fnos 的「App 日志上报」对 Luobo **不准确** —— Luobo 的日志
/// **只存本地、明确不做网络上报**（见功能机制说明）。因此这里是
/// 「匿名分析」（真实的 `AnalyticsService` 开关）+「导出日志」（本地导出）。
class SettingsAppPage extends StatelessWidget {
  const SettingsAppPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SettingsSubPage(
      title: l10n.settingsTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuoboSpacing.pageX,
          LuoboSpacing.pageY,
          LuoboSpacing.pageX,
          LuoboSpacing.pageBottom,
        ),
        children: [
          // ── 外观 / 语言 ────────────────────────────────────────────────
          LuoboCard(
            children: [
              LuoboRow(
                title: l10n.appearance,
                onTap: () => NavigationHelper.push(
                  context,
                  const SettingsAppearancePage(),
                ),
              ),
              const LuoboDivider(),
              Consumer<LocaleService>(
                builder: (ctx, locale, _) {
                  final code = locale.currentLocale?.languageCode ??
                      Localizations.localeOf(ctx).languageCode;
                  final name =
                      LocaleService.supportedLanguages[code] ?? 'English';
                  return LuoboRow(
                    title: l10n.language,
                    value: name,
                    onTap: () => _showLanguagePicker(ctx, locale),
                  );
                },
              ),
            ],
          ),

          // ── 缓存 / 匿名分析 / 导出日志 ────────────────────────────────
          const _CacheAndPrivacyCard(),
        ],
      ),
    );
  }

  void _showLanguagePicker(BuildContext context, LocaleService localeService) {
    final l10n = AppLocalizations.of(context)!;
    showLuoboSheet<void>(
      context: context,
      title: l10n.language,
      isScrollControlled: true,
      builder: (ctx) => Flexible(
        child: ListView(
          shrinkWrap: true,
          children: [
            LuoboSheetRow(
              title: l10n.systemDefault,
              selected: localeService.currentLocale == null,
              showChevron: false,
              onTap: () {
                localeService.setLocale(null);
                Navigator.pop(ctx);
              },
            ),
            for (final entry in LocaleService.supportedLanguages.entries)
              LuoboSheetRow(
                title: entry.value,
                selected:
                    localeService.currentLocale?.languageCode == entry.key,
                showChevron: false,
                onTap: () {
                  localeService.setLocale(Locale(entry.key));
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// 缓存大小 + 匿名分析 + 导出日志 + 退出登录。
class _CacheAndPrivacyCard extends StatefulWidget {
  const _CacheAndPrivacyCard();

  @override
  State<_CacheAndPrivacyCard> createState() => _CacheAndPrivacyCardState();
}

class _CacheAndPrivacyCardState extends State<_CacheAndPrivacyCard> {
  final _analytics = AnalyticsService();
  bool _analyticsEnabled = true;
  int _coverCacheBytes = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final enabled = _analytics.isEnabled;
      final bytes = await coverCacheDirSize();
      if (!mounted) return;
      setState(() {
        _analyticsEnabled = enabled;
        _coverCacheBytes = bytes;
      });
    } catch (_) {
      // 读不到就保持默认值，不阻塞页面。
    }
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _busy = true);
    var ok = false;
    try {
      await coverCacheManager.emptyCache();
      await _load();
      ok = true;
    } catch (e) {
      debugPrint('[SettingsApp] clear cache failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? l10n.allCacheCleared : l10n.operationFailed)),
    );
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logout),
          ),
        ],
      ),
    );
    if (ok == true) {
      // 与旧「服务器管理」页一致：先停播放再登出，否则音乐会继续在登录页背后播。
      // ⚠️ stop() 失败也必须继续登出 —— 否则用户点了确认却仍是登录态且无反馈。
      try {
        await player.stop();
      } catch (e) {
        debugPrint('[SettingsApp] stop playback before logout failed: $e');
      }
      try {
        await auth.logout();
      } catch (e) {
        debugPrint('[SettingsApp] logout failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.operationFailed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sizeLabel = formatBytes(_coverCacheBytes);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LuoboCard(
          children: [
            LuoboRow(
              title: l10n.clearAppCache,
              value: _busy ? null : sizeLabel,
              onTap: _busy ? null : _clearCache,
            ),
            const LuoboDivider(),
            LuoboRow(
              title: l10n.anonymousAnalyticsToggle,
              showChevron: false,
              trailing: LuoboSwitch(
                value: _analyticsEnabled,
                onChanged: (v) async {
                  await _analytics.setEnabled(v);
                  if (mounted) setState(() => _analyticsEnabled = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LuoboCapsuleButton(
          label: l10n.logout,
          onPressed: _logout,
        ),
      ],
    );
  }
}

/// 外观页：主题模式（单选）+ 强调色（8 色点）。
///
/// 设计稿：`03-设置二级页全量.png` C1。
/// 玻璃与卡片样式**由设计体系统一定义，不提供用户调节**（§7 ⑭）。
class SettingsAppearancePage extends StatefulWidget {
  const SettingsAppearancePage({super.key});

  @override
  State<SettingsAppearancePage> createState() => _SettingsAppearancePageState();
}

class _SettingsAppearancePageState extends State<SettingsAppearancePage> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final themeService = context.watch<ThemeService>();

    return SettingsSubPage(
      title: l10n.appearance,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuoboSpacing.pageX,
          LuoboSpacing.pageY,
          LuoboSpacing.pageX,
          LuoboSpacing.pageBottom,
        ),
        children: [
          LuoboSectionHeader(l10n.themeModeTitle),
          LuoboCard(
            children: [
              LuoboRadioRow(
                title: l10n.systemDefault,
                selected: themeService.themeMode == ThemeMode.system,
                onTap: () => themeService.setThemeMode(ThemeMode.system),
              ),
              const LuoboDivider(),
              LuoboRadioRow(
                title: l10n.themeModeLight,
                selected: themeService.themeMode == ThemeMode.light,
                onTap: () => themeService.setThemeMode(ThemeMode.light),
              ),
              const LuoboDivider(),
              LuoboRadioRow(
                title: l10n.themeModeDark,
                selected: themeService.themeMode == ThemeMode.dark,
                onTap: () => themeService.setThemeMode(ThemeMode.dark),
              ),
            ],
          ),
          LuoboSectionHeader(l10n.accentColorLabel),
          const LuoboCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: LuoboSpacing.rowX,
                  vertical: LuoboSpacing.cardPadY,
                ),
                child: _AccentDots(),
              ),
            ],
          ),
          LuoboHint(l10n.appearanceGlassHint),
        ],
      ),
    );
  }
}

/// 强调色 8 色点。
class _AccentDots extends StatelessWidget {
  const _AccentDots();

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();
    final c = LuoboColors.of(context);
    return Wrap(
      spacing: 11,
      runSpacing: 11,
      children: [
        for (final a in AccentColor.values)
          GestureDetector(
            onTap: () => themeService.setAccentColor(a),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: a.color,
                shape: BoxShape.circle,
                boxShadow: themeService.accentColor == a
                    ? [
                        BoxShadow(color: c.card, spreadRadius: 2.5),
                        BoxShadow(
                          color: LuoboAccent.accent,
                          spreadRadius: 4.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
