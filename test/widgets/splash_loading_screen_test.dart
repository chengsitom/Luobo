import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/widgets/splash_loading_screen.dart';

import '../bootstrap.dart';

/// 冷启品牌启动页：阶段文案随 `startupPhase` 变化，且**页面不被重建**
/// （重建会让流体背景 / logo 呼吸动画从头开始，用户会看到「动画重置」）。
void main() {
  initializeTestEnvironment();

  Future<void> pumpSplash(WidgetTester tester, ValueNotifier<StartupPhase> p) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashLoadingScreen(phase: p),
      ),
    );
  }

  testWidgets('阶段文案随 startupPhase 变化', (tester) async {
    final phase = ValueNotifier<StartupPhase>(StartupPhase.connecting);
    addTearDown(phase.dispose);

    await pumpSplash(tester, phase);
    await tester.pump();

    expect(find.text('正在连接服务器…'), findsOneWidget);

    phase.value = StartupPhase.verifying;
    // 呼吸动画/不确定进度条永不停止，不能用 pumpAndSettle；文案切换 260ms。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('正在验证身份…'), findsOneWidget);
    expect(find.text('正在连接服务器…'), findsNothing);

    phase.value = StartupPhase.failed;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('连接不稳定，正在重试…'), findsOneWidget);
  });

  testWidgets('阶段切换时 State 复用（不重建页面）', (tester) async {
    final phase = ValueNotifier<StartupPhase>(StartupPhase.connecting);
    addTearDown(phase.dispose);

    await pumpSplash(tester, phase);
    await tester.pump();
    final stateBefore = tester.state(find.byType(SplashLoadingScreen));

    phase.value = StartupPhase.preparing;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final stateAfter = tester.state(find.byType(SplashLoadingScreen));

    // 同一个 State 实例 = 动画控制器没被销毁重建 = 视觉上不跳。
    expect(identical(stateBefore, stateAfter), isTrue);
  });

  testWidgets('phase 为空时退化为默认「连接中」', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SplashLoadingScreen(),
      ),
    );
    await tester.pump();

    expect(find.text('正在连接服务器…'), findsOneWidget);
  });
}
