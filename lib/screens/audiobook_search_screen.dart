import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../utils/duration_format.dart';

/// 书内搜索页（合集型内容，§7.4）。
///
/// 全量章节列表已在详情页内存中，这里做纯前端标题子串过滤——
/// 零服务端接口（道理鱼 search3 覆盖不到有声书，服务端零改动约束不变）。
/// 结果行点击直接播放（从 0 播，与详情页点章节一致）。
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

  /// 小写标题预索引（P3 性能修复）：避免每次按键对全部章节重复 toLowerCase。
  late final List<String> _lowercaseTitles;

  @override
  void initState() {
    super.initState();
    _lowercaseTitles =
        widget.chapters.map((c) => c.title.toLowerCase()).toList();
  }

  /// 实时过滤结果（大小写不敏感子串匹配）。
  List<AudiobookChapter> get _results {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final results = <AudiobookChapter>[];
    for (var i = 0; i < widget.chapters.length; i++) {
      if (_lowercaseTitles[i].contains(q)) results.add(widget.chapters[i]);
    }
    return results;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  Future<void> _play(AudiobookChapter chapter) async {
    final index = widget.chapters.indexWhere((c) => c.id == chapter.id);
    if (index < 0) return;
    final ok = await Provider.of<PlayerProvider>(context, listen: false)
        .playAudiobookChapter(
      widget.book,
      widget.chapters,
      index,
      chaptersComplete: true, // 章节列表由详情页全量传入
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.failedToLoadChapters),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final results = _results;
    final hintStyle = TextStyle(
      fontSize: 17,
      color: isDark ? Colors.white70 : Colors.black54,
    );

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _queryController,
          autofocus: true,
          style: hintStyle,
          decoration: InputDecoration(
            hintText: l10n.searchChapters,
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.clear_circled_solid),
              onPressed: () {
                _queryController.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? Center(
              child: Text(
                l10n.searchChapters,
                style: TextStyle(color: Colors.grey[600]),
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Text(
                    l10n.noSearchResults,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final chapter = results[index];
                    final duration = chapter.durationSeconds != null &&
                            chapter.durationSeconds! > 0
                        ? formatDuration(chapter.durationSeconds!)
                        : '';
                    return ListTile(
                      leading: SizedBox(
                        width: 32,
                        child: Center(
                          child: Text(
                            '${chapter.order}',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        chapter.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: duration.isNotEmpty
                          ? Text(duration, style: const TextStyle(fontSize: 12))
                          : null,
                      onTap: () => _play(chapter),
                    );
                  },
                ),
    );
  }
}
