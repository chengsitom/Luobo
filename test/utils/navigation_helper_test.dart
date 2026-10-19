import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/utils/navigation_helper.dart';

/// `NavigationHelper.secondaryDepth` 是「一级页只出底栏 / 二级页只出播放条」
/// 这条互斥规则的**唯一判据**（见 `docs/视觉与交互对标飞牛音乐技术方案.md` §6.1）。
/// 判错了底部条带就会同时出两条、或者两条都不出，所以把它的语义钉死：
/// **只有挂在嵌套 Navigator 上的非首路由才计数**。
void main() {
  setUp(() => NavigationHelper.secondaryDepth.value = 0);

  testWidgets('push 计数、pop 归零、popUntil 也是一次次 pop', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        // 嵌套 Navigator（对应 main_screen 里 `mobileNavigatorKey` 那个）。
        home: Navigator(
          key: navKey,
          observers: [NavigationHelper.secondaryDepthObserver],
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );

    // 嵌套 Navigator 自己的初始路由 `isFirst` → **不算**二级页。
    expect(NavigationHelper.secondaryDepth.value, 0);

    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    expect(NavigationHelper.secondaryDepth.value, 1);

    navKey.currentState!.push(
      MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
    );
    await tester.pumpAndSettle();
    expect(NavigationHelper.secondaryDepth.value, 2);

    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(NavigationHelper.secondaryDepth.value, 1);

    // 底栏点击走的就是 `popUntil(isFirst)` —— 必须能一路归零。
    navKey.currentState!.popUntil((r) => r.isFirst);
    await tester.pumpAndSettle();
    expect(NavigationHelper.secondaryDepth.value, 0);
  });

  testWidgets('深度不会掉到负数（多余的 pop 不发散）', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          key: navKey,
          observers: [NavigationHelper.secondaryDepthObserver],
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (_) => const SizedBox.shrink()),
        ),
      ),
    );

    // 没有可 pop 的路由时 pop 是 no-op，观察者也不该收到回调。
    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(NavigationHelper.secondaryDepth.value, 0);
  });
}
