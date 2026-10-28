import 'json_coerce.dart';
import 'server_config.dart';
import 'song.dart';

/// 道理鱼「心动歌单」—— 服务端按曲库风格 / 场景组合出来的推荐歌单。
///
/// 接口实测（2026-10-27）：
/// - 列表 `GET /api/library/heart-playlists?count=8`
/// - 详情 `GET /api/library/heart-playlists/{id}`（额外带 `trackIds` / `tracks`）
///
/// 列表接口不返回曲目，详情接口一次返回全部曲目；[tracks] 在列表阶段为空。
class HeartPlaylist {
  const HeartPlaylist({
    required this.id,
    required this.name,
    required this.description,
    required this.genres,
    required this.scenes,
    required this.trackCount,
    required this.totalDurationSeconds,
    required this.coverUrls,
    required this.trackIds,
    required this.tracks,
  });

  final String id;
  final String name;
  final String description;
  final List<String> genres;
  final List<String> scenes;
  final int trackCount;
  final double totalDurationSeconds;

  /// 服务端返回的 4 个封面路径（`/api/cover?path=...`，不带票据）。
  final List<String> coverUrls;

  /// 详情接口返回的完整曲目 ID 顺序。
  final List<String> trackIds;

  /// 详情接口解析后的曲目；列表阶段为空。
  final List<Song> tracks;

  factory HeartPlaylist.fromListJson(Map<String, dynamic> json) {
    return HeartPlaylist._fromJson(json, tracks: const []);
  }

  /// [tracks] 由调用方用 `SubsonicService.songFromDaoliyuTrack` 解析后传入。
  factory HeartPlaylist.fromDetailJson(
    Map<String, dynamic> json, {
    List<Song> tracks = const [],
  }) {
    return HeartPlaylist._fromJson(json, tracks: tracks);
  }

  factory HeartPlaylist._fromJson(
    Map<String, dynamic> json, {
    required List<Song> tracks,
  }) {
    final rawTrackIds = _stringList(json['trackIds']);
    return HeartPlaylist(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      genres: _stringList(json['genres']),
      scenes: _stringList(json['scenes']),
      trackCount: jsonInt(json['trackCount']) ?? tracks.length,
      totalDurationSeconds: jsonDouble(json['totalDurationSeconds']) ?? 0,
      coverUrls: _stringList(json['coverUrls']),
      trackIds: rawTrackIds.isNotEmpty
          ? rawTrackIds
          : tracks.map((s) => s.id).toList(),
      tracks: tracks,
    );
  }

  /// `60 首 · 4 小时 16 分` 里的时长部分；没有时长返回空串。
  String get durationLabel => formatHeartDuration(totalDurationSeconds);

  /// 从名称里取「第 89 辑」的辑号；取不到返回 null。
  String? get issueLabel {
    final match = RegExp(r'第\s*(\d+)\s*辑').firstMatch(name);
    if (match == null) return null;
    return '第 ${match.group(1)} 辑';
  }

  /// 列表 / 详情共用的副标题：`60 首 · 4 小时 16 分`。
  String get metaLabel {
    final parts = <String>[
      if (trackCount > 0) '$trackCount 首',
      if (durationLabel.isNotEmpty) durationLabel,
    ];
    return parts.join(' · ');
  }
}

/// 一次心动歌单批次（列表接口的最外层）。
class HeartPlaylistBatch {
  const HeartPlaylistBatch({
    required this.batchId,
    required this.generatedAt,
    required this.playlists,
  });

  final String batchId;
  final DateTime? generatedAt;
  final List<HeartPlaylist> playlists;

  factory HeartPlaylistBatch.fromJson(Map<String, dynamic> json) {
    final raw = jsonList(json['playlists']);
    final playlists = raw
        .whereType<Map>()
        .map((e) => HeartPlaylist.fromListJson(
              Map<String, dynamic>.from(e),
            ))
        .where((p) => p.id.isNotEmpty)
        .toList();
    return HeartPlaylistBatch(
      batchId: json['batchId']?.toString() ?? '',
      generatedAt: json['generatedAt'] != null
          ? DateTime.tryParse(json['generatedAt'].toString())
          : null,
      playlists: playlists,
    );
  }
}

/// 心动歌单只在道理鱼服务器展示。
///
/// 用白名单而不是「非飞牛就显示」：飞牛走 Subsonic / auto 家族，
/// `serverType` 一般也不含 `daoliyu`，因此这里会正确返回 false。
/// 「自动检测」保存下来的道理鱼配置 `serverFamily` 可能仍是 subsonic，
/// 所以再用 `serverType` 兜底。
bool isDaoliyuServer(ServerConfig? config) {
  if (config == null) return false;
  final family = config.serverFamily.toLowerCase();
  final type = (config.serverType ?? '').toLowerCase();
  return family == 'daoliyu' || type.contains('daoliyu');
}

/// 把秒数格式化成心动歌单的「4 小时 16 分」。
String formatHeartDuration(double seconds) {
  final total = seconds.round();
  if (total <= 0) return '';
  final hours = total ~/ 3600;
  final minutes = (total % 3600) ~/ 60;
  if (hours > 0) {
    return minutes > 0 ? '$hours 小时 $minutes 分' : '$hours 小时';
  }
  if (minutes > 0) return '$minutes 分钟';
  return '$total 秒';
}

List<String> _stringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString() ?? '')
      .where((s) => s.isNotEmpty)
      .toList();
}
