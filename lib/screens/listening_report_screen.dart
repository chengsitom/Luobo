import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../theme/design_tokens.dart';
import '../services/recommendation_service.dart';
import '../theme/app_theme.dart';

class ListeningReportScreen extends StatelessWidget {
  const ListeningReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recService = Provider.of<RecommendationService>(context);
    final profiles = recService.profiles;

    if (profiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('听歌报告'),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline_rounded),
              onPressed: () => _showReportHelp(context),
            ),
          ],
        ),
        body: const Center(
          child: Text('还没有听歌数据，多听几首再来看吧'),
        ),
      );
    }

    final report =
        _buildReport(profiles, firstUseDate: recService.firstUseDate);

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
      body: ListView(
        padding: LuoboSpacing.scrollPadding(context, horizontal: 16, top: 12, bottom: 12),
        children: [
          _OverviewSection(report: report),
          const SizedBox(height: 24),
          if (report.streakDays > 0) ...[
            _StreakCard(report: report),
            const SizedBox(height: 24),
          ],
          if (report.monthlyTrend.isNotEmpty) ...[
            _MonthlyTrendCard(points: report.monthlyTrend),
            const SizedBox(height: 24),
          ],
          if (report.genreEvolution.isNotEmpty) ...[
            _GenreEvolutionCard(months: report.genreEvolution),
            const SizedBox(height: 24),
          ],
          _CompletionRateCard(report: report),
          const SizedBox(height: 24),
          if (report.timePeriodInsights.isNotEmpty) ...[
            _TimePeriodInsights(report: report),
            const SizedBox(height: 24),
          ],
          _RankingSection(title: '最常听的歌', items: report.topSongs),
          const SizedBox(height: 24),
          _RankingSection(title: '最常听的歌手', items: report.topArtists),
          const SizedBox(height: 24),
          if (report.artistPeakMonth != null) ...[
            _ArtistPeakCard(peak: report.artistPeakMonth!),
            const SizedBox(height: 24),
          ],
          if (report.mostSkipped.isNotEmpty) ...[
            _RankingSection(
                title: '最常跳过的歌', items: report.mostSkipped, isSkipList: true),
            const SizedBox(height: 24),
          ],
          if (report.singleLoopKings.isNotEmpty) ...[
            _RankingSection(title: '你的单曲循环', items: report.singleLoopKings),
            const SizedBox(height: 24),
          ],
          if (report.genreDistribution.isNotEmpty) ...[
            _GenreDistribution(genres: report.genreDistribution),
            const SizedBox(height: 24),
          ],
          if (report.newDiscoveries.isNotEmpty) ...[
            _InsightCard(
                title: '新发现',
                subtitle: '以前没怎么听，最近突然爱上的歌',
                items: report.newDiscoveries),
            const SizedBox(height: 24),
          ],
          if (report.oldFriends.isNotEmpty) ...[
            _InsightCard(
                title: '老朋友', subtitle: '一直陪伴你的歌手', items: report.oldFriends),
            const SizedBox(height: 24),
          ],
          if (report.weekendInsight != null) ...[
            _WeekendVsWeekdayCard(insight: report.weekendInsight!),
            const SizedBox(height: 24),
          ],
          if (report.songDroughtWarning != null) ...[
            _DroughtWarningCard(warning: report.songDroughtWarning!),
            const SizedBox(height: 24),
          ],
          if (report.longestLoop != null) ...[
            _LongestLoopCard(loop: report.longestLoop!),
            const SizedBox(height: 24),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showReportHelp(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
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
              const Text(
                '听歌报告说明',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '报告完全基于你的本地播放记录自动生成，各指标含义如下：',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.black.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              _buildHelpItem(
                icon: Icons.play_circle_outline_rounded,
                title: '播放次数与完播率',
                desc:
                    '播放次数只统计实际听到 80% 以上的播放；播几秒就跳过不算播放，只记为跳过。完播率 = 完整播放次数 ÷ 播放次数。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.schedule_rounded,
                title: '时段洞察',
                desc: '统计你在不同时间段（早晨/白天/晚上/深夜）的听歌量，以及各时段最常听的歌手和风格。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.local_fire_department_outlined,
                title: '连续听歌',
                desc: '按有效播放统计：最长连续听歌天数、累计活跃天数。连续 = 每天都至少有一次有效播放。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.bar_chart_rounded,
                title: '月份听歌趋势',
                desc: '最近 6 个月每个月的有效播放次数，看看你的听歌热情是涨是跌。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.music_note_outlined,
                title: '曲风进化史',
                desc: '最近 6 个月每个月最常听的 3 种风格，观察你的口味如何演变。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.calendar_month_outlined,
                title: '陪伴天数',
                desc: '从你第一次使用 App 那天算起，已经陪伴你多少天（首次使用日期在首次启动时记录）。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.trending_up_rounded,
                title: '歌手浓度',
                desc: '你最爱的歌手在哪个月份播放最集中，那个月就是你的"上头月"。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.star_rounded,
                title: '最常听的歌 / 最常听的歌手',
                desc: '按播放次数从高到低排名。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.skip_next_rounded,
                title: '最常跳过的歌',
                desc: '跳过率超过 40%、且播放与跳过累计 3 次以上的歌曲。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.repeat_rounded,
                title: '单曲循环',
                desc: '完整播放 5 次以上、完播率超过 80% 的歌，说明你真的爱它。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.pie_chart_outline_rounded,
                title: '流派分布',
                desc: '你所听音乐的风格占比。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.favorite_outline_rounded,
                title: '新发现 / 老朋友',
                desc: '新发现：以前很少听、最近突然爱上的歌；老朋友：一直陪伴你的歌手。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.calendar_view_day_rounded,
                title: '周末 vs 工作日',
                desc: '对比工作日和周末的播放量，以及各自最常听的歌手。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.warning_amber_rounded,
                title: '歌荒预警',
                desc: '最近 7 天播放高度集中在少数几首歌上时提醒你：该去发现新歌了。',
                isDark: isDark,
              ),
              _buildHelpItem(
                icon: Icons.emoji_events_outlined,
                title: '单曲循环王',
                desc: '播放次数最多的那首歌。',
                isDark: isDark,
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
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.appleMusicRed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.black.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ReportData _buildReport(
    Map<String, SongProfile> profiles, {
    DateTime? firstUseDate,
  }) {
    int totalPlays = 0;
    int totalDuration = 0;
    int totalSkips = 0;
    int totalCompleted = 0;
    final Set<String> uniqueArtists = {};
    final Map<String, int> artistPlayCounts = {};
    final Map<String, double> genrePlays = {};

    for (final p in profiles.values) {
      totalPlays += p.playCount;
      totalDuration += p.totalListenTime;
      totalSkips += p.skipCount;
      totalCompleted += p.completedPlays;
      if (p.artist != null) {
        uniqueArtists.add(p.artist!);
        artistPlayCounts[p.artist!] =
            (artistPlayCounts[p.artist!] ?? 0) + p.playCount;
      }
      if (p.genre != null && p.genre!.isNotEmpty) {
        final normalizedGenre = _normalizeGenre(p.genre!);
        genrePlays[normalizedGenre] =
            (genrePlays[normalizedGenre] ?? 0) + p.playCount;
      }
    }

    final sortedSongs = profiles.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final topSongs = sortedSongs
        .take(10)
        .map((p) => _RankItem(
            title: p.title,
            subtitle: p.artist ?? '',
            count: p.playCount,
            suffix: '次'))
        .toList();

    final sortedArtists = artistPlayCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists
        .take(10)
        .map((e) =>
            _RankItem(title: e.key, subtitle: '', count: e.value, suffix: '次'))
        .toList();

    final skippable = profiles.values
        .where((p) => p.playCount + p.skipCount >= 3 && p.skipRate > 0.4)
        .toList()
      ..sort((a, b) => b.skipCount.compareTo(a.skipCount));
    final mostSkipped = skippable
        .take(10)
        .map((p) => _RankItem(
            title: p.title,
            subtitle: p.artist ?? '',
            count: p.skipCount,
            suffix: '次跳过'))
        .toList();

    final loopable = profiles.values
        .where((p) => p.playCount >= 5 && p.completionRate > 0.8)
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final singleLoopKings = loopable
        .take(5)
        .map((p) => _RankItem(
            title: p.title,
            subtitle: p.artist ?? '',
            count: p.playCount,
            suffix: '次完整播放'))
        .toList();

    final totalGenrePlays = genrePlays.values.fold(0.0, (sum, v) => sum + v);
    final sortedGenres = genrePlays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final genreDistribution = sortedGenres.take(6).map((e) {
      final percent =
          totalGenrePlays > 0 ? (e.value / totalGenrePlays * 100) : 0.0;
      return _GenreItem(name: e.key, percent: percent);
    }).toList();

    final completionRate = totalPlays > 0 ? totalCompleted / totalPlays : 0.0;

    final streak = _buildStreak(profiles);
    final companionDays = firstUseDate == null
        ? 0
        : DateTime.now().difference(firstUseDate).inDays + 1;

    return _ReportData(
      totalPlays: totalPlays,
      totalMinutes: totalDuration ~/ 60,
      uniqueSongs: profiles.length,
      uniqueArtists: uniqueArtists.length,
      completionRate: completionRate,
      totalSkips: totalSkips,
      topSongs: topSongs,
      topArtists: topArtists,
      mostSkipped: mostSkipped,
      singleLoopKings: singleLoopKings,
      genreDistribution: genreDistribution,
      timePeriodInsights: _buildTimePeriodInsights(profiles),
      newDiscoveries: _buildNewDiscoveries(profiles),
      oldFriends: _buildOldFriends(profiles),
      weekendInsight: _buildWeekendInsight(profiles),
      streakDays: streak?.$1 ?? 0,
      activeDays: streak?.$2 ?? 0,
      monthlyTrend: _buildMonthlyTrend(profiles),
      genreEvolution: _buildGenreEvolution(profiles),
      firstUseDate: firstUseDate,
      companionDays: companionDays,
      artistPeakMonth: _buildArtistPeakMonth(profiles),
      songDroughtWarning: _buildDroughtWarning(profiles),
      longestLoop: _buildLongestLoop(profiles),
    );
  }

  /// 播放量最高歌手的「浓度最高月份」：返回 (歌手, 月份标签, 该月播放次数)
  (String, String, int)? _buildArtistPeakMonth(
    Map<String, SongProfile> profiles,
  ) {
    // Aggregate play counts by artist (consistent with the "top artists" ranking)
    final Map<String, int> artistTotalPlays = {};
    for (final p in profiles.values) {
      if (p.artist == null) continue;
      artistTotalPlays[p.artist!] =
          (artistTotalPlays[p.artist!] ?? 0) + p.playCount;
    }
    if (artistTotalPlays.isEmpty) return null;
    final topArtist = artistTotalPlays.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;

    final Map<String, int> monthly = {};
    for (final p in profiles.values) {
      if (p.artist != topArtist) continue;
      for (final e in p.monthlyPlays.entries) {
        monthly[e.key] = (monthly[e.key] ?? 0) + e.value;
      }
    }
    if (monthly.isEmpty) return null;
    final peak = monthly.entries.reduce((a, b) => b.value > a.value ? b : a);
    final parts = peak.key.split('-');
    return (topArtist, '${int.parse(parts[1])}月', peak.value);
  }

  /// 返回 (最长连续听歌天数, 累计活跃天数)，基于 dailyPlays 的日期并集
  (int, int)? _buildStreak(Map<String, SongProfile> profiles) {
    final Set<String> allDays = {};
    for (final p in profiles.values) {
      allDays.addAll(p.dailyPlays.keys);
    }
    if (allDays.isEmpty) return null;
    final days = allDays.map(_parseDayKey).toList()..sort();
    int longest = 1, current = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return (longest, days.length);
  }

  DateTime _parseDayKey(String key) {
    final parts = key.split('-');
    // 用 UTC 构建纯日期，避免夏令时导致相邻两天的差不是恰好 24 小时
    return DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// 按月份聚合有效播放次数，取最近 6 个月
  List<_MonthlyPoint> _buildMonthlyTrend(Map<String, SongProfile> profiles) {
    final Map<String, int> monthly = {};
    for (final p in profiles.values) {
      for (final e in p.monthlyPlays.entries) {
        monthly[e.key] = (monthly[e.key] ?? 0) + e.value;
      }
    }
    final months = monthly.keys.toList()..sort();
    final last = months.length > 6 ? months.sublist(months.length - 6) : months;
    return last.map((m) {
      final parts = m.split('-');
      return _MonthlyPoint(
          label: '${int.parse(parts[1])}月', count: monthly[m]!);
    }).toList();
  }

  /// 按月统计流派播放量，取最近 6 个月、每月前 3 大风格
  List<_GenreMonth> _buildGenreEvolution(Map<String, SongProfile> profiles) {
    final Map<String, Map<String, int>> byMonth = {};
    for (final p in profiles.values) {
      final genre = p.genre;
      if (genre == null) continue;
      for (final e in p.monthlyPlays.entries) {
        byMonth.putIfAbsent(e.key, () => {});
        byMonth[e.key]![genre] = (byMonth[e.key]![genre] ?? 0) + e.value;
      }
    }
    final months = byMonth.keys.toList()..sort();
    final last = months.length > 6 ? months.sublist(months.length - 6) : months;
    return last.map((m) {
      final entries = byMonth[m]!.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final parts = m.split('-');
      return _GenreMonth(
        label: '${int.parse(parts[0])}年${int.parse(parts[1])}月',
        genres: entries.take(3).map((e) => '${e.key} ×${e.value}').toList(),
      );
    }).toList();
  }

  /// Normalize genre names: case-insensitive + common Chinese/English/French mappings
  String _normalizeGenre(String genre) {
    final lower = genre.toLowerCase().trim();
    const mapping = {
      // 流行
      'pop': '流行',
      'cpop': '流行',
      'c-pop': '流行',
      '流行': '流行',
      '流行音乐': '流行',
      '国语流行': '流行',
      '华语流行': '流行',
      // 摇滚
      'rock': '摇滚',
      'rock & roll': '摇滚',
      'rock and roll': '摇滚',
      'rock&roll': '摇滚',
      '摇滚': '摇滚',
      '摇滚乐': '摇滚',
      // 流行摇滚
      'pop rock': '流行摇滚',
      'pop-rock': '流行摇滚',
      // 说唱
      'hip-hop': '说唱',
      'hip hop': '说唱',
      'hiphop': '说唱',
      '说唱': '说唱',
      '嘻哈': '说唱',
      'rap': '说唱',
      // R&B
      'r&b': 'R&B',
      'rnb': 'R&B',
      // 爵士
      'jazz': '爵士',
      '爵士': '爵士',
      '爵士乐': '爵士',
      // 古典
      'classical': '古典',
      '古典': '古典',
      '古典音乐': '古典',
      // 电子
      'electronic': '电子',
      'electro': '电子',
      '电子': '电子',
      '电子音乐': '电子',
      // 民谣
      'folk': '民谣',
      '民谣': '民谣',
      // 金属
      'metal': '金属',
      '金属': '金属',
      // 蓝调
      'blues': '蓝调',
      '蓝调': '蓝调',
      // 乡村
      'country': '乡村',
      '乡村': '乡村',
      // 雷鬼
      'reggae': '雷鬼',
      '雷鬼': '雷鬼',
      // 朋克
      'punk': '朋克',
      '朋克': '朋克',
      // 灵魂乐
      'soul': '灵魂乐',
      '灵魂乐': '灵魂乐',
      // 独立
      'indie': '独立',
      '独立': '独立',
      '独立音乐': '独立',
      // 另类
      'alternative': '另类',
      '另类': '另类',
      // 世界音乐
      'world': '世界音乐',
      'world music': '世界音乐',
      'asie': '世界音乐',
      'azië': '世界音乐',
      'musiques du monde': '世界音乐',
      // 原声带
      'soundtrack': '原声带',
      'ost': '原声带',
      'bandes originales de films': '原声带',
      '原声': '原声带',
      '原声带': '原声带',
      '影视原声': '原声带',
      // 其他
      'other': '其他',
      '其他': '其他',
    };
    return mapping[lower] ?? genre;
  }

  List<_TimePeriodInsight> _buildTimePeriodInsights(
      Map<String, SongProfile> profiles) {
    final Map<String, Map<String, int>> periodArtists = {
      '深夜': {},
      '早晨': {},
      '白天': {},
      '晚上': {}
    };
    final Map<String, Map<String, int>> periodGenres = {
      '深夜': {},
      '早晨': {},
      '白天': {},
      '晚上': {}
    };

    for (final p in profiles.values) {
      for (final entry in p.hourlyPlays.entries) {
        final hour = entry.key;
        final count = entry.value;
        final period = hour >= 22 || hour < 5
            ? '深夜'
            : hour < 9
                ? '早晨'
                : hour < 18
                    ? '白天'
                    : '晚上';
        if (p.artist != null)
          periodArtists[period]![p.artist!] =
              (periodArtists[period]![p.artist!] ?? 0) + count;
        if (p.genre != null && p.genre!.isNotEmpty) {
          final ng = _normalizeGenre(p.genre!);
          periodGenres[period]![ng] = (periodGenres[period]![ng] ?? 0) + count;
        }
      }
    }

    final insights = <_TimePeriodInsight>[];
    for (final period in periodArtists.keys) {
      final artists = periodArtists[period]!;
      final genres = periodGenres[period]!;
      if (artists.isEmpty && genres.isEmpty) continue;
      String? topArtist;
      String? topGenre;
      int totalInPeriod = 0;
      if (artists.isNotEmpty) {
        final sorted = artists.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topArtist = sorted.first.key;
        totalInPeriod = artists.values.fold(0, (s, v) => s + v);
      }
      if (genres.isNotEmpty) {
        final sorted = genres.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        topGenre = sorted.first.key;
      }
      if (totalInPeriod >= 3) {
        insights.add(_TimePeriodInsight(
            period: period,
            topArtist: topArtist,
            topGenre: topGenre,
            playCount: totalInPeriod));
      }
    }
    insights.sort((a, b) => b.playCount.compareTo(a.playCount));
    return insights;
  }

  List<String> _buildNewDiscoveries(Map<String, SongProfile> profiles) {
    // "新发现"：过去30天几乎没听过，但最近7天突然频繁播放的歌
    final now = DateTime.now();
    final recentCutoff = now.subtract(const Duration(days: 7));

    final discoveries = <_RankItem>[];
    for (final p in profiles.values) {
      if (!p.lastPlayed.isAfter(recentCutoff)) continue;
      // 判断标准：总播放不超过5次（说明以前没怎么听），但最近活跃
      // 且 playCount >= 3（最近确实在反复听）
      if (p.playCount >= 3 && p.playCount <= 8) {
        discoveries.add(_RankItem(
          title: '${p.title} - ${p.artist ?? ""}',
          subtitle: '',
          count: p.playCount,
          suffix: '次',
        ));
      }
    }
    discoveries.sort((a, b) => b.count.compareTo(a.count));
    return discoveries.take(5).map((e) => e.title).toList();
  }

  List<String> _buildOldFriends(Map<String, SongProfile> profiles) {
    final Map<String, int> artistTotalPlays = {};
    for (final p in profiles.values) {
      if (p.artist == null) continue;
      artistTotalPlays[p.artist!] =
          (artistTotalPlays[p.artist!] ?? 0) + p.playCount;
    }
    final friends = artistTotalPlays.entries
        .where((e) => e.value >= 10)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return friends.take(5).map((e) => e.key).toList();
  }

  _WeekendVsWeekday? _buildWeekendInsight(Map<String, SongProfile> profiles) {
    final Map<String, int> weekdayArtists = {};
    final Map<String, int> weekendArtists = {};
    int weekdayPlays = 0;
    int weekendPlays = 0;

    for (final p in profiles.values) {
      // Aggregate per actual listening date (dailyPlays), not by the weekday
      // of the *last* play — otherwise the full historical play count of a
      // song would be attributed to whichever weekday it was last played on.
      for (final entry in p.dailyPlays.entries) {
        final isWeekend = _isWeekendDayKey(entry.key);
        if (isWeekend) {
          weekendPlays += entry.value;
          if (p.artist != null) {
            weekendArtists[p.artist!] =
                (weekendArtists[p.artist!] ?? 0) + entry.value;
          }
        } else {
          weekdayPlays += entry.value;
          if (p.artist != null) {
            weekdayArtists[p.artist!] =
                (weekdayArtists[p.artist!] ?? 0) + entry.value;
          }
        }
      }
    }
    if (weekdayPlays == 0 && weekendPlays == 0) return null;

    String? topWeekday = weekdayArtists.isNotEmpty
        ? (weekdayArtists.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
        : null;
    String? topWeekend = weekendArtists.isNotEmpty
        ? (weekendArtists.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
        : null;

    return _WeekendVsWeekday(
        weekdayPlays: weekdayPlays,
        weekendPlays: weekendPlays,
        topWeekdayArtist: topWeekday,
        topWeekendArtist: topWeekend);
  }

  bool _isWeekendDayKey(String key) {
    final dow = _parseDayKey(key).weekday;
    return dow == 6 || dow == 7;
  }

  _DroughtWarning? _buildDroughtWarning(Map<String, SongProfile> profiles) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = profiles.values
        .where((p) => p.lastPlayed.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    if (recent.length <= 10) return null;
    final totalPlays = recent.fold(0, (sum, p) => sum + p.playCount);
    final top10Plays = recent.take(10).fold(0, (sum, p) => sum + p.playCount);
    final concentration = totalPlays > 0 ? top10Plays / totalPlays : 0.0;
    if (concentration > 0.8)
      return _DroughtWarning(
          concentration: concentration,
          repeatSongs: 10,
          totalSongs: recent.length);
    return null;
  }

  _LongestLoop? _buildLongestLoop(Map<String, SongProfile> profiles) {
    if (profiles.isEmpty) return null;
    final sorted = profiles.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final top = sorted.first;
    if (top.playCount < 5) return null;
    return _LongestLoop(
        title: top.title, artist: top.artist ?? '', playCount: top.playCount);
  }
}

// ─── Data Models ─────────────────────────────────────────────────────────────

class _ReportData {
  final int totalPlays, totalMinutes, uniqueSongs, uniqueArtists, totalSkips;
  final double completionRate;
  final List<_RankItem> topSongs, topArtists, mostSkipped, singleLoopKings;
  final List<_GenreItem> genreDistribution;
  final List<_TimePeriodInsight> timePeriodInsights;
  final List<String> newDiscoveries, oldFriends;
  final _WeekendVsWeekday? weekendInsight;
  final int streakDays, activeDays;
  final List<_MonthlyPoint> monthlyTrend;
  final List<_GenreMonth> genreEvolution;
  final DateTime? firstUseDate;
  final int companionDays;
  final (String, String, int)? artistPeakMonth;
  final _DroughtWarning? songDroughtWarning;
  final _LongestLoop? longestLoop;

  _ReportData(
      {required this.totalPlays,
      required this.totalMinutes,
      required this.uniqueSongs,
      required this.uniqueArtists,
      required this.completionRate,
      required this.totalSkips,
      required this.topSongs,
      required this.topArtists,
      required this.mostSkipped,
      required this.singleLoopKings,
      required this.genreDistribution,
      required this.timePeriodInsights,
      required this.newDiscoveries,
      required this.oldFriends,
      this.weekendInsight,
      this.streakDays = 0,
      this.activeDays = 0,
      this.monthlyTrend = const [],
      this.genreEvolution = const [],
      this.firstUseDate,
      this.companionDays = 0,
      this.artistPeakMonth,
      this.songDroughtWarning,
      this.longestLoop});
}

class _RankItem {
  final String title, subtitle, suffix;
  final int count;
  _RankItem(
      {required this.title,
      required this.subtitle,
      required this.count,
      required this.suffix});
}

class _GenreItem {
  final String name;
  final double percent;
  _GenreItem({required this.name, required this.percent});
}

class _TimePeriodInsight {
  final String period;
  final String? topArtist, topGenre;
  final int playCount;
  _TimePeriodInsight(
      {required this.period,
      this.topArtist,
      this.topGenre,
      required this.playCount});
}

class _WeekendVsWeekday {
  final int weekdayPlays, weekendPlays;
  final String? topWeekdayArtist, topWeekendArtist;
  _WeekendVsWeekday(
      {required this.weekdayPlays,
      required this.weekendPlays,
      this.topWeekdayArtist,
      this.topWeekendArtist});
}

class _MonthlyPoint {
  final String label;
  final int count;
  _MonthlyPoint({required this.label, required this.count});
}

class _GenreMonth {
  final String label;
  final List<String> genres;
  _GenreMonth({required this.label, required this.genres});
}

class _DroughtWarning {
  final double concentration;
  final int repeatSongs, totalSongs;
  _DroughtWarning(
      {required this.concentration,
      required this.repeatSongs,
      required this.totalSongs});
}

class _LongestLoop {
  final String title, artist;
  final int playCount;
  _LongestLoop(
      {required this.title, required this.artist, required this.playCount});
}

// ─── UI Widgets ──────────────────────────────────────────────────────────────

class _OverviewSection extends StatelessWidget {
  final _ReportData report;
  const _OverviewSection({required this.report});

  @override
  Widget build(BuildContext context) {
    final hours = report.totalMinutes ~/ 60;
    final mins = report.totalMinutes % 60;
    final durationStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          Expanded(child: _StatItem(value: durationStr, label: '总时长')),
          Expanded(
              child: _StatItem(value: '${report.totalPlays}', label: '播放次数')),
          Expanded(
              child: _StatItem(value: '${report.uniqueArtists}', label: '位歌手')),
          Expanded(
              child: _StatItem(value: '${report.uniqueSongs}', label: '首歌')),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value, label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodySmall?.color,
        ),
      ),
    ]);
  }
}

class _StreakCard extends StatelessWidget {
  final _ReportData report;
  const _StreakCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final firstUse = report.firstUseDate;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('连续听歌',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('最长连续 ${report.streakDays} 天 · 累计活跃 ${report.activeDays} 天',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child:
                  _StatItem(value: '${report.streakDays}', label: '最长连续（天）')),
          Expanded(
              child:
                  _StatItem(value: '${report.activeDays}', label: '累计活跃（天）')),
          if (report.companionDays > 0)
            Expanded(
                child: _StatItem(
                    value: '${report.companionDays}', label: '陪伴（天）')),
        ]),
        if (firstUse != null) ...[
          const SizedBox(height: 12),
          Text(
            '从 ${firstUse.year} 年 ${firstUse.month} 月 ${firstUse.day} 日开始，已陪伴你 ${report.companionDays} 天',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).textTheme.bodySmall?.color),
          ),
        ],
      ]),
    );
  }
}

class _MonthlyTrendCard extends StatelessWidget {
  final List<_MonthlyPoint> points;
  const _MonthlyTrendCard({required this.points});

  @override
  Widget build(BuildContext context) {
    final maxCount = points.fold(0, (int m, p) => p.count > m ? p.count : m);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('月份听歌趋势',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('最近 ${points.length} 个月，每个月的有效播放次数',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 16),
        SizedBox(
          height: 150,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: points.map((p) {
              final ratio = maxCount > 0 ? p.count / maxCount : 0.0;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      Text('${p.count}',
                          style: TextStyle(
                              fontSize: 10,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            heightFactor: ratio < 0.05 ? 0.05 : ratio,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    AppTheme.appleMusicRed
                                        .withValues(alpha: 0.4),
                                    AppTheme.appleMusicRed,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(p.label,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ]),
    );
  }
}

class _GenreEvolutionCard extends StatelessWidget {
  final List<_GenreMonth> months;
  const _GenreEvolutionCard({required this.months});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('曲风进化史',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('最近 ${months.length} 个月，你都在听什么风格',
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 12),
        ...months.map((m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                    width: 80,
                    child: Text(m.label,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600))),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(m.genres.join(' · '),
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color:
                                Theme.of(context).textTheme.bodySmall?.color))),
              ]),
            )),
      ]),
    );
  }
}

class _ArtistPeakCard extends StatelessWidget {
  final (String, String, int) peak; // (artist, monthLabel, count)
  const _ArtistPeakCard({required this.peak});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('歌手浓度',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${peak.$1} 是你最爱的歌手，${peak.$2} 是你最上头的时候（听了 ${peak.$3} 次）',
          style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Theme.of(context).textTheme.bodySmall?.color),
        ),
      ]),
    );
  }
}

class _CompletionRateCard extends StatelessWidget {
  final _ReportData report;
  const _CompletionRateCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final percent = (report.completionRate * 100).toStringAsFixed(1);
    final desc = report.completionRate > 0.85
        ? '你是认真听歌的人'
        : report.completionRate > 0.6
            ? '偶尔会跳过几首'
            : '你比较挑剔，很多歌没听完';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('完播率',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(children: [
          Text('$percent%',
              style:
                  const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          Expanded(
              child: Text(desc,
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color))),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: report.completionRate,
              minHeight: 6,
              backgroundColor: Colors.grey.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(AppTheme.appleMusicRed)),
        ),
      ]),
    );
  }
}

class _TimePeriodInsights extends StatelessWidget {
  final _ReportData report;
  const _TimePeriodInsights({required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('时段偏好',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...report.timePeriodInsights.map((insight) {
          final parts = <String>[];
          if (insight.topGenre != null) parts.add(insight.topGenre!);
          if (insight.topArtist != null) parts.add(insight.topArtist!);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(children: [
              SizedBox(
                  width: 50,
                  child: Text(insight.period,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600))),
              Expanded(
                  child: Text(parts.isNotEmpty ? parts.join(' · ') : '各种音乐',
                      style: TextStyle(
                          fontSize: 14,
                          color:
                              Theme.of(context).textTheme.bodySmall?.color))),
              Text('${insight.playCount}次',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).textTheme.bodySmall?.color)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _RankingSection extends StatelessWidget {
  final String title;
  final List<_RankItem> items;
  final bool isSkipList;
  const _RankingSection(
      {required this.title, required this.items, this.isSkipList = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: i < 3
                              ? AppTheme.appleMusicRed
                              : Theme.of(context).textTheme.bodySmall?.color))),
              const SizedBox(width: 8),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(item.title,
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    if (item.subtitle.isNotEmpty)
                      Text(item.subtitle,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  Theme.of(context).textTheme.bodySmall?.color),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                  ])),
              Text('${item.count} ${item.suffix}',
                  style: TextStyle(
                      fontSize: 13,
                      color: isSkipList
                          ? Colors.orange
                          : Theme.of(context).textTheme.bodySmall?.color)),
            ]),
          );
        }),
      ]),
    );
  }
}

class _GenreDistribution extends StatelessWidget {
  final List<_GenreItem> genres;
  const _GenreDistribution({required this.genres});

  @override
  Widget build(BuildContext context) {
    final maxPercent = genres.isNotEmpty ? genres.first.percent : 1.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('流派分布',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ...genres.map((genre) {
          final barWidth = maxPercent > 0 ? genre.percent / maxPercent : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(genre.name, style: const TextStyle(fontSize: 13)),
                Text('${genre.percent.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
              ]),
              const SizedBox(height: 4),
              FractionallySizedBox(
                widthFactor: barWidth.clamp(0.0, 1.0),
                child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          AppTheme.appleMusicRed,
                          AppTheme.appleMusicRed.withValues(alpha: 0.6)
                        ]),
                        borderRadius: BorderRadius.circular(3))),
              ),
            ]),
          );
        }),
      ]),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title, subtitle;
  final List<String> items;
  const _InsightCard(
      {required this.title, required this.subtitle, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).textTheme.bodySmall?.color)),
        const SizedBox(height: 12),
        ...items.map((name) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              const Icon(Icons.person_outline, size: 18),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(fontSize: 14))
            ]))),
      ]),
    );
  }
}

class _WeekendVsWeekdayCard extends StatelessWidget {
  final _WeekendVsWeekday insight;
  const _WeekendVsWeekdayCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('周末 vs 工作日',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
              child: Column(children: [
            const Text('工作日',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${insight.weekdayPlays} 次',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            if (insight.topWeekdayArtist != null) ...[
              const SizedBox(height: 4),
              Text(insight.topWeekdayArtist!,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)
            ],
          ])),
          Container(
              width: 1, height: 60, color: Colors.grey.withValues(alpha: 0.3)),
          Expanded(
              child: Column(children: [
            const Text('周末',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('${insight.weekendPlays} 次',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).textTheme.bodySmall?.color)),
            if (insight.topWeekendArtist != null) ...[
              const SizedBox(height: 4),
              Text(insight.topWeekendArtist!,
                  style: const TextStyle(fontSize: 13),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis)
            ],
          ])),
        ]),
      ]),
    );
  }
}

class _DroughtWarningCard extends StatelessWidget {
  final _DroughtWarning warning;
  const _DroughtWarningCard({required this.warning});

  @override
  Widget build(BuildContext context) {
    final percent = (warning.concentration * 100).toStringAsFixed(0);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 32),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('歌荒预警',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('最近 7 天，你 $percent% 的播放集中在 ${warning.repeatSongs} 首歌上。要不要发现点新歌？',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ])),
      ]),
    );
  }
}

class _LongestLoopCard extends StatelessWidget {
  final _LongestLoop loop;
  const _LongestLoopCard({required this.loop});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(CupertinoIcons.repeat, size: 28),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('最强单曲循环',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${loop.title} - ${loop.artist}',
              style: const TextStyle(fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
          Text('累计播放 ${loop.playCount} 次',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).textTheme.bodySmall?.color)),
        ])),
      ]),
    );
  }
}
