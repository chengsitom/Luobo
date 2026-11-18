import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luobo/models/album.dart';
import 'package:luobo/models/playlist.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/services/blocklist_service.dart';
import 'package:luobo/services/subsonic_service.dart';

import '../bootstrap.dart';

/// 曲库读取层的过滤（方案 R2：列表口径 vs 随机口径必须分开）。
void main() {
  initializeTestEnvironment();

  final blocklist = BlocklistService.instance;
  late LibraryProvider library;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await blocklist.resetForTest();
    await blocklist.attachScope('scope-under-test');

    library = LibraryProvider(SubsonicService())
      ..debugSeedPools(
        songs: [
          Song(id: 's1', title: 'A1', artistId: 'a1', artist: 'Artist 1'),
          Song(id: 's2', title: 'A1 #2', artistId: 'a1', artist: 'Artist 1'),
          Song(id: 's3', title: 'B', artistId: 'a2', artist: 'Artist 2'),
        ],
        albums: [
          Album(id: 'al1', name: 'Album 1', artistId: 'a1', artist: 'Artist 1'),
          Album(id: 'al2', name: 'Album 2', artistId: 'a2', artist: 'Artist 2'),
        ],
        playlists: [
          Playlist(id: 'p1', name: '儿歌', songCount: 1),
          Playlist(id: 'p2', name: '我的', songCount: 3),
        ],
      );
  });

  tearDown(() => library.dispose());

  test('彻底屏蔽艺人：列表与漫游都不再包含其歌曲', () async {
    expect(library.cachedAllSongs.length, 3);
    expect(library.roamPool.length, 3);

    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);

    expect(library.cachedAllSongs.map((s) => s.id), ['s3']);
    expect(library.roamPool.map((s) => s.id), ['s3']);
    // 该艺人的专辑也从列表消失
    expect(library.cachedAllAlbums.map((a) => a.id), ['al2']);
  });

  test('仅从漫游排除：列表照常显示，只是不进随机池', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.muted);

    // R2.3：用户主动浏览/点播仍然可以
    expect(library.cachedAllSongs.length, 3);
    expect(library.cachedAllAlbums.length, 2);
    // R2.2：但漫游抽不到
    expect(library.roamPool.map((s) => s.id), ['s3']);
  });

  test('歌单排除：成员进不了漫游，但仍在列表里', () async {
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s3'],
      songCount: 1,
    );

    expect(library.cachedAllSongs.map((s) => s.id), contains('s3'));
    expect(library.roamPool.map((s) => s.id), ['s1', 's2']);
  });

  test('隐藏歌单：歌单列表里看不到它，但成员歌曲照常可浏览', () async {
    expect(library.playlists.map((p) => p.id), ['p1', 'p2']);

    await blocklist.blockPlaylist('p1', '儿歌', mode: BlockMode.hidden);

    // 歌单条目消失
    expect(library.playlists.map((p) => p.id), ['p2']);
    // 歌曲不受歌单屏蔽影响（歌属于各自的艺人/专辑，不该在别处凭空少歌）
    expect(library.cachedAllSongs.length, 3);
  });

  test('解除屏蔽后读取层立即恢复（不需要重新同步）', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    expect(library.cachedAllSongs.length, 1);

    await blocklist.unblock(BlockKind.artist, 'a1');
    expect(library.cachedAllSongs.length, 3);
    expect(library.roamPool.length, 3);
  });

  test('列表过滤有 memo：不变时复用同一个 List 实例，变更后重算', () async {
    // 先放一条规则让过滤生效（空名单时直接返回原始列表，测不到 memo）
    await blocklist.blockArtist('a2', 'Artist 2', mode: BlockMode.muted);

    final first = library.cachedAllSongs;
    final second = library.cachedAllSongs;
    expect(identical(first, second), isTrue, reason: '同一 revision 应命中缓存');

    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    final third = library.cachedAllSongs;
    expect(identical(first, third), isFalse, reason: '名单变了必须重算');
    expect(third.map((s) => s.id), ['s3']);
  });

  test('切档后列表与漫游池各自重算', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    expect(library.cachedAllSongs.length, 1);
    expect(library.roamPool.length, 1);

    await blocklist.setMode(BlockKind.artist, 'a1', BlockMode.muted);
    // muted 仍可见，但漫游依旧排除
    expect(library.cachedAllSongs.length, 3);
    expect(library.roamPool.map((s) => s.id), ['s3']);
  });

  test('删歌单会连带清掉它的屏蔽规则（否则成员被永久排除）', () async {
    final fake = _FakeSubsonic();
    final provider = LibraryProvider(fake)
      ..debugSeedPools(
        songs: [
          Song(id: 's1', title: 'A', artistId: 'a1', artist: 'Artist 1'),
          Song(id: 's9', title: '儿歌', artistId: 'a9', artist: 'Kid'),
        ],
      );
    addTearDown(provider.dispose);

    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s9'],
      songCount: 1,
    );
    expect(
        blocklist.isSongExcluded(
          Song(id: 's9', title: '儿歌'),
        ),
        isTrue);

    await provider.deletePlaylist('p1');

    expect(blocklist.entryFor(BlockKind.playlist, 'p1'), isNull);
    expect(blocklist.isSongExcluded(Song(id: 's9', title: '儿歌')), isFalse);
  });

  test('删除失败时保留规则（不能把用户的设置弄丢）', () async {
    final provider = LibraryProvider(_FakeSubsonic(failDelete: true));
    addTearDown(provider.dispose);

    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s9'],
      songCount: 1,
    );

    await expectLater(provider.deletePlaylist('p1'), throwsA(anything));
    expect(blocklist.entryFor(BlockKind.playlist, 'p1'), isNotNull);
  });

  test('隐藏歌单不影响成员歌曲的可见性', () async {
    await blocklist.blockPlaylist('p1', '儿歌', mode: BlockMode.hidden);
    // 歌单条目消失，但它里面的歌属于各自的艺人/专辑 —— 不该在别处凭空少歌
    expect(library.playlists.map((p) => p.id), ['p2']);
    expect(library.cachedAllSongs.length, 3);
  });
}

/// 只替换需要的方法，其余走真实实现（真实实现会因"未配置服务器"直接抛错，
/// 正好用来证明「删除失败时不该清规则」）。
class _FakeSubsonic extends SubsonicService {
  _FakeSubsonic({this.failDelete = false});

  final bool failDelete;

  @override
  Future<void> deletePlaylist(String id) async {
    if (failDelete) throw Exception('boom');
  }
}
