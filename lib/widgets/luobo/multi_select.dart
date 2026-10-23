import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/song.dart';
import '../../providers/library_provider.dart';
import '../../providers/player_provider.dart';
import '../../services/offline_service.dart';
import '../../services/subsonic_service.dart';
import '../../theme/design_tokens.dart';
import '../song_tile.dart';
import 'empty_state.dart';
import 'luobo_toast.dart';
import 'song_divider.dart';
import 'sheet_shell.dart';

/// 多选整屏接管的公共组件与批量操作（设计稿/10，规格见
/// `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.5）。
///
/// 顶部悬浮栏：拖拽把手 + 玫红「−」圆 30 + 「已选 N 首」16/600 + 「完成」15；
/// 底部操作栏：4 等分（图标 18-20 + label 12），顶部分隔线。
class LuoboMultiSelectTopBar extends StatelessWidget {
  final int count;
  final VoidCallback onExit;
  final VoidCallback onDone;

  /// 全选/取消全选（fnos v1_0064 顶栏有「全选」；传 null 不显示）。
  final VoidCallback? onToggleSelectAll;
  final bool allSelected;

  const LuoboMultiSelectTopBar({
    super.key,
    required this.count,
    required this.onExit,
    required this.onDone,
    this.onToggleSelectAll,
    this.allSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: c.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: onExit,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: LuoboAccent.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.remove_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (onToggleSelectAll != null)
                GestureDetector(
                  onTap: onToggleSelectAll,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      allSelected ? l10n.deselectAll : l10n.selectAll,
                      style: LuoboType.body.copyWith(
                        fontSize: 13,
                        color: c.fg2,
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  l10n.selectedSongsCount(count),
                  style: LuoboType.body.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onDone,
                child: Text(
                  l10n.done,
                  style: LuoboType.body.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 多选操作栏（底部 4 等分；`playlist` 页可多传「移除」）。
class LuoboMultiSelectActionBar extends StatelessWidget {
  final List<({IconData icon, String label, VoidCallback? onTap})> actions;

  /// 底部安全区（放在栏内，让栏背景延伸到屏幕底）。
  final double bottomInset;

  const LuoboMultiSelectActionBar({
    super.key,
    required this.actions,
    this.bottomInset = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10 + bottomInset),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: c.divider, width: 0.5)),
      ),
      child: Row(
        children: [
          for (final action in actions)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: action.onTap,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action.icon,
                      size: 20,
                      color: action.onTap == null ? c.fg3 : c.fg2,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      action.label,
                      style: LuoboType.caption.copyWith(
                        fontSize: 12,
                        color: action.onTap == null ? c.fg3 : c.fg2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 批量操作（§4.5）：
/// - 播放：`playSong` 首曲 + 选中集为播放列表
/// - 加入播放列表：`addAllToQueue`
/// - 下载：`OfflineService.downloadSongs`，完成后**聚合提示**
/// - 添加到歌单：批量选择器（歌单列表 → `updatePlaylist(songIdsToAdd)`）
///
/// [onExit] 用于操作完成后退出多选态（页面自行清空选中）。
Future<void> runMultiAction(
  BuildContext context, {
  required LuoboMultiAction action,
  required List<Song> songs,
  VoidCallback? onExit,
}) async {
  final player = Provider.of<PlayerProvider>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;

  switch (action) {
    case LuoboMultiAction.play:
      if (songs.isNotEmpty) {
        player.playSong(songs.first, playlist: songs, startIndex: 0);
        onExit?.call();
      }
      break;
    case LuoboMultiAction.addToQueue:
      await player.addAllToQueue(songs);
      // 状态提醒（原先静默）。
      showLuoboToast(
        context,
        message: l10n.addedToQueue,
        tone: LuoboToastTone.info,
      );
      onExit?.call();
      break;
    case LuoboMultiAction.download:
      final subsonicService =
          Provider.of<SubsonicService>(context, listen: false);
      var ok = 0;
      var fail = 0;
      await OfflineService().downloadSongs(
        songs,
        subsonicService,
        onSongComplete: (song, success) {
          if (success) {
            ok++;
          } else {
            fail++;
          }
        },
      );
      showLuoboToast(
        context,
        message: fail == 0
            ? l10n.downloadedSongsFrom(songs.length, '')
            : '${l10n.downloadFailed} · 成功 $ok / 失败 $fail',
        tone: fail == 0 ? LuoboToastTone.success : LuoboToastTone.error,
      );
      onExit?.call();
      break;
    case LuoboMultiAction.addToPlaylist:
      await showBatchPlaylistPicker(context, songs);
      onExit?.call();
      break;
  }
}

enum LuoboMultiAction { play, addToQueue, download, addToPlaylist }

/// 批量「添加到歌单」选择器（§4.5）：复用歌单列表 + `LuoboSheetRow`，
/// 与单曲选择器（song_tile._showPlaylistPicker）同一视觉；空态用 EmptyState。
Future<void> showBatchPlaylistPicker(
  BuildContext context,
  List<Song> songs,
) async {
  final libraryProvider = Provider.of<LibraryProvider>(
    context,
    listen: false,
  );
  final l10n = AppLocalizations.of(context)!;

  await showLuoboSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (libraryProvider.playlists.isEmpty)
            LuoboEmptyState(message: '还没有歌单，先建一个吧~')
          else
            ...libraryProvider.playlists.map(
              (playlist) => LuoboSheetRow(
                title: playlist.name,
                subtitle: l10n.songsCount(playlist.songCount ?? 0),
                showChevron: false,
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    await Provider.of<SubsonicService>(
                      context,
                      listen: false,
                    ).updatePlaylist(
                      playlistId: playlist.id,
                      songIdsToAdd: songs.map((s) => s.id).toList(),
                    );
                    await libraryProvider.loadPlaylists();
                    if (!context.mounted) return;
                    showLuoboToast(
                      context,
                      message: l10n.addedSongsToPlaylist(songs.length, playlist.name),
                      tone: LuoboToastTone.success,
                      // 撤销已移除（服务端 songIndexToRemove 不可靠；fnos 亦无撤销）。
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    showLuoboToast(
                      context,
                      message: l10n.errorAddingToPlaylist(e),
                      tone: LuoboToastTone.error,
                    );
                  }
                },
              ),
            ),
        ],
      ),
    ),
  );
}
/// **多选全屏弹窗**（fnos v1_0064 实测：全屏 sheet + 把手 + 全选/完成 +
/// 圆形勾选行 + 底部 4 等分操作——**不是**页面内选择模式）。
///
/// 入口：列表页「共 N 首」行右侧的多选图标（fnos 同构）。
/// [onRemove] 提供时底部操作栏追加「移除」（歌单内使用）。
Future<void> showMultiSelectSheet(
  BuildContext context, {
  required List<Song> songs,
  Future<void> Function(List<Song> songs)? onRemove,
  String? removeLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: LuoboMotion.scrim,
    builder: (_) => FractionallySizedBox(
      // ⚠️ 2026-10-22 修正：不是通顶——sheet 从下方升起（顶部留出上一页），
      // **只有底部操作栏要求贴屏幕底**（安全区内置在操作栏背景内）。
      heightFactor: 0.92,
      child: _MultiSelectSheet(
        songs: songs,
        onRemove: onRemove,
        removeLabel: removeLabel,
      ),
    ),
  );
}

class _MultiSelectSheet extends StatefulWidget {
  final List<Song> songs;
  final Future<void> Function(List<Song> songs)? onRemove;
  final String? removeLabel;

  const _MultiSelectSheet({
    required this.songs,
    this.onRemove,
    this.removeLabel,
  });

  @override
  State<_MultiSelectSheet> createState() => _MultiSelectSheetState();
}

class _MultiSelectSheetState extends State<_MultiSelectSheet> {
  final Set<int> _selected = {};

  List<Song> get _selectedSongs =>
      [for (final i in _selected.toList()..sort()) widget.songs[i]];

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final allSelected =
        _selected.length == widget.songs.length && widget.songs.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      if (allSelected) {
                        _selected.clear();
                      } else {
                        _selected.addAll(
                          List.generate(widget.songs.length, (i) => i),
                        );
                      }
                    }),
                    child: Text(
                      allSelected ? l10n.deselectAll : l10n.selectAll,
                      style: LuoboType.body.copyWith(color: c.fg2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.selectedSongsCount(_selected.length),
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      l10n.done,
                      style: LuoboType.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: widget.songs.length,
                itemBuilder: (context, index) {
                  // 行样式与歌曲列表一致（封面 48/标题 15/副标题 12），
                  // 只是少了 ⋮；分隔线从封面右缘往后一点开始（含选择框 → 106）。
                  return Column(
                    children: [
                      SongTile(
                        song: widget.songs[index],
                        playlist: widget.songs,
                        index: index,
                        selectionMode: true,
                        selected: _selected.contains(index),
                        onTap: () => setState(() {
                          if (!_selected.remove(index)) _selected.add(index);
                        }),
                      ),
                      if (index < widget.songs.length - 1)
                        const LuoboSongDivider(indent: 106),
                    ],
                  );
                },
              ),
            ),
            LuoboMultiSelectActionBar(
              // 底部安全区放在**栏内**：栏背景延伸到屏幕底（通底）。
              bottomInset: MediaQuery.of(context).padding.bottom,
              actions: [
                (
                  icon: Icons.play_arrow_rounded,
                  label: l10n.play,
                  onTap: _selected.isEmpty
                      ? null
                      : () => _run(() => runMultiAction(
                            context,
                            action: LuoboMultiAction.play,
                            songs: _selectedSongs,
                          )),
                ),
                (
                  icon: Icons.queue_music_rounded,
                  label: l10n.addToPlaybackQueue,
                  onTap: _selected.isEmpty
                      ? null
                      : () => _run(() => runMultiAction(
                            context,
                            action: LuoboMultiAction.addToQueue,
                            songs: _selectedSongs,
                          )),
                ),
                (
                  icon: Icons.download_rounded,
                  label: l10n.download,
                  onTap: _selected.isEmpty
                      ? null
                      : () => _run(() => runMultiAction(
                            context,
                            action: LuoboMultiAction.download,
                            songs: _selectedSongs,
                          )),
                ),
                // 「添加到歌单」与「从歌单移除」互斥（fnos 歌单内多选只有移除）。
                if (widget.onRemove == null)
                  (
                    icon: Icons.playlist_add_rounded,
                    label: l10n.addToPlaylist,
                    onTap: _selected.isEmpty
                        ? null
                        : () => _run(() => runMultiAction(
                              context,
                              action: LuoboMultiAction.addToPlaylist,
                              songs: _selectedSongs,
                            )),
                  ),
                if (widget.onRemove != null)
                  (
                    icon: Icons.playlist_remove_rounded,
                    label: widget.removeLabel ?? l10n.removeFromPlaylist,
                    onTap: _selected.isEmpty
                        ? null
                        : () => _run(() async {
                              final songs = _selectedSongs;
                              Navigator.pop(context);
                              await widget.onRemove!(songs);
                            }),
                  ),
              ],
            ),
          ],
        ),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    await action();
    if (mounted) Navigator.pop(context);
  }
}
