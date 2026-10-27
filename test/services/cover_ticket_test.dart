import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/subsonic_service.dart';

/// 道理鱼封面票据 / 艺人封面路径的解析单测。
/// 真实结构见 `~/Downloads/道理鱼接口/道理鱼_接口素材/captures/api_cover_ticket.txt`。
void main() {
  group('parseAlbumCoverTicket', () {
    final now = DateTime.utc(2026, 8, 7, 6, 56, 20);

    test('真实响应：ticket + url + expiresAt/expiresInSeconds', () {
      final parsed = SubsonicService.parseAlbumCoverTicket(
        {
          'expiresAt': '2026-08-07T06:58:20Z',
          'expiresInSeconds': 120,
          'ticket': 'tk',
          'url': '/api/cover?albumId=alb_1&ticket=tk',
        },
        now,
      );
      expect(parsed, isNotNull);
      expect(parsed!.ticket, 'tk');
      expect(parsed.url, '/api/cover?albumId=alb_1&ticket=tk');
      expect(parsed.expiresAt, DateTime.utc(2026, 8, 7, 6, 58, 20));
    });

    test('只有 expiresInSeconds 时按剩余秒算', () {
      final parsed = SubsonicService.parseAlbumCoverTicket(
        {'ticket': 'tk', 'url': '/api/cover?albumId=a&ticket=tk', 'expiresInSeconds': 90},
        now,
      );
      expect(parsed!.expiresAt.difference(now).inSeconds, 90);
    });

    test('过期时间已过 → 给 30 秒缓冲', () {
      final parsed = SubsonicService.parseAlbumCoverTicket(
        {
          'ticket': 'tk',
          'url': '/api/cover?albumId=a&ticket=tk',
          'expiresAt': '2026-08-07T06:50:00Z',
        },
        now,
      );
      expect(parsed!.expiresAt.difference(now).inSeconds, 30);
    });

    test('缺 ticket / url → null', () {
      expect(SubsonicService.parseAlbumCoverTicket(null, now), isNull);
      expect(SubsonicService.parseAlbumCoverTicket({}, now), isNull);
      expect(
        SubsonicService.parseAlbumCoverTicket({'ticket': 'tk'}, now),
        isNull,
      );
      expect(
        SubsonicService.parseAlbumCoverTicket(
          {'ticket': '', 'url': '/api/cover'},
          now,
        ),
        isNull,
      );
    });
  });

  group('parseArtistCoverPaths', () {
    test('优先 coverArtPath', () {
      final map = SubsonicService.parseArtistCoverPaths({
        'items': [
          {
            'id': 'art_1',
            'name': 'A',
            'coverArtPath': 'system/covers/a.jpg',
            'coverArtUrl': '/api/cover?path=system%2Fcovers%2Fa.jpg',
          },
        ],
      });
      expect(map['art_1'], 'system/covers/a.jpg');
    });

    test('无 coverArtPath 时从 coverArtUrl 解出 path', () {
      final map = SubsonicService.parseArtistCoverPaths({
        'items': [
          {
            'id': 'art_2',
            'coverArt': '/api/cover?path=system%2Fcovers%2Fb.jpg',
          },
        ],
      });
      expect(map['art_2'], 'system/covers/b.jpg');
    });

    test('无封面 / 无 id 的条目跳过', () {
      final map = SubsonicService.parseArtistCoverPaths({
        'items': [
          {'id': 'art_3', 'name': 'NoCover'},
          {'name': 'NoId', 'coverArtPath': 'x.jpg'},
          'garbage',
        ],
      });
      expect(map, isEmpty);
    });

    test('非列表响应 / null → 空 Map', () {
      expect(SubsonicService.parseArtistCoverPaths(null), isEmpty);
      expect(SubsonicService.parseArtistCoverPaths({}), isEmpty);
      expect(
        SubsonicService.parseArtistCoverPaths({'items': 'x'}),
        isEmpty,
      );
    });
  });
}
