import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

/// 屏蔽对象的类型。
enum BlockKind { artist, album, playlist }

/// 屏蔽强度。
///
/// - [hidden]：**彻底屏蔽** —— 列表、搜索、漫游、推荐里都不出现。
/// - [muted]：**仅从漫游排除** —— 仍然可见可播，只是不会被随机/推荐抽到。
///
/// 不变式：[hidden] 蕴含 [muted]（都不想看了，自然也不该被随机抽到）。
/// 所以判定「能否被抽到」用 [BlocklistService.isSongExcluded]，
/// 判定「是否可见」用 [BlocklistService.isSongHidden]，前者恒包含后者。
enum BlockMode { hidden, muted }

@immutable
class BlockEntry {
  const BlockEntry({
    required this.kind,
    required this.targetId,
    required this.name,
    required this.mode,
    required this.addedAt,
    this.memberCount,
    this.expandedAt,
  });

  final BlockKind kind;
  final String targetId;

  /// 冗余展示名：管理页在拿不到服务端数据时也能显示"屏蔽了什么"。
  final String name;
  final BlockMode mode;
  final int addedAt;

  /// 歌单专用：展开成员时的 `songCount`（变化检测基线）。
  final int? memberCount;

  /// 歌单专用：最近一次展开成员的时间。
  final int? expandedAt;

  BlockEntry copyWith({
    String? name,
    BlockMode? mode,
    int? memberCount,
    int? expandedAt,
  }) {
    return BlockEntry(
      kind: kind,
      targetId: targetId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      addedAt: addedAt,
      memberCount: memberCount ?? this.memberCount,
      expandedAt: expandedAt ?? this.expandedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'kind': kind.name,
        'id': targetId,
        'name': name,
        'mode': mode.name,
        'addedAt': addedAt,
        if (memberCount != null) 'memberCount': memberCount,
        if (expandedAt != null) 'expandedAt': expandedAt,
      };

  static BlockEntry? fromJson(Map<String, dynamic> json) {
    final kind = BlockKind.values.asNameMap()[json['kind']];
    final mode = BlockMode.values.asNameMap()[json['mode']];
    final id = json['id']?.toString() ?? '';
    if (kind == null || mode == null || id.isEmpty) return null;
    return BlockEntry(
      kind: kind,
      targetId: id,
      name: json['name']?.toString() ?? '',
      mode: mode,
      addedAt: (json['addedAt'] as num?)?.toInt() ?? 0,
      memberCount: (json['memberCount'] as num?)?.toInt(),
      expandedAt: (json['expandedAt'] as num?)?.toInt(),
    );
  }
}

/// 屏蔽名单 —— **纯本地**，不发任何网络请求。
///
/// 设计要点（见 `docs/屏蔽与漫游排除技术方案.md`）：
/// - 名单按 `(服务器, 账号)` 隔离，用现成的 `coverCacheServerId`
///   （= md5(baseUrl|username)）作作用域，切服/切账号互不污染。
/// - 过滤只发生在**读取层**，库里/服务端的数据一律不动 —— 解除即恢复，
///   也不需要重新同步。
/// - 歌单需要"成员歌曲 id 集合"才能把歌从随机里排掉（漫游抽的是歌，不是歌单）。
///   成员优先用调用方已有的数据（用户打开过歌单就有），本服务不主动联网。
class BlocklistService extends ChangeNotifier {
  BlocklistService._();

  static final BlocklistService instance = BlocklistService._();

  static const String _keyPrefix = 'blocklist_v1';
  static const int _memberStaleMs = 7 * 24 * 60 * 60 * 1000;

  String _scope = '';
  bool _loaded = false;

  /// key = `<kind>:<id>`
  final Map<String, BlockEntry> _entries = {};

  /// playlistId -> 成员歌曲 id
  final Map<String, Set<String>> _playlistSongs = {};

  // ── 派生的匹配集合（任何变更后重建，避免逐条扫描 entries）─────────────
  final Set<String> _hiddenArtistIds = {};
  final Set<String> _hiddenArtistNames = {};
  final Set<String> _excludedArtistIds = {};
  final Set<String> _excludedArtistNames = {};
  final Set<String> _hiddenAlbumIds = {};
  final Set<String> _excludedAlbumIds = {};
  final Set<String> _hiddenPlaylistIds = {};
  final Set<String> _excludedSongIds = {};

  /// 每次名单或成员集合变化都 +1，供外部缓存失效。
  int _revision = 0;
  int get revision => _revision;

  bool get isEmpty => _entries.isEmpty;
  bool get isLoaded => _loaded;

  /// 已屏蔽条目（管理页用），按加入时间倒序。
  List<BlockEntry> get entries {
    final list = _entries.values.toList()
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
    return list;
  }

  List<BlockEntry> entriesOf(BlockKind kind) =>
      entries.where((e) => e.kind == kind).toList();

  BlockEntry? entryFor(BlockKind kind, String id) =>
      _entries['${kind.name}:$id'];

  /// 被排除歌单的成员歌曲总数（管理页展示"影响多少首"用）。
  int get excludedSongIdCount => _excludedSongIds.length;

  // ── 作用域 ────────────────────────────────────────────────────────────

  /// 绑定 (服务器, 账号) 作用域并加载对应名单。
  ///
  /// 幂等：同一作用域重复调用直接返回。切服/换账号时传新值即可。
  Future<void> attachScope(String scope) async {
    if (scope == _scope && _loaded) return;
    _scope = scope;
    _entries.clear();
    _playlistSongs.clear();
    _rebuildIndexes();
    _loaded = false;
    if (scope.isEmpty) {
      _loaded = true;
      notifyListeners();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('${_keyPrefix}_$scope');
      if (raw != null && raw.isNotEmpty) {
        final decoded = json.decode(raw) as Map<String, dynamic>;
        final list = decoded['entries'];
        if (list is List) {
          for (final item in list) {
            if (item is! Map) continue;
            final entry = BlockEntry.fromJson(Map<String, dynamic>.from(item));
            if (entry != null) {
              _entries['${entry.kind.name}:${entry.targetId}'] = entry;
            }
          }
        }
        final members = decoded['playlistSongs'];
        if (members is Map) {
          members.forEach((key, value) {
            if (value is List) {
              _playlistSongs[key.toString()] =
                  value.map((e) => e.toString()).toSet();
            }
          });
        }
      }
    } catch (e) {
      debugPrint('[Blocklist] load failed: $e');
    }
    _loaded = true;
    _rebuildIndexes();
    notifyListeners();
  }

  Future<void> _persist() async {
    // 先抓作用域：await 期间可能已经切服/换账号，用 `_scope` 实时值会把
    // A 账号的规则写到 B 账号名下。
    final scope = _scope;
    if (scope.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_keyPrefix}_$scope',
        json.encode({
          'entries': _entries.values.map((e) => e.toJson()).toList(),
          'playlistSongs': _playlistSongs.map(
            (key, value) => MapEntry(key, value.toList()),
          ),
        }),
      );
    } catch (e) {
      debugPrint('[Blocklist] persist failed: $e');
    }
  }

  // ── 判定 ──────────────────────────────────────────────────────────────

  /// 该艺人是否「彻底屏蔽」（列表里不该出现）。
  bool isArtistHidden(String? id, {String? name}) {
    if (_entries.isEmpty) return false;
    if (id != null && id.isNotEmpty && _hiddenArtistIds.contains(id)) {
      return true;
    }
    return _nameMatches(_hiddenArtistNames, name);
  }

  /// 该艺人是否「不参与随机/推荐」（屏蔽 ∪ 仅排除）。
  bool isArtistExcluded(String? id, {String? name}) {
    if (_entries.isEmpty) return false;
    if (id != null && id.isNotEmpty && _excludedArtistIds.contains(id)) {
      return true;
    }
    return _nameMatches(_excludedArtistNames, name);
  }

  bool isAlbumHidden(String? id) {
    if (_entries.isEmpty) return false;
    return id != null && id.isNotEmpty && _hiddenAlbumIds.contains(id);
  }

  bool isAlbumExcluded(String? id) {
    if (_entries.isEmpty) return false;
    return id != null && id.isNotEmpty && _excludedAlbumIds.contains(id);
  }

  bool isPlaylistHidden(String? id) {
    if (_entries.isEmpty) return false;
    return id != null && id.isNotEmpty && _hiddenPlaylistIds.contains(id);
  }

  /// 歌曲是否可以出现在「列表 / 搜索」里（仅 `hidden` 生效）。
  ///
  /// 注意：被屏蔽**歌单**里的歌不在此列 —— 歌单被隐藏只影响那个歌单条目，
  /// 它的歌仍然属于各自的艺人/专辑，照常可浏览（否则会在别处凭空少歌）。
  bool isSongHidden(Song song) {
    if (_entries.isEmpty) return false;
    if (isAlbumHidden(song.albumId)) return true;
    if (isArtistHidden(song.artistId, name: song.artist)) return true;
    final parts = song.artistParticipants;
    if (parts != null) {
      for (final p in parts) {
        if (isArtistHidden(p.id, name: p.name)) return true;
      }
    }
    return false;
  }

  /// 歌曲是否可以参与「随机 / 漫游 / 推荐 / AutoDJ」（`hidden` ∪ `muted` 都排除）。
  bool isSongExcluded(Song song) {
    if (_entries.isEmpty) return false;
    if (_excludedSongIds.contains(song.id)) return true;
    if (isAlbumExcluded(song.albumId)) return true;
    if (isArtistExcluded(song.artistId, name: song.artist)) return true;
    final parts = song.artistParticipants;
    if (parts != null) {
      for (final p in parts) {
        if (isArtistExcluded(p.id, name: p.name)) return true;
      }
    }
    return false;
  }

  /// 该歌单是否需要（重新）展开成员。
  ///
  /// 三个信号任一成立即需要：
  /// 1. 从没展开过（成员集合为空）；
  /// 2. 服务端 `songCount` 与展开时记的不一致（本机/别处增删过）；
  /// 3. 兜底：距上次展开超过 7 天（防止服务端不更新 songCount）。
  bool playlistNeedsMembers(Playlist playlist) {
    final entry = entryFor(BlockKind.playlist, playlist.id);
    if (entry == null) return false;
    // 从没展开过（或名单丢了）→ 必须拉。注意不能用 `members.isEmpty` 判：
    // 空歌单的成员集合本来就是空，否则每次 loadPlaylists 都要白拉一次。
    if (entry.expandedAt == null) return true;
    if (!_playlistSongs.containsKey(playlist.id)) return true;
    final expected = playlist.songCount;
    if (expected != null && entry.memberCount != expected) return true;
    return DateTime.now().millisecondsSinceEpoch - entry.expandedAt! >
        _memberStaleMs;
  }

  Set<String>? membersOf(String playlistId) => _playlistSongs[playlistId];

  // ── 变更 ──────────────────────────────────────────────────────────────

  Future<void> blockArtist(
    String id,
    String name, {
    required BlockMode mode,
  }) =>
      _upsert(
        BlockEntry(
          kind: BlockKind.artist,
          targetId: id,
          name: name,
          mode: mode,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<void> blockAlbum(
    String id,
    String name, {
    required BlockMode mode,
  }) =>
      _upsert(
        BlockEntry(
          kind: BlockKind.album,
          targetId: id,
          name: name,
          mode: mode,
          addedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  /// 屏蔽歌单。[members] 是当前能拿到的成员歌曲 id（没有就传 null，
  /// 之后由 `LibraryProvider` 在列表刷新时补一次展开）。
  Future<void> blockPlaylist(
    String id,
    String name, {
    required BlockMode mode,
    Iterable<String>? members,
    int? songCount,
  }) async {
    await _upsert(
      BlockEntry(
        kind: BlockKind.playlist,
        targetId: id,
        name: name,
        mode: mode,
        addedAt: DateTime.now().millisecondsSinceEpoch,
        memberCount: members == null ? null : songCount,
        expandedAt:
            members == null ? null : DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (members != null) {
      _playlistSongs[id] = members.toSet();
      _rebuildIndexes();
      notifyListeners();
    }
  }

  /// 切换强度（管理页用）。
  Future<void> setMode(BlockKind kind, String targetId, BlockMode mode) async {
    final key = '${kind.name}:$targetId';
    final entry = _entries[key];
    if (entry == null || entry.mode == mode) return;
    _entries[key] = entry.copyWith(mode: mode);
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  Future<void> unblock(BlockKind kind, String targetId) async {
    final key = '${kind.name}:$targetId';
    if (_entries.remove(key) == null) return;
    _playlistSongs.remove(targetId);
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  Future<void> _upsert(BlockEntry entry) async {
    _entries['${entry.kind.name}:${entry.targetId}'] = entry;
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  // ── 歌单成员保鲜（由调用方驱动，本服务不联网）─────────────────────────

  /// 用一份完整成员表覆盖（打开歌单详情 / 主动展开时调用）。
  Future<void> replacePlaylistMembers(
    String playlistId,
    Iterable<String> songIds, {
    int? songCount,
  }) async {
    final entry = entryFor(BlockKind.playlist, playlistId);
    if (entry == null) return;
    _playlistSongs[playlistId] = songIds.toSet();
    _entries['playlist:$playlistId'] = entry.copyWith(
      memberCount: songCount ?? songIds.length,
      expandedAt: DateTime.now().millisecondsSinceEpoch,
    );
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  /// 本机往被排除歌单里加歌：精确追加，**不需要重新拉成员**。
  Future<void> noteSongsAdded(
      String playlistId, Iterable<String> songIds) async {
    final entry = entryFor(BlockKind.playlist, playlistId);
    if (entry == null) return;
    final members = _playlistSongs.putIfAbsent(playlistId, () => <String>{});
    members.addAll(songIds);
    // 只有"已展开过"才维护基线；从没展开过时保持 null，让
    // `playlistNeedsMembers` 继续要求一次真正的展开（此时集合只是部分，
    // 编一个 memberCount 会让它误以为已是最新）。
    if (entry.memberCount != null) {
      _entries['playlist:$playlistId'] = entry.copyWith(
        memberCount: entry.memberCount! + songIds.length,
      );
    }
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  /// 本机从被排除歌单里删歌：精确移除。
  Future<void> noteSongsRemoved(
    String playlistId,
    Iterable<String> songIds,
  ) async {
    final entry = entryFor(BlockKind.playlist, playlistId);
    if (entry == null) return;
    final members = _playlistSongs[playlistId];
    if (members == null) return;
    members.removeAll(songIds);
    if (entry.memberCount != null) {
      _entries['playlist:$playlistId'] = entry.copyWith(
        memberCount: (entry.memberCount! - songIds.length).clamp(0, 1 << 30),
      );
    }
    _rebuildIndexes();
    notifyListeners();
    await _persist();
  }

  // ── 内部 ──────────────────────────────────────────────────────────────

  void _rebuildIndexes() {
    _hiddenArtistIds.clear();
    _hiddenArtistNames.clear();
    _excludedArtistIds.clear();
    _excludedArtistNames.clear();
    _hiddenAlbumIds.clear();
    _excludedAlbumIds.clear();
    _hiddenPlaylistIds.clear();
    _excludedSongIds.clear();

    for (final entry in _entries.values) {
      final hidden = entry.mode == BlockMode.hidden;
      switch (entry.kind) {
        case BlockKind.artist:
          _excludedArtistIds.add(entry.targetId);
          _excludedArtistNames.add(_norm(entry.name));
          if (hidden) {
            _hiddenArtistIds.add(entry.targetId);
            _hiddenArtistNames.add(_norm(entry.name));
          }
        case BlockKind.album:
          _excludedAlbumIds.add(entry.targetId);
          if (hidden) _hiddenAlbumIds.add(entry.targetId);
        case BlockKind.playlist:
          if (hidden) _hiddenPlaylistIds.add(entry.targetId);
          // 歌单被排除的是**成员歌曲**，两档都要展开（hidden 也要，否则
          // "隐藏了歌单但它的歌照样被随机抽到"）。
          final members = _playlistSongs[entry.targetId];
          if (members != null) _excludedSongIds.addAll(members);
      }
    }
    _revision++;
  }

  String _norm(String? value) => (value ?? '').trim().toLowerCase();

  /// 名字兜底匹配（`artistId` 缺失时用）。
  ///
  /// 除了整串相等，还要能命中「A feat. B」「A & B」「A, B」这类多艺人写法 ——
  /// 否则屏蔽了 A，合唱曲照样漏出来。反过来也会屏蔽 A 的合唱曲，这是符合
  /// 直觉的（用户就是不想听 A）。
  bool _nameMatches(Set<String> names, String? raw) {
    final normalized = _norm(raw);
    if (normalized.isEmpty) return false;
    if (names.contains(normalized)) return true;
    for (final sep in const [
      ',',
      '&',
      '/',
      '、',
      ';',
      ' feat. ',
      ' ft. ',
      ' with '
    ]) {
      if (!normalized.contains(sep)) continue;
      for (final part in normalized.split(sep)) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty && names.contains(trimmed)) return true;
      }
    }
    return false;
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _entries.clear();
    _playlistSongs.clear();
    _scope = '';
    _loaded = false;
    _rebuildIndexes();
  }
}
