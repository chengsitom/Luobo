import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/playback_context_tracker.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';
import '../widgets/luobo/playlist_settings.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import '../theme/app_icons.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import '../utils/song_sort.dart';
import '../widgets/luobo/anchored_menu.dart';

class PlaylistScreen extends StatefulWidget {
  final String playlistId;
  final String? playlistName;

  const PlaylistScreen({
    super.key,
    required this.playlistId,
    this.playlistName,
  });

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  Playlist? _playlist;
  bool _isLoading = true;
  bool _isDownloading = false;
  bool _isReordering = false;

  // 歌单内排序（fnos v6_0060「共 N 首」行右侧有排序入口；本地排序，不改服务端）。
  SongSortField _sortField = SongSortField.title;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadPlaylist();
  }

  Future<void> _loadPlaylist() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      final playlist = await libraryProvider.getPlaylist(widget.playlistId);
      if (mounted) {
        setState(() {
          _playlist = playlist;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 歌单详情头部（C6，设计稿/11）：流体封面取色 + 上下暗渐变 + 居中标题/
  /// 「N 首 · 时长」+ 双白胶囊（▶播放 / ⤨随机）。随滚动上移消失（LuoboHeroAppBar）。
  /// 歌单详情头部（fnos v6_0060 帧实测版式）：
  /// **inset 封面卡**（左右 41dp、约 277×230dp，流体取色）→ 卡下居中标题 25 +
  /// 「N 首」→ 双胶囊（116×48、间距 12、居中，主题取反：浅色黑/深色白）→
  /// 「共 N 首」行（右：排序 + 多选）。整块随滚动上移，顶栏圆钮常驻。
  /// 歌单详情头部（共享组件 LuoboHeroCardHeader；fnos 帧实测版式）。
  Widget _buildHeroHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final coverArt = _playlist!.coverArt;
    final coverUrl = coverArt != null
        ? Provider.of<LibraryProvider>(context, listen: false)
            .getCoverArtUrl(coverArt)
        : null;

    return LuoboHeroCardHeader(
      title: _playlist!.name,
      subtitle: l10n.songsCountWithDuration(
        _playlist!.songs?.length ?? 0,
        _playlist!.formattedDuration,
      ),
      countLabel: l10n.songsCount(_playlist!.songs?.length ?? 0),
      card: FluidBackground(
        imageProvider: (coverUrl == null || coverUrl.isEmpty)
            ? null
            : CachedNetworkImageProvider(
                coverUrl,
                cacheManager: coverCacheManager,
                cacheKey: coverArtCacheKeyFromUrl(coverUrl),
              ),
        borderRadius: 16,
        seed: FluidBackground.seedForIndex(_playlist!.id.hashCode % 7),
      ),
      onPlay: () => _playAll(),
      onShuffle: () => _playAll(shuffle: true),
      onSort: () => _showSortMenu(_sortAnchorHero),
      sortAnchorKey: _sortAnchorHero,
      onMultiSelect: _toggleSelectMode,
    );
  }


  void _showPlaylistSettings() {
    final l10n = AppLocalizations.of(context)!;
    showPlaylistSettingsSheet(
      context,
      playlist: _playlist!,
      onDownload: () {
        if (!_isDownloading) _downloadPlaylist();
      },
      isDownloading: _isDownloading,
      onDelete: () async {
        final confirmed = await showLuoboConfirmSheet(
          context: context,
          title: l10n.deletePlaylist,
          message: l10n.deletePlaylistConfirmation(_playlist!.name),
          confirmLabel: l10n.delete,
        );
        if (confirmed == true && context.mounted) {
          final libraryProvider =
              Provider.of<LibraryProvider>(context, listen: false);
          await libraryProvider.deletePlaylist(widget.playlistId);
          if (context.mounted) Navigator.pop(context);
        }
      },
    );
  }


  void _playAll({bool shuffle = false}) {
    if (_playlist?.songs == null || _playlist!.songs!.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    var songs = List.from(_playlist!.songs!);
    if (shuffle) {
      songs.shuffle();
    }

    playerProvider.playSong(songs.first, playlist: songs.cast(), startIndex: 0);
    _recordPlayback();
  }

  /// 记录「最近播放的手动歌单」（首页最近播放混合区，§5.1）。
  void _recordPlayback() {
    final playlist = _playlist;
    if (playlist == null) return;
    Provider.of<PlaybackContextTracker>(context, listen: false).record(
      kind: 'playlist',
      id: playlist.id,
      name: playlist.name,
      coverArts: _collectionCovers(),
    );
  }

  List<String> _collectionCovers() {
    final songs = _playlist?.songs ?? const [];
    if (songs.isEmpty) return const [];
    final primary = _playlist?.coverArt;
    if (primary != null && primary.isNotEmpty) return [primary];
    final seen = <String>{};
    final out = <String>[];
    for (final song in songs) {
      final cover = song.coverArt;
      if (cover != null && cover.isNotEmpty && seen.add(cover)) {
        out.add(cover);
        if (out.length == 4) break;
      }
    }
    return out;
  }

  Future<void> _removeSongFromPlaylist(Song song) async {
    // 按 song.id 定位服务端原序下标，不能直接用展示下标——列表排序后展示顺序
    // ≠ _playlist!.songs 原序，拿展示下标去 updatePlaylist 会删错歌。
    final all = _playlist?.songs;
    if (all == null) return;
    final index = all.indexWhere((s) => s.id == song.id);
    if (index < 0) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [index],
      );
      setState(() {
        final updatedSongs = List<Song>.from(_playlist!.songs!)
          ..removeAt(index);
        _playlist = _playlist!.copyWith(
          songCount: updatedSongs.length,
          songs: updatedSongs,
        );
      });
      if (mounted) {
        showLuoboToast(
      context,
      message: l10n.songRemovedFromPlaylist,
      tone: LuoboToastTone.info,
    );
      }
    } catch (e) {
      if (mounted) {
        showLuoboToast(
      context,
      message: l10n.errorRemovingSong(e),
      tone: LuoboToastTone.info,
    );
      }
    }
  }

  /// 多选（fnos v1_0064：点击后弹**全屏 sheet**选择，不是页面内模式）。
  void _toggleSelectMode() {
    final songs = _displaySongs;
    if (songs.isEmpty) return;
    showMultiSelectSheet(
      context,
      songs: songs,
      onRemove: _removeSongsByObjects,
      removeLabel: AppLocalizations.of(context)!.removeFromPlaylist,
    );
  }

  void _toggleReorderMode() {
    setState(() {
      _isReordering = !_isReordering;
    });
  }

  Future<void> _onSongReordered(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      final updatedSongs = List<Song>.from(_playlist!.songs!);
      final song = updatedSongs.removeAt(oldIndex);
      updatedSongs.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, song);
      _playlist = _playlist!.copyWith(songs: updatedSongs);
    });

    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: [oldIndex],
        songIdsToAdd: [
          _playlist!.songs![newIndex > oldIndex ? newIndex - 1 : newIndex].id,
        ],
      );
    } catch (e) {
      if (mounted) {
        showLuoboToast(
      context,
      message: l10n.errorReorderingSong(e),
      tone: LuoboToastTone.info,
    );
      }
      _loadPlaylist();
    }
  }

  /// 从当前歌单移除一批歌（全屏多选弹窗的「移除」回调）：确认 → 按 index 移除。
  Future<void> _removeSongsByObjects(List<Song> songs) async {
    final all = _playlist?.songs;
    if (all == null || songs.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final ids = songs.map((s) => s.id).toSet();
    final indices = [
      for (var i = 0; i < all.length; i++)
        if (ids.contains(all[i].id)) i,
    ]..sort((a, b) => b.compareTo(a));
    if (indices.isEmpty) return;

    final confirmed = await showLuoboConfirmSheet(
      context: context,
      title: l10n.removeSongs,
      message: l10n.removeSongsConfirm(indices.length),
      confirmLabel: l10n.remove,
    );
    if (confirmed != true || !mounted) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      await subsonicService.updatePlaylist(
        playlistId: widget.playlistId,
        songIndexesToRemove: indices,
      );
      await _loadPlaylist();
      if (mounted) {
        showLuoboToast(
          context,
          message: l10n.songRemovedFromPlaylist,
          tone: LuoboToastTone.success,
        );
      }
    } catch (e) {
      if (mounted) {
        showLuoboToast(
          context,
          message: l10n.errorRemovingSong(e),
          tone: LuoboToastTone.error,
        );
      }
    }
  }

  /// 普通列表分支的展示顺序（排序后）。
  List<Song> get _displaySongs {
    final songs = _playlist?.songs;
    if (songs == null || songs.length < 2) return songs ?? [];
    return sortSongs(songs, _sortField, ascending: _sortAscending);
  }

  /// 头图「共 N 首」行右侧排序入口的锚点（fnos v6_0060 有排序）。
  final _sortAnchorHero = GlobalKey();

  Future<void> _showSortMenu(GlobalKey anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final field = await showLuoboAnchoredMenu<SongSortField>(
      context: context,
      anchorKey: anchor,
      selected: _sortField,
      items: [
        for (final f in SongSortField.values)
          LuoboAnchoredMenuItem(
            value: f,
            label: _fieldLabel(l10n, f),
            trailing: (f == _sortField && songSortShowsDirection(f))
                ? Icon(
                    _sortAscending ? AppIcons.arrowUp : AppIcons.arrowDown,
                    size: 15,
                    color: LuoboAccent.accent,
                  )
                : null,
          ),
      ],
    );
    if (field == null || !mounted) return;
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  String _fieldLabel(AppLocalizations l10n, SongSortField field) {
    switch (field) {
      case SongSortField.title:
        return l10n.sortFieldTitle;
      case SongSortField.artist:
        return l10n.artists;
      case SongSortField.album:
        return l10n.albums;
      case SongSortField.recentlyAdded:
        return l10n.recentlyAdded;
    }
  }


  Future<void> _downloadPlaylist() async {
    final songs = _playlist?.songs;
    if (songs == null || songs.isEmpty) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final offlineService = OfflineService();
    await offlineService.initialize();
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isDownloading = true);

    offlineService.startBackgroundDownload(songs, subsonicService).then((_) {
      if (mounted) {
        setState(() => _isDownloading = false);
        showLuoboToast(
      context,
      message: l10n.downloadedSongsFrom(songs.length, _playlist!.name),
      tone: LuoboToastTone.info,
    );
      }
    });

    if (mounted) {
      showLuoboToast(
      context,
      message: l10n.downloadingSongsInBackground(songs.length),
      tone: LuoboToastTone.info,
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title:
              widget.playlistName != null ? Text(widget.playlistName!) : null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_playlist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(l10n.playlistNotFound)),
      );
    }

    if (_isReordering) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.reorderSongs),
          leading: IconButton(
            icon: const Icon(CupertinoIcons.xmark),
            onPressed: _toggleReorderMode,
          ),
          actions: [
            IconButton(
              tooltip: l10n.doneReordering,
              icon: const Icon(CupertinoIcons.checkmark),
              onPressed: _toggleReorderMode,
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _playlist!.coverArt != null
                        ? AlbumArtwork(
                            coverArt: _playlist!.coverArt,
                            size: 150,
                            borderRadius: 12,
                          )
                        : const Icon(
                            CupertinoIcons.music_note_list,
                            color: AppTheme.appleMusicRed,
                            size: 64,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _playlist!.name,
                    style: theme.textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.songsCountWithDuration(
                      _playlist!.songs?.length ?? 0,
                      _playlist!.formattedDuration,
                    ),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.play_fill,
                          label: AppLocalizations.of(context)!.play,
                          onTap: () => _playAll(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PlayButton(
                          icon: CupertinoIcons.shuffle,
                          label: AppLocalizations.of(context)!.shuffle,
                          onTap: () => _playAll(shuffle: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ReorderableListView.builder(
                padding: EdgeInsets.only(
                  bottom: LuoboSpacing.pageBottomWithStrip(context),
                ),
                itemCount: _playlist!.songs!.length,
                buildDefaultDragHandles: false,
                onReorder: _onSongReordered,
                itemBuilder: (context, index) {
                  final song = _playlist!.songs![index];
                  return ListTile(
                    key: ValueKey('reorder_${song.id}_$index'),
                    leading: ReorderableDragStartListener(
                      index: index,
                      child: Icon(
                        CupertinoIcons.line_horizontal_3,
                        color: isDark
                            ? AppTheme.darkSecondaryText
                            : AppTheme.lightSecondaryText,
                      ),
                    ),
                    title: Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      song.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeroHeader(context)),
          const SliverToBoxAdapter(child: Divider()),
          if (_playlist!.songs?.isEmpty ?? true)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    l10n.noSongsInPlaylist,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.lightSecondaryText,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final songs = _displaySongs;
                  final song = songs[index];
                  final tile = SongTile(
                    song: song,
                    playlist: songs,
                    index: index,
                    showArtist: true,
                    
                    // ⋮ 菜单变体 C（设计稿/09）：歌单内 = 横排 + 收藏 + 从当前歌单移除。
                    menuContext: SongMenuContext.playlist,
                    onRemoveFromPlaylist: () {
                      _removeSongFromPlaylist(song);
                    },
                    // 逐首播放也记录「最近播放的歌单」。
                    onTap: () {
                      _recordPlayback();
                      // 队列必须用展示顺序 songs（= _displaySongs，可能已排序），
                      // 而不是服务端原序 _playlist!.songs——否则 startIndex(展示位)
                      // 落到原序列表上会指向另一首歌，底栏显示选中歌、实际播放却是
                      // 另一首（排序开启时必现）。
                      Provider.of<PlayerProvider>(context, listen: false)
                          .playSong(
                        song,
                        playlist: songs,
                        startIndex: index,
                      );
                    },
                    onLongPress: _toggleSelectMode,
                  );
                  return Dismissible(
                    key: ValueKey('${song.id}_$index'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(
                        CupertinoIcons.trash,
                        color: Colors.white,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showLuoboConfirmSheet(
                            context: context,
                            title: l10n.removeFromPlaylist,
                            message: l10n.removeSongFromPlaylistConfirm(
                              song.title,
                            ),
                            confirmLabel: l10n.remove,
                          ) ??
                          false;
                    },
                    onDismissed: (_) => _removeSongFromPlaylist(song),
                    child: Column(
                      children: [
                        tile,
                        // 行间分隔线（fnos v6_0060 实测：左右各缩 16dp，
                        // 行高 64dp）。
                        if (index < _playlist!.songs!.length - 1)
                          const LuoboSongDivider(),
                      ],
                    ),
                  );
                },
                childCount: _playlist!.songs!.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: LuoboSpacing.pageBottomWithStrip(context))),
        ],
      ),
          // 悬浮顶栏（圆返回 + 圆⋮；滚动时常驻、无实色栏——帧实测）。
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    LuoboTopCircleButton(
                      icon: AppIcons.back,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    LuoboTopCircleButton(
                      icon: AppIcons.moreV,
                      onTap: _showPlaylistSettings,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
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
