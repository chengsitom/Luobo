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
      appBar: AppBar(
        title: Text(l10n.playlists),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI 智能歌单',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AiPlaylistScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () => _showCreatePlaylistDialog(context),
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
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: libraryProvider.playlists.length,
              itemBuilder: (context, index) {
                final playlist = libraryProvider.playlists[index];
                return _PlaylistTile(
                  playlist: playlist,
                  onTap: () => _openPlaylist(context, playlist),
                  onLongPress: () => _showPlaylistOptions(context, playlist),
                  onMore: () => _showPlaylistOptions(context, playlist),
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
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: playlist.coverArt != null
            ? AlbumArtwork(
                coverArt: playlist.coverArt,
                size: 56,
                borderRadius: 8,
              )
            : const Icon(
                CupertinoIcons.music_note_list,
                color: AppTheme.appleMusicRed,
                size: 28,
              ),
      ),
      title: Text(
        playlist.name,
        style: theme.textTheme.bodyLarge,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        AppLocalizations.of(
          context,
        )!
            .songsCount(playlist.songCount ?? 0),
        style: theme.textTheme.bodySmall,
      ),
      trailing: GestureDetector(
        onTap: onMore,
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.darkSurface
                : AppTheme.lightBackground,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            AppIcons.moreV,
            size: 16,
            color: AppTheme.lightSecondaryText,
          ),
        ),
      ),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
