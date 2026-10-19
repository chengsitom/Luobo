import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/auto_dj_service.dart';
import '../services/home_recommendation_service.dart';
import '../services/recommendation_service.dart';
import '../theme/app_icons.dart';
import '../theme/roaming_palettes.dart';
import '../utils/navigation_helper.dart';
import '../utils/refresh_feedback.dart';
import '../widgets/home_hero_card.dart';
import '../widgets/luobo/glass_circle_button.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/widgets.dart';
import 'ai_playlist_screen.dart';
import 'album_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'playlist_screen.dart';
import 'search_screen.dart';
import 'settings_root_screen.dart';
import 'song_list_screen.dart';

/// 新首页（§5.1，Apple Music「现在就听」风格，v2 独立实现）。
///
/// 数据说明：P3 起由 `HomeRecommendationService.generateFeed` 提供
/// （每日推荐 / 3 个场景 Mix / 探索发现，行为×图谱融合 + 全局去重）；
/// 继续播放 / 最近播放 / 你的歌单来自 RecommendationService 与 LibraryProvider。
class HomeV2Screen extends StatefulWidget {
  const HomeV2Screen({super.key});

  @override
  State<HomeV2Screen> createState() => _HomeV2ScreenState();
}

class _HomeV2ScreenState extends State<HomeV2Screen> {
  HomeFeed? _cachedFeed;
  String _lastFeedKey = '';

  // ── 「漫游」卡的随机配色（方案 §4.6）──
  // 漫游卡没有封面，配色从 `RoamingPalettes` 随机抽，**每次回到首页换一组**。
  // 只放内存、不持久化——「回来就换」本来就是易失行为。
  final Random _roamingRandom = Random();
  int _roamingPaletteIndex = -1;
  List<Color> _roamingPalette = RoamingPalettes.all.first;
  double _roamingSeed = 0;

  // ── 取色用的「随机一首歌的封面」（2026-10-08 用户要求）──
  // 「收藏大卡 / 你的歌单」的流体颜色**不再固定取第一首**，而是每次回到首页
  // 从池子里随机挑一首歌的封面。只放内存、不持久化。
  //
  // ⚠️ 为什么用「签名 + 懒重抽」而不是在 `didChangeDependencies` 里抽一次：
  // 首页首帧时 `LibraryProvider` 还没初始化（池子是空的），若那时抽完就不再抽，
  // 收藏卡会一直停在默认 mesh —— 正是要修的「取不到色」。签名里带上池子规模
  // 与 `_coverEpoch`，数据加载完（签名变）或回到首页（epoch 变）都会重抽。
  final Random _coverRandom = Random();
  int _coverEpoch = 0;
  String _coverSig = '';
  String? _favoriteCover;
  Map<String, String> _playlistCovers = const {};

  bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  @override
  void initState() {
    super.initState();
    _randomizeRoamingPalette();
    NavigationHelper.tabIndex.addListener(_onTabIndexChanged);
  }

  @override
  void dispose() {
    NavigationHelper.tabIndex.removeListener(_onTabIndexChanged);
    super.dispose();
  }

  /// 首页在 `IndexedStack` 里，切 tab 不会重建（`main_screen.dart`），所以「回到
  /// 首页」只能靠订阅 `NavigationHelper.tabIndex` 拿信号（首页 = 0）。
  void _onTabIndexChanged() {
    if (!mounted || NavigationHelper.tabIndex.value != 0) return;
    setState(() {
      _randomizeRoamingPalette();
      // 换一版取色：`_coverEpoch` 变了 → 下面的签名也变 → 重抽封面。
      _coverEpoch++;
    });
  }

  /// 抽一组新的漫游配色 + 纹样 seed（`exclude` 避免连续两次抽到同一组）。
  void _randomizeRoamingPalette() {
    final (index, colors) =
        RoamingPalettes.pick(_roamingRandom, exclude: _roamingPaletteIndex);
    _roamingPaletteIndex = index;
    _roamingPalette = colors;
    _roamingSeed = RoamingPalettes.randomSeed(_roamingRandom);
  }

  /// 过滤出可用的封面 id 并物化成池子（空池子返回空表）。
  List<String> _coverPool(Iterable<String?> covers) => covers
      .whereType<String>()
      .where((c) => c.isNotEmpty)
      .toList(growable: false);

  /// 从一组封面 id 里随机挑一个（空池子返回 null）。
  ///
  /// 传已物化的 [List] 时不再复制；传惰性 [Iterable] 时会先过滤物化。
  String? _pickCover(Iterable<String?> covers) {
    final pool = covers is List<String> ? covers : _coverPool(covers);
    if (pool.isEmpty) return null;
    return pool[_coverRandom.nextInt(pool.length)];
  }

  /// 曲库池 —— 歌单的「自己的歌」本地没有缓存（`Playlist.songs` 只有用户**打开过**
  /// 那个歌单时才有），所以缺池子时回落到全曲库随机，保证卡面一定有颜色。
  Iterable<String?> _libraryCovers(LibraryProvider p) =>
      p.cachedAllSongs.map(p.effectiveCoverArt);

  /// 池子签名变了（首次加载完 / 收藏数变化 / 歌单列表变化）或回到首页
  /// （`_coverEpoch` 变）就重抽一次。
  ///
  /// 与同文件 `_cachedFeed` / `_lastFeedKey` 是同一套「签名守卫的 build 期缓存」写法。
  void _rollCoversIfNeeded({
    required LibraryProvider library,
    required List<Song> favorites,
    required List<Playlist> playlists,
  }) {
    // ⚠️ 签名只用 **O(1) 标量**：早先拼了 `playlists.id.join()` 与
    // `cachedAllSongs.length`（后者在 mergeLocal 开启时**每次访问都会重建合并列表**），
    // 而这段代码在 build 期跑 —— 等于每帧做一次 O(N)。改成标量后仍能覆盖
    // 「数据加载完 / 收藏数变化 / 歌单列表变化 / 回到首页」四种该重抽的时机。
    final sig = '$_coverEpoch|${favorites.length}|'
        '${playlists.length}|${library.isInitialized}';
    if (sig == _coverSig) return;
    _coverSig = sig;

    // 全曲库池**一次重抽只物化一次**（早先每个歌单都重新遍历一遍全曲库）。
    final libraryPool = _coverPool(_libraryCovers(library));
    _favoriteCover = _pickCover(favorites.map(library.effectiveCoverArt)) ??
        _pickCover(libraryPool);
    _playlistCovers = {
      for (final p in playlists)
        p.id:
            _pickCover((p.songs ?? const []).map(library.effectiveCoverArt)) ??
                _pickCover(libraryPool) ??
                '',
    };
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    final l10n = AppLocalizations.of(context)!;
    if (hour < 12) return l10n.goodMorning;
    if (hour < 17) return l10n.goodAfternoon;
    return l10n.goodEvening;
  }

  String _computeSongsKey(List<Song> songs) =>
      songs.isEmpty ? '' : songs.map((s) => s.id).join('|');

  void _play(
    BuildContext context,
    Song song,
    List<Song> playlist,
    int index,
  ) {
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      song,
      playlist: playlist,
      startIndex: index,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tokens = HomeV2Tokens.of(context);
    final hPad = _isDesktop ? 32.0 : 16.0;

    return Scaffold(
      backgroundColor: tokens.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: _isDesktop ? 80 : 70,
            backgroundColor: tokens.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.only(left: hPad, bottom: 14),
              title: Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: _isDesktop ? 28 : 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            actions: [
              // C2 起底栏不再有「搜索」tab（改为 首页/音乐库/设置），
              // 搜索入口挪到大标题页右上角 —— 与 fnos 一致（§2.2）。
              GlassCircleButton(
                icon: AppIcons.search,
                tooltip: AppLocalizations.of(context)!.search,
                onPressed: () => NavigationHelper.push(
                  context,
                  const SearchScreen(),
                ),
              ),
              const SizedBox(width: 8),
              GlassCircleButton(
                icon: AppIcons.ai,
                tooltip: AppLocalizations.of(context)!.aiPlaylist,
                onPressed: () => NavigationHelper.push(
                  context,
                  const AiPlaylistScreen(),
                ),
              ),
              const SizedBox(width: 8),
              GlassCircleButton(
                icon: AppIcons.settings,
                tooltip: AppLocalizations.of(context)!.settings,
                onPressed: () => NavigationHelper.push(
                  context,
                  const SettingsRootScreen(),
                ),
              ),
              const SizedBox(width: 8),
              GlassCircleButton(
                icon: AppIcons.refresh,
                tooltip: AppLocalizations.of(context)!.recentlyPlayed,
                onPressed: () =>
                    NavigationHelper.push(context, const HistoryScreen()),
              ),
              if (_isDesktop) const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Consumer3<LibraryProvider, RecommendationService,
                HomeRecommendationService>(
              builder: (context, libraryProvider, recommendationService,
                  homeRecommendation, _) {
                // 未初始化（含首帧与 initialize 进行中）一律转圈，
                // 避免首帧（isLoading 仍为 false）落进下方空态分支整页闪「暂无内容」。
                if (!libraryProvider.isInitialized) {
                  return Padding(
                    padding: EdgeInsets.only(top: 120),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                // P3：候选池用全量曲库（全量同步未完成时回退随机池）。
                final allSongs = libraryProvider.cachedAllSongs.isNotEmpty
                    ? libraryProvider.cachedAllSongs
                    : libraryProvider.randomSongs;
                // feed 门控 = 曲库 id 串 + 推荐服务的 feedRevision：曲库没变但
                // 服务内部缓存失效（收藏变化 / 知识库重建）时同样要重建 feed，
                // 否则「点了喜欢推荐跟着变」永远不生效（§3.4）。
                final songsKey = _computeSongsKey(allSongs);
                final feedKey = songsKey.isEmpty
                    ? ''
                    : '$songsKey#${homeRecommendation.feedRevision}';

                if (recommendationService.enabled && feedKey.isNotEmpty) {
                  if (feedKey != _lastFeedKey) {
                    _cachedFeed = homeRecommendation.generateFeed(
                      allSongs: allSongs,
                    );
                    _lastFeedKey = feedKey;
                  }
                } else {
                  _cachedFeed = null;
                  _lastFeedKey = '';
                }

                final feed = _cachedFeed;
                final daily = feed?.daily ?? const <Song>[];

                if (allSongs.isEmpty && (feed == null || feed.isEmpty)) {
                  return _buildEmptyState(hPad, isDark);
                }

                // 取色：在构建各小节**之前**重抽（「收藏大卡」与「你的歌单」都读结果）。
                _rollCoversIfNeeded(
                  library: libraryProvider,
                  favorites: libraryProvider.starred?.songs ?? const <Song>[],
                  playlists: libraryProvider.playlists.take(10).toList(),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    // 顶部大卡：漫游 / 收藏（2026-10-09 起取代「今日推荐」的位置）。
                    _buildHeroEntries(context, libraryProvider, hPad),
                    // 「今日推荐」暂时下线 —— 见 `_showDailyRecommendation`。
                    _buildDailyCard(context, daily, libraryProvider, hPad),
                    _buildContinueListening(
                      context,
                      recommendationService,
                      allSongs,
                      libraryProvider,
                      hPad,
                    ),
                    const SizedBox(height: 16),
                    _buildRecentlyPlayed(context, libraryProvider, hPad),
                    const SizedBox(height: 16),
                    _buildPlaylists(context, libraryProvider, hPad),
                    const SizedBox(height: 16),
                    _buildDiscover(
                      context,
                      feed?.discover ?? const [],
                      libraryProvider,
                      hPad,
                    ),
                    // 视口已排除迷你播放器与底部导航，尾部仅留少量呼吸空间。
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 模块构建
  // ──────────────────────────────────────────────────────────────────────────

  /// 「今日推荐」大卡开关。
  ///
  /// 2026-10-09 用户要求**暂时**去掉（位置让给「漫游 / 收藏」大卡）。实现整体保留，
  /// 改回 `true` 即恢复；`generateFeed` 的 `daily` 仍在算，只是不再渲染。
  static const bool _showDailyRecommendation = false;

  /// 大卡高度 —— 飞牛首页实测 184dp；**两行共用**（顶部大卡与「你的歌单」）。
  static const double _heroCardHeight = 184;

  /// 大卡固定宽度 —— 只给**要横滑**的那一行用（「你的歌单」6 张，飞牛实测 151dp）。
  ///
  /// 顶部「漫游 / 收藏」只有 2 张、要求**铺满整行**，宽度由 `_heroRow` 现算（见该方法的
  /// `fillWidth`），不走这个常量。
  static const double _heroCardWidth = 151;

  /// 大卡之间的间距。
  static const double _heroCardGap = 12;

  /// 首页顶部「漫游 / 收藏」大卡（对标飞牛首页）—— 取代原「今日推荐」通栏横幅的
  /// 位置与「快速开始」小节（2026-10-09 用户要求）。
  ///
  /// **铺满整行**（右侧不留空白）、卡高 184dp；图标为卡面主体、文字退到左下角。
  Widget _buildHeroEntries(
    BuildContext context,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final favorites = libraryProvider.starred?.songs ?? const <Song>[];

    return _heroRow(
      hPad: hPad,
      // 只有 2 张 → 铺满整行，右侧不留空白（2026-10-09 用户反馈）。
      fillWidth: true,
      cards: [
        // 顺序（用户指定）：漫游 → 收藏。
        HomeHeroCard(
          icon: AppIcons.roam,
          title: l10n.roaming,
          subtitle: l10n.roamingSubtitle,
          // 漫游没有封面 → 配色由 `RoamingPalettes` 随机给（每次回到首页换一组）。
          colors: _roamingPalette,
          seed: _roamingSeed,
          onTap: () async {
            final started = await playerProvider.startRoaming();
            // 曲库还没同步好时给个明确反馈——静默无反应看起来像坏了。
            if (!started && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.noSongsFound)),
              );
            }
          },
          onLongPress: () => _pickRoamingMode(context, playerProvider),
        ),
        HomeHeroCard(
          icon: AppIcons.heartFilled,
          title: l10n.favorites,
          // 数字在标题下一行（`songCount` = 「N 首」）。
          subtitle: l10n.songCount(favorites.length),
          // 每次回到首页随机抽一首收藏的歌当取色源
          // （`_rollCoversIfNeeded`）；没有收藏时回落全曲库。
          imageUrl: _coverUrl(libraryProvider, _favoriteCover),
          seed: FluidBackground.seedForIndex(1),
          onTap: () => NavigationHelper.push(context, const FavoritesScreen()),
        ),
      ],
    );
  }

  /// 大卡横滑行 —— 顶部「漫游 / 收藏」与「你的歌单」**共用同一套排版**
  /// （2026-10-09 用户要求「你的歌单也同步改」）。
  ///
  /// [fillWidth] = true 时把本行**铺满**：N 张卡按可用宽度均分，右侧不留空白
  /// （2026-10-09 用户反馈「漫游 / 收藏不够大，右边还留白」）。「你的歌单」有 6 张、
  /// 必须横滑，所以走固定宽 `_heroCardWidth`。
  ///
  /// ⚠️ 外层 `SizedBox` 的高度**必须等于**卡高：横滑 `ListView` 的交叉轴是**紧约束**，
  /// 子项会被拉满容器高度。旧「你的歌单」走 `HorizontalScrollSection(cardSize: 150)`
  /// （容器高 = `cardSize + 60` = 210），于是卡实际是 **150×210**，不是它注释里写的正方形。
  Widget _heroRow({
    required List<Widget> cards,
    required double hPad,
    String? title,
    bool fillWidth = false,
  }) {
    if (cards.isEmpty) return const SizedBox.shrink();

    Widget buildRow(double cardWidth) => SizedBox(
          height: _heroCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: _heroCardGap),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              height: _heroCardHeight,
              child: cards[index],
            ),
          ),
        );

    return FluidBackgroundScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: hPad),
              child: SectionHeader(title: title),
            ),
          if (fillWidth)
            LayoutBuilder(
              builder: (context, constraints) {
                // N 张 + (N−1) 个间距 + 左右各 hPad == 可用宽度，右侧不留空白。
                final n = cards.length;
                final usable =
                    constraints.maxWidth - 2 * hPad - _heroCardGap * (n - 1);
                return buildRow(usable / n);
              },
            )
          else
            buildRow(_heroCardWidth),
        ],
      ),
    );
  }

  /// 歌单名 → 卡面首字字母牌（取第一个**完整字符**，避免把 emoji 的代理对劈开）。
  ///
  /// 用首字而不是封面：一个歌单里有很多首歌，**单张封面代表不了它**（用户 2026-10-09）。
  String? _monogramOf(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return String.fromCharCode(trimmed.runes.first).toUpperCase();
  }

  Widget _buildDailyCard(
    BuildContext context,
    List<Song> daily,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    if (!_showDailyRecommendation) return const SizedBox.shrink();
    if (daily.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // 每次进入首页从 30 首里随机抽一张有封面的歌展示（封面定期换）。
    final cover = _randomDailyCover(libraryProvider, daily);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: DailyRecommendationCard(
        title: l10n.dailyRecommendation,
        coverArt: cover,
        imageUrl: cover == null ? null : libraryProvider.getCoverArtUrl(cover),
        onTap: () => NavigationHelper.push(
          context,
          SongListScreen(
            title: l10n.dailyRecommendation,
            songs: daily,
            slogans: [
              l10n.dailySlogan1,
              l10n.dailySlogan2,
              l10n.dailySlogan3,
            ],
            imageUrl:
                cover == null ? null : libraryProvider.getCoverArtUrl(cover),
          ),
        ),
        onPlayAll: () => _play(context, daily.first, daily, 0),
      ),
    );
  }

  /// 从每日推荐里随机抽一个有封面的歌，返回其封面 ID；无则 null。
  String? _randomDailyCover(LibraryProvider p, List<Song> songs) {
    final covers = songs
        .map((s) => p.effectiveCoverArt(s))
        .where((c) => c != null && c.isNotEmpty)
        .toList();
    if (covers.isEmpty) return null;
    return covers[Random().nextInt(covers.length)];
  }

  Widget _buildContinueListening(
    BuildContext context,
    RecommendationService recommendationService,
    List<Song> allSongs,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    // 最近播放歌曲优先从全量曲库映射，避免被 50 首随机池漏掉（用户反馈）。
    final pool = libraryProvider.cachedAllSongs.isNotEmpty
        ? libraryProvider.cachedAllSongs
        : allSongs;
    final byId = {for (final s in pool) s.id: s};
    // 多行横滑：2 行 × 每行 5 个 = 10 首，横滑 5 下看全（用户反馈）。
    const rows = 2;
    const perRow = 5;
    final recent = recommendationService.recentlyPlayed
        .map((id) => byId[id])
        .whereType<Song>()
        .take(rows * perRow)
        .toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    const cardWidth = 200.0;
    const cardHeight = 72.0;
    const rowSpacing = 10.0;
    const colSpacing = 12.0;
    final gridHeight = rows * cardHeight + (rows - 1) * rowSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: SectionHeader(title: l10n.continueListening),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: gridHeight,
          // 横向 GridView 按「先列后行」填充（index0 左上、index1 左下、index2
          // 右上…），且 recentlyPlayed 本身最新在前（insert(0)），因此视觉上
          // 即：最新在左上角、整体 1 3 5 / 2 4 6 交错（用户 2026-08-05 确认）。
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: rows,
              crossAxisSpacing: rowSpacing,
              mainAxisSpacing: colSpacing,
              childAspectRatio: cardHeight / cardWidth,
            ),
            itemCount: recent.length,
            itemBuilder: (context, index) {
              final song = recent[index];
              return ContinuePlayingCard(
                song: song,
                coverArt: libraryProvider.effectiveCoverArt(song),
                width: cardWidth,
                onTap: () => _play(context, song, recent, index),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 长按「漫游」卡：选续播方式 + 每次追加数量。
  ///
  /// 原设置页「自动播放」小节的这两项搬到这里（方案 §5.3「路 3」），设置页不再
  /// 单独留 AutoDJ 小节。选中即生效（不关面板），方便来回对比。
  Future<void> _pickRoamingMode(
    BuildContext context,
    PlayerProvider playerProvider,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final service = playerProvider.autoDjService;
    await showLuoboSheet<void>(
      context: context,
      title: l10n.roaming,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final mode in AutoDjMode.values)
              LuoboSheetRow(
                title: _autoDjModeLabel(l10n, mode),
                selected: service.mode == mode,
                showChevron: false,
                onTap: () async {
                  await service.setMode(mode);
                  // sheet 可能在 await 期间被关掉 —— 此时 StatefulBuilder
                  // 已 dispose，再 setState 会在 debug 下断言。
                  if (!ctx.mounted) return;
                  setSheetState(() {});
                },
              ),
            if (service.mode != AutoDjMode.off) ...[
              const SizedBox(height: 4),
              LuoboSliderRow(
                title: l10n.autoDjSongsToAdd(service.songsToAdd),
                value: service.songsToAdd.toDouble(),
                min: 1,
                max: 20,
                divisions: 19,
                onChanged: (value) async {
                  await service.setSongsToAdd(value.round());
                  if (!ctx.mounted) return;
                  setSheetState(() {});
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _autoDjModeLabel(AppLocalizations l10n, AutoDjMode mode) {
    switch (mode) {
      case AutoDjMode.off:
        return l10n.autoDjModeOff;
      case AutoDjMode.shuffleLibrary:
        return l10n.autoDjModeShuffleLibrary;
      case AutoDjMode.similarSongs:
        return l10n.autoDjModeSimilarSongs;
      case AutoDjMode.sameGenre:
        return l10n.autoDjModeSameGenre;
      case AutoDjMode.sameArtist:
        return l10n.autoDjModeSameArtist;
      case AutoDjMode.smartMix:
        return l10n.autoDjModeSmartMix;
    }
  }

  /// 列表第一首有封面的歌的封面 URL（二级页 hero 取色用）。
  String? _firstCoverUrl(LibraryProvider p, List<Song> songs) {
    for (final song in songs) {
      final cover = p.effectiveCoverArt(song);
      if (cover != null && cover.isNotEmpty) {
        return p.getCoverArtUrl(cover);
      }
    }
    return null;
  }

  /// 最近播放的**专辑**横滑区。
  ///
  /// 2026-10-08：歌单 / 收藏卡已移除——它们的 2×2 拼图封面在不足 4 张时会留透明格，
  /// 观感是「封面显示不全」；歌单那一份语义搬到了「歌单」快捷入口卡
  /// （见 `_buildQuickEntries`）。
  Widget _buildRecentlyPlayed(
    BuildContext context,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    final l10n = AppLocalizations.of(context)!;
    final albums = libraryProvider.recentAlbums;
    if (albums.isEmpty) return const SizedBox.shrink();

    return HorizontalScrollSection(
      title: l10n.recentlyPlayed,
      padding: EdgeInsets.symmetric(horizontal: hPad),
      cardSize: 150,
      children: [
        // 最近播放的专辑（服务端 recentAlbums 顺序）。
        for (final album in albums.take(10))
          AlbumCard(
            album: album,
            size: 150,
            onTap: () => NavigationHelper.push(
              context,
              AlbumScreen(albumId: album.id),
            ),
          ),
      ],
    );
  }

  /// 「你的歌单」小节 —— 与顶部大卡同一套排版（2026-10-09 用户要求「同步改」）。
  ///
  /// 卡面主体是**歌单名首字字母牌**而不是封面：一个歌单里有很多首歌，单张封面代表不了它
  /// （用户明确否掉封面）；用法对标 Apple Music「Made For You」Mix 卡 —— 渐变 + 大号
  /// 半透明图形 + 大号粗体标题，而不是单张封面。取色仍走 `_playlistCovers`
  /// （每次回到首页随机抽该歌单里一首歌的封面**当取色源**，卡面不显示封面图）。
  Widget _buildPlaylists(
    BuildContext context,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    // ⚠️ 条数收在 6（方案 §8.6 的退路阶梯①）：每张卡都是一次独立的片段着色器
    // 绘制，10 张会明显推高首页的 GPU 压力。要放回更多，改这个常量即可，
    // 但请先在低端机上实测帧率。
    final playlists = libraryProvider.playlists.take(_playlistsInRow).toList();
    if (playlists.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return _heroRow(
      hPad: hPad,
      title: l10n.yourPlaylists,
      cards: [
        for (var i = 0; i < playlists.length; i++)
          HomeHeroCard(
            monogram: _monogramOf(playlists[i].name),
            title: playlists[i].name,
            // 歌单名可能较长 —— 允许两行（入口卡只有 1 行）。
            titleMaxLines: 2,
            subtitle: playlists[i].songCount == null
                ? null
                : l10n.songCount(playlists[i].songCount!),
            imageUrl: _coverUrl(
              libraryProvider,
              _playlistCovers[playlists[i].id],
            ),
            seed: FluidBackground.seedForIndex(i),
            onTap: () => NavigationHelper.push(
              context,
              PlaylistScreen(
                playlistId: playlists[i].id,
                playlistName: playlists[i].name,
              ),
            ),
          ),
      ],
    );
  }

  /// 「你的歌单」横滑最多展示几张 —— 受流体着色器绘制成本约束（方案 §8.6）。
  static const int _playlistsInRow = 6;

  /// 封面 id → 可直接喂给 `CachedNetworkImageProvider` 的 URL；空则 null。
  String? _coverUrl(LibraryProvider provider, String? coverArt) {
    if (coverArt == null || coverArt.isEmpty) return null;
    final url = provider.getCoverArtUrl(coverArt);
    return url.isEmpty ? null : url;
  }

  Widget _buildDiscover(
    BuildContext context,
    List<Song> discover,
    LibraryProvider libraryProvider,
    double hPad,
  ) {
    if (discover.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // 单曲横滑网格（§8-9）：探索发现是「歌曲」不是合集，用横卡与方块网格
    // （Mix/歌单/最近播放）区分；4 行 × 每行 5 首 = 20 首（探索发现全量），
    // 加宽卡片、隐藏播放按钮、歌名允许两行——未听过的歌认歌名比按钮重要。
    // 横向 GridView 按「先列后行」填充（index0 左上、index1 左下…）。
    const rows = 4;
    const perRow = 5;
    final songs = discover.take(rows * perRow).toList();
    const cardWidth = 240.0;
    const cardHeight = 72.0;
    const rowSpacing = 10.0;
    const colSpacing = 12.0;
    final gridHeight = rows * cardHeight + (rows - 1) * rowSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: SectionHeader(
            title: l10n.discover,
            actionText: l10n.seeAll,
            onActionTap: () => NavigationHelper.push(
              context,
              SongListScreen(
                title: l10n.discover,
                songs: discover,
                slogans: [
                  l10n.discoverSlogan1,
                  l10n.discoverSlogan2,
                  l10n.discoverSlogan3,
                ],
                imageUrl: _firstCoverUrl(libraryProvider, discover),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: gridHeight,
          child: GridView.builder(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            scrollDirection: Axis.horizontal,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: rows,
              crossAxisSpacing: rowSpacing,
              mainAxisSpacing: colSpacing,
              childAspectRatio: cardHeight / cardWidth,
            ),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return ContinuePlayingCard(
                song: song,
                coverArt: libraryProvider.effectiveCoverArt(song),
                width: cardWidth,
                showPlayButton: false,
                titleMaxLines: 2,
                // 副标题歌手 + 专辑：填满右侧留白，且"歌手 · 专辑"更便于认歌。
                subtitle: [song.artist, song.album]
                    .whereType<String>()
                    .where((s) => s.isNotEmpty)
                    .join(' · '),
                onTap: () => _play(context, song, discover, index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(double hPad, bool isDark) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 80),
      child: Column(
        children: [
          Icon(
            Icons.music_note_rounded,
            size: 64,
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noContentAvailable,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white54 : Colors.black45,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.tryRefreshing,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => refreshLibraryWithFeedback(
              context,
              Provider.of<LibraryProvider>(context, listen: false),
            ),
            icon: const Icon(Icons.refresh),
            label: Text(l10n.refresh),
          ),
        ],
      ),
    );
  }
}

// （`_CollectionCardV2` 已于 2026-10-08 删除：「最近播放」不再插入歌单/收藏卡，
// 其 2×2 拼图封面在不足 4 张时会留透明格；歌单语义搬到了「歌单」快捷入口卡。）
