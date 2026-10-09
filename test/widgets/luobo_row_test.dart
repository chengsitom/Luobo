import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/theme/design_tokens.dart';
import 'package:luobo/widgets/luobo/luobo_card.dart';
import 'package:luobo/widgets/luobo/luobo_tile.dart';

/// [LuoboRow] 右侧状态值的排版回归。
///
/// 背景：`value` 与标题同处一个 `spaceBetween` 行 —— 标题 `Flexible(flex:1)`、
/// 值 `Flexible(flex:2)`。这里钉住两件事：
/// 1. 超长值（服务器地址）**不溢出**（溢出会在测试里抛 RenderFlex 异常）；
/// 2. 短值仍然**贴右边缘**（不能因为标题是 flex 子项而被顶到中间）。
void main() {
  Future<void> pumpRow(WidgetTester tester, Widget row) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 360, child: LuoboCard(children: [row])),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('超长状态值不溢出（省略号收口）', (tester) async {
    await pumpRow(
      tester,
      const LuoboRow(
        icon: Icons.dns,
        title: '服务器地址',
        value: 'https://music.very-long-subdomain.example.com:4533/stream',
        showChevron: false,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('服务器地址'), findsOneWidget);
  });

  testWidgets('短状态值贴右边缘', (tester) async {
    await pumpRow(
      tester,
      const LuoboRow(title: '清除 App 缓存', value: '1.0 GB', showChevron: true),
    );

    final rowRect = tester.getRect(find.byType(LuoboRow));
    final valueRect = tester.getRect(find.text('1.0 GB'));
    // 行右内边距 rowX(16) + 值与 chevron 的间隔(6) + chevron 宽(15)
    expect(rowRect.right - valueRect.right, closeTo(37, 1));
  });

  testWidgets('无 value 时标题仍吃满整行', (tester) async {
    await pumpRow(
      tester,
      const LuoboRow(title: '播放设置', onTap: null),
    );

    final rowRect = tester.getRect(find.byType(LuoboRow));
    final titleRect = tester.getRect(find.text('播放设置'));
    expect(titleRect.left, closeTo(rowRect.left + LuoboSpacing.rowX, 1));
    expect(rowRect.right - titleRect.right, greaterThan(100));
  });
}
