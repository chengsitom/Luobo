import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/heart_playlist.dart';
import 'package:luobo/models/server_config.dart';
import 'package:luobo/models/song.dart';

void main() {
  group('HeartPlaylistBatch.fromJson', () {
    test('解析列表接口的真实字段', () {
      final batch = HeartPlaylistBatch.fromJson({
        'batchId': 'batch_349861bd3960f3bd',
        'generatedAt': '2026-10-27T09:00:18Z',
        'playlists': [
          {
            'id': 'batch_349861bd3960f3bd_b6589fc6ab0dc82c',
            'name': '流行、华语里的下班后的慢慢走 · 第89辑',
            'description': '想进入“驾车、放松”的状态……',
            'genres': ['流行', '华语'],
            'scenes': ['驾车', '放松'],
            'trackCount': 60,
            'totalDurationSeconds': 15400.82,
            'coverUrls': ['/api/cover?path=a', '/api/cover?path=b'],
          },
        ],
      });

      expect(batch.batchId, 'batch_349861bd3960f3bd');
      expect(batch.generatedAt, isNotNull);
      expect(batch.playlists, hasLength(1));

      final p = batch.playlists.first;
      expect(p.id, 'batch_349861bd3960f3bd_b6589fc6ab0dc82c');
      expect(p.name, '流行、华语里的下班后的慢慢走 · 第89辑');
      expect(p.genres, ['流行', '华语']);
      expect(p.scenes, ['驾车', '放松']);
      expect(p.trackCount, 60);
      expect(p.coverUrls, hasLength(2));
      expect(p.trackIds, isEmpty);
      expect(p.tracks, isEmpty);
      expect(p.issueLabel, '第 89 辑');
      expect(p.metaLabel, '60 首 · 4 小时 16 分');
    });

    test('空 / 坏数据不崩溃', () {
      final batch = HeartPlaylistBatch.fromJson({
        'playlists': [
          {'nonsense': true},
          null,
          'bad',
        ],
      });

      expect(batch.batchId, '');
      expect(batch.generatedAt, isNull);
      expect(batch.playlists, isEmpty);
    });
  });

  group('HeartPlaylist.fromDetailJson', () {
    test('曲目由调用方传入，trackIds 优先取接口字段', () {
      final songs = [
        Song(id: 'trk_1', title: '鲜花', artist: '回春丹'),
        Song(id: 'trk_2', title: 'Yellow', artist: 'Coldplay'),
      ];
      final detail = HeartPlaylist.fromDetailJson(
        {
          'id': 'batch_x_1',
          'name': '夜色慢慢降临 · 第89辑',
          'description': '夜晚、安静',
          'genres': ['情歌'],
          'scenes': ['夜晚'],
          'trackCount': 2,
          'totalDurationSeconds': 600,
          'coverUrls': const <String>[],
          'trackIds': ['trk_1', 'trk_2'],
          'tracks': [
            {'id': 'trk_1'},
            {'id': 'trk_2'},
          ],
        },
        tracks: songs,
      );

      expect(detail.trackIds, ['trk_1', 'trk_2']);
      expect(detail.tracks, hasLength(2));
      expect(detail.tracks.first.title, '鲜花');
      expect(detail.metaLabel, '2 首 · 10 分钟');
      expect(detail.issueLabel, '第 89 辑');
    });

    test('没有 trackIds 时从 tracks 推导', () {
      final detail = HeartPlaylist.fromDetailJson(
        {'id': 'x', 'name': 'n'},
        tracks: [Song(id: 'a', title: 'A')],
      );

      expect(detail.trackIds, ['a']);
      expect(detail.trackCount, 1);
      expect(detail.metaLabel, '1 首');
    });
  });

  group('isDaoliyuServer（飞牛不展示）', () {
    ServerConfig config(String family, {String? type}) => ServerConfig(
          serverUrl: 'https://example.com',
          username: 'u',
          password: 'p',
          serverFamily: family,
          serverType: type,
        );

    test('null / 未登录 → false', () {
      expect(isDaoliyuServer(null), isFalse);
    });

    test('显式 daoliyu → true', () {
      expect(isDaoliyuServer(config('daoliyu')), isTrue);
    });

    test('自动检测的 daoliyu（serverType 兜底）→ true', () {
      expect(
        isDaoliyuServer(config('auto', type: 'Daoliyu Music 2.0.0')),
        isTrue,
      );
      expect(
        isDaoliyuServer(config('subsonic', type: 'daoliyu')),
        isTrue,
      );
    });

    test('飞牛 / 普通 Subsonic / auto 非道理鱼 → false', () {
      expect(isDaoliyuServer(config('subsonic')), isFalse);
      expect(
        isDaoliyuServer(config('subsonic', type: 'Navidrome')),
        isFalse,
      );
      expect(isDaoliyuServer(config('auto', type: 'fnos')), isFalse);
    });
  });

  group('formatHeartDuration', () {
    test('小时 / 分钟 / 秒', () {
      expect(formatHeartDuration(15400.82), '4 小时 16 分');
      expect(formatHeartDuration(3600), '1 小时');
      expect(formatHeartDuration(90), '1 分钟');
      expect(formatHeartDuration(45), '45 秒');
      expect(formatHeartDuration(0), '');
    });
  });
}
