import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'diagnostics_service.dart';
import 'event_types.dart';

/// 全局异常捕获（三路挂钩）+ 友好错误页。
///
/// - [install]：FlutterError.onError / PlatformDispatcher.onError /
///   ErrorWidget.builder —— 这三路覆盖框架与平台回调，是兜底主通道；
/// - [runGuarded]：runZonedGuarded 包裹 runApp。注意 zone 只覆盖 runApp
///   同步路径及其派生的 future 与 print；帧回调/手势/框架定时器闭包创建于
///   root zone，不受本 zone 约束，因此 [install] 的三路钩子才是真正兜底。
class GlobalErrorHandler {
  GlobalErrorHandler._();

  /// 提供可用的 BuildContext（如 navigatorKey.currentContext），
  /// 供 ErrorWidget 兜底页获取 AppLocalizations；取不到时回退硬编码文案。
  static BuildContext? Function()? contextProvider;

  /// debug print 兜底无节流会淹没事件流（曾见单条循环打印 1600+ 条、队列状态
  /// 每秒 1 条）。以消息前 [printSuppressKeyLen] 字符为键做时间窗去重：
  /// [printSuppressWindowMs] 内同类消息只记 1 条，控制台输出不受影响。
  /// 取前缀而非全文：位置/耗时变化的消息也能被折叠。
  static const int printSuppressWindowMs = 10000;
  static const int printSuppressKeyLen = 64;
  static final Map<String, int> _printSuppress = {};

  static void install() {
    FlutterError.onError = (details) {
      DiagnosticsService.instance.record(
        EventType.logError,
        LogLevel.error,
        {
          'exception': details.exceptionAsString(),
          'stack': details.stack?.toString(),
          'library': details.library,
        },
      );
      FlutterError.presentError(details);
      // 崩溃场景：立即 flush，避免进程终止丢最后一条
      unawaited(DiagnosticsService.instance.flush());
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      DiagnosticsService.instance.record(
        EventType.logError,
        LogLevel.error,
        {'exception': '$error', 'stack': stack.toString()},
      );
      unawaited(DiagnosticsService.instance.flush());
      return true;
    };

    ErrorWidget.builder = (details) {
      final err = details.exceptionAsString();
      DiagnosticsService.instance.record(
        EventType.logError,
        LogLevel.error,
        {'widgetError': err},
      );
      // l10n 查找包 try/catch：ErrorWidget.builder 调用时机不稳定（SDK 文档
      // 明确警告），取 l10n 抛异常会让友好错误页渲染失败；兜底用英文
      // 与 en arb 的 renderError 同源。
      String label = 'Render error\n$err';
      try {
        final ctx = contextProvider?.call();
        final l10n = ctx != null ? AppLocalizations.of(ctx) : null;
        if (l10n != null) label = l10n.renderError(err);
      } catch (_) {
        // 保留兜底文案
      }
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: const Color(0xFF1C1C1E),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ),
      );
    };
  }

  /// 在 guarded zone 中执行 runApp，捕获未处理异步异常。
  /// debug 模式下额外拦截 zone 内 print（debugPrint 最终走 print），
  /// 兜底接入散落日志；release 下不拦截，避免全量落盘膨胀。
  static void runGuarded(void Function() body) {
    runZonedGuarded(
      () {
        if (kReleaseMode) {
          body();
          return;
        }
        Zone.current.fork(
          specification: ZoneSpecification(
            print: (self, parent, zone, line) {
              parent.print(zone, line); // 保留控制台输出
              final now = DateTime.now().millisecondsSinceEpoch;
              final key = line.length > printSuppressKeyLen
                  ? line.substring(0, printSuppressKeyLen)
                  : line;
              final last = _printSuppress[key];
              if (last != null && now - last < printSuppressWindowMs) {
                return; // 时间窗内同类消息已记录，抑制落盘
              }
              _printSuppress[key] = now;
              if (_printSuppress.length > 256) {
                _printSuppress
                    .removeWhere((_, t) => now - t >= printSuppressWindowMs);
              }
              DiagnosticsService.instance.record(
                EventType.logPrint,
                LogLevel.debug,
                {'msg': line},
              );
            },
          ),
        ).run(body);
      },
      (error, stack) {
        DiagnosticsService.instance.record(
          EventType.logError,
          LogLevel.error,
          {'exception': '$error', 'stack': stack.toString()},
        );
        unawaited(DiagnosticsService.instance.flush());
      },
    );
  }
}
