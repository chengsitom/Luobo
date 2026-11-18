import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/screens/server_unreachable_screen.dart';
import 'package:luobo/services/services.dart';

import '../bootstrap.dart';

/// 服务器连不上时的兜底页。
///
/// 这里锁两件真机上出过事的：
/// 1. 「进入离线模式」入口的文案**恒定**——曾经随"有没有下载"在「离线模式
///    （N 首可听）」和「浏览本地音乐」之间切换，用户以为离线选项被删了；
/// 2. 小屏 + 大字号不溢出——按钮最多 4 个（多服务器还有"切换服务器"）再加
///    一行说明，363dp 的机器上会直接黄黑条。
void main() {
  initializeTestEnvironment();

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool hasOfflineContent,
  }) async {
    final storageService = StorageService();
    final subsonicService = SubsonicService();
    final auth = AuthProvider(subsonicService, storageService);
    addTearDown(auth.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<StorageService>.value(value: storageService),
          Provider<SubsonicService>.value(value: subsonicService),
          ChangeNotifierProvider<AuthProvider>.value(value: auth),
        ],
        child: MaterialApp(
          locale: const Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ServerUnreachableScreen(
            hasOfflineContent: hasOfflineContent,
            onEnterOfflineMode: () {},
            onDisconnect: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('离线入口文案恒定：有无下载都叫「进入离线模式」', (tester) async {
    await pumpScreen(tester, hasOfflineContent: false);
    expect(find.text('进入离线模式'), findsOneWidget);
    expect(find.text('暂无已下载歌曲，仍可浏览本地音乐与设置'), findsOneWidget);

    await pumpScreen(tester, hasOfflineContent: true);
    expect(find.text('进入离线模式'), findsOneWidget);
    // 有下载时说明行改成"能听几首"，但入口名不变。
    expect(find.textContaining('可离线播放'), findsOneWidget);
  });

  testWidgets('小屏 + 大字号不溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpScreen(tester, hasOfflineContent: true);

    // overflow 会以异常形式上抛；滚动容器兜住后这里必须是 null。
    expect(tester.takeException(), isNull);
    // 最下面的「断开连接」仍可滚到。
    expect(find.text('断开连接'), findsOneWidget);
  });

  testWidgets('内容多时垂直居中而不是贴顶', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await pumpScreen(tester, hasOfflineContent: false);

    final top = tester.getTopLeft(find.byIcon(Icons.cloud_off_rounded)).dy;
    final bottom = tester.getBottomLeft(find.byType(OutlinedButton).last).dy;
    final contentCenter = (top + bottom) / 2;
    // 内容整块居中：中心应落在视口中心附近（留 40px 容差，含状态栏内边距）。
    expect(contentCenter, closeTo(900 / 2, 40));
  });
}
