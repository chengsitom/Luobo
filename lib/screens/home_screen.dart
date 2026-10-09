import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../utils/refresh_feedback.dart';
import '../utils/image_cache.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'playlist_screen.dart';
import 'history_screen.dart';
import '../l10n/app_localizations.dart';
import 'package:easy_refresh/easy_refresh.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, List<Song>> _cachedMixes = const {};
  List<Song> _cachedPersonalized = const [];
  String _lastRandomKey = '';

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppLocalizations.of(context)!.goodMorning;
    if (hour < 17) return AppLocalizations.of(context)!.goodAfternoon;
    return AppLocalizations.of(context)!.goodEvening;
  }

  String _computeRandomKey(List<Song> songs) {
    if (songs.isEmpty) return '';

    return songs.map((s) => s.id).join('|');
  }

  String _localizeVibesTitle(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context)!;
    if (key.startsWith('Morning')) return l10n.morningVibes;
    if (key.startsWith('Afternoon')) return l10n.afternoonVibes;
    if (key.startsWith('Evening')) return l10n.eveningVibes;
    if (key.startsWith('Night')) return l10n.nightVibes;
    return key;
  }

  void _showSectionsHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.3,
        maxChildSize: 0.92,
        snap: true,
        snapSizes: const [0.85],
        expand: false,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '首页推荐说明',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '所有推荐基于你的播放历史自动生成',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.black.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 20),
            _helpItem(
              icon: Icons.stars_rounded,
              title: '为你推荐',
              desc: '从整个曲库中按综合评分挑选，每次刷新结果不同。',
              isDark: isDark,
            ),
            _helpItem(
              icon: Icons.bolt_rounded,
              title: '快速选择',
              desc: '只从你最常听的歌手和风格中选歌，且排除最近听过的，适合随手播放。',
              isDark: isDark,
            ),
            _helpItem(
              icon: Icons.explore_rounded,
              title: '发现混音',
              desc: '在你喜欢的风格中推荐你没听过的歌手，帮你发现新音乐。',
              isDark: isDark,
            ),
            _helpItem(
              icon: Icons.album_rounded,
              title: '歌手 Mix',
              desc: '你播放最多的歌手会各生成一个专属 Mix，按喜好程度排序。',
              isDark: isDark,
            ),
            _helpItem(
              icon: Icons.album_rounded,
              title: '风格 Mix',
              desc: '你最常听的音乐风格（如国语流行、电子等）会生成对应 Mix。',
              isDark: isDark,
            ),
            _helpItem(
              icon: Icons.nightlight_round,
              title: '时段推荐',
              desc: '根据你在不同时间段的听歌习惯推荐，早上/下午/晚上/深夜各不同。',
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            Divider(color: isDark ? Colors.white12 : Colors.black12),
            const SizedBox(height: 12),
            Text(
              '推荐算法详解',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            _detailParagraph(
              '评分机制',
              '每首歌会根据多项指标计算综合评分：歌手亲和度(28%)、'
                  '是否收藏(20%)、风格亲和度(18%)、歌手评分(11%)、'
                  '用户评分(10%)、完播率(9%)、风格评分(7%)、播放次数(4%)、'
                  '时段匹配(5%)。跳过歌曲会扣分，最近播放过的歌曲也会降权，'
                  '从未播放的新歌有额外加成。',
              isDark: isDark,
            ),
            _detailParagraph(
              '为你推荐 vs 快速选择',
              '「为你推荐」从全部曲库中选歌，随机性较高，可能包含最近听过的歌；'
                  '「快速选择」只从你 Top 5 歌手和 Top 4 风格中选歌，'
                  '严格排除最近 10 首播放记录，结果更稳定。',
              isDark: isDark,
            ),
            _detailParagraph(
              '发现混音的分层逻辑',
              '优先推荐：你喜欢的风格中、你没听过的新歌手的歌曲；'
                  '其次：你喜欢的风格中任何没听过的歌；'
                  '最后：曲库中任何你没听过的歌。'
                  '核心目的是在熟悉的风格中帮你发现新歌手。',
              isDark: isDark,
            ),
            _detailParagraph(
              'Mix 生成规则',
              '歌手 Mix 取播放量前 3 的歌手各生成一个；'
                  '风格 Mix 取前 2 的风格各生成一个；'
                  '时段推荐分析你在当前时段最常听的风格生成。'
                  '所有 Mix 至少需要 5 首歌才会显示。',
              isDark: isDark,
            ),
            _detailParagraph(
              '数据来源',
              '所有推荐完全基于本地播放历史计算，不依赖任何云端服务。'
                  '你的播放、跳过、收藏、评分行为都会影响推荐结果。'
                  '历史数据有 30 天衰减周期，最近的行为权重更高。',
              isDark: isDark,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailParagraph(String title, String content,
      {required bool isDark}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color:
                  isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String desc,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.appleMusicRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = _isDesktop;
    final hPad = isDesktop ? 32.0 : 16.0;

    return Scaffold(
      body: EasyRefresh.builder(
        header: ClassicHeader(
          dragText: '下拉刷新',
          armedText: '释放刷新',
          readyText: '正在刷新...',
          processingText: '正在刷新...',
          processedText: '刷新完成',
          messageText: '上次更新于 %T',
          iconTheme: IconThemeData(
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          showMessage: false,
          // Trigger after only 60 px of overscroll so it fires easily
          triggerOffset: 60,
          // Render below the pinned SliverAppBar via HeaderLocator.sliver()
          // instead of above the whole viewport (which would overlap the
          // pinned nav bar).
          position: IndicatorPosition.locator,
        ),
        onRefresh: _handleRefresh,
        childBuilder: (context, physics) => CustomScrollView(
          physics: physics,
          slivers: [
            SliverAppBar(
              pinned: true,
              floating: true,
              expandedHeight: isDesktop ? 80 : 70,
              backgroundColor: isDark ? AppTheme.darkBackground : Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsets.only(left: hPad, bottom: 14),
                title: Text(
                  _getGreeting(),
                  style: TextStyle(
                    fontSize: isDesktop ? 28 : 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.info_outline_rounded,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () => _showSectionsHelp(context),
                ),
                IconButton(
                  icon: Icon(
                    Icons.history_rounded,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    NavigationHelper.push(context, const HistoryScreen());
                  },
                ),
                if (isDesktop) const SizedBox(width: 8),
              ],
            ),
            const HeaderLocator.sliver(),
            SliverToBoxAdapter(
              child: Consumer2<LibraryProvider, RecommendationService>(
                builder: (context, libraryProvider, recommendationService, _) {
                  if (libraryProvider.isLoading &&
                      !libraryProvider.isInitialized) {
                    return _buildLoadingState(isDesktop, hPad);
                  }

                  final allSongs = libraryProvider.randomSongs;
                  final key = _computeRandomKey(allSongs);

                  if (recommendationService.enabled && key.isNotEmpty) {
                    if (key != _lastRandomKey) {
                      _cachedMixes = recommendationService.generateMixes(
                        allSongs,
                      );
                      _cachedPersonalized = recommendationService
                          .getPersonalizedFeed(allSongs, limit: 10);
                      _lastRandomKey = key;
                    }
                  } else {
                    _cachedMixes = const {};
                    _cachedPersonalized = const [];
                    _lastRandomKey = '';
                  }

                  final mixes = _cachedMixes;
                  final personalizedFeed = _cachedPersonalized;

                  return Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: isDesktop ? 0 : 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (libraryProvider.recentAlbums.isNotEmpty ||
                            libraryProvider.playlists.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _QuickAccessGrid(
                            albums: libraryProvider.recentAlbums
                                .take(isDesktop ? 6 : 4)
                                .toList(),
                            playlists: libraryProvider.playlists
                                .take(isDesktop ? 3 : 2)
                                .toList(),
                            isDesktop: isDesktop,
                            hPad: hPad,
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Favorite Playlists Section
                        const FavoritePlaylistsSection(),
                        const SizedBox(height: 24),

                        if (recommendationService.enabled &&
                            personalizedFeed.isNotEmpty) ...[
                          _SectionTitle(
                            title: AppLocalizations.of(context)!.forYou,
                            icon: Icons.stars_rounded,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...personalizedFeed.take(5).map((song) {
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: personalizedFeed,
                                index: personalizedFeed.indexOf(song),
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: personalizedFeed,
                              index: personalizedFeed.indexOf(song),
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        if (mixes.containsKey('Quick Picks')) ...[
                          _SectionTitle(
                            title: AppLocalizations.of(context)!.quickPicks,
                            icon: Icons.bolt_rounded,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...mixes['Quick Picks']!.take(5).map((song) {
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: mixes['Quick Picks']!,
                                index: mixes['Quick Picks']!.indexOf(song),
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: mixes['Quick Picks']!,
                              index: mixes['Quick Picks']!.indexOf(song),
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        if (mixes.containsKey('Discover Mix')) ...[
                          _SectionTitle(
                            title: AppLocalizations.of(context)!.discoverMix,
                            icon: Icons.explore_rounded,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...mixes['Discover Mix']!.take(5).map((song) {
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: mixes['Discover Mix']!,
                                index: mixes['Discover Mix']!.indexOf(song),
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: mixes['Discover Mix']!,
                              index: mixes['Discover Mix']!.indexOf(song),
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        for (final entry in mixes.entries.where(
                          (e) =>
                              e.key != 'Quick Picks' &&
                              e.key != 'Discover Mix' &&
                              !e.key.contains('Vibes'),
                        )) ...[
                          _SectionTitle(
                            title: entry.key,
                            icon: Icons.album_rounded,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...entry.value.take(5).map((song) {
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: entry.value,
                                index: entry.value.indexOf(song),
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: entry.value,
                              index: entry.value.indexOf(song),
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        for (final entry in mixes.entries.where(
                          (e) => e.key.contains('Vibes'),
                        )) ...[
                          _SectionTitle(
                            title: _localizeVibesTitle(context, entry.key),
                            icon: Icons.nightlight_round,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...entry.value.take(5).map((song) {
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: entry.value,
                                index: entry.value.indexOf(song),
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: entry.value,
                              index: entry.value.indexOf(song),
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        if (libraryProvider.recentAlbums.isNotEmpty) ...[
                          HorizontalScrollSection(
                            title: AppLocalizations.of(context)!.recentlyPlayed,
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            cardSize: isDesktop ? 180 : 150,
                            children: libraryProvider.recentAlbums
                                .take(10)
                                .map(
                                  (album) => AlbumCard(
                                    album: album,
                                    size: isDesktop ? 180 : 150,
                                    onTap: () => _openAlbum(context, album.id),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (libraryProvider.playlists.isNotEmpty) ...[
                          HorizontalScrollSection(
                            title: AppLocalizations.of(context)!.yourPlaylists,
                            padding: EdgeInsets.symmetric(horizontal: hPad),
                            cardSize: isDesktop ? 180 : 150,
                            children: libraryProvider.playlists
                                .take(10)
                                .map(
                                  (playlist) => _PlaylistCard(
                                    playlist: playlist,
                                    size: isDesktop ? 180 : 150,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => PlaylistScreen(
                                          playlistId: playlist.id,
                                          playlistName: playlist.name,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        if (!recommendationService.enabled &&
                            libraryProvider.randomSongs.isNotEmpty) ...[
                          _SectionTitle(
                            title: AppLocalizations.of(context)!.madeForYou,
                            hPad: hPad,
                          ),
                          if (isDesktop) _DesktopSongTableHeader(hPad: hPad),
                          ...libraryProvider.randomSongs.take(5).map((song) {
                            final index = libraryProvider.randomSongs.indexOf(
                              song,
                            );
                            if (isDesktop) {
                              return _DesktopSongRow(
                                song: song,
                                playlist: libraryProvider.randomSongs,
                                index: index,
                                hPad: hPad,
                              );
                            }
                            return SongTile(
                              song: song,
                              playlist: libraryProvider.randomSongs,
                              index: index,
                              showAlbum: true,
                              showDuration: false,
                              titleMaxLines: 2,
                            );
                          }),
                          const SizedBox(height: 24),
                        ],

                        if (libraryProvider.recentAlbums.isEmpty &&
                            libraryProvider.playlists.isEmpty &&
                            libraryProvider.randomSongs.isEmpty &&
                            mixes.isEmpty) ...[
                          const SizedBox(height: 48),
                          Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.music_note_rounded,
                                  size: 64,
                                  color: Colors.grey[600],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  AppLocalizations.of(
                                    context,
                                  )!
                                      .noContentAvailable,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.tryRefreshing,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => refreshLibraryWithFeedback(
                                    context,
                                    libraryProvider,
                                  ),
                                  icon: const Icon(Icons.refresh),
                                  label: Text(
                                    AppLocalizations.of(context)!.refresh,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 150),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    await libraryProvider.refresh();
  }

  Widget _buildLoadingState(bool isDesktop, double hPad) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: isDesktop ? 3 : 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.5,
            children: List.generate(
              isDesktop ? 6 : 6,
              (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        HorizontalShimmerList(
          count: 5,
          child: AlbumCardShimmer(size: isDesktop ? 180 : 150),
        ),
      ],
    );
  }

  void _openAlbum(BuildContext context, String albumId) {
    NavigationHelper.push(context, AlbumScreen(albumId: albumId));
  }
}

class _QuickAccessGrid extends StatelessWidget {
  final List<dynamic> albums;
  final List<dynamic> playlists;
  final bool isDesktop;
  final double hPad;

  const _QuickAccessGrid({
    required this.albums,
    required this.playlists,
    this.isDesktop = false,
    this.hPad = 16,
  });

  @override
  Widget build(BuildContext context) {
    final raw = [...albums, ...playlists].take(isDesktop ? 9 : 6).toList();

    final items =
        (!isDesktop && raw.length.isOdd) ? raw.sublist(0, raw.length - 1) : raw;

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: hPad),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 280,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 3.2,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) =>
              _buildTile(context, items[index], subsonicService),
        ),
      );
    }

    const tileHeight = 56.0;
    const spacing = 8.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tileWidth = (constraints.maxWidth - spacing) / 2;
          final ratio = tileWidth / tileHeight;
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              childAspectRatio: ratio,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) =>
                _buildTile(context, items[index], subsonicService),
          );
        },
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    dynamic item,
    SubsonicService subsonicService,
  ) {
    final isPlaylist = item.runtimeType.toString().contains('Playlist');
    String? imageUrl;
    String title;
    VoidCallback onTap;

    if (isPlaylist) {
      title = item.name;
      imageUrl = item.coverArt != null
          ? (isLocalFilePath(item.coverArt)
              ? item.coverArt
              : subsonicService.getCoverArtUrl(item.coverArt!,
                  size: kCoverArtRequestSize))
          : null;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  PlaylistScreen(playlistId: item.id, playlistName: item.name),
            ),
          );
    } else {
      title = item.name;
      imageUrl = item.coverArt != null
          ? (isLocalFilePath(item.coverArt)
              ? item.coverArt
              : subsonicService.getCoverArtUrl(item.coverArt!,
                  size: kCoverArtRequestSize))
          : null;
      onTap = () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AlbumScreen(albumId: item.id)),
          );
    }

    return _QuickAccessTile(title: title, imageUrl: imageUrl, onTap: onTap);
  }
}

class _QuickAccessTile extends StatefulWidget {
  final String title;
  final String? imageUrl;
  final VoidCallback onTap;

  const _QuickAccessTile({
    required this.title,
    this.imageUrl,
    required this.onTap,
  });

  @override
  State<_QuickAccessTile> createState() => _QuickAccessTileState();
}

class _QuickAccessTileState extends State<_QuickAccessTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isDark
                ? (_isHovered ? AppTheme.darkElevated : AppTheme.darkCard)
                : (_isHovered ? Colors.grey[300] : Colors.grey[200]),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(4),
                    ),
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: widget.imageUrl != null
                          ? (isLocalFilePath(widget.imageUrl)
                              ? Image.file(
                                  File(widget.imageUrl!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (ctx, e, _) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white30,
                                    ),
                                  ),
                                )
                              : CachedNetworkImage(
                                  cacheManager: coverCacheManager,
                                  imageUrl: widget.imageUrl!,
                                  cacheKey:
                                      coverArtCacheKeyFromUrl(widget.imageUrl!),
                                  fit: BoxFit.cover,
                                  placeholder: (ctx, e) =>
                                      Container(color: Colors.grey[800]),
                                  errorWidget: (ctx, e, _) => Container(
                                    color: Colors.grey[800],
                                    child: const Icon(
                                      Icons.music_note,
                                      color: Colors.white30,
                                    ),
                                  ),
                                ))
                          : Container(
                              color: Colors.grey[800],
                              child: const Icon(
                                Icons.music_note,
                                color: Colors.white30,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final dynamic playlist;
  final VoidCallback? onTap;
  final double size;

  const _PlaylistCard({required this.playlist, this.onTap, this.size = 150});

  @override
  Widget build(BuildContext context) {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final coverArtUrl = playlist.coverArt != null
        ? subsonicService.getCoverArtUrl(
            playlist.coverArt!,
            size: kCoverArtRequestSize,
          )
        : null;
    final l10n = AppLocalizations.of(context)!;

    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: size,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverArtUrl != null
                    ? CachedNetworkImage(
                        cacheManager: coverCacheManager,
                        imageUrl: coverArtUrl,
                        cacheKey: coverArtCacheKeyFromUrl(coverArtUrl),
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                        errorWidget: (ctx, err, stack) => Container(
                          color: isDark
                              ? const Color(0xFF2C2C2E)
                              : Colors.grey[300],
                          child: const Center(
                            child: Icon(
                              Icons.queue_music_rounded,
                              size: 50,
                              color: Colors.white30,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color:
                            isDark ? const Color(0xFF2C2C2E) : Colors.grey[300],
                        child: const Center(
                          child: Icon(
                            Icons.queue_music_rounded,
                            size: 50,
                            color: Colors.white30,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              playlist.name,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            if (playlist.songCount != null)
              Text(
                l10n.songsCount(playlist.songCount!),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double hPad;

  const _SectionTitle({required this.title, this.icon, this.hPad = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppTheme.appleMusicRed),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopSongTableHeader extends StatelessWidget {
  final double hPad;
  const _DesktopSongTableHeader({this.hPad = 16});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final labelStyle = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.1,
      color: isDark ? Colors.white38 : Colors.black38,
    );
    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 4, hPad, 4),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text('#', style: labelStyle, textAlign: TextAlign.center),
          ),
          const SizedBox(width: 12),
          const SizedBox(width: 40),
          const SizedBox(width: 12),
          Expanded(
              flex: 5, child: Text(l10n.tableHeaderTitle, style: labelStyle)),
          Expanded(
              flex: 3, child: Text(l10n.tableHeaderAlbum, style: labelStyle)),
          const SizedBox(width: 40),
          SizedBox(
            width: 52,
            child: Text(l10n.tableHeaderTime,
                style: labelStyle, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class _DesktopSongRow extends StatefulWidget {
  final Song song;
  final List<Song> playlist;
  final int index;
  final double hPad;

  const _DesktopSongRow({
    required this.song,
    required this.playlist,
    required this.index,
    this.hPad = 16,
  });

  @override
  State<_DesktopSongRow> createState() => _DesktopSongRowState();
}

class _DesktopSongRowState extends State<_DesktopSongRow> {
  bool _hovered = false;

  String _formatDuration(int? seconds) {
    if (seconds == null) return '--:--';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final song = widget.song;
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    final isPlaying = context.select<PlayerProvider, bool>(
      (p) => (p.currentSong?.id == song.id) && p.isPlaying,
    );

    final rowBg = _hovered
        ? (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04))
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.read<PlayerProvider>().playSong(
              song,
              playlist: widget.playlist,
              startIndex: widget.index,
            ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: rowBg,
          padding: EdgeInsets.fromLTRB(widget.hPad, 6, widget.hPad, 6),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Center(
                  child: _hovered
                      ? Icon(
                          Icons.play_arrow_rounded,
                          size: 18,
                          color: isDark ? Colors.white : Colors.black,
                        )
                      : isPlaying
                          ? Icon(
                              Icons.bar_chart_rounded,
                              size: 18,
                              color: AppTheme.appleMusicRed,
                            )
                          : Text(
                              '${widget.index + 1}',
                              style: TextStyle(
                                fontSize: 13,
                                color: isPlaying
                                    ? AppTheme.appleMusicRed
                                    : (isDark
                                        ? Colors.white60
                                        : Colors.black54),
                              ),
                              textAlign: TextAlign.center,
                            ),
                ),
              ),
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: song.coverArt != null
                      ? CachedNetworkImage(
                          cacheManager: coverCacheManager,
                          imageUrl: subsonicService.getCoverArtUrl(
                            song.coverArt!,
                            size: kCoverArtRequestSize,
                          ),
                          cacheKey: coverArtCacheKey(song.coverArt!),
                          fit: BoxFit.cover,
                          placeholder: (ctx, url) =>
                              Container(color: Colors.grey[800]),
                          errorWidget: (ctx, err, stack) => Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.music_note,
                              size: 16,
                              color: Colors.white30,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[800],
                          child: const Icon(
                            Icons.music_note,
                            size: 16,
                            color: Colors.white30,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isPlaying
                            ? AppTheme.appleMusicRed
                            : (isDark ? Colors.white : Colors.black),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.artist != null)
                      Text(
                        song.artist!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  song.album ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 40,
                child: _hovered || song.starred == true
                    ? IconButton(
                        icon: Icon(
                          song.starred == true
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: song.starred == true
                              ? AppTheme.appleMusicRed
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          context.read<PlayerProvider>().toggleFavoriteForSong(
                                song,
                              );
                        },
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: 52,
                child: Text(
                  _formatDuration(song.duration),
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
