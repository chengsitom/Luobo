import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:luobo/models/models.dart';
import 'package:luobo/services/services.dart';
import 'package:luobo/providers/library_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RecommendationService.topArtistsView', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('无播放历史时返回空列表', () async {
      final service = RecommendationService();
      await service.initialize();
      expect(service.topArtistsView(5), isEmpty);
    });

    test('按播放加权亲和度降序取前 N（键为歌手名字）', () async {
      final service = RecommendationService();
      await service.initialize();
      // 周杰伦 3 次 > 林俊杰 2 次 > 王菲 1 次
      for (var i = 0; i < 3; i++) {
        await service.trackSongPlay(
          Song(id: 'jay_$i', title: 'Jay $i', artist: '周杰伦', artistId: 'zjl'),
        );
      }
      for (var i = 0; i < 2; i++) {
        await service.trackSongPlay(
          Song(id: 'jj_$i', title: 'JJ $i', artist: '林俊杰', artistId: 'ljj'),
        );
      }
      await service.trackSongPlay(
        Song(id: 'faye_0', title: 'Faye', artist: '王菲', artistId: 'wf'),
      );

      expect(service.topArtistsView(2), ['周杰伦', '林俊杰']);
    });

    test('limit 生效：播放 3 位歌手取 1 只返回首位', () async {
      final service = RecommendationService();
      await service.initialize();
      await service.trackSongPlay(
        Song(id: 'a', title: 'A', artist: 'Adele', artistId: 'ad'),
      );
      await service.trackSongPlay(
        Song(id: 'b', title: 'B', artist: 'Beyoncé', artistId: 'be'),
      );
      expect(service.topArtistsView(1), ['Adele']);
    });
  });

  group('artistAlbumCoverArt 拼贴收集', () {
    test('按 artistId 收集 ≤4 张专辑封面', () {
      final albums = [
        Album(
            id: '1', name: 'a1', artistId: 'x', artist: 'Jay', coverArt: 'c1'),
        Album(
            id: '2', name: 'a2', artistId: 'x', artist: 'Jay', coverArt: 'c2'),
        Album(
            id: '3', name: 'a3', artistId: 'x', artist: 'Jay', coverArt: 'c3'),
        Album(
            id: '4', name: 'a4', artistId: 'x', artist: 'Jay', coverArt: 'c4'),
        Album(
            id: '5', name: 'a5', artistId: 'x', artist: 'Jay', coverArt: 'c5'),
      ];
      final covers = artistAlbumCoverArt(albums, Artist(id: 'x', name: 'Jay'));
      // 只取前 4，跳过第 5 张
      expect(covers, ['c1', 'c2', 'c3', 'c4']);
    });

    test('artistId 不匹配时按名字兜底匹配', () {
      final albums = [
        // 服务端省略 artistId 的场景
        Album(id: '1', name: 'a1', artist: 'Jay', coverArt: 'c1'),
        Album(id: '2', name: 'a2', artist: 'Jay', coverArt: 'c2'),
        Album(id: '3', name: 'a3', artist: 'Other', coverArt: 'c9'),
      ];
      final covers = artistAlbumCoverArt(albums, Artist(id: 'x', name: 'Jay'));
      expect(covers, ['c1', 'c2']);
    });

    test('无任何封面时返回空列表（→ 渐变首字母占位）', () {
      final albums = [
        Album(id: '1', name: 'a1', artistId: 'x'),
        Album(id: '2', name: 'a2', artistId: 'x', coverArt: ''),
      ];
      expect(
          artistAlbumCoverArt(albums, Artist(id: 'x', name: 'Jay')), isEmpty);
    });

    test('少于 4 张时返回全部', () {
      final albums = [
        Album(id: '1', name: 'a1', artistId: 'x', coverArt: 'c1'),
      ];
      expect(artistAlbumCoverArt(albums, Artist(id: 'x', name: 'Jay')), ['c1']);
    });
  });

  group('LibraryProvider.resolveArtistCover', () {
    test('artistImageUrl 直链优先（第 1 级）', () {
      final provider = LibraryProvider(SubsonicService());
      final artist = Artist(
        id: 'x',
        name: 'Jay',
        artistImageUrl: 'https://cdn.example.com/artist/large.jpg',
      );
      final cover = provider.resolveArtistCover(artist);
      expect(cover.hasImage, isTrue);
      expect(cover.imageUrl, 'https://cdn.example.com/artist/large.jpg');
      expect(cover.collageCovers, isEmpty);
    });

    test('空库无任何图源时退化为渐变占位（第 5 级，名字保留）', () {
      final provider = LibraryProvider(SubsonicService());
      final artist = Artist(id: 'x', name: '周杰伦');
      final cover = provider.resolveArtistCover(artist);
      expect(cover.hasImage, isFalse);
      expect(cover.hasCollage, isFalse);
      expect(cover.name, '周杰伦');
    });
  });
}
