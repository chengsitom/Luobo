import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/providers.dart';

/// 新建歌单命名对话框（公共版，`playlists_screen` 与 `song_tile` 的
/// 「添加到歌单」选择器共用，见 `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.3）。
///
/// ⚠️ 仍是 Material `AlertDialog`（B 级「模态表单 sheet」改造前的过渡形态）；
/// 模态表单落地后只改这一个函数，调用方不动。
Future<void> showCreatePlaylistDialog(BuildContext context) async {
  final controller = TextEditingController();

  await showDialog(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(AppLocalizations.of(dialogContext)!.newPlaylist),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(
          hintText: AppLocalizations.of(dialogContext)!.playlistName,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(AppLocalizations.of(dialogContext)!.cancel),
        ),
        TextButton(
          onPressed: () async {
            if (controller.text.trim().isNotEmpty) {
              final libraryProvider = Provider.of<LibraryProvider>(
                dialogContext,
                listen: false,
              );
              await libraryProvider.createPlaylist(controller.text.trim());
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            }
          },
          child: Text(AppLocalizations.of(dialogContext)!.create),
        ),
      ],
    ),
  );
  controller.dispose();
}