import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:luobo/models/models.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/screens/listening_report_screen.dart';
import 'package:luobo/services/recommendation_service.dart';
import 'package:luobo/services/subsonic_service.dart';

import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();

  Future<void> pumpPage(WidgetTester tester, RecommendationService rec) async {
    final library = LibraryProvider(SubsonicService());
    addTearDown(library.dispose);
    addTearDown(rec.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<RecommendationService>.value(value: rec),
          ChangeNotifierProvider<LibraryProvider>.value(value: library),
        ],
        child: const MaterialApp(home: ListeningReportScreen()),
      ),
    );
    // trackSongPlay 会挂一个 800ms 防抖保存 timer，推进它避免测试结束时残留。
    await tester.pump(const Duration(milliseconds: 900));
    await tester.pump();
  }

  testWidgets('无数据时显示空态文案', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rec = RecommendationService();
    await rec.initialize();
    await pumpPage(tester, rec);

    expect(find.text('还没有听歌数据，多听几首再来看吧'), findsOneWidget);
    expect(find.text('你的音乐人格'), findsNothing);
  });

  testWidgets('有播放记录时渲染人格卡与四个章节', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rec = RecommendationService();
    await rec.initialize();
    for (var i = 0; i < 6; i++) {
      await rec.trackSongPlay(Song(
        id: 's$i',
        title: 'Song $i',
        artist: '歌手${i % 2}',
        genre: 'pop',
      ));
    }
    await pumpPage(tester, rec);

    // Hero 人格卡（固定标签，不依赖具体时段算出的钩子句）
    expect(find.text('你的音乐人格'), findsOneWidget);
    expect(find.text('累计聆听'), findsOneWidget);

    // 章节标题（第一屏可见）
    expect(find.text('你的口味指纹'), findsOneWidget);

    // 末尾章节与探索歌单按钮在 ListView 底部，需滚动进入视口。
    // 此测试的 LibraryProvider 无曲库，探索歌单为空 → 显示兜底文案。
    await tester.scrollUntilVisible(
      find.text('曲库太小，暂时挑不出探索歌单'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('接下来听点什么'), findsOneWidget);
    expect(find.byIcon(Icons.explore_rounded), findsOneWidget);
  });

  testWidgets('帮助按钮可打开说明弹层', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final rec = RecommendationService();
    await rec.initialize();
    await rec.trackSongPlay(Song(id: 's', title: 'Song', artist: 'A'));
    await pumpPage(tester, rec);

    await tester.tap(find.byIcon(Icons.help_outline_rounded));
    await tester.pumpAndSettle();

    expect(find.text('这份报告怎么来的？'), findsOneWidget);
    // 帮助项较多，只断言靠前的项；底部项需滚动，不做脆弱断言。
    expect(find.text('音乐人格'), findsOneWidget);
    expect(find.text('口是心非 / 生物钟'), findsOneWidget);
  });
}
