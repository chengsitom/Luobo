import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/player_provider.dart';
import '../services/transcoding_service.dart';
import '../theme/design_tokens.dart';

/// 连接状态（网络 + 转码）的**公共描述**。
///
/// 设计稿：`docs/设置页重构技术方案.md` §9.2.1。
/// 账号卡副标题 = `服务器类型 · 网络 · 短转码状态`，例：
/// `道理鱼音乐 · WiFi · 不转码`、`道理鱼音乐 · 蜂窝网络 · 转码中`。
///
/// ⚠️ **当前实际使用点：只有设置根页的账号卡。**
/// `widgets/mini_player.dart` 的长按 toast 与 `widgets/song_tile.dart` 的
/// `_QualityInfo` **仍是各自的内联实现**（它们的文案与条件都更长：带格式与码率、
/// 且 song_tile 还区分「是否当前曲目」），尚未迁移到本类。三者的**橙色深浅档**
/// 已统一走 `LuoboAccent.warnFor`，但文案分支仍是三份 —— 改判断条件时要一起改。
/// TODO：把上面两处也迁到本类（需要 long-form 入参）。
///
/// ⚠️ 短形态**不含格式码率**（`OPUS 192kbps`）—— 那截已在播放页时间行与
/// `⋮` 面板里，账号卡是概览位不重复；且带上会溢出换行（实测 183px / 可用 203px）。
@immutable
class ConnectionStatusInfo {
  const ConnectionStatusInfo({
    required this.network,
    required this.networkColor,
    required this.status,
    required this.statusColor,
    required this.isTranscoding,
  });

  /// `WiFi` / `蜂窝网络`
  final String network;
  final Color networkColor;

  /// `不转码` / `转码中` / `已转码`
  final String status;
  final Color statusColor;

  final bool isTranscoding;
}

abstract final class ConnectionStatus {
  /// 从已解析的原始值构造 —— 调用方负责 `watch` 以触发重建。
  static ConnectionStatusInfo fromValues({
    required AppLocalizations l10n,
    required bool isWifi,
    required bool isActiveStreamTranscoded,
    required bool isTranscodingNow,
    required bool isDark,
  }) {
    final network = isWifi ? l10n.networkWifi : l10n.networkMobile;
    final networkColor = isWifi ? LuoboAccent.wifi : LuoboAccent.cell;

    final String status;
    final Color statusColor;
    if (isActiveStreamTranscoded) {
      status = l10n.transcodeShortDone;
      // 橙色的浅/深两档只在 token 层定义一处（§9.2.1 表）。
      statusColor = LuoboAccent.warnFor(isDark);
    } else if (isTranscodingNow) {
      status = l10n.transcodeShortActive;
      statusColor = LuoboAccent.warnFor(isDark);
    } else {
      status = l10n.transcodeShortIdle;
      statusColor = LuoboAccent.accent;
    }

    return ConnectionStatusInfo(
      network: network,
      networkColor: networkColor,
      status: status,
      statusColor: statusColor,
      isTranscoding: isActiveStreamTranscoded || isTranscodingNow,
    );
  }

  /// 便捷：直接从 BuildContext 读取（**不 watch**，适合一次性读取）。
  static ConnectionStatusInfo of(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final transcoding = Provider.of<TranscodingService>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return fromValues(
      l10n: l10n,
      isWifi: transcoding.currentConnectionType == ConnectionType.wifi,
      isActiveStreamTranscoded: player.isActiveStreamTranscoded,
      isTranscodingNow: transcoding.getCurrentBitrate() != null,
      isDark: isDark,
    );
  }

  /// 账号卡副标题：`服务器类型 · 网络 · 短转码状态`。
  ///
  /// 服务器类型取 `AuthProvider.config.serverType`；未连接时只返回网络与状态。
  static String accountSubtitle(
    BuildContext context, {
    ConnectionStatusInfo? info,
  }) {
    final config = Provider.of<AuthProvider>(context, listen: false).config;
    final s = info ?? of(context);
    final parts = <String>[
      if (config != null && (config.serverType ?? '').isNotEmpty)
        config.serverType!,
      s.network,
      s.status,
    ];
    return parts.join(' · ');
  }
}
