import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/download_record.dart';
import 'package:luobo/models/song.dart';

void main() {
  group('downloadFileNameFor', () {
    test('uses the server suffix instead of hardcoded mp3', () {
      expect(downloadFileNameFor('trk_1', 'flac'), 'trk_1.flac');
      expect(downloadFileNameFor('trk_2', 'M4A'), 'trk_2.m4a');
      expect(downloadFileNameFor('trk_3', 'opus'), 'trk_3.opus');
    });

    test('falls back to mp3 for empty / hostile suffixes', () {
      expect(downloadFileNameFor('trk_1', null), 'trk_1.mp3');
      expect(downloadFileNameFor('trk_1', ''), 'trk_1.mp3');
      expect(downloadFileNameFor('trk_1', '../../evil'), 'trk_1.evil');
      expect(downloadFileNameFor('trk_1', 'a' * 20), 'trk_1.mp3');
    });

    test('sanitizes song id to avoid path traversal', () {
      expect(downloadFileNameFor('a/b:c', 'mp3'), 'a_b_c.mp3');
    });
  });

  group('DownloadRecord', () {
    test('round-trips through toMap / fromMap with full metadata', () {
      final song = Song(
        id: 'trk_1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        suffix: 'flac',
        size: 12345678,
      );
      final record = DownloadRecord(
        songId: 'trk_1',
        serverId: 'server_a',
        song: song,
        fileName: 'trk_1.flac',
        suffix: 'flac',
        bytes: 12345000,
        downloadedAt: DateTime(2026, 11, 17, 10, 30),
        source: DownloadSource.manual,
      );

      final restored = DownloadRecord.fromMap(record.toMap());

      expect(restored.songId, 'trk_1');
      expect(restored.serverId, 'server_a');
      expect(restored.fileName, 'trk_1.flac');
      expect(restored.bytes, 12345000);
      expect(restored.downloadedAt, DateTime(2026, 11, 17, 10, 30));
      expect(restored.source, DownloadSource.manual);
      expect(restored.status, DownloadStatus.complete);
      expect(restored.song.title, 'Test Song');
      expect(restored.song.artist, 'Test Artist');
      expect(restored.song.album, 'Test Album');
    });

    test('migrated legacy record falls back title to id', () {
      // 老白名单迁移时 songJson 只有 id，没有 title。
      final restored = DownloadRecord.fromMap({
        'songId': 'trk_legacy',
        'serverId': '',
        'songJson': '{"id":"trk_legacy"}',
        'fileName': 'trk_legacy.mp3',
        'suffix': 'mp3',
        'bytes': 999,
        'downloadedAt': 0,
      });

      expect(restored.song.id, 'trk_legacy');
      expect(restored.song.title, 'trk_legacy');
      expect(restored.serverId, '');
      expect(restored.status, DownloadStatus.complete);
    });

    test('handles corrupt songJson without throwing', () {
      final restored = DownloadRecord.fromMap({
        'songId': 'trk_bad',
        'songJson': 'not json',
        'fileName': 'trk_bad.mp3',
        'bytes': 0,
        'downloadedAt': 0,
      });

      expect(restored.song.id, 'trk_bad');
      expect(restored.song.title, 'trk_bad');
    });

    test('legacy records (empty serverId) are visible on every server', () {
      final legacy = DownloadRecord(
        songId: 'trk_1',
        serverId: '',
        song: Song(id: 'trk_1', title: 'x'),
        fileName: 'trk_1.mp3',
        suffix: 'mp3',
        bytes: 1,
        downloadedAt: DateTime.now(),
      );
      expect(recordBelongsToServer(legacy, 'serverA'), isTrue);
      expect(recordBelongsToServer(legacy, 'serverB'), isTrue);
      expect(recordBelongsToServer(legacy, ''), isTrue);
    });

    test('records are isolated by serverId to avoid cross-server songId clash',
        () {
      final onA = DownloadRecord(
        songId: '123', // 两服可能用相同的数字 id
        serverId: 'serverA',
        song: Song(id: '123', title: 'A version'),
        fileName: '123.mp3',
        suffix: 'mp3',
        bytes: 1,
        downloadedAt: DateTime.now(),
      );
      expect(recordBelongsToServer(onA, 'serverA'), isTrue);
      expect(recordBelongsToServer(onA, 'serverB'), isFalse);
      expect(recordBelongsToServer(onA, ''), isFalse);
    });

    test('preserves source and status enums', () {
      final record = DownloadRecord(
        songId: 'trk_1',
        serverId: 's',
        song: Song(id: 'trk_1', title: 'x'),
        fileName: 'trk_1.mp3',
        suffix: 'mp3',
        bytes: 1,
        downloadedAt: DateTime.now(),
        source: DownloadSource.auto,
        status: DownloadStatus.failed,
      );
      final restored = DownloadRecord.fromMap(record.toMap());
      expect(restored.source, DownloadSource.auto);
      expect(restored.status, DownloadStatus.failed);
    });
  });
}
