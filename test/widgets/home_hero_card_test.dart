import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/theme/design_tokens.dart';
import 'package:luobo/widgets/home_hero_card.dart';

/// [HomeHeroCard]（首页顶部「漫游 / 收藏」大卡）的排版与交互回归。
///
/// 背景：2026-10-09 首页改版 —— 「今日推荐」暂时下线、「快速开始」砍掉，顶部改为
/// 两张 151×184dp 的大卡（对标飞牛首页）。这里钉住三件事：
/// 1. 卡面三要素（图标 / 标题 / 副标题）都渲染，且**图标是居中大图标**；
/// 2. 副标题为空/纯空白时**不占位**（不留空行）；
/// 3. 点击 / 长按回调可触发。
void main() {
  Future<void> pumpCard(WidgetTester tester, Widget card) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 151, height: 184, child: card),
          ),
        ),
      ),
    );
    // ⚠️ 不能用 `pumpAndSettle`：`FluidBackground` 是**持续流动**的动画，
    // 永远「settle」不下来。与旧 `mix_grid_section_test` 同款处理。
    await tester.pump();
  }

  testWidgets('渲染图标 + 标题 + 副标题', (tester) async {
    await pumpCard(
      tester,
      HomeHeroCard(
        icon: Icons.explore,
        title: '漫游',
        subtitle: '随机漫游曲库',
        onTap: () {},
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.explore), findsOneWidget);
    expect(find.text('漫游'), findsOneWidget);
    expect(find.text('随机漫游曲库'), findsOneWidget);
  });

  testWidgets('图标居中且略高于正中（给底部文字留位）', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(icon: Icons.explore, title: '漫游'),
    );

    final cardRect = tester.getRect(find.byType(HomeHeroCard));
    final iconRect = tester.getRect(find.byIcon(Icons.explore));
    // 水平居中
    expect(
      iconRect.center.dx,
      closeTo(cardRect.center.dx, 1),
    );
    // 垂直方向在正中**之上**（alignment 0,-0.25）
    expect(iconRect.center.dy, lessThan(cardRect.center.dy));
    expect(iconRect.width, closeTo(HomeHeroCard.iconSize, 1));
  });

  testWidgets('图标是半透明的（不抢流体底）', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(icon: Icons.explore, title: '漫游'),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.explore));
    expect(
      icon.color,
      Colors.white.withValues(alpha: HomeHeroCard.iconOpacity),
    );
    // 2026-10-09 用户要求「降低一点」——原值 0.92
    expect(HomeHeroCard.iconOpacity, lessThan(0.8));
  });

  testWidgets('无副标题时不占位', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(icon: Icons.favorite, title: '收藏'),
    );

    expect(find.text('收藏'), findsOneWidget);
    // 只有一行文字（没有多余的空副标题行）
    expect(find.byType(Text), findsOneWidget);
  });

  testWidgets('点击与长按回调可触发', (tester) async {
    var taps = 0;
    var longPresses = 0;
    await pumpCard(
      tester,
      HomeHeroCard(
        icon: Icons.favorite,
        title: '收藏',
        onTap: () => taps++,
        onLongPress: () => longPresses++,
      ),
    );

    await tester.tap(find.byType(HomeHeroCard));
    await tester.pump();
    await tester.longPress(find.byType(HomeHeroCard));
    await tester.pump();

    expect(taps, 1);
    expect(longPresses, 1);
  });

  testWidgets('标题走 heroCardTitle 字阶', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(icon: Icons.favorite, title: '收藏'),
    );

    final text = tester.widget<Text>(find.text('收藏'));
    expect(text.style?.fontSize, LuoboType.heroCardTitle.fontSize);
    expect(text.style?.fontWeight, LuoboType.heroCardTitle.fontWeight);
    expect(text.style?.color, Colors.white);
  });

  testWidgets('字母牌模式：渲染半透明大字首字，不渲染图标', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(monogram: 'C', title: 'cheng喜欢的音乐'),
    );

    expect(find.text('C'), findsOneWidget);
    // 字母牌优先于图标；本卡没传 icon，所以整卡没有 Icon
    expect(find.byType(Icon), findsNothing);

    final glyph = tester.widget<Text>(find.text('C'));
    expect(glyph.style?.fontSize, HomeHeroCard.monogramSize);
    expect(glyph.style?.color, Colors.white.withValues(alpha: 0.22));
    // 比图标大 —— 「卡面作品」而不是「小图标」
    expect(HomeHeroCard.monogramSize, greaterThan(HomeHeroCard.iconSize));
  });

  testWidgets('字母牌与图标同时给时字母牌优先', (tester) async {
    await pumpCard(
      tester,
      const HomeHeroCard(
        icon: Icons.favorite,
        monogram: 'C',
        title: '收藏',
      ),
    );

    expect(find.text('C'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsNothing);
  });

  testWidgets('titleMaxLines 生效（歌单名可两行且不溢出）', (tester) async {
    const longName = '这是一个非常非常长的歌单名字需要换行显示';
    await pumpCard(
      tester,
      const HomeHeroCard(monogram: '这', title: longName, titleMaxLines: 2),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text(longName));
    expect(title.maxLines, 2);
  });
}
