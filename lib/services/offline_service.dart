import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/song.dart';
import '../models/playlist.dart';
import '../models/download_record.dart';
import '../utils/image_cache.dart';
import 'download_database_service.dart';
import 'lyrics/lyrics_cache.dart';
import 'subsonic_service.dart';

class DownloadState {
  final bool isDownloading;
  final int currentProgress;
  final int totalCount;
  final int downloadedCount;

  /// 本批次成功/失败数（已下载的跳过不计入失败）。供完成 Toast 报真实结果。
  final int successCount;
  final int failedCount;

  /// 本批次是否被用户主动取消（区别于真实失败：取消不该弹"下载失败"）。
  final bool cancelled;

  DownloadState({
    this.isDownloading = false,
    this.currentProgress = 0,
    this.totalCount = 0,
    this.downloadedCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.cancelled = false,
  });

  DownloadState copyWith({
    bool? isDownloading,
    int? currentProgress,
    int? totalCount,
    int? downloadedCount,
    int? successCount,
    int? failedCount,
    bool? cancelled,
  }) {
    return DownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      currentProgress: currentProgress ?? this.currentProgress,
      totalCount: totalCount ?? this.totalCount,
      downloadedCount: downloadedCount ?? this.downloadedCount,
      successCount: successCount ?? this.successCount,
      failedCount: failedCount ?? this.failedCount,
      cancelled: cancelled ?? this.cancelled,
    );
  }
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  SharedPreferences? _prefs;
  String? _offlineDir;
  final DownloadDatabaseService _db = DownloadDatabaseService();

  /// 记录表的内存镜像：同步方法（isSongDownloaded / getLocalPath 等）查它，
  /// 避免把十几个调用点全改成 async。写入路径与 DB 双写，读取只认镜像。
  Map<String, DownloadRecord> _records = {};

  /// 记录变更代次：任何 _records 写入都 +1，供已下载页 / 列表角标做响应式
  /// 刷新（同步查询拿不到 Flutter 的重建通知，用一个 int 代次桥接）。
  final ValueNotifier<int> recordsNotifier = ValueNotifier(0);

  /// 批量下载期间抑制逐首 notify：否则 N 首 × (已下载页整页 + 每个角标)
  /// 会重建上万次 widget。抑制期结束后由 startBackgroundDownload 统一notify 一次。
  bool _suppressRecordNotify = false;

  void _notifyRecordsChanged() {
    if (_suppressRecordNotify) return;
    recordsNotifier.value++;
  }

  /// 已下载列表页用：返回全部记录（调用方按 serverId 自行过滤/分组）。
  List<DownloadRecord> get downloadRecords =>
      List.unmodifiable(_records.values);

  /// 按服务器取下载记录。serverId 为空时返回全部（老数据无归属信息）。
  List<DownloadRecord> getDownloadRecords({String? serverId}) {
    if (serverId == null || serverId.isEmpty) {
      return List.unmodifiable(_records.values);
    }
    return List.unmodifiable(
      _records.values.where(
        (r) => r.serverId.isEmpty || r.serverId == serverId,
      ),
    );
  }

  DownloadRecord? getDownloadRecord(String songId) => _records[songId];

  bool _offlineMode = false;
  bool get isOfflineMode => _offlineMode;
  void setOfflineMode(bool value) => _offlineMode = value;

  final ValueNotifier<DownloadState> downloadState = ValueNotifier(
    DownloadState(),
  );
  bool _isBackgroundDownloadActive = false;

  static const String _keyDownloadedSongs = 'offline_downloaded_songs';
  static const String _keyPendingScrobbles = 'pending_scrobbles';
  static const String _keyParallelDownloads = 'parallel_downloads_count';
  static const String _keyKeepScreenOn = 'offline_keep_screen_on';
  static const String _keyWifiOnly = 'offline_wifi_only';

  static const int _defaultParallelDownloads = 3;
  static const int _maxParallelDownloads = 5;

  /// 并发调用共享同一个 Future，避免多处冷启初始化时 _loadRecords 重复跑、
  /// 其 _records 整体赋值覆盖掉初始化期间刚写入的下载记录。
  Future<void>? _initFuture;

  Future<void> initialize() {
    final existing = _initFuture;
    if (existing != null) return existing;
    final future = _initializeOnce();
    _initFuture = future;
    // 失败时允许下次重试，不让一次瞬时错误永久锁死初始化。
    future.catchError((_) => _initFuture = null);
    return future;
  }

  Future<void> _initializeOnce() async {
    _prefs ??= await SharedPreferences.getInstance();
    final dir = await getApplicationDocumentsDirectory();
    _offlineDir = '${dir.path}/offline_music';

    final offlineDirectory = Directory(_offlineDir!);
    if (!await offlineDirectory.exists()) {
      await offlineDirectory.create(recursive: true);
    }

    // 清理上次进程被强杀时残留的 .part（正常结束时 catch/rename 已清掉；
    // 强杀来不及跑，重启后这些半截文件既无记录也无法从 UI 删除）。
    try {
      await for (final entity in offlineDirectory.list()) {
        if (entity is File && entity.path.endsWith('.part')) {
          await entity.delete();
        }
      }
    } catch (e) {
      debugPrint('[Offline] .part cleanup failed: $e');
    }

    // DB 不可用（测试环境、数据库损坏）时降级为空记录继续跑——
    // 下载功能是辅助能力，绝不能因为打开 DB 失败拖垮整个 App 冷启。
    try {
      await _loadRecords();
      await _migrateLegacyWhitelist();
    } catch (e) {
      debugPrint('[Offline] load records failed, degrade to empty: $e');
      _records = {};
      _notifyRecordsChanged();
    }
  }

  /// 从 DB 加载记录到内存镜像，并做一致性自愈：
  /// 记录还在但文件已被外部删掉 → 删记录（避免"计数虚报、播放失败"）。
  Future<void> _loadRecords() async {
    final records = await _db.getAll();
    final survived = <DownloadRecord>[];
    for (final record in records) {
      final file = File('$_offlineDir/${record.fileName}');
      if (await file.exists()) {
        survived.add(record);
      } else {
        await _db.delete(record.songId);
      }
    }
    _records = {for (final r in survived) r.songId: r};
    _notifyRecordsChanged();
  }

  /// 老版本把下载清单存成 prefs 里的 songId 白名单，没有任何元数据。
  /// 冷启时扫一遍：文件还在就补一条记录（元数据缺失，title 用 id 兜底），
  /// 之后清掉旧键。用户已下载的文件一首都不会丢。
  Future<void> _migrateLegacyWhitelist() async {
    final legacy = _prefs?.getStringList(_keyDownloadedSongs);
    if (legacy == null || legacy.isEmpty) return;

    final migrated = <DownloadRecord>[];
    for (final id in legacy) {
      if (_records.containsKey(id)) continue;
      final file = File('$_offlineDir/$id.mp3');
      if (!await file.exists()) continue;
      final bytes = await file.length();
      migrated.add(
        DownloadRecord(
          songId: id,
          serverId: '', // 老数据无归属信息，不串到任何服务器
          song: Song(id: id, title: id),
          fileName: '$id.mp3',
          suffix: 'mp3',
          bytes: bytes,
          downloadedAt: DateTime.fromMillisecondsSinceEpoch(
            file.lastModifiedSync().millisecondsSinceEpoch,
          ),
        ),
      );
    }
    if (migrated.isNotEmpty) {
      await _db.upsertMany(migrated);
      for (final record in migrated) {
        _records[record.songId] = record;
      }
      _notifyRecordsChanged();
    }
    await _prefs?.remove(_keyDownloadedSongs);
  }

  /// 音频文件路径：从记录里取真实文件名（含扩展名）。
  /// 老数据/尚未建记录的 id 回退到 .mp3，保证所有调用点零改动。
  String _getSongPath(String songId) {
    final fileName = _records[songId]?.fileName ?? '$songId.mp3';
    return '$_offlineDir/$fileName';
  }

  String _getLyricsPath(String songId) {
    return '$_offlineDir/$songId.lyrics.json';
  }

  String _getCoverArtPath(String songId) {
    return '$_offlineDir/$songId.jpg';
  }

  String? getLocalCoverArtPath(String songId) {
    if (_offlineDir == null) return null;
    final path = _getCoverArtPath(songId);
    if (File(path).existsSync()) return path;
    return null;
  }

  Future<void> saveLyrics(String songId, Map<String, dynamic> data) async {
    if (_offlineDir == null) await initialize();
    try {
      await File(_getLyricsPath(songId)).writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint('Error saving lyrics: $e');
    }
  }

  Future<Map<String, dynamic>?> getLocalLyrics(String songId) async {
    if (_offlineDir == null) await initialize();
    try {
      final file = File(_getLyricsPath(songId));
      if (!file.existsSync()) return null;
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  bool isSongDownloaded(String songId) {
    if (_offlineDir == null) return false;
    final record = _records[songId];
    // 有记录就以记录为准（文件已由 _loadRecords 自愈校验过）；
    // 无记录时兼容尚未迁移的进程内状态，回退到文件存在判断。
    if (record != null) return true;
    return File('$_offlineDir/$songId.mp3').existsSync();
  }

  List<String> getDownloadedSongIds() {
    return _records.keys.toList();
  }

  int getDownloadedCount() {
    return _records.length;
  }

  Future<int> getDownloadedSize() async {
    if (_offlineDir == null) return 0;
    // 统一口径：只算音频文件本身（封面/歌词是附属小文件，不混入"下了多少MB"）。
    // 记录里的 bytes 是下载时算好的真实大小；缺记录的老文件回退 stat。
    var total = _records.values.fold<int>(0, (sum, r) => sum + r.bytes);
    final knownFiles = _records.values.map((r) => r.fileName).toSet();
    final dir = Directory(_offlineDir!);
    if (await dir.exists()) {
      await for (final entity in dir.list()) {
        if (entity is File &&
            !knownFiles.contains(entity.uri.pathSegments.last) &&
            !entity.path.endsWith('.part') &&
            !entity.path.endsWith('.jpg') &&
            !entity.path.endsWith('.lyrics.json')) {
          total += await entity.length();
        }
      }
    }
    return total;
  }

  Future<bool> downloadSong(
    Song song,
    SubsonicService subsonicService, {
    Function(double progress)? onProgress,
    DownloadSource source = DownloadSource.manual,
  }) async {
    if (_offlineDir == null) await initialize();

    final fileName = downloadFileNameFor(song.id, song.suffix);
    final filePath = '$_offlineDir/$fileName';
    final partPath = '$filePath.part';

    try {
      final url = subsonicService.getStreamUrl(song.id);
      final dio = Dio();

      // 先写临时文件，成功校验后再 rename 落盘——中途被杀/断网不会留下
      // 一个"存在但半截"的正式文件被 isSongDownloaded 误判为已完成。
      await dio.download(
        url,
        partPath,
        onReceiveProgress: (received, total) {
          if (total > 0 && onProgress != null) {
            onProgress(received / total);
          }
        },
      );

      final partFile = File(partPath);
      if (!await partFile.exists()) {
        debugPrint('Download incomplete: part file missing for ${song.title}');
        return false;
      }
      final downloadedBytes = await partFile.length();
      if (downloadedBytes < 1024) {
        debugPrint('Download incomplete: ${downloadedBytes}B for ${song.title}');
        await partFile.delete();
        return false;
      }
      // 服务端给了 size 时做一次完整性校验（允许 1% 的转码/分块误差）。
      final expected = song.size;
      if (expected != null && expected > 0) {
        final tolerance = (expected * 0.01).round() + 64;
        if ((downloadedBytes - expected).abs() > tolerance) {
          debugPrint(
            'Download size mismatch for ${song.title}: '
            'got $downloadedBytes, expected $expected',
          );
          await partFile.delete();
          return false;
        }
      }
      final finalFile = File(filePath);
      if (await finalFile.exists()) await finalFile.delete();
      // 换后缀重下（如 .mp3 → .flac）时删掉旧扩展名文件，避免孤儿文件
      // 占磁盘且被 getDownloadedSize 计入总量。
      final oldFileName = _records[song.id]?.fileName;
      if (oldFileName != null && oldFileName != fileName) {
        try {
          final oldFile = File('$_offlineDir/$oldFileName');
          if (await oldFile.exists()) await oldFile.delete();
        } catch (e) {
          debugPrint('[Offline] remove stale file failed: $e');
        }
      }
      await partFile.rename(filePath);

      final record = DownloadRecord(
        songId: song.id,
        serverId: subsonicService.coverCacheServerId,
        song: song,
        fileName: fileName,
        suffix: fileName.contains('.') ? fileName.split('.').last : 'mp3',
        bytes: downloadedBytes,
        downloadedAt: DateTime.now(),
        source: source,
      );
      await _db.upsert(record);
      _records[song.id] = record;
      _notifyRecordsChanged();

      try {
        if (song.coverArt != null) {
          final coverUrl = subsonicService.getCoverArtUrl(
            song.coverArt,
            size: kNowPlayingArtworkSize,
          );
          if (coverUrl.isNotEmpty) {
            final dioCover = Dio();
            await dioCover.download(coverUrl, _getCoverArtPath(song.id));
          }
        }
      } catch (e) {
        debugPrint('Error downloading cover art for ${song.title}: $e');
      }
      try {
        final lyricsMap = <String, dynamic>{};
        final syncedLyrics = await subsonicService.getLyricsBySongId(song.id);
        if (syncedLyrics != null) lyricsMap['lyricsList'] = syncedLyrics;
        final plainLyrics = await subsonicService.getLyrics(
          artist: song.artist,
          title: song.title,
        );
        if (plainLyrics != null) lyricsMap['lyrics'] = plainLyrics;
        if (lyricsMap.isNotEmpty) {
          // 带来源标记（`docs/歌词源优先级修复技术方案.md` §5.3）：下载路径拿到
          // 的都是服务器歌词，标记后不会被误判为「来源可疑」而触发会话级复查。
          await saveLyrics(
            song.id,
            withLyricsCacheMeta(
              lyricsMap,
              subsonicService.isDaoliyu
                  ? LyricsCacheSource.daoliyu
                  : LyricsCacheSource.server,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error downloading lyrics for ${song.title}: $e');
      }

      return true;
    } catch (e) {
      debugPrint('Error downloading song: $e');
      // 失败时清掉临时文件，绝不留半截数据。
      try {
        final partFile = File(partPath);
        if (await partFile.exists()) await partFile.delete();
      } catch (_) {}
      return false;
    }
  }

  Future<void> downloadSongs(
    List<Song> songs,
    SubsonicService subsonicService, {
    Function(int current, int total)? onProgress,
    Function(Song song, bool success)? onSongComplete,
    Function()? onComplete,
  }) async {
    if (_offlineDir == null) await initialize();

    for (int i = 0; i < songs.length; i++) {
      final song = songs[i];

      if (isSongDownloaded(song.id)) {
        onProgress?.call(i + 1, songs.length);
        onSongComplete?.call(song, true);
        continue;
      }

      final success = await downloadSong(song, subsonicService);
      onProgress?.call(i + 1, songs.length);
      onSongComplete?.call(song, success);
    }

    onComplete?.call();
  }

  /// Get the number of parallel downloads to use
  int getParallelDownloadsCount() {
    return _prefs?.getInt(_keyParallelDownloads) ?? _defaultParallelDownloads;
  }

  /// Set the number of parallel downloads (1 to _maxParallelDownloads)
  Future<void> setParallelDownloadsCount(int count) async {
    if (_prefs == null) await initialize();
    final clampedCount = count.clamp(1, _maxParallelDownloads);
    await _prefs?.setInt(_keyParallelDownloads, clampedCount);
  }

  Future<void> setKeepScreenOn(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyKeepScreenOn, value);
  }

  bool getKeepScreenOn() {
    return _prefs?.getBool(_keyKeepScreenOn) ?? true;
  }

  Future<void> setWifiOnly(bool value) async {
    if (_prefs == null) await initialize();
    await _prefs?.setBool(_keyWifiOnly, value);
  }

  /// 是否仅允许 Wi-Fi 下载。默认 false（不限制），避免改变老用户行为。
  bool getWifiOnly() {
    return _prefs?.getBool(_keyWifiOnly) ?? false;
  }

  /// 返回本批次 (成功数, 失败数)，供调用方弹真实的完成提示。
  /// 已有下载被跳过时既不算成功也不算失败。
  Future<({int succeeded, int failed})> startBackgroundDownload(
    List<Song> songs,
    SubsonicService subsonicService, {
    int? parallelCount,
  }) async {
    if (_isBackgroundDownloadActive) {
      debugPrint('Background download already in progress');
      return (succeeded: 0, failed: 0);
    }

    _isBackgroundDownloadActive = true;
    _suppressRecordNotify = true;
    final alreadyDownloadedCount = getDownloadedCount();
    final concurrentDownloads = parallelCount ?? getParallelDownloadsCount();
    final keepScreenOn = getKeepScreenOn();

    // Enable wake lock to prevent the screen from turning off during download
    if (keepScreenOn && !kIsWeb) {
      try {
        await WakelockPlus.enable();
        debugPrint('Wake lock enabled for library download');
      } catch (e) {
        debugPrint('Failed to enable wake lock: $e');
      }
    }

    downloadState.value = DownloadState(
      isDownloading: true,
      currentProgress: 0,
      totalCount: songs.length,
      downloadedCount: alreadyDownloadedCount,
    );

    var succeeded = 0;
    var failed = 0;

    if (_offlineDir == null) await initialize();

    try {
      final pendingSongs = songs.where((s) => !isSongDownloaded(s.id)).toList();
      int completedCount = songs.length - pendingSongs.length;

      // Process songs in batches using parallel downloads
      for (int i = 0; i < pendingSongs.length; i += concurrentDownloads) {
        if (!_isBackgroundDownloadActive) {
          break;
        }

        // Get the next batch of songs
        final batch = pendingSongs.skip(i).take(concurrentDownloads).toList();

        // 并发回调可能同帧到达，用 Future.wait 的返回值统一汇总，
        // 避免多个 async 回调各自 copyWith 造成计数互相覆盖。
        final results = await Future.wait(
          batch.map((song) async {
            if (!_isBackgroundDownloadActive) return false;
            return downloadSong(song, subsonicService);
          }),
        );

        completedCount += results.length;
        for (final success in results) {
          if (success) {
            succeeded++;
          } else {
            failed++;
          }
        }
        downloadState.value = downloadState.value.copyWith(
          currentProgress: completedCount,
          downloadedCount: getDownloadedCount(),
          successCount: succeeded,
          failedCount: failed,
        );
      }
    } catch (e) {
      debugPrint('Error during background download: $e');
    } finally {
      _isBackgroundDownloadActive = false;
      // 批量期间逐首 notify 被抑制，这里统一通知一次（列表/角标只重建一次）。
      _suppressRecordNotify = false;
      _notifyRecordsChanged();
      downloadState.value = downloadState.value.copyWith(isDownloading: false);

      // Always disable wake lock when download finishes or fails
      if (!kIsWeb) {
        try {
          await WakelockPlus.disable();
          debugPrint('Wake lock disabled after download');
        } catch (e) {
          debugPrint('Failed to disable wake lock: $e');
        }
      }
    }
    return (succeeded: succeeded, failed: failed);
  }

  void cancelBackgroundDownload() {
    if (!_isBackgroundDownloadActive) return;
    _isBackgroundDownloadActive = false;
    downloadState.value = downloadState.value.copyWith(
      isDownloading: false,
      cancelled: true,
    );
  }

  /// 下载结束后由进度卡监听器调用：归零批次计数，避免后续 rebuild 重复弹
  /// 终态卡。已下载总数（downloadedCount）保留，设置页统计不受影响。
  void resetDownloadState() {
    // 终态到下一帧这十几毫秒内若用户又发起了一轮下载，_isBackgroundDownloadActive
    // 已重新置 true；此时清零会吞掉新批次的进度/终态卡，直接跳过。
    if (_isBackgroundDownloadActive) return;
    downloadState.value = DownloadState(
      downloadedCount: getDownloadedCount(),
    );
  }

  bool get isBackgroundDownloadActive => _isBackgroundDownloadActive;

  Future<void> downloadPlaylist(
    Playlist playlist,
    SubsonicService subsonicService, {
    Function(int current, int total)? onProgress,
    Function()? onComplete,
  }) async {
    final songs = playlist.songs ?? [];
    await downloadSongs(
      songs,
      subsonicService,
      onProgress: onProgress,
      onComplete: onComplete,
    );
  }

  Future<bool> deleteSong(String songId) async {
    if (_offlineDir == null) return false;

    try {
      final file = File(_getSongPath(songId));
      if (await file.exists()) {
        await file.delete();
      }
      final lyricsFile = File(_getLyricsPath(songId));
      if (await lyricsFile.exists()) {
        await lyricsFile.delete();
      }
      final coverArtFile = File(_getCoverArtPath(songId));
      if (await coverArtFile.exists()) {
        await coverArtFile.delete();
      }
      // .part 名跟随记录里的真实文件名（可能是 .flac.part/.m4a.part），
      // 写死 .mp3.part 会漏掉非 mp3 的残留。
      final partFile = File('$_offlineDir/${_records[songId]?.fileName ?? '$songId.mp3'}.part');
      if (await partFile.exists()) await partFile.delete();

      await _db.delete(songId);
      _records.remove(songId);
      _notifyRecordsChanged();
      return true;
    } catch (e) {
      debugPrint('Error deleting song: $e');
      return false;
    }
  }

  Future<void> deleteAllDownloads() async {
    if (_offlineDir == null) return;

    try {
      final dir = Directory(_offlineDir!);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            await entity.delete();
          }
        }
      }

      await _db.clear();
      _records.clear();
      _notifyRecordsChanged();
      await _prefs?.remove(_keyDownloadedSongs);
    } catch (e) {
      debugPrint('Error deleting all downloads: $e');
    }
  }

  String? getLocalPath(String songId) {
    if (isSongDownloaded(songId)) {
      return _getSongPath(songId);
    }
    return null;
  }

  Future<void> queueScrobble(String songId, {bool submission = true}) async {
    if (_prefs == null) await initialize();
    final scrobbles = _getPendingScrobbles();
    scrobbles.add({
      'id': songId,
      'submission': submission ? 'true' : 'false',
      'time': DateTime.now().millisecondsSinceEpoch.toString(),
    });
    await _prefs!.setString(_keyPendingScrobbles, json.encode(scrobbles));
    debugPrint(
      'Scrobble queued for $songId (submission=$submission). Total pending: ${scrobbles.length}',
    );
  }

  List<Map<String, String>> _getPendingScrobbles() {
    final raw = _prefs?.getString(_keyPendingScrobbles);
    if (raw == null) return [];
    try {
      final list = json.decode(raw) as List;
      return list.map((e) => Map<String, String>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  int getPendingScrobbleCount() => _getPendingScrobbles().length;

  Future<void> flushPendingScrobbles(SubsonicService subsonicService) async {
    if (_prefs == null) await initialize();
    final pending = _getPendingScrobbles();
    if (pending.isEmpty) return;

    debugPrint('Flushing ${pending.length} pending scrobble(s)...');
    final remaining = <Map<String, String>>[];
    for (final scrobble in pending) {
      try {
        await subsonicService.scrobble(
          scrobble['id']!,
          submission: scrobble['submission'] == 'true',
        );
      } catch (e) {
        debugPrint('Scrobble flush failed for ${scrobble['id']}: $e');
        remaining.add(scrobble);
      }
    }

    if (remaining.isEmpty) {
      await _prefs!.remove(_keyPendingScrobbles);
      debugPrint('All pending scrobbles flushed successfully.');
    } else {
      await _prefs!.setString(_keyPendingScrobbles, json.encode(remaining));
      debugPrint('${remaining.length} scrobble(s) still pending after flush.');
    }
  }

  String getPlayableUrl(Song song, SubsonicService subsonicService) {
    if (song.isLocal == true && song.path != null) {
      return 'file://${song.path}';
    }

    final localPath = getLocalPath(song.id);
    if (localPath != null) {
      return 'file://$localPath';
    }
    return subsonicService.getStreamUrl(song.id);
  }
}
