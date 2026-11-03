/// 诊断事件类型常量表（domain.action）。
///
/// 开发时新增埋点必须先在此登记类型，避免字符串拼写漂移导致查不到日志。
class EventType {
  EventType._();

  // log.* —— LoggingService 统一日志
  static const String logDebug = 'log.debug';
  static const String logInfo = 'log.info';
  static const String logWarn = 'log.warn';
  static const String logError = 'log.error';
  static const String logPrint = 'log.print';

  // app.* —— 启动与生命周期
  static const String appStart = 'app.start';
  static const String appLaunchMilestone = 'app.launchMilestone';
  static const String appLifecycle = 'app.lifecycle';

  // metrics.* —— 周期性采样指标
  static const String metricsMemory = 'metrics.memory';

  // 持久化熔断探测（_writeSnapshot 熔断期间每 60s 试写一条）
  static const String appProbe = 'app.probe';

  // audio.* —— 场景 A：播放中断无声
  static const String audioInterruption = 'audio.interruption';
  static const String audioNoisy = 'audio.noisy';
  static const String audioRouteChanged = 'audio.routeChanged';
  static const String audioPlayerAction = 'audio.playerAction';
  static const String audioSessionState = 'audio.sessionState';
  static const String audioSilentPlayback = 'audio.silentPlayback';
  static const String audioStall = 'audio.stall';
  static const String audioBuffer = 'audio.buffer';
  static const String audioError = 'audio.error';

  // nav.* / ui.* —— 场景 B：全屏页/车载页卡顿
  static const String navTransition = 'nav.transition';
  static const String screenBuildTime = 'screen.buildTime';
  static const String paletteExtract = 'palette.extract';
  static const String paletteEvict = 'palette.evict';
  static const String animActive = 'anim.active';
  static const String carDrag = 'car.drag';
  static const String frameJank = 'frame.jank';

  /// 慢帧（UI 线程 build+raster 25~50ms，转场等动画期间的轻微掉帧）。
  static const String frameSlow = 'frame.slow';

  // net.* / stream.* —— 场景 C：网络切换与转码
  static const String netSwitch = 'net.switch';
  static const String netUrlResolved = 'net.urlResolved';
  static const String streamUrl = 'stream.url';
  static const String requestTiming = 'net.request';

  // 补充场景
  static const String restoreStart = 'restore.start';
  static const String restoreEnd = 'restore.end';
  static const String restoreError = 'restore.error';
  static const String trackNext = 'track.next';
  /// 有声书进度云同步（跟进度 / 合并结果 / 响应形态）。
  static const String audiobookProgressSync = 'audiobook.progressSync';
  static const String cachePrune = 'cache.prune';
  static const String taskBpm = 'task.bpm';
  static const String remoteConnect = 'remote.connect';
  static const String remoteDisconnect = 'remote.disconnect';
  static const String remoteError = 'remote.error';
  static const String lyricsLoad = 'lyrics.load';
}

/// 日志级别（由低到高）。
enum LogLevel { debug, info, warn, error }
