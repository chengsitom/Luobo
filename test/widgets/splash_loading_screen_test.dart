import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';

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

  /// 父级（AuthWrapper）每次 build 都会**新建**一个 SplashLoadingScreen 实例；
  /// 只要类型和 key 不变，Element 就复用，流体背景的时钟不会归零。
  /// 这条守住的是"别给启动页加 key / 别换包一层会重建的容器"——真加了，
  /// 用户会看到冷启动流体动画跳一下。
  testWidgets('父级重建不会重建流体背景', (tester) async {
    final phase = ValueNotifier<StartupPhase>(StartupPhase.connecting);
    addTearDown(phase.dispose);

    await pumpSplash(tester, phase);
    await tester.pump();
    final fluidBefore = tester.state(find.byType(FluidBackground));

    // 模拟 AuthWrapper 重建：同类型、新实例、同一位置。
    await pumpSplash(tester, phase);
    await tester.pump();
    final fluidAfter = tester.state(find.byType(FluidBackground));

    expect(identical(fluidBefore, fluidAfter), isTrue);
  });

  /// logobig.png 是「透明底 + 近白色图形」，logo 卡一旦给了白底就会白上加白、
  /// 冷启时几乎看不见（2026-11-19 用户反馈）。守住「卡体无纯白填充」这条。
  testWidgets('logo 卡不给白底（白色图形需叠在流体上）', (tester) async {
    final phase = ValueNotifier<StartupPhase>(StartupPhase.connecting);
    addTearDown(phase.dispose);

    await pumpSplash(tester, phase);
    await tester.pump();

    final card = tester.widget<Container>(find.byKey(const ValueKey('splashLogoCard')));
    final decoration = card.decoration as BoxDecoration?;
    // 允许 null 或任意非纯白底色；绝不能是 Colors.white。
    expect(decoration?.color, isNot(Colors.white));
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
