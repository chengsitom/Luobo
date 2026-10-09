import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Represents a single lyrics line with its timestamp
@immutable
class LyricsLine {
  final Duration timestamp;
  final String text;

  const LyricsLine({
    required this.timestamp,
    required this.text,
  });

  @override
  String toString() => 'LyricsLine(${timestamp.inMilliseconds}ms: "$text")';
}

/// Manages parsed LRC lyrics and provides synchronized line lookup
class LyricsManager {
  /// Parsed lyrics lines sorted by timestamp
  final List<LyricsLine> _lines;

  /// Binary search cache for performance optimization
  int? _lastIndex;

  /// Throttling: minimum interval between updates
  static const _minUpdateInterval = Duration(milliseconds: 200);
  DateTime? _lastUpdateTime;

  /// Current lyrics line cache
  String? _currentLine;

  LyricsManager._(this._lines);

  /// Creates an empty LyricsManager (no lyrics available)
  factory LyricsManager.empty() => LyricsManager._([]);

  /// Parses an LRC file content and creates a LyricsManager
  ///
  /// LRC format:
  /// [mm:ss.xx]Lyrics text
  /// [mm:ss.xx]Lyrics text
  ///
  /// Also supports extended tags like [ar:Artist], [ti:Title], etc.
  factory LyricsManager.parse(String lrcContent) {
    if (lrcContent.trim().isEmpty) {
      return LyricsManager.empty();
    }

    final lines = <LyricsLine>[];
    final linePattern = RegExp(r'\[(\d{2}):(\d{2})\.(\d{2,3})\](.*)');

    for (final line in lrcContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Match all timestamps on this line (some formats have multiple [mm:ss.xx] tags)
      final matches = linePattern.allMatches(trimmed);

      for (final match in matches) {
        final minutes = int.tryParse(match.group(1) ?? '0') ?? 0;
        final seconds = int.tryParse(match.group(2) ?? '0') ?? 0;
        final centiseconds = match.group(3) ?? '00';

        // Handle both 2-digit (centiseconds) and 3-digit (milliseconds) formats
        final msDigits = centiseconds.length;
        final milliseconds = msDigits == 2
            ? (int.tryParse(centiseconds) ?? 0) * 10
            : int.tryParse(centiseconds.substring(0, 3)) ?? 0;

        final text = match.group(4)?.trim() ?? '';

        if (text.isNotEmpty) {
          final timestamp = Duration(
            minutes: minutes,
            seconds: seconds,
            milliseconds: milliseconds,
          );
          lines.add(LyricsLine(timestamp: timestamp, text: text));
        }
      }
    }

    // Sort by timestamp for binary search
    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return LyricsManager._(lines);
  }

  /// Whether lyrics are available
  bool get hasLyrics => _lines.isNotEmpty;

  /// Total number of lyrics lines
  int get lineCount => _lines.length;

  /// Returns the current lyrics line for the given position
  /// Optimized with caching and throttling
  String? getCurrentLine(Duration position) {
    // Throttling check
    final now = DateTime.now();
    if (_lastUpdateTime != null) {
      final elapsed = now.difference(_lastUpdateTime!);
      if (elapsed < _minUpdateInterval && _currentLine != null) {
        return _currentLine;
      }
    }
    _lastUpdateTime = now;

    if (_lines.isEmpty) {
      _currentLine = null;
      return null;
    }

    // Find the line that corresponds to the current position
    final index = _findLineIndex(position);

    if (index >= 0 && index < _lines.length) {
      _currentLine = _lines[index].text;
      return _currentLine;
    }

    _currentLine = null;
    return null;
  }

  /// Returns the current line with context (previous, current, next)
  /// Useful for UI display with surrounding lines
  LyricsContext getContext(Duration position) {
    if (_lines.isEmpty) {
      return const LyricsContext();
    }

    final index = _findLineIndex(position);

    return LyricsContext(
      previousLine: index > 0 ? _lines[index - 1].text : null,
      currentLine:
          index >= 0 && index < _lines.length ? _lines[index].text : null,
      nextLine: index >= 0 && index < _lines.length - 1
          ? _lines[index + 1].text
          : null,
    );
  }

  /// Binary search to find the current line index
  /// Returns the index of the line that should be displayed at the given position
  int _findLineIndex(Duration position) {
    // Optimize: check if we're still on the same line
    if (_lastIndex != null && _lastIndex! >= 0 && _lastIndex! < _lines.length) {
      final currentLine = _lines[_lastIndex!];
      final nextTimestamp = _lastIndex! < _lines.length - 1
          ? _lines[_lastIndex! + 1].timestamp
          : null;

      if (position >= currentLine.timestamp &&
          (nextTimestamp == null || position < nextTimestamp)) {
        return _lastIndex!;
      }
    }

    // Binary search
    int left = 0;
    int right = _lines.length - 1;
    int result = -1;

    while (left <= right) {
      final mid = (left + right) ~/ 2;
      final line = _lines[mid];

      if (line.timestamp <= position) {
        result = mid;
        left = mid + 1;
      } else {
        right = mid - 1;
      }
    }

    _lastIndex = result;
    return result;
  }

  /// Creates a stream of lyrics lines synchronized to a position stream
  ///
  /// Usage:
  /// ```dart
  /// final lyricsStream = lyricsManager.syncToPosition(
  ///   audioPlayer.positionStream,
  ///   updateInterval: Duration(milliseconds: 500),
  /// );
  /// ```
  Stream<String?> syncToPosition(
    Stream<Duration> positionStream, {
    Duration updateInterval = const Duration(milliseconds: 500),
  }) {
    return positionStream
        .throttle(updateInterval)
        .map((position) => getCurrentLine(position))
        .distinct()
        .handleError((error) {
      debugPrint('Lyrics sync error: $error');
    });
  }

  /// Get all lyrics lines (for debugging or full display)
  List<LyricsLine> get allLines => UnmodifiableListView(_lines);

  /// Clear cache and reset state
  void clearCache() {
    _lastIndex = null;
    _currentLine = null;
    _lastUpdateTime = null;
  }
}

/// Context for lyrics display with surrounding lines
@immutable
class LyricsContext {
  final String? previousLine;
  final String? currentLine;
  final String? nextLine;

  const LyricsContext({
    this.previousLine,
    this.currentLine,
    this.nextLine,
  });

  bool get hasCurrentLine => currentLine != null && currentLine!.isNotEmpty;
}

/// Extension for throttling streams
extension _ThrottleStream<T> on Stream<T> {
  Stream<T> throttle(Duration duration) {
    Timer? timer;
    T? latestValue;
    bool hasLatest = false;

    return Stream.multi((controller) {
      final subscription = listen(
        (data) {
          latestValue = data;
          hasLatest = true;

          if (timer?.isActive != true) {
            controller.add(data);
            timer = Timer(duration, () {
              if (hasLatest) {
                controller.add(latestValue!);
                hasLatest = false;
              }
            });
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );

      controller.onCancel = subscription.cancel;
    });
  }
}
