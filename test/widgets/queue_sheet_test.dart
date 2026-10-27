import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/screens/now_playing_screen.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// 回归防护：播放队列浮层**固定高度**、不铺满整屏。
///
/// 2026-10-23 起 QueueSheet 改为固定高度（屏高 52%，320~480dp）+ 只展示
/// 待播放列表，不再用 DraggableScrollableSheet 撑满 70%~95%。
void main() {
  initializeTestEnvironment();

  testWidgets('队列弹层固定高度且不铺满全屏', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showQueueSheet(context),
              child: const Text('open-queue'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open-queue'));
    await tester.pumpAndSettle();

    // 不再使用可拖拽变高容器。
    expect(find.byType(DraggableScrollableSheet), findsNothing);

    final sheetSize = tester.getSize(find.byType(QueueSheet));
    final screenHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;

    expect(sheetSize.height, greaterThanOrEqualTo(320));
    expect(sheetSize.height, lessThanOrEqualTo(480));
    expect(
      sheetSize.height,
      lessThan(screenHeight * 0.9),
      reason: '浮层应固定高度、不铺满整屏',
    );
  });
}
