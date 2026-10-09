import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../services/audiobook_progress_store.dart';
import '../services/subsonic_service.dart';
import '../utils/audiobook_type.dart';
import '../utils/duration_format.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/load_error_view.dart';
import 'audiobook_search_screen.dart';

/// 全局路由观察者：注册进 MaterialApp.navigatorObservers（main.dart），
/// 详情页 RouteAware 订阅它才能在从播放页 pop 回来时收到 didPopNext。
/// C004 修复：页面自建 RouteObserver 不注册到 Navigator 时 didPopNext 永不触发。
final RouteObserver<ModalRoute<void>> audiobookRouteObserver =
    RouteObserver<ModalRoute<void>>();

/// 有声书章节列表页（道理鱼，**连续滚动**）。
///
/// 设计见 docs/有声书接入技术方案.md §7.3 + 改版讨论（2026-08-21）：
/// - 进入一次全量拉取章节（`take: 10000`，与 playAudiobookChapter 同一条
///   全量路径），不再页码分页——删除页码栏/请求序号防竞态/页码直跳整套；
/// - 顶部轻量 header：封面 64 + 书名/演播者/元信息 + 紧凑续播按钮
///   （B 档，不做大 hero 进度环）；
/// - 有保存进度的章节行显示「已播至 mm:ss」+ 恢复图标；
/// - 正在播放章节实时高亮（Consumer of PlayerProvider）；
/// - 进入自动 scroll 定位到已保存章节并短暂高亮；
/// - RouteAware.didPopNext 重读进度（从播放页返回刷新）。
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
  bool _isLoading = true;
  bool _isError = false;

  /// 本书内容类型（§7.4）：决定 AppBar 显示章节直跳（编号型）还是搜索（合集型）。
  AudiobookContentType? _contentType;

  String? _serverKey;
  final AudiobookProgressStore _store = AudiobookProgressStore.instance;
  bool _storeLoaded = false;
  AudiobookProgress? _progress; // 本书已保存的进度（用于"已播至"/恢复图标）

  /// 进入页面时短暂高亮的章节 order（~1.5s 淡出）。
  int? _highlightOrder;
  bool _highlightVisible = false;

  /// 进入时定位的章节 order（保存进度的章节），用于滚动定位 + 高亮。
  int? _targetOrder;

  /// 目标 order 是否在列表内**唯一**：服务端异常返回重复 order 时，
  /// 若仍把单一 GlobalKey 挂到多行会抛 Duplicate GlobalKey 崩溃（P3 修复）。
  bool _targetUnique = true;

  final GlobalKey _targetRowKey = GlobalKey();

  /// 设置定位目标并预计算唯一性（避免每行构建时 O(n) 扫描）。
  void _setTargetOrder(int? order, {List<AudiobookChapter>? chapters}) {
    _targetOrder = order;
    final list = chapters ?? _chapters;
    if (order == null) {
      _targetUnique = true;
      return;
    }
    _targetUnique = list.where((c) => c.order == order).length == 1;
  }

  /// 章节行基础高度（系统字号 1.0 时）。ListView 用 itemExtent 固定行高，
  /// 进入定位可按 `index * 实际行高` **精确** jumpTo（P2 修复：此前按平均行高
  /// 估算，长书末尾章节误差累积导致目标行未构建、定位+高亮静默失效）。
  static const double _baseRowExtent = 72.0;

  /// 章节行实际高度：随系统字号放宽（上限 1.5×）。行内含标题+副标题+尾部
  /// 按钮，大字号下 72px 会 RenderFlex 溢出；与列表页网格的 textScalerOf
  /// 处理保持一致。所有 `index × 行高` 的定位计算必须复用本方法。
  double _rowExtentOf(BuildContext context) =>
      _baseRowExtent *
      MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.5);

  /// 快滑索引条显示阈值：章节数 ≥ 此值才显示（§7.4；2026-08-21 真机调低：
  /// 三体 42 章也值得有索引条，30 章 ≈ 2160px 列表）。
  static const int _fastScrollMinChapters = 30;

  /// 定位任务世代：重试连点/重入时递增，旧任务在异步间隙放弃（P3 修复）。
  int _positionTaskEpoch = 0;

  /// 会话内章节缓存：详情页重进/重试避免重复全量拉取（R002 修复）。
  /// key = serverKey|bookId；TTL 60s——连载书内容可能更新，不做永久缓存。
  static final Map<String, _ChapterCacheEntry> _chapterCache = {};
  static const Duration _chapterCacheTtl = Duration(seconds: 60);

  /// 缓存条数上限：TTL 清理只在插入时触发，长会话里浏览多本大书后不再进新书
  /// 会一直留着过期条目（单条目是 take:10000 的全量章节，可达 MB 级），
  /// 因此按条数封顶，超出时按插入时间淘汰最旧的一本。
  static const int _chapterCacheMaxEntries = 3;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// C001 修复：必须先 await serverKey 初始化（加载进度），再加载章节——
  /// 否则 _loadChapters 读 _progress 时必为 null，定位到保存章节
  /// 的功能 100% 失效。
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
      });
    }
  }

  /// 一次全量拉取全书章节（连续滚动，无分页）。
  Future<void> _loadChapters() async {
    // 复审 P2：_init 在 await _initServerKey 之后才调 _loadChapters，间隙中
    // 用户可能已 pop 页面 → setState 前必须检查 mounted（与 _loadProgress 一致）。
    if (!mounted) return;

    // 会话内缓存命中（R002）：TTL 内直接复用，跳过加载态与网络请求。
    final cacheKey = '${_serverKey ?? ''}|${widget.book.id}';
    final cached = _chapterCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.at) < _chapterCacheTtl) {
      final savedOrder = _progress?.chapterOrder;
      setState(() {
        _chapters = cached.chapters;
        _isLoading = false;
        _isError = false;
        // 类型判断：缓存路径同样需要（§7.4）。
        _contentType =
            classifyAudiobookType(book: widget.book, chapters: cached.chapters);
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

    // 有保存进度 → 进入时定位到该章节（scroll + 高亮）。
    final savedOrder = _progress?.chapterOrder;

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
      // 写入缓存并顺手清理过期条目（防无限增长）。
      _chapterCache.removeWhere(
        (_, e) => DateTime.now().difference(e.at) > _chapterCacheTtl,
      );
      // 条数封顶：保留最近插入的 _chapterCacheMaxEntries 本（含本次）。
      if (_chapterCache.length >= _chapterCacheMaxEntries) {
        final oldest = _chapterCache.entries.toList()
          ..sort((a, b) => a.value.at.compareTo(b.value.at));
        for (final e in oldest
            .take(_chapterCache.length - _chapterCacheMaxEntries + 1)) {
          _chapterCache.remove(e.key);
        }
      }
      _chapterCache[cacheKey] = _ChapterCacheEntry(DateTime.now(), chapters);
      // 定位目标（唯一性基于最新全量列表计算）。
      _setTargetOrder(savedOrder, chapters: chapters);

      setState(() {
        _chapters = chapters;
        _isLoading = false;
        // 类型判断（§7.4）：编号型→章节直跳，合集型→书内搜索。
        _contentType =
            classifyAudiobookType(book: widget.book, chapters: chapters);
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLoadChapters),
        ),
      );
    }
  }

  void _triggerHighlight(int order) {
    // 章节可能已被服务端下架 → 只高亮当前列表里还存在的。
    if (!_chapters.any((c) => c.order == order)) return;
    setState(() {
      _highlightOrder = order;
      _highlightVisible = true;
    });
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _highlightVisible = false);
      }
    });
  }

  /// 滚动定位到保存章节。ListView 用 itemExtent 固定行高（_rowExtentOf），
  /// 可按 `index * 行高` **精确** jumpTo，目标行必然进入构建范围
  /// （P2 修复：不再按平均行高估算，长书末尾章节不再失效）。
  /// 必须在 post-frame 执行：setState 后 ListView 尚未挂载，
  /// 此时 hasClients 为 false，直接执行会静默失效。
  /// epoch 世代取消：重试连点产生的新定位任务会作废旧任务（P3 修复）。
  void _scrollToSavedChapter() {
    final epoch = ++_positionTaskEpoch;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || epoch != _positionTaskEpoch) return;
      final index = _chapters.indexWhere((c) => c.order == _targetOrder);
      if (index < 0 || !_scrollController.hasClients) return;

      _scrollController.jumpTo(
        (index * _rowExtentOf(context))
            .clamp(0.0, _scrollController.position.maxScrollExtent),
      );
      _refineScrollToTarget(epoch);
    });
  }

  /// 行已精确落在视口内，这里只做对齐微调（等目标行 build 后 ensureVisible）。
  /// 250ms 动画期间页面可能被 pop，此时 _scrollController 已 dispose，
  /// 因此每个 await 后复查 mounted/hasClients 并整体吞错，避免未处理异步异常。
  Future<void> _refineScrollToTarget(int epoch) async {
    try {
      for (var i = 0; i < 3; i++) {
        await Future.delayed(const Duration(milliseconds: 60));
        if (!mounted || epoch != _positionTaskEpoch) return;
        final ctx = _targetRowKey.currentContext;
        if (ctx != null && ctx.mounted && _scrollController.hasClients) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.3,
          );
          return;
        }
      }
    } catch (e) {
      debugPrint('AudiobookDetail: refine scroll failed – $e');
    }
  }

  /// 点击章节：从 0 播；点击恢复图标：从保存进度续播。
  Future<void> _playChapter(AudiobookChapter chapter,
      {AudiobookProgress? progress}) async {
    final index = _chapters.indexWhere((c) => c.id == chapter.id);
    if (index < 0) return;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    // C006 修复：全量章节拉取失败时 playAudiobookChapter 返回 false，
    // 弹 snackbar 提示（不清当前播放状态）。
    final ok = await playerProvider.playAudiobookChapter(
      widget.book,
      _chapters,
      index,
      resumePositionMs: (progress != null && !progress.completed)
          ? progress.positionMs
          : null,
      chaptersComplete: true, // _chapters 是 take:10000 的全量列表
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLoadChapters),
        ),
      );
    }
  }

  // ── RouteAware：从播放页返回时重读进度（§7.3 onResume）──────────────
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
    // 播放页 pop 回来 → 重读进度（"已播至"防过期）。
    if (_storeLoaded) {
      final serverKey = _serverKey;
      if (serverKey != null && mounted) {
        setState(() {
          _progress = _store.load(serverKey, widget.book.id);
        });
      }
    }
  }

  @override
  void dispose() {
    audiobookRouteObserver.unsubscribe(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        // 类型感知工具（§7.4）：编号型显示章节直跳，合集型显示书内搜索。
        actions: [
          if (_contentType == AudiobookContentType.numbered)
            IconButton(
              icon: const Icon(Icons.numbers_rounded),
              tooltip: l10n.jumpToChapter,
              onPressed: _jumpToChapterDialog,
            )
          else if (_contentType == AudiobookContentType.collection)
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: l10n.searchChapters,
              onPressed: _openSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(isDark, l10n),
          Expanded(child: _buildBody(isDark, l10n)),
        ],
      ),
    );
  }

  /// 轻量 header（B 档）：封面 64 + 书名/演播者/元信息 + 紧凑续播按钮。
  /// 取代旧的「继续收听」banner——有进度时按钮即续播入口。
  Widget _buildHeader(bool isDark, AppLocalizations l10n) {
    final book = widget.book;
    final durationText = formatDuration(book.totalDurationSeconds);
    final meta = [
      l10n.chapterCount(book.episodeCount),
      if (durationText.isNotEmpty) durationText,
    ].join(' · ');
    final showResume = _progress != null && !_progress!.completed;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          AudiobookCover(title: book.title, width: 64, height: 64, radius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (book.narrator != null && book.narrator!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    book.narrator!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
                if (meta.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    meta,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (showResume) ...[
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: () => _resumePlayback(_progress!),
              icon: const Icon(CupertinoIcons.play_fill, size: 16),
              label: Text(l10n.continueListening),
            ),
          ],
        ],
      ),
    );
  }

  /// 点击「继续收听」按钮：直接按保存章节续播（全量列表在手，无需翻页）。
  Future<void> _resumePlayback(AudiobookProgress progress) async {
    final index = _chapters.indexWhere((c) => c.order == progress.chapterOrder);
    if (index >= 0) {
      await _playChapter(_chapters[index], progress: progress);
    }
  }

  /// 章节直跳（编号型，§7.4）：输入 1..N → 精确 jumpTo + 高亮。
  Future<void> _jumpToChapterDialog() async {
    final total = _chapters.length;
    if (total <= 0) return;
    final l10n = AppLocalizations.of(context)!;
    final value = await showDialog<int>(
      context: context,
      builder: (_) => _JumpToChapterDialog(
        title: l10n.jumpToChapter,
        hintText: '1 - $total',
      ),
    );
    if (!mounted) return; // P3 修复：对话框期间页面可能被路由清理
    if (value != null && value >= 1 && value <= total) {
      _jumpToOrder(value);
    }
  }

  /// 精确跳到某章：itemExtent 下 `index×行高` 即达 + 高亮（直跳/索引条共用）。
  /// 直跳传入的是 1..N 章节序号，而服务端 order 可能非连续（增删章节）或某章
  /// 缺失回落为 0，按 order 查不到时回退为 1-based 下标，避免静默失效。
  void _jumpToOrder(int order) {
    var index = _chapters.indexWhere((c) => c.order == order);
    if (index < 0) index = order - 1;
    if (index < 0 || index >= _chapters.length) return;
    if (!_scrollController.hasClients) return;
    // 高亮/目标用命中的那一章真实 order（回退分支下 order 与下标不等价）。
    final targetOrder = _chapters[index].order;
    _setTargetOrder(targetOrder);
    _triggerHighlight(targetOrder);
    _scrollController.jumpTo(
      (index * _rowExtentOf(context))
          .clamp(0.0, _scrollController.position.maxScrollExtent),
    );
    final epoch = ++_positionTaskEpoch;
    _refineScrollToTarget(epoch);
  }

  /// 书内搜索（合集型，§7.4）：全量列表在内存，纯前端标题过滤，零服务端接口。
  void _openSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudiobookSearchScreen(
          book: widget.book,
          chapters: _chapters,
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError && _chapters.isEmpty) {
      return LoadErrorView(
        title: l10n.failedToLoadChapters,
        retryLabel: l10n.retry,
        onRetry: _loadChapters,
      );
    }

    if (_chapters.isEmpty) {
      return Center(
        child: Text(
          l10n.noSongsFound,
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Stack(
      children: [
        Consumer<PlayerProvider>(
          builder: (context, player, _) {
            final isCurrentBook = player.isPlayingAudiobook &&
                player.currentAudiobook?.id == widget.book.id;
            final currentOrder =
                isCurrentBook ? player.audiobookChapterOrder : null;

            return ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              // 统一行高：支撑进入定位按 index 精确 jumpTo（P2 修复），
              // 随系统字号放宽以免大字号溢出。
              itemExtent: _rowExtentOf(context),
              // 右侧留出快滑索引条命中区（§7.4）。
              padding: const EdgeInsets.only(right: 24),
              itemCount: _chapters.length,
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return _buildChapterTile(
                  isDark,
                  chapter,
                  isCurrent: currentOrder == chapter.order,
                  progress: _progress?.chapterOrder == chapter.order
                      ? _progress
                      : null,
                  highlight:
                      _highlightVisible && _highlightOrder == chapter.order,
                );
              },
            );
          },
        ),
        // 快滑索引条（§7.4）：章节数达到阈值才显示，避免短列表噪音。
        if (_chapters.length >= _fastScrollMinChapters)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: _FastScrollBar(
              itemCount: _chapters.length,
              itemExtent: _rowExtentOf(context),
              controller: _scrollController,
              labelBuilder: (index) => _chapters[index].title,
            ),
          ),
      ],
    );
  }

  Widget _buildChapterTile(
    bool isDark,
    AudiobookChapter chapter, {
    required bool isCurrent,
    required AudiobookProgress? progress,
    required bool highlight,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final accentColor = Theme.of(context).colorScheme.primary;

    // 已完成：显示"已听完"；有进度：显示"已播至 mm:ss"。
    String? subtitle;
    if (progress?.completed == true) {
      subtitle = l10n.finished;
    } else if (progress != null && progress.positionMs > 0) {
      // <0.5s 时 formatDurationMs 四舍五入为 0 秒返回空串，此时不拼"已播至 "，
      // 否则出现"已播至  · mm:ss"的悬空文案。
      final played = _formatMs(progress.positionMs);
      if (played.isNotEmpty) subtitle = l10n.playedTo(played);
    }
    if (chapter.durationSeconds != null && chapter.durationSeconds! > 0) {
      final durationText = _formatSeconds(chapter.durationSeconds!);
      subtitle = subtitle == null ? durationText : '$subtitle · $durationText';
    }

    // Apple §5.2：当前播放项用较亮/半粗标题低调标识，不用红色/等化器/波形
    // 图标制造噪声；序号列保持一致，仅当前项着色+加粗。
    final titleColor =
        isCurrent ? accentColor : (isDark ? Colors.white : Colors.black);
    final orderColor =
        isCurrent ? accentColor : (isDark ? Colors.white54 : Colors.black45);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      // 仅当目标 order 唯一时挂定位 key（P3 修复：重复 order 会 Duplicate GlobalKey）。
      key:
          _targetUnique && chapter.order == _targetOrder ? _targetRowKey : null,
      color:
          highlight ? accentColor.withValues(alpha: 0.12) : Colors.transparent,
      child: ListTile(
        leading: SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '${chapter.order}',
              style: TextStyle(
                fontSize: 15,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                color: orderColor,
              ),
            ),
          ),
        ),
        title: Text(
          chapter.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 16,
            color: titleColor,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: subtitle != null
            ? Text(subtitle, style: TextStyle(fontSize: 13))
            : null,
        trailing: progress != null && !progress.completed && !isCurrent
            ? IconButton(
                icon: Icon(CupertinoIcons.play_fill, color: accentColor),
                tooltip: l10n.continueListening,
                onPressed: () => _playChapter(chapter, progress: progress),
              )
            : null,
        onTap: () => _playChapter(chapter),
      ),
    );
  }

  // 时长格式化统一走共享工具（R002 修复，移除第 4/5 份副本）。
  String _formatMs(int ms) => formatDurationMs(ms);
  String _formatSeconds(int seconds) => formatDuration(seconds);
}

/// 章节列表会话内缓存条目（R002 修复）。
class _ChapterCacheEntry {
  final DateTime at;
  final List<AudiobookChapter> chapters;

  const _ChapterCacheEntry(this.at, this.chapters);
}

/// 章节直跳输入对话框：controller 生命周期随对话框 State（route **完全移除后**
/// 才 dispose），避免 pop 后立即手动 dispose 在键盘收起重建时触发
/// used-after-dispose 断言崩溃（P2 修复）。
class _JumpToChapterDialog extends StatefulWidget {
  final String title;
  final String hintText;

  const _JumpToChapterDialog({required this.title, required this.hintText});

  @override
  State<_JumpToChapterDialog> createState() => _JumpToChapterDialogState();
}

class _JumpToChapterDialogState extends State<_JumpToChapterDialog> {
  final TextEditingController _controller = TextEditingController(text: '1');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        autofocus: true,
        decoration: InputDecoration(hintText: widget.hintText),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(AppLocalizations.of(context)!.cancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pop(context, int.tryParse(_controller.text)),
          child: Text(AppLocalizations.of(context)!.ok),
        ),
      ],
    );
  }
}

/// 右侧快滑索引条（§7.4）：拖拽快速滑过几百条内容，拖动时气泡显示章节标题。
/// 精确跳转依赖 itemExtent 固定行高（`index × itemExtent` 即达）。
class _FastScrollBar extends StatefulWidget {
  final int itemCount;
  final double itemExtent;
  final ScrollController controller;
  final String Function(int index) labelBuilder;

  const _FastScrollBar({
    required this.itemCount,
    required this.itemExtent,
    required this.controller,
    required this.labelBuilder,
  });

  @override
  State<_FastScrollBar> createState() => _FastScrollBarState();
}

class _FastScrollBarState extends State<_FastScrollBar> {
  /// 拖动中悬停的章节 index（null = 未在拖动）。
  int? _hoverIndex;

  int _indexForDy(double dy, double height) {
    final t = (dy / height).clamp(0.0, 1.0);
    return (t * (widget.itemCount - 1)).round();
  }

  void _jump(int index) {
    if (!widget.controller.hasClients) return;
    widget.controller.jumpTo(
      (index * widget.itemExtent)
          .clamp(0.0, widget.controller.position.maxScrollExtent),
    );
  }

  void _handle(double dy, double height) {
    final index = _indexForDy(dy, height);
    // P3 性能修复：index 未变化（如 120Hz 连续采样同章节）时跳过重建与跳转。
    if (index == _hoverIndex) return;
    setState(() => _hoverIndex = index);
    _jump(index);
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxHeight;
        // P3 修复：极矮视口（<56px）不绘制，规避 clamp min>max 抛 ArgumentError
        // （thumbH clamp(40,height)、气泡 top clamp(4,height-36) 在 height<40 时越界）。
        if (height < 56) return const SizedBox(width: 24);

        final total = widget.itemCount;
        final hover = _hoverIndex;

        // 拇指高度 = 视口占比示意（最小 40dp）；位置 = 悬停章节比例。
        final thumbH = (height * (height / (total * widget.itemExtent)))
            .clamp(40.0, height);
        final thumbTop =
            hover == null ? 0.0 : (height - thumbH) * (hover / (total - 1));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => _handle(d.localPosition.dy, height),
          onVerticalDragUpdate: (d) => _handle(d.localPosition.dy, height),
          onVerticalDragEnd: (_) => setState(() => _hoverIndex = null),
          onTapDown: (d) => _jump(_indexForDy(d.localPosition.dy, height)),
          child: SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 轨道：拖动时亮起提示可拖区域。
                Container(
                  width: 3,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: hover == null
                        ? Colors.transparent
                        : accentColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // 拇指。
                Positioned(
                  top: thumbTop,
                  child: Container(
                    width: 5,
                    height: thumbH,
                    decoration: BoxDecoration(
                      color: hover == null
                          ? Colors.grey.withValues(alpha: 0.45)
                          : accentColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // 拖动气泡：显示章节标题。
                if (hover != null && hover < total)
                  Positioned(
                    right: 18,
                    top: (thumbTop + thumbH / 2 - 16).clamp(4.0, height - 36),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor,
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
