import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/luobo/create_playlist_dialog.dart';
import '../widgets/luobo/playlist_settings.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import 'playlist_screen.dart';
import 'ai_playlist_screen.dart';

class PlaylistsScreen extends StatelessWidget {
  const PlaylistsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final libraryProvider = Provider.of<LibraryProvider>(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // 与收藏页同款：透明顶栏 + 悬浮圆钮（无实色栏、无标题）。
      extendBodyBehindAppBar: true,
      appBar: LuoboListTopBar(
        actions: [
          LuoboTopCircleButton(
            icon: Icons.auto_awesome,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiPlaylistScreen()),
            ),
          ),
          const SizedBox(width: 8),
          LuoboTopCircleButton(
            icon: AppIcons.plus,
            onTap: () => _showCreatePlaylistDialog(context),
          ),
        ],
      ),
      body: libraryProvider.playlists.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.music_note_list,
                    size: 64,
                    color: AppTheme.lightSecondaryText,
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.noPlaylists, style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    l10n.createPlaylistToStart,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: const Icon(CupertinoIcons.add),
                    label: Text(l10n.newPlaylist),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.appleMusicRed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.only(
                top: listTopInset(context),
                bottom: LuoboSpacing.pageBottomWithStrip(context),
              ),
              itemCount: libraryProvider.playlists.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _PlaylistCountRow(
                    count: libraryProvider.playlists.length,
                  );
                }
                final i = index - 1;
                final playlist = libraryProvider.playlists[i];
                return Column(
                  children: [
                    _PlaylistTile(
                      playlist: playlist,
                      onTap: () => _openPlaylist(context, playlist),
                      onLongPress: () =>
                          _showPlaylistOptions(context, playlist),
                      onMore: () => _showPlaylistOptions(context, playlist),
                    ),
                    if (i < libraryProvider.playlists.length - 1)
                      const LuoboSongDivider(),
                  ],
                );
              },
            ),
    );
  }

  void _openPlaylist(BuildContext context, Playlist playlist) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PlaylistScreen(
          playlistId: playlist.id,
          playlistName: playlist.name,
        ),
      ),
    );
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) =>
      showCreatePlaylistDialog(context);

  void _showPlaylistOptions(BuildContext context, Playlist playlist) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    // 歌单设置胶囊叠（C3 二期已抽公共 `showPlaylistSettingsSheet`，
    // 见 lib/widgets/luobo/playlist_settings.dart）。
    showPlaylistSettingsSheet(
      context,
      playlist: playlist,
      onDelete: () async {
        final l10n = AppLocalizations.of(context)!;
        final confirmed = await showLuoboConfirmSheet(
          context: context,
          title: l10n.deletePlaylist,
          message: l10n.deletePlaylistConfirmation(playlist.name),
          confirmLabel: l10n.delete,
        );
        if (confirmed == true && context.mounted) {
          await libraryProvider.deletePlaylist(playlist.id);
        }
      },
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 行尾 `···` 圆钮（歌单设置，C3 二期 §4.4；设计稿/10）。
  final VoidCallback? onMore;

  const _PlaylistTile({
    required this.playlist,
    this.onTap,
    this.onLongPress,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: BorderRadius.circular(6),
                ),
                clipBehavior: Clip.antiAlias,
                child: playlist.coverArt != null
                    ? AlbumArtwork(
                        coverArt: playlist.coverArt,
                        size: 48,
                        borderRadius: 6,
                      )
                    : Icon(
                        CupertinoIcons.music_note_list,
                        color: c.fg3,
                        size: 22,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.songCount(playlist.songCount ?? 0),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onMore,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(AppIcons.moreV, size: 18, color: c.fg2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 歌单列表计数行（44dp，「共 N 个歌单」）。
class _PlaylistCountRow extends StatelessWidget {
  final int count;

  const _PlaylistCountRow({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Container(
      height: 44,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.only(left: 16),
      child: Text(
        AppLocalizations.of(context)!.playlistsTotal(count),
        style: LuoboType.body.copyWith(fontSize: 14, color: c.fg2),
      ),
    );
  }
}
