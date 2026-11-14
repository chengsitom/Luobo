import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:luobo/main.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/services/services.dart';
import 'package:luobo/theme/design_tokens.dart';
import 'package:luobo/widgets/luobo/list_top_bar.dart';

import '../bootstrap.dart';

/// 「添加服务器」页页头钉桩。
///
/// 2026-10-24 起设置页全体子页面统一走 [LuoboListTopBar] 的
/// 「返回 + 标题」胶囊（[LuoboBackTitlePill]）：40dp 高、圆角 20、
/// 左内边距 `LuoboSpacing.pageX`，标题跟着返回钮走，不再单独占一条页头。
void main() {
  initializeTestEnvironment();

  /// 胶囊高度（同歌手详情折叠态的返回胶囊）。
  const pillHeight = 40.0;

  Future<void> pumpLogin(WidgetTester tester) async {
    final storageService = StorageService();
    final subsonicService = SubsonicService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          Provider<SubsonicService>.value(value: subsonicService),
          ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider(
            create: (_) => AuthProvider(subsonicService, storageService),
          ),
        ],
        child: const MaterialApp(home: MuslyApp()),
      ),
    );
    await tester.pump();
    await tester.pump(); // 等待已保存配置的 FutureBuilder 解析
  }

  void expectDesignBackPill(WidgetTester tester, String title) {
    final pill = find.byType(LuoboBackTitlePill);
    expect(pill, findsOneWidget);
    expect(
      find.descendant(of: pill, matching: find.text(title)),
      findsOneWidget,
    );

    final size = tester.getSize(pill);
    expect(size.height, closeTo(pillHeight, 0.01));
    // 左内边距与列表页顶栏一致（`titleSpacing: 16`）。
    expect(tester.getTopLeft(pill).dx, LuoboSpacing.pageX);
    // 竖直居中于 56dp 顶栏。
    expect(tester.getTopLeft(pill).dy, closeTo((56 - pillHeight) / 2, 0.01));
  }

  /// 2026-10-27：设置页返回钮改成「上滑才带标题」。
  /// 可滚动页面先断言只有返回圆钮，上滑 120dp 后再断言标题胶囊；
  /// 内容不满一屏的短页面没有上滑机会，标题会一直显示（壳的兜底）。
  Future<void> expectTitleAfterScroll(
    WidgetTester tester,
    String title,
  ) async {
    final scrollableFinder = find.byType(Scrollable).first;
    final position = tester.state<ScrollableState>(scrollableFinder).position;
    if (position.maxScrollExtent > 0) {
      expect(find.byType(LuoboBackTitlePill), findsNothing);
      await tester.drag(scrollableFinder, const Offset(0, -120));
      await tester.pump();
    }
    expectDesignBackPill(tester, title);
  }

  testWidgets('添加服务器表单页页头 = 上滑后返回+标题胶囊', (tester) async {
    await pumpLogin(tester);

    // 方案 A 登录收口后，Add Server 直达表单，不再有类型网格中间步。
    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();

    expect(find.text('Server URL'), findsOneWidget); // 确认已进表单
    await expectTitleAfterScroll(tester, 'Add Server');
  });

  testWidgets('Add Server 直达表单：无类型选择步 + 品牌区', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();

    // 锁死方案 A 的收口行为，防止「选服务器类型」网格被加回来。
    expect(find.text('Subsonic'), findsNothing);
    expect(find.text('Server URL'), findsOneWidget);
    expect(find.text('萝卜'), findsOneWidget);
    expect(find.text('Connect to your Daoliyu server'), findsWidgets);
  });
}
