import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/providers/player_provider.dart';
import 'package:luobo/services/subsonic_service.dart';
import 'package:luobo/services/storage_service.dart';
import 'package:luobo/services/upnp_service.dart';
import 'package:luobo/services/audio_handler.dart';
import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/services/transcoding_service.dart';
import 'package:luobo/theme/app_icons.dart';
import 'package:luobo/widgets/song_tile.dart';
import '../test_helpers.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();
  group('SongTile', () {
    late SubsonicService subsonicService;
    late PlayerProvider playerProvider;

    setUp(() {
      subsonicService = SubsonicService();
      subsonicService = SubsonicService();
      playerProvider = PlayerProvider(
        subsonicService,
        StorageService(),
        FakeCastService(),
        UpnpService(),
        MuslyAudioHandler(),
        TranscodingService(),
      );
    });

    tearDown(() {
      playerProvider.dispose();
    });

    testWidgets('should display song information', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
        duration: 180,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LibraryProvider>(
              create: (_) => LibraryProvider(subsonicService),
            ),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SongTile(song: song, showArtist: true)),
          ),
        ),
      );

      expect(find.text('Test Song'), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
    });

    testWidgets('should show duration when enabled', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        duration: 180,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LibraryProvider>(
              create: (_) => LibraryProvider(subsonicService),
            ),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(body: SongTile(song: song, showDuration: true)),
          ),
        ),
      );

      expect(find.text('3:00'), findsOneWidget);
    });

    testWidgets('should show album when enabled', (tester) async {
      final song = Song(
        id: '1',
        title: 'Test Song',
        artist: 'Test Artist',
        album: 'Test Album',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LibraryProvider>(
              create: (_) => LibraryProvider(subsonicService),
            ),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SongTile(song: song, showArtist: true, showAlbum: true),
            ),
          ),
        ),
      );

      expect(find.textContaining('Test Artist'), findsOneWidget);
      expect(find.textContaining('Test Album'), findsOneWidget);
    });

    testWidgets('歌曲菜单只提供「屏蔽这首歌」，不再出现艺人/专辑屏蔽', (tester) async {
      // 菜单行数较多，默认 800×600 的测试视口会让 sheet 溢出；给足高度。
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final song = Song(
        id: 's1',
        title: 'Test Song',
        artist: 'Test Artist',
        artistId: 'a1',
        album: 'Test Album',
        albumId: 'al1',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => AuthProvider(subsonicService, StorageService()),
            ),
            ChangeNotifierProvider<LibraryProvider>(
              create: (_) => LibraryProvider(subsonicService),
            ),
            ChangeNotifierProvider<PlayerProvider>.value(value: playerProvider),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: SongTile(song: song)),
          ),
        ),
      );

      await tester.tap(find.byIcon(AppIcons.moreV));
      await tester.pumpAndSettle();

      expect(find.text('屏蔽这首歌'), findsOneWidget);
      expect(find.text('屏蔽该艺人'), findsNothing);
      expect(find.text('屏蔽该专辑'), findsNothing);
    });
  });
}
