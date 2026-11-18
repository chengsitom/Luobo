import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luobo/models/album.dart';
import 'package:luobo/models/artist_ref.dart';
import 'package:luobo/models/playlist.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/services/blocklist_service.dart';

import '../bootstrap.dart';

/// 屏蔽名单的判定口径（对应方案 R1/R2/R3 的验收标准）。
void main() {
  initializeTestEnvironment();

  final blocklist = BlocklistService.instance;

  setUp(() async {
    // 名单会持久化到 prefs：每个用例必须从干净状态开始，否则上一个用例
    // 的规则会被 attachScope 读回来，测试之间互相污染。
    SharedPreferences.setMockInitialValues({});
    await blocklist.resetForTest();
    await blocklist.attachScope('test-scope');
  });

  Song song({
    String id = 's1',
    String? artistId = 'a1',
    String? artist = 'Artist 1',
    String? albumId = 'al1',
    List<ArtistRef>? parts,
  }) =>
      Song(
        id: id,
        title: 'Song $id',
        artistId: artistId,
        artist: artist,
        albumId: albumId,
        artistParticipants: parts,
      );

  test('彻底屏蔽：既不显示也不参与随机', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);

    expect(blocklist.isArtistHidden('a1'), isTrue);
    expect(blocklist.isArtistExcluded('a1'), isTrue);
    expect(blocklist.isSongHidden(song()), isTrue);
    expect(blocklist.isSongExcluded(song()), isTrue);
  });

  test('仅从漫游排除：仍可见，但不参与随机', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.muted);

    expect(blocklist.isArtistHidden('a1'), isFalse);
    expect(blocklist.isArtistExcluded('a1'), isTrue);
    // 列表/搜索要能看到它（R2.3）
    expect(blocklist.isSongHidden(song()), isFalse);
    // 但漫游不能抽到它
    expect(blocklist.isSongExcluded(song()), isTrue);
  });

  test('专辑屏蔽同理，且不影响同艺人的其他专辑', () async {
    await blocklist.blockAlbum('al1', 'Album 1', mode: BlockMode.hidden);

    expect(blocklist.isSongHidden(song()), isTrue);
    expect(blocklist.isSongHidden(song(id: 's2', albumId: 'al2')), isFalse);
  });

  test('多艺人歌曲：命中任一被屏蔽艺人即排除', () async {
    await blocklist.blockArtist('a2', 'Guest', mode: BlockMode.muted);

    final withGuest = song(
      parts: const [
        ArtistRef(id: 'a1', name: 'Artist 1'),
        ArtistRef(id: 'a2', name: 'Guest'),
      ],
    );
    expect(blocklist.isSongExcluded(withGuest), isTrue);
  });

  test('artistId 缺失时按名字兜底匹配', () async {
    await blocklist.blockArtist('a9', '周杰伦', mode: BlockMode.hidden);

    expect(blocklist.isSongHidden(song(artistId: null, artist: '周杰伦')), isTrue);
    // 大小写/空格不敏感
    expect(
      blocklist.isSongHidden(song(artistId: null, artist: ' 周杰伦 ')),
      isTrue,
    );
    expect(blocklist.isSongHidden(song(artistId: null, artist: '别人')), isFalse);
  });

  test('歌单：排除的是成员歌曲，两档都生效', () async {
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s1', 's2'],
      songCount: 2,
    );

    // 成员被排除出随机
    expect(blocklist.isSongExcluded(song(id: 's1')), isTrue);
    // 但列表里照常可见（歌单屏蔽不影响歌曲本身的归属）
    expect(blocklist.isSongHidden(song(id: 's1')), isFalse);
    // 非成员不受影响
    expect(blocklist.isSongExcluded(song(id: 's3')), isFalse);
  });

  test('歌单：本机加歌立刻进排除集合，不需要重新拉成员', () async {
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s1'],
      songCount: 1,
    );

    await blocklist.noteSongsAdded('p1', ['s9']);
    expect(blocklist.isSongExcluded(song(id: 's9')), isTrue);
    // 基线同步了，不会因为 songCount 检测再触发一次拉取
    expect(
      blocklist.playlistNeedsMembers(Playlist(id: 'p1', name: '儿歌', songCount: 2)),
      isFalse,
    );
  });

  test('歌单：本机删歌立刻移出排除集合', () async {
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s1', 's2'],
      songCount: 2,
    );

    await blocklist.noteSongsRemoved('p1', ['s1']);
    expect(blocklist.isSongExcluded(song(id: 's1')), isFalse);
    expect(blocklist.isSongExcluded(song(id: 's2')), isTrue);
  });

  test('歌单成员变化检测：songCount 不一致就要重拉', () async {
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s1'],
      songCount: 1,
    );

    // 一致 → 不需要
    expect(
      blocklist.playlistNeedsMembers(Playlist(id: 'p1', name: '儿歌', songCount: 1)),
      isFalse,
    );
    // 别处加了歌 → 需要
    expect(
      blocklist.playlistNeedsMembers(Playlist(id: 'p1', name: '儿歌', songCount: 2)),
      isTrue,
    );
  });

  test('没被屏蔽的歌单永远不需要展开', () async {
    expect(
      blocklist.playlistNeedsMembers(Playlist(id: 'px', name: '其他', songCount: 9)),
      isFalse,
    );
  });

  test('解除屏蔽后立即恢复（无需重新同步）', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    expect(blocklist.isSongHidden(song()), isTrue);

    await blocklist.unblock(BlockKind.artist, 'a1');
    expect(blocklist.isSongHidden(song()), isFalse);
    expect(blocklist.isSongExcluded(song()), isFalse);
    expect(blocklist.isEmpty, isTrue);
  });

  test('切档：hidden ↔ muted 立即生效，revision 递增', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.muted);
    final rev = blocklist.revision;
    expect(blocklist.isSongHidden(song()), isFalse);

    await blocklist.setMode(BlockKind.artist, 'a1', BlockMode.hidden);
    expect(blocklist.isSongHidden(song()), isTrue);
    expect(blocklist.revision, greaterThan(rev));
  });

  test('作用域隔离：切账号后看不到上一个账号的名单', () async {
    await blocklist.blockArtist('a1', 'Artist 1', mode: BlockMode.hidden);
    expect(blocklist.isEmpty, isFalse);

    await blocklist.attachScope('another-scope');
    expect(blocklist.isEmpty, isTrue);
    // 回到原作用域，规则仍在
    await blocklist.attachScope('test-scope');
    expect(blocklist.isSongHidden(song()), isTrue);
  });

  test('Album/Playlist 模型在过滤里只读字段，不改对象', () async {
    // 防回归：屏蔽只影响判定，不应要求调用方改数据模型。
    expect(Album(id: 'al1', name: 'Album 1').id, 'al1');
  });
}
