import 'dart:async';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/diagnostics/diagnostics.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/storage_service.dart';
import '../services/lrclib_service.dart';
import '../services/lyrics/lyrics_cache.dart';
import '../services/netease_lyrics_service.dart';
import '../models/lyrics.dart';
import '../models/song.dart';
import '../widgets/album_artwork.dart' show isLocalFilePath;
import '../utils/image_cache.dart';

class CarModeScreen extends StatefulWidget {
  const CarModeScreen({super.key});

  @override
  State<CarModeScreen> createState() => _CarModeScreenState();
}

class _CarModeScreenState extends State<CarModeScreen>
    with TickerProviderStateMixin {
  SyncedLyrics? _lyrics;
  bool _lyricsLoading = true;
  String? _currentSongId;

  // Triple-tap to favorite
  int _tapCount = 0;
  Timer? _tapTimer;
  DateTime _lastTapTime = DateTime.now();
  bool? _favOverride; // 本地记忆收藏状态（歌曲对象不会自动更新 starred）
  Set<String>? _starredIds; // 本次车载会话缓存的已收藏歌曲 ID（权威来源 getStarred）
  bool _starredFetching = false;
  bool _feedbackVisible = false;
  bool _feedbackFavorited = true;
  bool _feedbackFailed = false;
  late final AnimationController _feedbackController;

  // Drag-to-dismiss state
  double _dragOffset = 0.0;
  bool _isDragging = false;
  static const double _dismissThreshold = 150.0;
  static const double _maxDragDistance = 400.0;

  double get _morphProgress => (_dragOffset / _maxDragDistance).clamp(0.0, 1.0);
  double get _scale => 1.0 - (_morphProgress * 0.15);
  double get _borderRadius => _morphProgress * 32.0;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
    final frameSw = Stopwatch()..start();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MetricsCollector.buildTime('CarModeScreen', frameSw.elapsedMilliseconds);
    });
    DiagnosticsService.instance.record(
      EventType.animActive,
      LogLevel.info,
      {'anim': 'carFeedback', 'pulseMs': 1200},
    );
    _feedbackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _feedbackVisible = false);
        }
      });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLyricsForCurrentSong();
      _ensureStarredIds();
    });
  }

  /// 从服务端拉取已收藏歌曲 ID 列表（每个车载会话只拉一次），
  /// 用于在 song.starred 缺失/过期时判断当前歌曲是否已收藏。
  Future<void> _ensureStarredIds() async {
    if (_starredIds != null || _starredFetching) return;
    _starredFetching = true;
    try {
      final subsonic = Provider.of<SubsonicService>(context, listen: false);
      final starred = await subsonic.getStarred();
      if (!mounted) return;
      setState(() {
        _starredIds = starred.songs.map((s) => s.id).toSet();
      });
    } catch (_) {
      // 失败时置空，避免后续重复请求
      _starredIds = const {};
    } finally {
      _starredFetching = false;
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _feedbackController.dispose();
    _tapTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLyricsForCurrentSong() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final song = player.currentSong;
    if (song == null) return;
    if (_currentSongId == song.id) return;
    _currentSongId = song.id;
    _favOverride = null;

    setState(() {
      _lyricsLoading = true;
      _lyrics = null;
    });

    try {
      final subsonicService =
          Provider.of<SubsonicService>(context, listen: false);
      final offlineService = OfflineService();
      final serverSource = subsonicService.isDaoliyu
          ? LyricsCacheSource.daoliyu
          : LyricsCacheSource.server;
      final cached = await offlineService.getLocalLyrics(song.id);
      // 缓存来源可信（服务器来源）直接用；来源是兜底或旧缓存无标记时，本会话首次
      // 复查一次服务器，命中则覆盖缓存 —— 解决「兜底永久占位」（§2.4 / §5.3）。
      final outcome = await resolveLyricsCache(
        songId: song.id,
        cached: cached,
        serverSource: serverSource,
        fetchServerLyrics: () => subsonicService.getLyricsBySongId(song.id),
        saveCache: (payload) => offlineService.saveLyrics(song.id, payload),
      );
      Map<String, dynamic>? syncedData =
          outcome.payload?['lyricsList'] as Map<String, dynamic>?;
      if (syncedData == null) {
        syncedData = await subsonicService.getLyricsBySongId(song.id);
        // 服务器命中 → 写缓存（§5.3）
        if (syncedData != null) {
          await offlineService.saveLyrics(
            song.id,
            withLyricsCacheMeta({'lyricsList': syncedData}, serverSource),
          );
        }
      }

      if (!mounted) return;

      if (syncedData != null) {
        final structuredLyrics = syncedData['structuredLyrics'];
        if (structuredLyrics is List && structuredLyrics.isNotEmpty) {
          final syncedEntry =
              structuredLyrics.cast<Map<String, dynamic>>().firstWhere(
                    (l) => l['synced'] == true,
                    orElse: () => <String, dynamic>{},
                  );
          final lines = syncedEntry['line'] as List?;
          if (lines != null && lines.isNotEmpty) {
            final parsedLines = lines
                .map<LyricLine>((line) {
                  final start = line['start'] as int? ?? 0;
                  return LyricLine(
                    timestamp: Duration(milliseconds: start),
                    text: line['value']?.toString() ?? '',
                  );
                })
                .where((l) => l.text.isNotEmpty)
                .toList();
            if (parsedLines.isNotEmpty) {
              setState(() {
                _lyrics = SyncedLyrics(lines: parsedLines);
                _lyricsLoading = false;
              });
              return;
            }
          }
        }
      }

      Map<String, dynamic>? plainData =
          outcome.payload?['lyrics'] as Map<String, dynamic>?;
      if (plainData == null) {
        plainData = await subsonicService.getLyrics(
          artist: song.artist,
          title: song.title,
          id: song.id,
        );
        // 服务器命中 → 写缓存（§5.3）
        if (plainData != null) {
          await offlineService.saveLyrics(
            song.id,
            withLyricsCacheMeta({'lyrics': plainData}, serverSource),
          );
        }
      }

      if (!mounted) return;

      if (plainData != null) {
        final value = plainData['value']?.toString();
        if (value != null && value.isNotEmpty) {
          if (value.contains('[') && value.contains(':')) {
            setState(() {
              _lyrics = SyncedLyrics.fromLrc(value);
              _lyricsLoading = false;
            });
          } else {
            setState(() {
              _lyrics = SyncedLyrics.fromPlainText(value);
              _lyricsLoading = false;
            });
          }
          return;
        }
      }

      // ── LRCLIB fallback（与歌词页面一致）──────────────────────────────
      final storageService = StorageService();
      final lrcLibEnabled = await storageService.getLrcLibFallback();
      if (lrcLibEnabled && song.artist != null) {
        final lrclib = LrcLibService();
        final fallbackLyrics = await lrclib.searchLyrics(
          artist: song.artist!,
          title: song.title,
          durationSeconds: song.duration,
        );
        if (fallbackLyrics != null) {
          // 缓存到本地，避免重复请求
          final cacheMap = <String, dynamic>{};
          if (fallbackLyrics.containsKey('structuredLyrics')) {
            cacheMap['lyricsList'] = fallbackLyrics;
          } else {
            cacheMap['lyrics'] = fallbackLyrics;
          }
          await offlineService.saveLyrics(
            song.id,
            withLyricsCacheMeta(cacheMap, LyricsCacheSource.lrclib),
          );

          if (fallbackLyrics.containsKey('structuredLyrics')) {
            final structured = fallbackLyrics['structuredLyrics'];
            if (structured is List && structured.isNotEmpty) {
              final entry = structured.cast<Map<String, dynamic>>().firstWhere(
                    (l) => l['synced'] == true,
                    orElse: () => <String, dynamic>{},
                  );
              final lines = entry['line'] as List?;
              if (lines != null && lines.isNotEmpty) {
                final parsedLines = lines
                    .map<LyricLine>((line) {
                      final start = line['start'] as int? ?? 0;
                      return LyricLine(
                        timestamp: Duration(milliseconds: start),
                        text: line['value']?.toString() ?? '',
                      );
                    })
                    .where((line) => line.text.isNotEmpty)
                    .toList();
                if (parsedLines.isNotEmpty && mounted) {
                  setState(() {
                    _lyrics = SyncedLyrics(lines: parsedLines);
                    _lyricsLoading = false;
                  });
                  return;
                }
              }
            }
          } else {
            final value = fallbackLyrics['value']?.toString();
            if (value != null && value.isNotEmpty && mounted) {
              if (value.contains('[') && value.contains(':')) {
                setState(() {
                  _lyrics = SyncedLyrics.fromLrc(value);
                  _lyricsLoading = false;
                });
              } else {
                setState(() {
                  _lyrics = SyncedLyrics.fromPlainText(value);
                  _lyricsLoading = false;
                });
              }
              return;
            }
          }
        }
      }

      // ── NetEase Cloud Music fallback（与歌词页面一致）─────────────────
      final neteaseEnabled = await storageService.getNeteaseFallback();
      if (neteaseEnabled && song.artist != null) {
        final netease = NeteaseLyricsService();
        final neteaseLyrics = await netease.searchLyrics(
          artist: song.artist!,
          title: song.title,
          durationSeconds: song.duration,
        );
        if (neteaseLyrics != null) {
          // 缓存到本地，避免重复请求
          final cacheMap = <String, dynamic>{};
          if (neteaseLyrics.containsKey('structuredLyrics')) {
            cacheMap['lyricsList'] = neteaseLyrics;
          } else {
            cacheMap['lyrics'] = neteaseLyrics;
          }
          await offlineService.saveLyrics(
            song.id,
            withLyricsCacheMeta(cacheMap, LyricsCacheSource.netease),
          );

          if (neteaseLyrics.containsKey('structuredLyrics')) {
            final structured = neteaseLyrics['structuredLyrics'];
            if (structured is List && structured.isNotEmpty) {
              final entry = structured.cast<Map<String, dynamic>>().firstWhere(
                    (l) => l['synced'] == true,
                    orElse: () => <String, dynamic>{},
                  );
              final lines = entry['line'] as List?;
              if (lines != null && lines.isNotEmpty) {
                final parsedLines = lines
                    .map<LyricLine>((line) {
                      final start = line['start'] as int? ?? 0;
                      return LyricLine(
                        timestamp: Duration(milliseconds: start),
                        text: line['value']?.toString() ?? '',
                      );
                    })
                    .where((line) => line.text.isNotEmpty)
                    .toList();
                if (parsedLines.isNotEmpty && mounted) {
                  setState(() {
                    _lyrics = SyncedLyrics(lines: parsedLines);
                    _lyricsLoading = false;
                  });
                  return;
                }
              }
            }
          } else {
            final value = neteaseLyrics['value']?.toString();
            if (value != null && value.isNotEmpty && mounted) {
              if (value.contains('[') && value.contains(':')) {
                setState(() {
                  _lyrics = SyncedLyrics.fromLrc(value);
                  _lyricsLoading = false;
                });
              } else {
                setState(() {
                  _lyrics = SyncedLyrics.fromPlainText(value);
                  _lyricsLoading = false;
                });
              }
              return;
            }
          }
        }
      }

      setState(() => _lyricsLoading = false);
    } catch (_) {
      if (mounted) setState(() => _lyricsLoading = false);
    }
  }

  String? _getCoverArtUrl(BuildContext context, Song? song) {
    if (song == null) return null;
    // Normalize to the album cover so every song of an album shares one URL.
    final coverId = Provider.of<LibraryProvider>(context, listen: false)
        .effectiveCoverArt(song);
    if (isLocalFilePath(coverId)) return coverId;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    return subsonic.getCoverArtUrl(coverId, size: kCoverArtRequestSize);
  }

  /// 三连击（600ms 内连续 3 次点按）收藏当前歌曲
  void _handleTripleTap() {
    final now = DateTime.now();
    if (now.difference(_lastTapTime) > const Duration(milliseconds: 600)) {
      _tapCount = 0;
    }
    _lastTapTime = now;
    _tapCount++;
    _tapTimer?.cancel();
    if (_tapCount >= 3) {
      _tapCount = 0;
      _favoriteSong();
    } else {
      _tapTimer = Timer(const Duration(milliseconds: 600), () {
        _tapCount = 0;
      });
    }
  }

  /// 收藏当前歌曲（已收藏则只提示，不做取消操作）
  Future<void> _favoriteSong() async {
    final player = Provider.of<PlayerProvider>(context, listen: false);
    final song = player.currentSong;
    if (song == null) return;
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final isFavorite = _favOverride ??
        (_starredIds?.contains(song.id) ?? (song.starred ?? false));
    if (isFavorite) {
      _showFavoriteFeedback(favorited: true, failed: false);
      return;
    }
    try {
      await subsonic.star(id: song.id);
      _favOverride = true;
      _starredIds = {...?_starredIds, song.id};
      _showFavoriteFeedback(favorited: true, failed: false);
    } catch (_) {
      _showFavoriteFeedback(favorited: false, failed: true);
    }
  }

  void _showFavoriteFeedback({
    required bool favorited,
    required bool failed,
  }) {
    setState(() {
      _feedbackFavorited = favorited;
      _feedbackFailed = failed;
      _feedbackVisible = true;
    });
    _feedbackController.forward(from: 0);
  }

  /// 居中的醒目收藏反馈：大爱心 + 光晕 + 弹性弹出 + 渐隐
  Widget _buildFeedbackOverlay() {
    return IgnorePointer(
      child: Center(
        child: AnimatedBuilder(
          animation: _feedbackController,
          builder: (context, _) {
            final t = _feedbackController.value;
            final popT = (t / 0.35).clamp(0.0, 1.0);
            final scale = Curves.elasticOut.transform(popT);
            final opacity = t <= 0.55 ? 1.0 : (1.0 - (t - 0.55) / 0.45);
            final color = _feedbackFailed
                ? Colors.grey
                : (_feedbackFavorited ? Colors.redAccent : Colors.blueGrey);
            return Opacity(
              opacity: opacity.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.6),
                        blurRadius: 30,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _feedbackFailed
                            ? Icons.error_outline_rounded
                            : Icons.favorite_rounded,
                        color: color,
                        size: 64,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _feedbackFailed
                            ? '操作失败'
                            : (_feedbackFavorited ? '已收藏' : '已取消收藏'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: GestureDetector(
            onVerticalDragStart: (_) {
              _isDragging = true;
            },
            onVerticalDragUpdate: (details) {
              if (!_isDragging) return;
              setState(() {
                _dragOffset = (_dragOffset + details.delta.dy).clamp(
                  0.0,
                  double.infinity,
                );
              });
            },
            onVerticalDragEnd: (details) {
              if (!_isDragging) return;
              _isDragging = false;
              final velocity = details.primaryVelocity ?? 0;
              final dismiss = _dragOffset > _dismissThreshold || velocity > 800;
              DiagnosticsService.instance.record(
                EventType.carDrag,
                LogLevel.info,
                {
                  'dragOffset': _dragOffset.round(),
                  'velocity': velocity.round(),
                  'dismiss': dismiss,
                },
              );
              if (dismiss) {
                setState(() {
                  _dragOffset = MediaQuery.of(context).size.height;
                });
                Future.delayed(const Duration(milliseconds: 250), () {
                  if (mounted) Navigator.pop(context);
                });
              } else {
                setState(() {
                  _dragOffset = 0.0;
                });
              }
            },
            onTap: _handleTripleTap,
            child: Stack(
              children: [
                AnimatedOpacity(
                  duration: _isDragging
                      ? Duration.zero
                      : const Duration(milliseconds: 250),
                  opacity: (1.0 - _morphProgress).clamp(0.0, 1.0),
                  child: AnimatedContainer(
                    duration: _isDragging
                        ? Duration.zero
                        : const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    transform: Matrix4.identity()..translate(0.0, _dragOffset),
                    transformAlignment: Alignment.topCenter,
                    child: Transform.scale(
                      scale: _scale,
                      alignment: Alignment.center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(_borderRadius),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: SafeArea(
                          bottom: false,
                          child: Consumer<PlayerProvider>(
                            builder: (context, player, _) {
                              final song = player.currentSong;
                              final coverUrl = _getCoverArtUrl(context, song);
                              final isFavorited = _favOverride ??
                                  (_starredIds?.contains(song?.id) ??
                                      (song?.starred ?? false));

                              // Reload lyrics if song changed
                              if (song != null && song.id != _currentSongId) {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) {
                                  _loadLyricsForCurrentSong();
                                });
                              }

                              return Column(
                                children: [
                                  // Top: close button
                                  Align(
                                    alignment: Alignment.topRight,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: GestureDetector(
                                        onTap: () => Navigator.pop(context),
                                        child: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Song title + artist · album
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            song?.title ?? '',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isFavorited) ...[
                                          const SizedBox(width: 6),
                                          const Icon(
                                            Icons.favorite_border_rounded,
                                            color: Colors.redAccent,
                                            size: 18,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32),
                                    child: Builder(
                                      builder: (context) {
                                        final artist = song?.artist;
                                        final album = song?.album;
                                        return Text(
                                          [
                                            if (artist != null &&
                                                artist.isNotEmpty)
                                              artist,
                                            if (album != null &&
                                                album.isNotEmpty)
                                              album,
                                          ].join(' · '),
                                          style: TextStyle(
                                            color: Colors.white
                                                .withValues(alpha: 0.6),
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Album cover (small)
                                  if (coverUrl != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        cacheManager: coverCacheManager,
                                        imageUrl: coverUrl,
                                        cacheKey:
                                            coverArtCacheKeyFromUrl(coverUrl),
                                        width: 120,
                                        height: 120,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[900],
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 120,
                                          height: 120,
                                          color: Colors.grey[900],
                                          child: const Icon(
                                            CupertinoIcons.music_note,
                                            color: Colors.white54,
                                            size: 40,
                                          ),
                                        ),
                                      ),
                                    ),
                                  // Lyrics area (expanded, shows 3 real lines)
                                  Expanded(
                                    child: _CarModeLyrics(
                                      player: player,
                                      lyrics: _lyrics,
                                      isLoading: _lyricsLoading,
                                    ),
                                  ),
                                  // Playback controls with progress ring
                                  Padding(
                                    padding: EdgeInsets.only(
                                      bottom: MediaQuery.of(context)
                                              .padding
                                              .bottom +
                                          20,
                                    ),
                                    child: _CarModeControls(player: player),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_feedbackVisible) _buildFeedbackOverlay(),
              ],
            ),
          ),
        ));
  }
}

class _CarModeLyrics extends StatelessWidget {
  final PlayerProvider player;
  final SyncedLyrics? lyrics;
  final bool isLoading;

  const _CarModeLyrics({
    required this.player,
    required this.lyrics,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white38),
      );
    }

    if (lyrics == null || lyrics!.isEmpty) {
      return const Center(
        child: Text(
          '暂无歌词',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 20,
          ),
        ),
      );
    }

    return StreamBuilder<Duration>(
      stream: player.positionStream,
      initialData: player.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final currentIndex = lyrics!.getCurrentLineIndex(position);
        final lines = lyrics!.lines;

        final prevLine = currentIndex > 0 ? lines[currentIndex - 1].text : '';
        final currentLine = currentIndex >= 0 ? lines[currentIndex].text : '';
        final nextLine = currentIndex >= 0 && currentIndex < lines.length - 1
            ? lines[currentIndex + 1].text
            : '';

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Previous line
              Text(
                prevLine,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 27,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Current line (highlighted)
              Text(
                currentLine,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Next line
              Text(
                nextLine,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 27,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CarModeControls extends StatelessWidget {
  final PlayerProvider player;

  const _CarModeControls({required this.player});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: player.positionStream,
      initialData: player.position,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = player.effectiveDuration;
        final progress = duration.inMilliseconds > 0
            ? (position.inMilliseconds / duration.inMilliseconds)
                .clamp(0.0, 1.0)
            : 0.0;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Previous
            IconButton(
              onPressed: player.skipPrevious,
              iconSize: 40,
              icon: const Icon(
                CupertinoIcons.backward_fill,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 32),
            // Play/Pause with progress ring
            GestureDetector(
              onTap: player.togglePlayPause,
              child: SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 3,
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    // Progress ring
                    SizedBox(
                      width: 72,
                      height: 72,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 3,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Play/Pause icon
                    Icon(
                      player.isPlaying
                          ? CupertinoIcons.pause_fill
                          : CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 32,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 32),
            // Next
            IconButton(
              onPressed: player.hasNext ? player.skipNext : null,
              iconSize: 40,
              icon: Icon(
                CupertinoIcons.forward_fill,
                color: player.hasNext
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
      },
    );
  }
}
