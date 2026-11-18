import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/sheet_shell.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/transcoding_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/widgets.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../l10n/app_localizations.dart';
import '../services/blocklist_service.dart';
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
    if (_songs.isEmpty || _isDownloading) return;

    final l10n = AppLocalizations.of(context)!;
    // 仅 Wi-Fi 下载：批量下载耗流量，蜂窝下按用户设置拦截。
    // 网络类型在 await 之前读，避免 async gap 后用 context。
    final isMobile = context.read<TranscodingService>().currentConnectionType !=
        ConnectionType.wifi;
    final offline = OfflineService();
    await offline.initialize();
    if (!mounted) return;
    if (offline.getWifiOnly() && isMobile) {
      showLuoboToast(
        context,
        message: l10n.downloadWifiOnlyBlocked,
        tone: LuoboToastTone.info,
      );
      return;
    }

    // 确认后再下：整张专辑的下载不可忽略、且按钮就在返回钮下面，容易误触。
    final confirmed = await showLuoboConfirmSheet(
      context: context,
      title: l10n.downloadAlbumConfirmTitle,
      message: l10n.downloadAlbumConfirmBody(_album!.name, _songs.length),
      confirmLabel: l10n.download,
    );
    if (confirmed != true || !mounted) return;

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    setState(() => _isDownloading = true);

    // 进度与结果提示由全局 DownloadProgressOverlay 统一负责（进度卡 + 终态卡），
    // 这里只管本页按钮的 loading 态，避免两套提示重复弹。
    offline.startBackgroundDownload(_songs, subsonicService).then((_) {
      if (mounted) setState(() => _isDownloading = false);
    });
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

    // 彻底屏蔽的专辑正常入口都已过滤，只剩"从播放队列点进来"能到这儿。
    if (BlocklistService.instance.isAlbumHidden(_album!.id)) {
      return Scaffold(
        appBar: AppBar(),
        body: BlockedPlaceholder(
          onUnblock: () async {
            await BlocklistService.instance
                .unblock(BlockKind.album, _album!.id);
            if (mounted) setState(() {});
          },
        ),
      );
    }

    final isOffline = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).isLocalPlaybackSession;

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
                    _album!.artist ??
                        AppLocalizations.of(context)!.unknownArtist,
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
              SliverToBoxAdapter(
                  child: SizedBox(
                      height: LuoboSpacing.pageBottomWithStrip(context))),
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
                    const SizedBox(width: 8),
                    // 屏蔽入口：一个弹窗两档强度（彻底屏蔽 / 仅从漫游排除）。
                    LuoboTopCircleButton(
                      icon: Icons.block_rounded,
                      onTap: () => showBlockSheet(
                        context,
                        kind: BlockKind.album,
                        targetId: _album!.id,
                        name: _album!.name,
                      ),
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
