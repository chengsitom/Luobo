import 'package:flutter_test/flutter_test.dart';

import 'package:luobo/models/album.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/services/services.dart';

import '../bootstrap.dart';

/// 离线模式的「刷新」语义 + 重连入口的安全边界。
void main() {
  initializeTestEnvironment();

  List<Song> songs(int n) => [
        for (var i = 0; i < n; i++) Song(id: 's$i', title: 'Song $i'),
      ];
  List<Album> albums(int n) => [
        for (var i = 0; i < n; i++) Album(id: 'a$i', name: 'Album $i'),
      ];

  /// 离线刷新：
  /// 1. 只重读本地缓存，不得伪装成一次成功的服务端同步（`isLocal` 也不能为真，
  ///    离线态的数据来自服务端缓存，不是本地文件）；
  /// 2. **必须报真实条数**——此前返回 `RefreshResult(success: true)` 让计数落到
  ///    默认 0，首页原样弹「刷新完成：0 张专辑，0 首歌曲」，用户以为本地空了。
  ///
  /// 只覆盖离线分支：在线分支会真的去打服务器 + 开 DB，在单测环境里既慢又
  /// 偶发超时（全量跑时曾出现），价值不如稳定性。
  test('离线刷新报真实条数，不计入服务端同步', () async {
    final provider = LibraryProvider(SubsonicService())
      ..setServerOfflineMode(true)
      ..debugSeedPools(songs: songs(3), albums: albums(2));

    final result = await provider.refresh();

    expect(result.success, isTrue);
    expect(result.isOffline, isTrue);
    expect(result.isLocal, isFalse);
    expect(result.songCount, 3);
    expect(result.albumCount, 2);
  });

  /// 全量缓存为空时，首页用的是 random/recent 兜底池 —— 计数也要跟首页
  /// 同口径，否则又会出现「有内容却说 0 首」。
  test('全量缓存为空时回退到 random/recent 池计数', () async {
    final provider = LibraryProvider(SubsonicService())
      ..setServerOfflineMode(true)
      ..debugSeedPools(
          songs: songs(0), albums: albums(0), randomSongs: songs(7));

    final result = await provider.refresh();

    expect(result.success, isTrue);
    expect(result.songCount, 7);
  });

  /// 本地文件模式复用 `AuthState.offlineMode`，但它没有服务器可连：
  /// `reconnect()` 必须立刻返回 false 且不改状态 —— 否则「刷新本地曲库」
  /// 会变成一次注定失败、最长 30s 的服务器重连。
  test('本地文件模式不触发服务器重连', () async {
    final auth = AuthProvider(SubsonicService(), StorageService());
    // 等构造里的 _loadSavedConfig 落定（mock prefs，无网络）。
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    await auth.setLocalOnlyMode(true);
    expect(auth.isLocalOnlyMode, isTrue);
    expect(auth.state, AuthState.offlineMode);
    // 本地文件模式对外也是"只能听本地"的会话。
    expect(auth.isLocalPlaybackSession, isTrue);

    expect(await auth.reconnect(), isFalse);
    expect(auth.state, AuthState.offlineMode);
    expect(auth.isLocalOnlyMode, isTrue);
  });
}
