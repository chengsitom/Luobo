import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/diagnostics/file_store_io.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// DiagFileStore 写锁与跨实例状态对账的单元测试。
///
/// 覆盖 P0 双写损坏修复的关键行为：
/// 1. 两个实例对同一目录互斥（第二个降级为 busy）；
/// 2. 心跳维持下存活锁不被误接管；
/// 3. 陈旧锁（前序实例崩溃）可被接管；
/// 4. 接管后轮转隔离旧文件；
/// 5. readTailState 从文件尾恢复 seq/appSessionId。
class _FakePathProvider extends PathProviderPlatform {
  final String path;
  _FakePathProvider(this.path);

  @override
  Future<String?> getApplicationDocumentsPath() async => path;

  @override
  Future<String?> getTemporaryPath() async => path;
}

void main() {
  late Directory tempDir;
  late String docsPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('diag_store_test');
    docsPath = '${tempDir.path}/docs';
    PathProviderPlatform.instance = _FakePathProvider(docsPath);
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  String eventLine(int seq, String appSessionId) =>
      '{"seq":$seq,"ts":"2026-08-05T10:00:00.000","sessionId":"app",'
      '"appSessionId":"$appSessionId","type":"log.info","level":"info",'
      '"payload":{}}';

  test('两个实例互斥：第二个获取锁返回 busy，释放后可被第三个获取', () async {
    final a = DiagFileStore();
    final b = DiagFileStore();
    final c = DiagFileStore();

    expect(await a.acquireWriterLock(), WriterLockResult.acquired);
    // 存活锁：第二个实例 busy
    expect(await b.acquireWriterLock(), WriterLockResult.busy);
    // 心跳刷新不影响互斥
    await a.refreshWriterLock();
    expect(await b.acquireWriterLock(), WriterLockResult.busy);

    await a.releaseWriterLock();
    expect(await c.acquireWriterLock(), WriterLockResult.acquired);
  });

  test('陈旧锁（前序实例崩溃）可被接管', () async {
    final a = DiagFileStore();
    // 预置 5 分钟前的锁文件，模拟崩溃残留
    final dir = Directory('$docsPath/diagnostics');
    await dir.create(recursive: true);
    final lock = File('${dir.path}/.writer.lock');
    await lock.writeAsString(
        '${DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch}');

    expect(await a.acquireWriterLock(), WriterLockResult.staleTakenOver);
    await a.releaseWriterLock();
  });

  test('接管陈旧锁后 rotateEvents 轮转隔离旧文件', () async {
    final a = DiagFileStore();
    await a.acquireWriterLock();
    await a.appendEvent(eventLine(1, 'as-old'));
    await a.flush();

    // 模拟崩溃：不 release，直接换新实例接管（锁变陈旧需等待超时——
    // 这里手动把锁时间戳改旧）
    final dir = Directory('$docsPath/diagnostics');
    final lock = File('${dir.path}/.writer.lock');
    await lock.writeAsString(
        '${DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch}');

    final b = DiagFileStore();
    expect(await b.acquireWriterLock(), WriterLockResult.staleTakenOver);
    await b.rotateEvents();

    // 旧事件落入 events.1.jsonl，新文件为空
    expect(await File('${dir.path}/events.1.jsonl').exists(), isTrue);
    expect(await File('${dir.path}/events.jsonl').exists(), isTrue);
    expect(await File('${dir.path}/events.jsonl').readAsString(), isEmpty);
  });

  test('readTailState 从文件尾恢复 seq 与 appSessionId', () async {
    final a = DiagFileStore();
    await a.acquireWriterLock();
    await a.appendEvent(eventLine(1, 'as-test'));
    await a.appendEvent(eventLine(2, 'as-test'));
    await a.appendEvent(eventLine(3, 'as-test'));
    await a.flush();

    final tail = await a.readTailState();
    expect(tail.seq, 3);
    expect(tail.appSessionId, 'as-test');
  });

  test('写锁被接管后原持有者停止落盘（所有权校验）', () async {
    final a = DiagFileStore();
    await a.acquireWriterLock();
    await a.appendEvent(eventLine(1, 'as-test'));
    await a.flush();
    expect(a.lockLost, isFalse);

    // 模拟被接管：锁文件 token 被其他实例改写
    final dir = Directory('$docsPath/diagnostics');
    final lock = File('${dir.path}/.writer.lock');
    await lock
        .writeAsString('${DateTime.now().millisecondsSinceEpoch} tok-other');

    await a.flush(); // 心跳校验发现 token 不符 → lockLost
    expect(a.lockLost, isTrue);

    // 失去写权后事件不再落盘
    await a.appendEvent(eventLine(2, 'as-test'));
    await a.flush();
    final tail = await a.readTailState();
    expect(tail.seq, 1); // 只有接管前的事件 1
  });
}
