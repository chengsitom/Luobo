import '../utils/byte_format.dart';
import 'artist_ref.dart';
import 'json_coerce.dart';

class Song {
  final String id;
  final String title;
  final String? album;
  final String? albumId;
  final String? artist;
  final String? artistId;
  final int? track;
  final int? year;
  final String? genre;
  final String? coverArt;
  final int? duration;
  final int? bitRate;
  final String? suffix;
  final String? contentType;
  final int? size;
  final String? path;
  final bool? starred;
  final int? userRating;
  final bool isLocal;
  final double? replayGainTrackGain;
  final double? replayGainAlbumGain;
  final double? replayGainTrackPeak;
  final double? replayGainAlbumPeak;
  final List<ArtistRef>? artistParticipants;
  final DateTime? created;
  final bool? hasDolbyAtmos;
  final int? samplingRate;
  final int? bitDepth;

  Song({
    required this.id,
    required this.title,
    this.album,
    this.albumId,
    this.artist,
    this.artistId,
    this.track,
    this.year,
    this.genre,
    this.coverArt,
    this.duration,
    this.bitRate,
    this.suffix,
    this.contentType,
    this.size,
    this.path,
    this.starred,
    this.userRating,
    this.isLocal = false,
    this.replayGainTrackGain,
    this.replayGainAlbumGain,
    this.replayGainTrackPeak,
    this.replayGainAlbumPeak,
    this.artistParticipants,
    this.created,
    this.hasDolbyAtmos,
    this.samplingRate,
    this.bitDepth,
  });

  factory Song.fromJson(Map<String, dynamic> json) {
    // 硬转 `as Map<String, dynamic>?` 在服务端把 replayGain 输出成别的形状时
    // 会让整首歌解析失败，这里只在确实是 Map 时取值。
    final rawReplayGain = json['replayGain'];
    final replayGain =
        rawReplayGain is Map ? Map<String, dynamic>.from(rawReplayGain) : null;

    return Song(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Title',
      album: json['album']?.toString(),
      albumId: json['albumId']?.toString(),
      artist: json['artist']?.toString(),
      artistId: json['artistId']?.toString(),
      track: jsonInt(json['track']),
      year: jsonInt(json['year']),
      genre: json['genre']?.toString(),
      coverArt: json['coverArt']?.toString(),
      duration: jsonInt(json['duration']),
      bitRate: jsonInt(json['bitRate']),
      suffix: json['suffix']?.toString(),
      contentType: json['contentType']?.toString(),
      size: jsonInt(json['size']),
      path: json['path']?.toString(),
      starred: json['starred'] != null ? true : false,
      userRating: jsonInt(json['userRating']),
      isLocal: jsonBool(json['isLocal']) ?? false,
      replayGainTrackGain: jsonDouble(replayGain?['trackGain']),
      replayGainAlbumGain: jsonDouble(replayGain?['albumGain']),
      replayGainTrackPeak: jsonDouble(replayGain?['trackPeak']),
      replayGainAlbumPeak: jsonDouble(replayGain?['albumPeak']),
      artistParticipants: ArtistRef.parseList(json['artists']),
      created: json['created'] != null
          ? DateTime.tryParse(json['created'].toString())
          : null,
      hasDolbyAtmos: jsonBool(json['hasDolbyAtmos']),
      samplingRate: jsonInt(json['samplingRate']),
      bitDepth: jsonInt(json['bitDepth']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'album': album,
      'albumId': albumId,
      'artist': artist,
      'artistId': artistId,
      'track': track,
      'year': year,
      'genre': genre,
      'coverArt': coverArt,
      'duration': duration,
      'bitRate': bitRate,
      'suffix': suffix,
      'contentType': contentType,
      'size': size,
      'path': path,
      'isLocal': isLocal,
      'replayGain': {
        if (replayGainTrackGain != null) 'trackGain': replayGainTrackGain,
        if (replayGainAlbumGain != null) 'albumGain': replayGainAlbumGain,
        if (replayGainTrackPeak != null) 'trackPeak': replayGainTrackPeak,
        if (replayGainAlbumPeak != null) 'albumPeak': replayGainAlbumPeak,
      },
      if (artistParticipants != null)
        'artists': artistParticipants!.map((a) => a.toJson()).toList(),
      'created': created?.toIso8601String(),
      if (hasDolbyAtmos != null) 'hasDolbyAtmos': hasDolbyAtmos,
      if (samplingRate != null) 'samplingRate': samplingRate,
      if (bitDepth != null) 'bitDepth': bitDepth,
    };
  }

  String get formattedDuration {
    if (duration == null) return '0:00';
    final minutes = duration! ~/ 60;
    final seconds = duration! % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  /// Human readable file size, e.g. "28.14 MB". Empty when unknown.
  ///
  /// 格式化本身收敛在 `utils/byte_format.dart`，这里只保留「未知为空串」的语义。
  String get formattedSize {
    final bytes = size;
    if (bytes == null || bytes <= 0) return '';
    return formatBytes(bytes);
  }

  /// Sample rate in kHz (e.g. "44.1 kHz"), empty when unknown.
  String get formattedSampleRate {
    final hz = samplingRate;
    if (hz == null || hz <= 0) return '';
    if (hz % 1000 == 0) return '${hz ~/ 1000} kHz';
    return '${(hz / 1000).toStringAsFixed(1)} kHz';
  }

  Song copyWith({
    String? id,
    String? title,
    String? album,
    String? albumId,
    String? artist,
    String? artistId,
    int? track,
    int? year,
    String? genre,
    String? coverArt,
    int? duration,
    int? bitRate,
    String? suffix,
    String? contentType,
    int? size,
    String? path,
    bool? starred,
    int? userRating,
    bool? isLocal,
    double? replayGainTrackGain,
    double? replayGainAlbumGain,
    double? replayGainTrackPeak,
    double? replayGainAlbumPeak,
    List<ArtistRef>? artistParticipants,
    DateTime? created,
    bool? hasDolbyAtmos,
    int? samplingRate,
    int? bitDepth,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      album: album ?? this.album,
      albumId: albumId ?? this.albumId,
      artist: artist ?? this.artist,
      artistId: artistId ?? this.artistId,
      track: track ?? this.track,
      year: year ?? this.year,
      genre: genre ?? this.genre,
      coverArt: coverArt ?? this.coverArt,
      duration: duration ?? this.duration,
      bitRate: bitRate ?? this.bitRate,
      suffix: suffix ?? this.suffix,
      contentType: contentType ?? this.contentType,
      size: size ?? this.size,
      path: path ?? this.path,
      starred: starred ?? this.starred,
      userRating: userRating ?? this.userRating,
      isLocal: isLocal ?? this.isLocal,
      replayGainTrackGain: replayGainTrackGain ?? this.replayGainTrackGain,
      replayGainAlbumGain: replayGainAlbumGain ?? this.replayGainAlbumGain,
      replayGainTrackPeak: replayGainTrackPeak ?? this.replayGainTrackPeak,
      replayGainAlbumPeak: replayGainAlbumPeak ?? this.replayGainAlbumPeak,
      artistParticipants: artistParticipants ?? this.artistParticipants,
      created: created ?? this.created,
      hasDolbyAtmos: hasDolbyAtmos ?? this.hasDolbyAtmos,
      samplingRate: samplingRate ?? this.samplingRate,
      bitDepth: bitDepth ?? this.bitDepth,
    );
  }
}
