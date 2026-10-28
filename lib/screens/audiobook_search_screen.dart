import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/duration_format.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/song_divider.dart';

/// 书内搜索页（合集型内容 / 编号型数字跳转）。
///
/// 2026-10-27 改版（§15.4.2）：
/// - **只搜本书章节标题**，纯前端子串匹配（全量列表已在内存，零接口）；
/// - 输入纯数字 → 顶部出现「跳到第 N 集」，点击返回 detail 定位（不直接播）；
/// - 点标题结果 → 从 0 播放；搜索框不消失，便于连点试听。
class AudiobookSearchScreen extends StatefulWidget {
  final Audiobook book;
  final List<AudiobookChapter> chapters;

  const AudiobookSearchScreen({
    super.key,
    required this.book,
    required this.chapters,
  });

  @override
  State<AudiobookSearchScreen> createState() => _AudiobookSearchScreenState();
}

class _AudiobookSearchScreenState extends State<AudiobookSearchScreen> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  /// 小写标题预索引：避免每次按键对全部章节重复 toLowerCase。
  late final List<String> _lowercaseTitles;

  @override
  void initState() {
    super.initState();
    _lowercaseTitles =
        widget.chapters.map((c) => c.title.toLowerCase()).toList();
  }

  List<AudiobookChapter> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <AudiobookChapter>[];
    for (var i = 0; i < widget.chapters.length; i++) {
      if (_lowercaseTitles[i].contains(q)) results.add(widget.chapters[i]);
    }
    return results;
  }

  /// 纯数字输入 → 可跳转的集号（1..total）。
  int? get _jumpOrder {
    final n = int.tryParse(_query.trim());
    if (n == null || n <= 0) return null;
    if (n > widget.book.episodeCount && n > widget.chapters.length) return null;
    return n;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _play(AudiobookChapter chapter) async {
    final index = widget.chapters.indexWhere((c) => c.id == chapter.id);
    if (index < 0) return;
    final ok =
        await Provider.of<PlayerProvider>(context, listen: false)
            .playAudiobookChapter(
      widget.book,
      widget.chapters,
      index,
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    final results = _results;
    final jumpOrder = _jumpOrder;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  LuoboTopCircleButton(
                    icon: AppIcons.back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: c.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(AppIcons.search, size: 17, color: c.fg2),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _queryController,
                              autofocus: true,
                              style: LuoboType.body.copyWith(
                                fontSize: 15,
                                color: c.fg,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: l10n.searchChapters,
                                hintStyle: LuoboType.body.copyWith(
                                  fontSize: 15,
                                  color: c.fg2,
                                ),
                              ),
                              onChanged: (v) => setState(() => _query = v),
                            ),
                          ),
                          if (_query.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _queryController.clear();
                                setState(() => _query = '');
                              },
                              child: Icon(
                                CupertinoIcons.xmark_circle_fill,
                                size: 17,
                                color: c.fg3,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(
                      l10n.cancel,
                      style: LuoboType.body.copyWith(
                        fontSize: 15,
                        color: LuoboAccent.accent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _query.trim().isEmpty
                  ? Center(
                      child: Text(
                        l10n.searchChapters,
                        style: LuoboType.body.copyWith(color: c.fg2),
                      ),
                    )
                  : ListView(
                      padding: EdgeInsets.only(
                        bottom: LuoboSpacing.pageBottomWithStrip(context),
                      ),
                      children: [
                        // 数字 → 跳集（返回 detail 定位，不直接播）。
                        if (jumpOrder != null)
                          InkWell(
                            onTap: () => Navigator.of(context).pop(jumpOrder),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.number,
                                    size: 18,
                                    color: LuoboAccent.accent,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    l10n.jumpToEpisode(jumpOrder),
                                    style: LuoboType.body.copyWith(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: LuoboAccent.accent,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    AppIcons.forward,
                                    size: 15,
                                    color: c.fg3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (results.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                            child: Text(
                              l10n.searchResultsCount(results.length),
                              style: LuoboType.caption.copyWith(color: c.fg2),
                            ),
                          ),
                        for (var i = 0; i < results.length; i++) ...[
                          _buildResult(results[i], c),
                          if (i < results.length - 1)
                            const LuoboSongDivider(indent: 80),
                        ],
                        if (results.isEmpty && jumpOrder == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 48),
                            child: Center(
                              child: Text(
                                l10n.noSearchResults,
                                style:
                                    LuoboType.body.copyWith(color: c.fg2),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult(AudiobookChapter chapter, LuoboColors c) {
    final l10n = AppLocalizations.of(context)!;
    final duration = (chapter.durationSeconds != null &&
            chapter.durationSeconds! > 0)
        ? formatDuration(chapter.durationSeconds!)
        : '';

    return InkWell(
      onTap: () => _play(chapter),
      child: SizedBox(
        height: 68,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 64,
                child: Text(
                  l10n.chapterX(chapter.order),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuoboType.caption.copyWith(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.fg2,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _highlightedTitle(chapter.title, _query, c),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        duration,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(AppIcons.play, size: 15, color: LuoboAccent.accent),
            ],
          ),
        ),
      ),
    );
  }

  /// 标题里命中的子串标玫红。
  Widget _highlightedTitle(String title, String query, LuoboColors c) {
    final base = LuoboType.body.copyWith(fontSize: 16, color: c.fg);
    final q = query.trim().toLowerCase();
    final index = q.isEmpty ? -1 : title.toLowerCase().indexOf(q);
    if (index < 0) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: base,
      );
    }
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: base,
        children: [
          TextSpan(text: title.substring(0, index)),
          TextSpan(
            text: title.substring(index, index + q.length),
            style: const TextStyle(color: LuoboAccent.accent),
          ),
          TextSpan(text: title.substring(index + q.length)),
        ],
      ),
    );
  }
}
