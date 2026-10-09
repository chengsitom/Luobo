import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/audiobook_progress_store.dart';
import '../services/subsonic_service.dart';
import '../utils/duration_format.dart';
import '../widgets/audiobook_cover.dart';
import '../widgets/load_error_view.dart';
import '../widgets/section_header.dart';
import 'audiobook_detail_screen.dart';

/// 有声书列表页（道理鱼）。
///
/// 设计见 docs/有声书接入技术方案.md §7.2 + 改版讨论（2026-08-21）：
/// AppBar「有声书」+ 下拉刷新 + 错误态/空态（复用 RadioScreen 三态模式）；
/// 顶部「继续收听」**横滑 shelf**（recent(limit:1)，排除已听完的书）；
/// 主体 **2 列自适应封面网格**（3:4 伪封面 + 书名/演播者·章节数）。
/// 封面占位图走 AudiobookCover（API 无封面字段）。
class AudiobookListScreen extends StatefulWidget {
  const AudiobookListScreen({super.key});

  @override
  State<AudiobookListScreen> createState() => _AudiobookListScreenState();
}

class _AudiobookListScreenState extends State<AudiobookListScreen> {
  List<Audiobook> _books = [];
  bool _isLoading = true;
  String? _error;
  AudiobookProgress? _recent;
  String? _serverKey;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final subsonicService =
          Provider.of<SubsonicService>(context, listen: false);
      final books = await subsonicService.getAudiobooks();
      _recent = await _loadRecentProgress(subsonicService);
      if (mounted) {
        setState(() {
          _books = books;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<AudiobookProgress?> _loadRecentProgress(
    SubsonicService subsonicService,
  ) async {
    final config = subsonicService.config;
    if (config == null) return null;
    final serverKey = AudiobookProgressStore.computeServerKey(
      serverUrl: config.serverUrl,
      localUrl: config.localUrl,
      username: config.username,
    );
    _serverKey = serverKey;
    // 共享单例：与播放器/详情页共用同一内存缓存（M001）。
    final store = AudiobookProgressStore.instance;
    await store.ensureLoaded(serverKey);
    final recent = store.recent(serverKey, limit: 1);
    return recent.isEmpty ? null : recent.first;
  }

  void _openBook(Audiobook book) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudiobookDetailScreen(
          book: book,
          serverKey: _serverKey,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.audiobooks)),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _buildBody(isDark, l10n),
      ),
    );
  }

  Widget _buildBody(bool isDark, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return LoadErrorView(
        title: l10n.failedToLoadAudiobooks,
        message: _error,
        retryLabel: l10n.retry,
        onRetry: _load,
      );
    }

    if (_books.isEmpty) {
      return EmptyStateView(
        icon: CupertinoIcons.book,
        message: l10n.noSongsFound,
        isDark: isDark,
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        if (_recent != null)
          SliverToBoxAdapter(child: _buildContinueShelf(l10n)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          sliver: SliverGrid(
            // maxCrossAxisExtent 180：手机 2 列，平板/桌面自动 3~4 列。
            // 0.56 保证 3:4 封面 + 两行标题在列宽 156~180 内不溢出；
            // 大字号（textScale > 1）时放宽 cell 高度（更小的 aspect），
            // 避免标题/副标题溢出重叠（P3 修复）；clamp 上限防极端缩放浪费空间。
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 180,
              childAspectRatio: 0.56 /
                  MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5),
              crossAxisSpacing: 16,
              mainAxisSpacing: 20,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildGridTile(isDark, _books[index]),
              childCount: _books.length,
            ),
          ),
        ),
      ],
    );
  }

  /// 「继续收听」横滑 shelf：封面 + 书名 + 章节/进度 caption。
  /// 点击进入详情页并定位到进度章节（不直接开播，避免误触打断当前播放）。
  /// 复用共享组件 HorizontalScrollSection（R002 修复，2026-08-21）。
  Widget _buildContinueShelf(AppLocalizations l10n) {
    final progress = _recent!;
    final book = _books.where((b) => b.id == progress.audiobookId).firstOrNull;
    if (book == null) return const SizedBox.shrink();

    // caption 定位到具体章节+分钟（"第 X 章 · 已播至 mm:ss"），不能只显示系列名；
    // 进度条无章节时长数据源，用文字代替。recent() 已排除 completed 的书
    // （audiobook_progress_store.dart:145），无需"已听完"分支（M002 修复）。
    final String caption;
    // <0.5s 时 formatDurationMs 四舍五入为 0 秒返回空串，此时不拼"已播至 "，
    // 否则出现"第 X 章 · 已播至 "的悬空文案。
    final played = formatDurationMs(progress.positionMs);
    if (played.isNotEmpty) {
      caption = '${l10n.chapterX(progress.chapterOrder)} · '
          '${l10n.playedTo(played)}';
    } else {
      caption = l10n.chapterX(progress.chapterOrder);
    }

    return HorizontalScrollSection(
      title: l10n.continueListening,
      // listHeight = cardSize + 60 = 206：封面 160 + 标题/进度 caption ≈ 46。
      cardSize: 146,
      children: [_buildShelfCard(book, caption)],
    );
  }

  Widget _buildShelfCard(Audiobook book, String caption) {
    final accentColor = Theme.of(context).colorScheme.primary;

    return InkWell(
      onTap: () => _openBook(book),
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AudiobookCover(title: book.title, width: 120, height: 160),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Flexible(
              child: Text(
                caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: accentColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridTile(bool isDark, Audiobook book) {
    final l10n = AppLocalizations.of(context)!;
    final durationText = formatDuration(book.totalDurationSeconds);
    final subtitle = [
      if (book.narrator != null && book.narrator!.isNotEmpty) book.narrator!,
      l10n.chapterCount(book.episodeCount),
      if (durationText.isNotEmpty) durationText,
    ].join(' · ');

    return InkWell(
      onTap: () => _openBook(book),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 3:4 竖版封面（书籍比例）。
          AspectRatio(
            aspectRatio: 3 / 4,
            child: AudiobookCover(
              title: book.title,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          const SizedBox(height: 6),
          // Flexible 兜底：网格 cell 高度不足时缩行省略而非溢出。
          // 标题 flex 3 / 副标题 flex 1：剩余高度大头给标题，保证 2 行稳定。
          Flexible(
            flex: 3,
            child: Text(
              book.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(
            child: Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
