import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'knowledge_recommendation_engine.dart';
import 'recommendation_service.dart';
import 'recommended_history_store.dart';
import 'song_knowledge_cache.dart';

/// 场景 Mix 类型（§4.7）。
enum SceneMix { commute, study, sleep }

/// 首页一次生成的全部推荐数据（§6 数据契约），各模块已全局去重。
class HomeFeed {
  final List<Song> daily;
  final List<Song> commuteMix;
  final List<Song> studyMix;
  final List<Song> sleepMix;
  final List<Song> favorites;
  final List<Song> discover;

  const HomeFeed({
    required this.daily,
    required this.commuteMix,
    required this.studyMix,
    required this.sleepMix,
    required this.favorites,
    required this.discover,
  });

  bool get isEmpty =>
      daily.isEmpty &&
      commuteMix.isEmpty &&
      studyMix.isEmpty &&
      sleepMix.isEmpty &&
      favorites.isEmpty &&
      discover.isEmpty;
}

/// 首页推荐编排服务（§4.3-4.8）。
///
/// 职责：把「用户行为（[RecommendationService]）」与「知识图谱内容
/// （[KnowledgeRecommendationEngine]）」融合成首页各模块数据：
/// - 融合打分 finalScore = α·行为分 + (1-α)·内容分，α=0.7（§4.4）
/// - 熟悉/探索分层：每日推荐按**配额**分熟悉槽 / 探索槽两路召回（熟悉为主、
///   探索补新，见 `docs/每日推荐探索配额与冷却技术方案.md` §3.2），场景 Mix
///   仍以熟悉层为主，探索发现只推未听过的（§4.5）
/// - 跨模块全局去重 + 同歌手≤2 首 / 同专辑≤1 首（§4.6）
/// - 每日推荐 / 探索发现均按日固定（key=日期，§4.8 / §8-10）；每日推荐另有
///   跨天冷却（§3.3）与收藏变化即时失效（§3.4）
/// - 无图谱 / 无行为自动退化（§4.4）
class HomeRecommendationService extends ChangeNotifier {
  HomeRecommendationService({
    required RecommendationService behavior,
    KnowledgeRecommendationEngine? engine,
    SongKnowledgeCache? knowledgeCache,
    RecommendedHistoryStore? history,
    Duration prefDebounce = const Duration(milliseconds: 800),
  })  : _behavior = behavior,
        _engine = engine ?? KnowledgeRecommendationEngine(),
        _knowledgeCache = knowledgeCache,
        _history = history,
        _prefDebounce = prefDebounce {
    _lastStarredSignature = _starredSignature();
    // 行为数据变化（播放/评分/收藏）后防抖重建用户标签偏好向量（§4.8 时序 2）。
    _behavior.addListener(_onBehaviorChanged);
  }

  /// 融合权重 α：行为:内容 = 7:3（已确认，调向 0.5 属二期 §9）。
  static const double alpha = 0.7;

  static const int dailyLimit = 30;
  static const int mixLimit = 20;
  static const int discoverLimit = 20;

  /// 每日推荐里「探索槽」的占比：limit=30 时熟悉 20 + 探索 10（§3.2）。
  static const double dailyDiscoverRatio = 1 / 3;

  /// 探索层一跳邻居的最小相似度（§8-2 已确认 Jaccard>0.25）。
  static const double discoverMinSimilarity = 0.25;

  /// 无标签歌的兜底：直接把 genre 当伪标签参与内容分（§4.3）。
  static const bool genreFallback = true;

  final RecommendationService _behavior;
  final KnowledgeRecommendationEngine _engine;
  final SongKnowledgeCache? _knowledgeCache;
  final RecommendedHistoryStore? _history;
  final Duration _prefDebounce;

  DateTime? _syncedCacheTime;

  /// 是否已经同步过一次知识库缓存（与 [_syncedCacheTime] 配对使用）。
  ///
  /// 只比较时间戳是不够的：缓存文件存在但 `meta` 里没有时间戳时
  /// （`getLastUpdateTime()` 返回 null），守卫
  /// `updated != null && updated == _syncedCacheTime` 会永远放行，于是
  /// [refreshKnowledgeFromCache] 每次调用都 `rebuildKnowledge()` +
  /// `notifyListeners()`。而它是由 `build()` 里的 `generateFeed()` 调用的，
  /// 于是形成「通知 → 重建 → 再生成 feed」的无限循环：实测 UI 线程 82%、
  /// 帧率 ~8fps、[_feedRevision] 每秒 +11。
  bool _knowledgeSynced = false;

  Timer? _prefDebounceTimer;
  String _lastStarredSignature = '';

  /// 防抖窗口内是否发生过收藏变化（累积，见 [_onBehaviorChanged]）。
  bool _starredDirty = false;

  /// 知识库版本号：重建后 +1，缓存仅在同一版本内命中
  /// （避免一次性脏标记在多模块间串扰，见 P0 单测暴露的问题）。
  int _knowledgeVersion = 0;

  /// feed 修订号：服务内部缓存失效（知识库重建 / 收藏变化 / 清缓存）时 +1。
  /// 首页据此判断「曲库没变但推荐该重建」（§3.4）——否则曲库 id 串不变时
  /// 即使清了缓存，首页也感知不到。
  int _feedRevision = 0;

  Map<String, _CacheEntry> _dailyCache = {};
  Map<String, _CacheEntry> _discoverCache = {};

  KnowledgeRecommendationEngine get engine => _engine;

  bool get hasKnowledge => _engine.hasIndex;
  bool get hasBehavior =>
      _behavior.profiles.isNotEmpty || _behavior.starredSongIds.isNotEmpty;

  /// 见 [_feedRevision]。
  int get feedRevision => _feedRevision;

  /// 每日推荐「探索槽」数量（按比例缩放，§3.2）。
  static int dailyDiscoverQuota(int limit) =>
      (limit * dailyDiscoverRatio).round();

  // ──────────────────────────────────────────────────────────────────────────
  // 数据入口（§4.8 时序）
  // ──────────────────────────────────────────────────────────────────────────

  /// 重建知识图谱索引。知识库导入 / 生成完成后调用。
  void rebuildKnowledge(Map<String, String> tagsBySongId) {
    _engine.rebuild(tagsBySongId);
    _knowledgeVersion++;
    _feedRevision++;
    notifyListeners();
  }

  /// 知识库缓存自动同步：缓存未初始化或更新时间未变化则跳过；
  /// `generateFeed` 每次调用前执行，知识库生成/导入后无需额外挂钩。
  void refreshKnowledgeFromCache() {
    final cache = _knowledgeCache;
    if (cache == null || !cache.isInitialized) return;
    final updated = cache.getLastUpdateTime();
    // ⚠️ 守卫必须覆盖「时间戳为 null」的缓存。只判断 `updated != null` 时，
    // 没有 meta 时间戳的缓存会让这里永远放行，与 `build()` 里的
    // generateFeed 构成无限重建循环（见 [_knowledgeSynced]）。
    if (_knowledgeSynced && updated == _syncedCacheTime) return;
    // 先记状态再重建：rebuildKnowledge 会 notifyListeners，避免重入。
    _knowledgeSynced = true;
    _syncedCacheTime = updated;
    rebuildKnowledge(cache.getAllTags());
  }

  /// 收藏集合签名（排序拼串），用于识别「收藏是否变化」。
  String _starredSignature() {
    final ids = _behavior.starredSongIds.toList()..sort();
    return ids.join(',');
  }

  void _onBehaviorChanged() {
    // 收藏是显式强意图 → 立即失效当日推荐（§3.4）；纯播放 / 跳过只重建偏好
    // 向量（影响次日与探索发现），不重排当日列表，避免听歌过程中列表乱跳。
    // 用累积标记而非一次性局部变量：防抖窗口内先收藏、后播放时不会丢掉收藏。
    final signature = _starredSignature();
    if (signature != _lastStarredSignature) {
      _lastStarredSignature = signature;
      _starredDirty = true;
    }
    _prefDebounceTimer?.cancel();
    _prefDebounceTimer = Timer(_prefDebounce, () {
      refreshUserPref();
      if (_starredDirty) {
        _starredDirty = false;
        clearCaches();
      }
    });
  }

  /// 从行为数据重建用户标签偏好向量。播放 / 评分 / 收藏等行为变化后调用。
  void refreshUserPref() {
    _engine.clearUserPref();
    for (final profile in _behavior.profiles.values) {
      final w = _behaviorWeight(profile);
      if (w != 0) _engine.addUserPref(profile.songId, w);
    }
    // 收藏但未播放的歌也贡献偏好（+2.0，与 _behaviorWeight 一致）。
    for (final id in _behavior.starredSongIds) {
      _engine.addUserPref(id, 2.0);
    }
    _engine.normalizeUserPref();
    notifyListeners();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 打分
  // ──────────────────────────────────────────────────────────────────────────

  double _behaviorScore(Song song) => _behavior.calculateSongScore(song);

  double _contentScore(Song song) {
    final tags = _engine.tagsOf(song.id);
    if (tags != null && tags.isNotEmpty) return _engine.contentScore(tags);
    if (genreFallback) {
      final genre = song.genre;
      if (genre != null && genre.isNotEmpty) {
        return _engine.contentScore({genre});
      }
    }
    return 0;
  }

  double _effectiveAlpha() {
    if (!hasKnowledge) return 1.0; // 无图谱 → 纯行为（§4.4）
    if (!hasBehavior) return 0.0; // 无行为 → 纯内容
    return alpha;
  }

  double _fusionScore(Song song) {
    final a = _effectiveAlpha();
    return a * _behaviorScore(song) + (1 - a) * _contentScore(song);
  }

  bool _isHeard(Song song) => _behavior.profiles.containsKey(song.id);

  /// 熟悉层候选池：只取听过的歌；听过的不足 12 首时用全库补足（冷启动）。
  List<Song> _familiarPool(List<Song> allSongs) {
    final heard = allSongs.where(_isHeard).toList();
    if (heard.length >= 12) return heard;
    return [...heard, ...allSongs.where((s) => !_isHeard(s))];
  }

  /// 按 [score]（默认融合分）降序选歌，应用「同歌手≤2 / 同专辑≤1」上限与
  /// 排除集合，并把选中的歌写入 [exclude]（跨模块全局去重，§4.6）。
  /// 未传入 [exclude] 时使用内部可变集合，不对外暴露。
  ///
  /// [artistCounts] / [albumCounts] 传入时跨多次调用**共享计数**，用于把
  /// 「同歌手≤2 / 同专辑≤1」的上限约束到多路召回的并集上（§3.5）；不传则
  /// 各自新建，单次调用行为不变。
  List<Song> _selectWithDedup(
    List<Song> candidates, {
    required int limit,
    Set<String>? exclude,
    double Function(Song)? score,
    Map<String, int>? artistCounts,
    Map<String, int>? albumCounts,
  }) {
    if (limit <= 0) return const [];
    final ex = exclude ?? <String>{};
    final sortScore = score ?? _fusionScore;
    final artists = artistCounts ?? <String, int>{};
    final albums = albumCounts ?? <String, int>{};
    final sorted = [...candidates]
      ..sort((a, b) => sortScore(b).compareTo(sortScore(a)));
    final result = <Song>[];
    for (final song in sorted) {
      if (result.length >= limit) break;
      if (ex.contains(song.id)) continue;
      final artist = song.artist;
      if (artist != null && (artists[artist] ?? 0) >= 2) continue;
      final albumId = song.albumId;
      if (albumId != null && (albums[albumId] ?? 0) >= 1) continue;
      result.add(song);
      ex.add(song.id);
      if (artist != null) artists[artist] = (artists[artist] ?? 0) + 1;
      if (albumId != null) albums[albumId] = (albums[albumId] ?? 0) + 1;
    }
    return result;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 首页各模块（§6 数据契约）
  // ──────────────────────────────────────────────────────────────────────────

  /// 每日推荐：**配额化两路召回** + 跨天冷却，当日固定（key=日期）。
  ///
  /// - 熟悉路：听过的歌按融合分取 `limit - 探索配额`
  /// - 探索路：未听过的歌按融合分取 `探索配额`（limit=30 时 20 + 10，§3.2）
  /// - 补足路：两路都不足时按融合分从全库补，保证条数不缩水（§8-7 修复成果）
  /// - 冷却：窗口内已推荐过的不再进池（安全阀：过滤后不足 limit 则忽略，§3.3）
  ///
  /// 设计背景见 `docs/每日推荐探索配额与冷却技术方案.md`。
  List<Song> dailyRecommendation({
    required List<Song> allSongs,
    int limit = dailyLimit,
    DateTime? now,
    Set<String>? exclude,
  }) {
    final day = now ?? DateTime.now();
    final dayKey = _dayKey(day);
    final cached = _dailyCache[dayKey];
    if (cached != null && cached.version == _knowledgeVersion) {
      return cached.songs;
    }

    final list = _composeDaily(
      allSongs: allSongs,
      limit: limit,
      day: day,
      exclude: exclude ?? <String>{},
    );
    _dailyCache[dayKey] = _CacheEntry(_knowledgeVersion, list);
    _history?.markRecommended(list.map((s) => s.id), now: day);
    return list;
  }

  /// 每日推荐的两路召回 + 补足（§3.1）；三路共享歌手/专辑计数，去重上限
  /// 在整批 30 首范围内生效（§3.5）。
  List<Song> _composeDaily({
    required List<Song> allSongs,
    required int limit,
    required DateTime day,
    required Set<String> exclude,
  }) {
    final pool = _applyCooldown(allSongs, day: day, limit: limit);
    final artistCounts = <String, int>{};
    final albumCounts = <String, int>{};
    final discoverQuota = dailyDiscoverQuota(limit);

    final familiar = _selectWithDedup(
      pool.where(_isHeard).toList(),
      limit: limit - discoverQuota,
      exclude: exclude,
      artistCounts: artistCounts,
      albumCounts: albumCounts,
    );
    final discover = _selectWithDedup(
      pool.where((s) => !_isHeard(s)).toList(),
      limit: discoverQuota,
      exclude: exclude,
      artistCounts: artistCounts,
      albumCounts: albumCounts,
    );

    final result = [...familiar, ...discover];
    if (result.length < limit) {
      // 冷启动 / 小库 / 冷却过滤过狠 → 按融合分从全库补足（可回捞冷却中的歌）。
      result.addAll(_selectWithDedup(
        allSongs,
        limit: limit - result.length,
        exclude: exclude,
        artistCounts: artistCounts,
        albumCounts: albumCounts,
      ));
    }
    return result;
  }

  /// 冷却过滤：窗口内推荐过的歌不进候选池。
  ///
  /// 安全阀：过滤后候选不足以凑满 [limit] 时**忽略冷却**（小库 / 新库 / 单测
  /// 小数据集不会推空，退化为原行为）。
  List<Song> _applyCooldown(
    List<Song> allSongs, {
    required DateTime day,
    required int limit,
  }) {
    final history = _history;
    if (history == null) return allSongs;
    final cooling = history.coolingDownIds(now: day);
    if (cooling.isEmpty) return allSongs;
    final filtered = allSongs.where((s) => !cooling.contains(s.id)).toList();
    return filtered.length >= limit ? filtered : allSongs;
  }

  static const Map<SceneMix, List<String>> _sceneKeywords = {
    SceneMix.commute: ['高能量', '快节奏', '运动', '活力', '兴奋', '劲爆', '燃'],
    SceneMix.study: ['纯音乐', '轻音乐', '舒缓', '安静', '平静', '治愈', '放松'],
    SceneMix.sleep: ['治愈', '舒缓', '慢', '安静', '催眠', '放松', '深夜', '低能量'],
  };

  bool _matchesScene(Song song, List<String> keywords) {
    final tags = _engine.tagsOf(song.id);
    if (tags == null || tags.isEmpty) return false;
    return tags.any((tag) => keywords.any((k) => tag.contains(k)));
  }

  /// 场景 Mix：熟悉层 + 标签过滤（§4.7），不足时全库补足。
  List<Song> sceneMix(
    SceneMix mix, {
    required List<Song> allSongs,
    int limit = mixLimit,
    Set<String>? exclude,
  }) {
    final keywords = _sceneKeywords[mix]!;
    final filtered = _familiarPool(allSongs)
        .where((s) => _matchesScene(s, keywords))
        .toList();
    if (filtered.length < limit) {
      final extra = allSongs
          .where((s) => !filtered.contains(s) && _matchesScene(s, keywords))
          .toList();
      filtered.addAll(extra);
    }
    return _selectWithDedup(filtered, limit: limit, exclude: exclude);
  }

  /// 你的最爱 Mix：熟悉层按「最爱分」（行为权重，收藏/评分/完成度/播放次数）
  /// 降序——不含最近播放惩罚，语义为长期最爱而非近期播放。
  List<Song> favoritesMix({
    required List<Song> allSongs,
    int limit = mixLimit,
    Set<String>? exclude,
  }) {
    final pool = _familiarPool(allSongs).toList()
      ..sort((a, b) => _favoriteScore(b).compareTo(_favoriteScore(a)));
    return _selectWithDedup(
      pool,
      limit: limit,
      exclude: exclude,
      score: _favoriteScore,
    );
  }

  /// 最爱分 = 行为综合权重（[SongProfile] 无则 0）。
  double _favoriteScore(Song song) {
    final profile = _behavior.profiles[song.id];
    if (profile == null) return 0;
    return _behaviorWeight(profile);
  }

  /// 探索发现：未听过的歌，取行为分最高的听过歌为种子做一跳邻居（§4.5），
  /// 不足时用偏好标签代表歌兜底；按日固定（key=日期，§8-10）。
  List<Song> discoverSongs({
    required List<Song> allSongs,
    int limit = discoverLimit,
    DateTime? now,
    Set<String>? exclude,
  }) {
    final day = _dayKey(now ?? DateTime.now());
    final cached = _discoverCache[day];
    if (cached != null && cached.version == _knowledgeVersion) {
      return cached.songs;
    }

    final byId = {for (final s in allSongs) s.id: s};
    final ex = exclude ?? <String>{};
    // 探索层只推未听过的歌：邻居/代表歌检索时排除全部已听歌曲。
    final similarExclude = <String>{...ex, ..._behavior.profiles.keys};
    final picked = <String>{};
    final result = <Song>[];

    void addCandidate(String id) {
      if (picked.contains(id) || ex.contains(id)) return;
      final song = byId[id];
      if (song == null || _isHeard(song)) return;
      // 探索层同样受同歌手≤2/同专辑≤1 约束（§4.6）。
      if (song.artist != null &&
          _countIn(result, (s) => s.artist == song.artist) >= 2) {
        return;
      }
      if (song.albumId != null &&
          _countIn(result, (s) => s.albumId == song.albumId) >= 1) {
        return;
      }
      picked.add(id);
      result.add(song);
    }

    final heard = allSongs.where(_isHeard).toList()
      ..sort((a, b) => _behaviorScore(b).compareTo(_behaviorScore(a)));

    for (final seed in heard.take(10)) {
      if (result.length >= limit) break;
      for (final id in _engine.findSimilar(
        seed.id,
        limit: 8,
        minSimilarity: discoverMinSimilarity,
        exclude: similarExclude,
      )) {
        if (result.length >= limit) break;
        addCandidate(id);
      }
    }

    // 无行为（无种子）或种子邻居不足时：偏好标签代表歌 / 内容分兜底。
    if (result.length < limit) {
      final representative = _engine.representativeSongs(
        topTags: 5,
        perTag: 4,
        exclude: similarExclude,
      );
      for (final id in representative) {
        if (result.length >= limit) break;
        addCandidate(id);
      }
    }
    if (result.length < limit) {
      final unheardByContent = allSongs.where((s) {
        return !_isHeard(s) && !picked.contains(s.id) && !ex.contains(s.id);
      }).toList()
        ..sort((a, b) => _contentScore(b).compareTo(_contentScore(a)));
      for (final song in unheardByContent) {
        if (result.length >= limit) break;
        addCandidate(song.id);
      }
    }

    _discoverCache[day] = _CacheEntry(_knowledgeVersion, result);
    return result;
  }

  /// 一次生成首页全部模块（§6），模块间全局去重。
  HomeFeed generateFeed({
    required List<Song> allSongs,
    DateTime? now,
  }) {
    refreshKnowledgeFromCache();
    final used = <String>{};
    final daily =
        dailyRecommendation(allSongs: allSongs, now: now, exclude: used);
    final commute =
        sceneMix(SceneMix.commute, allSongs: allSongs, exclude: used);
    final study = sceneMix(SceneMix.study, allSongs: allSongs, exclude: used);
    final sleep = sceneMix(SceneMix.sleep, allSongs: allSongs, exclude: used);
    final favorites = favoritesMix(allSongs: allSongs, exclude: used);
    final discover = discoverSongs(allSongs: allSongs, now: now, exclude: used);
    return HomeFeed(
      daily: daily,
      commuteMix: commute,
      studyMix: study,
      sleepMix: sleep,
      favorites: favorites,
      discover: discover,
    );
  }

  /// 清空每日/每周缓存（收藏变化、知识库重建或手动刷新时调用）。
  void clearCaches() {
    _dailyCache = {};
    _discoverCache = {};
    _feedRevision++;
    notifyListeners();
  }

  @override
  void dispose() {
    _prefDebounceTimer?.cancel();
    _behavior.removeListener(_onBehaviorChanged);
    _engine.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 工具
  // ──────────────────────────────────────────────────────────────────────────

  /// 行为综合权重（§4.2 w(s)）：收藏 +2.0 / 评分 / 完成度 / 播放次数，跳过衰减。
  double _behaviorWeight(SongProfile profile) {
    var w = 0.0;
    if (_behavior.starredSongIds.contains(profile.songId)) w += 2.0;
    if (profile.userRating != null) w += profile.userRating! / 5.0;
    w += profile.completionRate;
    w += math.min(profile.playCount / 10.0, 1.0);
    if (profile.isDisliked) w -= 0.8;
    return w.clamp(0.0, 4.0);
  }

  int _countIn(List<Song> songs, bool Function(Song) test) =>
      songs.where(test).length;

  static String _dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// 缓存条目：记录生成时的知识库版本，仅在版本一致时命中。
class _CacheEntry {
  const _CacheEntry(this.version, this.songs);

  final int version;
  final List<Song> songs;
}
