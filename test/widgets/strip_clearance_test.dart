import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/theme/design_tokens.dart';

/// 悬浮条带净空的回归测试（2026-11-12）。
///
/// 背景：`main_screen` 用 `Scaffold(extendBody: true)` 把「底栏 / 播放条」悬浮在
/// 内容之上，条带高度由框架写进 body 的 `MediaQuery.padding.bottom`。
///
/// 坑：**谁来消费这个值不一样** ——
/// - `ListView` / `GridView`（`BoxScrollView`）在 `padding == null` 时自动包
///   `SliverPadding`，净空自动生效；
/// - `CustomScrollView` **不会**，必须页面自己在末尾留
///   `LuoboSpacing.pageBottomWithStrip(context)`。
///
/// 用错的表现就是「列表最后一行被播放条压住」。这两个用例把差异钉死，
/// 将来 Flutter 改了自动 padding 行为，这里会先红。
void main() {
  const stripHeight = 98.0;
  const lastKey = Key('last-item');

  Widget host(Widget scrollView) => MaterialApp(
    home: Scaffold(
      extendBody: true,
      bottomNavigationBar: const SizedBox(height: stripHeight),
      body: scrollView,
    ),
  );

  /// 滚到底后，「最后一行的底边」到「条带顶边」的间距（< 0 表示被压住）。
  Future<double> gapAboveStrip(WidgetTester tester) async {
    await tester.drag(find.byType(Scrollable), const Offset(0, -4000));
    await tester.pumpAndSettle();
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    return (screenHeight - stripHeight) -
        tester.getBottomLeft(find.byKey(lastKey)).dy;
  }

  testWidgets('CustomScrollView + 末尾净空 → 最后一行完整露出', (tester) async {
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(child: SizedBox(height: 1200)),
              const SliverToBoxAdapter(
                child: SizedBox(height: 56, key: lastKey),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: LuoboSpacing.pageBottomWithStrip(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      await gapAboveStrip(tester),
      greaterThanOrEqualTo(0),
      reason: '最后一行必须停在条带上方，不能被悬浮播放条压住',
    );
  });

  testWidgets('CustomScrollView 不留净空 → 会被条带压住（这就是本次修的病）', (tester) async {
    await tester.pumpWidget(
      host(
        const CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: SizedBox(height: 1200)),
            SliverToBoxAdapter(child: SizedBox(height: 56, key: lastKey)),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 若哪天 Flutter 给 CustomScrollView 也加上了自动 padding，这条会变绿而失败，
    // 届时可以去掉页面里的显式净空（并同步 design_tokens 的注释）。
    expect(
      await gapAboveStrip(tester),
      lessThan(0),
      reason: 'CustomScrollView 不会自动吃 MediaQuery.padding.bottom',
    );
  });
}
