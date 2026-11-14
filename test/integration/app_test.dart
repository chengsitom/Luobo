import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luobo/main.dart';
import 'package:luobo/providers/auth_provider.dart';
import 'package:luobo/services/services.dart';
import '../bootstrap.dart';

void main() {
  initializeTestEnvironment();
  group('Musly App Integration Tests', () {
    testWidgets('should display login screen when not authenticated', (
      tester,
    ) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pump();
      await tester.pump(); // 等待已保存配置的 FutureBuilder 解析

      expect(find.text('Luobo'), findsWidgets);
      expect(find.text('Connect to your Daoliyu server'), findsOneWidget);
    });

    testWidgets('should have login form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pump();
      await tester.pump(); // 等待已保存配置的 FutureBuilder 解析

      // 网关页 → 点「Add Server」直接进入表单。
      // 方案 A 登录收口后已删除「选服务器类型」的类型网格中间步。
      await tester.tap(find.text('Add Server'));
      await tester.pumpAndSettle();

      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);
    });

    testWidgets('should validate empty form fields', (tester) async {
      final storageService = StorageService();
      final subsonicService = SubsonicService();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<StorageService>.value(value: storageService),
            Provider<SubsonicService>.value(value: subsonicService),
            ChangeNotifierProvider<LocaleService>(
                create: (_) => LocaleService()),
            ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
            ChangeNotifierProvider(
              create: (_) => AuthProvider(subsonicService, storageService),
            ),
          ],
          child: const MaterialApp(home: MuslyApp()),
        ),
      );

      await tester.pump();
      await tester.pump(); // 等待已保存配置的 FutureBuilder 解析

      await tester.tap(find.text('Add Server'));
      await tester.pumpAndSettle();

      // 方案 A 收口后 Add Server 直达表单，直接校验空字段。
      final connectButton = find.text('Connect');
      await tester.ensureVisible(connectButton);
      await tester.tap(connectButton);
      await tester.pump();

      expect(find.text('Please enter server URL'), findsOneWidget);
      expect(find.text('Please enter username'), findsOneWidget);
      expect(find.text('Please enter password'), findsOneWidget);
    });
  });
}
