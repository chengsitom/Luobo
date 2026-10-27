class WordSegment {
  final Duration timestamp;
  final String text;

  WordSegment({required this.timestamp, required this.text});
}

class SyncedLyrics {
  final List<LyricLine> lines;
  final String? artist;
  final String? title;

  /// 构造即归一化：**稳定排序 + 合并同时间戳的译文行**。
  ///
  /// 双语 LRC 的形态是「原文行 + 译文行」共用同一时间戳；不合并会带来两个 bug：
  /// 1. 高亮索引取「最后一个 timestamp <= position」→ 永远命中译文行；
  /// 2. 译文行用下一行时间戳算进度，同时间戳时 `end <= start` → 直接显示 100%。
  ///
  /// 时间戳为 0 的行（纯文本歌词）**不合并**，否则整篇纯文本会被并成一行。
  SyncedLyrics({required List<LyricLine> lines, this.artist, this.title})
      : lines = _normalize(lines);

  static List<LyricLine> _normalize(List<LyricLine> input) {
    if (input.isEmpty) return const [];
    // 稳定排序：时间戳相同保持文件顺序（List.sort 不保证稳定，用原下标兜底）。
    final indexed = input.asMap().entries.toList()
      ..sort((a, b) {
        final c = a.value.timestamp.compareTo(b.value.timestamp);
        return c != 0 ? c : a.key.compareTo(b.key);
      });

    final out = <LyricLine>[];
    for (final entry in indexed) {
      final line = entry.value;
      final canMerge = out.isNotEmpty &&
          line.timestamp == out.last.timestamp &&
          line.timestamp > Duration.zero;
      if (canMerge) {
        final prev = out.last;
        final merged = (prev.translation == null || prev.translation!.isEmpty)
            ? line.text
            : '${prev.translation}\n${line.text}';
        out[out.length - 1] = LyricLine(
          timestamp: prev.timestamp,
          text: prev.text,
          words: prev.words,
          translation: merged,
        );
      } else {
        out.add(line);
      }
    }
    return out;
  }

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  static final _wordTagRegex = RegExp(r'<(\d{1,2}):(\d{2})[.:]?(\d{2,3})>');

  static List<WordSegment> _parseWordSegments(String rawText) {
    final segments = <WordSegment>[];
    final matches = _wordTagRegex.allMatches(rawText).toList();
    for (int i = 0; i < matches.length; i++) {
      final m = matches[i];
      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final msStr = m.group(3)!;
      final ms = msStr.length == 2 ? int.parse(msStr) * 10 : int.parse(msStr);
      final ts = Duration(minutes: minutes, seconds: seconds, milliseconds: ms);
      final textStart = m.end;
      final textEnd =
          i + 1 < matches.length ? matches[i + 1].start : rawText.length;
      final segText = rawText.substring(textStart, textEnd).trim();
      if (segText.isNotEmpty) {
        segments.add(WordSegment(timestamp: ts, text: segText));
      }
    }
    return segments;
  }

  factory SyncedLyrics.fromLrc(String lrcContent) {
    final lines = <LyricLine>[];
    String? artist;
    String? title;

    for (final line in lrcContent.split('\n')) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('[ar:')) {
        artist = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }
      if (trimmed.startsWith('[ti:')) {
        title = trimmed.substring(4, trimmed.length - 1).trim();
        continue;
      }

      if (trimmed.startsWith('[al:') ||
          trimmed.startsWith('[by:') ||
          trimmed.startsWith('[offset:') ||
          trimmed.startsWith('[re:') ||
          trimmed.startsWith('[ve:')) {
        continue;
      }

      final regex =
          RegExp(r'\[(\d{1,2}):(\d{2})[:.](\d{2,3})\](.*)', dotAll: true);
      final match = regex.firstMatch(trimmed);

      if (match != null) {
        final minutes = int.parse(match.group(1)!);
        final seconds = int.parse(match.group(2)!);
        final millisPart = match.group(3)!;
        final milliseconds = millisPart.length == 2
            ? int.parse(millisPart) * 10
            : int.parse(millisPart);
        final rawText = match.group(4) ?? '';
        final lineTimestamp = Duration(
          minutes: minutes,
          seconds: seconds,
          milliseconds: milliseconds,
        );

        if (_wordTagRegex.hasMatch(rawText)) {
          final cleanText = rawText
              .replaceAll(_wordTagRegex, '')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
          if (cleanText.isNotEmpty) {
            final wordSegs = _parseWordSegments(rawText);
            lines.add(LyricLine(
              timestamp: lineTimestamp,
              text: cleanText,
              words: wordSegs.isNotEmpty ? wordSegs : null,
            ));
          }
        } else {
          final text = rawText.trim();
          if (text.isNotEmpty) {
            lines.add(LyricLine(timestamp: lineTimestamp, text: text));
          }
        }
      }
    }

    lines.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return SyncedLyrics(lines: lines, artist: artist, title: title);
  }

  factory SyncedLyrics.fromPlainText(String text) {
    final lines =
        text.split('\n').where((line) => line.trim().isNotEmpty).toList();

    return SyncedLyrics(
      lines: lines.asMap().entries.map((entry) {
        return LyricLine(timestamp: Duration.zero, text: entry.value.trim());
      }).toList(),
    );
  }

  int getCurrentLineIndex(Duration position) {
    if (lines.isEmpty) return -1;
    if (position < lines.first.timestamp) {
      return -1;
    }

    for (int i = lines.length - 1; i >= 0; i--) {
      if (position >= lines[i].timestamp) {
        return i;
      }
    }
    return -1;
  }
}

class LyricLine {
  final Duration timestamp;
  final String text;
  final List<WordSegment>? words;

  /// 同时间戳的译文（双语歌词的第二行）—— 由 [SyncedLyrics] 构造时合并进来。
  final String? translation;

  LyricLine({
    required this.timestamp,
    required this.text,
    this.words,
    this.translation,
  });

  bool get hasWordTimestamps => words != null && words!.isNotEmpty;

  @override
  String toString() => '[$timestamp] $text';
}
