import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/models/playlist.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/screens/blocklist_screen.dart';
import 'package:luobo/services/blocklist_service.dart';
import 'package:luobo/services/subsonic_service.dart';

import '../bootstrap.dart';

/// 设置 → 内容过滤：`hidden` 之后**唯一**的恢复入口，所以它必须能用。
void main() {
  initializeTestEnvironment();

  final blocklist = BlocklistService.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await blocklist.resetForTest();
    await blocklist.attachScope('ui-scope');
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    List<Playlist> playlists = const [],
  }) async {
    final library = LibraryProvider(SubsonicService())
      ..debugSeedPools(playlists: playlists);
    addTearDown(library.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<LibraryProvider>.value(
        value: library,
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BlocklistScreen(),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('空态文案', (tester) async {
    await pumpPage(tester);
    expect(find.text('还没有屏蔽任何内容'), findsOneWidget);
  });

  testWidgets('按类型分组列出，并标出当前强度', (tester) async {
    await blocklist.blockArtist('a1', '周杰伦', mode: BlockMode.hidden);
    await blocklist.blockAlbum('al1', '范特西', mode: BlockMode.muted);
    await blocklist.blockPlaylist(
      'p1',
      '儿歌',
      mode: BlockMode.muted,
      members: ['s1', 's2'],
      songCount: 2,
    );

    await pumpPage(tester);

    expect(find.text('周杰伦'), findsOneWidget);
    expect(find.text('范特西'), findsOneWidget);
    expect(find.text('儿歌'), findsOneWidget);
    // 两档强度的标签都要能区分出来
    expect(find.text('彻底屏蔽'), findsOneWidget);
    // 歌单额外标出"排除了多少首"
    expect(find.textContaining('仅从漫游排除'), findsWidgets);
    expect(find.textContaining('2 首'), findsOneWidget);
  });

  testWidgets('规则指向的歌单已不存在时会标出来', (tester) async {
    await blocklist.blockPlaylist(
      'gone',
      '旧歌单',
      mode: BlockMode.muted,
      members: ['s1'],
      songCount: 1,
    );
    // 现有歌单里没有 'gone'
    await pumpPage(
      tester,
      playlists: [Playlist(id: 'p1', name: '儿歌', songCount: 2)],
    );

    expect(find.textContaining('歌单已不存在'), findsOneWidget);
  });

  testWidgets('点条目弹出选择，可解除屏蔽', (tester) async {
    await blocklist.blockArtist('a1', '周杰伦', mode: BlockMode.hidden);
    await pumpPage(tester);

    await tester.tap(find.text('周杰伦'));
    await tester.pumpAndSettle();

    // 弹窗里两档 + 解除三个选项都在
    expect(find.text('彻底屏蔽'), findsWidgets);
    expect(find.text('仅从漫游排除'), findsWidgets);
    expect(find.text('解除屏蔽'), findsOneWidget);

    await tester.tap(find.text('解除屏蔽'));
    await tester.pumpAndSettle();

    expect(blocklist.isEmpty, isTrue);
    // 页面回到空态（管理页是唯一恢复入口，解除后必须立刻反映）
    expect(find.text('还没有屏蔽任何内容'), findsOneWidget);

    // 解除后会弹一条确认提示（带 2s 停留），走完它避免留下 pending timer。
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
