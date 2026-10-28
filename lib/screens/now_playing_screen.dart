import 'dart:async';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/sleep_timer_sheet.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../l10n/app_localizations.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/diagnostics/diagnostics.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../services/player_ui_settings_service.dart';
import '../widgets/star_rating_widget.dart';
import '../widgets/dolby_atmos_badge.dart';
import '../theme/app_theme.dart';
import '../utils/navigation_helper.dart';
import '../utils/image_cache.dart';
import '../utils/screen_helper.dart';
import '../utils/car_mode_auto_entry.dart';
import '../widgets/synced_lyrics_view.dart';
import '../widgets/compact_lyrics_view.dart';
import 'album_screen.dart';
import 'car_mode_screen.dart';
import '../widgets/multi_artist_widget.dart';
import '../widgets/song_tile.dart' show SongMenuContext, showSongMenuSheet;
import '../widgets/album_artwork.dart' show AlbumArtwork, isLocalFilePath;
import '../theme/design_tokens.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/player_progress_bar.dart';

const _kCarouselGap = 40.0;

class NowPlayingScreen extends StatefulWidget {
  const NowPlayingScreen({super.key});

  @override
  State<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends State<NowPlayingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  String? _cachedImageUrl;
  String? _cachedThumbnailUrl;
  String? _cachedCoverArtId;
  bool _showLyricsInternal = false;
  bool get _showLyrics => _showLyricsInternal;
  set _showLyrics(bool value) {
    if (_showLyricsInternal == value) return;
    _showLyricsInternal = value;
    _updateWakelock();
    _onLyricsModeChanged();
  }

  Future<void> _updateWakelock() async {
    if (kIsWeb) return;
    try {
      if (_showLyricsInternal) {
        await WakelockPlus.enable();
      } else {
        await WakelockPlus.disable();
      }
    } catch (e) {
      debugPrint('Failed to update wake lock: $e');
    }
  }

  double _dragOffset = 0.0;
  bool _isDragging = false;
  static const double _dismissThreshold = 150.0;
  static const double _maxDragDistance = 400.0;

  double get _morphProgress => (_dragOffset / _maxDragDistance).clamp(0.0, 1.0);

  double get _scale => 1.0 - (_morphProgress * 0.15);
  double get _borderRadius => _morphProgress * 32.0;

  double _horizontalDragOffset = 0.0;
  bool _isHorizontalDragging = false;
  Song? _previewSong;
  bool _isSwipeAnimating = false;
  bool _hasTriggeredHaptic = false;
  double _currentArtworkSize = 0.0;
  late AnimationController _swipeAnimationController;
  static const double _swipeThreshold = 80.0;
  static const double _swipeVelocityThreshold = 600.0;

  // ── 播放页停留 30s 自动进入车载页 ─────────────────────────────────────────
  // 仅播放中计时；任何触摸重置倒计时；进入车载页/离开本页/应用退后台时取消。
  static const Duration _autoCarModeDelay = Duration(seconds: 30);
  Timer? _autoCarModeTimer;
  late final PlayerProvider _playerProvider;
  bool _appBackgrounded = false;
  bool _carModeOpen = false;

  double get _swipeProgress =>
      (_horizontalDragOffset.abs() / _swipeThreshold).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _swipeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _playerProvider = context.read<PlayerProvider>();
    _playerProvider.addListener(_onPlayerChanged);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.pointerRouter.addGlobalRoute(_onGlobalPointerDown);
    // 已处于播放中时立即开始倒计时（不依赖下一次 provider 通知）。
    _syncAutoCarModeTimer(isPlaying: _playerProvider.isPlaying);
  }

  @override
  void dispose() {
    _autoCarModeTimer?.cancel();
    WidgetsBinding.instance.pointerRouter
        .removeGlobalRoute(_onGlobalPointerDown);
    WidgetsBinding.instance.removeObserver(this);
    _playerProvider.removeListener(_onPlayerChanged);
    _swipeAnimationController.dispose();
    if (_showLyricsInternal && !kIsWeb) {
      unawaited(WakelockPlus.disable());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final backgrounded = state != AppLifecycleState.resumed;
    if (backgrounded == _appBackgrounded) return;
    _appBackgrounded = backgrounded;
    if (backgrounded) {
      // 退后台暂停计时，回到前台若仍满足条件则重新开始。
      _autoCarModeTimer?.cancel();
      _autoCarModeTimer = null;
    } else {
      _syncAutoCarModeTimer(isPlaying: _playerProvider.isPlaying);
    }
  }

  void _onPlayerChanged() {
    _syncAutoCarModeTimer(isPlaying: _playerProvider.isPlaying);
  }

  void _onGlobalPointerDown(PointerEvent event) {
    // 任意触摸重置倒计时（全局 pointer 路由，仅在有计时器运行时生效）。
    _resetAutoCarModeTimer();
  }

  void _onLyricsModeChanged() {
    if (_showLyrics) {
      // 歌词页展示时不进入车载页：取消计时，退出歌词后重新开始。
      _autoCarModeTimer?.cancel();
      _autoCarModeTimer = null;
    } else {
      _syncAutoCarModeTimer(isPlaying: _playerProvider.isPlaying);
    }
  }

  void _syncAutoCarModeTimer({required bool isPlaying}) {
    if (!mounted) return;
    if (shouldRunAutoCarModeTimer(
      isPlaying: isPlaying,
      isPlayingRadio: _playerProvider.isPlayingRadio,
      isPlayingAudiobook: _playerProvider.isPlayingAudiobook,
      appBackgrounded: _appBackgrounded,
      carModeOpen: _carModeOpen,
      lyricsShowing: _showLyrics,
      autoEntryEnabled:
          PlayerUiSettingsService().getAutoCarModeEntry(),
    )) {
      if (_autoCarModeTimer == null) _startAutoCarModeTimer();
    } else {
      _autoCarModeTimer?.cancel();
      _autoCarModeTimer = null;
    }
  }

  void _startAutoCarModeTimer() {
    _autoCarModeTimer?.cancel();
    _autoCarModeTimer = Timer(_autoCarModeDelay, _enterCarModeAutomatically);
  }

  void _resetAutoCarModeTimer() {
    if (_autoCarModeTimer != null) _startAutoCarModeTimer();
  }

  void _enterCarModeAutomatically() {
    _autoCarModeTimer = null;
    if (!mounted) return;
    if (!shouldRunAutoCarModeTimer(
      isPlaying: _playerProvider.isPlaying,
      isPlayingRadio: _playerProvider.isPlayingRadio,
      isPlayingAudiobook: _playerProvider.isPlayingAudiobook,
      appBackgrounded: _appBackgrounded,
      carModeOpen: _carModeOpen,
      lyricsShowing: _showLyrics,
      autoEntryEnabled:
          PlayerUiSettingsService().getAutoCarModeEntry(),
    )) {
      return;
    }
    // 有弹层/其他路由覆盖本页（如队列弹层）时不进入车载页；
    // 重新排一次 30s 再试 —— 稳态播放无 provider 通知，不重排会静默失效。
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) {
      _startAutoCarModeTimer();
      return;
    }
    _openCarMode();
  }

  Future<void> _openCarMode() {
    if (_carModeOpen) return Future.value();
    _autoCarModeTimer?.cancel();
    _autoCarModeTimer = null;
    _carModeOpen = true;
    final transitionSw = Stopwatch()..start();
    return Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (_, __, ___) => const CarModeScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: Duration.zero,
      ),
    ).then((_) {
      _carModeOpen = false;
      DiagnosticsRouteObserver.transition(
        from: 'NowPlayingScreen',
        to: 'CarModeScreen',
        dwellMs: transitionSw.elapsedMilliseconds,
      );
      // 从车载页返回后重新开始倒计时，行为可重复。
      if (mounted && !_appBackgrounded) {
        _syncAutoCarModeTimer(isPlaying: _playerProvider.isPlaying);
      }
    });
  }

  void _onVerticalDragStart(DragStartDetails details) {
    _isDragging = true;
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() {
      _dragOffset = (_dragOffset + details.delta.dy).clamp(
        0.0,
        double.infinity,
      );
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging) return;
    _isDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    if (_dragOffset > _dismissThreshold || velocity > 800) {
      // 下拉隐藏返回主屏：此前该路径完全无埋点（查不到下拉卡顿），
      // pop 前记录转场并带手势参数。
      DiagnosticsRouteObserver.transition(
        from: 'NowPlayingScreen',
        to: 'MainScreen',
        dragOffset: _dragOffset,
        velocity: velocity,
      );
      Navigator.pop(context);
    } else {
      setState(() {
        _dragOffset = 0.0;
      });
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_showLyrics || _isSwipeAnimating) return;

    if (!kIsWeb && Platform.isAndroid) {
      final mediaQuery = MediaQuery.of(context);
      final sysInsets = mediaQuery.systemGestureInsets;
      final screenWidth = mediaQuery.size.width;
      const kEdgeBuffer = 8.0;
      final dx = details.globalPosition.dx;
      final inLeftZone = dx < sysInsets.left + kEdgeBuffer;
      final inRightZone = dx > screenWidth - sysInsets.right - kEdgeBuffer;
      if (inLeftZone || inRightZone) return;
    }

    _isHorizontalDragging = true;
    _hasTriggeredHaptic = false;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!_isHorizontalDragging || _showLyrics) return;
    setState(() {
      _horizontalDragOffset += details.delta.dx;
      _updatePreviewSong();
    });
    if (_previewSong != null && _swipeProgress >= 1.0 && !_hasTriggeredHaptic) {
      _hasTriggeredHaptic = true;
      HapticFeedback.lightImpact();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (!_isHorizontalDragging) return;
    _isHorizontalDragging = false;

    final velocity = details.primaryVelocity ?? 0;
    final provider = context.read<PlayerProvider>();

    final shouldSkipNext = (_horizontalDragOffset < -_swipeThreshold ||
            velocity < -_swipeVelocityThreshold) &&
        provider.hasNext;
    final shouldSkipPrevious = (_horizontalDragOffset > _swipeThreshold ||
            velocity > _swipeVelocityThreshold) &&
        provider.hasPrevious;

    if (shouldSkipNext || shouldSkipPrevious) {
      final targetIndex = shouldSkipNext
          ? provider.currentIndex + 1
          : provider.currentIndex - 1;
      _animateSwipeCompletion(
        goNext: shouldSkipNext,
        targetIndex: targetIndex,
        provider: provider,
        flingVelocity: velocity.abs(),
      );
    } else {
      _animateSwipeSpringBack();
    }
  }

  void _animateSwipeCompletion({
    required bool goNext,
    required int targetIndex,
    required PlayerProvider provider,
    required double flingVelocity,
  }) {
    _isSwipeAnimating = true;
    final startOffset = _horizontalDragOffset;
    // Animate exactly so preview lands at center (size + gap)
    final targetDistance = _currentArtworkSize + _kCarouselGap;
    final endOffset = goNext ? -targetDistance : targetDistance;
    final distance = (endOffset - startOffset).abs();

    // Match fling velocity: duration = distance / velocity, clamped
    final speed = flingVelocity.clamp(600.0, 3000.0);
    final durationMs = (distance / speed * 1000).round().clamp(120, 350);

    _swipeAnimationController.duration = Duration(milliseconds: durationMs);
    _swipeAnimationController.reset();
    final animation = Tween<double>(begin: startOffset, end: endOffset).animate(
      CurvedAnimation(parent: _swipeAnimationController, curve: Curves.easeOut),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = animation.value;
      });
    }

    animation.addListener(listener);

    _swipeAnimationController.forward().then((_) {
      animation.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = 0.0;
        _previewSong = null;
        _isSwipeAnimating = false;
      });
      provider.skipToIndex(targetIndex);
    });
  }

  void _animateSwipeSpringBack() {
    _isSwipeAnimating = true;
    final startOffset = _horizontalDragOffset;
    final distance = startOffset.abs();

    // Proportional duration: short snap-back for small drags
    final durationMs = (distance / 400 * 250).round().clamp(120, 300);

    _swipeAnimationController.duration = Duration(milliseconds: durationMs);
    _swipeAnimationController.reset();
    final animation = Tween<double>(begin: startOffset, end: 0.0).animate(
      CurvedAnimation(
        parent: _swipeAnimationController,
        curve: Curves.easeOutQuad,
      ),
    );

    void listener() {
      if (!mounted) return;
      setState(() {
        _horizontalDragOffset = animation.value;
      });
    }

    animation.addListener(listener);

    _swipeAnimationController.forward().then((_) {
      animation.removeListener(listener);
      if (!mounted) return;
      setState(() {
        _previewSong = null;
        _isSwipeAnimating = false;
      });
    });
  }

  void _updatePreviewSong() {
    final provider = context.read<PlayerProvider>();
    final queue = provider.queue;
    final currentIndex = provider.currentIndex;

    if (_horizontalDragOffset > 0 && currentIndex > 0) {
      _previewSong = queue[currentIndex - 1];
    } else if (_horizontalDragOffset < 0 && currentIndex < queue.length - 1) {
      _previewSong = queue[currentIndex + 1];
    } else {
      _previewSong = null;
    }
  }

  String? _getPreviewArtworkUrl(Song? song) {
    if (song == null) return null;
    if (song.coverArt == null) return null;

    if (isLocalFilePath(song.coverArt)) {
      return song.coverArt;
    }

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    return subsonicService.getCoverArtUrl(song.coverArt!);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    Song song,
    double screenWidth,
    double screenHeight,
    Duration animDuration,
    Curve animCurve,
  ) {
    final artworkLandMin = screenHeight < 280 ? 80.0 : 120.0;
    final artworkLandMax = (screenWidth * 0.40).clamp(artworkLandMin, 500.0);
    final artworkSize = (screenHeight * 0.75).clamp(
      artworkLandMin,
      artworkLandMax,
    );
    _currentArtworkSize = artworkSize;

    return Row(
      children: [
        Expanded(
          flex: 4,
          child: Center(
            child: AnimatedContainer(
              duration: animDuration,
              curve: animCurve,
              transform: Matrix4.identity()
                ..setTranslationRaw(0.0, -_morphProgress * 10, 0.0)
                ..scaleByDouble(
                  1.0 + _morphProgress * 0.03,
                  1.0 + _morphProgress * 0.03,
                  1.0,
                  1.0,
                ),
              transformAlignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Song title above the artwork, same width, 1-2 lines.
                  SizedBox(
                    width: artworkSize,
                    child: Text(
                      song.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 3),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _showLyrics = true;
                      });
                    },
                    child: _SwipeableAlbumArtwork(
                      currentImageUrl: _cachedImageUrl ?? '',
                      currentThumbnailUrl: _cachedThumbnailUrl,
                      previewImageUrl: _getPreviewArtworkUrl(_previewSong),
                      hasPreviewSong: _previewSong != null,
                      size: artworkSize,
                      swipeProgress: _swipeProgress,
                      horizontalDragOffset: _horizontalDragOffset,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 5,
          child: _showLyrics
              ? Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: _PlayerHeader(
                        albumName: song.album ??
                            AppLocalizations.of(context)!.unknownAlbum,
                        albumId: song.albumId,
                        showLyricsButton: false,
                        isLyricsActive: _showLyrics,
                        onLyricsPressed: () {
                          setState(() {
                            _showLyrics = !_showLyrics;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: CompactLyricsView(
                        key: ValueKey(song.id),
                        song: song,
                        onClose: () {
                          setState(() {
                            _showLyrics = false;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedOpacity(
                        duration: animDuration,
                        opacity: (1.0 - _morphProgress * 1.5).clamp(0.0, 1.0),
                        child: _PlayerHeader(
                          albumName: song.album ??
                              AppLocalizations.of(context)!.unknownAlbum,
                          albumId: song.albumId,
                          showLyricsButton: false,
                          isLyricsActive: _showLyrics,
                          onLyricsPressed: () {
                            setState(() {
                              _showLyrics = !_showLyrics;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedOpacity(
                        duration: animDuration,
                        opacity: (1.0 - _morphProgress * 1.2).clamp(0.0, 1.0),
                        child: AnimatedContainer(
                          duration: animDuration,
                          curve: animCurve,
                          transform: Matrix4.identity()
                            ..setTranslationRaw(0, _morphProgress * 15, 0),
                          child: _PlayerControls(
                            formatDuration: _formatDuration,
                            onLyricsPressed: () {
                              setState(() {
                                _showLyrics = !_showLyrics;
                              });
                            },
                            onCarPressed: _openCarMode,
                            isLyricsActive: _showLyrics,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, provider) => (
        provider.currentSong,
        provider.currentRadioStation,
        provider.isPlayingRadio,
      ),
      builder: (context, data, _) {
        final (song, radioStation, isPlayingRadio) = data;

        if (isPlayingRadio && radioStation != null) {
          return _buildRadioPlayer(context, radioStation);
        }

        if (song == null) {
          return Scaffold(
            body: Center(
              child: Text(AppLocalizations.of(context)!.noSongPlaying),
            ),
          );
        }

        // Normalize to the album cover so all songs of an album share one
        // cache key; request a display-sized image (300) instead of 1200 —
        // identical on a phone screen, 4x less decode work.
        final libraryProvider =
            Provider.of<LibraryProvider>(context, listen: false);
        final coverId = libraryProvider.effectiveCoverArt(song);
        if (_cachedCoverArtId != coverId) {
          _cachedCoverArtId = coverId;
          if (isLocalFilePath(coverId)) {
            _cachedImageUrl = coverId;
            _cachedThumbnailUrl = coverId;
          } else {
            final subsonicService = Provider.of<SubsonicService>(
              context,
              listen: false,
            );
            _cachedImageUrl = subsonicService.getCoverArtUrl(
              coverId,
              size: kCoverArtRequestSize,
            );
            _cachedThumbnailUrl = subsonicService.getCoverArtUrl(
              coverId,
              size: kCoverArtRequestSize,
            );
          }
        }

        final animDuration =
            _isDragging ? Duration.zero : const Duration(milliseconds: 300);
        final animCurve = Curves.easeOutCubic;

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: GestureDetector(
            onVerticalDragStart: _showLyrics ? null : _onVerticalDragStart,
            onVerticalDragUpdate: _showLyrics ? null : _onVerticalDragUpdate,
            onVerticalDragEnd: _showLyrics ? null : _onVerticalDragEnd,
            onHorizontalDragStart: _showLyrics ? null : _onHorizontalDragStart,
            onHorizontalDragUpdate:
                _showLyrics ? null : _onHorizontalDragUpdate,
            onHorizontalDragEnd: _showLyrics ? null : _onHorizontalDragEnd,
            child: Material(
              color: Colors.transparent,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AnimatedContainer(
                    duration: animDuration,
                    curve: animCurve,
                    transform: Matrix4.identity()
                      ..translateByDouble(0.0, _dragOffset, 0.0, 1.0)
                      ..scaleByDouble(_scale, _scale, 1.0, 1.0),
                    transformAlignment: Alignment.topCenter,
                    child: AnimatedContainer(
                      duration: animDuration,
                      curve: animCurve,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(_borderRadius),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Scaffold(
                        body: Stack(
                          fit: StackFit.expand,
                          children: [
                            _DynamicBackground(
                              imageUrl: _cachedImageUrl ?? '',
                            ),
                            IgnorePointer(
                              ignoring: _showLyrics,
                              child: AnimatedOpacity(
                                opacity: _showLyrics ? 0.12 : 1.0,
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOutCubic,
                                child: SafeArea(
                                  bottom: false,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final screenHeight =
                                          constraints.maxHeight;
                                      final screenWidth = constraints.maxWidth;

                                      final isLandscape =
                                          screenWidth > screenHeight;

                                      if (isLandscape) {
                                        return _buildLandscapeLayout(
                                          context,
                                          song,
                                          screenWidth,
                                          screenHeight,
                                          animDuration,
                                          animCurve,
                                        );
                                      }

                                      // Clamp artwork safely: ensure max >= min so
                                      // clamp() never throws on small screens
                                      // (e.g. Sony NW-A306 Walkman ~240x400 dp).
                                      final artworkMinSize =
                                          screenHeight < 400 ? 80.0 : 120.0;
                                      final artworkMaxSize =
                                          (screenHeight * 0.38)
                                              .clamp(artworkMinSize, 400.0);
                                      final artworkSize =
                                          (screenWidth * 0.80).clamp(
                                        artworkMinSize,
                                        artworkMaxSize,
                                      );
                                      _currentArtworkSize = artworkSize;

                                      final controlsHeight =
                                          screenHeight < 420 ? 180.0 : 250.0;
                                      final headerHeight =
                                          screenHeight < 420 ? 44.0 : 56.0;

                                      final availableSpace = screenHeight -
                                          headerHeight -
                                          artworkSize -
                                          controlsHeight;

                                      final topSpacing = (availableSpace * 0.35)
                                          .clamp(8.0, 60.0);
                                      final middleSpacing =
                                          (availableSpace * 0.45)
                                              .clamp(12.0, 50.0);
                                      final bottomSpacing =
                                          (availableSpace * 0.20)
                                              .clamp(4.0, 30.0);

                                      return SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: ConstrainedBox(
                                          constraints: BoxConstraints(
                                            minHeight: screenHeight,
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              AnimatedOpacity(
                                                duration: animDuration,
                                                opacity:
                                                    (1.0 - _morphProgress * 1.5)
                                                        .clamp(0.0, 1.0),
                                                child: _PlayerHeader(
                                                  albumName: song.album ??
                                                      AppLocalizations.of(
                                                              context)!
                                                          .unknownAlbum,
                                                  albumId: song.albumId,
                                                  showLyricsButton: false,
                                                  isLyricsActive: _showLyrics,
                                                  onLyricsPressed: () {
                                                    setState(() {
                                                      _showLyrics =
                                                          !_showLyrics;
                                                    });
                                                  },
                                                ),
                                              ),
                                              SizedBox(height: topSpacing),
                                              AnimatedContainer(
                                                duration: animDuration,
                                                curve: animCurve,
                                                transform: Matrix4.identity()
                                                  ..translateByDouble(
                                                    0.0,
                                                    -_morphProgress * 20,
                                                    0.0,
                                                    1.0,
                                                  )
                                                  ..scaleByDouble(
                                                    1.0 + _morphProgress * 0.05,
                                                    1.0 + _morphProgress * 0.05,
                                                    1.0,
                                                    1.0,
                                                  ),
                                                transformAlignment:
                                                    Alignment.center,
                                                child: Column(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    // Song title above the
                                                    // artwork, same width,
                                                    // 1-2 lines.
                                                    SizedBox(
                                                      width: artworkSize,
                                                      child: Text(
                                                        song.title,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          height: 1.25,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 3),
                                                    GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          _showLyrics = true;
                                                        });
                                                      },
                                                      child:
                                                          _SwipeableAlbumArtwork(
                                                        currentImageUrl:
                                                            _cachedImageUrl ??
                                                                '',
                                                        currentThumbnailUrl:
                                                            _cachedThumbnailUrl,
                                                        previewImageUrl:
                                                            _getPreviewArtworkUrl(
                                                          _previewSong,
                                                        ),
                                                        hasPreviewSong:
                                                            _previewSong !=
                                                                null,
                                                        size: artworkSize,
                                                        swipeProgress:
                                                            _swipeProgress,
                                                        horizontalDragOffset:
                                                            _horizontalDragOffset,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: middleSpacing),
                                              AnimatedOpacity(
                                                duration: animDuration,
                                                opacity:
                                                    (1.0 - _morphProgress * 1.2)
                                                        .clamp(0.0, 1.0),
                                                child: AnimatedContainer(
                                                  duration: animDuration,
                                                  curve: animCurve,
                                                  transform: Matrix4.identity()
                                                    ..translateByDouble(
                                                      0.0,
                                                      _morphProgress * 30,
                                                      0.0,
                                                      1.0,
                                                    ),
                                                  child: _PlayerControls(
                                                    formatDuration:
                                                        _formatDuration,
                                                    onLyricsPressed: () {
                                                      setState(() {
                                                        _showLyrics =
                                                            !_showLyrics;
                                                      });
                                                    },
                                                    onCarPressed: _openCarMode,
                                                    isLyricsActive: _showLyrics,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(height: bottomSpacing),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 450),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final isEntering = animation.status ==
                                        AnimationStatus.forward ||
                                    animation.status ==
                                        AnimationStatus.completed;
                                final slideAnimation = Tween<Offset>(
                                  begin: const Offset(0, 0.18),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: isEntering
                                        ? Curves.easeOutCubic
                                        : Curves.easeInCubic,
                                  ),
                                );
                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: slideAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: _showLyrics
                                  ? SizedBox.expand(
                                      key: const ValueKey('lyrics'),
                                      child: SyncedLyricsView(
                                        song: song,
                                        imageUrl: _cachedImageUrl,
                                        onClose: () {
                                          setState(() {
                                            _showLyrics = false;
                                          });
                                        },
                                      ),
                                    )
                                  : const SizedBox.shrink(
                                      key: ValueKey('no-lyrics'),
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRadioPlayer(BuildContext context, RadioStation station) {
    final animDuration =
        (_isDragging || _isHorizontalDragging || _isSwipeAnimating)
            ? Duration.zero
            : const Duration(milliseconds: 300);
    final animCurve = Curves.easeOutCubic;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: GestureDetector(
        onVerticalDragStart: _onVerticalDragStart,
        onVerticalDragUpdate: _onVerticalDragUpdate,
        onVerticalDragEnd: _onVerticalDragEnd,
        child: Material(
          color: Colors.transparent,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimatedContainer(
                duration: animDuration,
                curve: animCurve,
                transform: Matrix4.identity()
                  ..translateByDouble(0.0, _dragOffset, 0.0, 1.0)
                  ..scaleByDouble(_scale, _scale, 1.0, 1.0),
                transformAlignment: Alignment.topCenter,
                child: AnimatedContainer(
                  duration: animDuration,
                  curve: animCurve,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(_borderRadius),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Scaffold(
                    body: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF1a1a2e),
                            Color(0xFF16213e),
                            Color(0xFF0f0f23),
                          ],
                        ),
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(
                                      CupertinoIcons.chevron_down,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppTheme.appleMusicRed,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          AppLocalizations.of(context)!.live,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        AppLocalizations.of(context)!
                                            .internetRadioUppercase,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 48),
                                ],
                              ),
                            ),
                            const Spacer(flex: 2),
                            Container(
                              width: ScreenHelper.isSmallScreen(context)
                                  ? 160
                                  : 200,
                              height: ScreenHelper.isSmallScreen(context)
                                  ? 160
                                  : 200,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF2D55),
                                    Color(0xFFFF6B35)
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(
                                      0xFFFF2D55,
                                    ).withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.radio,
                                color: Colors.white,
                                size: ScreenHelper.radioIconSize(context),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal:
                                    ScreenHelper.playerHorizontalPadding(
                                        context),
                              ),
                              child: Text(
                                station.name,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize:
                                      ScreenHelper.radioTitleFontSize(context),
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: AppTheme.appleMusicRed,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            AppTheme.appleMusicRed.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.streamingLive,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(flex: 2),
                            Selector<PlayerProvider, bool>(
                              selector: (_, p) => p.isPlaying,
                              builder: (context, isPlaying, _) {
                                final provider = context.read<PlayerProvider>();
                                return GestureDetector(
                                  onTap: provider.togglePlayPause,
                                  child: Container(
                                    width: ScreenHelper.radioPlayButtonSize(
                                        context),
                                    height: ScreenHelper.radioPlayButtonSize(
                                        context),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 20,
                                          spreadRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      color: Colors.black,
                                      size: ScreenHelper.radioPlayIconSize(
                                          context),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () {
                                context.read<PlayerProvider>().stopRadio();
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.stop_rounded,
                                color: Colors.white60,
                              ),
                              label: Text(
                                AppLocalizations.of(context)!.stopRadio,
                                style: const TextStyle(color: Colors.white60),
                              ),
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Palette cache: avoids re-extracting colors for the same cover every rebuild.
// ─────────────────────────────────────────────────────────────────────────────
final _paletteCache = <String, List<Color>>{};

// Default fallback colors (Apple Music deep-dark aesthetic).
const _kDefaultMeshColors = [
  Color(0xFF1A0A2E),
  Color(0xFF0D1B3E),
  Color(0xFF0A1628),
  Color(0xFF160A2A),
];

Future<List<Color>> _extractPaletteColors(String imageUrl) async {
  if (_paletteCache.containsKey(imageUrl)) {
    DiagnosticsService.instance.record(
      EventType.paletteExtract,
      LogLevel.debug,
      {'url': imageUrl, 'cacheHit': true},
    );
    return _paletteCache[imageUrl]!;
  }

  final sw = Stopwatch()..start();
  try {
    ImageProvider provider;
    if (isLocalFilePath(imageUrl)) {
      provider = FileImage(File(imageUrl));
    } else {
      provider = NetworkImage(imageUrl);
    }

    final generator = await PaletteGenerator.fromImageProvider(
      provider,
      size: const Size(112, 112),
      maximumColorCount: 8,
    );

    final colors = <Color>[];

    // Prioritise vibrant then muted swatches for a rich mesh.
    final candidates = [
      generator.vibrantColor,
      generator.darkVibrantColor,
      generator.mutedColor,
      generator.darkMutedColor,
      generator.lightVibrantColor,
      generator.lightMutedColor,
    ].whereType<PaletteColor>().map((s) => s.color).toList();

    if (candidates.isEmpty) {
      final top = generator.colors.take(6).toList();
      colors.addAll(top);
    } else {
      colors.addAll(candidates);
    }

    // Always ensure 4 colors for AnimatedMeshGradient.
    while (colors.length < 4) {
      colors.add(colors.isNotEmpty ? colors.last : const Color(0xFF1A0A2E));
    }

    final result = [
      colors[0].withValues(alpha: 1.0),
      colors[1 % colors.length].withValues(alpha: 1.0),
      colors[2 % colors.length].withValues(alpha: 1.0),
      colors[3 % colors.length].withValues(alpha: 1.0),
    ];

    _paletteCache[imageUrl] = result;

    // Keep cache bounded.
    if (_paletteCache.length > 20) {
      final evicted = _paletteCache.keys.first;
      _paletteCache.remove(evicted);
      DiagnosticsService.instance.record(
        EventType.paletteEvict,
        LogLevel.info,
        {'evicted': evicted, 'cacheSize': _paletteCache.length},
      );
    }

    sw.stop();
    DiagnosticsService.instance.record(
      EventType.paletteExtract,
      LogLevel.info,
      {
        'url': imageUrl,
        'cacheHit': false,
        'elapsedMs': sw.elapsedMilliseconds,
      },
    );

    return result;
  } catch (_) {
    return _kDefaultMeshColors;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DynamicBackground: Animated Mesh Gradient background extracted from artwork.
// ─────────────────────────────────────────────────────────────────────────────

class _DynamicBackground extends StatefulWidget {
  final String imageUrl;

  const _DynamicBackground({required this.imageUrl});

  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}

class _DynamicBackgroundState extends State<_DynamicBackground> {
  List<Color> _meshColors = _kDefaultMeshColors;
  List<Color> _prevColors = _kDefaultMeshColors;

  @override
  void initState() {
    super.initState();
    _loadColors(widget.imageUrl);
  }

  @override
  void didUpdateWidget(_DynamicBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loadColors(widget.imageUrl);
    }
  }

  Future<void> _loadColors(String imageUrl) async {
    if (imageUrl.isEmpty) {
      if (mounted) {
        setState(() {
          _prevColors = _meshColors;
          _meshColors = _kDefaultMeshColors;
        });
      }
      return;
    }

    // Serve from cache immediately if available to avoid a flash.
    if (_paletteCache.containsKey(imageUrl)) {
      if (mounted) {
        setState(() {
          _prevColors = _meshColors;
          _meshColors = _paletteCache[imageUrl]!;
        });
      }
      return;
    }

    final colors = await _extractPaletteColors(imageUrl);
    if (mounted && imageUrl == widget.imageUrl) {
      setState(() {
        _prevColors = _meshColors;
        _meshColors = colors;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: TweenAnimationBuilder<List<Color>>(
        tween: _ColorListTween(begin: _prevColors, end: _meshColors),
        duration: const Duration(milliseconds: 900),
        builder: (context, colors, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: colors[3]),
              _GradientBlob(
                color: colors[0],
                alignment: const Alignment(-0.8, -0.8),
                radius: 0.9,
              ),
              _GradientBlob(
                color: colors[1],
                alignment: const Alignment(0.8, -0.6),
                radius: 0.8,
              ),
              _GradientBlob(
                color: colors[2],
                alignment: const Alignment(0.0, 0.9),
                radius: 0.85,
              ),
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.42),
                      Color.fromRGBO(0, 0, 0, 0.70),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// Smoothly interpolates between two color lists.
class _ColorListTween extends Tween<List<Color>> {
  _ColorListTween({required List<Color> begin, required List<Color> end})
      : super(begin: begin, end: end);

  @override
  List<Color> lerp(double t) {
    final b = begin!;
    final e = end!;
    return List.generate(
      b.length,
      (i) => Color.lerp(b[i], e[i], t)!,
    );
  }
}

// A single radial gradient color blob.
class _GradientBlob extends StatelessWidget {
  final Color color;
  final Alignment alignment;
  final double radius;

  const _GradientBlob({
    required this.color,
    required this.alignment,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: FractionallySizedBox(
        widthFactor: radius * 1.4,
        heightFactor: radius * 1.4,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                color.withValues(alpha: 0.85),
                color.withValues(alpha: 0.0),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerHeader extends StatelessWidget {
  final String albumName;
  final String? albumId;
  final bool showLyricsButton;
  final bool isLyricsActive;
  final VoidCallback? onLyricsPressed;

  const _PlayerHeader({
    required this.albumName,
    this.albumId,
    this.showLyricsButton = false,
    this.isLyricsActive = false,
    this.onLyricsPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              CupertinoIcons.chevron_down,
              color: Colors.white,
              size: 28,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: albumId != null
                  ? () {
                      Navigator.pop(context);
                      NavigationHelper.push(
                        context,
                        AlbumScreen(albumId: albumId!),
                      );
                    }
                  : null,
              child: Column(
                children: [
                  Text(
                    AppLocalizations.of(context)!.playingFrom,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    albumName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      decoration:
                          albumId != null ? TextDecoration.underline : null,
                      decorationColor: Colors.white.withValues(alpha: 0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLyricsButton)
                IconButton(
                  onPressed: onLyricsPressed,
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    CupertinoIcons.music_note_list,
                    color:
                        isLyricsActive ? AppTheme.appleMusicRed : Colors.white,
                    size: 22,
                  ),
                ),
              // 睡眠定时（保留）：speed 与队列按钮已按用户要求从顶栏移除。
              Selector<PlayerProvider, bool>(
                selector: (_, p) => p.hasSleepTimer,
                builder: (context, hasTimer, _) => IconButton(
                  tooltip: hasTimer
                      ? AppLocalizations.of(context)!.sleepTimerActive
                      : AppLocalizations.of(context)!.sleepTimer,
                  onPressed: () => _showSleepTimerDialog(context),
                  padding: const EdgeInsets.all(6),
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    CupertinoIcons.moon_zzz,
                    color: hasTimer ? AppTheme.appleMusicRed : Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ],
      ),
    );
  }


  void _showSleepTimerDialog(BuildContext context) {
    // 2026-10-27：实现抽到 widgets/luobo/sleep_timer_sheet.dart，
    // 有声书章节页的吸底控制条复用同一个入口。
    showSleepTimerSheet(context, context.read<PlayerProvider>());
  }
}

class _AlbumArtworkSection extends StatefulWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  final double size;

  const _AlbumArtworkSection({
    required this.imageUrl,
    this.thumbnailUrl,
    required this.size,
  });

  @override
  State<_AlbumArtworkSection> createState() => _AlbumArtworkSectionState();
}

class _AlbumArtworkSectionState extends State<_AlbumArtworkSection> {
  @override
  void initState() {
    super.initState();
    DiagnosticsService.instance.record(
      EventType.animActive,
      LogLevel.info,
      {'anim': 'albumArtworkRotation', 'pulseMs': 800, 'rotationSec': 12},
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(12);
    final boxShadow = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.4),
        blurRadius: 40,
        offset: const Offset(0, 20),
      ),
    ];

    final artworkWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              boxShadow: boxShadow,
            ),
            child: ClipRRect(
              borderRadius: borderRadius,
              child: widget.imageUrl.isNotEmpty
                  ? isLocalFilePath(widget.imageUrl)
                      ? Image.file(
                          File(widget.imageUrl),
                          key: ValueKey(widget.imageUrl),
                          fit: BoxFit.contain,
                          cacheWidth: 1200,
                          errorBuilder: (ctx, e, _) =>
                              _buildNoArtPlaceholder(ctx),
                        )
                      : CachedNetworkImage(
                          key: ValueKey(widget.imageUrl),
                          cacheManager: coverCacheManager,
                          imageUrl: widget.imageUrl,
                          cacheKey: coverArtCacheKeyFromUrl(widget.imageUrl),
                          fit: BoxFit.contain,
                          memCacheWidth: 1200,
                          maxWidthDiskCache: 1200,
                          maxHeightDiskCache: 1200,
                          useOldImageOnUrlChange: true,
                          fadeInDuration: Duration.zero,
                          fadeOutDuration: Duration.zero,
                          placeholder: (ctx, url) =>
                              widget.thumbnailUrl != null &&
                                      widget.thumbnailUrl!.isNotEmpty
                                  ? CachedNetworkImage(
                                      cacheManager: coverCacheManager,
                                      imageUrl: widget.thumbnailUrl!,
                                      cacheKey: coverArtCacheKeyFromUrl(
                                          widget.thumbnailUrl!),
                                      fit: BoxFit.contain,
                                      memCacheWidth: 200,
                                      fadeInDuration: Duration.zero,
                                      errorWidget: (ctx, err, stack) =>
                                          _buildLoadingPlaceholder(),
                                    )
                                  : _buildLoadingPlaceholder(),
                          errorWidget: (ctx, e, _) =>
                              _buildNoArtPlaceholder(ctx),
                        )
                  : _buildNoArtPlaceholder(context),
            ),
          ),
        ),
      ),
    );

    return artworkWidget;
  }

  Widget _buildLoadingPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: widget.size,
        height: widget.size,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildNoArtPlaceholder(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note_rounded,
            size: (widget.size * 0.28).clamp(40.0, 100.0),
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(height: 12),
          Text(
            AppLocalizations.of(context)!.noArtwork,
            style: TextStyle(
              fontSize: (widget.size * 0.045).clamp(11.0, 16.0),
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.18),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeableAlbumArtwork extends StatelessWidget {
  final String currentImageUrl;
  final String? currentThumbnailUrl;
  final String? previewImageUrl;
  final bool hasPreviewSong;
  final double size;
  final double swipeProgress;
  final double horizontalDragOffset;

  const _SwipeableAlbumArtwork({
    required this.currentImageUrl,
    this.currentThumbnailUrl,
    this.previewImageUrl,
    this.hasPreviewSong = false,
    required this.size,
    required this.swipeProgress,
    required this.horizontalDragOffset,
  });

  @override
  Widget build(BuildContext context) {
    final hasPreview = hasPreviewSong && horizontalDragOffset != 0;

    final isSwipingRight = horizontalDragOffset > 0;
    final previewStart =
        isSwipingRight ? -size - _kCarouselGap : size + _kCarouselGap;
    final previewOffset = previewStart + horizontalDragOffset;

    if (!hasPreview) {
      return _AlbumArtworkSection(
        imageUrl: currentImageUrl,
        thumbnailUrl: currentThumbnailUrl,
        size: size,
      );
    }

    // Fade based on distance from center
    final totalDistance = size + _kCarouselGap;
    final progress = (horizontalDragOffset.abs() / totalDistance).clamp(
      0.0,
      1.0,
    );
    final currentOpacity = (1.0 - progress * 0.5).clamp(0.5, 1.0);
    final previewOpacity = (progress * 0.5 + 0.5).clamp(0.5, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Transform.translate(
          offset: Offset(previewOffset, 0),
          child: Opacity(
            opacity: previewOpacity,
            child: _buildPreviewArtwork(context),
          ),
        ),
        Transform.translate(
          offset: Offset(horizontalDragOffset, 0),
          child: Opacity(
            opacity: currentOpacity,
            child: _AlbumArtworkSection(
              imageUrl: currentImageUrl,
              thumbnailUrl: currentThumbnailUrl,
              size: size,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewArtwork(BuildContext context) {
    final hasArtwork = previewImageUrl != null && previewImageUrl!.isNotEmpty;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3 + swipeProgress * 0.2),
            blurRadius: 30 + swipeProgress * 20,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: !hasArtwork
            ? _buildNoArtPlaceholder(context)
            : isLocalFilePath(previewImageUrl)
                ? Image.file(
                    File(previewImageUrl!),
                    key: ValueKey(previewImageUrl),
                    fit: BoxFit.contain,
                    cacheWidth: 1200,
                    errorBuilder: (ctx, e, _) => _buildNoArtPlaceholder(ctx),
                  )
                : CachedNetworkImage(
                    key: ValueKey(previewImageUrl),
                    cacheManager: coverCacheManager,
                    imageUrl: previewImageUrl!,
                    cacheKey: coverArtCacheKeyFromUrl(previewImageUrl!),
                    fit: BoxFit.contain,
                    memCacheWidth: 1200,
                    maxWidthDiskCache: 1200,
                    maxHeightDiskCache: 1200,
                    useOldImageOnUrlChange: true,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (ctx, url) => _buildPlaceholder(),
                    errorWidget: (ctx, err, stack) =>
                        _buildNoArtPlaceholder(context),
                  ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFF2A2A2A),
      highlightColor: const Color(0xFF3A3A3A),
      child: Container(
        width: size,
        height: size,
        color: const Color(0xFF2A2A2A),
      ),
    );
  }

  Widget _buildNoArtPlaceholder(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
        ),
      ),
      child: Icon(
        Icons.music_note_rounded,
        size: (size * 0.28).clamp(40.0, 100.0),
        color: Colors.white.withValues(alpha: 0.15),
      ),
    );
  }
}

class _PlayerControls extends StatefulWidget {
  final String Function(Duration) formatDuration;
  final VoidCallback? onLyricsPressed;
  final bool isLyricsActive;
  final VoidCallback? onCarPressed;

  const _PlayerControls({
    required this.formatDuration,
    this.onLyricsPressed,
    this.onCarPressed,
    this.isLyricsActive = false,
  });

  @override
  State<_PlayerControls> createState() => _PlayerControlsState();
}

class _PlayerControlsState extends State<_PlayerControls> {
  final _playerUiSettings = PlayerUiSettingsService();
  bool _showVolumeSlider = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    await _playerUiSettings.initialize();
    if (mounted) {
      setState(() {
        _showVolumeSlider = _playerUiSettings.getShowVolumeSlider();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ScreenHelper.playerHorizontalPadding(context),
      ),
      child: Column(
        children: [
          Selector<PlayerProvider, Song?>(
            selector: (_, p) => p.currentSong,
            builder: (context, song, _) => _SongInfo(
              song: song,
              onLyricsPressed: widget.onLyricsPressed,
              onCarPressed: widget.onCarPressed,
              isLyricsActive: widget.isLyricsActive,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: _playerUiSettings.showStarRatingsNotifier,
            builder: (context, showRating, _) {
              if (!showRating) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Selector<PlayerProvider, (Song?, bool)>(
                  selector: (_, p) => (p.currentSong, p.isPlayingAudiobook),
                  builder: (context, data, _) {
                    final (song, isAudiobook) = data;
                    // 有声书（P5）：隐藏评分（章节无评分语义）。
                    if (song == null || isAudiobook) {
                      return const SizedBox.shrink();
                    }
                    return StarRatingWidget(
                      rating: song.userRating ?? 0,
                      onRatingChanged: (rating) {
                        context.read<PlayerProvider>().setRating(
                              song.id,
                              rating,
                            );
                      },
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 24,
                    );
                  },
                ),
              );
            },
          ),
          // 用 effectiveDuration 而非 duration：转码流（chunked、无
          // Content-Length）播放器解析不出时长（duration 恒 0），进度条
          // 总时长标签会留空；effectiveDuration 会回退到服务端元数据
          //（song.duration），道理鱼曲目元数据带 durationSeconds。
          Selector<PlayerProvider, Duration>(
            selector: (_, p) => p.effectiveDuration,
            builder: (context, duration, _) {
              final provider = context.read<PlayerProvider>();
              return StreamBuilder<Duration>(
                stream: provider.positionStream,
                initialData: provider.position,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final progress = duration.inMilliseconds > 0
                      ? (pos.inMilliseconds / duration.inMilliseconds).clamp(
                          0.0,
                          1.0,
                        )
                      : 0.0;
                  // 流信息并进时间行中间（fnos 同款）：贴着进度条，而不是
                  // 掉到下面的播放按钮旁边。
                  return LuoboProgressBar(
                    progress: progress,
                    position: pos,
                    duration: duration,
                    formatDuration: widget.formatDuration,
                    centerInfo: const _StreamQualityLine(),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 4),
          const _PlaybackControls(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SongInfo extends StatefulWidget {
  final Song? song;
  final VoidCallback? onLyricsPressed;
  final VoidCallback? onCarPressed;
  final bool isLyricsActive;

  const _SongInfo({
    required this.song,
    this.onLyricsPressed,
    this.onCarPressed,
    this.isLyricsActive = false,
  });

  @override
  State<_SongInfo> createState() => _SongInfoState();
}

class _SongInfoState extends State<_SongInfo> {
  bool _isStarred = false;

  @override
  void initState() {
    super.initState();
    _isStarred = widget.song?.starred ?? false;
  }

  @override
  void didUpdateWidget(_SongInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.song?.id != widget.song?.id) {
      _isStarred = widget.song?.starred ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.song == null) return const SizedBox.shrink();

    // 有声书（B8）：章节 id 是 abe_，收藏/加歌单会把章节当歌曲打 Subsonic
    // 端点 → 无效请求 + 脏数据。隐藏这两颗按钮（歌曲专属操作）。
    final isAudiobook = Provider.of<PlayerProvider>(context).isPlayingAudiobook;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.song!.title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ScreenHelper.titleFontSize(context),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              MultiArtistWidget(
                artists: widget.song!.artistParticipants,
                artistFallback: widget.song!.artist,
                artistIdFallback: widget.song!.artistId,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: ScreenHelper.subtitleFontSize(context),
                ),
                onBeforeNavigate: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
              if (widget.song!.hasDolbyAtmos == true) ...[
                const SizedBox(height: 6),
                const DolbyAtmosBadge(
                    fontSize: 10,
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2)),
              ],
            ],
          ),
        ),
        // 车载模式入口（用户 2026-10-23 要求保留）。
        IconButton(
          onPressed: widget.onCarPressed,
          icon: const Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 24,
          ),
        ),
        // 2026-10-23：其余只保留「收藏♡ + 更多⋮」——歌词入口改为点封面，
        // 「加入歌单」从这一行移除。
        if (!isAudiobook)
          IconButton(
            onPressed: () => _toggleFavorite(context),
            icon: Icon(
              _isStarred ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
              color: _isStarred ? AppTheme.appleMusicRed : Colors.white,
              size: 26,
            ),
          ),
        if (!isAudiobook)
          // 播放页变体 ⋮（设计稿/09 变体 B）：无横排主操作、无「收藏」——
          // ♡ 已在左侧常驻（与 fnos 播放页一致）。
          IconButton(
            onPressed: () => showSongMenuSheet(
              context,
              song: widget.song!,
              menuContext: SongMenuContext.player,
            ),
            icon: const Icon(AppIcons.moreV, color: Colors.white, size: 24),
          ),
      ],
    );
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    if (widget.song == null) return;
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song!.id);
        setState(() => _isStarred = false);
        if (context.mounted) {
          showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.removedFromFavorites,
      tone: LuoboToastTone.info,
    );
        }
      } else {
        await subsonicService.star(id: widget.song!.id);
        setState(() => _isStarred = true);
        if (context.mounted) {
          showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.addedToFavorites,
      tone: LuoboToastTone.info,
    );
        }
      }
    } catch (e) {
      if (context.mounted) {
        showLuoboToast(
      context,
      message: 'Error: $e',
      tone: LuoboToastTone.info,
    );
      }
    }
  }

}

/// 进度条下方的音质信息行（fnos：「原文件 · FLAC · 1769 kbps」）。
///
/// 数据取 **实际播放流**：`isActiveStreamTranscoded` 为真时用
/// `activeStreamFormat/activeStreamBitrate`（转码后），否则回退到歌曲元数据
/// （`suffix` / `bitRate`）。
class _StreamQualityLine extends StatelessWidget {
  const _StreamQualityLine();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider,
        (bool, int?, String?, String?, int?)>(
      selector: (_, p) => (
        p.isActiveStreamTranscoded,
        p.activeStreamBitrate,
        p.activeStreamFormat,
        p.currentSong?.suffix,
        p.currentSong?.bitRate,
      ),
      builder: (context, data, _) {
        final (transcoded, streamBitrate, streamFormat, suffix, metadataBitrate) =
            data;
        final rawFormat = transcoded ? streamFormat : suffix;
        final format = (rawFormat == null ||
                rawFormat.isEmpty ||
                rawFormat.toLowerCase() == 'original')
            ? null
            : rawFormat.toUpperCase();
        final bitrate = transcoded ? streamBitrate : metadataBitrate;

        if (format == null && (bitrate == null || bitrate <= 0)) {
          return const SizedBox.shrink();
        }

        final l10n = AppLocalizations.of(context)!;
        final parts = <String>[
          transcoded ? l10n.qualityTranscoded : l10n.qualityOriginal,
          if (format != null) format,
          if (bitrate != null && bitrate > 0) '$bitrate kbps',
        ];
        return Text(
          parts.join(' · '),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
          ),
        );
      },
    );
  }
}

class _PlaybackControls extends StatelessWidget {
  const _PlaybackControls();

  @override
  Widget build(BuildContext context) {
    return Selector<PlayerProvider, (bool, bool, bool, RepeatMode, bool, bool)>(
      selector: (_, p) => (
        p.isPlaying,
        p.shuffleEnabled,
        p.hasNext,
        p.repeatMode,
        p.hasPrevious,
        p.isPlayingAudiobook,
      ),
      builder: (context, data, _) {
        final (isPlaying, shuffleEnabled, hasNext, repeatMode, _, isAudiobook) =
            data;
        final provider = context.read<PlayerProvider>();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // 左：单键循环播放模式（随机 / 列表循环 / 单曲循环）。
            // 有声书（B10）强制顺序播放，隐藏该键但保留占位以居中。
            if (isAudiobook)
              const SizedBox(width: 48)
            else
              IconButton(
                onPressed: () => cyclePlaybackMode(provider),
                tooltip: shuffleEnabled
                    ? AppLocalizations.of(context)!.shuffle
                    : (repeatMode == RepeatMode.one
                        ? AppLocalizations.of(context)!.repeatOne
                        : AppLocalizations.of(context)!.repeatAll),
                icon: Icon(
                  shuffleEnabled
                      ? AppIcons.shuffle
                      : (repeatMode == RepeatMode.one
                          ? CupertinoIcons.repeat_1
                          : CupertinoIcons.repeat),
                  color: (shuffleEnabled || repeatMode != RepeatMode.off)
                      ? AppTheme.appleMusicRed
                      : Colors.white.withValues(alpha: 0.7),
                  size: 22,
                ),
              ),
            IconButton(
              onPressed: provider.skipPrevious,
              icon: Icon(
                CupertinoIcons.backward_fill,
                color: Colors.white,
                size: ScreenHelper.skipButtonIconSize(context),
              ),
            ),
            Container(
              width: ScreenHelper.playButtonContainerSize(context),
              height: ScreenHelper.playButtonContainerSize(context),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: provider.togglePlayPause,
                icon: Icon(
                  isPlaying
                      ? CupertinoIcons.pause_fill
                      : CupertinoIcons.play_fill,
                  color: Colors.black,
                  size: ScreenHelper.playButtonIconSize(context),
                ),
              ),
            ),
            IconButton(
              onPressed: hasNext ? provider.skipNext : null,
              icon: Icon(
                CupertinoIcons.forward_fill,
                color: hasNext
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.3),
                size: ScreenHelper.skipButtonIconSize(context),
              ),
            ),
            // 右：播放列表（队列）。
            IconButton(
              onPressed: () => showQueueSheet(context),
              tooltip: AppLocalizations.of(context)!.queue,
              icon: Icon(
                CupertinoIcons.list_bullet,
                color: Colors.white.withValues(alpha: 0.7),
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VolumeSlider extends StatefulWidget {
  const _VolumeSlider();

  @override
  State<_VolumeSlider> createState() => _VolumeSliderState();
}

class _VolumeSliderState extends State<_VolumeSlider> {
  bool _isDragging = false;
  double _dragValue = 0.0;
  double _systemVolume = 0.5;
  StreamSubscription<double>? _volumeSubscription;

  // Serialise remote volume commits: store the latest desired value and run
  // one async write loop at a time so out-of-order responses can't snap the
  // renderer back to a stale level during a fast drag.
  double? _pendingRemoteVolume;
  bool _remoteCommitInProgress = false;

  @override
  void initState() {
    super.initState();
    _initVolumeController();
  }

  Future<void> _initVolumeController() async {
    VolumeController.instance.showSystemUI = false;

    _systemVolume = await VolumeController.instance.getVolume();
    if (mounted) setState(() {});

    _volumeSubscription = VolumeController.instance.addListener((volume) {
      if (mounted && !_isDragging) {
        setState(() {
          _systemVolume = volume;
        });
      }
    });
  }

  @override
  void dispose() {
    _volumeSubscription?.cancel();
    super.dispose();
  }

  void _applyVolume(double newVolume, PlayerProvider provider, bool isRemote) {
    setState(() {
      _dragValue = newVolume;
      if (!isRemote) _systemVolume = newVolume;
    });
    if (isRemote) {
      // Queue the value and let a single async loop drain the queue so rapid
      // drag ticks never result in out-of-order writes reaching the renderer.
      _pendingRemoteVolume = newVolume;
      _drainRemoteVolume(provider);
    } else {
      VolumeController.instance.setVolume(newVolume);
    }
  }

  Future<void> _drainRemoteVolume(PlayerProvider provider) async {
    if (_remoteCommitInProgress) return;
    _remoteCommitInProgress = true;
    try {
      while (_pendingRemoteVolume != null) {
        final value = _pendingRemoteVolume!;
        _pendingRemoteVolume = null;
        await provider.setVolume(value);
      }
    } finally {
      _remoteCommitInProgress = false;
    }
  }

  void _updateVolumeFromPosition(
    Offset localPosition,
    double width,
    PlayerProvider provider,
    bool isRemote,
  ) {
    final newVolume = (localPosition.dx / width).clamp(0.0, 1.0);
    _applyVolume(newVolume, provider, isRemote);
  }

  @override
  Widget build(BuildContext context) {
    // Consumer so the slider re-reads provider.volume on each UPnP poll tick.
    return Consumer<PlayerProvider>(
      builder: (context, provider, _) {
        final isRemote = provider.isRemotePlayback;
        final currentVolume = isRemote ? provider.volume : _systemVolume;
        final displayVolume = _isDragging ? _dragValue : currentVolume;

        return Row(
          children: [
            GestureDetector(
              onTap: () => _applyVolume(0.0, provider, isRemote),
              child: Icon(
                displayVolume <= 0.01
                    ? CupertinoIcons.speaker_slash_fill
                    : CupertinoIcons.speaker_1_fill,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final trackWidth = constraints.maxWidth;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragStart: (details) {
                      setState(() {
                        _isDragging = true;
                        _dragValue = currentVolume;
                      });
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    onHorizontalDragUpdate: (details) {
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    onHorizontalDragEnd: (details) {
                      setState(() => _isDragging = false);
                    },
                    onTapDown: (details) {
                      _updateVolumeFromPosition(
                        details.localPosition,
                        trackWidth,
                        provider,
                        isRemote,
                      );
                    },
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Background track
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              curve: Curves.easeOut,
                              height: _isDragging ? 5 : 3,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(
                                  _isDragging ? 2.5 : 1.5,
                                ),
                              ),
                            ),
                            // Active track
                            FractionallySizedBox(
                              widthFactor: displayVolume.clamp(0.0, 1.0),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                height: _isDragging ? 5 : 3,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    _isDragging ? 2.5 : 1.5,
                                  ),
                                  boxShadow: _isDragging
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                            ),
                            // Thumb
                            Positioned(
                              left: ((trackWidth *
                                          displayVolume.clamp(0.0, 1.0)) -
                                      (_isDragging ? 14 : 6))
                                  .clamp(
                                0.0,
                                trackWidth - (_isDragging ? 28 : 12),
                              ),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                curve: Curves.easeOut,
                                width: _isDragging ? 28 : 12,
                                height: _isDragging ? 28 : 12,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: _isDragging
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.25,
                                            ),
                                            blurRadius: 12,
                                            spreadRadius: 2,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.15,
                                            ),
                                            blurRadius: 4,
                                          ),
                                        ],
                                ),
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
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () => _applyVolume(1.0, provider, isRemote),
              child: Icon(
                CupertinoIcons.speaker_3_fill,
                color: Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// 打开播放队列浮层（fnos：从播放条/播放页的队列按钮升起）。
///
/// 用 root navigator + 透明背景：浮层自身负责底色与圆角（浅色 `c.bg`、
/// 深色深面），遮罩会盖住播放条与底栏。
Future<void> showQueueSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.42),
    builder: (_) => const QueueSheet(),
  );
}

/// 播放模式循环：随机播放 → 列表循环 → 单曲循环 → 随机播放。
///
/// 只用 PlayerProvider 的公开开关（`toggleShuffle` / `toggleRepeat`），
/// 播放页控制栏与队列浮层共用。
void cyclePlaybackMode(PlayerProvider provider) {
  // 三档：随机播放 → 列表循环 → 单曲循环 → 随机播放。
  // ⚠️ 必须**精确设置**目标 repeat：只调 `toggleRepeat`（off→all→one→off）
  // 在「随机播放 + 单曲循环」组合下会落到 off，导致「列表循环」这一档永远
  // 到不了（用户 2026-10-23 反馈）。
  if (provider.shuffleEnabled) {
    provider.toggleShuffle();
    _setRepeatMode(provider, RepeatMode.all);
    return;
  }
  if (provider.repeatMode == RepeatMode.one) {
    _setRepeatMode(provider, RepeatMode.off);
    provider.toggleShuffle();
    return;
  }
  _setRepeatMode(provider, RepeatMode.one);
}

void _setRepeatMode(PlayerProvider provider, RepeatMode target) {
  var guard = 0;
  while (provider.repeatMode != target && guard < 3) {
    provider.toggleRepeat();
    guard++;
  }
}

/// 播放队列浮层（对齐 fnos `v4_0002` / `v5_0048` / `v6_0096` 的**视觉**，
/// 但按用户 2026-10-23 的要求简化）：
///
/// 把手 → 模式胶囊（左）+「清空」胶囊（右）→ **只展示待播放（当前曲 → 队尾）**
/// 的 64dp 行（封面 48 r6 + 歌名 16/600 + 歌手 12 + ×）。
/// 不做「已播放/待播放」分区，也没有重新排序；浮层**固定高度**（屏高 52%，
/// 320~480dp），避免太高不好点。
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    // 2026-10-23：用户要求参考飞牛的高度比例（v4_0002 实测弹层占屏高
    // ≈75.5%）。这里取 72%（略低于飞牛，保留顶部可点区域），下限 420。
    final height =
        (MediaQuery.sizeOf(context).height * 0.72).clamp(420.0, 640.0);

    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 12),
                child: Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // 模式 + 清空两颗胶囊。
            Selector<PlayerProvider, (bool, RepeatMode)>(
              selector: (_, p) => (p.shuffleEnabled, p.repeatMode),
              builder: (context, mode, _) {
                final provider = context.read<PlayerProvider>();
                final (shuffle, repeat) = mode;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _QueuePill(
                        icon: shuffle
                            ? AppIcons.shuffle
                            : (repeat == RepeatMode.one
                                ? CupertinoIcons.repeat_1
                                : CupertinoIcons.repeat),
                        label: shuffle
                            ? l10n.shuffle
                            : (repeat == RepeatMode.one
                                ? l10n.repeatOne
                                : l10n.repeatAll),
                        onTap: () => cyclePlaybackMode(provider),
                      ),
                      const Spacer(),
                      _QueuePill(
                        icon: CupertinoIcons.trash,
                        label: l10n.clearQueue,
                        onTap: provider.clearQueue,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Selector<PlayerProvider, (List<Song>, int)>(
                selector: (_, p) => (p.queue, p.currentIndex),
                builder: (context, data, _) {
                  final (queue, currentIndex) = data;
                  final provider = context.read<PlayerProvider>();
                  final start = currentIndex.clamp(0, queue.length);
                  if (start >= queue.length) {
                    return LuoboEmptyState(message: l10n.noSongsInQueue);
                  }
                  final upcoming = queue.sublist(start);
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: upcoming.length,
                    itemBuilder: (context, i) {
                      final index = start + i;
                      return _QueueRow(
                        song: upcoming[i],
                        isPlaying: index == currentIndex,
                        onTap: () => provider.skipToIndex(index),
                        onRemove: () => provider.removeFromQueue(index),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

}

/// 队列顶部胶囊（白底 h36 r18；深色用抬升面）。
class _QueuePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QueuePill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 36,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: c.fg),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: LuoboType.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: c.fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 队列行（64dp）：封面 48 r6 + 歌名 16/600（播放中玫红）+ 歌手 12 + ×。
class _QueueRow extends StatelessWidget {
  final Song song;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueRow({
    required this.song,
    required this.isPlaying,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final coverArt = Provider.of<LibraryProvider>(context, listen: false)
        .effectiveCoverArt(song);
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AlbumArtwork(coverArt: coverArt, size: 48, borderRadius: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? LuoboAccent.accent : c.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      song.artist ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Icon(Icons.close_rounded, size: 20, color: c.fg3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
