import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/recommendation_service.dart';
import '../services/listening_report_service.dart';
import '../providers/library_provider.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_toast.dart';

/// 听歌报告：从「统计报表」改成「关于你的一本小册子」。
///
/// 结构：人格 Hero → 口味指纹 → 口味变迁 → 时光机 → 听歌建议。
/// 所有统计逻辑在 [ListeningInsightBuilder]，这里只负责把结论讲好。
class ListeningReportScreen extends StatefulWidget {
  const ListeningReportScreen({super.key});

  @override
  State<ListeningReportScreen> createState() => _ListeningReportScreenState();
}

class _ListeningReportScreenState extends State<ListeningReportScreen> {
  bool _creatingPlaylist = false;

  @override
  Widget build(BuildContext context) {
    final recService = Provider.of<RecommendationService>(context);
    final library = Provider.of<LibraryProvider>(context);
    // albumId → 名字：播放记录里只有 id，展示时从曲库映射。
    final albumNames = <String, String>{};
    for (final album in library.cachedAllAlbums) {
      albumNames[album.id] = album.name;
    }

    // songId → genre：老画像首次播放时没存风格，从曲库回填（只读，不落盘）。
    final genreLookup = <String, String>{};
    for (final song in library.cachedAllSongs) {
      if (song.genre != null && song.genre!.isNotEmpty) {
        genreLookup[song.id] = song.genre!;
      }
    }

    final insight = ListeningInsightBuilder(
      recService.profiles,
      firstUseDate: recService.firstUseDate,
      starredSongIds: recService.starredSongIds,
      genreLookup: genreLookup,
    ).build();

    // 探索歌单：与最近口味不同，只从 roamPool（已排除屏蔽）里选。
    final exploration = ExplorationPlaylistBuilder(
      profiles: recService.profiles,
      pool: library.roamPool,
      genreLookup: genreLookup,
      recentlyPlayed: recService.recentlyPlayed.toSet(),
      dislikedIds: recService.profiles.entries
          .where((e) => e.value.isDisliked)
          .map((e) => e.key)
          .toSet(),
    ).build();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('听歌报告'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showReportHelp(context),
          ),
        ],
      ),
      body: !insight.hasData
          ? const Center(child: Text('还没有听歌数据，多听几首再来看吧'))
          : ListView(
              padding: LuoboSpacing.scrollPadding(
                  context, horizontal: 16, top: 12, bottom: 40),
              children: [
                _PersonaHero(insight: insight),
                const SizedBox(height: 28),
                if (insight.flavorPrint.isNotEmpty) ...[
                  _ChapterHeader(
                      number: '01', title: '你的口味指纹', subtitle: '哪些风格，真正构成了你'),
                  const SizedBox(height: 12),
                  _FlavorPrintCard(genres: insight.flavorPrint),
                  const SizedBox(height: 28),
                ],
                if (insight.flavorShift != null) ...[
                  _ChapterHeader(
                      number: '02', title: '你的口味变了', subtitle: '最近 30 天，和之前不太一样'),
                  const SizedBox(height: 12),
                  _FlavorShiftCard(shift: insight.flavorShift!),
                  const SizedBox(height: 28),
                ],
                if (insight.timeCapsule.isNotEmpty ||
                    insight.powerDay != null ||
                    insight.forgottenTreasures.isNotEmpty ||
                    insight.topAlbums.isNotEmpty) ...[
                  _ChapterHeader(
                      number: '03', title: '你和它们的故事', subtitle: '有些歌，早就悄悄陪了你很久'),
                  const SizedBox(height: 12),
                  if (insight.timeCapsule.isNotEmpty)
                    _TimeCapsuleCard(items: insight.timeCapsule),
                  if (insight.powerDay != null) ...[
                    const SizedBox(height: 12),
                    _PowerDayCard(day: insight.powerDay!),
                  ],
                  if (insight.forgottenTreasures.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _ForgottenTreasuresCard(items: insight.forgottenTreasures),
                  ],
                  if (insight.topAlbums.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _AlbumStayCard(
                      albums: insight.topAlbums,
                      albumNames: albumNames,
                    ),
                  ],
                  const SizedBox(height: 28),
                ],
                _ChapterHeader(
                    number: '04', title: '接下来听点什么', subtitle: '给未来的你一点小建议'),
                const SizedBox(height: 12),
                if (insight.guiltyPleasure != null) ...[
                  _GuiltyPleasureCard(guilty: insight.guiltyPleasure!),
                  const SizedBox(height: 12),
                ],
                if (insight.rhythm != null) ...[
                  _RhythmCard(rhythm: insight.rhythm!),
                  const SizedBox(height: 12),
                ],
                _SuggestionsCard(
                  insight: insight,
                  exploration: exploration,
                  creating: _creatingPlaylist,
                  onCreatePlaylist: () => _createExplorationPlaylist(exploration),
                ),
              ],
            ),
    );
  }

  Future<void> _createExplorationPlaylist(List<ExplorationPick> picks) async {
    if (_creatingPlaylist || picks.isEmpty) return;
    setState(() => _creatingPlaylist = true);
    final name = '口味探索 · ${DateTime.now().month}月';
    final songIds = picks.map((p) => p.song.id).toList();
    try {
      await Provider.of<LibraryProvider>(context, listen: false)
          .createPlaylist(name, songIds: songIds);
      if (mounted) {
        showLuoboToast(context, message: '已生成「$name」', actionLabel: null);
      }
    } catch (e) {
      if (mounted) showLuoboToast(context, message: '生成失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _creatingPlaylist = false);
    }
  }

  void _showReportHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted = isDark
        ? Colors.white.withValues(alpha: 0.5)
        : Colors.black.withValues(alpha: 0.5);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: ListView(
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
              const Text('这份报告怎么来的？',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '全部基于你本机的播放记录自动算出，不上传、不联网。数字只是原料，报告想讲的是「你是谁」。',
                style: TextStyle(fontSize: 14, color: muted, height: 1.5),
              ),
              const SizedBox(height: 20),
              _buildHelpItem(
                icon: Icons.auto_awesome_rounded,
                title: '音乐人格',
                desc: '由你最常听歌的时段、完播习惯和对歌手的专注度共同决定。同一个人，听歌习惯变了，人格也会跟着变。',
                muted: muted,
              ),
              _buildHelpItem(
                icon: Icons.pie_chart_outline_rounded,
                title: '口味指纹',
                desc: '按有效播放次数统计的风格占比；流行的各种写法（pop / 华语流行）会归一成同一类。',
                muted: muted,
              ),
              _buildHelpItem(
                icon: Icons.swap_horiz_rounded,
                title: '口味变了',
                desc: '对比最近 30 天和之前 30 天的头部歌手/风格。只有真的换了人才会出现这一章。',
                muted: muted,
              ),
              _buildHelpItem(
                icon: Icons.history_rounded,
                title: '你和它们的故事',
                desc: '初见 = 第一次按下播放的歌；那一天 = 单曲单日循环最多的一天；遗忘的宝藏 = 循环过却 60 天没再听的歌；专辑按停留次数统计。',
                muted: muted,
              ),
              _buildHelpItem(
                icon: Icons.card_giftcard_rounded,
                title: '口是心非 / 生物钟',
                desc: '对比收藏与跳过，找出「收藏却总跳过」和「没收藏却反复听」；生物钟按实际听歌日期区分工作日与周末。',
                muted: muted,
              ),
              _buildHelpItem(
                icon: Icons.playlist_add_rounded,
                title: '口味探索歌单',
                desc: '故意避开你最近 30 天常听的歌手和曲风，从没听过或很久没听的歌里挑一批，帮你跳出循环。只从已解除屏蔽的曲库里选。',
                muted: muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpItem({
    required IconData icon,
    required String title,
    required String desc,
    required Color muted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: LuoboAccent.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(fontSize: 13, height: 1.4, color: muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero：人格卡 ───────────────────────────────────────────────────────────

class _PersonaHero extends StatelessWidget {
  final ListeningInsight insight;
  const _PersonaHero({required this.insight});

  @override
  Widget build(BuildContext context) {
    final hours = insight.totalMinutes ~/ 60;
    final mins = insight.totalMinutes % 60;
    final duration = hours > 0 ? '$hours 小时 $mins 分' : '$mins 分钟';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [LuoboAccent.accent, LuoboAccent.accentLight],
        ),
        boxShadow: [
          BoxShadow(
            color: LuoboAccent.accent.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_rounded,
              size: 16, color: Colors.white.withValues(alpha: 0.85)),
          const SizedBox(width: 6),
          Text('你的音乐人格',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85))),
        ]),
        const SizedBox(height: 12),
        Text(insight.persona.title,
            style: const TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 8),
        Text(insight.persona.headline,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        const SizedBox(height: 6),
        Text(insight.persona.description,
            style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Colors.white.withValues(alpha: 0.85))),
        if (insight.persona.traits.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: insight.persona.traits
                .map((t) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.25),
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _HeroStat(value: duration, label: '累计聆听'),
            _HeroStat(value: '${insight.totalPlays}', label: '次播放'),
            _HeroStat(value: '${insight.uniqueArtists}', label: '位歌手'),
            _HeroStat(value: '${insight.activeDays}', label: '天陪伴'),
          ],
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  const _HeroStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 3),
        Text(label,
            style: TextStyle(
                fontSize: 11, color: Colors.white.withValues(alpha: 0.75))),
      ]),
    );
  }
}

// ─── 章节标题 ───────────────────────────────────────────────────────────────

class _ChapterHeader extends StatelessWidget {
  final String number, title, subtitle;
  const _ChapterHeader(
      {required this.number, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: LuoboAccent.soft(),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(number,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: LuoboAccent.accent)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ]),
      ),
    ]);
  }
}

// ─── 01 口味指纹 ────────────────────────────────────────────────────────────

class _FlavorPrintCard extends StatelessWidget {
  final List<GenreShare> genres;
  const _FlavorPrintCard({required this.genres});

  @override
  Widget build(BuildContext context) {
    final max = genres.first.percent;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...genres.map((g) {
          final ratio = max > 0 ? g.percent / max : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(g.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                Text('${g.percent.toStringAsFixed(0)}%  ·  ${g.plays} 次',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
              ]),
              const SizedBox(height: 7),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: SizedBox(
                  height: 8,
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    widthFactor: 1,
                    child: FractionallySizedBox(
                      widthFactor: ratio.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [
                            LuoboAccent.accent,
                            LuoboAccent.accentLight,
                          ]),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── 02 口味变迁 ────────────────────────────────────────────────────────────

class _FlavorShiftCard extends StatelessWidget {
  final FlavorShift shift;
  const _FlavorShiftCard({required this.shift});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: _ShiftSide(
                label: '之前的偏爱',
                name: shift.fromArtist ?? shift.fromGenre ?? '—',
                count: shift.fromPlays,
                emphasized: false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.arrow_forward_rounded,
                size: 20, color: LuoboAccent.accent),
          ),
          Expanded(
            child: _ShiftSide(
                label: '最近的心头好',
                name: shift.toArtist ?? shift.toGenre ?? '—',
                count: shift.toPlays,
                emphasized: true),
          ),
        ]),
        if (shift.hasArtistShift && shift.hasGenreShift) ...[
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Text(
            '连曲风也从「${shift.fromGenre}」换成了「${shift.toGenre}」。',
            style: TextStyle(fontSize: 13, color: muted, height: 1.5),
          ),
        ],
      ]),
    );
  }
}

class _ShiftSide extends StatelessWidget {
  final String label, name;
  final int count;
  final bool emphasized;
  const _ShiftSide({
    required this.label,
    required this.name,
    required this.count,
    required this.emphasized,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 12, color: muted)),
      const SizedBox(height: 6),
      Text(name,
          style: TextStyle(
              fontSize: 15,
              fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
              color: emphasized ? LuoboAccent.accent : null),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      if (count > 0) ...[
        const SizedBox(height: 4),
        Text('$count 次', style: TextStyle(fontSize: 12, color: muted)),
      ],
    ]);
  }
}

// ─── 03 时光机 ──────────────────────────────────────────────────────────────

class _TimeCapsuleCard extends StatelessWidget {
  final List<TimeCapsuleItem> items;
  const _TimeCapsuleCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final isLast = i == items.length - 1;
          return IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              SizedBox(
                width: 20,
                child: Column(children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: LuoboAccent.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1,
                        color: LuoboAccent.accent.withValues(alpha: 0.3),
                      ),
                    ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.kind,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: LuoboAccent.accent)),
                        const SizedBox(height: 4),
                        Text(item.title,
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (item.artist != null && item.artist!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(item.artist!,
                              style: TextStyle(fontSize: 13, color: muted)),
                        ],
                        const SizedBox(height: 4),
                        Text(item.detail,
                            style: TextStyle(fontSize: 12, color: muted, height: 1.4)),
                      ]),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

// ─── 04 听歌建议 ────────────────────────────────────────────────────────────

class _SuggestionsCard extends StatelessWidget {
  final ListeningInsight insight;
  final List<ExplorationPick> exploration;
  final bool creating;
  final VoidCallback onCreatePlaylist;
  const _SuggestionsCard({
    required this.insight,
    required this.exploration,
    required this.creating,
    required this.onCreatePlaylist,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (insight.drought != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: LuoboAccent.soft(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(Icons.lightbulb_outline_rounded,
                  size: 20, color: LuoboAccent.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '最近一周，你 ${(insight.drought!.concentration * 100).toStringAsFixed(0)}% 的播放都集中在少数几首歌上。是时候换换口味了。',
                  style: TextStyle(fontSize: 13, height: 1.5, color: muted),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 18),
        ],
        if (insight.discoveries.isNotEmpty) ...[
          const Text('最近的新宠',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...insight.discoveries.map((d) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Icon(Icons.new_releases_outlined,
                      size: 16, color: LuoboAccent.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(d.title,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (d.artist != null && d.artist!.isNotEmpty)
                        Text(d.artist!,
                            style: TextStyle(fontSize: 12, color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Text('${d.plays} 次',
                      style: TextStyle(fontSize: 12, color: muted)),
                ]),
              )),
          const SizedBox(height: 16),
        ],
        if (exploration.isNotEmpty) ...[
          const Text('给你挑的探索歌单',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('故意避开你最近常听的歌手和曲风',
              style: TextStyle(fontSize: 12, color: muted)),
          const SizedBox(height: 10),
          ...exploration.take(5).map((pick) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Icon(Icons.explore_outlined, size: 16, color: LuoboAccent.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(pick.song.title,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (pick.song.artist != null && pick.song.artist!.isNotEmpty)
                        Text(pick.song.artist!,
                            style: TextStyle(fontSize: 11, color: muted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  Text(pick.reason,
                      style: TextStyle(fontSize: 11, color: LuoboAccent.accent)),
                ]),
              )),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: creating || exploration.isEmpty ? null : onCreatePlaylist,
            icon: creating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.explore_rounded, size: 18),
            label: Text(creating
                ? '正在生成…'
                : exploration.isEmpty
                    ? '曲库太小，暂时挑不出探索歌单'
                    : '生成「口味探索」歌单（${exploration.length} 首）'),
            style: FilledButton.styleFrom(
              backgroundColor: LuoboAccent.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── 03 故事章节的补充卡片 ──────────────────────────────────────────────────

/// 那一天：一个有具体日期的记忆锚点。
class _PowerDayCard extends StatelessWidget {
  final PowerDay day;
  const _PowerDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final parts = day.day.split('-');
    final dateLabel = parts.length == 3
        ? '${int.parse(parts[1])} 月 ${int.parse(parts[2])} 日'
        : day.day;
    return _CardWrap(
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: LuoboAccent.soft(),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.calendar_today_rounded,
              size: 22, color: LuoboAccent.accent),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('那一天 · $dateLabel',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: muted, height: 1.5),
                children: [
                  const TextSpan(text: '你把 '),
                  TextSpan(
                    text: '「${day.title}」',
                    style: TextStyle(
                        color: LuoboAccent.accent, fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: ' 循环了 ${day.plays} 遍'),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

/// 遗忘的宝藏：曾经循环、如今久未再听。
class _ForgottenTreasuresCard extends StatelessWidget {
  final List<ForgottenTreasure> items;
  const _ForgottenTreasuresCard({required this.items});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.home_outlined, size: 16, color: LuoboAccent.accent),
          const SizedBox(width: 6),
          const Text('遗忘的宝藏',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 6),
        Text('这些歌你曾经反复听，已经很久没见面了',
            style: TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 14),
        ...items.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(t.title,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (t.artist != null && t.artist!.isNotEmpty)
                      Text(t.artist!,
                          style: TextStyle(fontSize: 12, color: muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ]),
                ),
                Text('${t.daysSinceLastPlay} 天前 · ${t.plays} 次',
                    style: TextStyle(fontSize: 12, color: muted)),
              ]),
            )),
      ]),
    );
  }
}

/// 专辑情节：按停留次数排的专辑（id 映射不到名字的不显示）。
class _AlbumStayCard extends StatelessWidget {
  final List<AlbumStay> albums;
  final Map<String, String> albumNames;
  const _AlbumStayCard({
    required this.albums,
    required this.albumNames,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final named = albums.where((a) => albumNames.containsKey(a.albumId)).toList();
    if (named.isEmpty) return const SizedBox.shrink();
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.album_rounded, size: 16, color: LuoboAccent.accent),
          const SizedBox(width: 6),
          const Text('你常待的专辑',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 14),
        ...named.map((a) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Expanded(
                  child: Text(albumNames[a.albumId]!,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ),
                Text('${a.songCount} 首 · ${a.plays} 次',
                    style: TextStyle(fontSize: 12, color: muted)),
              ]),
            )),
      ]),
    );
  }
}

// ─── 04 建议章节的补充卡片 ──────────────────────────────────────────────────

/// 口是心非：收藏却总跳过 vs 没收藏却反复听。
class _GuiltyPleasureCard extends StatelessWidget {
  final GuiltyPleasure guilty;
  const _GuiltyPleasureCard({required this.guilty});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.card_giftcard_rounded, size: 16, color: LuoboAccent.accent),
          const SizedBox(width: 6),
          const Text('口是心非',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 12),
        if (guilty.hiddenGem != null) ...[
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: muted, height: 1.5),
              children: [
                const TextSpan(text: '没收藏，却偷偷听了 '),
                TextSpan(
                  text: '${guilty.hiddenGem!.plays} 次',
                  style: TextStyle(
                      color: LuoboAccent.accent, fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '：「${guilty.hiddenGem!.title}」'),
              ],
            ),
          ),
        ],
        if (guilty.pretender != null) ...[
          if (guilty.hiddenGem != null) const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              style: TextStyle(fontSize: 13, color: muted, height: 1.5),
              children: [
                const TextSpan(text: '收藏了，却跳过 '),
                TextSpan(
                  text: '${guilty.pretender!.count} 次',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '：「${guilty.pretender!.title}」'),
              ],
            ),
          ),
        ],
      ]),
    );
  }
}

/// 生物钟：工作日 vs 周末，给出「你是哪种人」的结论。
class _RhythmCard extends StatelessWidget {
  final RhythmInsight rhythm;
  const _RhythmCard({required this.rhythm});

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).textTheme.bodySmall?.color;
    final total = rhythm.weekdayPlays + rhythm.weekendPlays;
    final weekendPct = total > 0 ? rhythm.weekendPlays / total : 0.0;
    return _CardWrap(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          rhythm.isWeekendPerson
              ? '周末才是你的主场'
              : '工作日，音乐是你的陪伴',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '周末 ${rhythm.weekendPlays} 次 · 工作日 ${rhythm.weekdayPlays} 次，'
          '周末占了 ${(weekendPct * 100).toStringAsFixed(0)}%',
          style: TextStyle(fontSize: 12, color: muted),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: 8,
            width: double.infinity,
            child: Row(children: [
              Expanded(
                flex: rhythm.weekendPlays > 0 ? rhythm.weekendPlays : 1,
                child: Container(color: LuoboAccent.accent),
              ),
              Expanded(
                flex: rhythm.weekdayPlays > 0 ? rhythm.weekdayPlays : 1,
                child: Container(color: LuoboAccent.accent.withValues(alpha: 0.25)),
              ),
            ]),
          ),
        ),
        if (rhythm.weekendArtist != null || rhythm.weekdayArtist != null) ...[
          const SizedBox(height: 12),
          Text(
            rhythm.isWeekendPerson
                ? '周末最常听：${rhythm.weekendArtist ?? "—"}'
                : '工作日最常听：${rhythm.weekdayArtist ?? "—"}',
            style: TextStyle(fontSize: 12, color: muted),
          ),
        ],
      ]),
    );
  }
}

// ─── 通用卡片 ───────────────────────────────────────────────────────────────

class _CardWrap extends StatelessWidget {
  final Widget child;
  const _CardWrap({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}
