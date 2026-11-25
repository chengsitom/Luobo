import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/l10n/app_localizations.dart';
import 'package:luobo/models/song.dart';
import 'package:luobo/providers/library_provider.dart';
import 'package:luobo/providers/player_provider.dart';
import 'package:luobo/screens/search_screen.dart';
import 'package:luobo/services/audio_handler.dart';
import 'package:luobo/services/player_ui_settings_service.dart';
import 'package:luobo/services/storage_service.dart';
import 'package:luobo/services/subsonic_service.dart';
import 'package:luobo/services/transcoding_service.dart';
import 'package:luobo/services/upnp_service.dart';
import 'package:luobo/widgets/load_error_view.dart';
import 'package:provider/provider.dart';

import '../bootstrap.dart';
import '../test_helpers.dart';

/// 可控搜索：按 query 返回带唯一标记的歌曲，并可人为挂起。
class FakeLibraryProvider extends LibraryProvider {
  final Map<String, SearchResult Function()> responders = {};
  final Map<String, Completer<SearchResult>> pending = {};
  final List<String> calls = [];

  FakeLibraryProvider(super.service);

  void respond(String q, SearchResult Function() build) => responders[q] = build;

  @override
  Future<SearchResult> search(String query) async {
    calls.add(query);
    final completer = pending[query];
    if (completer != null) return completer.future;
    final build = responders[query];
    if (build != null) return build();
    return SearchResult(artists: [], albums: [], songs: []);
  }
}

SearchResult _resultWithSong(String title) => SearchResult(
      artists: const [],
      albums: const [],
      songs: [
        Song(
          id: title,
          title: title,
          artist: 'Artist',
          album: 'Album',
          duration: 180,
        ),
      ],
    );

Widget _buildApp(FakeLibraryProvider library, SubsonicService service) {
  return MultiProvider(
    providers: [
      Provider<SubsonicService>.value(value: service),
      Provider<StorageService>.value(value: StorageService()),
      ChangeNotifierProvider<LibraryProvider>.value(value: library),
      ChangeNotifierProvider<PlayerProvider>(
        create: (_) => PlayerProvider(
          service,
          StorageService(),
          FakeCastService(),
          UpnpService(),
          MuslyAudioHandler(),
          TranscodingService(),
        ),
      ),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: SearchScreen(autoFocus: false),
    ),
  );
}

/// 直接改 controller.text（只触发一次 onChanged），模拟用户在已有结果后继续输入，
/// 避开 tester.enterText 先清空再输入带来的「清空→重新搜」中间态。
Future<void> _typeWithoutClear(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.pump();
}

Future<void> _settle(WidgetTester tester) async {
  // LinearProgressIndicator 有无限动画，pumpAndSettle 不会收敛；用固定帧推进。
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 60));
  }
}

void main() {
  initializeTestEnvironment();

  setUp(() async {
    await PlayerUiSettingsService().initialize();
    await PlayerUiSettingsService().setLiveSearch(true);
  });

  testWidgets('实时搜索：已有结果后继续输入，结果页保持可见（不闪没）', (tester) async {
    final service = SubsonicService();
    final library = FakeLibraryProvider(service);
    library.respond('第一首', () => _resultWithSong('第一首'));
    // 新一轮搜索挂起，制造「在途」状态。
    final pending = Completer<SearchResult>();
    library.pending['第二首'] = pending;

    await tester.pumpWidget(_buildApp(library, service));

    // 首次搜索：立即出结果。
    await _typeWithoutClear(tester, '第一首');
    await _settle(tester);
    expect(find.text('第一首'), findsWidgets, reason: '首次搜索应显示结果');

    // 继续输入触发新一轮搜索，但结果尚未返回——旧结果必须还在。
    await _typeWithoutClear(tester, '第二首');
    // 推进 350ms 让 300ms 防抖触发 _search('第二首')。
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    expect(
      find.text('第一首'),
      findsWidgets,
      reason: '新搜索在途时旧结果应保持可见，不能被骨架屏替换而闪没',
    );

    // 收尾：让挂起的请求完成，避免 pending future。
    pending.complete(_resultWithSong('第二首'));
    await _settle(tester);
    expect(find.text('第二首'), findsWidgets, reason: '新结果返回后应展示');
  });

  testWidgets('实时搜索：旧请求晚返回不会覆盖新结果', (tester) async {
    final service = SubsonicService();
    final library = FakeLibraryProvider(service);

    final slow = Completer<SearchResult>();
    library.pending['旧词'] = slow;
    library.respond('新词', () => _resultWithSong('新结果'));

    await tester.pumpWidget(_buildApp(library, service));

    // 首搜挂起 → 再输入新词。
    await _typeWithoutClear(tester, '旧词');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    await _typeWithoutClear(tester, '新词');
    await _settle(tester);
    expect(find.text('新结果'), findsWidgets, reason: '新结果应正常展示');

    // 旧请求此刻才返回：序号守卫应丢弃，不能覆盖新结果。
    if (!slow.isCompleted) slow.complete(_resultWithSong('旧结果'));
    await _settle(tester);
    expect(find.text('新结果'), findsWidgets, reason: '旧请求晚返回不得覆盖新结果');
    expect(find.text('旧结果'), findsNothing, reason: '旧请求结果不应出现');
  });

  testWidgets('网络失败：搜索结果页显示错误态与重试，而不是闪回历史页', (tester) async {
    final service = SubsonicService();
    final library = FakeLibraryProvider(service);
    final failing = Completer<SearchResult>();
    library.pending['断网词'] = failing;

    await tester.pumpWidget(_buildApp(library, service));

    await _typeWithoutClear(tester, '断网词');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();

    // 网络失败：请求抛错。
    failing.completeError(Exception('SocketException: Network unreachable'));
    await _settle(tester);

    expect(
      find.byType(LoadErrorView),
      findsOneWidget,
      reason: '网络失败应展示错误态 + 重试，而不是掉回历史页（结果页一闪就没）',
    );
    expect(
      AppLocalizations.of(tester.element(find.byType(LoadErrorView)))!.retry,
      isNotEmpty,
    );

    // 收尾：清理异常 future，避免测试报未处理异常。
    await tester.pump();
  });

  testWidgets('输入后立刻回车提交：只发一次请求（防抖被撤销，不会重复搜）', (tester) async {
    final service = SubsonicService();
    final library = FakeLibraryProvider(service);
    library.respond('提交词', () => _resultWithSong('提交结果'));

    await tester.pumpWidget(_buildApp(library, service));

    // 输入触发 300ms 防抖排队，随即按搜索键提交。
    await _typeWithoutClear(tester, '提交词');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await _settle(tester);

    // 提交时若未撤销防抖，300ms 后 Timer 会对同一 query 再搜一次 → 2 次。
    expect(
      library.calls.where((q) => q == '提交词').length,
      1,
      reason: '回车提交应撤销已排队的防抖，同一 query 只发一次请求',
    );
    expect(find.text('提交结果'), findsWidgets, reason: '提交应正常出结果');
  });
}
