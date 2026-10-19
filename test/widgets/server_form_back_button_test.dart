import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:luobo/main.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/services/services.dart';
import 'package:luobo/theme/design_tokens.dart';
import 'package:luobo/widgets/luobo/glass_circle_button.dart';

import '../bootstrap.dart';

/// 「添加服务器」页左上返回钮的几何钉桩。
///
/// ⚠️ 这一页是全仓**唯一**把 `GlassBackButton` 放进 `AppBar.leading` 的地方
/// （其余二级页走 `SettingsSubPage` 的 `Stack`/`Positioned`）。而 `AppBar.leading`
/// 槽位是**紧约束** 56×56（`_kLeadingWidth` = `toolbarHeight`，且
/// `NavigationToolbar` 给 leading 的 `minHeight == maxHeight == toolbarHeight`），
/// 会把钮内部的 `SizedBox(40)` 撑成 56×56、并让钮贴屏幕左边缘 —— 实测过。
///
/// 另一个坑：钮的**自然直径**不是 40 而是 41.6 —— `LuoboGlassSurface` 的
/// `Container` 会按 Flutter 语义把 `BoxDecoration.border` 的宽度（0.8）当 padding
/// 加在子级外。所以槽位必须放得下 41.6，否则钮会被挤扁（给 40 宽 → 40×41.6）。
void main() {
  initializeTestEnvironment();

  /// 与 `SettingsSubPage` 上同一组件一致的直径。
  const designDiameter = LuoboGlass.circleButtonSize + 2 * LuoboGlass.borderWidth;

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

  void expectDesignBackButton(WidgetTester tester) {
    final back = find.byType(GlassBackButton);
    expect(back, findsOneWidget);

    final size = tester.getSize(back);
    // 正圆：既不是被槽位撑成的 56×56，也不是被挤扁的 40×41.6。
    expect(size.width, closeTo(size.height, 0.01));
    expect(size.width, closeTo(designDiameter, 0.01));
    // 左内边距与 `SettingsSubPage` 的 `Positioned(left: LuoboSpacing.pageX)` 一致。
    expect(tester.getTopLeft(back).dx, LuoboSpacing.pageX);
  }

  testWidgets('添加服务器第 1 步（类型网格）返回钮 = 设计直径 / 左内边距 16dp', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();

    expect(find.text('Subsonic'), findsOneWidget); // 确认停在类型网格步
    expectDesignBackButton(tester);
  });

  testWidgets('添加服务器第 2 步（表单）返回钮 = 设计直径 / 左内边距 16dp', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Add Server'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Subsonic'));
    await tester.pumpAndSettle();

    expect(find.text('Server URL'), findsOneWidget); // 确认已进表单步
    expectDesignBackButton(tester);
  });
}
