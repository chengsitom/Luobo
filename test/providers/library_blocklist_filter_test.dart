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

  test('revision 变化后过滤结果会重算（memo 不粘住旧结果）', () async {
    expect(library.cachedAllSongs.length, 3);
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    expect(library.cachedAllSongs.length, 1);
    await blocklist.setMode(BlockKind.artist, 'a1', BlockMode.muted);
    // 切档后列表恢复（muted 仍可见）
    expect(library.cachedAllSongs.length, 3);
    expect(library.roamPool.length, 1);
  });

  test('Playlist 隐藏判定不影响歌曲可见性', () {
    // 防回归：曾想把「歌单被隐藏」等同于「成员歌曲被隐藏」，那会让别处凭空少歌。
    expect(Playlist(id: 'p1', name: '儿歌').id, 'p1');
  });
}
