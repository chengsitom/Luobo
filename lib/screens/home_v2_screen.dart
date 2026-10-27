import 'dart:io';
import '../widgets/luobo/luobo_toast.dart';
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
import '../widgets/pressable_scale.dart';
import '../widgets/widgets.dart';
import 'ai_playlist_screen.dart';
import 'album_screen.dart';
import 'discover_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';
import 'playlist_screen.dart';
import 'search_screen.dart';
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
  // 漫游卡没有封面，配色从 `RoamingPalettes` 随机抽。**冷启抽一次后不再变**
  //（2026-10-24 用户：回到首页看到颜色跳变不舒服）。只放内存、不持久化。
  final Random _roamingRandom = Random();
  int _roamingPaletteIndex = -1;
  List<Color> _roamingPalette = RoamingPalettes.all.first;
  double _roamingSeed = 0;

  // ── 取色用的「随机一首歌的封面」（2026-10-08 用户要求）──
  // 「收藏大卡 / 你的歌单」的流体颜色从池子里随机挑一首歌的封面取色。
  //
  // ⚠️ 为什么用「签名 + 懒重抽」而不是在 `didChangeDependencies` 里抽一次：
  // 首页首帧时 `LibraryProvider` 还没初始化（池子是空的），若那时抽完就不再抽，
  // 收藏卡会一直停在默认 mesh —— 正是要修的「取不到色」。签名里带上池子规模，
  // 数据加载完（签名变）时重抽一次；**之后切 tab 回来不再重抽**
  //（2026-10-24 用户：每次回首页都跳变，不舒服）。
  final Random _coverRandom = Random();
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
    // 冷启抽一次：漫游配色 + 封面取色（封面在数据加载完后由签名触发）。
    _randomizeRoamingPalette();
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

  /// 池子签名变了（冷启数据加载完 / 收藏数变化 / 歌单列表变化）就重抽一次。
  ///
  /// ⚠️ 2026-10-24 起**不再随「切 tab 回首页」重抽**（用户反馈颜色跳变不舒服）。
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
    // 「数据加载完 / 收藏数变化 / 歌单列表变化」三种该重抽的时机。
    final sig = '${favorites.length}|'
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

  /// 正在后台计 feed / 已排队但尚未落地的目标 key 与曲库快照。
  bool _computingFeed = false;
  String _pendingFeedKey = '';
  List<Song>? _pendingFeedSongs;

  /// 帧后异步生成推荐 feed（原因见 `build()` 内注释）。
  ///
  /// 同一 [key] 只排队一次；计算期间若有更新的 key 到来，当前结果仍会落地，
  /// 随后继续算最新一版，保证「收藏/知识库变化后推荐跟着变」不丢。
  void _scheduleFeedBuild({
    required String key,
    required List<Song> songs,
    required HomeRecommendationService homeRecommendation,
  }) {
    if (key == _lastFeedKey) return;
    _pendingFeedKey = key;
    _pendingFeedSongs = songs;
    if (_computingFeed) return;
    _computingFeed = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _drainFeedBuild(homeRecommendation),
    );
  }

  void _drainFeedBuild(HomeRecommendationService homeRecommendation) {
    if (!mounted) {
      _computingFeed = false;
      return;
    }
    final key = _pendingFeedKey;
    final songs = _pendingFeedSongs;
    if (key.isEmpty || songs == null || key == _lastFeedKey) {
      _computingFeed = false;
      return;
    }
    final feed = homeRecommendation.generateFeed(allSongs: songs);
    if (!mounted) {
      _computingFeed = false;
      return;
    }
    final hasNewer = _pendingFeedKey != key;
    setState(() {
      _cachedFeed = feed;
      _lastFeedKey = key;
    });
    if (hasNewer) {
      // 计算期间来了更新的 key：接着算下一轮。
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _drainFeedBuild(homeRecommendation),
      );
    } else {
      _computingFeed = false;
      _pendingFeedKey = '';
      _pendingFeedSongs = null;
    }
  }

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
            // §6.4：大标题页「标题淡出、圆钮常驻」——顶栏**无实色底**，内容从
            // 问候语下方流过；问候语随折叠比淡出，右侧圆钮（搜索 / AI 歌单）常驻。
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            scrolledUnderElevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: EdgeInsets.zero,
              background: Builder(
                builder: (context) {
                  // 纯布局期读折叠比（无 setState、不掉帧）：展开 t=1、收起 t=0。
                  final settings = context
                      .dependOnInheritedWidgetOfExactType<
                          FlexibleSpaceBarSettings>();
                  final maxExtent = settings?.maxExtent ?? 0;
                  final minExtent = settings?.minExtent ?? 0;
                  final current = settings?.currentExtent ?? maxExtent;
                  final t = ((current - minExtent) /
                          max(1.0, maxExtent - minExtent))
                      .clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding:
                          EdgeInsets.only(left: hPad, bottom: 14),
                      child: Opacity(
                        opacity: t,
                        // 保留原 `FlexibleSpaceBar` 标题的展开缩放（默认
                        // `expandedTitleScale` = 1.5）：展开 36dp、收起 24dp，
                        // 只是从「缩进工具栏」改为「淡出」。
                        child: Transform.scale(
                          scale: 1 + 0.5 * t,
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: _isDesktop ? 28 : 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            actions: [
              // 2026-10-24 用户拍板：右上只留「搜索」「AI 歌单」两个圆钮
              //（设置走底栏 tab；最近播放改由首页大卡进入）。
              // `shadows: []`：纯白页面上玻璃默认阴影会在按钮周围形成灰晕
              //（两钮 8dp 间距还会叠加）—— 用户反馈「按钮下面有一个背景色」。
              GlassCircleButton(
                icon: AppIcons.search,
                tooltip: AppLocalizations.of(context)!.search,
                shadows: const [],
                onPressed: () => NavigationHelper.push(
                  context,
                  const SearchScreen(),
                ),
              ),
              const SizedBox(width: 8),
              GlassCircleButton(
                icon: AppIcons.ai,
                tooltip: AppLocalizations.of(context)!.aiPlaylist,
                shadows: const [],
                onPressed: () => NavigationHelper.push(
                  context,
                  const AiPlaylistScreen(),
                ),
              ),
              const SizedBox(width: 8),
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
                  // ⚠️ 不能在这里同步算 feed：generateFeed 会把全曲库打六遍分，
                  // 曲库大时单次几十毫秒。早先它和 refreshKnowledgeFromCache
                  // 的守卫缺陷叠加，直接变成「通知 → 重建 → 再算 feed」的
                  // 无限循环（线上实测 UI 线程 82%、约 8fps）。改成帧后异步：
                  // 算完再 setState，期间继续渲染上一版 feed。
                  _scheduleFeedBuild(
                    key: feedKey,
                    songs: allSongs,
                    homeRecommendation: homeRecommendation,
                  );
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
                    _buildRecentlyPlayed(
                      context,
                      libraryProvider,
                      recommendationService,
                      hPad,
                    ),
                    const SizedBox(height: 16),
                    _buildPlaylists(context, libraryProvider, hPad),
                    const SizedBox(height: 16),
                    _buildDiscover(
                      context,
                      feed?.discover ?? const [],
                      hPad,
                    ),
                    // 覆盖式底栏（`extendBody`）悬浮在内容之上，Scaffold 把底栏高度注入
                    // 成 `MediaQuery.padding.bottom`——但 `CustomScrollView` 不像 `ListView`
                    // 会自动吃掉这段 padding，得手动补，否则「探索发现」最后一排会被玻璃
                    // 底栏压住（用户 2026-10-20 反馈）。32 是额外的呼吸空间。
                    SizedBox(height: 32 + MediaQuery.of(context).padding.bottom),
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
      // 2026-10-24 用户拍板：加「最近播放」→ 3 张**横滑**（不再铺满整行）。
      // 3 张 × 151 + 2 × 12 + 左右 16 ≈ 509dp > 360，右侧自然露出第 3 张。
      fillWidth: false,
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
              showLuoboToast(
      context,
      message: l10n.noSongsFound,
      tone: LuoboToastTone.info,
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
        // 第 3 张：最近播放（2026-10-24 用户拍板，对齐飞牛首屏 3 张横滑）——
        // 原顶栏的「最近播放」圆钮已删除，入口收进这张卡。
        // 配色固定取 `RoamingPalettes` 的「抹茶绿」：飞牛这张卡就是绿底 + 时钟，
        // 也避免落到 `FluidPalette.defaultColors` 的深蓝紫（与相邻彩卡不搭）。
        HomeHeroCard(
          icon: AppIcons.history,
          title: l10n.recentlyPlayed,
          colors: RoamingPalettes.all[5],
          seed: FluidBackground.seedForIndex(2),
          onTap: () =>
              NavigationHelper.push(context, const HistoryScreen()),
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
          // 标题自己带页边距（`SectionHeader.padding`）——**不要再外包 Padding**，
          // 否则标题比卡片/歌曲行右移 16dp（2026-10-24 用户反馈「没有左对齐」）。
          if (title != null)
            SectionHeader(
              title: title,
              padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
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
    // 2026-10-24 用户拍板：改飞牛「最近播放」行式 —— 每列 4 行歌曲行、横滑。
    // （推翻 2026-08-05 的「2 行×5 列交错」宽横卡网格。）
    final recent = recommendationService.recentlyPlayed
        .map((id) => byId[id])
        .whereType<Song>()
        .take(_rowSongsPerColumn * _rowColumnsMax)
        .toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        SectionHeader(
          title: l10n.continueListening,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
        ),
        const SizedBox(height: 8),
        _buildSongRowColumns(recent),
      ],
    );
  }

  /// 歌曲行横滑区的每列行数 —— 飞牛首页实测 4 行（4 × 64 = 256dp）。
  static const int _rowSongsPerColumn = 4;

  /// 歌曲行横滑区最多几列（4 × 3 = 12 首）。
  static const int _rowColumnsMax = 3;

  /// 歌曲行横滑区（飞牛首页「最近播放 / 最近添加歌曲」同款）：
  /// 每列 4 行 `SongTile`（64dp 行、封面 48、⋮ 走 C3 面板），横向分页。
  ///
  /// 列宽 = 视口宽 − **20**：左 16 由 `SongTile` 自己的内边距提供，右侧露出
  /// 下一列的 **4dp 封面**（实测下一列封面左缘 356dp / 360 屏）作为可滑提示。
  Widget _buildSongRowColumns(List<Song> songs) {
    final columns = (songs.length / _rowSongsPerColumn).ceil();
    return SizedBox(
      height: _rowSongsPerColumn * 64.0,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columnWidth = constraints.maxWidth - 20;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: columns,
            itemBuilder: (context, column) {
              final start = column * _rowSongsPerColumn;
              final end = min(start + _rowSongsPerColumn, songs.length);
              final slice = songs.sublist(start, end);
              return SizedBox(
                width: columnWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < slice.length; i++)
                      SongTile(
                        song: slice[i],
                        playlist: songs,
                        index: start + i,
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
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

  /// 最近播放的**专辑**横滑区。
  ///
  /// 2026-10-08：歌单 / 收藏卡已移除——它们的 2×2 拼图封面在不足 4 张时会留透明格，
  /// 观感是「封面显示不全」；歌单那一份语义搬到了「歌单」快捷入口卡
  /// （见 `_buildQuickEntries`）。
  ///
  /// 2026-10-24：样式对齐飞牛「最近添加专辑」——150×150 封面 + 卡下两行
  /// （歌名 16/600、副题 12「歌手 · N 首」）；不再走 `HorizontalScrollSection`
  /// （它按 `cardSize + 60` 定容器高，会把两行文字挤扁）。
  Widget _buildRecentlyPlayed(
    BuildContext context,
    LibraryProvider libraryProvider,
    RecommendationService recommendationService,
    double hPad,
  ) {
    final l10n = AppLocalizations.of(context)!;
    // ⚠️ 修复（2026-10-22 用户反馈「最近播放不实时更新」）：原实现用
    // `libraryProvider.recentAlbums`，它其实是 `_cachedAllAlbums.take(20)`
    // （曲库列表头部，不是播放历史），只在初始化/刷新时赋值 → 永远不变。
    // 现改为从 **真实播放历史**（recentlyPlayed 歌曲 ID，最新在前）推导专辑。
    final albums =
        _recentAlbumsFromHistory(libraryProvider, recommendationService);
    if (albums.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.recentlyPlayed,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: _albumCardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: hPad),
            itemCount: albums.length,
            // 飞牛实测卡间距 13.5dp（取 14）。
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final album = albums[index];
              return _HomeAlbumCard(
                album: album,
                onTap: () => NavigationHelper.push(
                  context,
                  AlbumScreen(albumId: album.id),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 专辑卡总高：封面 150 + 6 + 歌名 ~22 + 3 + 副题 ~17 ≈ 198（留 2dp 余量）。
  static const double _albumCardHeight = 200;

  /// 由播放历史推导「最近播放的专辑」：按播放顺序去重取前 10 张。
  ///
  /// 2026-10-24：优先用 `cachedAllAlbums` 里的**完整 Album**（带 `songCount` /
  /// 规范歌手 / 封面），这样卡下的「歌手 · N 首」不用逐帧统计；缓存里找不到时
  /// 才用历史歌曲拼一个兜底 Album。
  List<Album> _recentAlbumsFromHistory(
    LibraryProvider libraryProvider,
    RecommendationService recommendationService,
  ) {
    final pool = libraryProvider.cachedAllSongs;
    if (pool.isEmpty) return const [];
    final byId = {for (final s in pool) s.id: s};
    final albumById = {for (final a in libraryProvider.cachedAllAlbums) a.id: a};
    final seen = <String>{};
    final out = <Album>[];
    for (final id in recommendationService.recentlyPlayed) {
      final song = byId[id];
      if (song == null) continue;
      final albumId = song.albumId;
      if (albumId == null || albumId.isEmpty) continue;
      if (!seen.add(albumId)) continue;
      out.add(
        albumById[albumId] ??
            Album(
              id: albumId,
              name: song.album ?? '',
              artist: song.artist,
              artistId: song.artistId,
              coverArt: song.coverArt,
            ),
      );
      if (out.length >= 10) break;
    }
    return out;
  }


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
            // 2026-10-24 用户拍板：**砍掉卡面中间的字母牌**，只留流体底 + 文字；
            // 文字整体靠右，长名称换行时**第二行优先占满**（见 `_HeroTitleText`）。
            title: playlists[i].name,
            titleMaxLines: 2,
            alignEnd: true,
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
    double hPad,
  ) {
    if (discover.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    // 2026-10-24 用户拍板：item 改飞牛行式（与「继续播放」同一套 4 行/列），
    // 「查看全部」进与收藏 / 歌单同款的 hero 头详情页（`DiscoverScreen`）。
    final songs = discover
        .take(_rowSongsPerColumn * _rowColumnsMax)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: l10n.discover,
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 8),
          actionText: l10n.seeAll,
          onActionTap: () => NavigationHelper.push(
            context,
            DiscoverScreen(
              songs: discover,
              subtitle: l10n.discoverSlogan1,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _buildSongRowColumns(songs),
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

/// 首页「最近播放」专辑卡 —— 飞牛「最近添加专辑」同款：
/// **150×150 封面（r10）** → 6 → 歌名 **16/600** → 3 → 副题 **12**「歌手 · N 首」。
///
/// 不复用 `AlbumCard`：它用的是 `bodyMedium` 字号、副题只有歌手（无「N 首」），
/// 且带 hover 播放按钮；这里按飞牛实测版式单独实现，避免影响其他页面的卡片。
class _HomeAlbumCard extends StatelessWidget {
  const _HomeAlbumCard({required this.album, this.onTap});

  final Album album;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = HomeV2Tokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    final artist = (album.artist ?? '').trim();
    final subtitle = [
      if (artist.isNotEmpty) artist,
      if (album.songCount != null) l10n.songCount(album.songCount!),
    ].join(' · ');

    return PressableScale(
      onTap: onTap,
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlbumArtwork(
              coverArt: album.coverArt,
              size: 150,
              borderRadius: 10,
            ),
            const SizedBox(height: 6),
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: tokens.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
