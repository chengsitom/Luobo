import 'package:dio/dio.dart';

import '../../utils/log_redaction.dart';
import 'diagnostics_service.dart';
import 'event_types.dart';
import 'metrics_collector.dart';

/// 共享 URL 脱敏：Subsonic 认证参数（u/p/t/s）、道理鱼 JWT（token/ticket）
/// 等全部打码，避免密码 / token 落盘。
///
/// 旧实现只盖 p/t/s 且用 `Uri.parse` 解析整个字符串 —— 遇到「URL 嵌在
/// 异常描述文字里」会解析失败并原样返回，等于没脱敏。统一委托给
/// [redactSecretsInText]，纯 URL 与整段日志文本都能正确处理。
String sanitizeQueryUrl(String url) => redactSecretsInText(url);

/// 网络指标拦截器：请求耗时/状态码聚合（MetricsCollector）+
/// requestTiming 事件落盘（DiagnosticsService）。
///
/// - [sanitizeUrl]：URL 脱敏回调，默认 [sanitizeQueryUrl]；
/// - [logLine]：可选，可读日志行输出（如 subsonic 侧接 Log API）。
Interceptor networkMetricsInterceptor({
  String Function(String url)? sanitizeUrl,
  void Function(String line)? logLine,
}) {
  final sanitize = sanitizeUrl ?? sanitizeQueryUrl;
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      options.extra['_logSw'] = Stopwatch()..start();
      if (logLine != null) {
        logLine('→ ${options.method} ${sanitize(options.uri.toString())}');
      }
      handler.next(options);
    },
    onResponse: (response, handler) {
      final sw = response.requestOptions.extra['_logSw'] as Stopwatch?;
      sw?.stop();
      final ms = sw?.elapsedMilliseconds ?? 0;
      final safe = sanitize(response.requestOptions.uri.toString());
      MetricsCollector.networkRequest(ms: ms, ok: true);
      DiagnosticsService.instance.record(
        EventType.requestTiming,
        LogLevel.info,
        {
          'method': response.requestOptions.method,
          'url': safe,
          'status': response.statusCode,
          'ms': ms,
          'ok': true,
        },
      );
      if (logLine != null) {
        logLine('← ${response.statusCode} $safe (${ms}ms)');
      }
      handler.next(response);
    },
    onError: (e, handler) {
      final sw = e.requestOptions.extra['_logSw'] as Stopwatch?;
      sw?.stop();
      final ms = sw?.elapsedMilliseconds ?? 0;
      final safe = sanitize(e.requestOptions.uri.toString());
      MetricsCollector.networkRequest(ms: ms, ok: false);
      DiagnosticsService.instance.record(
        EventType.requestTiming,
        LogLevel.warn,
        {
          'method': e.requestOptions.method,
          'url': safe,
          'status': e.response?.statusCode,
          'ms': ms,
          'ok': false,
          'type': e.type.name,
          'message': e.message,
        },
      );
      if (logLine != null) {
        logLine('✗ ${e.type.name} $safe (${ms}ms) — ${e.message}');
        if (e.error != null) logLine('  cause: ${e.error}');
      }
      handler.next(e);
    },
  );
}
