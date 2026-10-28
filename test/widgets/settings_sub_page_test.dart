import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luobo/widgets/luobo/hero_detail_header.dart';
import 'package:luobo/widgets/luobo/list_top_bar.dart';
import 'package:luobo/widgets/settings_sub_page.dart';

/// 设置二级页壳的钉桩。
///
/// 2026-10-24 用户反馈「播放器界面滑动后还是有不透明导航栏」——根因是顶栏净空
/// 被写成了**外层 Padding**，滚动内容在顶栏下沿被裁断。
/// 2026-10-27 用户要求「没上滑时不带标题，上滑到一定程度再加入」。
///
/// 这里钉五件事：
/// 1. 页头 = 透明 `LuoboListTopBar`；
/// 2. 初始只有返回圆钮，**不带标题**；
/// 3. 上滑超过阈值后出现「返回 + 标题」胶囊；
/// 4. body **不被外层 Padding 下推**（内容从圆钮下方流过）；
/// 5. 内容不满一屏时保留标题（没有上滑机会）。
void main() {
  testWidgets('设置二级页：初始不带标题，上滑后才出现标题胶囊', (tester) async {
    late double bodyMediaQueryTop;
    late double expectedPaddingTop;

    await tester.pumpWidget(
      MaterialApp(
        home: SettingsSubPage(
          title: '播放器界面',
          body: Builder(
            builder: (context) {
              bodyMediaQueryTop = MediaQuery.paddingOf(context).top;
              expectedPaddingTop = 16 + listScrollTopInset(context);
              return ListView(
                padding: EdgeInsets.only(top: expectedPaddingTop),
                children: const [SizedBox(height: 2000)],
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    // 1) 页头是通用顶栏（不是实色栏）：透明 + 初始只有返回圆钮。
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(appBar.backgroundColor, Colors.transparent);
    expect(appBar.elevation, 0);
    expect(appBar.scrolledUnderElevation, 0);
    expect(find.byType(LuoboTopCircleButton), findsOneWidget);
    expect(find.byType(LuoboBackTitlePill), findsNothing);
    expect(find.text('播放器界面'), findsNothing);

    // 2) body 从屏幕顶端开始（顶栏覆盖式，不占位、不被 Padding 下推）。
    expect(tester.getTopLeft(find.byType(ListView)).dy, 0);

    // 3) body 内 MediaQuery 已含 56 顶栏；滚动 padding = 56 + 16。
    expect(bodyMediaQueryTop, 56);
    expect(
      (tester.widget<ListView>(find.byType(ListView)).padding as EdgeInsets)
          .top,
      expectedPaddingTop,
    );
    expect(expectedPaddingTop, 56 + 16);

    // 4) 上滑超过 64dp 后，返回钮换成「返回 + 标题」胶囊。
    await tester.drag(find.byType(ListView), const Offset(0, -100));
    await tester.pump();
    expect(find.byType(LuoboBackTitlePill), findsOneWidget);
    expect(find.text('播放器界面'), findsOneWidget);

    // 5) 回滑到顶部后标题收起。
    await tester.drag(find.byType(ListView), const Offset(0, 100));
    await tester.pump();
    expect(find.byType(LuoboBackTitlePill), findsNothing);
  });

  testWidgets('滚动内容能滚到顶栏之下（首项不贴顶）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsSubPage(
          title: '播放器界面',
          body: Builder(
            builder: (context) => ListView(
              padding: EdgeInsets.only(top: listScrollTopInset(context) + 16),
              children: const [
                SizedBox(key: Key('first'), height: 100),
                SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );

    // 未滚动时首项在顶栏（56）+ 16 之下。
    expect(tester.getTopLeft(find.byKey(const Key('first'))).dy, 72);

    // 滚动后首项从顶栏下方流过（y < 56），而不是被裁在 56。
    // 只滚 60：首项仍有 40dp 留在视口内，键控 child 不会被回收。
    await tester.drag(find.byType(ListView), const Offset(0, -60));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const Key('first'))).dy, lessThan(56));
  });

  testWidgets('内容不满一屏时保留标题（没有上滑机会）', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsSubPage(
          title: '播放器界面',
          body: ListView(
            padding: const EdgeInsets.only(top: 72),
            children: const [SizedBox(height: 80)],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(LuoboBackTitlePill), findsOneWidget);
    expect(find.text('播放器界面'), findsOneWidget);
  });
}
