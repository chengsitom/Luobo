import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/models/server_config.dart';
import 'package:luobo/services/storage_service.dart';
import 'package:luobo/services/subsonic_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SubsonicService', () {
    late SubsonicService service;

    setUp(() {
      service = SubsonicService();
    });

    test('should initialize without configuration', () {
      expect(service.isConfigured, false);
      expect(service.config, isNull);
    });

    test('should configure with ServerConfig', () {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      service.configure(config);

      expect(service.isConfigured, true);
      expect(service.config, isNotNull);
      expect(service.config?.serverUrl, config.serverUrl);
    });

    test('should build cover art URL', () {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      service.configure(config);

      final url = service.getCoverArtUrl('art123', size: 300);

      expect(url, contains('https://demo.navidrome.org/rest/getCoverArt'));
      expect(url, contains('id=art123'));
      expect(url, contains('size=300'));
    });

    test('should return empty URL when coverArt is null', () {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      service.configure(config);

      final url = service.getCoverArtUrl(null);
      expect(url, '');
    });

    test('should build stream URL', () {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      service.configure(config);

      final url = service.getStreamUrl('song123');

      expect(url, contains('https://demo.navidrome.org/rest/stream'));
      expect(url, contains('id=song123'));
    });

    test('should include maxBitRate in stream URL when specified', () {
      final config = ServerConfig(
        serverUrl: 'https://demo.navidrome.org',
        username: 'demo',
        password: 'demo',
      );

      service.configure(config);

      final url = service.getStreamUrl('song123', maxBitRate: 320);

      expect(url, contains('maxBitRate=320'));
    });

    test('should throw when not configured', () {
      expect(() => service.getCoverArtUrl('art123'), returnsNormally);
      expect(() => service.getStreamUrl('song123'), throwsException);
    });

    test('hoistXmlAttributes lifts _attributes into the parent map', () {
      final normalized = SubsonicService.hoistXmlAttributes({
        '_attributes': {'status': 'ok', 'version': '1.16.1'},
        'albumList2': {
          'album': [
            {
              '_attributes': {'id': 'alb_1', 'name': 'Daoliyu Album'},
            },
          ],
        },
      }) as Map<String, dynamic>;

      expect(normalized['status'], 'ok');
      expect(normalized['version'], '1.16.1');
      expect(normalized.containsKey('_attributes'), false);

      final albums = normalized['albumList2']['album'] as List;
      expect(albums.first['id'], 'alb_1');
      expect(albums.first['name'], 'Daoliyu Album');
      expect((albums.first as Map).containsKey('_attributes'), false);
    });

    test('hoistXmlAttributes leaves flat responses untouched', () {
      final normalized = SubsonicService.hoistXmlAttributes({
        'status': 'ok',
        'artists': {
          'index': [
            {'name': 'A', 'albumCount': 5},
          ],
        },
      }) as Map<String, dynamic>;

      expect(normalized['status'], 'ok');
      expect((normalized['artists']['index'] as List).first['albumCount'], 5);
    });

    group('resolveActiveUrl', () {
      // Port 1 on loopback refuses connections instantly on every platform, so
      // the LAN probe fails fast without hitting a real server.
      const probeUrl = 'http://127.0.0.1:1';
      const remoteUrl = 'https://demo.navidrome.org';

      test('persists last active URL when no local URL configured', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        final svc = SubsonicService(storageService: storage);
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          username: 'demo',
          password: 'demo',
        ));

        await svc.resolveActiveUrl();

        expect(svc.activeBaseUrl, remoteUrl);
        expect(await storage.getLastActiveBaseUrl(), remoteUrl);
      });

      test('skips LAN probe when last session ended on remote', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.saveLastActiveBaseUrl(remoteUrl);
        final svc = SubsonicService(storageService: storage);
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          localUrl: probeUrl,
          username: 'demo',
          password: 'demo',
        ));

        await svc.resolveActiveUrl();

        // Remote used immediately; the background probe (unreachable port)
        // must not switch the active URL.
        expect(svc.activeBaseUrl, remoteUrl);
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(svc.activeBaseUrl, remoteUrl);
      });

      test('falls back to remote and persists when LAN probe fails', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        final svc = SubsonicService(storageService: storage);
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          localUrl: probeUrl,
          username: 'demo',
          password: 'demo',
        ));

        await svc.resolveActiveUrl();

        expect(svc.activeBaseUrl, remoteUrl);
        expect(await storage.getLastActiveBaseUrl(), remoteUrl);
      });

      test('forceProbe ignores last-active skip and probes LAN synchronously',
          () async {
        // 本地 HTTP 服务模拟可达的局域网端点。
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((req) => req.response
          ..statusCode = 200
          ..close());
        addTearDown(() => server.close(force: true));
        final lanUrl = 'http://127.0.0.1:${server.port}';

        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        // 上次会话在远端 → 普通调用会 skip 探测；forceProbe 必须无视它。
        await storage.saveLastActiveBaseUrl(remoteUrl);
        final svc = SubsonicService(storageService: storage);
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          localUrl: lanUrl,
          username: 'demo',
          password: 'demo',
        ));

        await svc.resolveActiveUrl(forceProbe: true);

        expect(svc.activeBaseUrl, lanUrl);
        expect(await storage.getLastActiveBaseUrl(), lanUrl);
      });

      test('notifies onActiveUrlChanged only when the active URL changes',
          () async {
        SharedPreferences.setMockInitialValues({});
        final svc = SubsonicService();
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          username: 'demo',
          password: 'demo',
        ));
        var notifications = 0;
        svc.onActiveUrlChanged = () => notifications++;

        await svc.resolveActiveUrl();
        expect(svc.activeBaseUrl, remoteUrl);
        expect(notifications, 1); // null → remote

        // 同一地址重复解析不得重复通知（转码层只随实际切换刷新）。
        await svc.resolveActiveUrl();
        expect(notifications, 1);
      });

      test('notifies when the LAN probe switches the active URL', () async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        server.listen((req) => req.response
          ..statusCode = 200
          ..close());
        addTearDown(() => server.close(force: true));
        final lanUrl = 'http://127.0.0.1:${server.port}';

        SharedPreferences.setMockInitialValues({});
        final storage = StorageService();
        await storage.saveLastActiveBaseUrl(remoteUrl);
        final svc = SubsonicService(storageService: storage);
        svc.configure(ServerConfig(
          serverUrl: remoteUrl,
          localUrl: lanUrl,
          username: 'demo',
          password: 'demo',
        ));
        var notifications = 0;
        svc.onActiveUrlChanged = () => notifications++;

        await svc.resolveActiveUrl(forceProbe: true);

        expect(svc.activeBaseUrl, lanUrl);
        expect(notifications, 1); // null → LAN（一次切换一次通知）
      });
    });
  });
}
