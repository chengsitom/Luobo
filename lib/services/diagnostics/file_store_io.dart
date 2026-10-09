import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

/// 写锁获取结果。
enum WriterLockResult {
  /// 拿到锁（前序实例正常退出或无锁）。
  acquired,

  /// 锁存在但已过期（前序实例崩溃未释放），已接管；调用方应轮转隔离
  /// 可能残留的僵尸写入句柄。
  staleTakenOver,

  /// 锁被存活实例持有：本实例应降级为仅内存 ring，不落盘。
  busy,
}

/// 原生平台事件/快照文件存储（dart:io）。
///
/// - events.jsonl：事件流，增量追加、跨冷启动保留；
/// - 轮转：单文件满 [maxFileBytes] 切新文件，最多 [maxFiles] 个，删最旧；
/// - metrics.jsonl：60s 指标快照，独立上限；
/// - 导出：拷贝文件 + 生成可读文本 + meta.json 到 `export_<ts>/` 目录；
/// - 写锁：`.writer.lock` 防止进程/引擎重建后两个实例并发追加同一文件
///   （曾导致 JSONL 记录被写穿、seq 重复、双 appSessionId 并存）。
///
/// 所有写入经单一串行 Future 链执行，避免并发 append 与轮转
/// （close/rename/reopen）交错导致的竞态。
class DiagFileStore {
  static const String _lockFileName = '.writer.lock';

  /// 锁心跳间隔：存活实例每 [lockHeartbeat] 刷新一次锁时间戳。
  static const Duration lockHeartbeat = Duration(seconds: 10);

  /// 锁过期阈值：超过此时长无心跳视为前序实例崩溃，可接管。
  static const Duration lockStaleAfter = Duration(seconds: 30);
  final int maxFileBytes;
  final int maxFiles;

  DiagFileStore({
    this.maxFileBytes = 1 * 1024 * 1024, // 1MB
    this.maxFiles = 5,
  });

  Directory? _dir;
  IOSink? _eventSink;
  IOSink? _metricsSink;
  int _eventBytes = 0;
  int _metricsBytes = 0;
  Future<void> _writeChain = Future.value(); // 串行化写入队列
  File? _lockFile;
  DateTime? _lockRefreshedAt;
  String _lockToken = '';
  bool _lockLost = false;

  /// 写锁是否已失去所有权（被其他实例接管）：失去后本实例停止落盘，
  /// 事件仅保留在内存 ring，由 DiagnosticsService 转入接管重试。
  bool get lockLost => _lockLost;

  Future<Directory> _ensureDir() async {
    if (_dir != null) return _dir!;
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/diagnostics');
    await dir.create(recursive: true);
    _dir = dir;
    return dir;
  }

  Future<void> init() async {
    final dir = await _ensureDir();
    // 续接已有文件大小（字节），避免重启后轮转阈值失效
    final f = File('${dir.path}/events.jsonl');
    if (await f.exists()) {
      _eventBytes = await f.length();
    }
    final m = File('${dir.path}/metrics.jsonl');
    if (await m.exists()) {
      _metricsBytes = await m.length();
    }
    // 清理上次轮转/崩溃残留的 tmp 文件
    final tmp = File('${dir.path}/metrics.tmp');
    if (await tmp.exists()) {
      try {
        await tmp.delete();
      } catch (_) {}
    }
  }

  Future<IOSink> _openEventSink() async {
    _eventSink ??= File('${(await _ensureDir()).path}/events.jsonl')
        .openWrite(mode: FileMode.append);
    return _eventSink!;
  }

  Future<IOSink> _openMetricsSink() async {
    _metricsSink ??= File('${(await _ensureDir()).path}/metrics.jsonl')
        .openWrite(mode: FileMode.append);
    return _metricsSink!;
  }

  int _utf8Bytes(String s) => utf8.encode(s).length;

  Future<void> appendEvent(String line) {
    if (_lockLost) return Future.value(); // 已失去写权：事件留在内存 ring
    final op =
        _writeChain.catchError((_) {}).then((_) => _appendEventInner(line));
    // 链保持存活：错误仅由本次调用方感知，不毒化后续任务
    _writeChain = op.catchError((_) {});
    return op;
  }

  Future<void> _appendEventInner(String line) async {
    final sink = await _openEventSink();
    sink.write(line);
    sink.write('\n');
    _eventBytes += _utf8Bytes(line) + 1;
    if (_eventBytes >= maxFileBytes) {
      await _rotateEvents();
    }
  }

  Future<void> appendMetrics(String line) {
    if (_lockLost) return Future.value(); // 已失去写权：快照不落盘
    final op =
        _writeChain.catchError((_) {}).then((_) => _appendMetricsInner(line));
    _writeChain = op.catchError((_) {});
    return op;
  }

  Future<void> _appendMetricsInner(String line) async {
    final sink = await _openMetricsSink();
    sink.write(line);
    sink.write('\n');
    _metricsBytes += _utf8Bytes(line) + 1;
    if (_metricsBytes >= 2 * maxFileBytes) {
      // 指标独立轮转：tmp + rename 原子替换，避免中途崩溃留半截文件
      await _metricsSink?.flush();
      await _metricsSink?.close();
      _metricsSink = null;
      final dir = await _ensureDir();
      final f = File('${dir.path}/metrics.jsonl');
      if (await f.exists()) {
        final content = await f.readAsBytes();
        final keep = content.length > maxFileBytes
            ? content.sublist(content.length - maxFileBytes)
            : content;
        final tmp = File('${dir.path}/metrics.tmp');
        await tmp.writeAsBytes(keep, flush: true);
        await tmp.rename('${dir.path}/metrics.jsonl');
      }
      _metricsBytes = (await f.exists()) ? await f.length() : 0;
    }
  }

  Future<void> _rotateEvents() async {
    await _eventSink?.flush();
    await _eventSink?.close();
    _eventSink = null;
    final dir = await _ensureDir();
    // events.4 -> 删除；events.3 -> events.4 ... events.1 -> events.2；events.jsonl -> events.1
    final oldest = File('${dir.path}/events.$maxFiles.jsonl');
    if (await oldest.exists()) await oldest.delete();
    for (var i = maxFiles - 1; i >= 1; i--) {
      final src = File('${dir.path}/events.$i.jsonl');
      if (await src.exists()) {
        await src.rename('${dir.path}/events.${i + 1}.jsonl');
      }
    }
    final cur = File('${dir.path}/events.jsonl');
    if (await cur.exists()) {
      await cur.rename('${dir.path}/events.1.jsonl');
    }
    _eventBytes = 0;
    await _openEventSink();
  }

  /// 供外部（诊断服务）在接管陈旧写锁后调用：轮转当前事件文件，
  /// 隔离可能残留的僵尸写入句柄，保证新文件从 0 字节干净开始。
  Future<void> rotateEvents() => _rotateEvents();

  // ── 写锁（跨实例防并发追加）────────────────────────────────────────────

  /// 以独占方式获取写锁。
  ///
  /// - 锁文件不存在 → 创建并返回 [WriterLockResult.acquired]；
  /// - 锁存在但超过 [lockStaleAfter] 无心跳（内容缺失/超时）→ 接管并返回
  ///   [WriterLockResult.staleTakenOver]；
  /// - 锁被存活实例持有 → 返回 [WriterLockResult.busy]，调用方应降级为
  ///   仅内存 ring（不落盘）。
  Future<WriterLockResult> acquireWriterLock() async {
    final dir = await _ensureDir();
    final lockFile = File('${dir.path}/$_lockFileName');
    _lockFile = lockFile;
    _lockToken = 'tok-${Random().nextInt(1 << 31).toRadixString(16)}';
    _lockLost = false;
    try {
      await lockFile.create(exclusive: true);
      await _touchLock();
      return WriterLockResult.acquired;
    } on FileSystemException {
      // 已存在：内容缺失或心跳超时视为陈旧（前序实例崩溃未释放）
      try {
        final content = (await lockFile.readAsString()).trim();
        final createdMs = int.tryParse(content.split(' ').first);
        final isStale = createdMs == null ||
            DateTime.now().difference(
                    DateTime.fromMillisecondsSinceEpoch(createdMs)) >
                lockStaleAfter;
        if (isStale) {
          await _touchLock();
          return WriterLockResult.staleTakenOver;
        }
      } catch (_) {}
      _lockFile = null;
      return WriterLockResult.busy;
    }
  }

  /// 心跳刷新锁时间戳（由周期 flush 调用，内部按 [lockHeartbeat] 节流）。
  ///
  /// 每次调用先做**所有权校验**：锁文件里的 token 已被其他实例改写
  /// （本实例被接管）→ 置 [lockLost]，本实例停止落盘，防止两个实例
  /// 同时写事件文件（曾见接管轮转后旧实例继续写旧分卷）。
  Future<void> refreshWriterLock() async {
    final lock = _lockFile;
    if (lock == null) return;
    // 所有权校验：内容非 `ts token` 两段或 token 不符 → 已被接管
    try {
      final parts = (await lock.readAsString()).trim().split(' ');
      if (parts.length != 2 || parts[1] != _lockToken) {
        _markLockLost();
        return;
      }
    } catch (_) {
      _markLockLost();
      return;
    }
    final now = DateTime.now();
    if (_lockRefreshedAt != null &&
        now.difference(_lockRefreshedAt!) < lockHeartbeat) {
      return;
    }
    try {
      await _touchLock();
    } catch (_) {
      _markLockLost();
    }
  }

  void _markLockLost() {
    _lockLost = true;
    _lockFile = null;
    _lockRefreshedAt = null;
  }

  Future<void> _touchLock() async {
    final lock = _lockFile;
    if (lock == null) return;
    await lock
        .writeAsString('${DateTime.now().millisecondsSinceEpoch} $_lockToken');
    _lockRefreshedAt = DateTime.now();
  }

  /// 释放写锁（正常退出/切换实例时调用；崩溃场景由陈旧超时兜底）。
  Future<void> releaseWriterLock() async {
    final lock = _lockFile;
    _lockFile = null;
    _lockRefreshedAt = null;
    if (lock == null) return;
    try {
      await lock.delete();
    } catch (_) {}
  }

  /// 读取指标快照文件尾部（fps/jankRate/网络聚合），供移动端单文件导出。
  Future<String> readMetricsTail({int maxLines = 120}) async {
    final dir = await _ensureDir();
    final f = File('${dir.path}/metrics.jsonl');
    try {
      final lines = await f.readAsLines();
      return lines.length > maxLines
          ? lines.sublist(lines.length - maxLines).join('\n')
          : lines.join('\n');
    } catch (_) {
      return '';
    }
  }

  /// 从事件文件尾恢复 {seq, appSessionId}：跨启动状态对账，修复双实例
  /// 写穿后新实例 seq/appSessionId 与文件不一致（重复 seq、会话分叉）的问题。
  /// 只读各文件尾部，与导出解析策略一致：损坏行跳过。
  Future<({int? seq, String? appSessionId})> readTailState() async {
    final dir = await _ensureDir();
    int? maxSeq;
    String? lastAppSessionId;
    Future<void> scan(File f) async {
      try {
        final lines = await f.readAsLines();
        final tail =
            lines.length > 40 ? lines.sublist(lines.length - 40) : lines;
        for (final line in tail) {
          try {
            final m = jsonDecode(line) as Map<String, dynamic>;
            final s = (m['seq'] as num?)?.toInt();
            if (s != null && (maxSeq == null || s > maxSeq!)) maxSeq = s;
            final aid = m['appSessionId'] as String?;
            if (aid != null && aid.isNotEmpty) lastAppSessionId = aid;
          } catch (_) {
            // 损坏行跳过（与导出解析策略一致）
          }
        }
      } catch (_) {
        // 文件不可读跳过
      }
    }

    // 最旧分卷 → 最新分卷 → 当前文件；appSessionId 取最新有效行（覆盖赋值）
    for (var i = maxFiles; i >= 1; i--) {
      await scan(File('${dir.path}/events.$i.jsonl'));
    }
    await scan(File('${dir.path}/events.jsonl'));
    return (seq: maxSeq, appSessionId: lastAppSessionId);
  }

  Future<void> _flushSinks() async {
    try {
      await _eventSink?.flush();
      await _metricsSink?.flush();
    } catch (_) {}
  }

  Future<void> flush() async {
    // 先等待写链排空，再 flush sink，避免与链内轮转交错
    await _writeChain.catchError((_) {});
    await _flushSinks();
    await refreshWriterLock(); // 心跳：维持写锁存活，防被误判陈旧接管
  }

  Future<void> close() async {
    await _writeChain.catchError((_) {});
    try {
      await _eventSink?.flush();
      await _metricsSink?.flush();
      await _eventSink?.close();
      await _metricsSink?.close();
    } catch (_) {}
    _eventSink = null;
    _metricsSink = null;
    await releaseWriterLock();
  }

  /// 清空全部日志/指标/导出目录。与写入、导出共享同一串行链，避免竞态。
  Future<void> clear() {
    final op = _writeChain.catchError((_) {}).then((_) => _clearInner());
    _writeChain = op.catchError((_) {});
    return op;
  }

  Future<void> _clearInner() async {
    // 已在串行链内执行：直接 flush+close sink，不再等待链（避免自等待死锁）
    try {
      await _eventSink?.flush();
      await _metricsSink?.flush();
      await _eventSink?.close();
      await _metricsSink?.close();
    } catch (_) {}
    _eventSink = null;
    _metricsSink = null;
    final dir = await _ensureDir();
    // 删除轮转分卷、当前文件、指标与历史导出目录（避免磁盘无界增长）
    for (var i = 1; i <= maxFiles; i++) {
      final f = File('${dir.path}/events.$i.jsonl');
      if (await f.exists()) await f.delete();
    }
    final e = File('${dir.path}/events.jsonl');
    if (await e.exists()) await e.delete();
    final m = File('${dir.path}/metrics.jsonl');
    if (await m.exists()) await m.delete();
    final tmp = File('${dir.path}/metrics.tmp');
    if (await tmp.exists()) await tmp.delete();
    final lock = File('${dir.path}/$_lockFileName');
    if (await lock.exists()) await lock.delete();
    _lockFile = null;
    _lockRefreshedAt = null;
    _lockLost = false;
    await for (final entry in dir.list()) {
      if (entry is Directory &&
          entry.uri.pathSegments.isNotEmpty &&
          entry.uri.pathSegments.last.startsWith('export_')) {
        try {
          await entry.delete(recursive: true);
        } catch (_) {}
      }
    }
    _eventBytes = 0;
    _metricsBytes = 0;
  }

  /// 导出：拷贝原始文件 + 生成可读文本 + meta.json，返回导出目录路径。
  /// 与写入、清空共享同一串行链，避免与轮转/删除交错。
  Future<String?> export(String readableText, Map<String, dynamic> meta) {
    final op = _writeChain
        .catchError((_) {})
        .then((_) => _exportInner(readableText, meta));
    _writeChain = op.catchError((_) => null);
    return op;
  }

  Future<String?> _exportInner(
      String readableText, Map<String, dynamic> meta) async {
    await _flushSinks();
    final dir = await _ensureDir();
    final exportDir = Directory(
      '${dir.path}/export_${DateTime.now().millisecondsSinceEpoch}',
    );
    await exportDir.create(recursive: true);
    for (var i = maxFiles; i >= 1; i--) {
      final src = File('${dir.path}/events.$i.jsonl');
      if (await src.exists()) {
        await src.copy('${exportDir.path}/events.$i.jsonl');
      }
    }
    final e = File('${dir.path}/events.jsonl');
    if (await e.exists()) {
      await e.copy('${exportDir.path}/events.jsonl');
    }
    final m = File('${dir.path}/metrics.jsonl');
    if (await m.exists()) {
      await m.copy('${exportDir.path}/metrics.jsonl');
    }
    await File('${exportDir.path}/export.txt')
        .writeAsString(readableText, flush: true);
    await File('${exportDir.path}/meta.json').writeAsString(
        const JsonEncoder.withIndent('  ').convert(meta),
        flush: true);
    return exportDir.path;
  }

  /// 读取最近事件文件尾部（用于导出可读文本 / 诊断页加载）。
  /// 按时间序拼接：最旧分卷（events.$maxFiles）→ 最新分卷（events.1）→ 当前文件，
  /// 尾部截断时保留最新数据。
  Future<String> readEventLines({int maxLines = 500}) async {
    final dir = await _ensureDir();
    final lines = <String>[];
    for (var i = maxFiles; i >= 1; i--) {
      final f = File('${dir.path}/events.$i.jsonl');
      if (await f.exists()) {
        lines.addAll(await f.readAsLines());
      }
    }
    final cur = File('${dir.path}/events.jsonl');
    if (await cur.exists()) {
      lines.addAll(await cur.readAsLines());
    }
    if (lines.length > maxLines) {
      return lines.sublist(lines.length - maxLines).join('\n');
    }
    return lines.join('\n');
  }
}
