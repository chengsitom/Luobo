import 'dart:convert';

import 'song.dart';

/// 一条本地下载记录。
///
/// 老版本只把 songId 存进 SharedPreferences 的白名单，没有任何元数据——
/// 于是「已下载」页无从渲染、切服无法隔离、文件残缺也无法自愈。这里把
/// 一首下载歌需要的所有信息收敛成一条记录；[song] 用 songJson 存，是因为
/// Song 已有稳定的 toJson/fromJson，迁移老数据时也能构造最小 Song 兜底。
/// 由歌曲元数据推导本地文件名。扩展名跟服务端原始格式走——下载走
/// format=raw 直出，FLAC/APE/M4A 都可能，写死 .mp3 会让 AVPlayer /
/// ExoPlayer 按扩展名猜错解码器。非法字符做收敛，避免路径注入。
String downloadFileNameFor(String songId, String? suffix) {
  final raw = (suffix ?? '').trim().toLowerCase();
  var clean = raw.replaceAll(RegExp(r'[^a-z0-9]'), '');
  if (clean.isEmpty || clean.length > 8) clean = 'mp3';
  final safeId = songId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  return '$safeId.$clean';
}

enum DownloadSource {
  /// 用户从 ⋮ 菜单 / 专辑 / 歌单 / 多选主动下载。
  manual,

  /// 预留：播放即自动缓存（当前未启用，字段先留好，加功能不用改表结构）。
  auto,
}

enum DownloadStatus {
  complete,
  failed,
}

class DownloadRecord {
  final String songId;
  final String serverId;
  final Song song;
  final String fileName;
  final String suffix;
  final int bytes;
  final DateTime downloadedAt;
  final DownloadSource source;
  final DownloadStatus status;

  const DownloadRecord({
    required this.songId,
    required this.serverId,
    required this.song,
    required this.fileName,
    required this.suffix,
    required this.bytes,
    required this.downloadedAt,
    this.source = DownloadSource.manual,
    this.status = DownloadStatus.complete,
  });

  factory DownloadRecord.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> songMap;
    try {
      final decoded = jsonDecode(map['songJson'] as String);
      songMap = decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      songMap = <String, dynamic>{};
    }
    // 迁移老白名单时没有完整元数据，songJson 至少带 id；缺 title 时用 id
    // 兜底，避免 UI 出现 "Unknown Title" 而用户认不出是哪首歌。
    songMap.putIfAbsent('id', () => map['songId']);
    songMap.putIfAbsent('title', () => map['songId']);

    return DownloadRecord(
      songId: map['songId'] as String,
      serverId: (map['serverId'] as String?) ?? '',
      song: Song.fromJson(songMap),
      fileName: (map['fileName'] as String?) ?? '${map['songId']}.mp3',
      suffix: (map['suffix'] as String?) ?? 'mp3',
      bytes: (map['bytes'] as int?) ?? 0,
      downloadedAt: DateTime.fromMillisecondsSinceEpoch(
        (map['downloadedAt'] as int?) ?? 0,
      ),
      source: map['source'] == 'auto'
          ? DownloadSource.auto
          : DownloadSource.manual,
      status: map['status'] == 'failed'
          ? DownloadStatus.failed
          : DownloadStatus.complete,
    );
  }

  Map<String, dynamic> toMap() => {
        'songId': songId,
        'serverId': serverId,
        'songJson': jsonEncode(song.toJson()),
        'fileName': fileName,
        'suffix': suffix,
        'bytes': bytes,
        'downloadedAt': downloadedAt.millisecondsSinceEpoch,
        'source': source == DownloadSource.auto ? 'auto' : 'manual',
        'status': status == DownloadStatus.failed ? 'failed' : 'complete',
      };

  DownloadRecord copyWith({
    String? serverId,
    Song? song,
    String? fileName,
    String? suffix,
    int? bytes,
    DateTime? downloadedAt,
    DownloadSource? source,
    DownloadStatus? status,
  }) {
    return DownloadRecord(
      songId: songId,
      serverId: serverId ?? this.serverId,
      song: song ?? this.song,
      fileName: fileName ?? this.fileName,
      suffix: suffix ?? this.suffix,
      bytes: bytes ?? this.bytes,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      source: source ?? this.source,
      status: status ?? this.status,
    );
  }
}
