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
import '../widgets/audiobook_cover.dart';
import '../widgets/audiobook_dock.dart';
import '../widgets/load_error_view.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/playing_bars.dart';
import '../widgets/luobo/song_divider.dart';
import 'audiobook_detail_screen.dart';

/// 有声书库页（道理鱼）。
///
/// 设计见 docs/有声书接入技术方案.md §15.3（2026-10-27 无封面改版）：
/// - 服务端**永远没有封面** → 不做封面墙，改**行式书架**；
/// - 顶部「继续收听」横滑最多 3 本（卡片可直接续播）；
/// - 书架行 = 纯文字书封首字 + 书名 + 演播者·章节·时长 + 进度条 + 续播钮；
/// - 从详情页返回时刷新进度（修复旧实现 shelf 不更新的问题）。
class AudiobookListScreen extends StatefulWidget {
  const AudiobookListScreen({super.key});

  @override
  State<AudiobookListScreen> createState() => _AudiobookListScreenState();
}

class _AudiobookListScreenState extends State<AudiobookListScreen> {
  List<Audiobook> _books = [];
  List<AudiobookProgress> _recents = [];
  bool _isLoading = true;
  String? _error;
  String? _serverKey;
  String? _resumingId;

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
      await _refreshProgress(subsonicService);
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

  /// 重读「继续收听」候选（最多 3 本）；store 是共享单例，能读到播放器的写入。
  Future<void> _refreshProgress(SubsonicService subsonicService) async {
    final config = subsonicService.config;
    if (config == null) return;
    final serverKey = AudiobookProgressStore.computeServerKey(
      serverUrl: config.serverUrl,
      localUrl: config.localUrl,
      username: config.username,
    );
    _serverKey = serverKey;
    final store = AudiobookProgressStore.instance;
    await store.ensureLoaded(serverKey);
    _recents = store.recent(serverKey, limit: 3);
  }

  Audiobook? _bookById(String id) {
    for (final b in _books) {
      if (b.id == id) return b;
    }
    return null;
  }

  AudiobookProgress? _progressOf(Audiobook book) {
    final serverKey = _serverKey;
    if (serverKey == null) return null;
    return AudiobookProgressStore.instance.load(serverKey, book.id);
  }

  /// 进入详情页；返回后重读进度（shelf 与行内进度即时更新）。
  Future<void> _openBook(Audiobook book) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AudiobookDetailScreen(
          book: book,
          serverKey: _serverKey,
        ),
      ),
    );
    if (!mounted) return;
    final subsonicService =
        Provider.of<SubsonicService>(context, listen: false);
    await _refreshProgress(subsonicService);
    if (mounted) setState(() {});
  }

  /// 直接从卡片/行尾续播：拉一次全量章节定位到保存章节。
  Future<void> _resume(Audiobook book, AudiobookProgress progress) async {
    if (_resumingId != null) return;
    setState(() => _resumingId = book.id);

    final subsonicService =
        Provider.of<SubsonicService>(context, listen: false);
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    try {
      final page = await subsonicService.getAudiobookChapters(
        book.id,
        skip: 0,
        take: 10000,
      );
      final chapters = page.chapters
        ..sort((a, b) => a.order.compareTo(b.order));
      if (chapters.isEmpty) throw Exception('empty chapters');

      var index =
          chapters.indexWhere((c) => c.id == progress.chapterId);
      if (index < 0) {
        index = chapters.indexWhere((c) => c.order == progress.chapterOrder);
      }
      if (index < 0) index = 0;

      final ok = await player.playAudiobookChapter(
        book,
        chapters,
        index,
        resumePositionMs:
            progress.completed ? null : progress.positionMs,
        chaptersComplete: true,
      );
      if (!ok && mounted) {
        showLuoboToast(
          context,
          message: l10n.failedToLoadChapters,
          tone: LuoboToastTone.info,
        );
      }
    } catch (_) {
      if (mounted) {
        showLuoboToast(
          context,
          message: l10n.failedToLoadChapters,
          tone: LuoboToastTone.info,
        );
      }
    } finally {
      if (mounted) setState(() => _resumingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: const LuoboListTopBar(),
      body: Consumer<PlayerProvider>(
        builder: (context, player, _) {
          // 有声书正在播放：书库页底部也显示吸底播放条（用户 2026-10-27）。
          final current =
              player.isPlayingAudiobook ? player.currentAudiobook : null;
          final bottomInset = current != null
              ? AudiobookDock.contentHeight +
                  8 +
                  MediaQuery.paddingOf(context).bottom
              : 100.0;

          return Stack(
            children: [
              RefreshIndicator(
                onRefresh: _load,
                child: _buildBody(isDark, l10n, bottomInset, player),
              ),
              if (current != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: AudiobookDock(
                    player: player,
                    book: current,
                    onTitleTap: () => _openBook(current),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(
    bool isDark,
    AppLocalizations l10n,
    double bottomInset,
    PlayerProvider player,
  ) {
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

    final c = LuoboColors.of(context);
    final recents =
        _recents.where((p) => _bookById(p.audiobookId) != null).toList();

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // 顶部留白放进滚动内容里 → 列表从悬浮圆钮下方流过（§8.3）。
        SliverToBoxAdapter(child: SizedBox(height: listTopInset(context))),
        if (recents.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildContinueSection(recents, l10n, player),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 8),
            child: Row(
              children: [
                Text(
                  l10n.myBookshelf,
                  style: LuoboType.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: c.fg2,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${l10n.booksCount(_books.length)}',
                  style: LuoboType.caption.copyWith(color: c.fg2),
                ),
              ],
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final book = _books[index];
              return Column(
                children: [
                  _buildBookRow(book, l10n, player),
                  if (index < _books.length - 1)
                    const LuoboSongDivider(indent: 76),
                ],
              );
            },
            childCount: _books.length,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: bottomInset)),
      ],
    );
  }

  /// 「继续收听」：横滑卡（300×98），卡面直接续播，点击卡片进详情。
  Widget _buildContinueSection(
    List<AudiobookProgress> recents,
    AppLocalizations l10n,
    PlayerProvider player,
  ) {
    final c = LuoboColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Text(
            l10n.continueListening,
            style: LuoboType.body.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.fg2,
            ),
          ),
        ),
        SizedBox(
          height: 98,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: recents.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final progress = recents[index];
              final book = _bookById(progress.audiobookId)!;
              return _buildResumeCard(book, progress, l10n, c, player);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCard(
    Audiobook book,
    AudiobookProgress progress,
    AppLocalizations l10n,
    LuoboColors c,
    PlayerProvider player,
  ) {
    final isCurrent = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == book.id;
    final ratio = progress.progressRatio(
          totalEpisodes: book.episodeCount,
        ) ??
        0;
    final remaining = _remainingSeconds(book, progress);
    final subtitle = [
      l10n.chapterX(progress.chapterOrder),
      if (remaining != null) l10n.remainingTime(_humanDuration(l10n, remaining)),
    ].join(' · ');

    return SizedBox(
      width: 300,
      child: Material(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openBook(book),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                AudiobookCover(
                  title: book.title,
                  size: AudiobookCoverSize.medium,
                  narrator: book.narrator,
                  category: audiobookDisplayCategory(book),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: c.fg,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                      const SizedBox(height: 8),
                      _RatioBar(value: ratio, height: 3),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _CirclePlayButton(
                  loading: _resumingId == book.id,
                  isPlaying: isCurrent && player.isPlaying,
                  onTap: isCurrent
                      ? player.togglePlayPause
                      : () => _resume(book, progress),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookRow(
    Audiobook book,
    AppLocalizations l10n,
    PlayerProvider player,
  ) {
    final c = LuoboColors.of(context);
    final progress = _progressOf(book);
    final isCurrent = player.isPlayingAudiobook &&
        player.currentAudiobook?.id == book.id;
    final finished = progress?.completed == true;
    final hasProgress = progress != null &&
        !progress.completed &&
        (progress.positionMs > 0 || progress.chapterOrder > 1);
    final ratio = progress?.progressRatio(
          totalEpisodes: book.episodeCount,
        ) ??
        0;
    final percent = (ratio * 100).round();

    return SizedBox(
      height: hasProgress ? 84 : 72,
      child: InkWell(
        onTap: () => _openBook(book),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AudiobookCover(
                title: book.title,
                size: AudiobookCoverSize.small,
                narrator: book.narrator,
                category: audiobookDisplayCategory(book),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _bookMeta(book, l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                    if (hasProgress) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.chapterX(progress.chapterOrder)} · '
                        '${l10n.listenedPercent(percent)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.caption.copyWith(
                          color: LuoboAccent.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      _RatioBar(value: ratio, height: 3, width: 0.72),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (hasProgress || isCurrent)
                _CirclePlayButton(
                  size: 32,
                  loading: _resumingId == book.id,
                  isPlaying: isCurrent && player.isPlaying,
                  onTap: isCurrent
                      ? player.togglePlayPause
                      : () => _resume(book, progress!),
                )
              else if (finished)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(AppIcons.check, size: 13, color: c.fg3),
                    const SizedBox(width: 3),
                    Text(
                      l10n.finished,
                      style: LuoboType.caption.copyWith(color: c.fg3),
                    ),
                  ],
                )
              else
                Icon(AppIcons.forward, size: 18, color: c.fg3),
            ],
          ),
        ),
      ),
    );
  }

  String _bookMeta(Audiobook book, AppLocalizations l10n) {
    final parts = <String>[
      if (book.narrator != null && book.narrator!.isNotEmpty) book.narrator!,
      l10n.chapterCount(book.episodeCount),
      if (book.totalDurationSeconds != null && book.totalDurationSeconds! > 0)
        _humanDuration(l10n, book.totalDurationSeconds!),
    ];
    return parts.join(' · ');
  }

  /// 剩余秒数：总时长 × (1 - 进度)。无总时长时返回 null（不显示）。
  int? _remainingSeconds(Audiobook book, AudiobookProgress progress) {
    final total = book.totalDurationSeconds;
    if (total == null || total <= 0) return null;
    final ratio =
        progress.progressRatio(totalEpisodes: book.episodeCount) ?? 0;
    return (total * (1 - ratio)).round().clamp(0, total);
  }

  /// 人类可读时长（9 小时 20 分钟 / 20 分钟）。
  String _humanDuration(AppLocalizations l10n, int seconds) {
    if (seconds <= 0) return l10n.durationMinutes(0);
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return l10n.durationHoursMinutes(h, m);
    return l10n.durationMinutes(m);
  }
}

/// 细进度条（3dp）：底 `divider` + 前景 accent。
class _RatioBar extends StatelessWidget {
  final double value; // 0..1
  final double height;

  /// 相对可用宽度的占比（null = 铺满）。
  final double? width;

  const _RatioBar({required this.value, required this.height, this.width});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final bar = ClipRRect(
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
                child: ColoredBox(color: LuoboAccent.accent),
              ),
            ),
          ],
        ),
      ),
    );
    if (width == null) return bar;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: width,
      child: bar,
    );
  }
}

/// 圆形播放钮（主题取反：浅色黑底白图标 / 深色白底黑图标）。
class _CirclePlayButton extends StatelessWidget {
  final bool loading;

  /// 当前这本书正在播放：显示跳动的音柱（静态 ▶ 看不出在播哪本）。
  final bool isPlaying;
  final VoidCallback onTap;
  final double size;

  const _CirclePlayButton({
    required this.loading,
    required this.onTap,
    this.isPlaying = false,
    this.size = 36,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? Colors.white : Colors.black;
    final fg = isDark ? Colors.black : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: loading ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
        child: Center(
          child: loading
              ? SizedBox(
                  width: size * 0.42,
                  height: size * 0.42,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                )
              : isPlaying
                  ? PlayingBars(size: size * 0.42, color: fg)
                  : Padding(
                      padding: EdgeInsets.only(left: size * 0.07),
                      child:
                          Icon(AppIcons.play, size: size * 0.42, color: fg),
                    ),
        ),
      ),
    );
  }
}
