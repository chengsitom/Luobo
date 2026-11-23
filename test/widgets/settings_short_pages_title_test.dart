import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/providers/providers.dart';
import 'package:luobo/services/services.dart';
import 'package:luobo/services/audio_handler.dart';
import 'package:luobo/services/locale_service.dart';
import 'package:luobo/services/local_music_service.dart';
import 'package:luobo/services/transcoding_service.dart';
import 'package:luobo/widgets/luobo/list_top_bar.dart';
import 'package:luobo/screens/settings_about_page.dart';
import 'package:luobo/screens/settings_app_page.dart';

import '../bootstrap.dart';
import '../test_helpers.dart' as helpers;

/// 守护「短设置页也要上滑才显标题」的约定。
///
/// 2026-11-23 用户反馈：设置里「关于」「App 设置」两页内容不满一屏，
/// 走了 ScrollRevealScaffold 的短页兜底、一进去就挂着标题，和别的二级页不一致。
/// 修复：这两页 body 垫一屏高度让它可上滑。这里钉住行为，防止垫高被误删。
Widget _probeApp(Widget child) {
  final service = SubsonicService();
  final storage = StorageService();
  return MultiProvider(
    providers: [
      Provider<SubsonicService>.value(value: service),
      Provider<StorageService>.value(value: storage),
      ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(service, storage)),
      ChangeNotifierProvider<PlayerProvider>(
        create: (_) => PlayerProvider(service, storage, helpers.FakeCastService(),
            UpnpService(), MuslyAudioHandler(), TranscodingService()),
      ),
      ChangeNotifierProvider<LibraryProvider>(
          create: (_) => LibraryProvider(service)),
      ChangeNotifierProvider<TranscodingService>(
          create: (_) => TranscodingService()),
      ChangeNotifierProvider<LocaleService>(create: (_) => LocaleService()),
      ChangeNotifierProvider<LocalMusicService>(
          create: (_) => LocalMusicService()),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  initializeTestEnvironment();

  for (final entry in <String, Widget>{
    '关于页': const SettingsAboutPage(),
    'App设置页': const SettingsAppPage(),
  }.entries) {
    testWidgets('${entry.key}：初始无标题，上滑后显示标题胶囊', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_probeApp(entry.value));
      await tester.pump();

      // 初始：只有返回圆钮，没有标题胶囊。
      expect(find.byType(LuoboBackTitlePill), findsNothing,
          reason: '${entry.key} 初始不应显示标题');

      // 上滑超过阈值（64dp）后标题出现。
      await tester.drag(find.byType(ListView).first, const Offset(0, -120));
      await tester.pump();
      expect(find.byType(LuoboBackTitlePill), findsOneWidget,
          reason: '${entry.key} 上滑后应显示标题胶囊');
    });
  }
}
