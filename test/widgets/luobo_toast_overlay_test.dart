import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luobo/widgets/luobo/luobo_toast.dart';

/// 轻提示的「宿主已销毁」路径。
///
/// 真实故障（2026-11-18 用户反馈「多选歌曲后添加到歌单没有成功的 toast」）：
/// 多选 sheet → 选歌单 → sheet 立刻 `pop`，等 `updatePlaylist` 网络回来时，
/// 原来传给 `showLuoboToast(context)` 的 context 已经 unmounted，函数里的
/// `if (!context.mounted) return` 把提示吞掉了 —— 加了歌但毫无反馈。
///
/// 修法是把「往哪个 overlay 插」和「用谁的 context」解耦：只要 root overlay
/// 还活着（它挂在 Navigator 上，页面/弹窗销毁不影响），提示就能出来。
void main() {
  testWidgets('页面被 pop 后，用提前抓的 root overlay 仍能弹提示', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    OverlayState? captured;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('home')),
      ),
    );

    // 模拟 sheet：push 一个页面，在它活着的时候抓 root overlay。
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (ctx) {
          captured = Overlay.of(ctx, rootOverlay: true);
          return const Scaffold(body: Text('sheet'));
        },
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsOneWidget);
    expect(captured, isNotNull);

    // sheet 关掉 —— 此后那个 context 已 unmounted。
    navKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('sheet'), findsNothing);

    showLuoboToastOnOverlay(
      captured!,
      message: '已添加 2 首到「测试歌单」',
      tone: LuoboToastTone.success,
    );
    await tester.pump(); // 插入 overlay
    await tester.pump(const Duration(milliseconds: 200)); // 淡入

    expect(find.text('已添加 2 首到「测试歌单」'), findsOneWidget);

    // 走完停留 + 淡出，避免测试结束时留 pending timer。
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('overlay 已销毁时安静返回，不抛异常', (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    OverlayState? captured;

    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navKey,
        home: const Scaffold(body: Text('home')),
      ),
    );
    navKey.currentState!.push(
      MaterialPageRoute(
        builder: (ctx) {
          captured = Overlay.of(ctx, rootOverlay: true);
          return const Scaffold(body: Text('sheet'));
        },
      ),
    );
    await tester.pumpAndSettle();

    // 整个 App 换掉 → 旧 overlay 不再 mounted。
    await tester
        .pumpWidget(const MaterialApp(home: Scaffold(body: Text('new'))));
    await tester.pump();

    expect(
      () => showLuoboToastOnOverlay(captured!, message: '不该出现'),
      returnsNormally,
    );
    await tester.pump();
    expect(find.text('不该出现'), findsNothing);
  });
}
