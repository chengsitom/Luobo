import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/playback_context_tracker.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/song_sort.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/song_tile.dart';

/// 收藏页 —— **只列收藏的歌曲**（2026-10-08 拍板：砍掉「专辑」tab）。
///
/// 2026-10-22：整页重构为**与歌单详情同款**（用户：「收藏页面和歌单应该是一样的
/// 样式」）——共享 `LuoboHeroCardHeader`（inset 流体卡 + 居中标题 + 双胶囊 +
/// 共 N 首/排序/多选）+ 同款歌曲行与分隔线（`LuoboSongDivider`，左端 76）。
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Song> _favoriteSongs = [];
  bool _isLoading = true;

  // 排序（与歌单详情同款：标题/歌手/最近添加 + 方向）。
  SongSortField _sortField = SongSortField.title;
  bool _sortAscending = true;
  final _sortAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final starred = await subsonicService.getStarred();
      if (mounted) {
        setState(() {
          _favoriteSongs = starred.songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Song> get _displaySongs {
    if (_favoriteSongs.length < 2) return _favoriteSongs;
    return sortSongs(_favoriteSongs, _sortField, ascending: _sortAscending);
  }

  void _playAll({bool shuffle = false}) {
    if (_favoriteSongs.isEmpty) return;
    var songs = List<Song>.from(_displaySongs);
    if (shuffle) songs.shuffle();
    Provider.of<PlayerProvider>(context, listen: false)
        .playSong(songs.first, playlist: songs, startIndex: 0);
    _recordPlayback();
  }

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

  /// 多选（fnos：全屏弹窗；收藏的「移除」= 取消收藏）。
  void _openMultiSelect() {
    final songs = _displaySongs;
    if (songs.isEmpty) return;
    showMultiSelectSheet(
      context,
      songs: songs,
      onRemove: _unstarSongs,
      removeLabel: AppLocalizations.of(context)!.removeFromFavorites,
    );
  }

  Future<void> _unstarSongs(List<Song> songs) async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;
    var ok = 0;
    for (final song in songs) {
      try {
        await libraryProvider.unstar(songId: song.id);
        ok++;
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      final ids = songs.map((s) => s.id).toSet();
      _favoriteSongs.removeWhere((s) => ids.contains(s.id));
    });
    showLuoboToast(
      context,
      message: l10n.removedFromFavorites,
      tone: ok > 0 ? LuoboToastTone.success : LuoboToastTone.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(l10n)),
                    if (_favoriteSongs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: LuoboEmptyState(message: l10n.noFavoriteSongs),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final songs = _displaySongs;
                            final song = songs[index];
                            return Column(
                              children: [
                                SongTile(
                                  song: song,
                                  playlist: songs,
                                  index: index,
                                  showArtist: true,
                                  // 逐首播放也记录「最近播放的收藏列表」。
                                  onTap: () {
                                    _recordPlayback();
                                    Provider.of<PlayerProvider>(
                                      context,
                                      listen: false,
                                    ).playSong(
                                      song,
                                      playlist: songs,
                                      startIndex: index,
                                    );
                                  },
                                ),
                                if (index < songs.length - 1)
                                  const LuoboSongDivider(),
                              ],
                            );
                          },
                          childCount: _favoriteSongs.length,
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: LuoboSpacing.pageBottomWithStrip(context))),
                  ],
                ),
                // 悬浮顶栏（圆返回；滚动常驻、无实色栏）。
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
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return LuoboHeroCardHeader(
      title: l10n.favorites,
      subtitle: l10n.songsCount(_favoriteSongs.length),
      countLabel: l10n.songsCount(_favoriteSongs.length),
      // 收藏无封面 → 流体用暖色盘 + 中央心形（fnos 收藏页同构：渐变+心形）。
      card: Stack(
        fit: StackFit.expand,
        children: [
          const FluidBackground(
            colors: [Color(0xFFFF7A3C), Color(0xFFF93D4E), Color(0xFFFFB03A)],
            borderRadius: 16,
            seed: 1.2,
          ),
          Center(
            child: Icon(
              AppIcons.heartFilled,
              size: 72,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      onPlay: () => _playAll(),
      onShuffle: () => _playAll(shuffle: true),
      onSort: () => _showSortMenu(_sortAnchor),
      sortAnchorKey: _sortAnchor,
      onMultiSelect: _openMultiSelect,
    );
  }

  /// 记录「最近播放的收藏列表」（首页最近播放混合区，§5.1）。
  void _recordPlayback() {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<PlaybackContextTracker>(context, listen: false).record(
      kind: 'starred',
      id: 'starred',
      name: l10n.favorites,
      coverArts: _favoriteCovers(),
    );
  }

  List<String> _favoriteCovers() {
    final seen = <String>{};
    final out = <String>[];
    for (final song in _favoriteSongs) {
      final cover = song.coverArt;
      if (cover != null && cover.isNotEmpty && seen.add(cover)) {
        out.add(cover);
        if (out.length == 4) break;
      }
    }
    return out;
  }
}