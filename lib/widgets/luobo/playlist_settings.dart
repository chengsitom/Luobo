import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/models.dart';
import '../../providers/library_provider.dart';
import 'capsule_button.dart';
import 'playlist_form_sheet.dart';
import 'sheet_shell.dart';

/// 歌单设置胶囊叠（设计稿/10，规格见 歌曲列表弹窗方案 §4.4）：
/// **无把手**（同确认弹窗）+ 居中标题「歌单设置」+ 胶囊叠。
///
/// 列表页（`playlists_screen`）与歌单详情页（`playlist_screen`）共用；
/// 详情页额外动作（收藏/排序/多选/下载）由调用方传回调后动态出现。
Future<void> showPlaylistSettingsSheet(
  BuildContext context, {
  required Playlist playlist,
  VoidCallback? onRename,
  VoidCallback? onDelete,
  VoidCallback? onToggleFavorite,
  bool? isFavorite,
  VoidCallback? onReorder,
  VoidCallback? onMultiSelect,
  VoidCallback? onDownload,
  bool isDownloading = false,
}) async {
  final libraryProvider = Provider.of<LibraryProvider>(
    context,
    listen: false,
  );
  final l10n = AppLocalizations.of(context)!;

  await showLuoboSheet(
    context: context,
    title: l10n.playlistSettings,
    showHandle: false,
    builder: (ctx) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LuoboCapsuleButton(
          height: 50,
          label: l10n.edit,
          onPressed: () {
            Navigator.pop(ctx);
            (onRename ??
                () => showRenamePlaylistDialog(context, playlist, libraryProvider))();
          },
        ),
        if (onToggleFavorite != null) ...[
          const SizedBox(height: 16),
          LuoboCapsuleButton(
            label: isFavorite == true
                ? l10n.removeFromFavorites
                : l10n.addToFavorites,
            onPressed: () {
              Navigator.pop(ctx);
              onToggleFavorite();
            },
          ),
        ],
        if (onReorder != null) ...[
          const SizedBox(height: 16),
          LuoboCapsuleButton(
            label: l10n.reorderSongs,
            onPressed: () {
              Navigator.pop(ctx);
              onReorder();
            },
          ),
        ],
        if (onMultiSelect != null) ...[
          const SizedBox(height: 16),
          LuoboCapsuleButton(
            label: l10n.selectSongs,
            onPressed: () {
              Navigator.pop(ctx);
              onMultiSelect();
            },
          ),
        ],
        if (onDownload != null) ...[
          const SizedBox(height: 16),
          LuoboCapsuleButton(
            label: l10n.downloadPlaylist,
            onPressed: isDownloading
                ? null
                : () {
                    Navigator.pop(ctx);
                    onDownload();
                  },
          ),
        ],
        if (onDelete != null) ...[
          const SizedBox(height: 16),
          LuoboCapsuleButton(
            label: l10n.deletePlaylist,
            style: LuoboCapsuleStyle.danger,
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
          ),
        ],
        const SizedBox(height: 16),
        LuoboCapsuleButton(
          height: 50,
          label: l10n.cancel,
          onPressed: () => Navigator.pop(ctx),
        ),
      ],
    ),
  );
}

/// 歌单改名（§4.4「编辑 = 改名 only」）：fnos 模态表单
/// （`playlist_form_sheet.dart`——圆 × + 居中标题 + 玫红实心 ✓）。
Future<void> showRenamePlaylistDialog(
  BuildContext context,
  Playlist playlist,
  LibraryProvider libraryProvider,
) =>
    showPlaylistFormSheet(context, playlist: playlist);
