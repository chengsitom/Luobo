import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../utils/navigation_helper.dart';
import 'saved_profiles_screen.dart';

class SettingsServerTab extends StatefulWidget {
  const SettingsServerTab({super.key});

  @override
  State<SettingsServerTab> createState() => _SettingsServerTabState();
}

class _SettingsServerTabState extends State<SettingsServerTab> {
  // 已保存配置计数：缓存 future，避免每次 build 重建导致 count 闪烁。
  Future<List<ServerConfig>>? _profilesFuture;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _reloadProfiles();
    }
  }

  void _reloadProfiles() {
    _profilesFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).getSavedProfiles();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authProvider = Provider.of<AuthProvider>(context);
    final serverType = authProvider.config?.serverType;
    final serverVersion = authProvider.config?.serverVersion;
    final serverFamily = authProvider.config?.serverFamily;

    // 优先按客户端认定的家族显示（serverType 是服务器 ping 自报的协议名，
    // 道理鱼这类带私有扩展的服务器不会自报「daoliyu」）。未知家族回退
    // 到 serverType，都没有时用默认文案。
    String serverSubtitle;
    switch (serverFamily) {
      case 'daoliyu':
        serverSubtitle = '道理鱼';
      case 'jellyfin':
        serverSubtitle = 'Jellyfin';
      default:
        serverSubtitle = 'Subsonic API';
        if (serverType != null && serverType.isNotEmpty) {
          serverSubtitle = serverType;
        }
    }
    if (serverVersion != null && serverVersion.isNotEmpty) {
      serverSubtitle += ' $serverVersion';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildSection(
          title: l10n.sectionServerConnection,
          children: [
            _buildInfoTile(
              icon: CupertinoIcons.cloud,
              title: l10n.serverType,
              subtitle: serverSubtitle,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.link,
              title: l10n.serverUrl,
              subtitle: authProvider.config?.serverUrl ?? l10n.notConnected,
            ),
            _buildDivider(),
            _buildInfoTile(
              icon: CupertinoIcons.person,
              title: l10n.username,
              subtitle: authProvider.config?.username ?? l10n.unknown,
            ),
          ],
        ),
        _buildSection(
          title: l10n.sectionSavedProfiles,
          children: [_buildSavedProfilesEntry()],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ── C1 组件化的行/分组辅助 ────────────────────────────────────────────
  // 页面内容与结构保持不变，只把外壳换成设计体系组件。

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

  /// 只读信息行（主标题 + 副标题）。图标统一玫红（§2.3）。
  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return LuoboRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showChevron: false,
    );
  }

  // ── 已迁移走的入口（勿在此处再加回） ──────────────────────────────────
  //
  // · 「音乐文件夹」→ 并入「修改连接」页（`server_form_screen.dart` 的
  //   「音乐库范围」行），并从多选改为**单选**（修掉「勾多个只取 `.first`」
  //   的既有 bug）。见 `docs/设置页重构技术方案.md` §9.6。
  // · 「退出登录」→ 移到 App 设置页（`settings_app_page.dart` 的独立胶囊）。

  /// 已保存配置入口行：`已保存配置 (N) >`，点击进入独立卡片二级页
  /// （[SavedProfilesScreen]）。原内嵌配置列表已拆出，避免配置多时
  /// 把服务器管理页拉得过长。
  Widget _buildSavedProfilesEntry() {
    return FutureBuilder<List<ServerConfig>>(
      future: _profilesFuture,
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        final l10n = AppLocalizations.of(context)!;
        return LuoboRow(
          icon: Icons.dns_rounded,
          title: l10n.sectionSavedProfiles,
          value: count > 0 ? '$count' : null,
          onTap: () =>
              NavigationHelper.push(context, const SavedProfilesScreen()),
        );
      },
    );
  }
}
