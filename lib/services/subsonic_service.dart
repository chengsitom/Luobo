import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:uuid/uuid.dart';
import '../models/json_coerce.dart';
import '../models/models.dart';
import 'diagnostics/diagnostics.dart';
import 'jellyfin_service.dart';
import 'lyrics/lrc_parser.dart';
import 'storage_service.dart';
import 'youtube_service.dart';

class PingResult {
  final bool success;
  final String? error;
  final String? serverType;
  final String? serverVersion;

  PingResult({
    required this.success,
    this.error,
    this.serverType,
    this.serverVersion,
  });
}

class SubsonicService {
  Dio _dio;
  ServerConfig? _config;
  JellyfinService? _jellyfin;
  YoutubeService? _youtube;
  String? _activeBaseUrl;
  final StorageService? _storageService;

  // ── 道理鱼自研 /api 层 JWT 通道 ─────────────────────────────────────────
  // 道理鱼除 Subsonic 兼容层外，还有一套自研 JSON API（/api/*），需要
  // Bearer JWT。歌词/随机歌等能力走这一层（见 getLyricsBySongId /
  // getRandomSongs 的 daoliyu 分支）。
  String? _apiJwt;
  bool _apiLoginFailed = false;

  /// 最近一次 loginToApi 拿到的 userId（道理鱼 /api/auth/login 响应 user.id）。
  String? _apiUserId;

  /// 进行中的 loginToApi Future：并发去重，多个 _apiGet 同时触发时只发一次登录。
  Future<bool>? _loginInFlight;

  /// Notified whenever [_activeBaseUrl] actually changes (LAN↔remote switch
  /// during startup / background probe / network-change re-probe, or config
  /// reset). Wired in main.dart to refresh the transcoding LAN override.
  void Function()? onActiveUrlChanged;

  static const String _clientName = 'Musly';
  static const String _apiVersion = '1.16.1';

  SubsonicService({StorageService? storageService})
      : _storageService = storageService,
        _dio = Dio() {
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _addLogInterceptor(_dio);
  }

  void _addLogInterceptor(Dio dio) {
    dio.interceptors.add(networkMetricsInterceptor(
      logLine: (line) => Log.i('Net', line),
    ));
  }

  Future<void> configure(ServerConfig config) async {
    _config = config;
    _apiJwt = null;
    _apiLoginFailed = false;
    _apiUserId = null;
    _loginInFlight = null; // 丢弃进行中的登录（旧服务器凭据/地址已失效）
    _setActiveBaseUrl(null);
    if (config.isJellyfin) {
      _jellyfin ??= JellyfinService();
      _jellyfin!.configure(config);
      _youtube?.dispose();
      _youtube = null;
      // } else if (config.serverFamily == 'youtube') {
      //   _youtube ??= YoutubeService();
      //   _jellyfin = null;
    } else {
      _jellyfin = null;
      _youtube?.dispose();
      _youtube = null;
      await _configureCertificateValidation(
        config.allowSelfSignedCertificates,
        customCertPath: config.customCertificatePath,
        clientCertPath: config.clientCertificatePath,
        clientCertPassword: config.clientCertificatePassword,
      );
    }
  }

  /// Assigns [_activeBaseUrl] and notifies [onActiveUrlChanged] only when the
  /// value actually changes, so listeners (transcoding LAN override) refresh
  /// exactly once per LAN↔remote switch.
  void _setActiveBaseUrl(String? url) {
    if (url == _activeBaseUrl) return;
    _activeBaseUrl = url;
    // LAN↔远程切换：自研 /api 层 JWT 与地址绑定，切换后需按新地址重新登录。
    _apiJwt = null;
    _apiLoginFailed = false;
    onActiveUrlChanged?.call();
  }

  /// Probes the local URL; if reachable, uses it. Otherwise falls back to the
  /// remote (serverUrl). Call this after [configure] and before making requests.
  ///
  /// The last successfully resolved URL is persisted so cold start doesn't
  /// stall up to 3s probing a LAN that is not reachable: when the previous
  /// session ended on the remote URL, the probe is skipped and the LAN is
  /// re-probed in the background, switching silently once it responds.
  ///
  /// Pass [forceProbe] to always probe the LAN synchronously, ignoring the
  /// persisted last-active hint. Used when the network changed or after a
  /// ping failure to re-evaluate the reachable address.
  Future<void> resolveActiveUrl({bool forceProbe = false}) async {
    if (_config == null) return;
    final localUrl = _config!.normalizedLocalUrl;
    if (localUrl == null) {
      _setActiveBaseUrl(_config!.normalizedUrl);
      Log.i('Net', 'No local URL configured, using remote: $_activeBaseUrl');
      DiagnosticsService.instance.record(
        EventType.netUrlResolved,
        LogLevel.info,
        {'host': _activeBaseUrl, 'switched': false},
      );
      await _persistLastActiveBaseUrl();
      return;
    }

    // Last session ended on the remote URL — use it immediately and probe the
    // LAN in the background instead of blocking startup (unless forceProbe).
    final lastActive = await _storageService?.getLastActiveBaseUrl();
    if (!forceProbe &&
        lastActive != null &&
        lastActive == _config!.normalizedUrl) {
      _setActiveBaseUrl(_config!.normalizedUrl);
      Log.i(
          'Net', 'Last session on remote, skipping LAN probe: $_activeBaseUrl');
      DiagnosticsService.instance.record(
        EventType.netUrlResolved,
        LogLevel.info,
        {'host': _activeBaseUrl, 'switched': false, 'skipProbe': true},
      );
      await _persistLastActiveBaseUrl();
      unawaited(_probeLocalUrlInBackground(localUrl));
      return;
    }

    // First run, or the last session was on the LAN — probe the LAN first.
    final probe = await _probeLocalUrl(localUrl);
    if (probe.ok) {
      final switched = _activeBaseUrl != localUrl;
      _setActiveBaseUrl(localUrl);
      DiagnosticsService.instance.record(
        EventType.netUrlResolved,
        LogLevel.info,
        {
          'host': _activeBaseUrl,
          'probeMs': probe.ms,
          'switched': switched,
        },
      );
      Log.i('Net', 'LAN URL reachable, using: $_activeBaseUrl');
      await _persistLastActiveBaseUrl();
      return;
    }

    final switched = _activeBaseUrl != _config!.normalizedUrl;
    _setActiveBaseUrl(_config!.normalizedUrl);
    DiagnosticsService.instance.record(
      EventType.netUrlResolved,
      LogLevel.info,
      {'host': _activeBaseUrl, 'switched': switched},
    );
    Log.i('Net', 'Falling back to remote URL: $_activeBaseUrl');
    await _persistLastActiveBaseUrl();
  }

  /// Pings the local URL with a short timeout. Returns whether the LAN
  /// endpoint responded 200, plus the probe duration in ms.
  Future<({bool ok, int ms})> _probeLocalUrl(String localUrl) async {
    try {
      final params = _getAuthParams();
      final queryString = params.entries
          .map((e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
          .join('&');
      final pingUrl = '$localUrl/rest/ping?$queryString';
      final probeDio = Dio();
      probeDio.options.connectTimeout = const Duration(seconds: 3);
      probeDio.options.receiveTimeout = const Duration(seconds: 3);
      probeDio.options.sendTimeout = const Duration(seconds: 3);
      final probeSw = Stopwatch()..start();
      final response = await probeDio.get(pingUrl);
      probeSw.stop();
      return (ok: response.statusCode == 200, ms: probeSw.elapsedMilliseconds);
    } catch (e) {
      Log.w('Net', 'LAN URL probe failed', error: e);
      return (ok: false, ms: 0);
    }
  }

  /// Background LAN probe after a skipped startup probe: switches the active
  /// base URL (and persists it) once the LAN becomes reachable.
  Future<void> _probeLocalUrlInBackground(String localUrl) async {
    final probe = await _probeLocalUrl(localUrl);
    if (!probe.ok || _config == null) return;
    final switched = _activeBaseUrl != localUrl;
    _setActiveBaseUrl(localUrl);
    DiagnosticsService.instance.record(
      EventType.netUrlResolved,
      LogLevel.info,
      {
        'host': _activeBaseUrl,
        'probeMs': probe.ms,
        'switched': switched,
        'background': true,
      },
    );
    Log.i('Net', 'LAN URL reachable (background), using: $_activeBaseUrl');
    await _persistLastActiveBaseUrl();
  }

  Future<void> _persistLastActiveBaseUrl() async {
    final base = _activeBaseUrl;
    if (base == null) return;
    try {
      await _storageService?.saveLastActiveBaseUrl(base);
    } catch (e) {
      Log.w('Net', 'Failed to persist last active URL', error: e);
    }
  }

  String get activeBaseUrl => _activeBaseUrl ?? _config?.normalizedUrl ?? '';

  /// Whether the active connection is using the LAN (local) URL rather than
  /// the remote server URL.  Only meaningful when the user configured both
  /// addresses.
  ///
  /// Jellyfin always resolves its base URL to serverUrl (jellyfin_service
  /// configure), so the LAN probe never affects its actual traffic — treating
  /// it as LAN would force original streams over the WAN path (rule 1
  /// mismatch), so it is excluded here.
  bool get isUsingLocalUrl {
    if (_jellyfin != null) return false;
    if (_config == null || _config!.normalizedLocalUrl == null) return false;
    final base = _activeBaseUrl ?? _config!.normalizedUrl;
    return base.isNotEmpty && base == _config!.normalizedLocalUrl;
  }

  /// Whether the current server config includes a LAN (local) URL.
  bool get hasLocalUrl =>
      _config?.normalizedLocalUrl != null &&
      _config!.normalizedLocalUrl!.isNotEmpty;

  bool get isYoutube => _youtube != null;
  bool get isJellyfin => _jellyfin != null;

  /// For YouTube songs, returns a pre-warmed [StreamAudioSource] that proxies
  /// audio through youtube_explode_dart's HTTP client (avoids ExoPlayer's 403).
  /// Returns null for Subsonic / Jellyfin (use [resolveStreamUrlAsync]).
  Future<StreamAudioSource?> getYoutubeAudioSource(Song song) async {
    if (_youtube != null) return _youtube!.buildAudioSource(song.id);
    return null;
  }

  /// Resolves the playable URL for [song]. For YouTube this calls the async
  /// manifest extraction; for other families it returns the pre-built URL.
  Future<String> resolveStreamUrlAsync(Song song) async {
    if (_youtube != null) {
      return _youtube!.resolveStreamUrl(song.id);
    }
    return getStreamUrl(song.id);
  }

  Future<void> _configureCertificateValidation(
    bool allowSelfSigned, {
    String? customCertPath,
    String? clientCertPath,
    String? clientCertPassword,
  }) async {
    _dio = Dio();
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _addLogInterceptor(_dio);

    final hasCustomServerCert =
        customCertPath != null && customCertPath.isNotEmpty;
    final hasClientCert = clientCertPath != null && clientCertPath.isNotEmpty;

    if (hasCustomServerCert || allowSelfSigned || hasClientCert) {
      // Pre-load certificate files asynchronously to avoid blocking UI
      Uint8List? customServerCertBytes;
      Uint8List? clientCertBytes;

      if (hasCustomServerCert) {
        try {
          final file = File(customCertPath);
          if (await file.exists()) {
            customServerCertBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Failed to load custom server certificate: $e');
        }
      }

      if (hasClientCert) {
        try {
          final file = File(clientCertPath);
          if (await file.exists()) {
            clientCertBytes = await file.readAsBytes();
          }
        } catch (e) {
          debugPrint('Failed to load client certificate: $e');
        }
      }

      HttpClient createClient() {
        HttpClient buildClient(SecurityContext context) {
          return HttpOverrides.runWithHttpOverrides(() {
            final client = HttpClient(context: context);
            client.connectionTimeout = const Duration(seconds: 15);
            client.idleTimeout = const Duration(seconds: 15);
            if (allowSelfSigned) {
              client.badCertificateCallback = (cert, host, port) => true;
            }
            return client;
          }, _RealHttpOverrides());
        }

        try {
          final context = SecurityContext(withTrustedRoots: true);

          if (hasCustomServerCert && customServerCertBytes != null) {
            context.setTrustedCertificatesBytes(customServerCertBytes);
          }

          if (hasClientCert && clientCertBytes != null) {
            final password = clientCertPassword;

            context.useCertificateChainBytes(clientCertBytes,
                password: password);

            context.usePrivateKeyBytes(clientCertBytes, password: password);
          }

          return buildClient(context);
        } catch (e) {
          debugPrint('Failed to configure TLS: $e');
          return buildClient(SecurityContext(withTrustedRoots: true));
        }
      }

      HttpOverrides.global = _TlsHttpOverrides(createClient);

      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          createClient;
    } else {
      HttpOverrides.global = null;
    }
  }

  ServerConfig? get config => _config;

  bool get isConfigured => _config != null && _config!.isValid;

  /// Whether the configured server is 道理鱼 (daoliyu family). Gates the
  /// self-layer /api branches (lyrics / random / genres) so Navidrome and
  /// other Subsonic servers are completely unaffected.
  bool get isDaoliyu => _config?.serverFamily == 'daoliyu';

  /// The 道理鱼 JWT from the last successful /api/auth/login (null if not
  /// logged in yet). Persisted into ServerConfig.apiToken by AuthProvider.
  String? get apiJwtOrNull => _apiJwt;

  /// The 道理鱼 userId from the last successful /api/auth/login.
  String? get apiUserId => _apiUserId;

  /// Logs into the 道理鱼 self-layer API and caches the JWT.
  ///
  /// - 并发安全：进行中的登录 Future 会被复用（_loginInFlight），多个调用
  ///   同时触发只发一次 login 请求。
  /// - 错误分类：凭据无效 / 响应结构异常 → 永久标记失败（_apiLoginFailed），
  ///   避免每首歌重复尝试；网络/超时等瞬时错误 → 不标记，下次请求可重试
  ///   （否则一次网络抖动会导致整个会话的歌词/随机歌永久降级）。
  /// - 成功/失败均不影响 Subsonic 层（浏览/播放走 Subsonic 兼容层）。
  Future<bool> loginToApi() async {
    if (_apiJwt != null) return true;
    if (_apiLoginFailed) return false;
    if (_config == null) return false;
    // 并发去重：已有进行中的登录则直接复用其结果。
    final inFlight = _loginInFlight;
    if (inFlight != null) return inFlight;
    final future = _performApiLogin();
    _loginInFlight = future;
    try {
      return await future;
    } finally {
      if (identical(_loginInFlight, future)) _loginInFlight = null;
    }
  }

  Future<bool> _performApiLogin() async {
    try {
      final resp = await _dio.post(
        '$activeBaseUrl/api/auth/login',
        data: {'username': _config!.username, 'password': _config!.password},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      final data = resp.data as Map<String, dynamic>;
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        // 结构异常（非预期响应）→ 永久失败
        _apiLoginFailed = true;
        return false;
      }
      _apiJwt = token;
      final user = data['user'] as Map<String, dynamic>?;
      _apiUserId = user?['id'] as String?;
      _apiLoginFailed = false;
      Log.i('Daoliyu', 'API login OK (user=${_apiUserId})');
      return true;
    } on DioException catch (e) {
      // 401 = 凭据无效 → 永久失败；其它（网络/超时/5xx）→ 可重试。
      if (e.response?.statusCode == 401) {
        _apiLoginFailed = true;
      }
      Log.w('Daoliyu', 'API login failed: $e');
      return false;
    } catch (e) {
      // 响应结构解析异常 → 永久失败（换凭据才有意义）
      _apiLoginFailed = true;
      Log.w('Daoliyu', 'API login parse failed: $e');
      return false;
    }
  }

  /// GET the 道理鱼 self-layer API with Bearer auth.
  ///
  /// JWT 过期（401）时重登一次再重试；仍失败返回 null（调用方走降级）。
  Future<Map<String, dynamic>?> _apiGet(String path) async {
    if (!await loginToApi()) return null;
    try {
      final resp = await _dio.get(
        '$activeBaseUrl$path',
        options: Options(headers: {'Authorization': 'Bearer $_apiJwt'}),
      );
      return resp.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _apiJwt = null;
        _apiLoginFailed = false;
        if (await loginToApi()) {
          try {
            final retry = await _dio.get(
              '$activeBaseUrl$path',
              options: Options(headers: {'Authorization': 'Bearer $_apiJwt'}),
            );
            return retry.data as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, String> _getAuthParams() {
    if (_config == null) throw Exception('Server not configured');

    final params = <String, String>{
      'u': _config!.username,
      'v': _apiVersion,
      'c': _clientName,
      'f': 'json',
    };

    if (_config!.useLegacyAuth) {
      params['p'] = _config!.password;
    } else {
      final salt = const Uuid().v4().substring(0, 8);
      final token =
          md5.convert(utf8.encode('${_config!.password}$salt')).toString();
      params['t'] = token;
      params['s'] = salt;
    }

    return params;
  }

  Map<String, String>? _stableAuthParams;

  void _ensureStableAuthParams() {
    if (_stableAuthParams != null) return;
    if (_config == null) return;

    final params = <String, String>{
      'u': _config!.username,
      'v': _apiVersion,
      'c': _clientName,
      'f': 'json',
    };

    if (_config!.useLegacyAuth) {
      params['p'] = _config!.password;
    } else {
      const salt = 'musly_stable';
      final token =
          md5.convert(utf8.encode('${_config!.password}$salt')).toString();
      params['t'] = token;
      params['s'] = salt;
    }
    _stableAuthParams = params;
  }

  String _buildUrl(String endpoint, [Map<String, String>? extraParams]) {
    if (_config == null) throw Exception('Server not configured');

    final params = _getAuthParams();
    if (extraParams != null) {
      params.addAll(extraParams);
    }

    if (_config!.selectedMusicFolderIds.isNotEmpty) {
      params['musicFolderId'] = _config!.selectedMusicFolderIds.first;
    }

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '$activeBaseUrl/rest/$endpoint?$queryString';
  }

  /// 把 XML→JSON 直转服务端（daoliyu）的 `_attributes` 子对象提升到父层。
  ///
  /// daoliyu 的 Subsonic 兼容层把所有「XML 属性」塞进 `_attributes` 里
  /// （`{"subsonic-response":{"_attributes":{"status":"ok"},
  /// "albumList2":{"album":[{"_attributes":{"id":"alb_1"}}]}}}`），
  /// 而 Navidrome 等是平铺的。不归一化会让 `Album/Song/Artist.fromJson`
  /// 全部拿到空 id 与 `Unknown Album`，表现为「接口全 200 但没有任何数据」。
  /// 无 `_attributes` 时结构原样返回，因此对其他服务端零影响。
  @visibleForTesting
  static dynamic hoistXmlAttributes(dynamic node) => _hoistXmlAttributes(node);

  static dynamic _hoistXmlAttributes(dynamic node) {
    if (node is List) return node.map(_hoistXmlAttributes).toList();
    if (node is! Map) return node;

    final children = Map<String, dynamic>.from(node);
    final attrs = children.remove('_attributes');
    final result = <String, dynamic>{};
    if (attrs is Map) {
      attrs.forEach((key, value) => result[key.toString()] = value);
    }
    // 子元素后写，父层同名键优先，避免属性覆盖真正的子节点。
    children.forEach(
      (key, value) => result[key.toString()] = _hoistXmlAttributes(value),
    );
    return result;
  }

  /// XML→JSON 直转的服务端在列表只剩 1 个元素时会返回 Map 而非 List
  /// （search3 早就为此做过局部兼容）。统一收敛成 List，避免 `is List`
  /// 守卫把单条结果静默丢成空列表。模型层用同一个 `jsonList`。
  static List<dynamic> _asList(dynamic node) => jsonList(node);

  /// 解码 → `_attributes` 归一化 → status 校验。`_request` 与自建 URL 的写
  /// 操作（createPlaylist/updatePlaylist）共用，避免归一化只覆盖部分路径。
  Map<String, dynamic> _decodeSubsonic(dynamic raw) {
    final data = raw is String ? json.decode(raw) : raw;

    final subsonicResponse = data is Map ? data['subsonic-response'] : null;
    if (subsonicResponse == null) {
      throw Exception('Invalid response format');
    }

    final normalized = _hoistXmlAttributes(subsonicResponse);
    if (normalized is! Map<String, dynamic>) {
      throw Exception('Invalid response format');
    }

    if (normalized['status'] != 'ok') {
      final error = normalized['error'];
      final message = error is Map ? error['message'] : null;
      throw Exception(message ?? 'Unknown error');
    }

    return normalized;
  }

  Future<Map<String, dynamic>> _request(
    String endpoint, [
    Map<String, String>? params,
  ]) async {
    final url = _buildUrl(endpoint, params);

    try {
      final response = await _dio.get(url);
      return _decodeSubsonic(response.data);
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          throw Exception('Connection timed out. Check your server URL.');
        case DioExceptionType.connectionError:
          final cause = e.error?.toString() ?? '';
          if (cause.contains('HandshakeException') ||
              cause.contains('CERTIFICATE_VERIFY_FAILED') ||
              cause.contains('SSL')) {
            throw Exception(
                'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.');
          }
          throw Exception(
              'Cannot connect to server. Check the URL and your internet connection.');
        case DioExceptionType.badResponse:
          final status = e.response?.statusCode;
          if (status == 401 || status == 403)
            throw Exception('Invalid username or password.');
          if (status == 404)
            throw Exception('Server not found. Check your URL path.');
          if (status != null && status >= 500)
            throw Exception(
                'Server error ($status). The server failed to process the request.');
          throw Exception('Request failed (HTTP $status).');
        default:
          throw Exception('Network error. Check your connection.');
      }
    }
  }

  Future<bool> ping() async {
    try {
      await _request('ping');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PingResult> pingWithError() async {
    if (_jellyfin != null) return _jellyfin!.pingWithError();
    if (_youtube != null) return _youtube!.pingWithError();
    try {
      final response = await _request('ping');
      return PingResult(
        success: true,
        serverType: response['type']?.toString(),
        serverVersion: response['serverVersion']?.toString(),
      );
    } catch (e) {
      return PingResult(success: false, error: e.toString());
    }
  }

  Future<List<MusicFolder>> getMusicFolders() async {
    try {
      final response = await _request('getMusicFolders');
      final folders = <MusicFolder>[];

      final foldersData = _asList(response['musicFolders']?['musicFolder']);
      folders.addAll(
        foldersData.whereType<Map>().map(
              (f) => MusicFolder.fromJson(Map<String, dynamic>.from(f)),
            ),
      );

      return folders;
    } catch (e) {
      return [];
    }
  }

  /// Returns a cover-art URL. All callers share the same [size] so
  /// `cached_network_image` hits the same disk-cache entry regardless of
  /// context (list, player, full-screen), avoiding duplicate downloads.
  String getCoverArtUrl(String? coverArt, {int size = 600}) {
    if (_jellyfin != null)
      return _jellyfin!.getCoverArtUrl(coverArt, size: size);
    if (_youtube != null) return _youtube!.getCoverArtUrl(coverArt, size: size);
    if (coverArt == null || _config == null) {
      return '';
    }
    // 绝对 URL 防护：持久化队列/歌单里的 coverArt 可能是旧服务器的绝对 URL
    // （如 Navidrome share/img/eyJ...）。host 与当前服务器一致才原样返回
    // （LAN↔远程同服可命中），不一致（旧服务器）返回空 → 占位图，
    // 不再把跨服请求外发（诊断日志 confirmed share/img 404）。
    if (coverArt.startsWith('http://') || coverArt.startsWith('https://')) {
      try {
        final coverHost = Uri.parse(coverArt).host;
        final activeHost = Uri.parse(activeBaseUrl).host;
        return coverHost == activeHost ? coverArt : '';
      } catch (_) {
        return '';
      }
    }
    _ensureStableAuthParams();

    final params = Map<String, String>.from(
      _stableAuthParams ?? _getAuthParams(),
    );
    params['id'] = coverArt;
    if (size > 0) {
      params['size'] = size.toString();
    }

    if (_config!.selectedMusicFolderIds.isNotEmpty) {
      params['musicFolderId'] = _config!.selectedMusicFolderIds.first;
    }

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '$activeBaseUrl/rest/getCoverArt?$queryString';
  }

  /// Stable per-(server, account) scope for the semantic cover-cache key
  /// (`coverArt-<serverId>-<id>-<size>`). Excludes the password so changing
  /// it doesn't invalidate cached covers; LAN/remote host switching is absorbed
  /// because the id stays the same across hosts of the same server.
  String get coverCacheServerId {
    final base = _activeBaseUrl ?? _config?.normalizedUrl ?? '';
    final user = _config?.username ?? '';
    if (base.isEmpty || user.isEmpty) return '';
    return md5.convert(utf8.encode('$base|$user')).toString();
  }

  String getStreamUrl(String songId, {int? maxBitRate, String? format}) {
    if (_jellyfin != null)
      return _jellyfin!
          .getStreamUrl(songId, maxBitRate: maxBitRate, format: format);
    if (_youtube != null) return _youtube!.getStreamUrl(songId);
    final params = <String, String>{'id': songId};
    if (isDaoliyu) {
      // 道理鱼 Subsonic 兼容层：
      // - 无转码参数时默认会转码 AAC 192k（chunked 无 Content-Length，
      //   ExoPlayer 解析不出时长 → 拖动进度条后从 0:00 重播）。LAN/无损场景
      //   必须显式 format=raw 直出，才有 Content-Length + Range 可精确 seek。
      // - 明确请求转码（maxBitRate/format）时透传转码参数；转码流不支持
      //   Range，seek 由 PlayerProvider 走自研 /api/tracks/{id}/stream
      //   的 timeOffset 重起流（见 getDaoliyuApiStreamUrl，2026-08-11 WebUI 实测）。
      if (maxBitRate == null && format == null) {
        params['format'] = 'raw';
      } else {
        if (maxBitRate != null) {
          params['maxBitRate'] = maxBitRate.toString();
        }
        if (format != null) {
          params['format'] = format;
        }
      }
    } else {
      if (maxBitRate != null) {
        params['maxBitRate'] = maxBitRate.toString();
      }
      if (format != null) {
        params['format'] = format;
      }
      // Ask Navidrome (and other OpenSubsonic servers) to estimate the
      // Content-Length of on-the-fly transcoded streams. Without it the player
      // can't resolve the track duration nor seek reliably (issue #170).
      params['estimateContentLength'] = 'true';
    }
    return _buildUrl('stream', params);
  }

  /// 道理鱼自研流端点：`GET /api/tracks/{id}/stream?token=<JWT>[&timeOffset=<秒>]`。
  ///
  /// Subsonic 兼容层的转码流是 chunked（无 Content-Length）且服务端不认
  /// HTTP Range，ExoPlayer 无法按字节 seek（durationMs=null → 从头重播）。
  /// 自研层支持「时间起点」参数（`timeOffset`/`startTime`/`offset`，WebUI
  /// 实测三选一生效），服务端 ffmpeg 直接从指定秒数重转码——WebUI 的 seek
  /// 正是靠重发带 timeOffset 的新流实现（2026-08-11 实测）。
  ///
  /// 转码播放与 seek 兼得时：首次播放传 timeOffset=0，seek 时重发带目标秒数的
  /// 新流即可。JWT 登录失败（无法走自研层）返回 null，调用方降级为 Subsonic
  /// 转码 URL（此时 seek 大概率仍不可用，但不比现状更差）。
  Future<String?> getDaoliyuApiStreamUrl(String songId,
      {int timeOffsetSeconds = 0}) async {
    if (!await loginToApi()) return null;
    final params = <String, String>{
      'token': _apiJwt ?? '',
      if (timeOffsetSeconds > 0) 'timeOffset': timeOffsetSeconds.toString(),
    };
    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');
    return '$activeBaseUrl/api/tracks/$songId/stream?$queryString';
  }

  Future<List<Artist>> getArtists() async {
    if (_jellyfin != null) return _jellyfin!.getArtists();
    if (_youtube != null) return _youtube!.getArtists();
    final response = await _request('getArtists');
    final artists = <Artist>[];

    for (final index in _asList(response['artists']?['index'])) {
      if (index is! Map) continue;
      artists.addAll(
        _asList(index['artist']).whereType<Map>().map(
              (a) => Artist.fromJson(Map<String, dynamic>.from(a)),
            ),
      );
    }

    return artists;
  }

  Future<List<Song>> getAllSongs() async {
    if (_jellyfin != null) return _jellyfin!.getAllSongs();
    // Subsonic has no direct "get all songs" endpoint.
    return [];
  }

  Future<Artist> getArtist(String id) async {
    final response = await _request('getArtist', {'id': id});
    return Artist.fromJson(response['artist'] as Map<String, dynamic>);
  }

  Future<List<Album>> getAlbumList({
    String type = 'recent',
    int size = 20,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getAlbumList(type: type, size: size, offset: offset);
    if (_youtube != null)
      return _youtube!.getAlbumList(type: type, size: size, offset: offset);
    final response = await _request('getAlbumList2', {
      'type': type,
      'size': size.toString(),
      'offset': offset.toString(),
    });

    final albumsData = _asList(response['albumList2']?['album']);
    return albumsData
        .whereType<Map>()
        .map((a) => Album.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }

  Future<Album> getAlbum(String id) async {
    if (_jellyfin != null) return _jellyfin!.getAlbum(id);
    if (_youtube != null) return _youtube!.getAlbum(id);
    final response = await _request('getAlbum', {'id': id});
    return Album.fromJson(response['album'] as Map<String, dynamic>);
  }

  Future<List<Song>> getAlbumSongs(String albumId) async {
    if (_jellyfin != null) return _jellyfin!.getAlbumSongs(albumId);
    if (_youtube != null) return _youtube!.getAlbumSongs(albumId);
    final response = await _request('getAlbum', {'id': albumId});
    final songsData = _asList(response['album']?['song']);
    return songsData
        .whereType<Map>()
        .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<List<Album>> getArtistAlbums(String artistId, {Artist? artist}) async {
    if (_jellyfin != null) return _jellyfin!.getArtistAlbums(artistId);
    if (_youtube != null) return _youtube!.getArtistAlbums(artistId);
    // Reuse the albums already fetched via getArtist to avoid a redundant
    // network request when the caller has already resolved the artist.
    if (artist != null && artist.albums.isNotEmpty) {
      return artist.albums;
    }
    final response = await _request('getArtist', {'id': artistId});
    final albumsData = _asList(response['artist']?['album']);
    return albumsData
        .whereType<Map>()
        .map((a) => Album.fromJson(Map<String, dynamic>.from(a)))
        .toList();
  }

  Future<List<Playlist>> getPlaylists() async {
    if (_jellyfin != null) return _jellyfin!.getPlaylists();
    if (_youtube != null) return _youtube!.getPlaylists();
    final response = await _request('getPlaylists');
    final playlistsData = _asList(response['playlists']?['playlist']);
    return playlistsData
        .whereType<Map>()
        .map((p) => Playlist.fromJson(Map<String, dynamic>.from(p)))
        .toList();
  }

  Future<Playlist> getPlaylist(String id) async {
    if (_jellyfin != null) return _jellyfin!.getPlaylist(id);
    if (_youtube != null) return _youtube!.getPlaylist(id);
    final response = await _request('getPlaylist', {'id': id});
    return Playlist.fromJson(response['playlist'] as Map<String, dynamic>);
  }

  Future<void> createPlaylist({
    required String name,
    String? comment,
    List<String>? songIds,
  }) async {
    if (_jellyfin != null) {
      await _jellyfin!
          .createPlaylist(name: name, comment: comment, songIds: songIds);
      return;
    }
    if (_youtube != null) {
      await _youtube!
          .createPlaylist(name: name, comment: comment, songIds: songIds);
      return;
    }
    // songId must be appended directly, using it as a map key would produce
    // songId[i]=x which Navidrome doesn't recognize
    String url = _buildUrl('createPlaylist', {'name': name});
    if (songIds != null && songIds.isNotEmpty) {
      for (final songId in songIds) {
        url += '&songId=${Uri.encodeComponent(songId)}';
      }
    }

    try {
      final response = await _dio.get(url);
      _decodeSubsonic(response.data);
    } on DioException catch (e) {
      throw Exception('Network error: ${e.message}');
    }
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? name,
    String? comment,
    List<String>? songIdsToAdd,
    List<int>? songIndexesToRemove,
  }) async {
    final params = <String, String>{'playlistId': playlistId};
    if (name != null) params['name'] = name;
    if (comment != null) params['comment'] = comment;

    String url = _buildUrl('updatePlaylist', params);

    if (songIdsToAdd != null && songIdsToAdd.isNotEmpty) {
      for (final songId in songIdsToAdd) {
        url += '&songIdToAdd=${Uri.encodeComponent(songId)}';
      }
    }

    if (songIndexesToRemove != null && songIndexesToRemove.isNotEmpty) {
      for (final index in songIndexesToRemove) {
        url += '&songIndexToRemove=${Uri.encodeComponent(index.toString())}';
      }
    }

    debugPrint('updatePlaylist URL: ${sanitizeQueryUrl(url)}');

    try {
      final response = await _dio.get(url);
      _decodeSubsonic(response.data);

      debugPrint('updatePlaylist successful');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 500)
        throw Exception(
            'Server error ($status). The server failed to process the request.');
      throw Exception('Network error. Check your connection.');
    }
  }

  Future<void> deletePlaylist(String id) async {
    if (_jellyfin != null) {
      await _jellyfin!.deletePlaylist(id);
      return;
    }
    if (_youtube != null) {
      await _youtube!.deletePlaylist(id);
      return;
    }
    await _request('deletePlaylist', {'id': id});
  }

  Future<SearchResult> search(
    String query, {
    int artistCount = 20,
    int albumCount = 20,
    int songCount = 20,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.search(query,
          songCount: songCount,
          albumCount: albumCount,
          artistCount: artistCount);
    if (_youtube != null)
      return _youtube!.search(query,
          songCount: songCount,
          albumCount: albumCount,
          artistCount: artistCount);
    final response = await _request('search3', {
      'query': query,
      'artistCount': artistCount.toString(),
      'albumCount': albumCount.toString(),
      'songCount': songCount.toString(),
    });

    final searchResult = response['searchResult3'];
    debugPrint('SubsonicService: search3 response: searchResult=$searchResult');

    final artists = _asList(searchResult?['artist'])
        .whereType<Map>()
        .map((a) => Artist.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    final albums = _asList(searchResult?['album'])
        .whereType<Map>()
        .map((a) => Album.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    final songs = _asList(searchResult?['song'])
        .whereType<Map>()
        .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    debugPrint(
        'SubsonicService: search3 parsed: ${artists.length} artists, ${albums.length} albums, ${songs.length} songs');
    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<List<Song>> getRandomSongs({int size = 20, String? genre}) async {
    if (_jellyfin != null)
      return _jellyfin!.getRandomSongs(size: size, genre: genre);
    if (_youtube != null)
      return _youtube!.getRandomSongs(size: size, genre: genre);

    // ── 道理鱼：自研层 random（Subsonic 层无 getRandomSongs）──────────
    if (isDaoliyu) {
      final data = await _apiGet('/api/tracks/random?limit=$size');
      final items = data?['items'] as List<dynamic>? ?? [];
      return items
          .map((e) => _daoliyuTrackToSong(e as Map<String, dynamic>))
          .whereType<Song>()
          .toList();
    }

    final params = <String, String>{'size': size.toString()};
    if (genre != null) params['genre'] = genre;

    final response = await _request('getRandomSongs', params);
    final songsData = _asList(response['randomSongs']?['song']);
    return songsData
        .whereType<Map>()
        .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  /// 道理鱼自研 track 对象 → Luobo Song 模型。
  ///
  /// 字段对照（api_random.body 实测）：id/title、artist{id,name}、album{id,title}、
  /// durationSeconds→duration、trackNumber→track、bitrate→bitRate、
  /// genres[]→genre(取首)、coverArt(路径式，见方案 §8 坑，保留原值)。
  Song? _daoliyuTrackToSong(Map<String, dynamic> t) {
    final id = t['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final artist = t['artist'] as Map<String, dynamic>?;
    final album = t['album'] as Map<String, dynamic>?;
    final genres = t['genres'] as List<dynamic>? ?? [];
    return Song(
      id: id,
      title: t['title']?.toString() ?? 'Unknown Title',
      album: album?['title']?.toString() ?? t['albumTitle']?.toString(),
      albumId: album?['id']?.toString() ?? t['albumId']?.toString(),
      artist: artist?['name']?.toString() ?? t['artistName']?.toString(),
      artistId: artist?['id']?.toString() ?? t['artistId']?.toString(),
      track: jsonInt(t['trackNumber']) ?? jsonInt(t['track']),
      genre: genres.isNotEmpty ? genres.first.toString() : null,
      // 道理鱼自研层 coverArt 是 path 形式（/api/cover?path=...），与 Subsonic
      // getCoverArt?id=album:alb_xxx 不匹配，直接用会 404。改为专辑 id 前缀，
      // 与 Subsonic 层封面取法对齐。
      coverArt: album?['id'] != null
          ? 'album:${album!['id']}'
          : t['coverArt']?.toString(),
      duration: jsonInt(t['durationSeconds']) ?? jsonInt(t['duration']),
      bitRate: jsonInt(t['bitrate']) ?? jsonInt(t['bitRate']),
      suffix: t['detectedContainer']?.toString() ?? t['fileFormat']?.toString(),
      samplingRate: jsonInt(t['sampleRate']),
      bitDepth: jsonInt(t['bitDepth']),
      created: t['createdAt'] != null
          ? DateTime.tryParse(t['createdAt'].toString())
          : null,
    );
  }

  // ── 有声书（道理鱼自研 /api 层，见 docs/有声书接入技术方案.md §5）─────────
  // 道理鱼有声书业务在 /Music2 源，不在 Subsonic 音乐索引里（search3 搜不到），
  // 入口统一走自研层。播放复用 Subsonic：章节 id（abe_）直接喂 /rest/stream。

  /// 有声书列表。GET /api/library/audiobooks?limit=100
  /// → {"items":[...], "skip":0, "take":100, "total":N}
  Future<List<Audiobook>> getAudiobooks() async {
    if (!isDaoliyu) return [];
    final data = await _apiGet('/api/library/audiobooks?limit=100');
    final items = data?['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => Audiobook.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// 章节列表（服务端分页）。GET /api/library/audiobooks/{id}/episodes?limit=&skip=
  /// → {"chapters":[...], "count":N}（episodeItems 与 chapters 重复，取 chapters；
  /// ⚠️ 必须带 library/ 前缀，无前缀 → NOT_FOUND）
  ///
  /// ⚠️ Bug1：响应 `count` 是**当页返回条数**（实测取 2 章 → count:2），不是总
  /// 章节数；总章节数在列表项的 `episodeCount`（实测 120 章）。分页 total 必须
  /// 用 Audiobook.episodeCount，调用方（详情页）据此计算 totalPages——否则
  /// 100+ 章永远只有 1 页无法翻页。此处 total 仅作 fallback（无 episodeCount 时）。
  Future<AudiobookChapterPage> getAudiobookChapters(
    String audiobookId, {
    int skip = 0,
    int take = 50,
  }) async {
    final data = await _apiGet(
        '/api/library/audiobooks/$audiobookId/episodes?limit=$take&skip=$skip');
    final chapters = data?['chapters'] as List<dynamic>? ?? [];
    return AudiobookChapterPage(
      chapters: chapters
          .map((e) => AudiobookChapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      // count 是当页条数，非总数；仅作无 episodeCount 时的兜底。
      total: jsonInt(data?['count']) ?? 0,
    );
  }

  /// 章节对象 → Song 模型（复用现有播放栈）。
  ///
  /// id = 章节 id（abe_，直接喂 Subsonic /rest/stream，明文认证、m4a 直出）；
  /// album/artist = 有声书 title（播放页天然显示书名）；track = 章节 order
  /// （1-based，进度记忆按此索引）；albumId/artistId 置 null（避免播放页点
  /// 专辑/艺人名跳转不存在的专辑页）；coverArt 置空 → 占位图。
  Song audiobookChapterToSong(Audiobook book, AudiobookChapter chapter) {
    return Song(
      id: chapter.id,
      title: chapter.title,
      album: book.title,
      artist: book.title,
      albumId: null,
      artistId: null,
      track: chapter.order,
      duration: chapter.durationSeconds,
      coverArt: null,
    );
  }

  Future<void> star({String? id, String? albumId, String? artistId}) async {
    if (_jellyfin != null) {
      await _jellyfin!.star(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    if (_youtube != null) {
      await _youtube!.star(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('star', params);
  }

  Future<void> unstar({String? id, String? albumId, String? artistId}) async {
    if (_jellyfin != null) {
      await _jellyfin!.unstar(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    if (_youtube != null) {
      await _youtube!.unstar(id: id, albumId: albumId, artistId: artistId);
      return;
    }
    final params = <String, String>{};
    if (id != null) params['id'] = id;
    if (albumId != null) params['albumId'] = albumId;
    if (artistId != null) params['artistId'] = artistId;
    await _request('unstar', params);
  }

  Future<void> setRating(String id, int rating) async {
    if (rating < 0 || rating > 5) {
      throw ArgumentError('Rating must be between 0 and 5');
    }
    await _request('setRating', {'id': id, 'rating': rating.toString()});
  }

  Future<SearchResult> getStarred() async {
    if (_jellyfin != null) return _jellyfin!.getStarred();
    if (_youtube != null) return _youtube!.getStarred();
    final response = await _request('getStarred2');
    final starred = response['starred2'];

    final artists = _asList(starred?['artist'])
        .whereType<Map>()
        .map((a) => Artist.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    final albums = _asList(starred?['album'])
        .whereType<Map>()
        .map((a) => Album.fromJson(Map<String, dynamic>.from(a)))
        .toList();

    final songs = _asList(starred?['song'])
        .whereType<Map>()
        .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
        .toList();

    return SearchResult(artists: artists, albums: albums, songs: songs);
  }

  Future<void> scrobble(String id, {bool submission = true}) async {
    if (_jellyfin != null) {
      await _jellyfin!.scrobble(id, submission: submission);
      return;
    }
    if (_youtube != null) {
      await _youtube!.scrobble(id, submission: submission);
      return;
    }
    await _request('scrobble', {'id': id, 'submission': submission.toString()});
  }

  Future<Map<String, dynamic>?> getLyrics({
    String? artist,
    String? title,
    String? id,
  }) async {
    if (_jellyfin != null && id != null) {
      final result = await _jellyfin!.getLyrics(id);
      if (result != null && result.containsKey('value')) return result;
      return null;
    }
    try {
      final params = <String, String>{};
      if (artist != null) params['artist'] = artist;
      if (title != null) params['title'] = title;

      final response = await _request('getLyrics', params);
      return response['lyrics'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getLyricsBySongId(String songId) async {
    if (_jellyfin != null) {
      final result = await _jellyfin!.getLyrics(songId);
      if (result != null && result.containsKey('structuredLyrics'))
        return result;
      return null;
    }

    // ── 道理鱼优先：自研层歌词（Subsonic 层无 getLyricsBySongId）──────
    if (isDaoliyu) {
      final apiLyrics = await _getDaoliyuLyrics(songId);
      if (apiLyrics != null) return apiLyrics;
    }

    try {
      final response = await _request('getLyricsBySongId', {'id': songId});
      return response['lyricsList'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// 道理鱼自研歌词：GET /api/tracks/{id}/lyrics，取 effectiveCandidate.lyrics
  /// （LRC 含中英交错行）。
  ///
  /// 返回**双键契约**（`docs/歌词源优先级修复技术方案.md` §4 方案 C / §5.1）：
  ///   • `lyrics`：原始 LRC 文本（无损）→ 车机链走 LyricsManager 解析时间轴；
  ///   • `structuredLyrics`：行数组 `{'synced': true, 'line': [{'start','value'}]}`
  ///     → 三个 UI 入口（全屏歌词页 / 车载模式页 / 迷你播放器）逐行渲染。
  ///
  /// 仅当 LRC 含有效时间轴行时才产出 `structuredLyrics`；纯文本时只返回 `lyrics`
  /// （此时两侧都拿不到有效歌词，仍走 LRCLIB/网易云兜底）。
  ///
  /// 拿不到有效歌词返回 null（走 LRCLIB/网易云兜底）。
  Future<Map<String, dynamic>?> _getDaoliyuLyrics(String songId) async {
    final data = await _apiGet('/api/tracks/$songId/lyrics');
    if (data == null) return null;

    try {
      final candidates = data['candidates'] as List<dynamic>? ?? [];
      Map<String, dynamic>? candidate =
          data['effectiveCandidate'] as Map<String, dynamic>?;
      if (candidate == null && candidates.isNotEmpty) {
        candidate = candidates.first as Map<String, dynamic>;
      }
      if (candidate == null) return null;

      final lrc = candidate['lyrics'] as String?;
      if (lrc == null || lrc.isEmpty) return null;

      final result = <String, dynamic>{'lyrics': lrc};
      final lines = lrcToStructuredLines(lrc);
      if (lines.isNotEmpty) {
        result['structuredLyrics'] = [
          {'synced': true, 'line': lines},
        ];
      }
      return result;
    } catch (e) {
      // 服务端返回结构意外（类型/字段变化）时，降级走 LRCLIB/网易云兜底。
      Log.w('Daoliyu', 'Lyrics parse failed: $e');
      return null;
    }
  }

  Future<List<Genre>> getGenres() async {
    if (_jellyfin != null) return _jellyfin!.getGenres();
    if (_youtube != null) return _youtube!.getGenres();
    // 道理鱼 Subsonic 层无 getGenres → 返回空，由 GenresScreen 本地聚合。
    if (isDaoliyu) return [];
    final response = await _request('getGenres');
    final genresData = _asList(response['genres']?['genre']);
    return genresData
        .whereType<Map>()
        .map((g) => Genre.fromJson(Map<String, dynamic>.from(g)))
        .where((g) => g.value.isNotEmpty)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
  }

  Future<List<Song>> getSongsByGenre(
    String genre, {
    int count = 50,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getSongsByGenre(genre, size: count, offset: offset);
    if (_youtube != null)
      return _youtube!.getSongsByGenre(genre, size: count, offset: offset);
    final response = await _request('getSongsByGenre', {
      'genre': genre,
      'count': count.toString(),
      'offset': offset.toString(),
    });
    final songsData = _asList(response['songsByGenre']?['song']);
    return songsData
        .whereType<Map>()
        .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
        .toList();
  }

  Future<List<Album>> getAlbumsByGenre(
    String genre, {
    int size = 50,
    int offset = 0,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getAlbumsByGenre(genre, size: size, offset: offset);
    if (_youtube != null)
      return _youtube!.getAlbumsByGenre(genre, size: size, offset: offset);
    try {
      final response = await _request('getAlbumList2', {
        'type': 'byGenre',
        'genre': genre,
        'size': size.toString(),
        'offset': offset.toString(),
      });
      final albumsData = _asList(response['albumList2']?['album']);
      return albumsData
          .whereType<Map>()
          .map((a) => Album.fromJson(Map<String, dynamic>.from(a)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<RadioStation>> getInternetRadioStations() async {
    try {
      final response = await _request('getInternetRadioStations');
      final stationsData = _asList(
        response['internetRadioStations']?['internetRadioStation'],
      );
      return stationsData
          .whereType<Map>()
          .map((s) => RadioStation.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> createInternetRadioStation({
    required String name,
    required String streamUrl,
    String? homePageUrl,
  }) async {
    final params = <String, String>{'name': name, 'streamUrl': streamUrl};
    if (homePageUrl != null && homePageUrl.isNotEmpty) {
      params['homepageUrl'] = homePageUrl;
    }
    await _request('createInternetRadioStation', params);
  }

  Future<void> updateInternetRadioStation({
    required String id,
    required String name,
    required String streamUrl,
    String? homePageUrl,
  }) async {
    final params = <String, String>{
      'id': id,
      'name': name,
      'streamUrl': streamUrl,
    };
    if (homePageUrl != null && homePageUrl.isNotEmpty) {
      params['homepageUrl'] = homePageUrl;
    }
    await _request('updateInternetRadioStation', params);
  }

  Future<void> deleteInternetRadioStation(String id) async {
    await _request('deleteInternetRadioStation', {'id': id});
  }

  Future<List<Song>> getSimilarSongs(String id, {int count = 50}) async {
    if (_jellyfin != null) return _jellyfin!.getSimilarSongs(id, count: count);
    if (_youtube != null) return _youtube!.getSimilarSongs(id, count: count);
    try {
      final response = await _request('getSimilarSongs2', {
        'id': id,
        'count': count.toString(),
      });
      final songsData = _asList(response['similarSongs2']?['song']);
      return songsData
          .whereType<Map>()
          .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (e) {
      try {
        final response = await _request('getSimilarSongs', {
          'id': id,
          'count': count.toString(),
        });
        final songsData = _asList(response['similarSongs']?['song']);
        return songsData
            .whereType<Map>()
            .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
            .toList();
      } catch (_) {}
      return [];
    }
  }

  Future<List<Song>> getArtistTopSongs(
    String artistId, {
    int count = 50,
    Artist? artist,
  }) async {
    if (_jellyfin != null)
      return _jellyfin!.getArtistTopSongs(artistId, count: count);
    if (_youtube != null)
      return _youtube!.getArtistTopSongs(artistId, count: count);
    try {
      // Reuse the caller-provided artist to avoid a redundant getArtist call.
      final resolved = artist ?? await getArtist(artistId);

      final response = await _request('getTopSongs', {
        'artist': resolved.name,
        'count': count.toString(),
      });
      final songsData = _asList(response['topSongs']?['song']);
      return songsData
          .whereType<Map>()
          .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
          .toList();
    } catch (e) {
      try {
        final albums = await getArtistAlbums(artistId, artist: artist);
        if (albums.isEmpty) return [];

        final songs = <Song>[];
        for (final album in albums.take(3)) {
          final albumSongs = await getAlbumSongs(album.id);
          songs.addAll(albumSongs);
          if (songs.length >= count) break;
        }
        return songs.take(count).toList();
      } catch (_) {
        return [];
      }
    }
  }
}

class SearchResult {
  final List<Artist> artists;
  final List<Album> albums;
  final List<Song> songs;

  SearchResult({
    required this.artists,
    required this.albums,
    required this.songs,
  });

  bool get isEmpty => artists.isEmpty && albums.isEmpty && songs.isEmpty;
}

class _TlsHttpOverrides extends HttpOverrides {
  final HttpClient Function() _factory;

  _TlsHttpOverrides(this._factory);

  @override
  HttpClient createHttpClient(SecurityContext? context) => _factory();
}

/// Bypasses [HttpOverrides.global] to create a real [HttpClient].
class _RealHttpOverrides extends HttpOverrides {}
