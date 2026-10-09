/// 歌词文本解析的公共纯函数（无状态、无 IO）。
///
/// P0 用途：
///   • 供道理鱼自研歌词分支（`SubsonicService._getDaoliyuLyrics`）产出
///     `structuredLyrics` 行数组，与 `lyrics`（原始 LRC）组成双键契约；
///   • 供车机链（`PlayerProvider._loadAndSyncLyrics`）判定「是否含时间轴」
///     以及做纯文本降级。
///
/// P1 用途：替换 `lrclib_service.dart` / `netease_lyrics_service.dart` 里两份
/// 完全等价的私有 `_buildStructuredLyrics`（等价重构，需回归）。
///
/// 见 `docs/歌词源优先级修复技术方案.md` §5.1 / §5.2 / §5.5。
library;

import 'dart:convert';

/// 匹配 `[mm:ss.xx]` / `[mm:ss.xxx]`，分钟数允许 1 位以上。
///
/// 与 `lrclib_service` / `netease_lyrics_service` 的私有实现保持完全一致，
/// 以便 P1 做等价替换。
final RegExp _lrcLinePattern = RegExp(r'\[(\d+):(\d{2})\.(\d{2,3})\](.*)');

/// LRC 元信息标签行，如 `[ti:歌名]` / `[ar:歌手]` / `[offset:0]`。
/// 这类行不含时间轴，但会被纯文本歌词文件带进来，需在降级时跳过。
final RegExp _lrcTagLinePattern = RegExp(r'^\s*\[[a-zA-Z#]+:[^\]]*\]\s*$');

/// 纯文本歌词的元信息行前缀，如「作词 : 张三」「作曲：李四」。
///
/// 纯文本歌词首行极常见是这类内容，直接取首行会让车机副标题显示非歌词文本。
final RegExp _metaLinePattern = RegExp(
  r'^\s*(作词|作曲|作词人|作曲人|词曲|编曲|制作人|出品|监制|混音|母带|录音|'
  r'和声|吉他|贝斯|鼓|钢琴|弦乐|演唱|歌手|词|曲|OP|SP)\s*[:：]',
  caseSensitive: false,
);

/// LRC 文本 → Subsonic structured-lyrics 行数组。
///
/// 每项形如 `{'start': <毫秒>, 'value': <文本>}`；无有效时间轴行时返回空列表。
/// 调用方据此决定是否产出 `structuredLyrics` 键（空则不产出，退回纯文本语义）。
List<Map<String, dynamic>> lrcToStructuredLines(String lrcText) {
  final lines = <Map<String, dynamic>>[];
  for (final raw in LineSplitter.split(lrcText)) {
    final line = raw.trim();
    if (line.isEmpty) continue;

    final match = _lrcLinePattern.firstMatch(line);
    if (match == null) continue;

    final text = match.group(4)!.trim();
    if (text.isEmpty) continue;

    final minutes = int.parse(match.group(1)!);
    final seconds = int.parse(match.group(2)!);
    final fracStr = match.group(3)!;
    // 2 位为厘秒、3 位为毫秒
    final fracMs =
        fracStr.length == 2 ? int.parse(fracStr) * 10 : int.parse(fracStr);
    final startMs = (minutes * 60 + seconds) * 1000 + fracMs.clamp(0, 999);

    lines.add({'start': startMs, 'value': text});
  }
  return lines;
}

/// 文本是否含可被时间轴消费的歌词行。
///
/// 用它替代 `text.contains('[') && text.contains(':')` 这类粗判：后者会把
/// 只带 `[ti:歌名]` 标签的纯文本歌词误判为 LRC。
bool hasLrcTimeline(String text) => lrcToStructuredLines(text).isNotEmpty;

/// structured-lyrics 行数组 → LRC 文本（[lrcToStructuredLines] 的逆运算）。
///
/// ⚠️ 分钟数必须补足 2 位：`LyricsManager.parse` 的正则是
/// `\[(\d{2}):(\d{2})\.(\d{2,3})\]`，**要求恰好 2 位**。此前
/// `player_provider._convertStructuredToLrc` 直接写 `'$minutes:'`，10 分钟以内的
/// 行会产出 `[0:05.30]` 而被解析器整段丢弃（短曲全部无歌词）。
String linesToLrc(List<Map<String, dynamic>> lines) {
  final buffer = StringBuffer();
  for (final line in lines) {
    final startMs = (line['start'] as num?)?.toInt() ?? 0;
    final minutes = startMs ~/ 60000;
    final seconds = (startMs % 60000) ~/ 1000;
    final centiseconds = (startMs % 1000) ~/ 10;
    buffer.writeln(
      '[${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}.'
      '${centiseconds.toString().padLeft(2, '0')}]'
      '${line['value'] ?? ''}',
    );
  }
  return buffer.toString();
}

/// 纯文本歌词 → 静态单行 LRC（`docs/歌词源优先级修复技术方案.md` §5.5 选项 A）。
///
/// 规则：按行拆分 → 去空行 → 去 LRC 标签行与元信息行 → 取首行，包装为
/// `[00:00.00]<该行>`。无可选行时返回 null，调用方退化为「不推」（回落歌手名）。
///
/// 为什么取单行而不是按行均分：单行时间戳为 0，`LyricsManager.getCurrentLine`
/// 对任意播放位置都命中该行，副标题静态显示首行且不会错位。
String? plainTextToStaticLrc(String plainText) {
  for (final raw in LineSplitter.split(plainText)) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (_lrcTagLinePattern.hasMatch(line)) continue;
    if (_metaLinePattern.hasMatch(line)) continue;
    return '[00:00.00]$line';
  }
  return null;
}
