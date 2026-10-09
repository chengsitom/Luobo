import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../theme/app_theme.dart';

/// 服务器家族徽标：图标 + 品牌色。
///
/// 优先采用配置声明的 `serverFamily`；对「自动检测」保存下来的配置
/// （serverFamily 落为 subsonic 但 ping 自报 serverType 含 jellyfin 等），
/// 用 serverType 兜底，让徽标与服务器真实类型一致（纯展示，无网络行为）。
class ServerFamilyInfo {
  const ServerFamilyInfo({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  static ServerFamilyInfo of(ServerConfig profile) {
    final family = profile.serverFamily.toLowerCase();
    final type = (profile.serverType ?? '').toLowerCase();
    if (family == 'daoliyu' || type.contains('daoliyu')) {
      return const ServerFamilyInfo(
        icon: CupertinoIcons.music_note_list,
        color: Color(0xFF34C759),
        label: '道理鱼',
      );
    }
    if (family == 'jellyfin' || type.contains('jellyfin')) {
      return const ServerFamilyInfo(
        icon: CupertinoIcons.tv,
        color: Color(0xFFA970FF),
        label: 'Jellyfin',
      );
    }
    if (family == 'youtube') {
      return const ServerFamilyInfo(
        icon: CupertinoIcons.play_rectangle,
        color: Color(0xFFFF0000),
        label: 'YouTube Music',
      );
    }
    return const ServerFamilyInfo(
      icon: CupertinoIcons.music_note,
      color: Color(0xFF6366F1),
      label: 'Subsonic',
    );
  }
}

/// 已保存服务器配置卡片（iOS 分组卡片风，圆角 16 无阴影）。
///
/// 登录网关页与设置「已保存配置」二级页共用；当前连接卡片带绿色徽标，
/// 尾部可选展示 二维码 / 编辑 / 删除 三个操作图标。
class ServerProfileCard extends StatelessWidget {
  final ServerConfig profile;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onQr;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ServerProfileCard({
    super.key,
    required this.profile,
    required this.isActive,
    required this.onTap,
    this.onQr,
    this.onEdit,
    this.onDelete,
  });

  String get _label {
    if (profile.name?.isNotEmpty == true) return profile.name!;
    return '${profile.username}@'
        '${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final info = ServerFamilyInfo.of(profile);
    final secondary =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;
    final danger = const Color(0xFFFF3B30);

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: info.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(info.icon, color: info.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  isActive ? FontWeight.w600 : FontWeight.w500,
                              color:
                                  isActive ? theme.colorScheme.primary : null,
                            ),
                          ),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759).withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF34C759),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.connected,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF34C759),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      profile.serverUrl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: secondary),
                    ),
                    // 有名称时显示账号行；无名称时账号已包含在标题
                    // （username@host）里，避免重复展示。
                    if (profile.username.isNotEmpty &&
                        profile.name?.isNotEmpty == true)
                      Text(
                        profile.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: secondary),
                      ),
                  ],
                ),
              ),
              if (onQr != null)
                _actionButton(
                  icon: CupertinoIcons.qrcode,
                  color: secondary,
                  tooltip: l10n.shareQrCode,
                  onPressed: onQr!,
                ),
              if (onEdit != null)
                _actionButton(
                  icon: CupertinoIcons.pencil,
                  color: secondary,
                  tooltip: l10n.edit,
                  onPressed: onEdit!,
                ),
              if (onDelete != null)
                _actionButton(
                  icon: CupertinoIcons.trash,
                  color: danger,
                  tooltip: l10n.delete,
                  onPressed: onDelete!,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color),
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
    );
  }
}

/// 「＋ 添加服务器」虚线入口卡，与 [ServerProfileCard] 同尺寸同圆角。
class AddServerCard extends StatelessWidget {
  final VoidCallback onTap;

  const AddServerCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Material(
      color: isDark ? AppTheme.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: primary.withValues(alpha: 0.45),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.add, color: primary, size: 20),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.of(context)!.addServer,
                style: TextStyle(
                  color: primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
