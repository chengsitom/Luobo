import 'package:flutter_test/flutter_test.dart';

import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/services/services.dart';

import '../bootstrap.dart';

/// 离线模式的「刷新」语义 + 重连入口的安全边界。
void main() {
  initializeTestEnvironment();

  /// 离线刷新：
  /// 1. 只重读本地缓存，不得伪装成一次成功的服务端同步（`isLocal` 也不能为真，
  ///    离线态的数据来自服务端缓存，不是本地文件）；
  /// 2. 绝不能再回到「成功 + 0 张专辑 0 首歌曲」——那串数字会被首页原样弹成
  ///    「刷新完成：0 张专辑，0 首歌曲」，用户以为本地空了（真机反馈）。
  ///
  /// 只覆盖离线分支：在线分支会真的去打服务器 + 开 DB，在单测环境里既慢又
  /// 偶发超时（全量跑时曾出现），价值不如稳定性。
  test('离线刷新标记为 offline，不计入服务端同步', () async {
    final provider = LibraryProvider(SubsonicService());
    provider.setServerOfflineMode(true);

    final result = await provider.refresh();

    expect(result.success, isTrue);
    expect(result.isOffline, isTrue);
    expect(result.isLocal, isFalse);
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

    expect(await auth.reconnect(), isFalse);
    expect(auth.state, AuthState.offlineMode);
    expect(auth.isLocalOnlyMode, isTrue);
  });
}
