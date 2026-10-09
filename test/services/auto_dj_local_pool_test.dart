import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/services/auto_dj_service.dart';
import 'package:luobo/services/subsonic_service.dart';

List<Song> _pool(int n) =>
    List.generate(n, (i) => Song(id: 'song-$i', title: 'Song $i'));

void main() {
  group('AutoDjService 本地池（漫游续播）', () {
    late AutoDjService service;

    setUp(() async {
      service = AutoDjService();
      await service.setMode(AutoDjMode.shuffleLibrary);
      await service.setSongsToAdd(5);
      service.setServices(SubsonicService(), null);
      service.setLocalPool(null);
    });

    tearDown(() async {
      service.setLocalPool(null);
      await service.setMode(AutoDjMode.off);
    });

    test('注入池子后，续播取歌全部来自池子且单批不重复', () async {
      service.setLocalPool(_pool(200));
      expect(service.hasLocalPool, isTrue);

      final picked = await service.getSongsToQueue(
        currentSong: null,
        currentQueue: const [],
      );

      expect(picked.length, 5);
      expect(picked.map((s) => s.id).toSet().length, 5, reason: '单批内不应重复');
      for (final song in picked) {
        expect(song.id, startsWith('song-'), reason: '应来自本地池而非服务端随机');
      }
    });

    test('多轮取歌会覆盖池中不同歌曲（不是反复抽同几首）', () async {
      service.setLocalPool(_pool(200));
      final seen = <String>{};
      for (var i = 0; i < 6; i++) {
        final batch = await service.getSongsToQueue(
          currentSong: null,
          currentQueue: const [],
        );
        expect(batch, isNotEmpty);
        seen.addAll(batch.map((s) => s.id));
      }
      // 6 批 × 5 首 = 30 首；若每批都重抽同一小撮，seen 会远小于 20。
      expect(seen.length, greaterThan(20));
    });

    test('池子比一批还小时不会取空，走到末尾会重洗续上', () async {
      service.setLocalPool(_pool(8));
      for (var i = 0; i < 5; i++) {
        final batch = await service.getSongsToQueue(
          currentSong: null,
          currentQueue: const [],
        );
        expect(batch, isNotEmpty, reason: '第 ${i + 1} 轮不应取空');
      }
    });

    test('已在队列里的歌不会被重复补进来', () async {
      final pool = _pool(50);
      service.setLocalPool(pool);
      final first = await service.getSongsToQueue(
        currentSong: null,
        currentQueue: const [],
      );
      final second = await service.getSongsToQueue(
        currentSong: null,
        currentQueue: first,
      );
      final overlap = second.map((s) => s.id).toSet()
        ..retainAll(first.map((s) => s.id).toSet());
      expect(overlap, isEmpty);
    });

    test('传 null / 空列表即退出漫游（回到无池状态）', () {
      service.setLocalPool(_pool(50));
      expect(service.hasLocalPool, isTrue);

      service.setLocalPool(null);
      expect(service.hasLocalPool, isFalse);

      service.setLocalPool(_pool(50));
      service.setLocalPool(const []);
      expect(service.hasLocalPool, isFalse);
    });
  });
}
