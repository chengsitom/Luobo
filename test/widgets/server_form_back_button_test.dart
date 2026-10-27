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

  testWidgets('添加服务器第 1 步（类型网格）页头 = 返回+标题胶囊', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();

    expect(find.text('Subsonic'), findsOneWidget); // 确认停在类型网格步
    expectDesignBackPill(tester, 'Add Server');
  });

  testWidgets('添加服务器第 2 步（表单）页头 = 返回+标题胶囊', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subsonic'));
    await tester.pumpAndSettle();

    expect(find.text('Server URL'), findsOneWidget); // 确认已进表单步
    expectDesignBackPill(tester, 'Add Server');
  });
}
