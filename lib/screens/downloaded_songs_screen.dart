import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/download_record.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../services/offline_service.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/byte_format.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/song_tile.dart';

/// 「已下载」列表页：浏览、播放、删除本地已下载的歌曲。
///
/// 数据源是 [OfflineService] 的下载记录表（本地，零网络）；记录里已存完整
/// [Song] 元数据，因此断网也能渲染。封面路径替换成本地文件绝对路径，
/// 走 AlbumArtwork 已有的 isLocalFilePath 分支，离线照样显示。
class DownloadedSongsScreen extends StatefulWidget {
  const DownloadedSongsScreen({super.key});

  @override
  State<DownloadedSongsScreen> createState() => _DownloadedSongsScreenState();
}

enum _SortMode { downloadedAt, title, artist }

class _DownloadedSongsScreenState extends State<DownloadedSongsScreen> {
  final _offline = OfflineService();
  List<DownloadRecord> _records = [];
  bool _isLoading = true;
  _SortMode _sortMode = _SortMode.downloadedAt;
  bool _ascending = false; // 最近下载默认倒序
  final _sortAnchor = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _offline.initialize();
    if (!mounted) return;
    final serverId = context.read<SubsonicService>().coverCacheServerId;
    setState(() {
      _records = _offline.getDownloadRecords(serverId: serverId);
      _isLoading = false;
    });
  }

  List<DownloadRecord> get _sortedRecords {
    final list = List<DownloadRecord>.from(_records);
    list.sort((a, b) {
      int cmp;
      switch (_sortMode) {
        case _SortMode.downloadedAt:
          cmp = a.downloadedAt.compareTo(b.downloadedAt);
        case _SortMode.title:
          cmp = a.song.title.compareTo(b.song.title);
        case _SortMode.artist:
          cmp = (a.song.artist ?? '').compareTo(b.song.artist ?? '');
      }
      return _ascending ? cmp : -cmp;
    });
    return list;
  }

  List<Song> get _displaySongs {
    return _sortedRecords.map((record) {
      final localCover = _offline.getLocalCoverArtPath(record.songId);
      // coverArt 塞本地绝对路径 → AlbumArtwork 走 Image.file 分支，离线可见。
      return localCover != null
          ? record.song.copyWith(coverArt: localCover)
          : record.song;
    }).toList();
  }

  int get _totalBytes => _records.fold(0, (sum, r) => sum + r.bytes);

  void _playAll({bool shuffle = false}) {
    final songs = _displaySongs;
    if (songs.isEmpty) return;
    final playList = List<Song>.from(songs);
    if (shuffle) playList.shuffle();
    context.read<PlayerProvider>().playSong(
          playList.first,
          playlist: playList,
          startIndex: 0,
        );
  }

  Future<void> _showSortMenu() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboAnchoredMenu<_SortMode>(
      context: context,
      anchorKey: _sortAnchor,
      selected: _sortMode,
      items: [
        LuoboAnchoredMenuItem(
          value: _SortMode.downloadedAt,
          label: l10n.sortDownloadedAt,
        ),
        LuoboAnchoredMenuItem(
          value: _SortMode.title,
          label: l10n.sortFieldTitle,
        ),
        LuoboAnchoredMenuItem(
          value: _SortMode.artist,
          label: l10n.artists,
        ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (_sortMode == picked) {
        _ascending = !_ascending;
      } else {
        _sortMode = picked;
        _ascending = picked != _SortMode.downloadedAt;
      }
    });
  }

  void _openMultiSelect() {
    final songs = _displaySongs;
    if (songs.isEmpty) return;
    showMultiSelectSheet(
      context,
      songs: songs,
      onRemove: _deleteSongs,
      removeLabel: AppLocalizations.of(context)!.removeDownload,
    );
  }

  Future<void> _deleteSongs(List<Song> songs) async {
    for (final song in songs) {
      await _offline.deleteSong(song.id);
    }
    if (!mounted) return;
    setState(() {
      final ids = songs.map((s) => s.id).toSet();
      _records.removeWhere((r) => ids.contains(r.songId));
    });
    showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.downloadsDeleted,
      tone: LuoboToastTone.success,
    );
  }

  /// 单曲菜单里的「已下载 → 删除」走的是 SongTile ⋮ 自带逻辑；
  /// 这里通过监听下载记录变化刷新页面（删除后返回本页时 _load 重跑）。
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final songs = _displaySongs;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(l10n)),
                    if (songs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: LuoboEmptyState(
                          message: l10n.noDownloadedSongs,
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return Column(
                              children: [
                                SongTile(
                                  song: songs[index],
                                  playlist: songs,
                                  index: index,
                                  showArtist: true,
                                  showDownloadBadge: false,
                                  onTap: () => context.read<PlayerProvider>().playSong(
                                        songs[index],
                                        playlist: songs,
                                        startIndex: index,
                                      ),
                                ),
                                if (index < songs.length - 1)
                                  const LuoboSongDivider(),
                              ],
                            );
                          },
                          childCount: songs.length,
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: LuoboSpacing.pageBottomWithStrip(context),
                      ),
                    ),
                  ],
                ),
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
      title: l10n.downloadedSongs,
      subtitle: l10n.downloadedSubtitle,
      countLabel: l10n.songsCount(_records.length),
      card: Stack(
        fit: StackFit.expand,
        children: [
          const FluidBackground(
            colors: [Color(0xFF3CC98A), Color(0xFF0E9F8E), Color(0xFF4A7DFF)],
            borderRadius: 16,
            seed: 2.3,
          ),
          Center(
            child: Icon(
              AppIcons.storage,
              size: 72,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Text(
              l10n.downloadedSize(formatBytes(_totalBytes)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      onPlay: () => _playAll(),
      onShuffle: () => _playAll(shuffle: true),
      onSort: _showSortMenu,
      sortAnchorKey: _sortAnchor,
      onMultiSelect: _openMultiSelect,
    );
  }
}
