import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:luobo/services/diagnostics/diagnostics.dart';
import 'package:luobo/theme/roaming_palettes.dart';
import 'package:luobo/widgets/fluid_card_overlay.dart';
import 'package:luobo/widgets/mix_grid_section.dart';
import 'package:luobo/widgets/section_header.dart';

import '../test_helpers.dart';

void main() {
  group('MixGridSection（流体网格 / 横滑）', () {
    testWidgets('网格模式：4 张卡共用一个 Ticker', (tester) async {
      final cards = ['A', 'B', 'C', 'D']
          .map((title) => MixCardData(title: title, useFluidGradient: true))
          .toList();

      await tester.pumpWidget(
        createTestApp(
          // 首页里这段本来就在 CustomScrollView 内，测试里给个可滚动容器，
          // 避免默认 800×600 测试视口把 4 张卡挤成 RenderFlex overflow。
          child: SingleChildScrollView(
            child: MixGridSection(title: '网格段', cards: cards),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FluidBackground), findsNWidgets(4));
      expect(tester.binding.transientCallbackCount, 1,
          reason: '4 张卡应共享 Scope 的 1 个时钟');

      // 埋点：本段的背景模式被记录（A/B 时用来归属 frame.jank）
      final modeEvent = DiagnosticsService.instance.ring.lastWhere(
        (e) =>
            e.type == EventType.animActive &&
            e.payload['anim'] == 'mixCardFluidBackground',
      );
      expect(modeEvent.payload['cards'], 4);
      expect(modeEvent.payload['clock'], 'monotonic');

      // 让 DiagnosticsService 的通知节流 Timer 落地，否则测试结束会报
      // 「A Timer is still pending」。
      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });

    testWidgets('流体包事件可接到诊断系统（shaderReady / paletteExtract）', (tester) async {
      final received = <String>[];
      FluidBackgroundEvents.onEvent = (event, payload) {
        received.add(event);
      };
      addTearDown(() => FluidBackgroundEvents.onEvent = null);

      final cards = [
        const MixCardData(title: '通勤活力', useFluidGradient: true),
      ];
      await tester.pumpWidget(
        createTestApp(
          child: SingleChildScrollView(
            child: MixGridSection(title: '网格段', cards: cards),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // 至少收到渲染路径事件（shaderReady 或 shaderUnavailable 二选一）
      expect(
        received.any(
          (e) => e == 'shaderReady' || e == 'shaderUnavailable',
        ),
        isTrue,
        reason: '实际收到: $received',
      );

      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });

    testWidgets('title 为 null 时不画小节标题（网格模式）', (tester) async {
      final cards = [
        const MixCardData(title: '歌单', useFluidGradient: true),
        const MixCardData(title: '收藏', useFluidGradient: true),
        const MixCardData(title: '漫游', useFluidGradient: true),
      ];

      await tester.pumpWidget(
        createTestApp(
          child: SingleChildScrollView(
            child: MixGridSection(
              cards: cards,
              columns: 3,
              childAspectRatio: 0.70,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SectionHeader), findsNothing);
      expect(find.byType(FluidBackground), findsNWidgets(3));
      // 3 列若沿用默认 0.9 会 RenderFlex overflow —— 上面 takeException 已覆盖。
      expect(find.text('漫游'), findsOneWidget);

      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });

    testWidgets('横滑模式：150dp 正方形卡 + 文字叠在流体内（白色）', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SingleChildScrollView(
            child: MixGridSection(
              title: '快速开始',
              cardWidth: 150,
              cards: const [
                MixCardData(
                  title: '漫游',
                  subtitle: '随机漫游曲库',
                  useFluidGradient: true,
                ),
                MixCardData(
                  title: '歌单',
                  subtitle: '全部歌单',
                  useFluidGradient: true,
                ),
                MixCardData(
                  title: '收藏',
                  subtitle: '12',
                  useFluidGradient: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // 小节标题照画（2026-10-08 第二轮：从「无标题」改为「快速开始」）
      expect(find.byType(SectionHeader), findsOneWidget);
      expect(find.text('快速开始'), findsOneWidget);
      expect(find.byType(FluidBackground), findsNWidgets(3));

      // 正方形卡：宽高都等于 cardWidth
      final size = tester.getSize(find.byType(FluidBackground).first);
      expect(size.width, 150);
      expect(size.height, 150);

      // 文字在流体内 → 一律白色（网格模式的文字在卡下方、用的是主题色）
      final title = tester.widget<Text>(find.text('漫游'));
      expect(title.style?.color, Colors.white);
      final subtitle = tester.widget<Text>(find.text('随机漫游曲库'));
      expect(subtitle.style?.color, Colors.white.withValues(alpha: 0.75));

      // 横滑：卡片横向排列（第 2 张在第 1 张右侧）
      final first = tester.getTopLeft(find.byType(FluidBackground).at(0));
      final second = tester.getTopLeft(find.byType(FluidBackground).at(1));
      expect(second.dy, first.dy);
      expect(second.dx, greaterThan(first.dx));

      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });

    testWidgets('count 在标题的上一行（歌单 / 收藏的数字上移）', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: SingleChildScrollView(
            child: MixGridSection(
              title: '快速开始',
              cardWidth: 150,
              cards: const [
                MixCardData(title: '收藏', count: '12', useFluidGradient: true),
                MixCardData(
                  title: '歌单',
                  subtitle: '全部歌单',
                  useFluidGradient: true,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(FluidCardOverlay), findsNWidgets(2));

      // 数字在标题**上方**：数字底边不高于标题顶边，且左对齐
      final titleRect = tester.getRect(find.text('收藏'));
      final countRect = tester.getRect(find.text('12'));
      expect(countRect.bottom, lessThanOrEqualTo(titleRect.top));
      expect(countRect.left, closeTo(titleRect.left, 1));

      // 字阶与「漫游」的两行逐行对齐：数字 = 主行（15/w600）、名称 = 次行（12/白75%）
      final countStyle = tester.widget<Text>(find.text('12')).style!;
      expect(countStyle.fontSize, 15);
      expect(countStyle.fontWeight, FontWeight.w600);
      expect(countStyle.color, Colors.white);
      final nameStyle = tester.widget<Text>(find.text('收藏')).style!;
      expect(nameStyle.fontSize, 12);
      expect(nameStyle.color, Colors.white.withValues(alpha: 0.75));

      // 没有 count 的卡：标题就是主行（与「漫游」一致）
      final playlistTitleStyle = tester.widget<Text>(find.text('歌单')).style!;
      expect(playlistTitleStyle.fontSize, 15);
      expect(playlistTitleStyle.fontWeight, FontWeight.w600);

      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });

    testWidgets('fluidColors 有值时直接用它，不再从封面取色（漫游卡）', (tester) async {
      final palette = RoamingPalettes.all.first;
      await tester.pumpWidget(
        createTestApp(
          child: SingleChildScrollView(
            child: MixGridSection(
              cardWidth: 150,
              cards: [
                MixCardData(
                  title: '漫游',
                  useFluidGradient: true,
                  fluidColors: palette,
                  seed: 1.25,
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      final background = tester.widget<FluidBackground>(
        find.byType(FluidBackground),
      );
      expect(background.colors, same(palette));
      expect(background.imageProvider, isNull, reason: '有固定配色就不该再传图');
      expect(background.seed, 1.25, reason: '每张卡可有自己的纹样 seed');

      await tester.pump(
        DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
      );
    });
  });
}
