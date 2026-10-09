import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../utils/image_cache.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/android_auto_service.dart';
import '../services/streaming_cache_cleaner.dart';
import '../services/android_system_service.dart';
import '../services/windows_system_service.dart';
import '../services/bluetooth_avrcp_service.dart';
import '../services/samsung_integration_service.dart';
import '../services/recommendation_service.dart';
import '../services/replay_gain_service.dart';
import '../services/auto_dj_service.dart';
import '../services/discord_rpc_service.dart';
import '../services/storage_service.dart';
import '../services/cast_service.dart';
import '../services/upnp_service.dart';
import '../services/audio_handler.dart';
import '../services/audio_interruption_policy.dart';
import '../services/fade_settings_service.dart';
import '../services/lock_screen_lyrics_service.dart';
import '../services/lyrics/lrc_parser.dart';
import '../services/lyrics/lyrics_source.dart';
import '../services/audiobook_progress_store.dart';
import '../services/diagnostics/diagnostics.dart';
import '../services/transcoding_service.dart';
import '../providers/library_provider.dart';

enum RepeatMode { off, all, one }

class PlayerProvider extends ChangeNotifier with WidgetsBindingObserver {
  final SubsonicService _subsonicService;
  late final StorageService _storageService;
  final MuslyAudioHandler _audioHandler;
  // Convenience getter — use this everywhere just_audio is accessed directly.
  AudioPlayer get _audioPlayer => _audioHandler.player;
  final OfflineService _offlineService = OfflineService();
  final AndroidAutoService _androidAutoService = AndroidAutoService();
  final AndroidSystemService _androidSystemService = AndroidSystemService();
  final WindowsSystemService _windowsService = WindowsSystemService();
  final BluetoothAvrcpService _bluetoothService = BluetoothAvrcpService();
  final SamsungIntegrationService _samsungService = SamsungIntegrationService();
  final ReplayGainService _replayGainService = ReplayGainService();
  final AutoDjService _autoDjService = AutoDjService();
  late final DiscordRpcService _discordRpcService;
  final CastService _castService;
  late final UpnpService _upnpService;
  final LockScreenLyricsService _lyricsService = LockScreenLyricsService();

  /// 歌词取源链的唯一实现（`docs/歌词源优先级修复技术方案.md` §4.1）——
  /// 车机副标题 / 通知栏 / 锁屏与 App 内入口共用同一取源顺序。
  late final LyricsSourceService _lyricsSourceService =
      LyricsSourceService(subsonic: _subsonicService);
  LibraryProvider? _libraryProvider;
  RecommendationService? _recommendationService;

  /// Id of the song whose playback end was already recorded, to avoid
  /// counting the same song multiple times when multiple "song ended"
  /// events fire (completion + index change + manual skip).
  String? _trackedSongId;

  /// Song that fired the current "completed" playback event, captured
  /// synchronously when the event arrives. [_onSongComplete] runs
  /// asynchronously, so the user may have already skipped to another track
  /// by the time it executes; this lets us attribute the event to the song
  /// that actually finished instead of the one currently playing.
  Song? _completedSong;
  DateTime? _bufferStartAt;
  int _silentCheckToken = 0;

  /// Transcode settings actually applied to the CURRENT stream, captured
  /// when the stream URL was built. null means the stream is the original
  /// file — even if transcoding settings have changed since playback
  /// started, the audio that is playing is still the original.
  int? _activeStreamBitrate;
  String? _activeStreamFormat;

  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _shuffleEnabled = false;
  bool _gaplessEnabled = true;
  final List<String> _shuffleHistory = [];

  /// Shuffled play order (indices into [_queue]) for "every song plays once
  /// per round" semantics. When exhausted and repeat-all is on, the order is
  /// rebuilt with a fresh shuffle so each round has a new sequence.
  List<int> _shuffleOrder = [];
  int _shuffleOrderPos = 0;
  RepeatMode _repeatMode = RepeatMode.off;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  Song? _currentSong;
  double _volume = 1.0;

  /// True only while audio is actually being rendered on a remote device.
  /// Distinct from isConnected: if the user plays a radio station while a
  /// UPnP renderer is connected, the audio is still local, so this stays false.
  bool _isRenderingRemotely = false;

  String? _resolvedArtworkUrl;

  final StreamingCacheCleaner _cacheCleaner = StreamingCacheCleaner();

  RadioStation? _currentRadioStation;
  bool _isPlayingRadio = false;

  // ── 有声书状态（道理鱼）──────────────────────────────────────────────
  // 见 docs/有声书接入技术方案.md §8.1。_isPlayingAudiobook 是单一 gate：
  // 歌词短路 / scrobble / 统计 / 队列持久化 / 车载模式 / shuffle/repeat 全按它判断。
  bool _isPlayingAudiobook = false;
  Audiobook? _currentAudiobook; // 当前播放的有声书（进度记忆的归属）
  int? _audiobookChapterOrder; // 当前章节 order（1-based，bookmark 用，取自 Song.track）

  /// 进入有声书前的 shuffle/repeat 设置（退出时恢复，Bug B6/B10）。
  bool? _savedShuffleBeforeAudiobook;
  RepeatMode? _savedRepeatBeforeAudiobook;

  /// 进度记忆存储（纯客户端，serverKey 隔离，§9）。
  // 全局共享单例：与列表页/详情页共用同一内存缓存（Meta-Review R001/M001）。
  final AudiobookProgressStore _audiobookProgressStore =
      AudiobookProgressStore.instance;
  String? _audiobookServerKey;

  /// 上次真正落盘的有声书位置（ms）。seek 落盘去抖用：进度条拖拽期间
  /// onChanged 会连续调 seek，位移不足 1s 时不重复写整表快照（§9.2-1）。
  int? _lastSavedAudiobookPositionMs;

  bool _hasPlayedOnce = false;

  SharedPreferences? _prefs;
  Timer? _persistDebounceTimer;
  static const String _keyQueue = 'persistent_queue';
  static const String _keyQueueIndex = 'persistent_queue_index';
  static const String _keyQueueSongId = 'persistent_queue_song_id';
  static const String _keyQueuePosition = 'persistent_queue_position_ms';
  static const String _keyQueueServer = 'persistent_queue_server';

  final bool _reactivatingSession = false;

  Timer? _sleepTimer;
  DateTime? _sleepTimerEnd;
  bool _sleepTimerEndCurrentSong = false;
  bool _sleepTimerFadeOut = false;
  int _sleepTimerFadeDurationSeconds = 30;
  Timer? _sleepTimerFadeTimer;
  Timer? _sleepTimerFadePeriodicTimer;

  // Fade in/out
  final FadeSettingsService _fadeSettingsService = FadeSettingsService();
  Timer? _fadeTimer;
  bool _isFading = false;

  /// 打断前是否在播放（等价 MusicFree 的 `resumeState`）。
  ///
  /// 只在**瞬时打断**（`begin + type=pause`）时置位；打断结束且标记为真才恢复播放。
  /// 语义与置位/清位规则见 `docs/音频打断处理技术方案.md` §4.1：
  /// **`pause()` 内不得清此标记**（打断开始时是「先置位、再 pause」）。
  bool _wasPlayingBeforeInterruption = false;

  final TranscodingService _transcodingService;

  double _playbackSpeed = 1.0;
  double _pitch = 1.0;
  bool _pitchCorrection = true;

  PlayerProvider(
    this._subsonicService,
    StorageService storageService,
    this._castService,
    this._upnpService,
    this._audioHandler,
    this._transcodingService,
  ) {
    _storageService = storageService;
    _discordRpcService = DiscordRpcService(storageService);
    _castService.addListener(_onCastStateChanged);
    _upnpService.addListener(_onUpnpStateChanged);
    _upnpService.onRendererLost = _onUpnpRendererLost;
    _initializePlayer();
    try {
      _initializeAndroidAuto();
    } catch (_) {}
    try {
      _initializeSystemServices();
    } catch (_) {}
    _initializeAutoDj();
    _wireAudioHandlerCallbacks();
    try {
      _initializeLyricsService();
    } catch (_) {}

    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      try {
        _discordRpcService.initialize();
      } catch (_) {}
      try {
        loadDiscordRpcStateStyle();
      } catch (_) {}
    }

    _restoreQueueState();

    // Register app lifecycle observer to save state on iOS when app goes to background
    WidgetsBinding.instance.addObserver(this);
  }

  /// Handle app lifecycle changes - save queue state when going to background (important for iOS)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    DiagnosticsService.instance.record(
      EventType.appLifecycle,
      LogLevel.info,
      {
        'state': state.name,
        'isPlaying': _isPlaying,
        'playerPlaying': _audioPlayer.playing,
        'processingState': _audioPlayer.processingState.name,
        'songId': _currentSong?.id,
        'posMs': _audioPlayer.position.inMilliseconds,
        'hasSource': _audioPlayer.audioSource != null,
        'remotePlayback': _isRenderingRemotely,
      },
    );
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      debugPrint(
          '[Player] App lifecycle state: $state - saving queue state immediately');
      _saveQueueStateImmediate();
      // 有声书进度兜底：退后台/暂停立即保存（§9.2-3）。
      _saveAudiobookProgress();
      // inactive 是瞬态（通知栏/App 切换器/来电横幅），不算退后台；
      // 只有真正退后台（paused）才置位，避免瞬态回前台误触发会话重激活。
      if (state == AppLifecycleState.paused) {
        _wasBackgrounded = true;
      }
    } else if (state == AppLifecycleState.resumed) {
      final hadBackgrounded = _wasBackgrounded;
      _wasBackgrounded = false;
      // 退后台再回前台：记录会话/路由快照，并重新激活音频会话——
      // 暂停 + 蓝牙断开 + 长时间后台会让系统收回会话（无声 bug 触发链的一环），
      // 前台恢复时把会话重新激活，保证下次 play 时输出管线就绪。
      unawaited(_recordAudioSessionState('lifecycleResume'));
      unawaited(_snapshotAudioRoute());
      if (hadBackgrounded) {
        debugPrint(
            '[Player] App resumed from background - reactivating audio session');
        unawaited(_reactivateSessionOnResume());
      }
    }
  }

  /// Connect [MuslyAudioHandler] lock-screen commands back to this provider.
  /// On iOS these come via [audio_service] instead of [iOSSystemPlugin].
  void _wireAudioHandlerCallbacks() {
    _audioHandler.onPlay = play;
    _audioHandler.onPause = pause;
    _audioHandler.onStop = stop;
    _audioHandler.onSkipNext = skipNext;
    _audioHandler.onSkipPrevious = skipPrevious;
    _audioHandler.onSeekTo = seek;
    _audioHandler.onTogglePlayPause = togglePlayPause;
  }

  // ── Persistent Queue ───────────────────────────────────────────────────────

  void _saveQueueState() {
    _persistDebounceTimer?.cancel();
    _persistDebounceTimer = Timer(const Duration(milliseconds: 200), () async {
      await _saveQueueStateImmediate();
    });
  }

  Future<void> _saveQueueStateImmediate() async {
    // B15：guard 必须放在这里（真正写库处）而非 debounce 包装版——
    // didChangeAppLifecycleState 退后台直调 Immediate 版，只 guard debounce 版
    // 会被绕过，章节队列照样写进 persistent_queue_*。有声书进度由 §9 独立存储。
    if (_isPlayingAudiobook) return;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;
      final queueJson = _queue.map((s) => s.toJson()).toList();
      await _prefs!.setString(_keyQueue, jsonEncode(queueJson));
      await _prefs!.setInt(_keyQueueIndex, _currentIndex);
      await _prefs!.setString(_keyQueueSongId, _currentSong?.id ?? '');
      await _prefs!.setInt(_keyQueuePosition, _position.inMilliseconds);
      // 记录队列所属服务器（coverCacheServerId 命名空间），冷启动恢复时校验，
      // 避免切服后恢复旧服务器的队列（旧 songId 打新服务器 → stream/lyrics 404）。
      await _prefs!.setString(
        _keyQueueServer,
        _subsonicService.coverCacheServerId,
      );
      debugPrint(
          'Queue state saved: index $_currentIndex, position $_position');
    } catch (e) {
      debugPrint('Error saving queue state: $e');
    }
  }

  Future<void> _restoreQueueState() async {
    DiagnosticsService.instance.record(
      EventType.restoreStart,
      LogLevel.info,
      {'queueKey': _keyQueue},
    );
    try {
      _prefs ??= await SharedPreferences.getInstance();
      if (_prefs == null) return;

      final queueRaw = _prefs!.getString(_keyQueue);
      if (queueRaw == null || queueRaw.isEmpty) return;

      // 服务器归属校验：队列记录的是上次保存时的 coverCacheServerId。
      // 若与当前服务器不一致（切服后冷启动），丢弃旧服务器队列，
      // 避免用旧 songId 打新服务器导致 stream/lyrics 404。
      if (!await _queueMatchesCurrentServer()) {
        debugPrint(
            '[Player] Queue server mismatch — discarding restored queue');
        DiagnosticsService.instance.record(
          EventType.restoreError,
          LogLevel.info,
          {'error': 'queueServerMismatch'},
        );
        _clearPersistedQueue();
        return;
      }

      final queueJson = jsonDecode(queueRaw) as List<dynamic>;
      if (queueJson.isEmpty) return;

      final restoredSongs = queueJson
          .map((j) => Song.fromJson(j as Map<String, dynamic>))
          .where((s) {
        // Validate local files still exist.
        if (s.isLocal && s.path != null) {
          return File(s.path!).existsSync();
        }
        return true;
      }).toList();

      if (restoredSongs.isEmpty) return;

      final savedIndex = _prefs!.getInt(_keyQueueIndex) ?? 0;
      final savedSongId = _prefs!.getString(_keyQueueSongId);
      final savedPositionMs = _prefs!.getInt(_keyQueuePosition) ?? 0;

      var targetIndex = savedIndex.clamp(0, restoredSongs.length - 1);
      if (savedSongId != null && savedSongId.isNotEmpty) {
        final idIndex = restoredSongs.indexWhere((s) => s.id == savedSongId);
        if (idIndex != -1) targetIndex = idIndex;
      }

      _queue = restoredSongs;
      _currentIndex = targetIndex;
      _currentSong = restoredSongs[targetIndex];
      _position = Duration(milliseconds: savedPositionMs);
      final songDurationSecs = restoredSongs[targetIndex].duration;
      if (songDurationSecs != null && songDurationSecs > 0) {
        _duration = Duration(seconds: songDurationSecs);
      }
      notifyListeners();
      DiagnosticsService.instance.record(
        EventType.restoreEnd,
        LogLevel.info,
        {
          'count': restoredSongs.length,
          'index': targetIndex,
          'positionMs': savedPositionMs,
        },
      );
      debugPrint(
          'Restored persistent queue: ${restoredSongs.length} songs, index $targetIndex, position $_position');
    } catch (e) {
      debugPrint('Error restoring queue state: $e');
      DiagnosticsService.instance.record(
        EventType.restoreError,
        LogLevel.error,
        {'error': '$e'},
      );
    }
  }

  /// 队列是否属于当前服务器。冷启动时 AuthProvider 可能尚未 configure
  /// （coverCacheServerId 为空），此时视为「未知服务器」，放行恢复，
  /// 由 [validateQueueForServer] 在配置就绪后补校验。
  Future<bool> _queueMatchesCurrentServer() async {
    _prefs ??= await SharedPreferences.getInstance();
    if (_prefs == null) return true;
    final savedServer = _prefs!.getString(_keyQueueServer) ?? '';
    final currentServer = _subsonicService.coverCacheServerId;
    if (savedServer.isEmpty || currentServer.isEmpty) return true;
    return savedServer == currentServer;
  }

  /// 服务器配置就绪后的队列归属补校验（MainScreen.initState 调用）：
  /// 冷启动时队列可能在 configure 前就被恢复，若队列属于旧服务器则清空。
  Future<void> validateQueueForServer() async {
    if (_queue.isEmpty) return;
    if (await _queueMatchesCurrentServer()) return;
    debugPrint(
        '[Player] validateQueueForServer: queue belongs to another server — '
        'clearing ${_queue.length} songs');
    clearQueue();
  }

  void _clearPersistedQueue() {
    _persistDebounceTimer?.cancel();
    try {
      SharedPreferences.getInstance().then((p) {
        p.remove(_keyQueue);
        p.remove(_keyQueueIndex);
        p.remove(_keyQueueSongId);
        p.remove(_keyQueuePosition);
        p.remove(_keyQueueServer);
      });
    } catch (_) {}
  }

  void setLibraryProvider(LibraryProvider libraryProvider) {
    _libraryProvider = libraryProvider;
  }

  /// Resolves the cover art id for a song, normalized to the album cover so
  /// every song of an album shares one cache key (see
  /// [LibraryProvider.effectiveCoverArt]).
  String _effectiveCoverId(Song song) {
    return _libraryProvider?.effectiveCoverArt(song) ??
        song.coverArt ??
        song.id;
  }

  void setRecommendationService(RecommendationService recommendationService) {
    _recommendationService = recommendationService;
    _autoDjService.setServices(_subsonicService, recommendationService);
  }

  AutoDjService get autoDjService => _autoDjService;
  LockScreenLyricsService get lyricsService => _lyricsService;

  Future<void> _initializeAutoDj() async {
    await _autoDjService.initialize();
    _autoDjService.setServices(_subsonicService, _recommendationService);
  }

  Future<void> _initializeLyricsService() async {
    await _lyricsService.initialize();
  }

  Future<void> _initializeSystemServices() async {
    await _androidSystemService.initialize();
    _androidSystemService.onPlay = play;
    _androidSystemService.onPause = pause;
    _androidSystemService.onStop = stop;
    _androidSystemService.onSkipNext = skipNext;
    _androidSystemService.onSkipPrevious = skipPrevious;
    _androidSystemService.onSeekTo = seek;
    _androidSystemService.onSeekForward =
        (interval) => seek(_position + interval);
    _androidSystemService.onSeekBackward = (interval) {
      final target = _position - interval;
      seek(target.isNegative ? Duration.zero : target);
    };
    _androidSystemService.onHeadsetHook = togglePlayPause;
    _androidSystemService.onHeadsetDoubleClick = skipNext;

    await _windowsService.initialize();
    _windowsService.onPlay = play;
    _windowsService.onPause = pause;
    _windowsService.onStop = stop;
    _windowsService.onSkipNext = skipNext;
    _windowsService.onSkipPrevious = skipPrevious;
    _windowsService.onSeekTo = seek;

    // Audio focus and noisy callbacks must be no-ops in remote-playback mode.
    // The audio is playing on the renderer device, not on this phone, so
    // Android reassigning audio focus at screen-off (or a noisy event) must
    // not pause the renderer.
    _androidSystemService.onAudioFocusLoss = () {
      if (isRemotePlayback) return;
      pause();
    };
    _androidSystemService.onAudioFocusLossTransient = () {
      if (isRemotePlayback) return;
      pause();
    };
    _androidSystemService.onAudioFocusLossTransientCanDuck = () {
      if (isRemotePlayback) return;
      _smoothVolumeChange(0.3);
    };
    _androidSystemService.onAudioFocusGain = () {
      if (isRemotePlayback) return;
      _smoothVolumeChange(_volume);
    };
    _androidSystemService.onBecomingNoisy = () {
      if (isRemotePlayback) return;
      pause();
    };

    await _bluetoothService.initialize();
    _bluetoothService.onPlay = play;
    _bluetoothService.onPause = pause;
    _bluetoothService.onStop = stop;
    _bluetoothService.onSkipNext = skipNext;
    _bluetoothService.onSkipPrevious = skipPrevious;
    _bluetoothService.onSeekTo = seek;
    _bluetoothService.onDeviceConnected = (device) {
      debugPrint('Bluetooth device connected: ${device.name}');
      // AVRCP support means the device can handle audio controls, which is
      // a reliable proxy for A2DP audio output (watches/controllers don't
      // advertise AVRCP). Re-query isA2dpConnected for ground truth.
      _bluetoothService.isA2dpConnected().then((active) {
        _isA2dpAudioActive = active;
        debugPrint('Bluetooth A2DP audio active: $_isA2dpAudioActive');
      });
      _updateAllServices();
    };
    _bluetoothService.onDeviceDisconnected = (device) {
      debugPrint('Bluetooth device disconnected: ${device.name}');
      _bluetoothService.isA2dpConnected().then((active) {
        _isA2dpAudioActive = active;
        debugPrint('Bluetooth A2DP audio active: $_isA2dpAudioActive');
      });
    };

    _bluetoothService.registerAbsoluteVolumeControl();

    _samsungService.initialize();
    _samsungService.onDexModeEnter = () {
      debugPrint('Entered Samsung DeX mode');
      notifyListeners();
    };
    _samsungService.onDexModeExit = () {
      debugPrint('Exited Samsung DeX mode');
      notifyListeners();
    };
    _samsungService.onEdgePanelAction = (action) {
      switch (action) {
        case 'play':
          play();
          break;
        case 'pause':
          pause();
          break;
        case 'next':
          skipNext();
          break;
        case 'previous':
          skipPrevious();
          break;
      }
    };
  }

  void _initializeAndroidAuto() {
    // 先接线回调、再订阅事件通道：initialize() 会订阅 EventChannel 并拉起
    // MusicService，车机按键可能在订阅建立的瞬间到达，回调未就绪会被丢弃。
    _androidAutoService.onPlay = play;
    _androidAutoService.onPause = pause;
    _androidAutoService.onStop = stop;
    _androidAutoService.onSkipNext = skipNext;
    _androidAutoService.onSkipPrevious = skipPrevious;
    _androidAutoService.onSeekTo = seek;
    _androidAutoService.onPlayFromMediaId = _playFromMediaId;
    _androidAutoService.onSetVolume = _onRemoteVolumeChange;

    _androidAutoService.onGetAlbumSongs = _getAlbumSongsForAndroidAuto;
    _androidAutoService.onGetArtistAlbums = _getArtistAlbumsForAndroidAuto;
    _androidAutoService.onGetPlaylistSongs = _getPlaylistSongsForAndroidAuto;
    _androidAutoService.onSearch = _searchForAndroidAuto;
    _androidAutoService.onPlayFromSearch = _playFromSearchForAndroidAuto;
    _androidAutoService.onRequestLibraryData = _onRequestLibraryData;

    _androidAutoService.initialize();
  }

  void _onRequestLibraryData() {
    debugPrint(
        'PlayerProvider: Android Auto requested library data, delegating to LibraryProvider');
    // The LibraryProvider handles this in its constructor, but we add this
    // as a fallback to ensure the request is handled
    if (_libraryProvider != null) {
      // Trigger a re-push of library data via the LibraryProvider
      // This is handled by the callback registered in LibraryProvider's constructor
    }
  }

  Future<List<Map<String, String>>> _getAlbumSongsForAndroidAuto(
    String albumId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final offlineSongs = _libraryProvider!.cachedAllSongs
          .where((s) => s.albumId == albumId && downloadedIds.contains(s.id))
          .toList();
      if (offlineSongs.isNotEmpty) {
        return offlineSongs
            .map(
              (song) => {
                'id': song.id,
                'title': song.title,
                'artist': song.artist ?? '',
                'album': song.album ?? '',
                'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) !=
                        null
                    ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                        .toString()
                    : _subsonicService.getCoverArtUrl(song.coverArt),
                'duration': (song.duration ?? 0).toString(),
              },
            )
            .toList();
      }
    }
    try {
      final songs = await _subsonicService.getAlbumSongs(albumId);
      return songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting album songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getArtistAlbumsForAndroidAuto(
    String artistId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final albumIdsWithDownloads = _libraryProvider!.cachedAllSongs
          .where((s) => s.artistId == artistId && downloadedIds.contains(s.id))
          .map((s) => s.albumId)
          .whereType<String>()
          .toSet();
      final offlineAlbums = _libraryProvider!.cachedAllAlbums
          .where((a) => albumIdsWithDownloads.contains(a.id))
          .toList();
      if (offlineAlbums.isNotEmpty) {
        return offlineAlbums
            .map(
              (album) => {
                'id': album.id,
                'name': album.name,
                'artist': album.artist ?? '',
                'artworkUrl': _subsonicService.getCoverArtUrl(
                  album.coverArt,
                  size: 300,
                ),
              },
            )
            .toList();
      }
    }
    try {
      final albums = await _subsonicService.getArtistAlbums(artistId);
      return albums
          .map(
            (album) => {
              'id': album.id,
              'name': album.name,
              'artist': album.artist ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                album.coverArt,
                size: 300,
              ),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting artist albums for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _getPlaylistSongsForAndroidAuto(
    String playlistId,
  ) async {
    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final cachedPlaylist = _libraryProvider!.playlists
          .where((p) => p.id == playlistId)
          .firstOrNull;
      if (cachedPlaylist?.songs != null && cachedPlaylist!.songs!.isNotEmpty) {
        final offlineSongs = cachedPlaylist.songs!
            .where((s) => downloadedIds.contains(s.id))
            .toList();
        if (offlineSongs.isNotEmpty) {
          return offlineSongs
              .map(
                (song) => {
                  'id': song.id,
                  'title': song.title,
                  'artist': song.artist ?? '',
                  'album': song.album ?? '',
                  'artworkUrl': _offlineService.getLocalCoverArtPath(song.id) !=
                          null
                      ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                          .toString()
                      : _subsonicService.getCoverArtUrl(song.coverArt,
                          size: 300),
                  'duration': (song.duration ?? 0).toString(),
                },
              )
              .toList();
        }
      }
    }
    try {
      final playlist = await _subsonicService.getPlaylist(playlistId);
      final songs = playlist.songs ?? [];
      return songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Error getting playlist songs for Android Auto: $e');
      return [];
    }
  }

  Future<List<Map<String, String>>> _searchForAndroidAuto(
    String query,
  ) async {
    debugPrint(
        'PlayerProvider: _searchForAndroidAuto called with query="$query"');
    debugPrint(
        'PlayerProvider: isOfflineMode=${_offlineService.isOfflineMode}, libraryProvider=$_libraryProvider');

    if (_offlineService.isOfflineMode && _libraryProvider != null) {
      await _offlineService.initialize();
      final downloadedIds = _offlineService.getDownloadedSongIds().toSet();
      final lowerQuery = query.toLowerCase();
      final offlineResults = _libraryProvider!.cachedAllSongs
          .where(
            (s) =>
                downloadedIds.contains(s.id) &&
                (s.title.toLowerCase().contains(lowerQuery) ||
                    (s.artist?.toLowerCase().contains(lowerQuery) ?? false) ||
                    (s.album?.toLowerCase().contains(lowerQuery) ?? false)),
          )
          .take(20)
          .toList();
      return offlineResults
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl':
                  _offlineService.getLocalCoverArtPath(song.id) != null
                      ? Uri.file(_offlineService.getLocalCoverArtPath(song.id)!)
                          .toString()
                      : _subsonicService.getCoverArtUrl(song.coverArt),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    }
    try {
      debugPrint(
          'PlayerProvider: Calling subsonicService.search with query="$query"');
      final results = await _subsonicService.search(
        query,
        songCount: 20,
        albumCount: 0,
        artistCount: 0,
      );
      debugPrint(
          'PlayerProvider: Search returned ${results.songs.length} songs');
      return results.songs
          .map(
            (song) => {
              'id': song.id,
              'title': song.title,
              'artist': song.artist ?? '',
              'album': song.album ?? '',
              'artworkUrl': _subsonicService.getCoverArtUrl(
                song.coverArt,
                size: 300,
              ),
              'duration': (song.duration ?? 0).toString(),
            },
          )
          .toList();
    } catch (e, stackTrace) {
      debugPrint('PlayerProvider: Android Auto search error: $e');
      debugPrint('PlayerProvider: Stack trace: $stackTrace');
      return [];
    }
  }

  Future<void> _playFromSearchForAndroidAuto(String query) async {
    debugPrint('Android Auto: playFromSearch called with query: "$query"');
    try {
      if (query.trim().isEmpty) {
        if (_currentSong != null) {
          await play();
        } else if (_libraryProvider != null &&
            _libraryProvider!.randomSongs.isNotEmpty) {
          final songs = _libraryProvider!.randomSongs;
          await playSong(songs.first, playlist: songs, startIndex: 0);
        }
        return;
      }

      final results = await _subsonicService.search(
        query,
        songCount: 20,
        albumCount: 0,
        artistCount: 0,
      );
      if (results.songs.isNotEmpty) {
        await playSong(
          results.songs.first,
          playlist: results.songs,
          startIndex: 0,
        );
      } else {
        debugPrint('Android Auto: no search results for "$query"');
      }
    } catch (e) {
      debugPrint('Android Auto: playFromSearch error: $e');
    }
  }

  Future<void> _playFromMediaId(String mediaId) async {
    debugPrint('Android Auto: playFromMediaId called with: $mediaId');

    final queueIndex = _queue.indexWhere((song) => song.id == mediaId);
    if (queueIndex != -1) {
      await skipToIndex(queueIndex);
      return;
    }

    if (_libraryProvider != null) {
      final randomSongs = _libraryProvider!.randomSongs;
      final songIndex = randomSongs.indexWhere((song) => song.id == mediaId);
      if (songIndex != -1) {
        await playSong(
          randomSongs[songIndex],
          playlist: randomSongs,
          startIndex: songIndex,
        );
        return;
      }
    }

    try {
      final searchResults = await _subsonicService.search(
        mediaId,
        songCount: 5,
      );
      if (searchResults.songs.isNotEmpty) {
        final song = searchResults.songs.firstWhere(
          (s) => s.id == mediaId,
          orElse: () => searchResults.songs.first,
        );
        await playSong(song);
        return;
      }

      debugPrint('Android Auto: Could not find song with id: $mediaId');
    } catch (e) {
      debugPrint('Android Auto: Error fetching song: $e');
    }
  }

  String? _resolveArtworkUrl() {
    if (_currentSong == null) return null;
    if (_currentSong!.coverArt == null) return null;
    if (_currentSong!.isLocal) {
      return Uri.file(_currentSong!.coverArt!).toString();
    }

    return _resolvedArtworkUrl;
  }

  Future<void> _refreshArtworkUrl() async {
    final song = _currentSong;
    if (song == null || song.coverArt == null) {
      _resolvedArtworkUrl = null;
      return;
    }
    if (song.isLocal) {
      _resolvedArtworkUrl = Uri.file(song.coverArt!).toString();
      return;
    }

    await _offlineService.initialize();

    final localPath = _offlineService.getLocalCoverArtPath(song.id);
    if (localPath != null) {
      _resolvedArtworkUrl = Uri.file(localPath).toString();
      if (_currentSong?.id == song.id) _updateAllServices();
      return;
    }

    final coverArtId = song.coverArt!;

    // Search for cached artwork from highest to lowest quality for iOS Now
    // Playing / Control Center. Lookups use the semantic cover-cache key
    // (coverArt-<serverId>-<id>-<size>) so they hit whatever variant a previous
    // session downloaded (previously keyed by URL, these lookups always missed
    // and forced a fresh 600px download on every track change).
    for (final sz in [1200, 800, 600, 400, 300, 200]) {
      final key = coverArtCacheKey(coverArtId, size: sz);
      try {
        final fileInfo = await coverCacheManager.getFileFromCache(key);
        if (fileInfo != null && fileInfo.file.existsSync()) {
          if (_currentSong?.id == song.id) {
            _resolvedArtworkUrl = Uri.file(fileInfo.file.path).toString();
            _updateAllServices();
          }
          return;
        }
      } catch (_) {}
    }
    // Request high quality for iOS Now Playing bar / Control Center (1200px)
    final serverUrl = _subsonicService.getCoverArtUrl(coverArtId);

    if (!_offlineService.isOfflineMode) {
      _resolvedArtworkUrl = serverUrl;
      if (_currentSong?.id == song.id) _updateAllServices();
    }
  }

  void _updateAndroidAuto() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _androidAutoService.updatePlaybackState(
      songId: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist ?? '',
      album: _currentSong!.album ?? '',
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
    );

    // Update the audio_service handler so lock screen / Control Center / iOS
    // Now Playing info stays accurate regardless of the UI lifecycle.
    _audioHandler.updateNowPlaying(
      id: _currentSong!.id,
      title: _currentSong!.title,
      artist: _currentSong!.artist,
      album: _currentSong!.album,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
    );

    _updateDiscordRpc();
    _updateAllServices();
  }

  void _updateAllServices() {
    if (_currentSong == null) return;

    final artworkUrl = _resolveArtworkUrl();

    final effectiveDuration = _duration.inMilliseconds > 0
        ? _duration
        : Duration(seconds: _currentSong!.duration ?? 0);

    _androidSystemService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    _windowsService.updatePlaybackState(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
    );

    _bluetoothService.updateFromSong(
      song: _currentSong!,
      artworkUrl: artworkUrl,
      duration: effectiveDuration,
      position: _position,
      isPlaying: _isPlaying,
      currentIndex: _currentIndex,
      queueLength: _queue.length,
    );

    if (_samsungService.isSamsungDevice) {
      _samsungService.updateFromSong(
        song: _currentSong!,
        artworkUrl: artworkUrl,
        duration: effectiveDuration,
        position: _position,
        isPlaying: _isPlaying,
      );
    }
  }

  bool get isSamsungDevice => _samsungService.isSamsungDevice;
  bool get isDexMode => _samsungService.isDexMode;
  bool get hasBluetoothDevice => _bluetoothService.hasConnectedDevices;
  List<BluetoothDeviceInfo> get connectedBluetoothDevices =>
      _bluetoothService.connectedDevices;

  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  bool get isPlaying => _isPlaying;
  bool get isLoading => _isLoading;

  /// Actual transcode state of the current stream (captured when the stream
  /// URL was built). See [_activeStreamBitrate].
  int? get activeStreamBitrate => _activeStreamBitrate;
  String? get activeStreamFormat => _activeStreamFormat;
  bool get isActiveStreamTranscoded =>
      _activeStreamBitrate != null || _activeStreamFormat != null;

  void _setActiveStream(int? maxBitRate, String? format) {
    // 转码判定：明确码率（>0）或非 raw 的显式编码都算转码——format-only
    // 的转码（如 format=mp3 用服务端默认码率）同样会得到无 Content-Length
    // 的 chunked 流，seek 行为与码率转码一致。
    final applied = (maxBitRate != null && maxBitRate > 0) ||
        (format != null && format != TranscodeFormat.original);
    _activeStreamBitrate = applied ? maxBitRate : null;
    _activeStreamFormat = applied ? format : null;
    DiagnosticsService.instance.record(
      EventType.streamUrl,
      LogLevel.info,
      {
        'songId': _currentSong?.id,
        'maxBitRate': _activeStreamBitrate,
        'format': _activeStreamFormat,
        'transcoded': applied,
      },
    );
  }

  /// True when audio is playing on a remote renderer (UPnP or Cast) rather
  /// than locally.  Used to suppress audio-focus and noisy-event handling that
  /// would incorrectly pause the remote device, and to route UI volume changes
  /// to the renderer instead of the Android system volume.
  bool get isRemotePlayback => _isRenderingRemotely;

  /// 当前请求是否会让道理鱼走转码流。道理鱼转码流是 chunked（无
  /// Content-Length）且 seek 必须靠自研 /api 层 timeOffset 重起流，无法走
  /// 无缝 concat 预建（预建会立即并发拉取整队列转码流），播放入口据此强制
  /// 单曲模式；seek 由 [_restartDaoliyuStream] 处理。
  bool get _isDaoliyuTranscodeRequested {
    if (!_subsonicService.isDaoliyu) return false;
    return (_transcodingService.getCurrentBitrate() ?? 0) > 0 ||
        _transcodingService.getCurrentFormat() != null;
  }

  /// 道理鱼感知的流 URL 构建（playSong / _prepareCurrentSong 共用）：转码场景
  /// 优先自研 /api/tracks/{id}/stream（JWT + timeOffset 重起流），JWT 失败回退
  /// Subsonic 转码 URL（seek 不可用、从头播）；非转码场景走常规 getStreamUrl
  ///（道理鱼下无转码参数时为 format=raw 直出）。
  /// [viaTimeOffset] 为 true 表示实际使用了自研 timeOffset 流——调用方据此决定
  /// 恢复位置用基准偏移（_streamBaseOffsetMs）还是原生 seek。
  Future<({String url, bool viaTimeOffset})> _buildDaoliyuAwareStreamUrl(
    Song song, {
    int? maxBitRate,
    String? format,
    int timeOffsetSeconds = 0,
  }) async {
    if (_isDaoliyuTranscodeRequested) {
      final apiUrl = await _subsonicService.getDaoliyuApiStreamUrl(song.id,
          timeOffsetSeconds: timeOffsetSeconds);
      if (apiUrl != null) {
        return (url: apiUrl, viaTimeOffset: true);
      }
    }
    return (
      url: _subsonicService.getStreamUrl(song.id,
          maxBitRate: maxBitRate, format: format),
      viaTimeOffset: false,
    );
  }

  bool get shuffleEnabled => _shuffleEnabled;
  bool get gaplessEnabled => _gaplessEnabled;
  RepeatMode get repeatMode => _repeatMode;
  Duration get position => _position;
  Duration get duration => _duration;

  /// Track duration for progress UI. Falls back to the server-reported
  /// metadata when the player can't resolve it (e.g. on-the-fly transcoded
  /// streams with unknown Content-Length).
  Duration get effectiveDuration {
    if (_duration.inMilliseconds > 0) return _duration;
    final song = _currentSong;
    if (song != null && song.duration != null && song.duration! > 0) {
      return Duration(seconds: song.duration!);
    }
    return _duration;
  }

  Song? get currentSong => _currentSong;
  bool get hasNext =>
      _queue.isNotEmpty &&
      (_currentIndex < _queue.length - 1 ||
          _repeatMode == RepeatMode.all ||
          (_shuffleEnabled && _queue.length > 1));
  bool get hasPrevious =>
      _queue.isNotEmpty &&
      (_currentIndex > 0 ||
          _repeatMode == RepeatMode.all ||
          (_shuffleEnabled && _shuffleHistory.isNotEmpty));
  double get volume => _volume;

  RadioStation? get currentRadioStation => _currentRadioStation;
  bool get isPlayingRadio => _isPlayingRadio;

  /// 是否正在播放有声书（§8.1）。单一 gate：歌词短路 / 统计隔离 /
  /// 队列持久化 / 车载守卫 / shuffle/repeat 全按此判断。
  bool get isPlayingAudiobook => _isPlayingAudiobook;

  /// 当前播放的有声书（进度记忆的归属）。
  Audiobook? get currentAudiobook => _currentAudiobook;

  /// 当前章节 order（1-based）。详情页据此实时高亮正在播放的章节行。
  int? get audiobookChapterOrder => _audiobookChapterOrder;

  // Unified position stream: fed by the local audio player in normal mode, or
  // by UPnP/Cast polling in remote-playback mode.  The UI subscribes to this
  // instead of directly to _audioPlayer.positionStream so that the progress
  // bar animates correctly regardless of which playback path is active.
  final _positionController = StreamController<Duration>.broadcast();
  Stream<Duration> get positionStream => _positionController.stream;

  // Subscriptions stored so they can be cancelled before dispose closes the
  // StreamController, preventing a late just_audio tick from calling add() on
  // a closed controller.
  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;
  StreamSubscription<int?>? _currentIndexSub;
  StreamSubscription<Set<AudioDevice>>? _devicesSub;

  ConcatenatingAudioSource? _concatenatingSource;

  /// 道理鱼转码流 seek 重起流后的时间偏移基准（毫秒）。正常播放/切歌为 0；
  /// 重起一条带 timeOffset=X 的自研流后，ExoPlayer 的位置从 0 计起，而歌曲
  /// 实际位置 = 流位置 + 基准。位置流/Windows 轮询据此换算显示位置。
  int _streamBaseOffsetMs = 0;

  /// 道理鱼转码 seek 重起流的竞态令牌：每次重起/切歌自增，异步流程在提交
  /// 前校验令牌，被更新的操作取代（连续快速拖动、切歌中途）时直接放弃。
  int _seekRestartToken = 0;

  /// 最近一次 seek() 请求的目标位置（道理鱼转码重起流被更新 seek 取代后，
  /// 以它作为重新起流的目标；position 流 tick 会覆盖 [_position]，不能复用）。
  Duration _lastSeekRequest = Duration.zero;

  // Fallback timer for Windows where positionStream may not emit reliably
  Timer? _windowsPositionTimer;
  Duration? _lastPolledPosition;

  double get progress {
    final duration = effectiveDuration;
    if (duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / duration.inMilliseconds;
  }

  double get playbackSpeed => _playbackSpeed;

  double get pitch => _pitch;

  bool get pitchCorrection => _pitchCorrection;

  Future<void> setPlaybackSpeed(double speed) async {
    _playbackSpeed = speed.clamp(0.25, 4.0);

    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      // Fallback to just_audio native setSpeed when pitch plugin is unavailable.
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  Future<void> togglePitchCorrection() async {
    _pitchCorrection = !_pitchCorrection;
    final targetPitch = _pitchCorrection ? 1.0 : _playbackSpeed;
    _pitch = targetPitch.clamp(0.5, 2.0);

    final success = await _audioHandler.setPlaybackParameters(
      _playbackSpeed,
      _pitch,
    );
    if (!success) {
      await _audioPlayer.setSpeed(_playbackSpeed);
    }

    notifyListeners();
  }

  bool get hasSleepTimer => _sleepTimer != null;
  bool get sleepTimerEndCurrentSong => _sleepTimerEndCurrentSong;
  bool get sleepTimerFadeOut => _sleepTimerFadeOut;
  int get sleepTimerFadeDurationSeconds => _sleepTimerFadeDurationSeconds;

  Duration? get sleepTimerRemaining {
    if (_sleepTimerEnd == null) return null;
    final remaining = _sleepTimerEnd!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  void setSleepTimer(
    Duration duration, {
    bool endCurrentSong = false,
    bool fadeOut = false,
    int fadeDurationSeconds = 30,
  }) {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerEndCurrentSong = endCurrentSong;
    _sleepTimerFadeOut = fadeOut;
    _sleepTimerFadeDurationSeconds = fadeDurationSeconds;

    if (duration > Duration.zero) {
      _sleepTimerEnd = DateTime.now().add(duration);

      if (fadeOut) {
        final fadeStart = duration - Duration(seconds: fadeDurationSeconds);
        if (fadeStart > Duration.zero) {
          _sleepTimerFadeTimer =
              Timer(fadeStart, () => _startFadeOut(fadeDurationSeconds));
        } else {
          _startFadeOut(fadeDurationSeconds);
        }
      }

      _sleepTimer = Timer(duration, () {
        if (endCurrentSong) {
          _sleepTimerEndCurrentSong = true;
          _sleepTimer = null;
          _sleepTimerEnd = null;
          notifyListeners();
        } else {
          _doSleepTimerStop();
        }
      });
    }
    notifyListeners();
  }

  void _startFadeOut([int fadeDurationSeconds = 30]) {
    _sleepTimerFadePeriodicTimer?.cancel();
    final steps = fadeDurationSeconds.clamp(5, 300);
    const stepDuration = Duration(seconds: 1);
    final originalVolume = _volume;
    int step = 0;
    _sleepTimerFadePeriodicTimer = Timer.periodic(stepDuration, (t) {
      step++;
      final newVolume = originalVolume * (1.0 - step / steps);
      _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
      if (step >= steps) {
        t.cancel();
        _sleepTimerFadePeriodicTimer = null;
      }
    });
  }

  void _doSleepTimerStop() {
    _sleepTimerFadePeriodicTimer?.cancel();
    _sleepTimerFadePeriodicTimer = null;
    _audioPlayer.setVolume(_volume);
    pause();
    _sleepTimer = null;
    _sleepTimerEnd = null;
    _sleepTimerFadeOut = false;
    _sleepTimerFadeDurationSeconds = 30;
    _sleepTimerEndCurrentSong = false;
    notifyListeners();
  }

  void _initializePlayer() {
    _configureAudioSession();

    _storageService.getVolume().then((savedVolume) {
      _volume = savedVolume;
      _audioPlayer.setVolume(_volume);
      notifyListeners();
    });

    _storageService.getShuffleMode().then((saved) {
      _shuffleEnabled = saved;
      notifyListeners();
    });

    _storageService.getRepeatMode().then((saved) {
      _repeatMode =
          RepeatMode.values[saved.clamp(0, RepeatMode.values.length - 1)];
      notifyListeners();
    });

    _storageService.getGaplessPlayback().then((saved) {
      _gaplessEnabled = saved;
      notifyListeners();
    });

    _playerStateSub = _audioPlayer.playerStateStream.listen(
      (state) {
        // In remote-playback mode the local player is stopped/paused; ignore
        // its state so it doesn't overwrite the UPnP/Cast-managed values.
        if (_isRenderingRemotely) return;

        final wasPlaying = _isPlaying;
        _isPlaying = state.playing;

        if (wasPlaying != _isPlaying && !_reactivatingSession) {
          final stateLabel = _isPlaying ? '▶ Playing' : '⏸ Paused';
          final songLabel = _currentSong?.title ?? 'unknown';
          Log.i('Player',
              '$stateLabel — "$songLabel" (${state.processingState.name})');

          // Start/stop Windows position polling timer
          if (_isPlaying && Platform.isWindows && !_isRenderingRemotely) {
            _windowsPositionTimer?.cancel();
            _lastPolledPosition = null;
            _windowsPositionTimer = Timer.periodic(
              const Duration(milliseconds: 500),
              (_) {
                final pos = _audioPlayer.position;
                // 与 positionStream 一致：道理鱼转码重起流后加基准偏移。
                final effective = _streamBaseOffsetMs > 0
                    ? Duration(
                        milliseconds: pos.inMilliseconds + _streamBaseOffsetMs)
                    : pos;
                if (_lastPolledPosition == null ||
                    effective.inMilliseconds !=
                        _lastPolledPosition!.inMilliseconds) {
                  _lastPolledPosition = effective;
                  _position = effective;
                  _positionController.add(effective);
                  notifyListeners();
                  _updateAllServices();
                }
              },
            );
          } else {
            _windowsPositionTimer?.cancel();
            _windowsPositionTimer = null;
            _lastPolledPosition = null;
          }
        }

        if (state.processingState == ProcessingState.completed) {
          Log.i('Player',
              '✓ Song completed: "${_currentSong?.title ?? 'unknown'}"');
          // Capture the song synchronously: [_onSongComplete] runs async and
          // the user may skip to another track before it executes.
          _completedSong = _currentSong;
          _onSongComplete().catchError(
              (e) => Log.e('Player', '_onSongComplete error', error: e));
        }

        if (state.processingState == ProcessingState.buffering &&
            _bufferStartAt == null) {
          Log.i('Player', '⟳ Buffering: "${_currentSong?.title ?? 'unknown'}"');
          _bufferStartAt = DateTime.now();
          // 播放中卡顿判定：已在播放且位置已推进（排除加载新曲场景）
          final isStall = wasPlaying && _position.inSeconds >= 1;
          DiagnosticsService.instance.record(
            EventType.audioBuffer,
            LogLevel.info,
            {
              'event': 'start',
              'stall': isStall,
              'songId': _currentSong?.id,
            },
          );
          if (isStall) {
            DiagnosticsService.instance.record(
              EventType.audioStall,
              LogLevel.warn,
              {'songId': _currentSong?.id},
            );
          }
        }
        if (state.processingState != ProcessingState.buffering &&
            _bufferStartAt != null) {
          final bufferedMs =
              DateTime.now().difference(_bufferStartAt!).inMilliseconds;
          _bufferStartAt = null;
          DiagnosticsService.instance.record(
            EventType.audioBuffer,
            LogLevel.info,
            {
              'event': 'end',
              'bufferedMs': bufferedMs,
              'songId': _currentSong?.id,
            },
          );
        }

        if (wasPlaying != _isPlaying && !_reactivatingSession) {
          notifyListeners();
          _updateAndroidAuto();
        }
      },
      onError: (error) {
        Log.e('Player', 'State stream error', error: error);
        DiagnosticsService.instance.record(
          EventType.audioError,
          LogLevel.error,
          {
            'error': '$error',
            'songId': _currentSong?.id,
            'netSessionId': DiagnosticsService.instance.netSessionId,
          },
        );
      },
    );

    Duration? lastNotified;
    Duration? lastSystemUpdate;
    Duration? lastAudiobookSave;
    _positionSub = _audioPlayer.positionStream.listen(
      (position) {
        // In remote-playback mode the local player sits idle at position zero;
        // ignore its ticks so they don't overwrite the UPnP/Cast position.
        if (_isRenderingRemotely) return;

        // 道理鱼转码流 seek 重起后是从 timeOffset 起播的新流，播放器位置从
        // 0 计起，加上基准偏移才是歌曲真实位置。
        final effective = _streamBaseOffsetMs > 0
            ? Duration(
                milliseconds: position.inMilliseconds + _streamBaseOffsetMs)
            : position;

        final positionJumpedBack = _position.inMilliseconds > 0 &&
            effective.inMilliseconds < _position.inMilliseconds - 1000;

        _position = effective;
        _positionController.add(effective);

        if (positionJumpedBack ||
            lastNotified == null ||
            effective.inMilliseconds - lastNotified!.inMilliseconds > 250) {
          lastNotified = effective;
          notifyListeners();
        }

        if (lastSystemUpdate == null ||
            (effective.inMilliseconds - lastSystemUpdate!.inMilliseconds)
                    .abs() >
                1000) {
          lastSystemUpdate = effective;
          _updateAllServices();
          _saveQueueState();
          // 有声书进度写入（位置流 5s 节流，§9.2-1）——顺手存 chapterOrder/
          // chapterId；positionMs > 本章时长×95% 时推进 chapterOrder。
          // 单独用比 _saveQueueState 更长的间隔：进度存的是整表快照，1s 粒度
          // 会造成持续磁盘写放大；暂停/退后台/切章/播完另有写入路径，5s 不丢进度。
          if (lastAudiobookSave == null ||
              (effective.inMilliseconds - lastAudiobookSave!.inMilliseconds)
                      .abs() >
                  5000) {
            lastAudiobookSave = effective;
            _saveAudiobookProgress();
          }
        }
      },
      onError: (error) {
        debugPrint('Position stream error (can be ignored): $error');
      },
    );

    _durationSub = _audioPlayer.durationStream.listen(
      (duration) {
        // In remote-playback mode the local player has no loaded track; ignore
        // its duration so it doesn't zero out the UPnP/Cast duration.
        if (_isRenderingRemotely) return;

        _duration = duration ?? Duration.zero;
        notifyListeners();
        _updateAndroidAuto();
      },
      onError: (error) {
        debugPrint('Duration stream error (can be ignored): $error');
      },
    );

    _currentIndexSub = _audioPlayer.currentIndexStream.listen(
      (index) {
        if (index != null &&
            index != _currentIndex &&
            !_isRenderingRemotely &&
            _concatenatingSource != null) {
          _onCurrentIndexChanged(index).catchError((e) {
            debugPrint('[Player] _onCurrentIndexChanged error: $e');
          });
        }
      },
      onError: (error) {
        debugPrint('Current index stream error (can be ignored): $error');
      },
    );
  }

  Future<void> _configureAudioSession() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
      debugPrint('[Player] AudioSession configured for music playback');
      DiagnosticsService.instance.record(
        EventType.audioSessionState,
        LogLevel.info,
        {'trigger': 'configure', 'config': 'music', 'platform': 'android'},
      );

      // 设备流变化（蓝牙断开/重连、耳机插拔）→ 记录路由变更。
      // 订阅是纯观测：只写日志，不干预播放；持有引用以便 dispose 取消。
      _devicesSub ??= session.devicesStream.listen(
        (_) => unawaited(_snapshotAudioRoute()),
        onError: (Object e) {
          debugPrint('[Player] Devices stream error (ignored): $e');
        },
      );

      // Listen for audio interruptions (another app takes audio focus)
      session.interruptionEventStream.listen((event) {
        DiagnosticsService.instance.record(
          EventType.audioInterruption,
          LogLevel.info,
          {'begin': event.begin, 'type': event.type.name},
        );
        // 方案 B（docs/音频打断处理技术方案.md §4.1）：Android 的库内打断处理
        // 已关闭（audio_handler.dart），这里是唯一决策点。
        unawaited(_handleInterruptionEvent(event));
      });

      // Listen for headphone/bluetooth disconnection
      session.becomingNoisyEventStream.listen((_) {
        DiagnosticsService.instance.record(
          EventType.audioNoisy,
          LogLevel.warn,
          {'device': 'becameNoisy'},
        );
        if (isRemotePlayback) return;
        pause();
      });
    } catch (e) {
      Log.e('Player', 'AudioSession 配置失败', error: e);
    }
  }

  /// 打断处理的**唯一入口**（方案 B：Android 侧 `just_audio` 的库内处理已关闭）。
  ///
  /// 决策由纯函数 [decideInterruption] 完成（可单测），这里只执行副作用。
  /// 背景：此前「暂停」由 App 层做（把音量压到 0），「恢复播放」却被库内抢走，
  /// 恢复路径不经过 `play()/_fadeIn()` ⇒ 音量停在 0，位置照走但完全无声。
  /// 详见 `docs/音频打断处理技术方案.md` §3.1。
  Future<void> _handleInterruptionEvent(AudioInterruptionEvent event) async {
    // 远程播放：本地播放器被有意暂停，不干预（沿用既有守卫语义）。
    if (isRemotePlayback) return;

    try {
      final decision = decideInterruption(
        begin: event.begin,
        type: event.type,
        isPlaying: _audioPlayer.playing,
        wasPlayingBeforeInterruption: _wasPlayingBeforeInterruption,
      );
      _wasPlayingBeforeInterruption = decision.wasPlayingBeforeInterruption;

      switch (decision.action) {
        case InterruptionAction.none:
          break;
        case InterruptionAction.duck:
          // 保持既有 duck 语义（直接设 0.3），不顺手改成渐变，避免扩大回归面。
          _audioPlayer.setVolume(0.3);
          break;
        case InterruptionAction.restoreVolume:
          _audioPlayer.setVolume(_volume);
          break;
        case InterruptionAction.pause:
          // skipFade：打断要立刻静音，不能留淡出尾巴（库内处理已关闭，没人替我们停）。
          // keepInterruptionResume：保留上面刚写入的标记，供打断结束后决定是否恢复。
          await pause(skipFade: true, keepInterruptionResume: true);
          break;
        case InterruptionAction.resume:
          // 走 App 层 play() ⇒ `_fadeIn()` 恢复音量（这正是方案 B 的目的）。
          await play();
          break;
      }
    } catch (e) {
      // 打断处理不得把异常抛进 zone（监听器是 unawaited 调用）：play() 的网络错误、
      // setVolume 失败等都应被吞掉并留痕，避免未捕获异步异常（code-review R4）。
      debugPrint('[Player] Interruption handling failed: $e');
      DiagnosticsService.instance.record(
        EventType.audioInterruption,
        LogLevel.warn,
        {
          'begin': event.begin,
          'type': event.type.name,
          'error': '$e',
        },
      );
    }
  }

  // ── 音频路由/会话诊断辅助 ─────────────────────────────────

  /// 退后台标记：paused/inactive 置位，resumed 清除。
  /// 用于区分「正常 play」与「退后台回前台后的首次 play」（无声高发窗口）。
  bool _wasBackgrounded = false;

  List<String> _lastAudioDevices = const [];

  /// 当前输出设备摘要（'name:type' 排序列表）；查询失败/超时返回 null。
  /// 设备查询在会话重建窗口可能挂起（曾导致会话快照事件延迟 2s 甚至丢失），
  /// 这里限时 300ms——快照埋点绝不阻塞在设备查询上。
  Future<List<String>?> _audioDevicesSummary() async {
    try {
      if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return null;
      final session = await AudioSession.instance;
      final devices =
          await session.getDevices().timeout(const Duration(milliseconds: 300));
      return devices.map((d) => '${d.name}:${d.type.name}').toList()..sort();
    } catch (_) {
      return null;
    }
  }

  /// 快照当前音频输出设备（audio_session 无 route 流，用 getDevices 对比）。
  Future<void> _snapshotAudioRoute() async {
    final names = await _audioDevicesSummary();
    if (names == null) return;
    if (!listEquals(names, _lastAudioDevices)) {
      DiagnosticsService.instance.record(
        EventType.audioRouteChanged,
        LogLevel.info,
        {'from': _lastAudioDevices.join(','), 'to': names.join(',')},
      );
      _lastAudioDevices = names;
    }
  }

  /// 会话/输出管线状态快照。只查询不干预：用于还原「播放无声」时间线，
  /// 尤其「退后台 → 回前台 → play」后位置前进但无输出的场景（playing 与
  /// 位置前进并不代表输出管线已重建）。
  Future<void> _recordAudioSessionState(
    String trigger, {
    Map<String, dynamic>? extra,
  }) async {
    if (kIsWeb) return;
    try {
      final devices = await _audioDevicesSummary();
      DiagnosticsService.instance.record(
        EventType.audioSessionState,
        LogLevel.info,
        {
          'trigger': trigger,
          'playerPlaying': _audioPlayer.playing,
          'processingState': _audioPlayer.processingState.name,
          'posMs': _audioPlayer.position.inMilliseconds,
          // idle 态下 duration 为 null（重载守卫漏判的关键证据，见 play()）。
          'durationMs': _audioPlayer.duration?.inMilliseconds,
          'volume': _audioPlayer.volume,
          'hasSource': _audioPlayer.audioSource != null,
          'songId': _currentSong?.id,
          'remotePlayback': _isRenderingRemotely,
          'afterResume': _wasBackgrounded,
          if (devices != null) 'devices': devices.join(','),
          if (extra != null) ...extra,
        },
      );
    } catch (_) {}
  }

  Future<void> _ensureAudioFocus() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final granted = await _androidSystemService.requestAudioFocus();
      debugPrint('[Player] Audio focus requested, granted=$granted');
    } catch (e) {
      debugPrint('[Player] Audio focus request failed: $e');
    }
  }

  /// Records how a song ended, exactly once per song:
  /// - listened to < 80%  → counted as a skip (does NOT increase play count)
  /// - listened to >= 80% → counted as a completed play
  void _recordSongEnd(Song song, int playedSeconds, int totalSeconds) {
    final service = _recommendationService;
    if (service == null) return;
    // Only the song that is actually playing right now can "end". A stale
    // completion event arriving after the user switched tracks must not
    // count the new song as played.
    if (_currentSong?.id != song.id) return;
    if (_trackedSongId == song.id) return;
    _trackedSongId = song.id;
    if (totalSeconds > 0 && playedSeconds < totalSeconds * 0.8) {
      service.trackSkip(song, secondsPlayed: playedSeconds);
    } else if (playedSeconds > 0 && (totalSeconds > 0 || playedSeconds >= 30)) {
      // When the track duration is unknown, require at least 30s of actual
      // listening before counting it as a play — otherwise a few seconds of
      // playback with an unresolved duration would count as a full play.
      service.trackSongPlay(
        song,
        durationPlayed: playedSeconds,
        completed: true,
      );
    }
  }

  Future<void> _onSongComplete() async {
    final completedSong = _completedSong ?? _currentSong;
    _completedSong = null;

    // A completion event is only valid for the song that was playing when it
    // fired. If the user already moved on (e.g. a manual skip raced with the
    // queued event), ignore it entirely — recording/scrobbling the current
    // song here would over-count it and advance the queue a second time.
    if (completedSong != null && completedSong.id != _currentSong?.id) {
      return;
    }

    // 有声书（B7/B3/B9）：不 scrobble、不记录歌曲统计；bookmark 推进。
    // sleepTimer endCurrentSong 检查保持原顺序（§14 编码注意：两种停止不冲突）。
    if (_isPlayingAudiobook) {
      final isLast = _currentIndex >= _queue.length - 1;
      final currentOrder = _audiobookChapterOrder ?? 1;
      // bookmark 推进到下一章；末章 → completed（保留条目，"已听完"显示）。
      _saveAudiobookChapterProgress(
        chapterOrder: isLast ? currentOrder : currentOrder + 1,
        positionMs: 0,
        completed: isLast,
      );

      if (_sleepTimerEndCurrentSong) {
        _doSleepTimerStop();
        return;
      }

      if (isLast) {
        // 末章播完：停止 + completed（不触发 AutoDJ/推荐续播，B7）。
        // C002 修复：先清空章节队列再解除 gate——stop 后位置 tick/退后台会
        // 触发 _saveQueueStateImmediate，若 gate 先解除、队列还在，章节会被
        // 写进 persistent_queue_*（冷启动当歌曲恢复）。
        // R005 修复：必须先清 gate（_clearAudiobookState）再 stop()，否则
        // stop() 开头的 _saveAudiobookProgress 会用 (last,0,completed:false)
        // 覆盖刚写入的 completed:true。
        _queue.clear();
        _currentIndex = -1;
        _currentSong = null;
        _concatenatingSource = null;
        // 复审 P3：一并复位 shuffle 状态，避免残留索引指向已清空的旧队列。
        _shuffleOrder = [];
        _shuffleOrderPos = 0;
        _clearAudiobookState(); // 播放结束 = 退出有声书（恢复 shuffle/repeat）
        await stop();
        _lyricsService.stopSync();
        await _lyricsService.loadLyrics(null);
      } else {
        await skipNext();
      }
      _cacheCleaner.prune();
      return;
    }

    if (completedSong != null && completedSong.isLocal != true) {
      _subsonicService.scrobble(completedSong.id, submission: true).catchError(
        (e) {
          _offlineService.queueScrobble(completedSong.id, submission: true);
        },
      );
    }

    if (completedSong != null) {
      _recordSongEnd(completedSong, _duration.inSeconds, _duration.inSeconds);
    }

    if (_sleepTimerEndCurrentSong) {
      _doSleepTimerStop();
      return;
    }

    if (_concatenatingSource != null) {
      // With ConcatenatingAudioSource this only fires at the very end
      // of the queue when LoopMode is off.
      if (_shuffleEnabled &&
          _repeatMode == RepeatMode.all &&
          _queue.length > 1) {
        // A shuffled round finished: rebuild with a fresh order instead of
        // looping the same sequence.
        await _restartShuffleRound();
      } else {
        await _handleEndOfQueue();
      }
      return;
    }

    // Fallback for single-song mode
    if (_repeatMode == RepeatMode.one ||
        (_repeatMode == RepeatMode.all && _queue.length == 1)) {
      await seek(Duration.zero);
      await play();
      // A new loop iteration is starting: allow the next completion of the
      // same song to be recorded again instead of being deduped away.
      _trackedSongId = null;
    } else if (_currentIndex < _queue.length - 1 ||
        _repeatMode == RepeatMode.all ||
        _shuffleEnabled) {
      await skipNext();
    } else {
      await _handleEndOfQueue();
    }

    // Prune the streaming cache after every song finishes to keep it
    // within the configured size limit.
    _cacheCleaner.prune();
  }

  Future<void> _handleEndOfQueue() async {
    // 有声书：末章播完不追加 AutoDJ 歌曲（B7/B16）。
    if (_isPlayingAudiobook) return;
    if (_autoDjService.isEnabled) {
      await _addAutoDjSongs();

      if (_currentIndex < _queue.length - 1) {
        await skipToIndex(_currentIndex + 1);
      }
    }
  }

  Future<void> playSong(
    Song song, {
    List<Song>? playlist,
    int? startIndex,
    bool forcePlay = false,
    bool audiobook = false,
    Audiobook? audiobookBook,
    int? resumePositionMs,
  }) async {
    // 从有声书切到普通歌/另一本有声书：先保存上一本的进度（§9.2-2）。
    if (_isPlayingAudiobook && !audiobook) {
      _saveAudiobookProgress();
      _restorePlaybackSettingsAfterAudiobook();
    }
    // Only treat tapping the currently-playing song as pause/resume when the
    // request comes from the UI. Automatic transitions (skipNext/skipToIndex)
    // pass forcePlay: true so a duplicate song id never replays the same track
    // via togglePlayPause.
    if (!forcePlay && _currentSong?.id == song.id && !_isPlayingRadio) {
      await togglePlayPause();
      return;
    }

    _isPlayingRadio = false;
    _currentRadioStation = null;

    // Reset the active-stream transcode snapshot; the URL builders below
    // re-capture whatever is actually applied to this song's stream.
    _setActiveStream(null, null);

    debugPrint(
        '[Player] ▶ playSong: "${song.title}" by ${song.artist ?? 'unknown'} (id=${song.id} local=${song.isLocal})');
    _isLoading = true;
    notifyListeners();

    try {
      if (playlist != null) {
        final isNewQueue = !identical(playlist, _queue);
        _queue = List.from(playlist);
        _currentIndex =
            startIndex ?? playlist.indexWhere((s) => s.id == song.id);
        if (_currentIndex == -1) _currentIndex = 0;
        if (isNewQueue) {
          _shuffleHistory.clear();
          if (_shuffleEnabled) _rebuildShuffleOrder();
        }
      } else if (_queue.isEmpty || !_queue.any((s) => s.id == song.id)) {
        _queue = [song];
        _currentIndex = 0;
        _shuffleHistory.clear();
      } else {
        _currentIndex = _queue.indexWhere((s) => s.id == song.id);
      }

      _currentSong = song;
      // 有声书：置位必须在队列设置后、_saveQueueState 之前（顺序不可反，
      // 否则 _saveQueueState 会把章节队列写进 persistent_queue_*，B1/B15）。
      _isPlayingAudiobook = audiobook;
      _currentAudiobook = audiobook ? audiobookBook : null;
      // 章节 order 存到 Song.track（audiobookChapterToSong 映射），bookmark 用。
      _audiobookChapterOrder = audiobook ? song.track : null;
      _resolvedArtworkUrl = null;
      // 恢复续播：resumePositionMs 直接赋给 _position，复用 _prepareCurrentSong
      // 的恢复 seek 路径（B5）。普通歌曲仍从 0 开始。
      _position = Duration(milliseconds: resumePositionMs ?? 0);
      // 新歌：清掉上一首的转码 seek 基准与竞态令牌，废弃仍在途的重起流。
      _streamBaseOffsetMs = 0;
      _seekRestartToken++;
      notifyListeners();
      _saveQueueState();

      await _refreshArtworkUrl();

      // Load lyrics for lock screen sync
      await _loadAndSyncLyrics(song);

      // Update song info for iOS Live Activity
      await _lyricsService.updateSongInfo(
        title: song.title,
        artist: song.artist ?? 'Unknown Artist',
        artworkUrl: _resolvedArtworkUrl ?? song.coverArt,
      );

      if (_castService.isConnected) {
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true
            ? Uri.file(song.path!).toString()
            : await _subsonicService.resolveStreamUrlAsync(song);
        final coverUrl = song.isLocal == true && song.coverArt != null
            ? song.coverArt!
            : _subsonicService.getCoverArtUrl(_effectiveCoverId(song));

        await _castService.loadMedia(
          url: playUrl,
          title: song.title,
          artist: song.artist ?? 'Unknown Artist',
          imageUrl: coverUrl,
          albumName: song.album,
          trackNumber: song.track,
          duration:
              song.duration != null ? Duration(seconds: song.duration!) : null,
          autoPlay: true,
        );
        _isRenderingRemotely = true;
        _isPlaying = true;
      } else if (_upnpService.isConnected) {
        // Reset before sending Stop so a poll that fires mid-load can't
        // mistake the STOPPED state for a natural track end and advance twice.
        _upnpWasPlaying = false;
        debugPrint(
          'UPnP: playSong() taking UPnP branch, isConnected=${_upnpService.isConnected}',
        );
        if (_audioPlayer.playing) await _audioPlayer.stop();

        final playUrl = song.isLocal == true && song.path != null
            ? Uri.file(song.path!).toString()
            : await _subsonicService.resolveStreamUrlAsync(song);

        try {
          // Resolve the MIME type so strict UPnP renderers (e.g. moode /
          // upmpdcli with "check metadata" on) can validate protocolInfo.
          final mimeType =
              song.contentType ?? UpnpService.mimeTypeFromSuffix(song.suffix);
          final success = await _upnpService.loadAndPlay(
            url: playUrl,
            title: song.title,
            artist: song.artist ?? 'Unknown Artist',
            album: song.album,
            albumArtUrl: (song.coverArt != null || _libraryProvider != null)
                ? _subsonicService.getCoverArtUrl(
                    _effectiveCoverId(song),
                    size: 0,
                  )
                : null,
            durationSecs: song.duration,
            contentType: mimeType,
          );
          if (!success) {
            _upnpService.disconnect();
            debugPrint(
                'UPnP playback failed (retries exhausted), disconnected');
            return;
          }
        } catch (e) {
          _upnpService.disconnect();
          debugPrint('UPnP playback failed, disconnected: $e');
          rethrow;
        }
        _isRenderingRemotely = true;
        _isPlaying = true;
      } else {
        _isRenderingRemotely = false;

        // For YouTube, pre-fetch the manifest then hand a StreamAudioSource
        // to just_audio so ExoPlayer never touches the YouTube URL directly.
        final youtubeSource = song.isLocal != true
            ? await _subsonicService.getYoutubeAudioSource(song)
            : null;

        if (youtubeSource != null) {
          // YouTube: single StreamAudioSource, no gapless
          await _audioPlayer.setAudioSource(youtubeSource);
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          // play() Future 要等播放停止才完成：不 await（见 play() 注释）。
          _startPlayback();
        } else if (_subsonicService.isYoutube) {
          // All songs are YouTube — can't build ConcatenatingAudioSource easily
          final String playUrl;
          if (song.isLocal == true && song.path != null) {
            playUrl = Uri.file(song.path!).toString();
          } else {
            final offlinePath = _offlineService.getLocalPath(song.id);
            if (offlinePath != null) {
              playUrl = 'file://$offlinePath';
            } else {
              playUrl = await _subsonicService.resolveStreamUrlAsync(song);
            }
          }
          await _audioPlayer.setUrl(playUrl);
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          _startPlayback();
        } else if (_gaplessEnabled && !_isDaoliyuTranscodeRequested) {
          // Build ConcatenatingAudioSource for gapless playback
          try {
            await _buildAndSetConcatenatingSource(initialIndex: _currentIndex);
          } catch (e) {
            // Android 16 / Media3 first-play workaround
            if (!_hasPlayedOnce) {
              debugPrint(
                'First playback failed (Android 16 Media3 issue), retrying: $e',
              );
              await Future.delayed(const Duration(milliseconds: 100));
              await _buildAndSetConcatenatingSource(
                  initialIndex: _currentIndex);
              _hasPlayedOnce = true;
            } else {
              rethrow;
            }
          }
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          _startPlayback();
        } else {
          // Gapless disabled — single-song mode
          final String playUrl;
          if (song.isLocal == true && song.path != null) {
            playUrl = Uri.file(song.path!).toString();
          } else {
            final offlinePath = _offlineService.getLocalPath(song.id);
            if (offlinePath != null) {
              playUrl = 'file://$offlinePath';
            } else {
              // Apply transcoding settings if enabled (LAN connection always
              // resolves to null → original, rule 1).
              final maxBitRate = _transcodingService.getCurrentBitrate();
              final format = _transcodingService.getCurrentFormat();
              _setActiveStream(maxBitRate, format);
              // 道理鱼转码走自研 /api/tracks/{id}/stream（JWT），seek 用
              // timeOffset 重起流；JWT 失败回退 Subsonic 转码 URL。
              playUrl = (await _buildDaoliyuAwareStreamUrl(song,
                      maxBitRate: maxBitRate, format: format))
                  .url;
            }
          }
          // Cache remote streams locally so seeking works even when the
          // server transcodes and doesn't support HTTP range requests (#170).
          if (song.isLocal == true ||
              _offlineService.getLocalPath(song.id) != null) {
            await _audioPlayer.setUrl(playUrl);
          } else {
            // Route straight to ExoPlayer so seeking keeps the target
            // position. LockCachingAudioSource would downgrade range
            // requests to a full 200 response and restart playback from the
            // beginning — including on LAN, where the server often omits the
            // Accept-Ranges header and seek visibly rewinds to 0:00.
            await _audioPlayer.setAudioSource(
              AudioSource.uri(Uri.parse(playUrl), tag: song.id),
            );
          }
          await _applyReplayGain(song);
          await _ensureAudioFocus();
          _startPlayback();
        }
      }

      // 有声书续播：seek 到恢复位置。必须在这里（播放发起后立即）执行——
      // 此前 _audioPlayer.play() 被 await，本块延迟到暂停/停止时才运行，
      // 实际播放始终从 0:00 开始（这就是「有声书点了从 0s 播」的根因）。
      // 走 provider seek() 而非 _audioPlayer.seek()：道理鱼转码流无
      // Content-Length、字节 seek 无效，seek() 内部会带 timeOffset 重起流。
      // cast/UPnP 远程播放本地播放器已 stop，seek 不生效（B14 一期接受）。
      if (audiobook && resumePositionMs != null && resumePositionMs > 0) {
        try {
          await seek(Duration(milliseconds: resumePositionMs));
          // 道理鱼转码续播：seek 重起了一条带 timeOffset 的新流，但重起流只在
          // _isPlaying 为真时自动续播；此刻播放态标志可能尚未由
          // playerStateStream 置位，这里显式确保新流处于播放态（幂等）。
          if (isActiveStreamTranscoded && _subsonicService.isDaoliyu) {
            _startPlayback();
          }
        } catch (e) {
          debugPrint('[Player] Audiobook resume seek failed: $e');
        }
      }

      // 有声书：不 scrobble、不写推荐最近播放（§8.5 统计隔离，B9）。
      if (song.isLocal != true && !audiobook) {
        if (_offlineService.isOfflineMode) {
          _offlineService.queueScrobble(song.id, submission: false);
        } else {
          _subsonicService.scrobble(song.id, submission: false).catchError((e) {
            _offlineService.queueScrobble(song.id, submission: false);
          });

          _offlineService
              .flushPendingScrobbles(_subsonicService)
              .catchError((e) {
            debugPrint('Scrobble flush failed: $e');
          });
        }
      }

      if (_recommendationService != null && !audiobook) {
        _trackedSongId = null;
        _recommendationService!.trackSongPlay(
          song,
          durationPlayed: 0,
          completed: false,
          countPlay: false,
        );
      }

      _updateAndroidAuto();
    } catch (e) {
      debugPrint('[Player] ✗ Error playing song "${song.title}": $e');
      _isPlaying = false;
      _position = Duration.zero;
      _updateAndroidAuto();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── 有声书播放（§8.2）─────────────────────────────────────────────────

  /// 播放有声书章节。
  ///
  /// 队列 = 全书章节列表（不是当前显示页）：拉一次全量章节（统一走
  /// episodes?limit=10000，与分页共用解析），映射为 Song 后走现有播放栈。
  /// [chapters]/[index] 是调用方（详情页当前页）的定位信息，order 用于在
  /// 全量列表里找到真实下标。
  ///
  /// 规则：
  /// - 进入有声书时保存当前 shuffle/repeat 并强制顺序播放（B6/B10），
  ///   退出时恢复；
  /// - 同一本书内切章：复用现有队列（playSong 已有 indexWhere 分支），
  ///   不重复拉取/重建（§8.2-2）；
  /// - 有保存进度且为用户点「继续收听」→ [resumePositionMs] 续播
  ///   （forcePlay:true 保证非 toggle，B2）；
  /// - 全量拉取失败（P4）：返回 false，不清当前播放状态。
  ///
  /// 返回 true 表示已开始播放；false 表示章节拉取失败（UI 弹 snackbar）。
  ///
  /// [chaptersComplete] 由调用方声明 [chapters] 是否为全书章节（详情页/搜索页
  /// 都是 take:10000 的全量列表，传 true）；为 false 时退化为按条数启发式判断。
  Future<bool> playAudiobookChapter(
    Audiobook book,
    List<AudiobookChapter> chapters,
    int index, {
    int? resumePositionMs,
    bool chaptersComplete = false,
  }) async {
    // 先保存上一本的进度（切书/切歌都不丢，§9.2-2）。
    if (_isPlayingAudiobook) {
      _saveAudiobookProgress();
    }

    // 同一本书内切章：复用现有队列（chapters 为空则落入下方全量拉取路径，
    // 避免对空调用方列表取下标 RangeError，P3 修复）。
    if (_isPlayingAudiobook &&
        _currentAudiobook?.id == book.id &&
        _queue.isNotEmpty &&
        chapters.isNotEmpty) {
      final order = chapters[index].order;
      var targetIndex = _queue.indexWhere((s) => s.track == order);
      if (targetIndex == -1) targetIndex = 0;
      await playSong(
        _queue[targetIndex],
        playlist: _queue,
        startIndex: targetIndex,
        forcePlay: true,
        audiobook: true,
        audiobookBook: book,
        resumePositionMs: resumePositionMs,
      );
      return true;
    }

    // 新书/从歌曲切来：优先复用调用方已持有的全量章节（详情页一次全量拉取
    // 后直接传入，避免同会话重复 take:10000，M001）；入参为空或未声明完整
    // （如外部深链）才回退到服务端全量拉取（P4：失败不清当前播放状态）。
    //
    // 条数启发式（chapters.length >= book.episodeCount）只作兜底：episodeCount
    // 可能过期偏高（服务端已删章节），会让其实已全量的列表被误判为不全而重复
    // 发起 take:10000；因此以调用方显式声明 [chaptersComplete] 为准。
    List<AudiobookChapter> fullChapters;
    if (chapters.isNotEmpty &&
        (chaptersComplete ||
            book.episodeCount <= 0 ||
            chapters.length >= book.episodeCount)) {
      fullChapters = chapters;
    } else {
      final AudiobookChapterPage fullPage;
      try {
        fullPage = await _subsonicService.getAudiobookChapters(
          book.id,
          skip: 0,
          take: 10000,
        );
      } catch (e) {
        debugPrint('[Player] Failed to load audiobook chapters: $e');
        return false;
      }
      if (fullPage.chapters.isEmpty) return false;
      fullChapters = fullPage.chapters;
    }

    // 强制顺序播放（B6）：保存当前设置，退出恢复。
    _savedShuffleBeforeAudiobook ??= _shuffleEnabled;
    _savedRepeatBeforeAudiobook ??= _repeatMode;
    _shuffleEnabled = false;
    _repeatMode = RepeatMode.off;
    await _audioPlayer.setLoopMode(LoopMode.off);
    notifyListeners();

    // serverKey：进度存储按服务器维度隔离（§9.1）。
    _audiobookServerKey = _computeAudiobookServerKey();
    // R001 修复：写进度前先加载磁盘历史（共享单例首次写必先 ensureLoaded，
    // 否则 _persist 整键覆盖会清空该 serverKey 下全部历史进度）。
    if (_audiobookServerKey != null) {
      await _audiobookProgressStore.ensureLoaded(_audiobookServerKey!);
    }

    final songs = fullChapters
        .map((c) => _subsonicService.audiobookChapterToSong(book, c))
        .toList();
    // M001 修复：回退分支（入参 chapters 为空）下不能对调用方列表取下标，
    // 从 fullChapters 取目标章，避免 RangeError。
    final order =
        (chapters.isEmpty ? fullChapters.first : chapters[index]).order;
    var targetIndex = songs.indexWhere((s) => s.track == order);
    if (targetIndex == -1) targetIndex = 0;

    await playSong(
      songs[targetIndex],
      playlist: songs,
      startIndex: targetIndex,
      forcePlay: true,
      audiobook: true,
      audiobookBook: book,
      resumePositionMs: resumePositionMs,
    );
    return true;
  }

  /// 计算当前服务器的进度 key：sha256(serverUrl + localUrl + username)[0:12]。
  String? _computeAudiobookServerKey() {
    final config = _subsonicService.config;
    if (config == null) return null;
    return AudiobookProgressStore.computeServerKey(
      serverUrl: config.serverUrl,
      localUrl: config.localUrl,
      username: config.username,
    );
  }

  /// 保存当前有声书进度（多路兜底，§9.2）。
  ///
  /// 位置流 5s 节流 / 切歌 / 暂停 / seek / 退后台 / 章节播完 多路都会调这里；
  /// store 内部内存缓存防读-改-写竞态（P2）。
  void _saveAudiobookProgress() {
    final book = _currentAudiobook;
    final order = _audiobookChapterOrder;
    final serverKey = _audiobookServerKey;
    if (!_isPlayingAudiobook || book == null || order == null) return;
    if (serverKey == null) return;

    var chapterOrder = order;
    var positionMs = _position.inMilliseconds;
    if (positionMs < 0) positionMs = 0;

    // 进度超过本章时长×95%（如拖进度条跨章）→ 落到下一章 pos 0，
    // 避免恢复时先定位旧章再被自愈逻辑推走（§9.2-1）。
    // C003 修复：末章不 +1（无下一章），保持末章 order 由播完逻辑标 completed，
    // 否则写入 lastOrder+1 恢复时定位失败。
    final durationMs = _duration.inMilliseconds;
    final isLast = _currentIndex >= _queue.length - 1;
    if (durationMs > 0 && positionMs >= durationMs * 0.95 && !isLast) {
      chapterOrder = order + 1;
      positionMs = 0;
    }

    // 记录真正落盘的位置，供 seek 去抖判断（见 seek()）。
    _lastSavedAudiobookPositionMs = positionMs;

    _audiobookProgressStore.save(
      serverKey,
      AudiobookProgress(
        audiobookId: book.id,
        chapterOrder: chapterOrder,
        chapterId: _currentSong?.id,
        positionMs: positionMs,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// 保存指定章节/位置的进度（章节播完推进 bookmark 用，§8.3/§9.2-4）。
  void _saveAudiobookChapterProgress({
    required int chapterOrder,
    required int positionMs,
    required bool completed,
  }) {
    final book = _currentAudiobook;
    final serverKey = _audiobookServerKey;
    if (book == null || serverKey == null) return;
    _audiobookProgressStore.save(
      serverKey,
      AudiobookProgress(
        audiobookId: book.id,
        chapterOrder: chapterOrder,
        chapterId: _currentSong?.id,
        positionMs: positionMs,
        completed: completed,
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// 退出有声书（切普通歌/电台/停止）时恢复用户原 shuffle/repeat 设置（B6/B10）。
  void _restorePlaybackSettingsAfterAudiobook() {
    if (_savedShuffleBeforeAudiobook != null) {
      _shuffleEnabled = _savedShuffleBeforeAudiobook!;
      _savedShuffleBeforeAudiobook = null;
    }
    if (_savedRepeatBeforeAudiobook != null) {
      _repeatMode = _savedRepeatBeforeAudiobook!;
      _savedRepeatBeforeAudiobook = null;
    }
    // 恢复 just_audio loopMode（有声书置 off 时被改过）。
    _audioPlayer
        .setLoopMode(_repeatMode == RepeatMode.all
            ? LoopMode.all
            : (_repeatMode == RepeatMode.one ? LoopMode.one : LoopMode.off))
        .catchError((e) {
      debugPrint('[Player] Failed to restore loop mode: $e');
    });
  }

  /// 清有声书标志（电台入口用，B4）——不保存进度（电台不是歌曲语义，
  /// 进度由位置流最后 1s 已存过）。
  void _clearAudiobookState() {
    _isPlayingAudiobook = false;
    _currentAudiobook = null;
    _audiobookChapterOrder = null;
    _audiobookServerKey = null;
    _restorePlaybackSettingsAfterAudiobook();
  }

  Future<void> playRadioStation(RadioStation station) async {
    if (_isPlayingRadio && _currentRadioStation?.id == station.id) {
      await togglePlayPause();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _clearAudiobookState(); // B4：电台播放时清有声书标志（车载守卫/进度归属）
      _currentSong = null;
      _queue = [];
      _currentIndex = -1;
      _isPlayingRadio = true;
      _isRenderingRemotely = false; // radio always plays locally
      _currentRadioStation = station;
      _position = Duration.zero;
      _duration = Duration.zero;

      try {
        await _audioPlayer.setUrl(station.streamUrl);
      } catch (e) {
        if (!_hasPlayedOnce) {
          debugPrint(
            'First radio playback failed (Android 16 Media3 issue), retrying: $e',
          );
          await Future.delayed(const Duration(milliseconds: 100));
          await _audioPlayer.setUrl(station.streamUrl);
          _hasPlayedOnce = true;
        } else {
          rethrow;
        }
      }

      await _audioPlayer.setVolume(_volume);

      await _ensureAudioFocus();
      // play() Future 要等播放停止才完成：不 await，否则下面的
      // _updateSystemServicesForRadio（车载/通知栏电台状态）永远不会执行。
      // play 失败不抛出（_startPlayback 吞错）→ 通过 onError 复位电台状态，
      // 避免流启动失败时 UI 卡在"播放中"（Review P2）。
      _startPlayback(onError: (e) {
        debugPrint('Error playing radio station: $e');
        _isPlaying = false;
        _isPlayingRadio = false;
        _currentRadioStation = null;
        notifyListeners();
      });

      _updateSystemServicesForRadio(station);
    } catch (e) {
      debugPrint('Error playing radio station: $e');
      _isPlaying = false;
      _isPlayingRadio = false;
      _currentRadioStation = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopRadio() {
    if (_isPlayingRadio) {
      _audioPlayer.stop();
      _isPlayingRadio = false;
      _currentRadioStation = null;
      _isPlaying = false;
      _clearAudiobookState(); // B4：电台停止同样清有声书标志
      // Clear lyrics when stopping radio
      _lyricsService.stopSync();
      _lyricsService.loadLyrics(null);
      notifyListeners();
    }
  }

  /// 加载并同步当前歌的歌词（车机副标题 / 通知栏 / 锁屏）。
  ///
  /// 取源走 [LyricsSourceService]（唯一实现，与 App 内入口同一顺序）。此前这里
  /// 只有 `getLyricsBySongId` 一条来源，服务器没歌词时车机链一条都拿不到，而 App
  /// 内靠网易云兜底照常显示 —— 见 `docs/歌词源优先级修复技术方案.md` §2.6。
  Future<void> _loadAndSyncLyrics(Song song) async {
    // 有声书无歌词：完全短路（章节标题可能被 LRCLIB 误匹配到奇怪歌词），
    // 且 return 前必须 stopSync + 清空，否则锁屏/歌词区残留上一首歌歌词（B13）。
    if (_isPlayingAudiobook) {
      _lyricsService.stopSync();
      await _lyricsService.loadLyrics(null);
      return;
    }
    try {
      // Stop any previous sync
      _lyricsService.stopSync();

      final result = await _lyricsSourceService.fetchForSong(song);

      // 取源链含缓存/服务器/外部兜底多段网络，期间可能已经切歌。若不设守卫，先发起
      // 的慢请求后完成会覆盖新歌歌词，通知栏/车机副标题显示错歌（code-review R3）。
      // 参照 `_checkSilentPlayback` 的守卫写法；`_currentSong == null` 时（电台/切远端
      // 过渡）不判定，保持原有行为。
      if (_currentSong != null && song.id != _currentSong!.id) {
        debugPrint('[Lyrics] Discarded stale lyrics for "${song.title}"');
        return;
      }

      // 纯文本（无时间轴）歌词：合成静态单行 LRC，副标题静态显示首行
      // （§5.5 选项 A）；过滤后无可选行则退化为不推。
      final String? lrc;
      if (result == null) {
        lrc = null;
      } else if (result.isLrc) {
        lrc = result.raw;
      } else {
        lrc = plainTextToStaticLrc(result.raw);
      }

      if (lrc != null && lrc.isNotEmpty) {
        await _lyricsService.loadLyrics(lrc);
        _lyricsService.startSync(_audioPlayer.positionStream);
        debugPrint(
          '[Lyrics] Loaded and started sync for "${song.title}" '
          '(source=${result!.source.wireName}, isLrc=${result.isLrc})',
        );
      } else {
        // No lyrics available - clear any existing
        await _lyricsService.loadLyrics(null);
        debugPrint('[Lyrics] No lyrics available for "${song.title}"');
      }
    } catch (e) {
      debugPrint('[Lyrics] Failed to load lyrics for "${song.title}": $e');
      // Don't block playback if lyrics fail
      await _lyricsService.loadLyrics(null);
    }
  }

  void _updateSystemServicesForRadio(RadioStation station) {
    _windowsService.updatePlaybackState(
      song: null,
      isPlaying: true,
      position: Duration.zero,
      duration: Duration.zero,
      artworkUrl: null,
    );

    _androidSystemService.updatePlaybackState(
      songId: station.id,
      title: station.name,
      artist: 'Internet Radio',
      album: station.homePageUrl ?? '',
      artworkUrl: null,
      duration: Duration.zero,
      position: Duration.zero,
      isPlaying: true,
    );
  }

  /// 发起播放但不阻塞。just_audio/media_kit 的 play() Future 在播放「停止」
  /// 时才完成（见 play() 注释），绝不能 await；且平台播放请求失败会在该
  /// Future 上抛错，fire-and-forget 必须吞掉，避免未捕获异步异常。
  /// [onError] 供调用方感知 play 失败（如电台失败复位状态）。
  void _startPlayback({void Function(Object error)? onError}) {
    // 任何「开始播放」都让挂起的「打断后自动恢复」意图失效（方案 B §4.1 步骤 3）：
    // 覆盖 play() / playSong()（不经 play()）/ 无声自愈 / 会话重激活。
    _wasPlayingBeforeInterruption = false;
    unawaited(_audioPlayer.play().catchError((Object e) {
      debugPrint('[Player] play() error (ignored): $e');
      onError?.call(e);
    }));
  }

  Future<void> play() async {
    DiagnosticsService.instance.beginPlaybackSession();
    DiagnosticsService.instance.record(
      EventType.audioPlayerAction,
      LogLevel.info,
      {
        'action': 'play',
        'route': DiagnosticsService.instance.currentRoute,
        'songId': _currentSong?.id,
        'posMs': _audioPlayer.position.inMilliseconds,
        'processingState': _audioPlayer.processingState.name,
        'durationMs': _audioPlayer.duration?.inMilliseconds,
        'volume': _audioPlayer.volume,
        'hasSource': _audioPlayer.audioSource != null,
        'afterResume': _wasBackgrounded,
      },
    );
    unawaited(_snapshotAudioRoute());
    if (_castService.isConnected) {
      await _castService.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } else if (_upnpService.isConnected) {
      await _upnpService.play();
      _isPlaying = true;
      notifyListeners();
      _updateAndroidAuto();
    } else {
      // After app restart the audio source may not be loaded yet.
      // If we have a current song but the player has no source, prepare it first.
      // idle 态同样必须重载：暂停 + 蓝牙断开 + 长时间后台会让源陈旧失效
      // （processingState=idle、duration=null），此时直接 play() 时钟照走但
      // 无声（2026-08-07 诊断日志确认的无声 bug 根因，位置前进≠输出管线重建）。
      var neededPrepare = false;
      if (_currentSong != null &&
          (_audioPlayer.audioSource == null ||
              _audioPlayer.processingState == ProcessingState.idle ||
              _audioPlayer.duration == Duration.zero)) {
        neededPrepare = true;
        // 重载前记录最后位置与歌曲：_prepareCurrentSong 从头建源会把位置清零，
        // 重载后 seek 回去，避免暂停后恢复从 0:00 重放。
        final restorePos = _audioPlayer.position;
        final restoreSongId = _currentSong?.id;
        await _prepareCurrentSong();
        // 重载可能耗时（网络流）：期间若已切歌/停止，seek 不能作用到新源上。
        if (restoreSongId != null &&
            restoreSongId == _currentSong?.id &&
            restorePos > Duration.zero) {
          await _audioPlayer.seek(restorePos);
        }
      } else if (_audioPlayer.processingState == ProcessingState.completed) {
        // 队列播完/单曲播完后再点播放：媒体停在曲末，play() 不会自动重播。
        // seek(0) 归零（道理鱼转码流会走 timeOffset 重起流），再 play 从头播。
        await seek(Duration.zero);
      }
      await _ensureAudioFocus();
      // 关键修复：just_audio/media_kit 的 play() Future 在播放「停止」时才完成，
      // 绝不能 await——否则后面的 _fadeIn/_checkSilentPlayback/play 会话快照全部
      // 延迟到暂停/切歌时才执行（2026-08-11 诊断日志实证：action=play 在
      // 11:28:47.332，play 会话快照却在 11:28:58.423 用户暂停后才落盘）。无声
      // 自愈因此永远测的是暂停态，位置停滞类无声从不被恢复。
      _startPlayback();
      await _fadeIn();
      // 无声检测：play 后 1.5s 内 playing 但位置未前进 → 疑似无声；
      // 同时无条件记录一次会话快照，覆盖「位置前进但无声」场景。
      _checkSilentPlayback();
      unawaited(_recordAudioSessionState('play', extra: {
        'prepared': neededPrepare,
        'fadeEnabled': _fadeSettingsService.getFadeEnabled(),
      }));
    }
  }

  /// 派生检测器：play 后无声音输出（状态 playing 但 position 停滞）。
  /// 同时无条件记录一次会话快照（postPlayCheck）：覆盖与停滞相反的另一类
  /// 无声——位置在前进但输出管线未重建（退后台回前台后首次 play 的典型症状）。
  ///
  /// 修复说明（2026-08-20）：此前 _audioPlayer.play() 被 await，本检测延迟到
  /// 暂停/切歌时才执行，测的是暂停态（playing=false 直接 return），从来自愈
  /// 不生效。现在 play() 不再 await play Future，本检测在播放发起后立即执行：
  /// 1.5s 后仍未进入播放态 / 源回 idle / ready 但位置停滞 → 重载音源自愈。
  /// pause/seek/切歌都会自增 _silentCheckToken 使本次检测失效，能走到判定
  /// 说明用户没有干预，属于播放未生效。
  Future<void> _checkSilentPlayback() async {
    final token = ++_silentCheckToken; // 只让最新一次 play 的检测生效
    final songId = _currentSong?.id;
    final startPos = _audioPlayer.position;
    await Future.delayed(const Duration(milliseconds: 1500));
    if (token != _silentCheckToken) return; // 已被更新的 play/pause/seek 取代
    try {
      final nowPos = _audioPlayer.position;
      final advancedMs = (nowPos - startPos).inMilliseconds;
      await _recordAudioSessionState('postPlayCheck', extra: {
        'posBeforeMs': startPos.inMilliseconds,
        'posAfterMs': nowPos.inMilliseconds,
        'advancedMs': advancedMs,
        'fadeEnabled': _fadeSettingsService.getFadeEnabled(),
        // 「位置前进但无声」指纹：playing && ready && 位置推进 && 音量>0。
        // 若满足而用户没听到声音，说明输出管线/会话未接上。
        'silentLikely': _audioPlayer.playing &&
            _audioPlayer.processingState == ProcessingState.ready &&
            advancedMs >= 500 &&
            _audioPlayer.volume > 0.01,
      });
      if (_currentSong?.id != songId) return; // 已切歌，不误报
      if (_currentSong == null) return; // radio（_currentSong==null）不在此列
      // 已切到 Cast/UPnP 远端播放：本地播放器被有意暂停/停止，不干预，避免
      // 自愈强行本地重播形成双路音频（Review P2）。
      if (_isRenderingRemotely) return;

      // 无声判定：未进入播放态 / 源回 idle / ready 但位置停滞（<500ms）。
      // buffering/loading 不算（网络慢属正常等待，不是无声）。completed 不在此列：
      // 1.5s 内自然播完（短曲/曲末点播）是正常完成而非无声，由 _onSongComplete
      // 接管，不应从 0 重播一次（Review P3）。
      final stuck = !_audioPlayer.playing ||
          _audioPlayer.processingState == ProcessingState.idle ||
          (_audioPlayer.processingState == ProcessingState.ready &&
              advancedMs < 500);
      // 第四类无声（方案 B §4.4）：在播 + 位置前进 + **音量≈0**。
      // 这是「暂停把音量压到 0、恢复播放却被库内抢走」的静音失联指纹，
      // 上面三条判定都抓不到。`_volume > 0.01` 是为了排除用户把 App 内音量
      // 拉到 0 的正常情况，避免误报。
      final silentByVolume = _audioPlayer.playing &&
          _audioPlayer.processingState == ProcessingState.ready &&
          advancedMs >= 500 &&
          _audioPlayer.volume < 0.01 &&
          _volume > 0.01;
      if (!stuck && !silentByVolume) return;

      if (silentByVolume) {
        // 音量型无声：只需把音量拉回，不必重建输出管线。
        DiagnosticsService.instance.record(
          EventType.audioSilentPlayback,
          LogLevel.warn,
          {
            'posBeforeMs': startPos.inMilliseconds,
            'posAfterMs': nowPos.inMilliseconds,
            'route': DiagnosticsService.instance.currentRoute,
            'songId': songId,
            'volume': _audioPlayer.volume,
            'recovery': 'restoreVolume',
          },
        );
        try {
          await _audioPlayer.setVolume(_volume);
          unawaited(_recordAudioSessionState('selfHealVolume'));
        } catch (e) {
          debugPrint('[Player] Self-heal volume restore failed: $e');
        }
        return;
      }

      DiagnosticsService.instance.record(
        EventType.audioSilentPlayback,
        LogLevel.warn,
        {
          'posBeforeMs': startPos.inMilliseconds,
          'posAfterMs': nowPos.inMilliseconds,
          'route': DiagnosticsService.instance.currentRoute,
          'songId': songId,
          'recovery': 'reprepare',
        },
      );
      try {
        // 重载音源重建整个输出管线（退后台回前台首次 play 的无声根因）。
        await _prepareCurrentSong();
        if (token != _silentCheckToken) return; // 重载期间用户已暂停/切歌
        // 重载从头建源：恢复到触发时位置，避免从 0:00 重放。道理鱼转码流
        // 由 _prepareCurrentSong 内部按 timeOffset 起播（_streamBaseOffsetMs
        // 已置位），无需再 seek。
        if (startPos > Duration.zero && _streamBaseOffsetMs == 0) {
          await _audioPlayer.seek(startPos);
        }
        _startPlayback();
        unawaited(_recordAudioSessionState('selfHeal'));
      } catch (e) {
        debugPrint('[Player] Self-heal re-prepare failed: $e');
      }
    } catch (_) {
      // 播放器已释放等异常：忽略本次检测
    }
  }

  /// 暂停。
  ///
  /// [skipFade] 为真时跳过淡出，立刻静音并暂停 —— 打断路径（方案 B §4.1 步骤 4）
  /// 用它，避免打断后还继续出声 `fadeDurationMs`（默认 300ms）。
  ///
  /// [keepInterruptionResume] 为真时**保留**「打断后自动恢复」标记，仅供打断路径
  /// 使用（打断是「先置位、再调 pause()」）。其余调用一律清标记 —— 用户主动暂停 /
  /// 拔耳机 / 媒体会话暂停都意味着「不想继续播」，结束后不得被自动恢复
  /// （2026-10-08 code-review R1：原先 `pause()` 一律不清，用户手动暂停后仍会被
  /// `end + pause` 自动拉起）。
  Future<void> pause({
    bool skipFade = false,
    bool keepInterruptionResume = false,
  }) async {
    if (!keepInterruptionResume) _wasPlayingBeforeInterruption = false;
    _silentCheckToken++; // 使挂起的无声检测失效
    DiagnosticsService.instance.record(
      EventType.audioPlayerAction,
      LogLevel.info,
      {
        'action': 'pause',
        'songId': _currentSong?.id,
        'posMs': _audioPlayer.position.inMilliseconds,
        'processingState': _audioPlayer.processingState.name,
        'durationMs': _audioPlayer.duration?.inMilliseconds,
        'volume': _audioPlayer.volume,
        'fadeEnabled': _fadeSettingsService.getFadeEnabled(),
        'skipFade': skipFade,
      },
    );
    if (_castService.isConnected) {
      await _castService.pause();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    } else if (_upnpService.isConnected) {
      await _upnpService.pause();
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    } else {
      await _fadeOut(
        onComplete: () async {
          await _audioPlayer.pause();
        },
        immediate: skipFade,
      );
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
      unawaited(_recordAudioSessionState('pause'));
    }
    // 暂停后位置流停止输出，5s 节流窗口内的最后位置不会被写入；暂停即落盘，
    // 避免暂停后进程被强杀时进度最多回退 5s（stop()/退后台另有保存路径）。
    if (_isPlayingAudiobook) _saveAudiobookProgress();
  }

  Future<void> stop() async {
    _silentCheckToken++; // 使挂起的无声检测失效
    _bufferStartAt = null; // 避免 buffering 状态残留误配对
    // R005 修复：有声书停止前保存当前真实位置（随后 _position 归零，
    // 若在归零后才保存会用 0 覆盖 1s 节流刚写入的真实位置）。
    if (_isPlayingAudiobook) _saveAudiobookProgress();
    if (_castService.isConnected) {
      await _castService.stop();
    } else if (_upnpService.isConnected) {
      _upnpWasPlaying = false; // prevent poll from misreading the STOPPED state
      await _upnpService.stop();
    } else {
      await _audioPlayer.stop();
    }

    // 用户主动停止 ⇒ 作废挂起的「打断后自动恢复」意图（方案 B §4.1 步骤 3）。
    _wasPlayingBeforeInterruption = false;

    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
  }

  // ── Fade In/Out ────────────────────────────────────────────────────────────

  void _stopFade() {
    _fadeTimer?.cancel();
    _fadeTimer = null;
    _isFading = false;
  }

  Future<void> _fadeIn() async {
    _stopFade();

    if (!_fadeSettingsService.getFadeEnabled()) {
      await _audioPlayer.setVolume(_volume);
      return;
    }

    final fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    final steps = 20;
    final stepDurationMs = fadeDurationMs ~/ steps;
    final volumeStep = _volume / steps;

    _isFading = true;
    await _audioPlayer.setVolume(0.0);

    var currentStep = 0;
    _fadeTimer =
        Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) async {
      if (!_isFading || currentStep >= steps) {
        timer.cancel();
        _isFading = false;
        return;
      }
      currentStep++;
      final newVolume = volumeStep * currentStep;
      await _audioPlayer.setVolume(newVolume.clamp(0.0, _volume));
    });
  }

  /// 淡出并回调（默认把音量压到 0）。
  ///
  /// [immediate] 为真时跳过淡出动画，直接静音后回调 —— 供打断路径使用
  /// （`pause(skipFade: true)`），避免打断后继续出声。
  Future<void> _fadeOut(
      {VoidCallback? onComplete, bool immediate = false}) async {
    _stopFade();

    if (immediate || !_fadeSettingsService.getFadeEnabled()) {
      await _audioPlayer.setVolume(0.0);
      onComplete?.call();
      return;
    }

    final fadeDurationMs = _fadeSettingsService.getFadeDurationMs();
    final steps = 20;
    final stepDurationMs = fadeDurationMs ~/ steps;
    final currentVolume = _audioPlayer.volume;
    final volumeStep = currentVolume / steps;

    _isFading = true;

    var currentStep = 0;
    _fadeTimer =
        Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) async {
      if (!_isFading || currentStep >= steps) {
        timer.cancel();
        _isFading = false;
        onComplete?.call();
        return;
      }
      currentStep++;
      final newVolume = currentVolume - (volumeStep * currentStep);
      await _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
    });
  }

  void _smoothVolumeChange(double targetVolume, {int durationMs = 150}) {
    _stopFade();

    final currentVolume = _audioPlayer.volume;
    if ((currentVolume - targetVolume).abs() < 0.01) return;

    final steps = 10;
    final stepDurationMs = durationMs ~/ steps;
    final volumeDiff = targetVolume - currentVolume;
    final volumeStep = volumeDiff / steps;

    _isFading = true;

    var currentStep = 0;
    _fadeTimer =
        Timer.periodic(Duration(milliseconds: stepDurationMs), (timer) async {
      if (!_isFading || currentStep >= steps) {
        timer.cancel();
        _isFading = false;
        return;
      }
      currentStep++;
      final newVolume = currentVolume + (volumeStep * currentStep);
      await _audioPlayer.setVolume(newVolume.clamp(0.0, 1.0));
    });
  }

  Future<void> togglePlayPause() async {
    DiagnosticsService.instance.record(
      EventType.audioPlayerAction,
      LogLevel.info,
      {'action': 'toggle', 'wasPlaying': _isPlaying},
    );
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    _silentCheckToken++; // 使挂起的无声检测失效（seek 后位置跳变）
    DiagnosticsService.instance.record(
      EventType.audioPlayerAction,
      LogLevel.info,
      {
        'action': 'seek',
        'songId': _currentSong?.id,
        'targetMs': position.inMilliseconds,
        'posMs': _audioPlayer.position.inMilliseconds,
        'processingState': _audioPlayer.processingState.name,
        'durationMs': _audioPlayer.duration?.inMilliseconds,
        'transcoded': isActiveStreamTranscoded,
        'daoliyu': _subsonicService.isDaoliyu,
      },
    );
    _position = position;
    _lastSeekRequest = position; // 供重起流被取代后按最新目标重试
    // 用户主动 seek ⇒ 作废挂起的「打断后自动恢复」意图（方案 B §4.1 步骤 3）。
    _wasPlayingBeforeInterruption = false;
    notifyListeners();
    if (_castService.isConnected) {
      await _castService.seek(position);
    } else if (_upnpService.isConnected) {
      await _upnpService.seek(position);
    } else if (_subsonicService.isDaoliyu && isActiveStreamTranscoded) {
      // 道理鱼转码流是 chunked（无 Content-Length），ExoPlayer 无法按字节
      // seek（实测拖动后从 0:00 重播），服务端也不认 HTTP Range。改走自研
      // /api/tracks/{id}/stream?timeOffset=<秒> 重起一条从目标时间开始转码的
      // 新流——WebUI 快进正是这个机制（2026-08-11 实测）。
      await _restartDaoliyuStream(position);
    } else {
      await _audioPlayer.seek(position);
    }
    // seek 后位置流的下一个 tick 可能被 5s 节流吞掉，若紧接着暂停/强杀会恢复回
    // seek 前位置；seek 即落盘（§9.2-1）。但进度条拖拽期间 onChanged 会连续调
    // seek，每次都写整表快照会造成写放大——位移不足 1s 时跳过，交给位置流
    // 5s 节流或 pause/stop/退后台的即时写兜底。
    if (_isPlayingAudiobook &&
        (_lastSavedAudiobookPositionMs == null ||
            (position.inMilliseconds - _lastSavedAudiobookPositionMs!).abs() >=
                1000)) {
      _saveAudiobookProgress();
    }
  }

  /// 道理鱼转码流的 seek：重发带 `timeOffset=<目标秒>` 的自研流 URL，服务端
  /// ffmpeg 直接从该时间点重新转码推送，播放器从新流开头续播，实现「跳到
  /// X 秒」而非 Range 续传。重起后播放器位置从 0 计起，显示位置由
  /// [_streamBaseOffsetMs] 补回；锁屏歌词也按「流位置 + 基准」重新同步。
  Future<void> _restartDaoliyuStream(Duration position) async {
    final song = _currentSong;
    if (song == null) return;
    final token = ++_seekRestartToken;

    final url = await _subsonicService.getDaoliyuApiStreamUrl(song.id,
        timeOffsetSeconds: position.inSeconds);
    if (url == null) {
      // 自研层不可用（JWT 登录失败）→ 退回原生 seek（转码流大概率仍无效，
      // 但不比现状更差）。
      if (token == _seekRestartToken) {
        await _audioPlayer.seek(position);
      }
      return;
    }
    if (token != _seekRestartToken) return; // 已被更新的 seek/切歌取代

    DiagnosticsService.instance.record(
      EventType.audioPlayerAction,
      LogLevel.info,
      {
        'action': 'seekRestart',
        'songId': song.id,
        'targetMs': position.inMilliseconds,
        'baseOffsetMs': position.inMilliseconds,
      },
    );

    try {
      await _audioPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: song.id),
      );
    } catch (e) {
      // 新流加载失败：不留「base 已设但无源」的悬空状态——清基准并退回
      // 原生 seek（即使失败也只影响本次拖动）。
      if (token == _seekRestartToken) {
        _streamBaseOffsetMs = 0;
        await _audioPlayer.seek(position);
      }
      return;
    }
    if (token != _seekRestartToken) {
      // 加载期间又被更新的 seek 取代：当前加载的是旧目标流，以最新目标
      // 重新起流（position 流 tick 会覆盖 _position，须用 _lastSeekRequest）。
      await _restartDaoliyuStream(_lastSeekRequest);
      return;
    }

    // 流加载成功后才设基准：避免旧源被替换前发出的位置 tick 被加上新基准
    // （短暂错位）。
    _streamBaseOffsetMs = position.inMilliseconds;
    if (_isPlaying)
      _startPlayback(); // 用当前态而非入口快照；不 await（play Future 播放停止才完成，否则下方歌词重同步被延迟到暂停时）

    // 重起流后播放器位置从 0 计起：锁屏歌词同步到「流位置 + 基准」才正确。
    _lyricsService.stopSync();
    _lyricsService.startSync(_audioPlayer.positionStream.map(
        (p) => Duration(milliseconds: p.inMilliseconds + _streamBaseOffsetMs)));
  }

  Future<void> seekToProgress(double progress) async {
    final position = Duration(
      milliseconds: (progress * effectiveDuration.inMilliseconds).round(),
    );
    await seek(position);
  }

  Future<void> skipNext() async {
    // 有声书：不记录歌曲统计（B9）、不触发 AutoDJ（B7/B16），始终按队列顺序。
    // gapless 走 _audioPlayer.seek(index:) → _onCurrentIndexChanged 处理 bookmark；
    // 非 gapless 走 skipToIndex（内部透传 audiobook 状态，B11）。
    if (_isPlayingAudiobook) {
      if (_concatenatingSource != null) {
        if (_currentIndex < _queue.length - 1) {
          await _audioPlayer.seek(Duration.zero, index: _currentIndex + 1);
        }
      } else if (_currentIndex < _queue.length - 1) {
        await skipToIndex(_currentIndex + 1);
      }
      return;
    }

    if (_currentSong != null) {
      _recordSongEnd(_currentSong!, _position.inSeconds, _duration.inSeconds);
    }

    if (_autoDjService.shouldAddSongs(_currentIndex, _queue.length)) {
      await _addAutoDjSongs();
    }

    if (_concatenatingSource != null) {
      if (_shuffleEnabled && _queue.length > 1) {
        _shuffleHistory.add(_currentSong!.id);
        if (_shuffleHistory.length > 50) _shuffleHistory.removeAt(0);
        final next = _pickShuffleNextIndex();
        if (next != -1) {
          await _audioPlayer.seek(Duration.zero, index: next);
        } else if (_repeatMode == RepeatMode.all) {
          await _restartShuffleRound();
        }
      } else if (_currentIndex < _queue.length - 1) {
        await _audioPlayer.seek(Duration.zero, index: _currentIndex + 1);
      } else if (_repeatMode == RepeatMode.all) {
        await _audioPlayer.seek(Duration.zero, index: 0);
      }
      return;
    }

    if (_shuffleEnabled && _queue.length > 1) {
      _shuffleHistory.add(_currentSong!.id);
      if (_shuffleHistory.length > 50) _shuffleHistory.removeAt(0);
      final next = _pickShuffleNextIndex();
      if (next != -1) {
        await skipToIndex(next);
      } else if (_repeatMode == RepeatMode.all) {
        await _restartShuffleRound();
      }
    } else if (_currentIndex < _queue.length - 1) {
      await skipToIndex(_currentIndex + 1);
    } else if (_repeatMode == RepeatMode.all) {
      if (_queue.length == 1) {
        await seek(Duration.zero);
        await play();
      } else {
        await skipToIndex(0);
      }
    }
  }

  /// Builds a fresh shuffled play order (indices into [_queue]). Recently
  /// played songs (up to 20 from [_shuffleHistory]) are pushed to the tail so
  /// they don't immediately repeat across rounds.
  void _rebuildShuffleOrder() {
    _shuffleOrder = List.generate(_queue.length, (i) => i)..shuffle();
    final recentIds = _shuffleHistory.take(20).toSet();
    if (recentIds.isNotEmpty) {
      final front = <int>[];
      final back = <int>[];
      for (final idx in _shuffleOrder) {
        if (idx >= 0 &&
            idx < _queue.length &&
            recentIds.contains(_queue[idx].id)) {
          back.add(idx);
        } else {
          front.add(idx);
        }
      }
      _shuffleOrder = [...front, ...back];
    }
    _shuffleOrderPos = 0;
  }

  /// Points [_shuffleOrderPos] at the current song's position in the order so
  /// the "next" is always the entry right after the currently playing song,
  /// regardless of whether the track changed automatically or via seek.
  void _syncShuffleOrderPos() {
    if (_shuffleOrder.isEmpty) {
      _rebuildShuffleOrder();
      return;
    }
    final pos = _shuffleOrder.indexOf(_currentIndex);
    _shuffleOrderPos = pos != -1 ? pos : 0;
  }

  /// Picks the next index for shuffle mode by walking the shuffled order, so
  /// every song plays exactly once per round (no random re-picks). Returns -1
  /// when the round is exhausted; the caller decides whether to restart
  /// (repeat-all) or stop.
  int _pickShuffleNextIndex() {
    if (_queue.length <= 1 || _currentSong == null) return -1;
    _syncShuffleOrderPos();
    final currentId = _currentSong!.id;
    for (var i = _shuffleOrderPos + 1; i < _shuffleOrder.length; i++) {
      final idx = _shuffleOrder[i];
      if (idx >= 0 && idx < _queue.length && _queue[idx].id != currentId) {
        return idx;
      }
    }
    return -1; // round exhausted
  }

  /// Starts a new shuffled round: fresh order, and in gapless mode the
  /// concatenating source is rebuilt so just_audio follows the new sequence.
  Future<void> _restartShuffleRound() async {
    if (_queue.isEmpty) return;
    if (_concatenatingSource != null) {
      _queue.shuffle();
      // Keep the current song pinned at index 0 so playback continues
      // smoothly; the fresh order starts with a different song anyway.
      if (_currentSong != null) {
        _queue.remove(_currentSong);
        _queue.insert(0, _currentSong!);
        _currentIndex = 0;
      }
      _rebuildShuffleOrder();
      final startIdx = _shuffleOrder.isNotEmpty ? _shuffleOrder.first : 0;
      await _buildAndSetConcatenatingSource(initialIndex: startIdx);
      await play();
      _saveQueueState();
    } else {
      _rebuildShuffleOrder();
      await skipToIndex(_shuffleOrder.isNotEmpty ? _shuffleOrder.first : 0);
    }
  }

  /// 漫游起播时塞进队列的歌曲数。
  ///
  /// 不塞全库：队列会被持久化（`_keyQueue`），gapless 下还要重建拼接音源，几千首
  /// 的队列在冷启动恢复与拼接源构建上都吃不消。100 首约撑 5~6 小时，之后的续播
  /// 会接上。
  static const int roamingSeedCount = 100;

  /// 首页「漫游」入口：立刻用**本地全曲库**乱序起播，并打开 AutoDJ 续播，形成
  /// 「播不完」的随机漫游（对标飞牛音乐的「全曲库随机漫游」）。
  ///
  /// 返回 false 表示**没有可播的内容**（曲库还没同步 / 未登录），调用方应给出提示
  /// ——否则点一下毫无反应，看起来像坏了。
  ///
  /// ⚠️ `AutoDjMode` 是**全局持久化**状态：点过一次之后，**任何**播放都会在队列
  /// 快播完时自动续歌。这是已拍板接受的连带效应（方案 §5.4），不是 bug。
  Future<bool> startRoaming() async {
    final library = _libraryProvider;
    if (library == null) return false;

    // 池子优先用本地全量缓存（真·全曲库）；全量同步还没完成时退回服务端随机池。
    final pool = library.cachedAllSongs.isNotEmpty
        ? library.cachedAllSongs
        : library.randomSongs;
    if (pool.isEmpty) return false;

    final shuffled = List<Song>.from(pool)..shuffle();
    final seedCount =
        shuffled.length < roamingSeedCount ? shuffled.length : roamingSeedCount;
    final queue = shuffled.take(seedCount).toList();

    // 先把池子交给 AutoDJ 再起播：否则队列很短时第一首还没播完就可能触发续播，
    // 那一次会退化成服务端随机。
    if (_autoDjService.mode == AutoDjMode.off) {
      await _autoDjService.setMode(AutoDjMode.shuffleLibrary);
    }
    _autoDjService.setLocalPool(pool);

    await playSong(queue.first, playlist: queue, startIndex: 0);
    return true;
  }

  Future<void> _addAutoDjSongs() async {
    if (!_autoDjService.isEnabled) return;

    try {
      final songsToAdd = await _autoDjService.getSongsToQueue(
        currentSong: _currentSong,
        currentQueue: _queue,
        availableSongs: _libraryProvider?.cachedAllSongs,
      );

      if (songsToAdd.isNotEmpty) {
        _queue.addAll(songsToAdd);
        if (_concatenatingSource != null) {
          for (final song in songsToAdd) {
            try {
              final source = await _buildAudioSourceForSong(song);
              _concatenatingSource!.add(source);
            } catch (e) {
              debugPrint(
                  'Error adding AutoDJ song to concatenating source: $e');
            }
          }
        }
        notifyListeners();
        _saveQueueState();
        debugPrint('Auto DJ added ${songsToAdd.length} songs to queue');
      }
    } catch (e) {
      debugPrint('Auto DJ error: $e');
    }
  }

  Future<void> skipPrevious() async {
    // 有声书：始终按队列顺序回退（不参与 shuffle/B9 统计）。
    if (_isPlayingAudiobook) {
      if (_position.inSeconds > 3) {
        await seek(Duration.zero);
        return;
      }
      if (_concatenatingSource != null) {
        if (_currentIndex > 0) {
          await _audioPlayer.seek(Duration.zero, index: _currentIndex - 1);
        } else {
          await seek(Duration.zero);
        }
      } else if (_currentIndex > 0) {
        await skipToIndex(_currentIndex - 1);
      } else {
        await seek(Duration.zero);
      }
      return;
    }

    if (_position.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    if (_concatenatingSource != null) {
      if (_shuffleEnabled && _shuffleHistory.isNotEmpty) {
        final prevId = _shuffleHistory.removeLast();
        final prev = _queue.indexWhere((s) => s.id == prevId);
        if (prev != -1) {
          await _audioPlayer.seek(Duration.zero, index: prev);
          return;
        }
      }
      if (_currentIndex > 0) {
        await _audioPlayer.seek(Duration.zero, index: _currentIndex - 1);
      } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
        await _audioPlayer.seek(Duration.zero, index: _queue.length - 1);
      } else {
        await seek(Duration.zero);
      }
      return;
    }

    if (_shuffleEnabled && _shuffleHistory.isNotEmpty) {
      final prevId = _shuffleHistory.removeLast();
      final prev = _queue.indexWhere((s) => s.id == prevId);
      if (prev != -1) await skipToIndex(prev);
    } else if (_currentIndex > 0) {
      await skipToIndex(_currentIndex - 1);
    } else if (_repeatMode == RepeatMode.all && _queue.isNotEmpty) {
      if (_queue.length == 1) {
        await seek(Duration.zero);
        await play();
      } else {
        await skipToIndex(_queue.length - 1);
      }
    } else {
      await seek(Duration.zero);
    }
  }

  Future<void> skipToIndex(int index) async {
    if (index >= 0 && index < _queue.length) {
      if (_concatenatingSource != null) {
        await _audioPlayer.seek(Duration.zero, index: index);
      } else {
        await playSong(
          _queue[index],
          playlist: _queue,
          startIndex: index,
          forcePlay: true,
          // B11：非 gapless 队列内切章必须透传有声书状态，否则
          // _isPlayingAudiobook 被置 false（进度不保存、车载/统计/shuffle 全恢复）。
          audiobook: _isPlayingAudiobook,
          audiobookBook: _currentAudiobook,
        );
      }
    }
  }

  void toggleShuffle() {
    // B10：有声书下强制顺序播放，忽略 shuffle 切换（UI 按钮已隐藏，方法级兜底）。
    if (_isPlayingAudiobook) return;
    _shuffleEnabled = !_shuffleEnabled;
    _shuffleHistory.clear();
    if (_shuffleEnabled && _queue.length > 1 && _currentSong != null) {
      final currentSong = _currentSong!;
      _queue.shuffle();
      _queue.remove(currentSong);
      _queue.insert(0, currentSong);
      _currentIndex = 0;
      _rebuildShuffleOrder();
      if (_concatenatingSource != null) {
        _buildAndSetConcatenatingSource(initialIndex: 0).catchError((e) {
          debugPrint('Error rebuilding concatenating source after shuffle: $e');
        });
      }
      _saveQueueState();
    } else {
      _shuffleOrder = [];
      _shuffleOrderPos = 0;
    }
    _storageService.saveShuffleMode(_shuffleEnabled);
    notifyListeners();
  }

  void toggleRepeat() {
    // B10：有声书下强制 repeat=off，忽略循环切换（UI 按钮已隐藏，方法级兜底）。
    if (_isPlayingAudiobook) return;
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        // When shuffling, keep the player loop off so a completed round fires
        // ProcessingState.completed and we can rebuild with a fresh shuffle
        // order instead of looping the same sequence.
        _audioPlayer.setLoopMode(_shuffleEnabled ? LoopMode.off : LoopMode.all);
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        _audioPlayer.setLoopMode(LoopMode.one);
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        _audioPlayer.setLoopMode(LoopMode.off);
        break;
    }
    _storageService.saveRepeatMode(_repeatMode.index);
    notifyListeners();
  }

  void toggleGaplessPlayback() {
    _gaplessEnabled = !_gaplessEnabled;
    _storageService.saveGaplessPlayback(_gaplessEnabled);
    notifyListeners();
  }

  void addToQueue(Song song) {
    // B12：有声书播放时禁止把歌曲混进章节队列（UI 入口已隐藏，这里是方法级兜底）。
    if (_isPlayingAudiobook) return;
    // Skip duplicates so the queue never contains the same song id twice.
    if (_queue.any((s) => s.id == song.id)) return;
    _queue.add(song);
    notifyListeners();
  }

  Future<void> addToQueueNext(Song song) async {
    // B12：有声书播放时禁止把歌曲混进章节队列。
    if (_isPlayingAudiobook) return;
    // Skip duplicates so the queue never contains the same song id twice.
    if (_queue.any((s) => s.id == song.id)) return;
    final insertIndex = _currentIndex + 1;
    if (insertIndex < _queue.length) {
      _queue.insert(insertIndex, song);
    } else {
      _queue.add(song);
    }
    if (_concatenatingSource != null) {
      try {
        final audioSource = await _buildAudioSourceForSong(song);
        if (insertIndex < _concatenatingSource!.length) {
          _concatenatingSource!.insert(insertIndex, audioSource);
        } else {
          _concatenatingSource!.add(audioSource);
        }
      } catch (e) {
        debugPrint('Error adding to concatenating source: $e');
      }
    }
    notifyListeners();
  }

  Future<void> addAllToQueue(Iterable<Song> songs) async {
    // B12：有声书播放时禁止把歌曲混进章节队列。
    if (_isPlayingAudiobook) return;
    // Skip duplicates so the queue never contains the same song id twice.
    final existingIds = _queue.map((s) => s.id).toSet();
    final newSongs = songs.where((s) => !existingIds.contains(s.id)).toList();
    if (newSongs.isEmpty) return;
    _queue.addAll(newSongs);
    if (_concatenatingSource != null) {
      for (final song in newSongs) {
        try {
          final source = await _buildAudioSourceForSong(song);
          _concatenatingSource!.add(source);
        } catch (e) {
          debugPrint('Error adding to concatenating source: $e');
        }
      }
    }
    notifyListeners();
  }

  void removeFromQueue(int index) {
    // B12：有声书播放时禁止从章节队列移除（破坏 order 语义）。
    if (_isPlayingAudiobook) return;
    if (index >= 0 && index < _queue.length) {
      _queue.removeAt(index);
      if (_concatenatingSource != null &&
          index < _concatenatingSource!.length) {
        try {
          _concatenatingSource!.removeAt(index);
        } catch (e) {
          debugPrint('Error removing from concatenating source: $e');
        }
      }
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex && _queue.isNotEmpty) {
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.length - 1;
        }
        if (_queue.isNotEmpty) {
          playSong(
            _queue[_currentIndex],
            playlist: _queue,
            startIndex: _currentIndex,
          );
        }
      }
      _saveQueueState();
      notifyListeners();
    }
  }

  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _currentSong = null;
    _concatenatingSource = null;
    // 切服务器（main.dart 调 clearQueue）时清有声书状态，避免标志残留
    // （进度归属/车载守卫误判）。
    _isPlayingAudiobook = false;
    _currentAudiobook = null;
    _audiobookChapterOrder = null;
    _audiobookServerKey = null;
    _restorePlaybackSettingsAfterAudiobook();
    try {
      _discordRpcService.clearPresence();
    } catch (_) {}
    // Clear lyrics when clearing queue
    try {
      _lyricsService.stopSync();
    } catch (_) {}
    _clearPersistedQueue();
    try {
      _lyricsService.loadLyrics(null);
    } catch (_) {}
    _audioPlayer.stop();
    _isPlaying = false;
    _position = Duration.zero;
    notifyListeners();
    _updateAndroidAuto();
  }

  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final song = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, song);

    if (_concatenatingSource != null) {
      try {
        _concatenatingSource!.move(oldIndex, newIndex);
      } catch (e) {
        debugPrint('Error moving in concatenating source: $e');
      }
    }

    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex -= 1;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex += 1;
    }

    notifyListeners();
    _saveQueueState();
  }

  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _storageService.saveVolume(_volume);
    if (_castService.isConnected) {
      await _castService.setVolume(_volume);
    } else if (_upnpService.isConnected) {
      await _upnpService.setVolume((_volume * 100).round());
    } else {
      await _applyReplayGain(_currentSong);
    }
    notifyListeners();
  }

  bool _upnpVolumeWriteInProgress = false;

  void _onRemoteVolumeChange(int volume) {
    if (_castService.isConnected) {
      _castService.setVolume(volume / 100.0);
    } else if (_upnpService.isConnected) {
      if (_upnpVolumeWriteInProgress) return;
      _applyUpnpVolume(volume);
    }
  }

  Future<void> _applyUpnpVolume(int volume) async {
    _upnpVolumeWriteInProgress = true;
    _volume = (volume / 100.0).clamp(0.0, 1.0);
    notifyListeners();
    try {
      await _upnpService.setVolume(volume);
      final actual = await _upnpService.getVolume();
      if (actual >= 0) {
        _volume = actual / 100.0;
        _androidSystemService.updateRemoteVolume(actual);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('UPnP setVolume error: $e');
    } finally {
      _upnpVolumeWriteInProgress = false;
    }
  }

  // ── Gapless playback helpers ───────────────────────────────────────────

  Future<AudioSource> _buildAudioSourceForSong(Song song) async {
    if (song.isLocal == true && song.path != null) {
      return AudioSource.uri(Uri.file(song.path!));
    }
    final offlinePath = _offlineService.getLocalPath(song.id);
    if (offlinePath != null) {
      return AudioSource.uri(Uri.file(offlinePath));
    }
    // Apply transcoding settings if enabled (LAN connection always resolves
    // to null → original, rule 1).
    final maxBitRate = _transcodingService.getCurrentBitrate();
    final format = _transcodingService.getCurrentFormat();
    // Only the current song's source reflects the actual active stream;
    // sources for other queue entries are prebuilt and must not overwrite it.
    if (song.id == _currentSong?.id) {
      _setActiveStream(maxBitRate, format);
    }
    final url = _subsonicService.getStreamUrl(song.id,
        maxBitRate: maxBitRate, format: format);
    // Transcoding streams don't support HTTP range requests reliably. Route
    // them straight to ExoPlayer so seeking keeps the target position —
    // LockCachingAudioSource would downgrade range requests to a full 200
    // response and restart playback from the beginning (#170). This applies to
    // the original stream too: on LAN the server often omits the
    // Accept-Ranges header, and seek visibly rewinds to 0:00.
    return AudioSource.uri(Uri.parse(url), tag: song.id);
  }

  Future<void> _buildAndSetConcatenatingSource(
      {required int initialIndex}) async {
    final children = await Future.wait(_queue.map(_buildAudioSourceForSong));
    _concatenatingSource = ConcatenatingAudioSource(children: children);
    await _audioPlayer.setAudioSource(
      _concatenatingSource!,
      initialIndex: initialIndex,
      preload: true,
    );
  }

  Future<void> _prepareCurrentSong() async {
    if (_currentSong == null) return;
    // 恢复当前歌：清掉旧基准与竞态令牌，位置恢复在下面按场景处理
    // （道理鱼转码用 timeOffset 起播，其余用原生 seek）。
    _streamBaseOffsetMs = 0;
    _seekRestartToken++;
    var restoredViaTimeOffset = false; // 道理鱼转码按 timeOffset 起播时置位
    try {
      if (_gaplessEnabled &&
          _queue.isNotEmpty &&
          !_isDaoliyuTranscodeRequested) {
        await _buildAndSetConcatenatingSource(initialIndex: _currentIndex);
      } else {
        final String playUrl;
        if (_currentSong!.isLocal == true && _currentSong!.path != null) {
          playUrl = Uri.file(_currentSong!.path!).toString();
        } else {
          final offlinePath = _offlineService.getLocalPath(_currentSong!.id);
          if (offlinePath != null) {
            playUrl = 'file://$offlinePath';
          } else {
            // Apply transcoding settings if enabled, matching playSong's
            // stream URL so the restore path honors the same bitrate/format.
            // (LAN connection always resolves to null → original, rule 1.)
            final maxBitRate = _transcodingService.getCurrentBitrate();
            final format = _transcodingService.getCurrentFormat();
            _setActiveStream(maxBitRate, format);
            // 道理鱼转码恢复：直接带 timeOffset=<上次位置秒> 起播，避免先起流
            // 再 seek（转码流 seek 无效）；JWT 失败回退 Subsonic URL（从头播）。
            final result = await _buildDaoliyuAwareStreamUrl(
              _currentSong!,
              maxBitRate: maxBitRate,
              format: format,
              timeOffsetSeconds: _position.inSeconds,
            );
            playUrl = result.url;
            restoredViaTimeOffset = result.viaTimeOffset;
          }
        }
        if (_currentSong!.isLocal == true ||
            _offlineService.getLocalPath(_currentSong!.id) != null) {
          await _audioPlayer.setUrl(playUrl);
        } else {
          // Route straight to ExoPlayer so seeking keeps the target position.
          // LockCachingAudioSource would downgrade range requests to a full
          // 200 response and restart playback from the beginning — including
          // on LAN, where the server often omits the Accept-Ranges header and
          // seek visibly rewinds to 0:00.
          await _audioPlayer.setAudioSource(
            AudioSource.uri(Uri.parse(playUrl), tag: _currentSong!.id),
          );
        }
      }
      // Seek to the restored position after the source is loaded. 道理鱼转码
      // 流已按 timeOffset 起播（ExoPlayer 位置从 0 计起）→ 只设基准偏移不再
      // seek；其余场景用原生 seek 恢复。
      if (_position.inMilliseconds > 0) {
        if (restoredViaTimeOffset) {
          _streamBaseOffsetMs = _position.inMilliseconds;
        } else if (_isDaoliyuTranscodeRequested) {
          // 道理鱼转码但未能走 timeOffset（JWT 失败回退）：转码流 seek 无效、
          // 只能从头播，归零位置避免 UI 显示错误进度。
          _position = Duration.zero;
          notifyListeners();
        } else {
          await _audioPlayer.seek(_position);
        }
      }
    } catch (e) {
      debugPrint('Error preparing current song after restore: $e');
    }
  }

  Future<void> _onCurrentIndexChanged(int newIndex) async {
    if (newIndex < 0 || newIndex >= _queue.length) return;
    if (newIndex == _currentIndex) return;

    _bufferStartAt = null; // 切歌：复位缓冲检测，避免旧歌 buffering 残留
    _position = Duration.zero; // 同步归零，避免 stall 判定误用旧曲位置
    _streamBaseOffsetMs = 0; // 切歌：清掉上一首的转码 seek 基准
    _seekRestartToken++; // 切歌：废弃仍在途的重起流
    DiagnosticsService.instance.record(
      EventType.trackNext,
      LogLevel.info,
      {
        'from': _currentSong?.id,
        'to': _queue[newIndex].id,
        'fromTitle': _currentSong?.title,
        'toTitle': _queue[newIndex].title,
      },
    );
    debugPrint(
        '[Player] ⏭ Track changed by index: $newIndex "${_queue[newIndex].title}"');

    // Sleep timer: end after current song
    if (_sleepTimerEndCurrentSong) {
      _doSleepTimerStop();
      return;
    }

    // 有声书 gapless 切章（B3/B7/B9/B16）：跳过 scrobble/_recordSongEnd/
    // AutoDJ/歌词加载；bookmark 推进到新章 order、position=0。
    if (_isPlayingAudiobook) {
      _currentIndex = newIndex;
      _currentSong = _queue[_currentIndex];
      _audiobookChapterOrder = _currentSong?.track;
      _resolvedArtworkUrl = null;
      notifyListeners();
      // 新章从 0 开始（position 已归零），写入进度。
      _saveAudiobookChapterProgress(
        chapterOrder: _audiobookChapterOrder ?? 1,
        positionMs: 0,
        completed: false,
      );
      return;
    }

    // Track completion of the previous song
    if (_currentSong != null) {
      if (_currentSong!.isLocal != true) {
        _subsonicService
            .scrobble(_currentSong!.id, submission: true)
            .catchError(
          (e) {
            _offlineService.queueScrobble(_currentSong!.id, submission: true);
          },
        );
      }
      if (_currentSong != null) {
        _recordSongEnd(_currentSong!, _position.inSeconds, _duration.inSeconds);
      }
    }

    // AutoDJ: add songs near end of queue
    if (_autoDjService.shouldAddSongs(newIndex, _queue.length)) {
      await _addAutoDjSongs();
    }

    _currentIndex = newIndex;
    _currentSong = _queue[_currentIndex];
    _resolvedArtworkUrl = null;
    if (_shuffleEnabled) _syncShuffleOrderPos();
    notifyListeners();
    _saveQueueState();

    await _refreshArtworkUrl();
    if (_currentSong != null) {
      await _loadAndSyncLyrics(_currentSong!);
      await _lyricsService.updateSongInfo(
        title: _currentSong!.title,
        artist: _currentSong!.artist ?? 'Unknown Artist',
        artworkUrl: _resolvedArtworkUrl ?? _currentSong!.coverArt,
      );
      await _applyReplayGain(_currentSong);
    }

    _updateAllServices();
    _updateAndroidAuto();
  }

  Future<void> _applyReplayGain(Song? song) async {
    await _replayGainService.initialize();

    final replayGainMultiplier = _replayGainService.calculateVolumeMultiplier(
      trackGain: song?.replayGainTrackGain,
      albumGain: song?.replayGainAlbumGain,
      trackPeak: song?.replayGainTrackPeak,
      albumPeak: song?.replayGainAlbumPeak,
    );

    final effectiveVolume = _volume * replayGainMultiplier;
    await _audioPlayer.setVolume(effectiveVolume);
  }

  Future<void> refreshReplayGain() async {
    await _applyReplayGain(_currentSong);
    notifyListeners();
  }

  ReplayGainService get replayGainService => _replayGainService;

  Future<void> toggleFavorite() async {
    if (_currentSong == null) return;

    final isStarred = _currentSong!.starred == true;

    final newSong = _currentSong!.copyWith(starred: !isStarred);
    _currentSong = newSong;
    notifyListeners();

    try {
      if (isStarred) {
        await _subsonicService.unstar(id: newSong.id);
      } else {
        await _subsonicService.star(id: newSong.id);
      }
      _libraryProvider?.loadStarred();
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
      _currentSong = _currentSong!.copyWith(starred: isStarred);
      notifyListeners();
    }
  }

  Future<void> toggleFavoriteForSong(Song song) async {
    final isStarred = song.starred == true;
    try {
      if (isStarred) {
        await _subsonicService.unstar(id: song.id);
      } else {
        await _subsonicService.star(id: song.id);
      }
      _libraryProvider?.loadStarred();

      if (_currentSong?.id == song.id) {
        _currentSong = _currentSong!.copyWith(starred: !isStarred);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error toggling favorite for song: $e');
    }
  }

  Future<void> setRating(String songId, int rating) async {
    if (_currentSong?.id != songId) return;

    final previousRating = _currentSong?.userRating;
    _currentSong = _currentSong?.copyWith(userRating: rating);
    notifyListeners();

    try {
      await _subsonicService.setRating(songId, rating);
    } catch (e) {
      _currentSong = _currentSong?.copyWith(userRating: previousRating);
      notifyListeners();
      rethrow;
    }
  }

  /// 退后台回前台：重新激活音频会话（Android/iOS 通用）。
  /// 播放器暂停期间系统会收回会话/焦点（尤其蓝牙断开 + 长时间后台），恢复时
  /// setActive(true) 让下次 play() 的输出管线处于就绪态。不自动恢复播放——
  /// 保持用户离开时的暂停状态。
  Future<void> _reactivateSessionOnResume() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return;
    if (_isRenderingRemotely) return; // 远程播放不干预本地会话
    if (_currentSong == null) return; // 无可播放内容时不抢会话/焦点
    try {
      final session = await AudioSession.instance;
      // setActive(true) 在 Android 上返回音频焦点请求结果（granted/failed）——
      // 必须如实记录，焦点被其他 app 持有时 result=false（此前恒记 true 失真）。
      final ok = await session.setActive(true);
      DiagnosticsService.instance.record(
        EventType.audioSessionState,
        LogLevel.info,
        {'trigger': 'reactivateAfterBackground', 'result': ok},
      );
    } catch (e) {
      DiagnosticsService.instance.record(
        EventType.audioSessionState,
        LogLevel.warn,
        {
          'trigger': 'reactivateAfterBackground',
          'result': false,
          'error': '$e',
        },
      );
    }
  }

  Future<void> reactivateAudioSession() async {
    final focusGranted = await _androidSystemService.requestAudioFocus();
    DiagnosticsService.instance.record(
      EventType.audioSessionState,
      LogLevel.info,
      {
        'trigger': 'reactivate',
        'focusGranted': focusGranted,
        'playerPlaying': _audioPlayer.playing,
        'processingState': _audioPlayer.processingState.name,
        'posMs': _audioPlayer.position.inMilliseconds,
        'songId': _currentSong?.id,
      },
    );

    if (_currentSong != null) {
      _updateAllServices();
    }

    if (Platform.isIOS) {
      try {
        final session = await AudioSession.instance;
        await session.setActive(true);

        // Wait a bit for the audio session to stabilize
        await Future.delayed(const Duration(milliseconds: 100));

        // If there's a current song and audio is not playing, resume it
        // This handles the case where iOS pauses audio when dismissing the player
        if (_currentSong != null && !_audioPlayer.playing) {
          debugPrint(
              '[Player] iOS: Resuming playback after audio session reactivation (song: ${_currentSong!.title})');
          _startPlayback();
          _isPlaying = true;
          notifyListeners();
          _updateAllServices();
        }
      } catch (e) {
        debugPrint('[Player] iOS: Error reactivating audio session: $e');
      }
    }
  }

  @override
  void dispose() {
    _sleepTimer?.cancel();
    _sleepTimerFadeTimer?.cancel();
    _sleepTimerFadePeriodicTimer?.cancel();
    _bufferStartAt = null; // dispose：复位缓冲检测
    // Save queue state immediately before cancelling the debounce timer
    _saveQueueStateImmediate();
    _persistDebounceTimer?.cancel();
    _windowsPositionTimer?.cancel();
    _castService.removeListener(_onCastStateChanged);
    _upnpService.removeListener(_onUpnpStateChanged);
    if (_upnpService.onRendererLost == _onUpnpRendererLost) {
      _upnpService.onRendererLost = null;
    }
    // Stop playback before disposing audio handler to prevent NPE on Android
    _audioPlayer.stop().catchError((_) {});

    // Dispose audio handler with error handling
    _audioHandler.customAction('dispose').catchError((e) {
      debugPrint('Error disposing audio handler: $e');
    });

    try {
      _androidAutoService.dispose();
    } catch (_) {}
    try {
      _androidSystemService.dispose();
    } catch (_) {}
    try {
      _windowsService.dispose();
    } catch (_) {}
    try {
      _bluetoothService.dispose();
    } catch (_) {}
    try {
      _samsungService.dispose();
    } catch (_) {}

    // Dispose lyrics service
    try {
      _lyricsService.dispose();
    } catch (_) {}

    try {
      _discordRpcService.shutdown();
    } catch (_) {}
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _currentIndexSub?.cancel();
    _devicesSub?.cancel();
    _devicesSub = null;
    _positionController.close();
    // Remove app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _discordStateText() {
    switch (_discordRpcStateStyle) {
      case 'song_title':
        return _currentSong?.title ?? 'Unknown Song';
      case 'app_name':
        return 'Luobo';
      case 'artist':
      default:
        return _currentSong?.artist ?? 'Unknown Artist';
    }
  }

  void _updateDiscordRpc() {
    try {
      if (_currentSong == null) {
        _discordRpcService.clearPresence();
        return;
      }

      final int now = DateTime.now().millisecondsSinceEpoch;
      final int startTimestamp = now - _position.inMilliseconds;
      final int? endTimestamp = _isPlaying && _duration.inMilliseconds > 0
          ? startTimestamp + _duration.inMilliseconds
          : null;

      final stateText = _discordStateText();

      _discordRpcService.updatePresence(
        state: stateText,
        details: _currentSong!.title,
        largeImageKey: 'musly_logo',
        largeImageText: _currentSong!.album,
        smallImageKey: 'musly_logo',
        smallImageText: _isPlaying ? 'Playing' : 'Paused',
        startTime: startTimestamp,
        endTime: endTimestamp,
      );
    } catch (_) {}
  }

  Future<void> setDiscordRpcEnabled(bool enabled) async {
    try {
      await _discordRpcService.setEnabled(enabled);
      if (enabled) {
        _updateDiscordRpc();
      }
    } catch (_) {}
  }

  bool get discordRpcEnabled => _discordRpcService.enabled;

  String _discordRpcStateStyle = 'artist';

  Future<void> loadDiscordRpcStateStyle() async {
    _discordRpcStateStyle = await _storageService.getDiscordRpcStateStyle();
  }

  Future<void> setDiscordRpcStateStyle(String style) async {
    _discordRpcStateStyle = style;
    await _storageService.saveDiscordRpcStateStyle(style);
    _updateDiscordRpc();
    notifyListeners();
  }

  String get discordRpcStateStyle => _discordRpcStateStyle;

  void _onCastStateChanged() {
    notifyListeners();
    if (_castService.isConnected) {
      _audioPlayer.pause();
      _silentCheckToken++; // 使挂起的无声检测失效：切远端后不误触发本地自愈
      // 切远端 ⇒ 作废挂起的「打断后自动恢复」意图（方案 B §4.1 步骤 3）。
      _wasPlayingBeforeInterruption = false;
      _androidSystemService.setRemotePlayback(isRemote: true, volume: 50);
      if (_currentSong != null) {
        final song = _currentSong!;
        _currentSong = null;
        playSong(song);
      }
    } else {
      _isRenderingRemotely = false;
      _androidSystemService.setRemotePlayback(isRemote: false);
      _isPlaying = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  bool _upnpWasConnected = false;
  bool _upnpWasPlaying = false;
  // True when an A2DP audio-output device (car, speaker) is connected.
  // Control-only devices (Garmin watch, etc.) don't set this flag.
  bool _isA2dpAudioActive = false;

  void _onUpnpStateChanged() {
    final connected = _upnpService.isConnected;

    if (connected && !_upnpWasConnected) {
      _upnpWasConnected = true;
      _upnpWasPlaying = false;
      if (_audioPlayer.playing) _audioPlayer.pause();
      _silentCheckToken++; // 使挂起的无声检测失效：切远端后不误触发本地自愈
      // 切远端 ⇒ 作废挂起的「打断后自动恢复」意图（方案 B §4.1 步骤 3）。
      _wasPlayingBeforeInterruption = false;
      final vol = _upnpService.volume;

      if (vol >= 0) _volume = vol / 100.0;
      _androidSystemService.setRemotePlayback(
        isRemote: true,
        volume: vol >= 0 ? vol : 50,
      );
      if (_currentSong != null) {
        final song = _currentSong!;
        _currentSong = null;
        playSong(song);
      }
      return;
    }

    if (!connected && _upnpWasConnected) {
      _upnpWasConnected = false;
      _upnpWasPlaying = false;
      _isRenderingRemotely = false;
      _isPlaying = false;
      // Preserve _position and _duration so the UI shows where we were.
      _androidSystemService.setRemotePlayback(isRemote: false);
      notifyListeners();
      _updateAndroidAuto();
      return;
    }

    if (!connected) return;

    final pos = _upnpService.rendererPosition;
    final dur = _upnpService.rendererDuration;
    final playing = _upnpService.isRendererPlaying;
    final rendererState = _upnpService.rendererState;

    if (_upnpWasPlaying && rendererState == 'STOPPED') {
      // _upnpWasPlaying is reset to false in playSong() and stop() before
      // any Stop command is sent, so this only fires for a *natural* track
      // end.  We don't check duration > 0 here because many renderers
      // (including moode/upmpdcli) return 0:00:00 from GetPositionInfo once
      // the transport is stopped, which would cause the check to silently fail.
      debugPrint(
          'UPnP: Track ended (pos=${pos.inSeconds}s, dur=${dur.inSeconds}s) — advancing');
      _upnpWasPlaying = false;
      _completedSong = _currentSong;
      _onSongComplete()
          .catchError((e) => debugPrint('[Player] _onSongComplete error: $e'));
      return;
    }

    _upnpWasPlaying = playing;

    bool changed = false;

    if ((_position - pos).abs() > const Duration(milliseconds: 500)) {
      _position = pos;
      changed = true;
    }
    if (dur != _duration) {
      _duration = dur;
      changed = true;
    }
    if (playing != _isPlaying) {
      _isPlaying = playing;
      changed = true;
    }

    final vol = _upnpService.volume;
    if (vol >= 0 && !_upnpVolumeWriteInProgress) {
      final normalized = vol / 100.0;
      if ((_volume - normalized).abs() > 0.005) {
        _volume = normalized;
        changed = true;
        _androidSystemService.updateRemoteVolume(vol);
      }
    }

    if (changed) {
      _positionController.add(_position);
      notifyListeners();
      _updateAndroidAuto();
    }
  }

  /// Called by [UpnpService] after 30 consecutive poll failures (~30 s).
  /// [_onUpnpStateChanged] has already switched us off remote playback and
  /// preserved [_position]. Load the song into the local player at the last
  /// known position, paused, so the user can resume wherever they want.
  /// Android routes audio to a connected A2DP device automatically.
  Future<void> _onUpnpRendererLost() async {
    final lastPosition = _position;
    final lastSong = _currentSong;

    debugPrint(
      'UPnP: renderer lost — A2DP audio active: $_isA2dpAudioActive, '
      'last position: ${lastPosition.inSeconds}s, song: "${lastSong?.title}"',
    );

    if (lastSong == null) return;

    final playUrl = lastSong.isLocal == true && lastSong.path != null
        ? Uri.file(lastSong.path!).toString()
        : _offlineService.getPlayableUrl(lastSong, _subsonicService);

    _isLoading = true;
    notifyListeners();

    try {
      await _audioPlayer.setUrl(playUrl);
      _position = lastPosition;
      await _audioPlayer.seek(lastPosition);
      // Leave paused — let the user consciously resume on their new output.
    } catch (e) {
      debugPrint('UPnP fallback: failed to reload local player: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      _updateAndroidAuto();
    }
  }
}
