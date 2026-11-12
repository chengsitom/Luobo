import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../providers/providers.dart';
import '../services/recommendation_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/song_tile.dart';
import 'listening_report_screen.dart';

/// 最近播放（播放历史）页。
///
/// 2026-10-23：套用**与歌单详情/收藏页同款**的 hero 头（用户：「最近播放页
/// 套用同一套 hero 头，和歌单/收藏一致」）——共享 `LuoboHeroCardHeader`
/// （inset 流体卡 + 居中标题 + 双胶囊 + 共 N 首/多选）+ 同款歌曲行与分隔线。
/// 顺序即播放时间倒序，不做本地排序（排序会破坏「最近」语义）。
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Song> _recentSongs = [];
  bool _isLoading = true;
  LibraryProvider? _libraryProvider;
  RecommendationService? _recommendationService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check if still mounted before accessing context
      if (!mounted) return;

      // Listen for library / profile updates in case data arrives later.
      _libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      _recommendationService = Provider.of<RecommendationService>(
        context,
        listen: false,
      );

      // Check again after provider lookup (widget may have been disposed)
      if (!mounted) return;

      _libraryProvider!.addListener(_onProvidersChanged);
      _recommendationService!.addListener(_onProvidersChanged);
      _loadHistory();
    });
  }

  @override
  void dispose() {
    _libraryProvider?.removeListener(_onProvidersChanged);
    _recommendationService?.removeListener(_onProvidersChanged);
    super.dispose();
  }

  void _onProvidersChanged() {
    if (mounted) _loadHistory();
  }

  Future<void> _loadHistory() async {
    final recommendationService = _recommendationService;
    final libraryProvider = _libraryProvider;
    if (recommendationService == null || libraryProvider == null) return;

    // If library is still loading, keep showing the spinner.
    if (libraryProvider.cachedAllSongs.isEmpty) {
      if (!libraryProvider.isLoading && libraryProvider.isInitialized) {
        // Library finished loading and is genuinely empty.
        if (mounted) {
          setState(() {
            _recentSongs = [];
            _isLoading = false;
          });
        }
      }
      return;
    }

    // Load history even if recommendations are disabled
    // The profiles are still tracked even when recommendations are off

    final profiles = recommendationService.profiles;
    final allSongs = libraryProvider.cachedAllSongs;

    final songMap = {for (var s in allSongs) s.id: s};

    final playedSongs = profiles.entries
        .where((e) => e.value.playCount > 0 && songMap.containsKey(e.key))
        .map((e) => MapEntry(songMap[e.key]!, e.value.lastPlayed))
        .toList();

    playedSongs.sort((a, b) => b.value.compareTo(a.value));

    if (mounted) {
      setState(() {
        _recentSongs = playedSongs.map((e) => e.key).take(100).toList();
        _isLoading = false;
      });
    }
  }

  void _playAll({bool shuffle = false}) {
    if (_recentSongs.isEmpty) return;
    final songs = List<Song>.from(_recentSongs);
    if (shuffle) songs.shuffle();
    Provider.of<PlayerProvider>(context, listen: false)
        .playSong(songs.first, playlist: songs, startIndex: 0);
  }

  void _openMultiSelect() {
    if (_recentSongs.isEmpty) return;
    showMultiSelectSheet(context, songs: _recentSongs);
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
                    if (_recentSongs.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: LuoboEmptyState(
                          message: l10n.noListeningHistory,
                          icon: AppIcons.history,
                        ),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final songs = _recentSongs;
                            return Column(
                              children: [
                                SongTile(
                                  song: songs[index],
                                  playlist: songs,
                                  index: index,
                                  // 历史记录不管理收藏（无「从喜欢的歌曲中移除」）。
                                  menuContext: SongMenuContext.history,
                                ),
                                if (index < songs.length - 1)
                                  const LuoboSongDivider(),
                              ],
                            );
                          },
                          childCount: _recentSongs.length,
                        ),
                      ),
                    SliverToBoxAdapter(child: SizedBox(height: LuoboSpacing.pageBottomWithStrip(context))),
                  ],
                ),
                // 悬浮顶栏（圆返回 + 听歌报告；滚动常驻、无实色栏）。
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
                            icon: Icons.bar_chart_rounded,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ListeningReportScreen(),
                                ),
                              );
                            },
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
      title: l10n.listeningHistory,
      subtitle: l10n.songsCount(_recentSongs.length),
      countLabel: l10n.songsCount(_recentSongs.length),
      // 无封面 → 冷色流体 + 中央时钟（与收藏页「暖色流体 + 心形」同构）。
      card: Stack(
        fit: StackFit.expand,
        children: [
          const FluidBackground(
            colors: [Color(0xFF3D6BFF), Color(0xFF7A4DFF), Color(0xFF2FBBDD)],
            borderRadius: 16,
            seed: 2.4,
          ),
          Center(
            child: Icon(
              AppIcons.history,
              size: 72,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
      onPlay: () => _playAll(),
      onShuffle: () => _playAll(shuffle: true),
      onMultiSelect: _openMultiSelect,
    );
  }
}
