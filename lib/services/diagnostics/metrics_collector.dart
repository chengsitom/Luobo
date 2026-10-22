import 'dart:async';
import 'dart:ui' show FramePhase;

import 'package:flutter/painting.dart';
import 'package:flutter/scheduler.dart';

import 'diagnostics_service.dart';
import 'event_types.dart';
import 'platform.dart';

/// 性能指标采集器。
///
/// - 帧摘要：FrameTimings 入帧数据环形缓冲（10s），供派生检测器消费；
/// - 派生检测器：单帧 UI 线程 build+raster >50ms 产出 frame.jank（带当前
///   路由/交互上下文；不采用 totalSpan，避免低帧率上下文误报）；
/// - 启动里程碑：main() 各阶段打点；
/// - 页面 build 计时：>16ms 记录 screen.buildTime；
/// - 内存/缓存：60s 采样（原生端 RSS + 图片缓存）；
/// - 网络：计数器由 Dio 拦截器喂入。
class MetricsCollector {
  MetricsCollector._();

  static final MetricsCollector instance = MetricsCollector._();

  static const int _jankThresholdMs = 50;
  static const int _slowFrameMs = 25; // 慢帧阈值：转场动画期间的轻微掉帧
  static const int _slowBuildMs = 16;
  static const Duration _frameWindow = Duration(seconds: 10);
  static const Duration _sampleInterval = Duration(seconds: 60);

  final List<FrameTiming> _frames = [];
  Timer? _sampleTimer;
  int _frameSeq = 0;
  DateTime? _lastFrameAt;
  DateTime? _lastJankRecordedAt;
  DateTime? _lastSlowRecordedAt;

  bool _started = false;

  /// 启动里程碑记录（main() 各阶段）。
  static void milestone(String name, int elapsedMs,
      {Map<String, dynamic>? extra}) {
    DiagnosticsService.instance.record(
      EventType.appLaunchMilestone,
      LogLevel.info,
      {'name': name, 'elapsedMs': elapsedMs, ...?extra},
    );
  }

  /// 页面 build 耗时（>16ms 记录）。
  static void buildTime(String screen, int buildMs) {
    if (buildMs > _slowBuildMs) {
      DiagnosticsService.instance.record(
        EventType.screenBuildTime,
        LogLevel.info,
        {'screen': screen, 'buildMs': buildMs},
      );
    }
  }

  /// 网络请求计时喂入（Dio 拦截器调用）。
  static void networkRequest({required int ms, required bool ok}) {
    DiagnosticsService.instance.networkRequest(ms: ms, ok: ok);
  }

  /// 歌词加载结果记录（lrclib/netease 共用）。
  static void lyricsLoad({
    required String source,
    required bool ok,
    required bool found,
    required int elapsedMs,
    Object? error,
    String? artist,
    String? title,
  }) {
    DiagnosticsService.instance.record(
      EventType.lyricsLoad,
      LogLevel.info,
      {
        'source': source,
        'ok': ok,
        'found': found,
        'elapsedMs': elapsedMs,
        if (error != null) 'error': '$error',
        if (artist != null) 'artist': artist,
        if (title != null) 'title': title,
      },
    );
  }

  /// 歌词加载结果记录（Stopwatch 版，内部 stop 后上报，供多个歌词源共用）。
  static void lyricsLoadFrom(
    Stopwatch sw, {
    required String source,
    required bool ok,
    required bool found,
    Object? error,
    String? artist,
    String? title,
  }) {
    sw.stop();
    lyricsLoad(
      source: source,
      ok: ok,
      found: found,
      elapsedMs: sw.elapsedMilliseconds,
      error: error,
      artist: artist,
      title: title,
    );
  }

  void start() {
    if (_started) return;
    _started = true;
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _sampleTimer ??=
        Timer.periodic(_sampleInterval, (_) => unawaited(_sample()));
  }

  void stop() {
    _sampleTimer?.cancel();
    _sampleTimer = null;
  }

  void _onTimings(List<FrameTiming> timings) {
    if (timings.isEmpty) return;
    final now = DateTime.now();
    _lastFrameAt = now;
    for (final t in timings) {
      _frames.add(t);
      _frameSeq++;
      // jank 判定用 UI 线程实际工作量（build+raster），而非 totalSpan：
      // totalSpan 含帧管线等待（vsync 错过、低帧率上下文如 Android Auto
      // 投射/后台），build/raster 仅 ~10ms 却报 50ms+，会系统性误报
      // （曾见 892 条 jank 全部 buildMs 5-8ms）。
      final buildMs = t.buildDuration.inMicroseconds / 1000;
      final rasterMs = t.rasterDuration.inMicroseconds / 1000;
      final uiMs = buildMs + rasterMs;
      final totalMs = t.totalSpan.inMicroseconds / 1000;
      if (uiMs > _jankThresholdMs) {
        // 秒级聚合：持续卡顿时避免逐帧事件淹没缓冲
        final last = _lastJankRecordedAt;
        if (last == null ||
            now.difference(last) >= const Duration(seconds: 1)) {
          _lastJankRecordedAt = now;
          DiagnosticsService.instance.record(
            EventType.frameJank,
            LogLevel.warn,
            {
              'frame': _frameSeq,
              'totalMs': totalMs.round(),
              'buildMs': buildMs.round(),
              'rasterMs': rasterMs.round(),
              'route': DiagnosticsService.instance.currentRoute,
            },
          );
        }
      } else if (uiMs > _slowFrameMs) {
        // 慢帧（25~50ms）：转场动画等场景的轻微掉帧，jank 阈值抓不到，
        // 逐帧上报会刷屏，同样秒级聚合（info 级）。
        final last = _lastSlowRecordedAt;
        if (last == null ||
            now.difference(last) >= const Duration(seconds: 1)) {
          _lastSlowRecordedAt = now;
          DiagnosticsService.instance.record(
            EventType.frameSlow,
            LogLevel.info,
            {
              'frame': _frameSeq,
              'totalMs': totalMs.round(),
              'buildMs': buildMs.round(),
              'rasterMs': rasterMs.round(),
              'route': DiagnosticsService.instance.currentRoute,
            },
          );
        }
      }
    }
    // 只保留最近 [_frameWindow] 内的帧（按时间裁剪）。
    //
    // 早先按「最多 900 帧」裁剪：60fps 下约 15s、8fps 下约 112s——窗口长度
    // 随帧率漂移，jankRate 的统计区间跟着失真。按时间裁剪后窗口恒定；
    // 另外保留 1200 帧硬上限（120Hz × 10s）兜住内存。
    final newestUs = _frames.last.timestampInMicroseconds(FramePhase.vsyncStart);
    final cutoffUs = newestUs - _frameWindow.inMicroseconds;
    var drop = 0;
    while (drop < _frames.length - 1 &&
        _frames[drop].timestampInMicroseconds(FramePhase.vsyncStart) <
            cutoffUs) {
      drop++;
    }
    if (drop > 0) _frames.removeRange(0, drop);
    if (_frames.length > 1200) {
      _frames.removeRange(0, _frames.length - 1200);
    }
  }

  /// 计算最近窗口 FPS 与 jank 率。
  void _aggregate() {
    if (_frames.isEmpty) return;
    // 空闲保护：长时间没有新帧时窗口数据已失效，报 0 而不是沿用旧值。
    // 否则「停在某个页面不动」会被诊断页读成「持续 100% jank」。
    final lastAt = _lastFrameAt;
    if (lastAt != null &&
        DateTime.now().difference(lastAt) > _frameWindow * 2) {
      DiagnosticsService.instance.updateFrameStats(fps: 0, jankRate: 0);
      return;
    }
    // 最近 10s 窗口内 jank 帧占比（与事件判定同源）。
    final jank = _frames.where((f) {
      return (f.buildDuration.inMicroseconds +
                  f.rasterDuration.inMicroseconds) /
              1000 >
          _jankThresholdMs;
    }).length;
    final jankRate = jank / _frames.length;
    final fps = _estimateFps();
    DiagnosticsService.instance.updateFrameStats(fps: fps, jankRate: jankRate);
  }

  /// 真实帧率：窗口内「帧数差 ÷ 时间跨度」。
  ///
  /// 早先用 `帧数 × 1000 / 窗口毫秒`，缓冲一满（900 帧）就恒定输出 90，
  /// 与真实帧率无关——诊断页的 FPS 卡片因此长期是假数。
  double _estimateFps() {
    if (_frames.length < 2) return 0;
    final firstUs = _frames.first.timestampInMicroseconds(FramePhase.vsyncStart);
    final lastUs = _frames.last.timestampInMicroseconds(FramePhase.vsyncStart);
    final spanUs = lastUs - firstUs;
    if (spanUs <= 0) return 0;
    return (_frames.length - 1) *
        Duration.microsecondsPerSecond /
        spanUs;
  }

  Future<void> _sample() async {
    _aggregate();
    final rss = await PlatformInfo.currentRssKb();
    final cache = PaintingBinding.instance.imageCache;
    DiagnosticsService.instance.record(
      EventType.metricsMemory,
      LogLevel.info,
      {
        'sample': 'memory',
        'rssKb': rss,
        'imageCacheCount': cache.currentSize,
        'imageCacheBytes': cache.currentSizeBytes,
        'imageCacheLimitBytes': cache.maximumSizeBytes,
      },
      sessionId: 'app',
    );
  }
}
