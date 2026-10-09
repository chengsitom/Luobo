import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/screens/song_list_screen.dart';
import 'package:luobo/services/diagnostics/diagnostics.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// 让 DiagnosticsService 的通知节流 Timer 落地，否则测试结束会报
/// 「A Timer is still pending even after the widget tree was disposed」。
Future<void> _flushDiagnosticsTimers(WidgetTester tester) => tester.pump(
      DiagnosticsService.notifyThrottle + const Duration(milliseconds: 50),
    );

/// ⚠️ 本文件**不传 `imageUrl`**：走真实封面会拉起 `CachedNetworkImageProvider`
/// 的下载链路，测试结束时残留 Timer。这也是 `fluid_background_test.dart` 一律
/// 用 `colors:` 的原因——取色链路由该文件在包内单独覆盖。
void main() {
  initializeTestEnvironment();

  final songs = [
    Song(id: 's1', title: 'Song 1', artist: 'Artist 1'),
    Song(id: 's2', title: 'Song 2', artist: 'Artist 2'),
  ];

  Widget buildScreen() => createTestApp(
        child: SongListScreen(
          title: '今日推荐',
          songs: songs,
          slogans: const ['每天都是新的'],
        ),
      );

  group('SongListScreen（二级页 hero 流沙流体）', () {
    testWidgets('hero 背景是流沙流体，且 34pt 标题 / slogan / 三键都保留', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      // 背景：流体（不再是自己画渐变的 AnimatedContainer）
      expect(find.byType(FluidBackground), findsOneWidget);
      // 标题与 slogan 仍在
      expect(find.text('今日推荐'), findsOneWidget);
      expect(find.text('每天都是新的'), findsOneWidget);
      // 三键保留（随机 / 播放 / 加入当前播放列表）
      expect(find.byIcon(Icons.shuffle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.playlist_add_rounded), findsOneWidget);

      await _flushDiagnosticsTimers(tester);
    });

    testWidgets('hero 用分区遮罩：不整幅暗化（否则中段流动感被抹平）', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();

      expect(tester.takeException(), isNull);
      final fluid =
          tester.widget<FluidBackground>(find.byType(FluidBackground));
      // 不用模块的整幅 showScrim：离屏实测它把中段空间对比度压到 0.023，
      // 而分区遮罩是 0.068（≈3 倍），白字对比度两者持平（3.97/3.56 vs 4.09/3.68）。
      expect(fluid.showScrim, isFalse);
      // 分区遮罩 = 两块线性渐变（顶部压标题 / 底部压 slogan）
      expect(
        find.descendant(
          of: find.byType(FlexibleSpaceBar),
          matching: find.byWidgetPredicate((w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).gradient is LinearGradient),
        ),
        findsNWidgets(2),
      );
      // 无封面 → 交由包内 FluidPalette.defaultColors 兜底，不回退品牌红紫
      expect(fluid.imageProvider, isNull);

      await _flushDiagnosticsTimers(tester);
    });

    testWidgets('埋点记录 hero 的流体背景模式（供 frame.jank 归属）', (tester) async {
      await tester.pumpWidget(buildScreen());
      await tester.pump();
      await tester.pump();

      final event = DiagnosticsService.instance.ring.lastWhere(
        (e) =>
            e.type == EventType.animActive &&
            e.payload['anim'] == 'songListHeroFluidBackground',
      );
      expect(event.payload['songs'], songs.length);
      expect(event.payload['cover'], isFalse);
      expect(event.payload['clock'], 'monotonic');

      await _flushDiagnosticsTimers(tester);
    });
  });
}
