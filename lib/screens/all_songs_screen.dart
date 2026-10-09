import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../models/models.dart';
import '../utils/song_sort.dart';
import '../widgets/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../l10n/app_localizations.dart';

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  List<Song> _songs = [];
  List<Song> _sortedSongs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  SongSortField _sortField = SongSortField.title;
  bool _sortAscending = true;

  /// 锚定菜单的锚点：AppBar 的排序钮 / 头部那行「排序」各一个
  /// （点哪个就锚在哪个上）。
  final _sortAnchorAppBar = GlobalKey();
  final _sortAnchorHeader = GlobalKey();
  LibraryProvider? _libraryProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCachedData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _libraryProvider?.removeListener(_onLibraryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  void _onLibraryChanged() {
    if (!mounted) return;
    final provider = _libraryProvider;
    if (provider == null) return;
    final songs = provider.cachedAllSongs;
    if (songs.length != _songs.length || songs.isEmpty != _songs.isEmpty) {
      setState(() {
        _songs = songs;
        _sortSongs();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedData() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    _libraryProvider = libraryProvider;
    libraryProvider.addListener(_onLibraryChanged);

    // Returns immediately when the cache is empty; the background sync
    // notifies this screen via _onLibraryChanged when data is ready.
    await libraryProvider.ensureLibraryLoaded();

    if (mounted) {
      setState(() {
        _songs = libraryProvider.cachedAllSongs;
        _sortSongs();
        _isLoading = false;
      });
    }
  }

  void _sortSongs() {
    _sortedSongs = sortSongs(_songs, _sortField, ascending: _sortAscending);
  }

  bool _showsDirection(SongSortField field) => songSortShowsDirection(field);

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

  /// 锚定毛玻璃菜单（设计稿 §2.3 范式①；实测规格见
  /// `docs/锚定浮层与列表页排序技术方案.md` §2）。
  ///
  /// 交互：点**已选中**字段 = 翻转方向；点**其它**字段 = 切换字段（保持方向）。
  Future<void> _showSortOptions(GlobalKey anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboAnchoredMenu<SongSortField>(
      context: context,
      anchorKey: anchor,
      selected: _sortField,
      items: [
        for (final field in SongSortField.values)
          LuoboAnchoredMenuItem(
            value: field,
            label: _fieldLabel(l10n, field),
            // 方向箭头**只在选中项**上出现（未选中项什么都不带）。
            trailing: (field == _sortField && _showsDirection(field))
                ? Icon(
                    _sortAscending ? AppIcons.arrowUp : AppIcons.arrowDown,
                    size: 15,
                    color: LuoboAccent.accent,
                  )
                : null,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == _sortField) {
        if (_showsDirection(picked)) _sortAscending = !_sortAscending;
      } else {
        _sortField = picked;
      }
    });
    _sortSongs();
  }

  void _playAll({bool shuffle = false}) {
    if (_sortedSongs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    List<Song> playlist = List.from(_sortedSongs);
    if (shuffle) {
      playlist.shuffle();
    }

    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  String _getSortLabel() =>
      _fieldLabel(AppLocalizations.of(context)!, _sortField);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.allSongs),
        actions: [
          if (_sortedSongs.isNotEmpty)
            IconButton(
              key: _sortAnchorAppBar,
              icon: const Icon(Icons.sort_rounded),
              onPressed: () => _showSortOptions(_sortAnchorAppBar),
              tooltip: l10n.sortBy,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noSongsFound,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.songsCount(_sortedSongs.length),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                GestureDetector(
                                  key: _sortAnchorHeader,
                                  onTap: () =>
                                      _showSortOptions(_sortAnchorHeader),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.sort_rounded,
                                        size: 14,
                                        color: AppTheme.appleMusicRed,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _getSortLabel(),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.appleMusicRed,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      // 方向外显（原先被写进了文案，如「标题（A-Z）」）
                                      if (_showsDirection(_sortField)) ...[
                                        const SizedBox(width: 3),
                                        Icon(
                                          _sortAscending
                                              ? AppIcons.arrowUp
                                              : AppIcons.arrowDown,
                                          size: 13,
                                          color: AppTheme.appleMusicRed,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _playAll(shuffle: true),
                            icon: Icon(
                              Icons.shuffle_rounded,
                              color: isDark ? Colors.white70 : Colors.black54,
                              size: 28,
                            ),
                            tooltip: l10n.shuffle,
                          ),
                          const SizedBox(width: 8),
                          Consumer<PlayerProvider>(
                            builder: (context, playerProvider, _) {
                              final isCurrentPlaylist =
                                  playerProvider.queue.isNotEmpty &&
                                      playerProvider.queue.any(
                                        (song) => _sortedSongs
                                            .any((s) => s.id == song.id),
                                      );
                              final isPlaying =
                                  isCurrentPlaylist && playerProvider.isPlaying;

                              return GestureDetector(
                                onTap: () {
                                  if (isCurrentPlaylist &&
                                      playerProvider.currentSong != null) {
                                    if (playerProvider.isPlaying) {
                                      playerProvider.pause();
                                    } else {
                                      playerProvider.play();
                                    }
                                  } else {
                                    _playAll();
                                  }
                                },
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppTheme.appleMusicRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppTheme.appleMusicRed.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _sortedSongs.length,
                        itemBuilder: (context, index) {
                          return SongTile(
                            song: _sortedSongs[index],
                            playlist: _sortedSongs,
                            index: index,
                            showAlbum: true,
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
