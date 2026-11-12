import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/car_lyrics_metadata.dart';

void main() {
  group('carTrackLabel', () {
    test('歌名 + 艺人 → 「歌名 - 艺人」', () {
      expect(
        carTrackLabel(songTitle: '富士山下', artist: '陈奕迅'),
        '富士山下 - 陈奕迅',
      );
    });

    test('艺人缺失/空白 → 只留歌名', () {
      expect(carTrackLabel(songTitle: '富士山下'), '富士山下');
      expect(carTrackLabel(songTitle: '富士山下', artist: '   '), '富士山下');
    });

    test('两端空白会被去掉（服务端元数据经常带尾部空格）', () {
      expect(
        carTrackLabel(songTitle: ' 富士山下 ', artist: ' 陈奕迅 '),
        '富士山下 - 陈奕迅',
      );
    });
  });

  group('buildCarLyricMetadata', () {
    test('有歌词行 → 标题=歌词，艺人/专辑=歌名-艺人', () {
      final meta = buildCarLyricMetadata(
        line: '谁能凭爱意要富士山私有',
        songTitle: '富士山下',
        artist: '陈奕迅',
      );
      expect(meta, isNotNull);
      expect(meta!.title, '谁能凭爱意要富士山私有');
      expect(meta.artist, '富士山下 - 陈奕迅');
      expect(meta.album, '富士山下 - 陈奕迅');
    });

    test('无歌词行（null / 空 / 全空白）→ null，由调用方回落成歌名', () {
      for (final line in [null, '', '   ']) {
        expect(
          buildCarLyricMetadata(
            line: line,
            songTitle: '富士山下',
            artist: '陈奕迅',
          ),
          isNull,
          reason: 'line=$line',
        );
      }
    });

    test('歌词行两端空白会被去掉（LRC 里常见尾随空格）', () {
      final meta = buildCarLyricMetadata(
        line: '  谁能凭爱意要富士山私有  ',
        songTitle: '富士山下',
      );
      expect(meta!.title, '谁能凭爱意要富士山私有');
    });

    test('「Unknown Artist」占位视为缺失，不带到车机上', () {
      final meta = buildCarLyricMetadata(
        line: '第一句',
        songTitle: '富士山下',
        artist: 'Unknown Artist',
      );
      expect(meta!.artist, '富士山下');
    });
  });
}
