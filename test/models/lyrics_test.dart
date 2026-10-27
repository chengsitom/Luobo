import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/lyrics.dart';

/// 双语歌词归一化：同时间戳的「原文 + 译文」两行合并为一行，
/// 译文放进 `translation`，避免高亮永远落在译文行（2026-10-23）。
void main() {
  group('SyncedLyrics 双语合并', () {
    test('同时间戳两行合并：原文保留、译文进 translation', () {
      final lyrics = SyncedLyrics.fromLrc('''
[00:10.00]I keep thinking about you
[00:10.00]我一直想着你
[00:15.00]Another line
''');
      expect(lyrics.lines.length, 2);
      expect(lyrics.lines.first.text, 'I keep thinking about you');
      expect(lyrics.lines.first.translation, '我一直想着你');
      expect(lyrics.lines[1].translation, isNull);
    });

    test('时间戳相同也保持文件顺序（稳定排序）', () {
      final lyrics = SyncedLyrics.fromLrc('''
[00:20.00]B 行
[00:20.00]B 译文
[00:10.00]A 行
[00:10.00]A 译文
''');
      expect(lyrics.lines.map((l) => l.text).toList(), ['A 行', 'B 行']);
      expect(lyrics.lines.map((l) => l.translation).toList(), ['A 译文', 'B 译文']);
    });

    test('纯文本歌词（时间戳全为 0）不合并', () {
      final lyrics = SyncedLyrics.fromPlainText('第一行\n第二行\n第三行');
      expect(lyrics.lines.length, 3);
      expect(lyrics.lines.every((l) => l.translation == null), isTrue);
    });

    test('三行同时间戳：后两行都进译文', () {
      final lyrics = SyncedLyrics.fromLrc('''
[00:05.00]Original
[00:05.00]译文一
[00:05.00]译文二
''');
      expect(lyrics.lines.length, 1);
      expect(lyrics.lines.single.translation, '译文一\n译文二');
    });
  });
}
