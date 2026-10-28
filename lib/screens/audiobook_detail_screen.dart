import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../services/audiobook_progress_store.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/audiobook_type.dart';
import '../utils/duration_format.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/audiobook_dock.dart';
import '../widgets/load_error_view.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/playing_bars.dart';
import '../widgets/luobo/sheet_shell.dart';
import 'audiobook_search_screen.dart';

/// 全局路由观察者：注册进 MaterialApp.navigatorObservers（main.dart），
/// 详情页 RouteAware 订阅它才能在从播放页 pop 回来时收到 didPopNext。
final RouteObserver<ModalRoute<void>> audiobookRouteObserver =
    RouteObserver<ModalRoute<void>>();

enum _ChapterFilter { all, unlistened, listened }

/// 有声书章节页（道理鱼，2026-10-27 无封面改版）。
///
/// 设计见 docs/有声书接入技术方案.md §15.4：
/// - 无图 hero 头：大号纯文字书封 + 书名 + 元信息 + 主胶囊 + 全书进度；
/// - `pinned` 筛选 chip 行（全部/未听/已听 + 重播本章），滚到顶栏下沿吸顶；
/// - 72dp 章节行 + 分隔线 + 行内进度条；快滑条每 50 集刻度；
/// - 滚动态返回圆钮长成「返回 + 书名」胶囊；
/// - 底部听书控制条：±15s / 播放暂停 / 倍速 / 睡眠定时。
class AudiobookDetailScreen extends StatefulWidget {
  final Audiobook book;
  final String? serverKey; // 由列表页传入；null 时自行计算

  const AudiobookDetailScreen({
    super.key,
    required this.book,
    this.serverKey,
  });

  @override
  State<AudiobookDetailScreen> createState() => _AudiobookDetailScreenState();
}

class _AudiobookDetailScreenState extends State<AudiobookDetailScreen>
    with RouteAware {
  List<AudiobookChapter> _chapters = [];
  List<AudiobookChapter> _visible = [];
  bool _isLoading = true;
  bool _isError = false;

  _ChapterFilter _filter = _ChapterFilter.all;
  int _listenedTotal = 0;

  String? _serverKey;
  final AudiobookProgressStore _store = AudiobookProgressStore.instance;
  bool _storeLoaded = false;
  AudiobookProgress? _progress;

  int? _highlightOrder;
  bool _highlightVisible = false;
  int? _targetOrder;
  bool _targetUnique = true;

  final GlobalKey _targetRowKey = GlobalKey();

  /// 头部（书封/书名/进度）测量用；定位时据其高度计算是否需要滚动。
  final GlobalKey _heroKey = GlobalKey();

  /// 章节行基础高度（itemExtent，快滑/定位按 index×行高精确计算）。
  static const double _baseRowExtent = 72.0;

  static const int _fastScrollMinChapters = 30;
  int _positionTaskEpoch = 0;

  static final Map<String, _ChapterCacheEntry> _chapterCache = {};
  static const Duration _chapterCacheTtl = Duration(seconds: 60);
  static const int _chapterCacheMaxEntries = 3;

  /// 章节列表独立 controller。
  ///
  /// 2026-10-27 最终：**头部与筛选 chip 固定，只有章节列表滚动**（进入定位
  /// 与手动滑动都不动头部）。NestedScrollView/CustomScrollView 的联动滚动
  /// 无法同时满足「进入头部不动」与「手动头部滚动」，用户要求前者，故固定头部。
  final ScrollController _listController = ScrollController();
  final ValueNotifier<bool> _showQuickNav = ValueNotifier(false);

  /// 头部（书封）是否已基本滚出视口 → 顶栏返回钮长成「返回 + 书名」胶囊。
  final ValueNotifier<bool> _collapsed = ValueNotifier(false);

  /// 快捷按钮「滚动中显示、停下 1.8s 后消失」的定时器。
  Timer? _quickNavTimer;

  /// 快滑索引条正在拖动：此时强制隐藏快捷按钮（用户 2026-10-27）。
  bool _fastScrolling = false;

  /// 进入自动定位期间抑制快捷按钮（jumpTo 会触发滚动通知，否则一进来就冒出来）。
  bool _suppressQuickNav = false;

  /// 进入页面且有定位目标时先隐身：定位完成（或超时）再显示，
  /// 避免「先停在第 1 章顶部、再跳到目标章」的一帧闪烁（用户 2026-10-27）。
  bool _awaitingInitialLocate = false;

  double _rowExtentOf(BuildContext context) =>
      _baseRowExtent *
      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);

  /// 头部实测高度（book cover + 标题 + 进度条），定位计算用；未测到时为 null。
  double? get _heroHeight {
    final box = _heroKey.currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box.size.height : null;
  }

  /// 列表前的内容总高 = 头部（筛选已移到右上角弹窗，不再占列表高度）。
  double get _headerExtent => _heroHeight ?? 0;

  /// 把第 index 章定位到的目标滚动偏移：
  /// - 已在视口内（含头部未滚走）→ 0，不做无谓滚动（用户：第 2 章不该滚）；
  /// - 否则滚到该章紧贴透明顶栏下方（头部滚走）。
  double? _targetOffsetFor(int index, double viewport, double max) {
    final hero = _heroHeight;
    if (hero == null) return null;
    final rows = _rowExtentOf(context);
    // 顶部透明 pinned 占位（statusBar+56）算进滚动内容，viewport 也是整屏，
    // 故可见判定把这段净空计回；目标偏移 hero+index*rows（占位高在行绝对位
    // 与吸顶区各出现一次、相减抵消）。
    final topInset = MediaQuery.paddingOf(context).top + 56;
    final restTop = topInset + hero + index * rows; // s=0 时该章顶部的 y
    if (restTop + rows <= viewport + 1) return 0; // 已完整可见 → 不滚
    return (hero + index * rows).clamp(0.0, max);
  }

  @override
  void initState() {
    super.initState();
    _listController.addListener(_onListScroll);
    _init();
  }

  /// 头部滚出 → 顶栏显示书名胶囊（阈值 = 头部高度 − 40，留一点提前量）。
  void _onListScroll() {
    if (!_listController.hasClients) return;
    final hero = _heroHeight;
    if (hero == null) return;
    _collapsed.value = _listController.offset > (hero - 40);
  }

  /// 列表滚动：超过阈值时**临时**浮出快捷按钮，停下 1.8s 后自动消失。
  void _updateQuickNav(double offset) {
    if (_suppressQuickNav || _fastScrolling) {
      _quickNavTimer?.cancel();
      _showQuickNav.value = false;
      return;
    }
    if (offset <= 300) {
      _quickNavTimer?.cancel();
      _showQuickNav.value = false;
      return;
    }
    _showQuickNav.value = true;
    _quickNavTimer?.cancel();
    _quickNavTimer = Timer(const Duration(milliseconds: 1800), () {
      if (mounted) _showQuickNav.value = false;
    });
  }

  Future<void> _init() async {
    await _initServerKey();
    await _loadChapters();
  }

  Future<void> _initServerKey() async {
    if (widget.serverKey != null) {
      _serverKey = widget.serverKey;
      await _loadProgress();
      return;
    }
    final subsonicService =
        Provider.of<SubsonicService>(context, listen: false);
    final config = subsonicService.config;
    if (config != null) {
      _serverKey = AudiobookProgressStore.computeServerKey(
        serverUrl: config.serverUrl,
        localUrl: config.localUrl,
        username: config.username,
      );
      await _loadProgress();
    }
  }

  Future<void> _loadProgress() async {
    final serverKey = _serverKey;
    if (serverKey == null) return;
    await _store.ensureLoaded(serverKey);
    _storeLoaded = true;
    if (mounted) {
      setState(() {
        _progress = _store.load(serverKey, widget.book.id);
        _rebuildVisible();
      });
    }
  }

  void _rebuildVisible() {
    final p = _progress;
    _listenedTotal = _chapters.where((c) => _isListened(c, p)).length;
    if (_filter == _ChapterFilter.all) {
      _visible = _chapters;
    } else {
      _visible = _chapters.where((c) {
        final listened = _isListened(c, p);
        return _filter == _ChapterFilter.listened ? listened : !listened;
      }).toList();
    }
  }

  bool _isListened(AudiobookChapter chapter, AudiobookProgress? p) {
    if (p == null) return false;
    if (p.listenedOrders.contains(chapter.order)) return true;
    // 旧数据没有集合 → 按「上次听到之前都算听过」估算。
    if (p.listenedOrders.isEmpty) return chapter.order < p.chapterOrder;
    return false;
  }

  /// 进入时定位到哪一章：**正在播本书时优先播放器的当前章**，否则用保存进度。
  ///
  /// store 进度是 5s 节流写入的，切章后可能还停留在上一章；直接用 store 会
  /// 定位到「上一章」（用户 2026-10-27：从书库进入没定位到正在播放的章节）。
  int? _readingOrder() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isPlayingThisBook = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == widget.book.id;
    if (isPlayingThisBook) {
      return player.audiobookChapterOrder ?? _progress?.chapterOrder;
    }
    return _progress?.chapterOrder;
  }

  Future<void> _loadChapters() async {
    if (!mounted) return;

    final cacheKey = '${_serverKey ?? ''}|${widget.book.id}';
    final cached = _chapterCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _chapterCacheTtl) {
      final savedOrder = _readingOrder();
      setState(() {
        _chapters = cached.chapters;
        _isLoading = false;
        _isError = false;
        _awaitingInitialLocate = savedOrder != null && savedOrder > 0;
        _rebuildVisible();
      });
      if (savedOrder != null && savedOrder > 0) {
        _setTargetOrder(savedOrder, chapters: cached.chapters);
        _triggerHighlight(savedOrder);
        _scrollToSavedChapter();
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _isError = false;
    });

    final savedOrder = _readingOrder();

    try {
      final subsonicService =
          Provider.of<SubsonicService>(context, listen: false);
      final result = await subsonicService.getAudiobookChapters(
        widget.book.id,
        skip: 0,
        take: 10000,
      );
      if (!mounted) return;

      final chapters = result.chapters
        ..sort((a, b) => a.order.compareTo(b.order));

      _chapterCache.removeWhere(
        (_, e) => DateTime.now().difference(e.at) > _chapterCacheTtl,
      );
      if (_chapterCache.length >= _chapterCacheMaxEntries) {
        final oldest = _chapterCache.entries.toList()
          ..sort((a, b) => a.value.at.compareTo(b.value.at));
        for (final e in oldest
            .take(_chapterCache.length - _chapterCacheMaxEntries + 1)) {
          _chapterCache.remove(e.key);
        }
      }
      _chapterCache[cacheKey] = _ChapterCacheEntry(DateTime.now(), chapters);
      _setTargetOrder(savedOrder, chapters: chapters);

      setState(() {
        _chapters = chapters;
        _isLoading = false;
        _awaitingInitialLocate = savedOrder != null && savedOrder > 0;
        _rebuildVisible();
      });
      if (savedOrder != null) {
        _triggerHighlight(savedOrder);
        _scrollToSavedChapter();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _isLoading = false;
      });
      showLuoboToast(
        context,
        message: AppLocalizations.of(context)!.failedToLoadChapters,
        tone: LuoboToastTone.info,
      );
    }
  }

  void _setTargetOrder(int? order, {List<AudiobookChapter>? chapters}) {
    _targetOrder = order;
    final list = chapters ?? _chapters;
    if (order == null) {
      _targetUnique = true;
      return;
    }
    _targetUnique = list.where((c) => c.order == order).length == 1;
  }

  void _triggerHighlight(int order) {
    if (!_chapters.any((c) => c.order == order)) return;
    setState(() {
      _highlightOrder = order;
      _highlightVisible = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _highlightVisible = false);
    });
  }

  /// 进入时定位：只 `jumpTo` 内层列表，头部不动（NestedScrollView 内层）。
  void _scrollToSavedChapter() {
    _suppressQuickNav = true;
    _quickNavTimer?.cancel();
    _showQuickNav.value = false;
    final epoch = ++_positionTaskEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryScrollToSaved(epoch, 0);
    });
  }

  void _endQuickNavSuppression() {
    // 定位结束 → 显示列表（若之前为隐身）。
    if (_awaitingInitialLocate && mounted) {
      setState(() => _awaitingInitialLocate = false);
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _suppressQuickNav = false;
    });
  }

  Future<void> _tryScrollToSaved(int epoch, int attempt) async {
    if (!mounted || epoch != _positionTaskEpoch) return;
    final index = _visible.indexWhere((c) => c.order == _targetOrder);
    final list = _listController;

    if (index < 0 ||
        !list.hasClients ||
        list.position.viewportDimension <= 0 ||
        _heroHeight == null) {
      if (attempt < 12) {
        await Future.delayed(const Duration(milliseconds: 60));
        return _tryScrollToSaved(epoch, attempt + 1);
      }
      debugPrint(
        '[Audiobook] locate failed: index=$index '
        'hasClients=${list.hasClients} hero=$_heroHeight '
        'visible=${_visible.length} targetOrder=$_targetOrder',
      );
      _endQuickNavSuppression();
      return;
    }

    final target = _targetOffsetFor(
      index,
      list.position.viewportDimension,
      list.position.maxScrollExtent,
    );
    if (target == null) {
      _endQuickNavSuppression();
      return;
    }
    if ((list.offset - target).abs() > 1) list.jumpTo(target);
    debugPrint(
      '[Audiobook] locate ok: index=$index target=$target '
      'offset=${list.offset} hero=$_heroHeight',
    );
    _endQuickNavSuppression();
  }

  Future<void> _playChapter(
    AudiobookChapter chapter, {
    AudiobookProgress? progress,
  }) async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final ok = await player.playAudiobookChapter(
      widget.book,
      _chapters,
      _chapters.indexWhere((c) => c.id == chapter.id),
      resumePositionMs: (progress != null && !progress.completed)
          ? progress.positionMs
          : null,
      chaptersComplete: true,
    );
    if (!ok && mounted) {
      showLuoboToast(
        context,
        message: AppLocalizations.of(context)!.failedToLoadChapters,
        tone: LuoboToastTone.info,
      );
    }
  }

  /// 重播本章：正在播本书 → 当前章 seek(0)；否则取保存章节从 0 播。
  Future<void> _replayChapter() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    if (player.isPlayingAudiobook &&
        player.currentAudiobook?.id == widget.book.id) {
      await player.seek(Duration.zero);
      return;
    }
    final order = _progress?.chapterOrder;
    if (order == null) return;
    final index = _chapters.indexWhere((c) => c.order == order);
    if (index >= 0) await _playChapter(_chapters[index]);
  }

  Future<void> _showChapterActions(AudiobookChapter chapter) async {
    final l10n = AppLocalizations.of(context)!;
    final listened = _isListened(chapter, _progress);
    final action = await showLuoboSheet<String>(
      context: context,
      title: chapter.title,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LuoboSheetRow(
            title: l10n.playFromHere,
            showChevron: false,
            onTap: () => Navigator.of(ctx).pop('play'),
          ),
          LuoboSheetRow(
            title: listened ? l10n.markUnlistened : l10n.markListened,
            showChevron: false,
            onTap: () => Navigator.of(ctx).pop('toggle'),
          ),
        ],
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'play') {
      await _playChapter(chapter);
    } else if (action == 'toggle') {
      _toggleListened(chapter);
    }
  }

  void _toggleListened(AudiobookChapter chapter) {
    final serverKey = _serverKey;
    if (serverKey == null) return;
    final current = _progress ??
        AudiobookProgress(
          audiobookId: widget.book.id,
          chapterOrder: 1,
          positionMs: 0,
          episodeCount: widget.book.episodeCount,
          updatedAt: DateTime.now(),
        );
    final listened = _isListened(chapter, current);
    final next = listened
        ? current.withoutListenedChapter(chapter.order)
        : current.withListenedChapter(chapter.order);
    final saved = next.copyWith(updatedAt: DateTime.now());
    _store.save(serverKey, saved);
    setState(() {
      _progress = saved;
      _rebuildVisible();
    });
  }

  void _setFilter(_ChapterFilter filter) {
    if (_filter == filter) return;
    setState(() {
      _filter = filter;
      _rebuildVisible();
    });
    // 若当前进度章仍在结果内，滚回它；否则停留在顶部。
    final target = _progress?.chapterOrder;
    if (target != null) {
      final index = _visible.indexWhere((c) => c.order == target);
      if (index >= 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !_listController.hasClients) return;
          final target = _targetOffsetFor(
            index,
            _listController.position.viewportDimension,
            _listController.position.maxScrollExtent,
          );
          if (target != null) _listController.jumpTo(target);
        });
      }
    }
  }

  /// 书内搜索：返回纯数字时直接跳到该集（合集型按标题搜，编号型按号跳）。
  Future<void> _openSearch() async {
    final order = await Navigator.of(context).push<int>(
      MaterialPageRoute(
        builder: (_) => AudiobookSearchScreen(
          book: widget.book,
          chapters: _chapters,
        ),
      ),
    );
    if (!mounted || order == null) return;
    _jumpToOrder(order);
  }

  void _jumpToOrder(int order) {
    var index = _visible.indexWhere((c) => c.order == order);
    if (index < 0) {
      index = _visible.indexWhere((c) => c.order >= order);
    }
    if (index < 0) return;
    final targetOrder = _visible[index].order;
    _setTargetOrder(targetOrder);
    _triggerHighlight(targetOrder);
    if (!_listController.hasClients) return;
    // 手动跳转（搜索/目录）：目标在前几章时不滚（_targetOffsetFor 返回 0），
    // 否则滚到紧贴吸顶 chip 下方。
    final target = _targetOffsetFor(
      index,
      _listController.position.viewportDimension,
      _listController.position.maxScrollExtent,
    );
    if (target != null) _listController.jumpTo(target);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null) {
      audiobookRouteObserver.subscribe(this, route);
    }
  }

  @override
  void didPopNext() {
    if (!_storeLoaded) return;
    final serverKey = _serverKey;
    if (serverKey != null && mounted) {
      setState(() {
        _progress = _store.load(serverKey, widget.book.id);
        _rebuildVisible();
      });
    }
  }

  @override
  void dispose() {
    audiobookRouteObserver.unsubscribe(this);
    _quickNavTimer?.cancel();
    _listController.removeListener(_onListScroll);
    _listController.dispose();
    _showQuickNav.dispose();
    _collapsed.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const LuoboListTopBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_isError && _chapters.isEmpty) {
      return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: const LuoboListTopBar(),
        body: LoadErrorView(
          title: l10n.failedToLoadChapters,
          retryLabel: l10n.retry,
          onRetry: _loadChapters,
        ),
      );
    }

    return Scaffold(
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          final isCurrentBook = player.isPlayingAudiobook &&
              player.currentAudiobook?.id == widget.book.id;
          final hasDock = isCurrentBook;
          final rowExtent = _rowExtentOf(context);
          final bottomInset = hasDock
              ? 90 + MediaQuery.paddingOf(context).bottom
              : 24.0;

          return Stack(
            children: [
              // 单层 CustomScrollView：hero + pinned chips + 列表**一起滚动**
              // （用户 2026-10-27：接受整体滚动，拒绝固定头部）。
              // 进入定位期间隐身（仍布局以测量/跳转），定位完成淡入，去掉跳闪。
              // 透明顶栏：内容从顶栏（透明）后穿过滚动，和歌手/专辑详情一致。
              // 顶部净空用**首个透明 pinned 占位**（statusBar+56 高）承担，而不是
              // 外层 Padding —— 外层 Padding 会把滚动视图整体下移、内容在栏下沿被
              // 硬裁断，看起来就是「一条不透明导航栏」（list_top_bar.dart 已记此坑）。
              // 占位排在最前 → 筛选 chip 吸顶位置天然落在它（= 顶栏）下方。
              AnimatedOpacity(
                opacity: _awaitingInitialLocate ? 0 : 1,
                duration: const Duration(milliseconds: 120),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n.metrics.axis == Axis.vertical) {
                      _updateQuickNav(n.metrics.pixels);
                    }
                    return false;
                  },
                  child: CustomScrollView(
                    controller: _listController,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _PinnedHeaderDelegate(
                          height: MediaQuery.paddingOf(context).top + 56,
                          child: const SizedBox.expand(),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: KeyedSubtree(
                          key: _heroKey,
                          child: _buildHeroHeader(l10n, isDark, player),
                        ),
                      ),
                      SliverFixedExtentList(
                        itemExtent: rowExtent,
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildChapterRow(
                            _visible[index],
                            index,
                            player,
                            isDark,
                            l10n,
                          ),
                          childCount: _visible.length,
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
                    ],
                  ),
                ),
              ),
              // 快滑索引条（列表内容区右侧）。
              if (_visible.length >= _fastScrollMinChapters)
                Positioned(
                  right: 0,
                  top: MediaQuery.paddingOf(context).top + 56,
                  bottom: 0,
                  child: _FastScrollBar(
                    itemCount: _visible.length,
                    itemExtent: rowExtent,
                    controller: _listController,
                    headerExtent: _headerExtent,
                    onDragStateChanged: (dragging) {
                      _fastScrolling = dragging;
                      _quickNavTimer?.cancel();
                      _showQuickNav.value = false;
                    },
                    labelBuilder: (index) {
                      final c = _visible[index];
                      return '第 ${c.order} 集 · ${c.title}';
                    },
                    tickEvery: _visible.length >= 200 ? 50 : 0,
                    tickLabelBuilder: (index) => '${_visible[index].order}',
                  ),
                ),
              _buildTopBar(context, l10n),
              // 滑动超过一屏：靠边浮出「到顶 / 到底 / 到播放章」三个按钮。
              ValueListenableBuilder<bool>(
                valueListenable: _showQuickNav,
                builder: (context, show, _) {
                  if (!show) return const SizedBox.shrink();
                  return Positioned(
                    // 贴右边缘；与快滑索引条有约 24dp 重叠（按钮在上层，
                    // 快滑条上下大部分仍可拖动）。放左侧会长期挡住章节序号。
                    right: 12,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _QuickNavButton(
                            icon: AppIcons.arrowUp,
                            onTap: _scrollToTop,
                          ),
                          const SizedBox(height: 10),
                          _QuickNavButton(
                            icon: Icons.my_location_rounded,
                            onTap: _scrollToPlayingChapter,
                          ),
                          const SizedBox(height: 10),
                          _QuickNavButton(
                            icon: AppIcons.arrowDown,
                            onTap: _scrollToBottom,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              if (hasDock)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AudiobookDock(
                    player: player,
                    book: widget.book,
                    onTitleTap: _scrollToPlayingChapter,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ── 快捷跳转（到顶 / 到底 / 到播放章）───────────────────────────────

  /// 到顶部：**先内层归零，再外层归零**（同时 animate 会互相打断，导致「差一点」）。
  /// 到顶部：只滚章节列表（头部固定不动）。
  Future<void> _scrollToTop() async {
    if (!_listController.hasClients) return;
    await _listController.animateTo(
      0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  /// 到底部：只滚章节列表。
  Future<void> _scrollToBottom() async {
    if (!_listController.hasClients) return;
    await _listController.animateTo(
      _listController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _scrollToPlayingChapter() {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final isThisBook = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == widget.book.id;
    final order = isThisBook
        ? player.audiobookChapterOrder
        : _progress?.chapterOrder;
    if (order == null) return;

    // 当前筛选可能把目标章排除了 → 先切回「全部」再定位（否则点了没反应）。
    if (_filter != _ChapterFilter.all &&
        !_visible.any((c) => c.order == order)) {
      setState(() {
        _filter = _ChapterFilter.all;
        _rebuildVisible();
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToOrder(order));
      return;
    }
    _jumpToOrder(order);
  }

  // ── 头部 ──────────────────────────────────────────────────────────────

  Widget _buildHeroHeader(
    AppLocalizations l10n,
    bool isDark,
    PlayerProvider player,
  ) {
    final c = LuoboColors.of(context);
    final book = widget.book;
    final meta = [
      if (book.narrator != null && book.narrator!.isNotEmpty) book.narrator!,
      if (audiobookDisplayCategory(book) != null)
        audiobookDisplayCategory(book)!,
      l10n.chapterCount(book.episodeCount),
      if (book.totalDurationSeconds != null && book.totalDurationSeconds! > 0)
        _humanDuration(l10n, book.totalDurationSeconds!),
    ].join(' · ');

    final progress = _progress;
    final isThisBook = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == book.id;
    final ratio = _liveRatio(player);
    final remaining = _remainingSeconds(book, progress, ratio);
    final hasProgress =
        (progress != null && !progress.completed) || isThisBook;
    final displayOrder = isThisBook
        ? (player.audiobookChapterOrder ?? progress?.chapterOrder)
        : progress?.chapterOrder;

    return Padding(
      // 顶部留白给悬浮顶栏（状态栏 + 56）让位。
      // CustomScrollView 已被外层 Padding 下移 statusBar+56，这里只留小间距。
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          AudiobookCover(
            title: book.title,
            size: AudiobookCoverSize.large,
            narrator: book.narrator,
            category: audiobookDisplayCategory(book),
            elevated: true,
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              book.title,
              style: LuoboType.navTitle.copyWith(fontSize: 25, color: c.fg),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              meta,
              style: LuoboType.caption.copyWith(color: c.fg2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150),
            child: LuoboHeroCapsule(
              icon: AppIcons.play,
              label: hasProgress && displayOrder != null
                  ? '${l10n.continueListening} · ${l10n.chapterX(displayOrder)}'
                  : l10n.play,
              onTap: hasProgress && displayOrder != null
                  ? () {
                      final index = _chapters
                          .indexWhere((c) => c.order == displayOrder);
                      if (index >= 0) {
                        _playChapter(
                          _chapters[index],
                          progress: (progress != null &&
                                  progress.chapterOrder == displayOrder)
                              ? progress
                              : null,
                        );
                      }
                    }
                  : () {
                      if (_chapters.isNotEmpty) _playChapter(_chapters.first);
                    },
            ),
          ),
          const SizedBox(height: 14),
          if (ratio != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    l10n.listenedPercent((ratio * 100).round()),
                    style: LuoboType.caption.copyWith(color: c.fg2),
                  ),
                  const Spacer(),
                  if (remaining != null)
                    Text(
                      l10n.remainingTime(_humanDuration(l10n, remaining)),
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _RatioBar(value: ratio, height: 4),
            ),
            // 进度条到 chip 的间距由 chip 行的 14dp 内边距承担（两侧对称）。
          ] else
            // 无整本书进度时也别加额外间距：否则 chip 距上 28、距下 14，
            // 看起来就像贴着分割线（用户 2026-10-27）。
            const SizedBox.shrink(),
        ],
      ),
    );
  }

  // ── 悬浮顶栏 ──────────────────────────────────────────────────────────

  /// 悬浮顶栏：头部可见时左侧是返回圆钮；头部滚出后长成「返回 + 书名」胶囊
  /// （同歌手详情折叠形态，用户 2026-10-27）。右侧始终是搜索圆钮。
  Widget _buildTopBar(BuildContext context, AppLocalizations l10n) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: _collapsed,
                  builder: (context, collapsed, _) => AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    // 左对齐：AnimatedSwitcher 无 alignment，默认 layoutBuilder 用
                    // center Stack，会把 40dp 圆钮居中摆在胶囊宽度里，胶囊移除、
                    // Stack 宽度塌回 40 时圆钮从中间跳回最左 → 用户看到的「跳变」。
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        ...previous,
                        if (current != null) current,
                      ],
                    ),
                    child: collapsed
                        ? ConstrainedBox(
                            key: const ValueKey('pill'),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.sizeOf(context).width - 120,
                            ),
                            child: LuoboBackTitlePill(title: widget.book.title),
                          )
                        : LuoboTopCircleButton(
                            key: const ValueKey('circle'),
                            icon: AppIcons.back,
                            onTap: () => Navigator.of(context).maybePop(),
                          ),
                  ),
                ),
                const Spacer(),
                LuoboTopCircleButton(
                  icon: AppIcons.filter,
                  onTap: _showFilterSheet,
                ),
                const SizedBox(width: 10),
                LuoboTopCircleButton(
                  icon: AppIcons.search,
                  onTap: _openSearch,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 筛选弹窗（右上角入口）──────────────────────────────────────────────

  /// 右上角筛选钮 → 底部单选面板（飞牛同款）：全部 / 未听 / 已听 三档带计数，
  /// 底部附「重播本章」（有未完成进度时）。原吸顶 chip 行在透明顶栏下显得悬空，
  /// 改为弹窗（用户 2026-10-27）。
  Future<void> _showFilterSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final total = _chapters.length;
    final unlistened = math.max(0, total - _listenedTotal);
    final canReplay = _progress != null && !_progress!.completed;

    await showLuoboSheet<void>(
      context: context,
      title: l10n.chapterFilter,
      builder: (ctx) {
        final c = LuoboColors.of(ctx);
        Widget countBadge(int n) => Text(
              '$n',
              style: LuoboType.caption.copyWith(color: c.fg2),
            );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LuoboSheetRow(
              title: l10n.filterAll,
              trailing: countBadge(total),
              selected: _filter == _ChapterFilter.all,
              showChevron: false,
              onTap: () {
                _setFilter(_ChapterFilter.all);
                Navigator.of(ctx).pop();
              },
            ),
            LuoboSheetRow(
              title: l10n.filterUnlistened,
              trailing: countBadge(unlistened),
              selected: _filter == _ChapterFilter.unlistened,
              showChevron: false,
              onTap: () {
                _setFilter(_ChapterFilter.unlistened);
                Navigator.of(ctx).pop();
              },
            ),
            LuoboSheetRow(
              title: l10n.filterListened,
              trailing: countBadge(_listenedTotal),
              selected: _filter == _ChapterFilter.listened,
              showChevron: false,
              onTap: () {
                _setFilter(_ChapterFilter.listened);
                Navigator.of(ctx).pop();
              },
            ),
            if (canReplay) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 2, 4, 10),
                child: Divider(height: 0.5, thickness: 0.5, color: c.divider),
              ),
              LuoboSheetRow(
                title: l10n.replayChapter,
                leading: const Icon(
                  CupertinoIcons.arrow_counterclockwise,
                  size: 18,
                  color: LuoboAccent.accent,
                ),
                showChevron: false,
                onTap: () {
                  Navigator.of(ctx).pop();
                  _replayChapter();
                },
              ),
            ],
          ],
        );
      },
    );
  }

  // ── 章节行 ────────────────────────────────────────────────────────────

  Widget _buildChapterRow(
    AudiobookChapter chapter,
    int index,
    PlayerProvider player,
    bool isDark,
    AppLocalizations l10n,
  ) {
    final c = LuoboColors.of(context);
    final p = _progress;
    final isCurrentBook = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == widget.book.id;
    final isCurrent = isCurrentBook &&
        player.audiobookChapterOrder == chapter.order;
    final listened = _isListened(chapter, p);
    final isSavedChapter = p != null && p.chapterOrder == chapter.order;
    // 「上次播放章」样式只在**本书未在播放**时出现（冷启 / 在播别的书）：用来
    // 指示「从这里续听」。本书正在播时只有真正在播的那一章高亮——否则缓存的
    // `_progress`（_playChapter 不会即时刷新）还停在旧章，会和当前章一起高亮
    // （用户 2026-10-27：在播第 3 章、点了第 4 章，3、4 两行都高亮）。
    final isResumeChapter =
        !isCurrentBook && isSavedChapter && !p.completed;
    // 高亮：当前播放章 + 上次播放章都用同一套「正在播放」样式。
    final shouldHighlight = isCurrent || isResumeChapter;
    // 只有「既非当前、也非上次播放章」的已听章才显示 ✓/已听完。
    final showListened = listened && !isCurrent && !isResumeChapter;
    // 行内进度/「已播至」也只在未播本书时显示：本书在播时进度看吸底条，
    // 行上再按旧快照画一条就是过期信息。
    final playedMs =
        !isCurrentBook && isSavedChapter && !p.completed ? p.positionMs : 0;
    final durationMs = !isCurrentBook && isSavedChapter ? p.durationMs : null;
    final showBar = playedMs > 0 && (durationMs ?? 0) > 0;

    final durationText = (chapter.durationSeconds != null &&
            chapter.durationSeconds! > 0)
        ? formatDuration(chapter.durationSeconds!)
        : '';
    String? state;
    if (showListened) {
      state = l10n.finished;
    } else if (playedMs > 0) {
      final played = formatDurationMs(playedMs);
      if (played.isNotEmpty) state = l10n.playedTo(played);
    }
    final subtitle = [
      if (state != null) state,
      if (durationText.isNotEmpty) durationText,
    ].join(' · ');

    final accent = LuoboAccent.accent;
    final highlight = _highlightVisible && _highlightOrder == chapter.order;

    return Container(
      key: _targetUnique && chapter.order == _targetOrder
          ? _targetRowKey
          : null,
      decoration: BoxDecoration(
        color: highlight
            ? accent.withValues(alpha: 0.12)
            : (shouldHighlight
                // 暗色下 5% 几乎看不见（用户 2026-10-27），提到 16%。
                ? accent.withValues(alpha: isDark ? 0.16 : 0.06)
                : Colors.transparent),
        border: Border(
          left: shouldHighlight
              ? const BorderSide(color: LuoboAccent.accent, width: 3)
              : BorderSide.none,
          bottom: BorderSide(
            color: c.divider.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      child: InkWell(
        // 点击「上次播放章」续播到保存位置（冷启/在播别的书时）；点其它章从 0 起。
        // 否则冷启点进度章会从 0:00 重放（用户 2026-10-28：记录了 12 分却从头播）。
        onTap: () => _playChapter(chapter, progress: isResumeChapter ? p : null),
        onLongPress: () => _showChapterActions(chapter),
        child: Padding(
          padding: const EdgeInsets.only(left: 16, right: 16),
          child: Row(
            children: [
              SizedBox(
                width: 32,
                child: Center(
                  child: isCurrent
                      ? (player.isPlaying
                          ? PlayingBars(size: 14, color: accent)
                          : Icon(AppIcons.play, size: 13, color: accent))
                      // 上次播放章：沿用「正在播放」底色/竖条/红标题，
                      // 左侧用**红色三角**（用户 2026-10-27）。
                      : isResumeChapter
                          ? Icon(AppIcons.play, size: 12, color: accent)
                          : showListened
                              ? Icon(AppIcons.check, size: 13, color: c.fg3)
                              : Text(
                                    '${chapter.order}',
                                    style: LuoboType.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: c.fg2,
                                    ),
                                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chapter.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        color: shouldHighlight ? accent : c.fg,
                        fontWeight: shouldHighlight
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                    if (showBar) ...[
                      const SizedBox(height: 5),
                      _RatioBar(
                        value: (playedMs / durationMs!).clamp(0.0, 1.0),
                        height: 2,
                      ),
                    ],
                  ],
                ),
              ),
              // 行尾不再重复放播放三角：左侧状态列已经表达了「当前/上次位置」，
              // 点整行即播放（用户 2026-10-27：左右两边都有一个红色三角）。
            ],
          ),
        ),
      ),
    );
  }

  /// 全书进度：正在播本书时用**播放器实时位置**重算，否则用保存进度。
  ///
  /// 用户 2026-10-27：「播放时有声书的进度条没有进度」——原实现只读进入页面时
  /// 的 `_progress`，播放过程中不更新。gapless 下必须用章节内位置。
  double? _liveRatio(PlayerProvider player) {
    final p = _progress;
    final total = widget.book.episodeCount;
    if (total <= 0) return null;

    final isThisBook = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == widget.book.id;
    final chapterDuration = player.chapterDuration;
    if (!isThisBook || chapterDuration.inMilliseconds <= 0) {
      return p?.progressRatio(totalEpisodes: total);
    }

    final currentOrder =
        player.audiobookChapterOrder ?? p?.chapterOrder ?? 1;
    var listened = 0;
    if (p != null && p.listenedOrders.isNotEmpty) {
      listened = p.listenedOrders
          .where((o) => o != currentOrder && o >= 1 && o <= total)
          .length;
    } else {
      listened = (currentOrder - 1).clamp(0, total);
    }
    final fraction = (player.chapterPosition.inMilliseconds /
            chapterDuration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
    return ((listened + fraction) / total).clamp(0.0, 1.0).toDouble();
  }

  int? _remainingSeconds(
    Audiobook book,
    AudiobookProgress? progress,
    double? liveRatio,
  ) {
    final total = book.totalDurationSeconds;
    if (total == null || total <= 0) return null;
    final ratio = liveRatio ??
        progress?.progressRatio(totalEpisodes: book.episodeCount) ??
        0;
    return (total * (1 - ratio)).round().clamp(0, total);
  }

  String _humanDuration(AppLocalizations l10n, int seconds) {
    if (seconds <= 0) return l10n.durationMinutes(0);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return l10n.durationHoursMinutes(h, m);
    return l10n.durationMinutes(m);
  }
}

/// 章节列表会话内缓存条目。
class _ChapterCacheEntry {
  final DateTime at;
  final List<AudiobookChapter> chapters;

  const _ChapterCacheEntry(this.at, this.chapters);
}

/// 固定高度的 pinned sliver（筛选 chip 吸顶用）。
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _PinnedHeaderDelegate({required this.height, required this.child});

  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) =>
      child;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate old) =>
      old.height != height || old.child != child;
}

/// 长列表快捷跳转圆钮（到顶 / 到底 / 到播放章）。
class _QuickNavButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QuickNavButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: c.card,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: c.isDark ? 0.5 : 0.16),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: c.fg),
      ),
    );
  }
}

/// 细进度条（4dp/3dp/2dp 共用）。
class _RatioBar extends StatelessWidget {
  final double value;
  final double height;

  const _RatioBar({required this.value, required this.height});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: c.divider)),
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: value.clamp(0.0, 1.0),
                child: const ColoredBox(color: LuoboAccent.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 右侧快滑索引条：拖动气泡显示「第 N 集 · 标题」，每 [tickEvery] 项一个刻度。
class _FastScrollBar extends StatefulWidget {
  final int itemCount;
  final double itemExtent;
  final ScrollController controller;
  final double headerExtent;
  final String Function(int index) labelBuilder;
  final int tickEvery;
  final String Function(int index)? tickLabelBuilder;

  /// 拖动开始/结束回调（用于隐藏快捷跳转按钮）。
  final ValueChanged<bool>? onDragStateChanged;

  const _FastScrollBar({
    required this.itemCount,
    required this.itemExtent,
    required this.controller,
    required this.headerExtent,
    required this.labelBuilder,
    this.tickEvery = 0,
    this.tickLabelBuilder,
    this.onDragStateChanged,
  });

  @override
  State<_FastScrollBar> createState() => _FastScrollBarState();
}

class _FastScrollBarState extends State<_FastScrollBar> {
  int? _hoverIndex;

  int _indexForDy(double dy, double height) {
    final t = (dy / height).clamp(0.0, 1.0);
    return (t * (widget.itemCount - 1)).round();
  }

  void _jump(int index) {
    if (!widget.controller.hasClients) return;
    widget.controller.jumpTo(
      (widget.headerExtent + index * widget.itemExtent)
          .clamp(0.0, widget.controller.position.maxScrollExtent),
    );
  }

  void _handle(double dy, double height) {
    final index = _indexForDy(dy, height);
    if (index == _hoverIndex) return;
    setState(() => _hoverIndex = index);
    _jump(index);
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final accent = LuoboAccent.accent;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        if (height < 56) return const SizedBox(width: 36);

        final total = widget.itemCount;
        final hover = _hoverIndex;
        final thumbH =
            (height * (height / (total * widget.itemExtent))).clamp(40.0, height);
        final thumbTop =
            hover == null ? 0.0 : (height - thumbH) * (hover / (total - 1));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) {
            widget.onDragStateChanged?.call(true);
            _handle(d.localPosition.dy, height);
          },
          onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, height),
          onVerticalDragEnd: (_) {
            widget.onDragStateChanged?.call(false);
            setState(() => _hoverIndex = null);
          },
          onTapDown: (d) => _jump(_indexForDy(d.localPosition.dy, height)),
          child: SizedBox(
            width: 36,
            child: Stack(
              alignment: Alignment.center,
              // ⚠️ 气泡（宽 220）超出 36 宽容器，默认硬裁剪会只剩贴边一小条红块
              // （用户 2026-10-27 截图反馈的「异常红色」）。
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 3,
                  height: double.infinity,
                  margin: const EdgeInsets.only(right: 0),
                  decoration: BoxDecoration(
                    color: hover == null
                        ? Colors.transparent
                        : accent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 刻度（每 50 集）。
                if (widget.tickEvery > 0)
                  for (var i = 0; i < total; i += widget.tickEvery)
                    Positioned(
                      right: 15,
                      top: (i / (total - 1) * height - 5)
                          .clamp(0.0, height - 10),
                      child: Text(
                        widget.tickLabelBuilder?.call(i) ??
                            widget.labelBuilder(i),
                        style: TextStyle(
                          fontSize: 8.5,
                          color: c.fg3,
                          height: 1,
                        ),
                      ),
                    ),
                Positioned(
                  top: thumbTop,
                  // 居中于轨道（容器宽 36、轨道中心 18）。
                  right: hover == null ? 13 : 12,
                  child: Container(
                    // 拖动时加宽（10 → 12），更跟手、不像一个「半圆点」。
                    width: hover == null ? 10 : 12,
                    height: thumbH,
                    decoration: BoxDecoration(
                      color: hover == null
                          ? c.fg3.withValues(alpha: 0.75)
                          : accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                if (hover != null && hover < total)
                  Positioned(
                    // 紧贴 thumb 左缘，避免中间露出「半圆形红色」的错觉。
                    right: 22,
                    top: (thumbTop + thumbH / 2 - 16)
                        .clamp(4.0, height - 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.labelBuilder(hover),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
