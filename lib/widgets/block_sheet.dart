import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/blocklist_service.dart';

// 调用方（详情页/歌曲菜单）只需要屏蔽类型，顺带再导出，省一个 import。
export '../services/blocklist_service.dart'
    show BlockKind, BlockMode, BlockEntry;
import 'luobo/luobo_toast.dart';
import 'luobo/sheet_shell.dart';

/// 「屏蔽」入口统一的弹窗：**一个入口、两档强度**。
///
/// - 彻底屏蔽：列表、搜索、漫游里都不出现（`BlockMode.hidden`）
/// - 仅从漫游排除：仍可浏览可播，只是不会被随机/推荐抽到（`BlockMode.muted`）
///
/// 已屏蔽的对象再次打开时，会把当前档位标出来，并多一行「解除屏蔽」。
///
/// ⚠️ 提示走 **root overlay**：点击后 sheet 会先 pop，网络/存储回来时调用方的
/// context 可能已经销毁（`showLuoboToast(context)` 会静默放弃）。
Future<void> showBlockSheet(
  BuildContext context, {
  required BlockKind kind,
  required String targetId,
  required String name,
  Iterable<String>? members,
  int? songCount,
}) async {
  if (targetId.isEmpty) {
    // 个别服务端缺 artistId/albumId：没有稳定 id 就不给入口，避免"屏蔽了没效果"。
    return;
  }
  final l10n = AppLocalizations.of(context)!;
  final toastOverlay = Overlay.of(context, rootOverlay: true);
  final blocklist = BlocklistService.instance;
  final existing = blocklist.entryFor(kind, targetId);

  final title = switch (kind) {
    BlockKind.artist => l10n.blockArtistAction,
    BlockKind.album => l10n.blockAlbumAction,
    BlockKind.playlist => l10n.blockPlaylistAction,
    BlockKind.song => l10n.blockSongAction,
  };

  Future<void> apply(BlockMode mode) async {
    switch (kind) {
      case BlockKind.artist:
        await blocklist.blockArtist(targetId, name, mode: mode);
      case BlockKind.album:
        await blocklist.blockAlbum(targetId, name, mode: mode);
      case BlockKind.playlist:
        await blocklist.blockPlaylist(
          targetId,
          name,
          mode: mode,
          members: members,
          songCount: songCount,
        );
      case BlockKind.song:
        await blocklist.blockSong(targetId, name, mode: mode);
    }
    showLuoboToastOnOverlay(
      toastOverlay,
      message: l10n.blockedSuccess(name),
      tone: LuoboToastTone.success,
    );
  }

  await showLuoboSheet<void>(
    context: context,
    title: title,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuoboSheetRow(
          title: l10n.blockModeHide,
          subtitle: l10n.blockModeHideDesc,
          leading: const Icon(Icons.visibility_off_rounded, size: 18),
          showChevron: false,
          selected: existing?.mode == BlockMode.hidden,
          onTap: () {
            Navigator.pop(ctx);
            apply(BlockMode.hidden);
          },
        ),
        LuoboSheetRow(
          title: l10n.blockModeMute,
          subtitle: l10n.blockModeMuteDesc,
          leading: const Icon(Icons.shuffle_rounded, size: 18),
          showChevron: false,
          selected: existing?.mode == BlockMode.muted,
          onTap: () {
            Navigator.pop(ctx);
            apply(BlockMode.muted);
          },
        ),
        if (existing != null)
          LuoboSheetRow(
            title: l10n.unblockAction,
            leading: const Icon(Icons.undo_rounded, size: 18),
            showChevron: false,
            danger: true,
            onTap: () {
              Navigator.pop(ctx);
              blocklist.unblock(kind, targetId);
              showLuoboToastOnOverlay(
                toastOverlay,
                message: l10n.unblockAction,
                tone: LuoboToastTone.info,
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    ),
  );
}
