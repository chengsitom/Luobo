import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../widgets/widgets.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../l10n/app_localizations.dart';
import '../services/offline_service.dart';

class AlbumScreen extends StatefulWidget {
  final String albumId;

  const AlbumScreen({super.key, required this.albumId});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  Album? _album;
  List<Song> _songs = [];
  bool _isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _loadAlbum();
  }

  Future<void> _loadAlbum() async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      Album? album;

      if (libraryProvider.isLocalOnlyMode) {
        album = libraryProvider.cachedAllAlbums.firstWhere(
          (a) => a.id == widget.albumId,
          orElse: () => Album(id: widget.albumId, name: 'Unknown Album'),
        );
      } else {
        album = await subsonicService.getAlbum(widget.albumId);
      }

      final songs = await libraryProvider.getAlbumSongs(widget.albumId);

      if (mounted) {
        setState(() {
          _album = album;
          _songs = songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// 多选（fnos：全屏弹窗）。
  void _openMultiSelect() {
    if (_songs.isEmpty) return;
    showMultiSelectSheet(context, songs: _songs);
  }

  void _playAll({bool shuffle = false}) {
    if (_songs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    List<Song> playlist = List.from(_songs);
    if (shuffle) {
      playlist.shuffle();
    }

    playerProvider.playSong(playlist.first, playlist: playlist, startIndex: 0);
  }

  Future<void> _downloadAlbum() async {
    if (_songs.isEmpty) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final offlineService = OfflineService();
    await offlineService.initialize();
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isDownloading = true);

    offlineService.startBackgroundDownload(_songs, subsonicService).then((_) {
      if (mounted) {
        setState(() => _isDownloading = false);
        showLuoboToast(
      context,
      message: l10n.downloadedSongsFrom(_songs.length, _album!.name),
      tone: LuoboToastTone.info,
    );
      }
    });

    if (mounted) {
      showLuoboToast(
      context,
      message: l10n.downloadingSongsInBackground(_songs.length),
      tone: LuoboToastTone.info,
    );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const AlbumArtworkShimmer(size: 250),
                    const SizedBox(height: 24),
                    Shimmer.fromColors(
                      baseColor:
                          isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 200,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Shimmer.fromColors(
                      baseColor:
                          isDark ? AppTheme.darkCard : const Color(0xFFE0E0E0),
                      highlightColor: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF5F5F5),
                      child: Container(
                        width: 150,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => const SongTileShimmer(),
                childCount: 10,
              ),
            ),
          ],
        ),
      );
    }

    if (_album == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(AppLocalizations.of(context)!.albumNotFound)),
      );
    }


    final isOffline = Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 头部（fnos 专辑详情：**保留专辑封面**；与歌单/收藏同款骨架）。
              SliverToBoxAdapter(
                child: LuoboHeroCardHeader(
                  title: _album!.name,
                  subtitle: [
                    _album!.artist ?? AppLocalizations.of(context)!.unknownArtist,
                    if (_album!.year != null) _album!.year.toString(),
                  ].join(' · '),
                  countLabel: AppLocalizations.of(context)!.songsCount(
                    _songs.length,
                  ),
                  card: Center(
                    child: AlbumArtwork(
                      coverArt: _album!.coverArt,
                      size: 230,
                      borderRadius: 12,
                      preserveAspectRatio: true,
                    ),
                  ),
                  onPlay: () => _playAll(),
                  onShuffle: () => _playAll(shuffle: true),
                  onMultiSelect: _openMultiSelect,
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final song = _songs[index];
                  return Column(
                    children: [
                      SongTile(
                        song: song,
                        playlist: _songs,
                        index: index,
                        showArtwork: false,
                        showTrackNumber: true,
                        showArtist: false,
                      ),
                      // 序号行分隔线：左缩 42 对到歌名（设计稿/08 §3）。
                      if (index < _songs.length - 1)
                        const LuoboSongDivider(indent: 42),
                    ],
                  );
                }, childCount: _songs.length),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          // 悬浮顶栏（圆返回 + 下载；滚动常驻、无实色栏，同歌单/收藏）。
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
                    if (!isOffline)
                      LuoboTopCircleButton(
                        icon: Icons.download_rounded,
                        onTap: _isDownloading ? () {} : _downloadAlbum,
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
