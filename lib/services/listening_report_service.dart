import 'recommendation_service.dart';
import '../models/song.dart';

/// 听歌报告的全部洞察数据。
///
/// 设计原则：这里只产出**关于「你」的结论**，不是数据库报表。
/// UI 层只负责呈现，不含任何统计逻辑，便于单测与复用。
class ListeningInsight {
  // 基础盘（只在 Hero 卡用小字呈现，不再单独成卡）
  final int totalPlays;
  final int totalMinutes;
  final int uniqueSongs;
  final int uniqueArtists;
  final int totalSkips;
  final double completionRate;
  final int streakDays;
  final int activeDays;
  final int companionDays;

  // 四个故事章节
  final MusicPersona persona;
  final List<GenreShare> flavorPrint;
  final FlavorShift? flavorShift;
  final List<TimeCapsuleItem> timeCapsule;
  final List<InsightRankItem> topSongs;
  final List<InsightRankItem> topArtists;
  final List<NewDiscovery> discoveries;
  final DroughtInfo? drought;

  // A 类新增维度（均用现成字段算出，不碰数据层）
  final List<ForgottenTreasure> forgottenTreasures;
  final PowerDay? powerDay;
  final GuiltyPleasure? guiltyPleasure;
  final RhythmInsight? rhythm;
  final List<AlbumStay> topAlbums;

  ListeningInsight({
    required this.totalPlays,
    required this.totalMinutes,
    required this.uniqueSongs,
    required this.uniqueArtists,
    required this.totalSkips,
    required this.completionRate,
    required this.streakDays,
    required this.activeDays,
    required this.companionDays,
    required this.persona,
    required this.flavorPrint,
    required this.flavorShift,
    required this.timeCapsule,
    required this.topSongs,
    required this.topArtists,
    required this.discoveries,
    required this.drought,
    required this.forgottenTreasures,
    required this.powerDay,
    required this.guiltyPleasure,
    required this.rhythm,
    required this.topAlbums,
  });

  bool get hasData => totalPlays > 0;
}

/// 音乐人格：主标签 + 一句话钩子 + 若干性格碎片。
class MusicPersona {
  final String title;
  final String headline;
  final String description;
  final List<String> traits;

  MusicPersona({
    required this.title,
    required this.headline,
    required this.description,
    required this.traits,
  });
}

class GenreShare {
  final String name;
  final int plays;
  final double percent;
  GenreShare({required this.name, required this.plays, required this.percent});
}

/// 口味变迁：最近 30 天 vs 前 30 天，头部歌手/风格是否发生更替。
class FlavorShift {
  final String? fromArtist;
  final String? toArtist;
  final int fromPlays;
  final int toPlays;
  final String? fromGenre;
  final String? toGenre;

  FlavorShift({
    this.fromArtist,
    this.toArtist,
    required this.fromPlays,
    required this.toPlays,
    this.fromGenre,
    this.toGenre,
  });

  bool get hasArtistShift =>
      fromArtist != null && toArtist != null && fromArtist != toArtist;
  bool get hasGenreShift =>
      fromGenre != null && toGenre != null && fromGenre != toGenre;
}

/// 时光机里的一张卡片：初见 / 最长陪伴 / 上头月。
class TimeCapsuleItem {
  final String kind; // '初见' / '最长陪伴' / '上头月'
  final String title;
  final String? artist;
  final String detail;
  TimeCapsuleItem({
    required this.kind,
    required this.title,
    this.artist,
    required this.detail,
  });
}

class InsightRankItem {
  final String id;
  final String title;
  final String? subtitle;
  final int count;
  InsightRankItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.count,
  });
}

class NewDiscovery {
  final String songId;
  final String title;
  final String? artist;
  final int plays;
  NewDiscovery({
    required this.songId,
    required this.title,
    this.artist,
    required this.plays,
  });
}

class DroughtInfo {
  final double concentration;
  final int recentSongs;
  DroughtInfo({required this.concentration, required this.recentSongs});
}

/// 遗忘的宝藏：曾经循环过、但很久没再听的歌。
class ForgottenTreasure {
  final String songId;
  final String title;
  final String? artist;
  final int plays;
  final int daysSinceLastPlay;
  ForgottenTreasure({
    required this.songId,
    required this.title,
    this.artist,
    required this.plays,
    required this.daysSinceLastPlay,
  });
}

/// 那一天：某一天把某一首歌循环了最多遍。
class PowerDay {
  final String day; // YYYY-MM-DD
  final String songId;
  final String title;
  final String? artist;
  final int plays;
  PowerDay({
    required this.day,
    required this.songId,
    required this.title,
    this.artist,
    required this.plays,
  });
}

/// 口是心非：收藏了却总跳过 / 没收藏却反复听。
class GuiltyPleasure {
  final NewDiscovery? hiddenGem; // 没收藏却反复听
  final InsightRankItem? pretender; // 收藏了却总跳过
  GuiltyPleasure({this.hiddenGem, this.pretender});
}

/// 生物钟：工作日 vs 周末的播放量与各自最常听的歌手。
class RhythmInsight {
  final int weekdayPlays;
  final int weekendPlays;
  final String? weekdayArtist;
  final String? weekendArtist;
  RhythmInsight({
    required this.weekdayPlays,
    required this.weekendPlays,
    this.weekdayArtist,
    this.weekendArtist,
  });

  bool get isWeekendPerson => weekendPlays > weekdayPlays;
}

/// 专辑情节：按 albumId 聚合的停留，UI 层负责把 id 映射成名字。
class AlbumStay {
  final String albumId;
  final int plays;
  final int songCount;
  AlbumStay({
    required this.albumId,
    required this.plays,
    required this.songCount,
  });
}

/// 把行为画像翻译成人格故事。纯函数，[now] 可注入以便测试。
class ListeningInsightBuilder {
  final Map<String, SongProfile> profiles;
  final DateTime now;
  final DateTime? firstUseDate;

  /// 收藏的歌曲 id；「口是心非」维度需要它，缺省视为无收藏。
  final Set<String> starredSongIds;

  /// songId → genre 的曲库映射。老画像在首次播放时没存 genre，用它回填；
  /// 只读、不落盘，不修改持久化数据。
  final Map<String, String> genreLookup;

  ListeningInsightBuilder(
    this.profiles, {
    DateTime? now,
    this.firstUseDate,
    Set<String>? starredSongIds,
    Map<String, String>? genreLookup,
  })  : now = now ?? DateTime.now(),
        starredSongIds = starredSongIds ?? const {},
        genreLookup = genreLookup ?? const {};

  /// 取一首歌归一化后的风格：画像优先，缺失时从曲库回填，脏标签返回 null。
  String? _cleanGenre(SongProfile p) {
    var genre = p.genre;
    if (genre == null || genre.isEmpty) genre = genreLookup[p.songId];
    if (genre == null || genre.isEmpty) return null;
    return normalizeGenre(genre);
  }

  ListeningInsight build() {
    int totalPlays = 0, totalDuration = 0, totalSkips = 0, totalCompleted = 0;
    final artistPlays = <String, int>{};
    final genrePlays = <String, int>{};

    for (final p in profiles.values) {
      totalPlays += p.playCount;
      totalDuration += p.totalListenTime;
      totalSkips += p.skipCount;
      totalCompleted += p.completedPlays;
      if (p.artist != null && p.artist!.isNotEmpty) {
        artistPlays[p.artist!] = (artistPlays[p.artist!] ?? 0) + p.playCount;
      }
      final g = _cleanGenre(p);
      // 0 次播放的画像（如只被回填了 genre、实际没听过）不构成口味，
      // 否则会出现「摇滚 0% · 0 次」这种空条目，且占比被污染。
      if (g != null && p.playCount > 0) {
        genrePlays[g] = (genrePlays[g] ?? 0) + p.playCount;
      }
    }

    final sortedSongs = profiles.values.toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));
    final topSongs = sortedSongs.take(10).map(_toRankItem).toList();

    final sortedArtists = artistPlays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topArtists = sortedArtists
        .take(10)
        .map((e) => InsightRankItem(id: e.key, title: e.key, count: e.value))
        .toList();

    final totalGenrePlays = genrePlays.values.fold(0, (s, v) => s + v);
    final flavorPrint = genrePlays.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = flavorPrint.take(4).map((e) {
      return GenreShare(
        name: e.key,
        plays: e.value,
        percent: totalGenrePlays > 0 ? e.value / totalGenrePlays * 100 : 0.0,
      );
    }).toList();

    final completionRate = totalPlays > 0 ? totalCompleted / totalPlays : 0.0;
    final topArtistShare = totalPlays > 0 && sortedArtists.isNotEmpty
        ? sortedArtists.first.value / totalPlays
        : 0.0;
    final periods = _periodPlays();
    final dominantPeriod = _dominantPeriod(periods);
    final streak = _streak();

    return ListeningInsight(
      totalPlays: totalPlays,
      totalMinutes: totalDuration ~/ 60,
      uniqueSongs: profiles.length,
      uniqueArtists: artistPlays.length,
      totalSkips: totalSkips,
      completionRate: completionRate,
      streakDays: streak.$1,
      activeDays: streak.$2,
      companionDays: firstUseDate == null
          ? 0
          : now.difference(firstUseDate!).inDays + 1,
      persona: _buildPersona(
        dominantPeriod: dominantPeriod,
        periodPlays: periods,
        completionRate: completionRate,
        topArtistShare: topArtistShare,
        streakDays: streak.$1,
      ),
      flavorPrint: topGenres,
      flavorShift: _buildFlavorShift(),
      timeCapsule: _buildTimeCapsule(sortedSongs),
      topSongs: topSongs,
      topArtists: topArtists,
      discoveries: _buildDiscoveries(),
      drought: _buildDrought(),
      forgottenTreasures: _buildForgottenTreasures(),
      powerDay: _buildPowerDay(),
      guiltyPleasure: _buildGuiltyPleasure(),
      rhythm: _buildRhythm(),
      topAlbums: _buildTopAlbums(),
    );
  }

  InsightRankItem _toRankItem(SongProfile p) => InsightRankItem(
        id: p.songId,
        title: p.title,
        subtitle: p.artist,
        count: p.playCount,
      );

  // ── 人格 ──────────────────────────────────────────────────────────────────

  Map<String, int> _periodPlays() {
    final result = <String, int>{'深夜': 0, '清晨': 0, '白天': 0, '夜晚': 0};
    for (final p in profiles.values) {
      for (final e in p.hourlyPlays.entries) {
        result[_periodOf(e.key)] = result[_periodOf(e.key)]! + e.value;
      }
    }
    return result;
  }

  String _dominantPeriod(Map<String, int> periods) {
    var best = '未知';
    var max = 0;
    for (final e in periods.entries) {
      if (e.value > max) {
        max = e.value;
        best = e.key;
      }
    }
    return max == 0 ? '未知' : best;
  }

  MusicPersona _buildPersona({
    required String dominantPeriod,
    required Map<String, int> periodPlays,
    required double completionRate,
    required double topArtistShare,
    required int streakDays,
  }) {
    final periodCount = periodPlays[dominantPeriod] ?? 0;

    // 主标题 = 时段 × 行为特征
    String title;
    String description;
    if (dominantPeriod == '未知') {
      title = '音乐探索者';
      description = '你的听歌故事才刚拉开序幕，继续保持好奇。';
    } else if (dominantPeriod == '深夜') {
      title = completionRate >= 0.7 ? '深夜沉浸者' : '深夜漫游者';
      description = completionRate >= 0.7
          ? '夜深了，你把世界调小声，一首一首慢慢听完。'
          : '夜里你更愿意随手翻歌，合口味就多留一会儿。';
    } else if (dominantPeriod == '清晨') {
      title = '晨间唤醒者';
      description = '你习惯用音乐给自己按下新一天的启动键。';
    } else if (dominantPeriod == '白天') {
      title = topArtistShare >= 0.3 ? '白日循环控' : '通勤浏览者';
      description = topArtistShare >= 0.3
          ? '白天你总回到同一批熟悉的声音里，像回到老座位。'
          : '白天你让音乐当背景，随手切换也不将就。';
    } else {
      title = topArtistShare >= 0.3 ? '晚间专情派' : '夜晚收藏家';
      description = topArtistShare >= 0.3
          ? '入夜后你听得格外专注，心里那几位轮流上场。'
          : '夜里是你淘歌的黄金时间，好歌一首首收进口袋。';
    }

    // 钩子句：结论先行 + 具体数字
    String headline;
    switch (dominantPeriod) {
      case '深夜':
        headline = '22 点之后，你听完了 $periodCount 首歌';
        break;
      case '清晨':
        headline = '早上 9 点前，你已经听了 $periodCount 首';
        break;
      case '白天':
        headline = '白天这 9 个小时，你听了 $periodCount 首';
        break;
      case '夜晚':
        headline = '18 点以后，你听了 $periodCount 首';
        break;
      default:
        headline = '你已经累计听了 $_totalPlays 次';
    }

    // 性格碎片
    final traits = <String>[];
    traits.add(switch (dominantPeriod) {
      '深夜' => '夜猫子',
      '清晨' => '早起鸟',
      '白天' => '白日梦',
      '夜晚' => '夜游人',
      _ => '爱听的人',
    });
    if (completionRate >= 0.85) {
      traits.add('完播达人');
    } else if (completionRate > 0 && completionRate < 0.5) {
      traits.add('挑剔耳朵');
    }
    if (topArtistShare >= 0.3) {
      traits.add('专一派');
    } else if (topArtistShare > 0 && topArtistShare <= 0.12 && uniqueArtistCount >= 10) {
      traits.add('博爱听众');
    }
    if (_newSongRatio() >= 0.25) traits.add('尝鲜派');
    if (streakDays >= 7) traits.add('坚持冠军');

    return MusicPersona(
      title: title,
      headline: headline,
      description: description,
      traits: traits.take(3).toList(),
    );
  }

  int get _totalPlays => profiles.values.fold(0, (s, p) => s + p.playCount);
  int get uniqueArtistCount {
    final set = <String>{};
    for (final p in profiles.values) {
      if (p.artist != null && p.artist!.isNotEmpty) set.add(p.artist!);
    }
    return set.length;
  }

  double _newSongRatio() {
    if (profiles.isEmpty) return 0.0;
    final cutoff = _dayKey(now.subtract(const Duration(days: 30)));
    var fresh = 0;
    for (final p in profiles.values) {
      final first = _firstDay(p);
      if (first != null && first.compareTo(cutoff) >= 0) fresh++;
    }
    return fresh / profiles.length;
  }

  // ── 口味变迁：近 30 天 vs 前 30 天 ────────────────────────────────────────

  FlavorShift? _buildFlavorShift() {
    final todayPlus = _dayKey(now.add(const Duration(days: 1)));
    final recentFrom = _dayKey(now.subtract(const Duration(days: 30)));
    final prevFrom = _dayKey(now.subtract(const Duration(days: 60)));

    final recentArtist = _topArtistInWindow(recentFrom, todayPlus);
    final prevArtist = _topArtistInWindow(prevFrom, recentFrom);
    final recentGenre = _topGenreInWindow(recentFrom, todayPlus);
    final prevGenre = _topGenreInWindow(prevFrom, recentFrom);

    final artistShift = prevArtist != null &&
        recentArtist != null &&
        prevArtist.$1 != recentArtist.$1;
    final genreShift = prevGenre != null &&
        recentGenre != null &&
        prevGenre.$1 != recentGenre.$1;
    if (!artistShift && !genreShift) return null;

    return FlavorShift(
      fromArtist: artistShift ? prevArtist.$1 : null,
      toArtist: artistShift ? recentArtist.$1 : null,
      fromPlays: artistShift ? prevArtist.$2 : 0,
      toPlays: artistShift ? recentArtist.$2 : 0,
      fromGenre: genreShift ? prevGenre.$1 : null,
      toGenre: genreShift ? recentGenre.$1 : null,
    );
  }

  (String, int)? _topArtistInWindow(String from, String toExclusive) {
    final agg = <String, int>{};
    for (final p in profiles.values) {
      if (p.artist == null || p.artist!.isEmpty) continue;
      final n = _playsInWindow(p, from, toExclusive);
      if (n > 0) agg[p.artist!] = (agg[p.artist!] ?? 0) + n;
    }
    return _maxEntry(agg);
  }

  (String, int)? _topGenreInWindow(String from, String toExclusive) {
    final agg = <String, int>{};
    for (final p in profiles.values) {
      final g = _cleanGenre(p);
      if (g == null) continue;
      final n = _playsInWindow(p, from, toExclusive);
      if (n > 0) {
        agg[g] = (agg[g] ?? 0) + n;
      }
    }
    return _maxEntry(agg);
  }

  int _playsInWindow(SongProfile p, String from, String toExclusive) {
    var sum = 0;
    for (final e in p.dailyPlays.entries) {
      final k = e.key;
      if (k.compareTo(from) >= 0 && k.compareTo(toExclusive) < 0) {
        sum += e.value;
      }
    }
    return sum;
  }

  (String, int)? _maxEntry(Map<String, int> agg) {
    if (agg.isEmpty) return null;
    final top = agg.entries.reduce((a, b) => b.value >= a.value ? b : a);
    return top.value > 0 ? (top.key, top.value) : null;
  }

  // ── 时光机 ────────────────────────────────────────────────────────────────

  List<TimeCapsuleItem> _buildTimeCapsule(List<SongProfile> sortedSongs) {
    final items = <TimeCapsuleItem>[];

    // 初见：全局最早一次有效播放的那首歌
    SongProfile? firstSong;
    String? firstDay;
    for (final p in profiles.values) {
      final day = _firstDay(p);
      if (day == null) continue;
      if (firstDay == null || day.compareTo(firstDay) < 0) {
        firstDay = day;
        firstSong = p;
      }
    }
    if (firstSong != null && firstDay != null) {
      final d = DateTime.parse(firstDay);
      items.add(TimeCapsuleItem(
        kind: '初见',
        title: firstSong.title,
        artist: firstSong.artist,
        detail: '${d.year} 年 ${d.month} 月 ${d.day} 日，你第一次听了它',
      ));
    }

    // 最长陪伴：从第一次听到最后一次听，跨度最大的歌
    SongProfile? loyalSong;
    var longestSpan = 0;
    for (final p in profiles.values) {
      final first = _firstDay(p);
      final last = _lastDay(p);
      if (first == null || last == null) continue;
      final span = DateTime.parse(last).difference(DateTime.parse(first)).inDays + 1;
      if (span > longestSpan) {
        longestSpan = span;
        loyalSong = p;
      }
    }
    if (loyalSong != null && longestSpan >= 2) {
      items.add(TimeCapsuleItem(
        kind: '最长陪伴',
        title: loyalSong.title,
        artist: loyalSong.artist,
        detail: '断断续续陪了你 $longestSpan 天',
      ));
    }

    // 上头月：播放最多的那首歌，它最集中的月份
    if (sortedSongs.isNotEmpty && sortedSongs.first.monthlyPlays.isNotEmpty) {
      final king = sortedSongs.first;
      final monthly = king.monthlyPlays.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final peak = monthly.first;
      final parts = peak.key.split('-');
      if (parts.length == 2) {
        items.add(TimeCapsuleItem(
          kind: '上头月',
          title: king.title,
          artist: king.artist,
          detail: '${parts[0]} 年 ${int.parse(parts[1])} 月，你听了它 ${peak.value} 次',
        ));
      }
    }

    return items;
  }

  String? _firstDay(SongProfile p) {
    if (p.dailyPlays.isEmpty) return null;
    var min = p.dailyPlays.keys.first;
    for (final k in p.dailyPlays.keys) {
      if (k.compareTo(min) < 0) min = k;
    }
    return min;
  }

  String? _lastDay(SongProfile p) {
    if (p.dailyPlays.isEmpty) return null;
    var max = p.dailyPlays.keys.first;
    for (final k in p.dailyPlays.keys) {
      if (k.compareTo(max) > 0) max = k;
    }
    return max;
  }

  // ── 建议 ──────────────────────────────────────────────────────────────────

  List<NewDiscovery> _buildDiscoveries() {
    final cutoff = _dayKey(now.subtract(const Duration(days: 14)));
    final result = <NewDiscovery>[];
    for (final p in profiles.values) {
      final first = _firstDay(p);
      if (first == null || first.compareTo(cutoff) < 0) continue;
      if (p.playCount < 3) continue;
      result.add(NewDiscovery(
        songId: p.songId,
        title: p.title,
        artist: p.artist,
        plays: p.playCount,
      ));
    }
    result.sort((a, b) => b.plays.compareTo(a.plays));
    return result.take(5).toList();
  }

  DroughtInfo? _buildDrought() {
    final from = _dayKey(now.subtract(const Duration(days: 7)));
    final toExclusive = _dayKey(now.add(const Duration(days: 1)));
    // 文案说「最近一周 X% 的播放」，分子分母就都必须用**窗口内**播放数，
    // 不能用历史累计 playCount——否则三个月前循环上千次、上周只听 1 次的老歌
    // 会把集中度拉高，误报歌荒。
    final recent = <(SongProfile, int)>[];
    for (final p in profiles.values) {
      final inWindow = _playsInWindow(p, from, toExclusive);
      if (inWindow > 0) recent.add((p, inWindow));
    }
    if (recent.length <= 5) return null;
    final total = recent.fold(0, (s, e) => s + e.$2);
    if (total == 0) return null;
    // 必须按窗口内播放数降序再取前 5，否则算的是「任意 5 首」的集中度。
    recent.sort((a, b) => b.$2.compareTo(a.$2));
    final top5 = recent.take(5).fold(0, (s, e) => s + e.$2);
    final concentration = top5 / total;
    return concentration >= 0.7
        ? DroughtInfo(concentration: concentration, recentSongs: recent.length)
        : null;
  }

  // ── A 类新增维度 ──────────────────────────────────────────────────────────

  /// 遗忘的宝藏：至少循环过 5 次，但超过 60 天没再听。
  /// 按「播放次数 × 冷却天数」排序，越用力越久违越靠前。
  List<ForgottenTreasure> _buildForgottenTreasures() {
    final result = <ForgottenTreasure>[];
    for (final p in profiles.values) {
      if (p.playCount < 5) continue;
      final last = p.lastPlayed;
      if (last.millisecondsSinceEpoch <= 0) continue;
      final days = now.difference(last).inDays;
      if (days < 60) continue;
      result.add(ForgottenTreasure(
        songId: p.songId,
        title: p.title,
        artist: p.artist,
        plays: p.playCount,
        daysSinceLastPlay: days,
      ));
    }
    result.sort((a, b) =>
        (b.plays * b.daysSinceLastPlay).compareTo(a.plays * a.daysSinceLastPlay));
    return result.take(5).toList();
  }

  /// 那一天：扫描所有 dailyPlays，找单曲单日播放的最高纪录。
  PowerDay? _buildPowerDay() {
    String? day;
    SongProfile? song;
    var max = 0;
    for (final p in profiles.values) {
      for (final e in p.dailyPlays.entries) {
        if (e.value > max) {
          max = e.value;
          day = e.key;
          song = p;
        }
      }
    }
    if (day == null || song == null || max < 3) return null;
    return PowerDay(
      day: day,
      songId: song.songId,
      title: song.title,
      artist: song.artist,
      plays: max,
    );
  }

  /// 口是心非：
  /// - 隐藏宝石：没收藏、却听了 ≥8 次（且没被跳过）
  /// - 装样子：收藏了、跳过率 >40% 且跳过 ≥3 次
  GuiltyPleasure? _buildGuiltyPleasure() {
    NewDiscovery? hiddenGem;
    var bestPlays = 0;
    InsightRankItem? pretender;
    var worstSkipRate = 0.0;

    for (final p in profiles.values) {
      final starred = starredSongIds.contains(p.songId);
      if (!starred && p.playCount >= 8 && p.skipCount == 0 && p.playCount > bestPlays) {
        bestPlays = p.playCount;
        hiddenGem = NewDiscovery(
          songId: p.songId,
          title: p.title,
          artist: p.artist,
          plays: p.playCount,
        );
      }
      if (starred && p.skipCount >= 3 && p.skipRate > 0.4 && p.skipRate > worstSkipRate) {
        worstSkipRate = p.skipRate;
        pretender = InsightRankItem(
          id: p.songId,
          title: p.title,
          subtitle: p.artist,
          count: p.skipCount,
        );
      }
    }
    if (hiddenGem == null && pretender == null) return null;
    return GuiltyPleasure(hiddenGem: hiddenGem, pretender: pretender);
  }

  /// 生物钟：按每天实际播放日期判定周末（6/7），聚合播放量与头部歌手。
  RhythmInsight? _buildRhythm() {
    var weekdayPlays = 0, weekendPlays = 0;
    final weekdayArtists = <String, int>{};
    final weekendArtists = <String, int>{};

    for (final p in profiles.values) {
      for (final e in p.dailyPlays.entries) {
        final weekend = _isWeekendDayKey(e.key);
        if (weekend) {
          weekendPlays += e.value;
          if (p.artist != null && p.artist!.isNotEmpty) {
            weekendArtists[p.artist!] = (weekendArtists[p.artist!] ?? 0) + e.value;
          }
        } else {
          weekdayPlays += e.value;
          if (p.artist != null && p.artist!.isNotEmpty) {
            weekdayArtists[p.artist!] = (weekdayArtists[p.artist!] ?? 0) + e.value;
          }
        }
      }
    }
    if (weekdayPlays == 0 && weekendPlays == 0) return null;
    return RhythmInsight(
      weekdayPlays: weekdayPlays,
      weekendPlays: weekendPlays,
      weekdayArtist: _maxEntry(weekdayArtists)?.$1,
      weekendArtist: _maxEntry(weekendArtists)?.$1,
    );
  }

  bool _isWeekendDayKey(String key) {
    final d = DateTime.tryParse(key);
    return d != null && (d.weekday == 6 || d.weekday == 7);
  }

  /// 专辑情节：按 albumId 聚合，UI 层把 id 映射成名字（拿不到则跳过）。
  List<AlbumStay> _buildTopAlbums() {
    final agg = <String, (int, Set<String>)>{};
    for (final p in profiles.values) {
      if (p.albumId == null || p.albumId!.isEmpty || p.playCount <= 0) continue;
      final entry = agg.putIfAbsent(p.albumId!, () => (0, <String>{}));
      agg[p.albumId!] = (entry.$1 + p.playCount, entry.$2..add(p.songId));
    }
    final result = agg.entries
        .map((e) => AlbumStay(
              albumId: e.key,
              plays: e.value.$1,
              songCount: e.value.$2.length,
            ))
        .toList()
      ..sort((a, b) => b.plays.compareTo(a.plays));
    return result.take(3).toList();
  }

  // ── 工具 ──────────────────────────────────────────────────────────────────

  /// (最长连续天数, 活跃天数)，基于每日播放日期并集。
  (int, int) _streak() {
    final days = <String>{};
    for (final p in profiles.values) {
      days.addAll(p.dailyPlays.keys);
    }
    if (days.isEmpty) return (0, 0);
    final sorted = days.map(DateTime.parse).toList()..sort();
    var longest = 1;
    var current = 1;
    for (var i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return (longest, sorted.length);
  }

  String _periodOf(int hour) {
    if (hour >= 22 || hour < 5) return '深夜';
    if (hour < 9) return '清晨';
    if (hour < 18) return '白天';
    return '夜晚';
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// 归一化流派名，只输出下面词表里的【标准风格名】。
///
/// 道理鱼的 genres 字段很脏：混进了「摇滚拯救受伤小狗」「国内独立乐队合集」
/// 这类歌单名，还有 R / B（R&B 被拆开）这种碎标签。若像过去那样把未知标签
/// 原样返回，口味指纹里就会冒出根本不是风格的奇怪条目。
///
/// 策略：
///  1. 精确命中同义词表 → 标准名；
///  2. 否则做包含匹配，把「XX 摇滚」「朋克时期」这类标签归到它隐含的风格大类
///     （这些歌单名往往确实围绕该风格，归类比丢弃更合理）；
///  3. 完全不含任何风格词的，返回 null，不参与统计。
///
/// 绝不输出原始标签字符串，从根上杜绝脏数据泄漏到报告里。
String? normalizeGenre(String genre) {
  final lower = genre.toLowerCase().trim();
  if (lower.isEmpty || lower.length <= 1) return null;

  const exact = {
    'pop': '流行', 'cpop': '流行', 'c-pop': '流行', '流行': '流行',
    '流行音乐': '流行', '国语流行': '流行', '华语流行': '流行',
    'rock': '摇滚', 'rock & roll': '摇滚', 'rock and roll': '摇滚',
    'rock&roll': '摇滚', '摇滚': '摇滚', '摇滚乐': '摇滚',
    'pop rock': '流行摇滚', 'pop-rock': '流行摇滚',
    'hip-hop': '说唱', 'hip hop': '说唱', 'hiphop': '说唱',
    '说唱': '说唱', '嘻哈': '说唱', 'rap': '说唱',
    'r&b': 'R&B', 'rnb': 'R&B',
    'jazz': '爵士', '爵士': '爵士', '爵士乐': '爵士',
    'classical': '古典', '古典': '古典', '古典音乐': '古典',
    'electronic': '电子', 'electro': '电子', '电子': '电子', '电子音乐': '电子',
    'folk': '民谣', '民谣': '民谣',
    'metal': '金属', '金属': '金属',
    'blues': '蓝调', '蓝调': '蓝调',
    'country': '乡村', '乡村': '乡村',
    'reggae': '雷鬼', '雷鬼': '雷鬼',
    'punk': '朋克', '朋克': '朋克',
    'soul': '灵魂乐', '灵魂乐': '灵魂乐',
    'indie': '独立', '独立': '独立', '独立音乐': '独立',
    'alternative': '另类', '另类': '另类',
    'world': '世界音乐', 'world music': '世界音乐',
    'asie': '世界音乐', 'azië': '世界音乐',
    'musiques du monde': '世界音乐',
    'soundtrack': '原声带', 'ost': '原声带',
    'bandes originales de films': '原声带',
    '原声': '原声带', '原声带': '原声带', '影视原声': '原声带',
    'other': '其他', '其他': '其他',
  };
  final hit = exact[lower];
  if (hit != null) return hit;

  // 更具体的风格优先，避免「流行摇滚」这类同时含多个词的标签归类不稳定。
  const containsRules = <(String, String)>[
    ('朋克', '朋克'), ('punk', '朋克'),
    ('金属', '金属'), ('metal', '金属'),
    ('说唱', '说唱'), ('嘻哈', '说唱'), ('hip', '说唱'), ('rap', '说唱'),
    ('爵士', '爵士'), ('jazz', '爵士'),
    ('古典', '古典'), ('classical', '古典'),
    ('蓝调', '蓝调'), ('blues', '蓝调'),
    ('乡村', '乡村'), ('country', '乡村'),
    ('雷鬼', '雷鬼'), ('reggae', '雷鬼'),
    ('民谣', '民谣'), ('folk', '民谣'),
    ('电子', '电子'), ('electro', '电子'),
    ('独立', '独立'), ('indie', '独立'),
    ('另类', '另类'), ('alternative', '另类'),
    ('r&b', 'R&B'), ('rnb', 'R&B'),
    ('摇滚', '摇滚'), ('rock', '摇滚'), ('grunge', '摇滚'),
    ('儿歌', '儿歌'),
    ('原声', '原声带'), ('soundtrack', '原声带'), ('ost', '原声带'),
    ('世界音乐', '世界音乐'), ('world music', '世界音乐'),
    ('轻音乐', '轻音乐'),
    ('流行', '流行'), ('pop', '流行'),
  ];
  for (final (keyword, name) in containsRules) {
    if (lower.contains(keyword)) return name;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────────
// 探索歌单：生成一张「与你最近口味不同」的歌单。
//
// 与 RecommendationService.getDiscoverMix（同曲风换歌手，方向是"延续"）相反，
// 这里做的是"反向"：拿最近 30 天的画像算出近期头部歌手/风格，主动避开它们。
// 纯函数、种子可注入，便于单测与稳定复现。
// ─────────────────────────────────────────────────────────────────────────────

/// 一首探索歌及它被选中的原因（供 UI 展示，也让算法可解释）。
class ExplorationPick {
  final Song song;
  final String reason;
  const ExplorationPick({required this.song, required this.reason});
}

class ExplorationPlaylistBuilder {
  final Map<String, SongProfile> profiles;
  final List<Song> pool;
  final Map<String, String> genreLookup;
  final Set<String> recentlyPlayed;
  final Set<String> dislikedIds;
  final DateTime now;
  final int seed;
  final int limit;

  /// 温和强度：陌生层占大头，回访层做点缀。
  ExplorationPlaylistBuilder({
    required this.profiles,
    required this.pool,
    required this.genreLookup,
    required this.recentlyPlayed,
    required this.dislikedIds,
    DateTime? now,
    this.seed = 0,
    this.limit = 10,
  }) : now = now ?? DateTime.now();

  List<ExplorationPick> build() {
    final recentFrom =
        _dayKey(now.subtract(const Duration(days: 30)));
    final todayPlus = _dayKey(now.add(const Duration(days: 1)));

    // 1) 近期口味：最近 30 天的头部歌手 / 头部风格（清洗后）。
    final recentArtist = <String, int>{};
    final recentGenre = <String, int>{};
    for (final p in profiles.values) {
      final n = _playsBetween(p, recentFrom, todayPlus);
      if (n <= 0) continue;
      if (p.artist != null && p.artist!.isNotEmpty) {
        recentArtist[p.artist!] = (recentArtist[p.artist!] ?? 0) + n;
      }
      final g = _cleanGenreFor(p);
      if (g != null) recentGenre[g] = (recentGenre[g] ?? 0) + n;
    }
    final topArtists = _topKeys(recentArtist, 5);
    final topGenres = _topKeys(recentGenre, 3);

    // 2) 排除集：最近听过、明确不喜欢、以及歌本身已在曲库里"最近很热"的歌手
    //    不由单曲排除，而是靠上面的 topArtists 反向过滤。
    final excluded = <String>{...recentlyPlayed, ...dislikedIds};

    // 3) 候选分层：从最"陌生"到较温和。
    final unfamiliar = <Song>[];
    const revisitDays = 60;
    final revisitFrom =
        _dayKey(now.subtract(const Duration(days: revisitDays)));
    final revisit = <Song>[];
    final sameGenre = <Song>[];
    final fallback = <Song>[];

    for (final s in pool) {
      if (excluded.contains(s.id)) continue;
      final p = profiles[s.id];
      final songGenre = _cleanGenreForSong(s);
      final inTopArtist = s.artist != null && topArtists.contains(s.artist);
      final inTopGenre = songGenre != null && topGenres.contains(songGenre);
      final everPlayed = p != null && p.playCount > 0;
      final isRevisit = p != null &&
          p.playCount > 0 &&
          p.lastPlayed.isBefore(DateTime.parse(revisitFrom));

      if (!everPlayed && !inTopArtist && !inTopGenre) {
        unfamiliar.add(s); // 没听过 + 歌手/风格都不在近期头部
      } else if (isRevisit) {
        revisit.add(s); // 很久以前听过、近期没碰的老朋友
      } else if (!everPlayed && !inTopArtist && inTopGenre) {
        sameGenre.add(s); // 同风格但换歌手（温和保底）
      } else {
        fallback.add(s);
      }
    }

    // 4) 确定性打散（同一 seed 结果稳定，便于测试与复现）。
    _shuffle(
      unfamiliar: unfamiliar,
      revisit: revisit,
      sameGenre: sameGenre,
      fallback: fallback,
    );

    // 5) 温和配比：陌生 60% → 回访 20% → 同风格 20%，不足按序从后续层补。
    final targetUnfamiliar = (limit * 0.6).round();
    final targetRevisit = (limit * 0.2).round();
    final picked = <ExplorationPick>[];
    final artistCount = <String, int>{};
    final genreCount = <String, int>{};
    const maxPerArtist = 2;
    const maxPerGenre = 4;

    bool tryAdd(Song s, String reason) {
      final artist = s.artist ?? '';
      final g = _cleanGenreForSong(s) ?? '';
      if (artist.isNotEmpty && (artistCount[artist] ?? 0) >= maxPerArtist) {
        return false;
      }
      if (g.isNotEmpty && (genreCount[g] ?? 0) >= maxPerGenre) {
        return false;
      }
      picked.add(ExplorationPick(song: s, reason: reason));
      if (artist.isNotEmpty) artistCount[artist] = (artistCount[artist] ?? 0) + 1;
      if (g.isNotEmpty) genreCount[g] = (genreCount[g] ?? 0) + 1;
      return true;
    }

    void takeFrom(List<Song> src, String reason, int count) {
      for (final s in src) {
        if (picked.length >= limit) break;
        if (count <= 0) break;
        if (tryAdd(s, reason)) count--;
      }
    }

    takeFrom(unfamiliar, '陌生新面孔', targetUnfamiliar);
    takeFrom(revisit, '许久未见的老朋友', targetRevisit);
    takeFrom(sameGenre, '同风格，换个人', limit - picked.length);
    // 兜底：还不够就从所有层剩余里按陌生优先补齐。
    if (picked.length < limit) {
      for (final layer in [unfamiliar, revisit, sameGenre, fallback]) {
        for (final s in layer) {
          if (picked.length >= limit) break;
          if (picked.any((e) => e.song.id == s.id)) continue;
          tryAdd(s, '为你换换口味');
        }
      }
    }
    return picked;
  }

  String? _cleanGenreFor(SongProfile p) {
    var genre = p.genre;
    if (genre == null || genre.isEmpty) genre = genreLookup[p.songId];
    if (genre == null || genre.isEmpty) return null;
    return normalizeGenre(genre);
  }

  String? _cleanGenreForSong(Song s) {
    var genre = s.genre;
    if (genre == null || genre.isEmpty) genre = genreLookup[s.id];
    if (genre == null || genre.isEmpty) return null;
    return normalizeGenre(genre);
  }

  int _playsBetween(SongProfile p, String from, String toExclusive) {
    var n = 0;
    for (final e in p.dailyPlays.entries) {
      if (e.key.compareTo(from) >= 0 && e.key.compareTo(toExclusive) < 0) {
        n += e.value;
      }
    }
    return n;
  }

  List<String> _topKeys(Map<String, int> m, int limit) {
    final sorted = m.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).map((e) => e.key).toList();
  }

  void _shuffle({
    required List<Song> unfamiliar,
    required List<Song> revisit,
    required List<Song> sameGenre,
    required List<Song> fallback,
  }) {
    int cmp(Song a, Song b) {
      final ha = _stableHash(a.id) ^ seed;
      final hb = _stableHash(b.id) ^ seed;
      final c = ha.compareTo(hb);
      return c != 0 ? c : a.id.compareTo(b.id);
    }

    unfamiliar.sort(cmp);
    revisit.sort(cmp);
    sameGenre.sort(cmp);
    fallback.sort(cmp);
  }

  /// 稳定的字符串哈希（Dart 的 String.hashCode 跨运行不稳定，这里自己算）。
  static int _stableHash(String s) {
    var h = 5381;
    for (final c in s.codeUnits) {
      h = ((h << 5) + h + c) & 0x7fffffff;
    }
    return h;
  }

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
