import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/server_config.dart';
import '../utils/image_cache.dart';
import '../services/diagnostics/diagnostics.dart';
import '../services/services.dart';

enum AuthState {
  unknown,
  unauthenticated,
  authenticating,
  authenticated,
  offlineMode,
  serverUnreachable,
  error,
}

class AuthProvider extends ChangeNotifier {
  final SubsonicService _subsonicService;
  final StorageService _storageService;

  AuthState _state = AuthState.unknown;
  String? _error;
  ServerConfig? _config;
  bool _hasOfflineContent = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  AuthProvider(this._subsonicService, this._storageService) {
    _loadSavedConfig();
    _listenToConnectivityChanges();
  }

  AuthState get state => _state;
  String? get error => _error;
  ServerConfig? get config => _config;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get hasOfflineContent => _hasOfflineContent;

  void _listenToConnectivityChanges() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      if (_config == null || !_config!.hasLocalUrl) return;
      if (_state != AuthState.authenticated &&
          _state != AuthState.serverUnreachable) return;
      // Network changed — re-probe local/remote URL
      DiagnosticsService.instance.record(
        EventType.netSwitch,
        LogLevel.info,
        {
          'from': 'connectivityChanged',
          'to': results.map((r) => r.name).join(',')
        },
      );
      // 网络已变化：强制同步探测，不依赖上次会话的记忆跳过。
      await _subsonicService.resolveActiveUrl(forceProbe: true);
      Log.i('Auth',
          'Network changed, active URL: ${_subsonicService.activeBaseUrl}');
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadSavedConfig() async {
    final config = await _storageService.getServerConfig();
    if (config != null && config.isValid) {
      _config = config;

      if (config.serverType == 'local') {
        OfflineService().setOfflineMode(true);
        _state = AuthState.offlineMode;
        notifyListeners();
        return;
      }

      await _subsonicService.configure(config);
      await _subsonicService.resolveActiveUrl();
      await _verifyConnection();
    } else {
      _state = AuthState.unauthenticated;
      notifyListeners();
    }
  }

  Future<void> _verifyConnection() async {
    debugPrint('[Auth] _verifyConnection: pinging ${_config?.serverUrl}');
    _state = AuthState.authenticating;
    notifyListeners();

    PingResult? pingResult;
    const maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      // 第 1 次尝试带备选地址兜底（LAN↔远端）；后续尝试按当前 activeBaseUrl
      // 重建 URL（后台探测已切换时自然落到备选地址）。
      pingResult =
          attempt == 1 ? await _pingWithFailover() : await _pingWithErrorOnce();
      if (pingResult.success) break;
      debugPrint(
          '[Auth] Ping attempt $attempt/$maxAttempts failed: ${pingResult.error}');
      if (attempt < maxAttempts) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    if (pingResult!.success) {
      debugPrint(
          '[Auth] Ping OK — type=${pingResult.serverType} version=${pingResult.serverVersion}');
      if (_config != null) {
        final updatedConfig = _config!.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
        );
        if (updatedConfig.serverType != _config!.serverType ||
            updatedConfig.serverVersion != _config!.serverVersion) {
          _config = updatedConfig;
          await _storageService.saveServerConfig(updatedConfig);
        }
      }
      debugPrint('[Auth] State: authenticating → authenticated');
      _state = AuthState.authenticated;
      // 语义化封面缓存 key 的 (服务器, 账号) 命名空间：换密码不失效、多服务器不串图。
      registerCoverCacheServerId(_subsonicService.coverCacheServerId);

      final offlineService = OfflineService();
      await offlineService.initialize();
      offlineService.flushPendingScrobbles(_subsonicService).catchError(
            (e) => debugPrint('Error flushing pending scrobbles: $e'),
          );
    } else {
      debugPrint('[Auth] Ping failed: ${pingResult.error}');

      // 记录失败原因：切换配置失败时，网关/设置页据此展示准确文案
      //（此前 _verifyConnection 不写 _error，切失败后要么 null 要么是
      // 上一次表单登录遗留的旧错误）。
      _error = pingResult.error ?? 'Failed to connect to server';

      final offlineService = OfflineService();
      await offlineService.initialize();
      _hasOfflineContent = offlineService.getDownloadedCount() > 0;
      debugPrint(
          '[Auth] State: authenticating → serverUnreachable (offlineContent=$_hasOfflineContent)');
      _state = AuthState.serverUnreachable;
    }
    notifyListeners();
  }

  /// 单次带超时的 ping（10s 上限）。
  Future<PingResult> _pingWithErrorOnce() {
    return _subsonicService.pingWithError().timeout(
          const Duration(seconds: 10),
          onTimeout: () =>
              PingResult(success: false, error: 'Connection timed out'),
        );
  }

  /// 带备选地址兜底的认证 ping：单次 ping 失败且配置了局域网地址、且属于
  /// 连接类错误时，强制同步探测备选地址（可达则切换）后重试一次，消除
  /// 「上次在远端 → 登录 ping 远端、远端偶发不可达但局域网通」的偶发登录失败，
  /// 也覆盖「已提交局域网但局域网抖动」场景。凭据/SSL 类错误不触发（换地址无意义）。
  Future<PingResult> _pingWithFailover() async {
    var ping = await _pingWithErrorOnce();
    if (ping.success) return ping;

    final error = ping.error ?? '';
    if (_subsonicService.hasLocalUrl && _isConnectionError(error)) {
      debugPrint('[Auth] Ping failed, failover: probing alternate URL');
      DiagnosticsService.instance.record(
        EventType.netSwitch,
        LogLevel.info,
        {'from': 'pingFailover', 'to': 'forceProbe', 'error': error},
      );
      await _subsonicService.resolveActiveUrl(forceProbe: true);
      final retry = await _pingWithErrorOnce();
      if (retry.success) return retry;
    }
    return ping;
  }

  /// 连接类错误才触发地址兜底；凭据（Invalid username）/SSL 换地址无意义。
  bool _isConnectionError(String error) {
    final e = error.toLowerCase();
    return e.contains('socket') ||
        e.contains('connection refused') ||
        e.contains('connection failed') ||
        e.contains('connection errored') ||
        e.contains('cannot connect') ||
        e.contains('timed out') ||
        e.contains('timeout');
  }

  void enterOfflineMode() {
    OfflineService().setOfflineMode(true);
    _state = AuthState.offlineMode;
    notifyListeners();
  }

  Future<void> retryConnection() async {
    if (_config == null) return;
    await _subsonicService.configure(_config!);
    await _subsonicService.resolveActiveUrl();
    await _verifyConnection();
  }

  Future<void> disconnect() async {
    _config = null;
    _state = AuthState.unauthenticated;
    await _storageService.clearServerConfig();
    notifyListeners();
  }

  Future<bool> login({
    required String serverUrl,
    String? localUrl,
    required String username,
    required String password,
    bool useLegacyAuth = false,
    bool allowSelfSignedCertificates = false,
    String? customCertificatePath,
    String? clientCertificatePath,
    String? clientCertificatePassword,
    String? profileName,
    String serverFamily = 'subsonic',
  }) async {
    debugPrint(
        '[Auth] login: user=$username server=$serverUrl local=$localUrl family=$serverFamily');
    // 记录登录前的状态：已登录（authenticated）时添加配置失败不应改变
    // AuthWrapper 根路由——否则 MainScreen 会被 error 态的 LoginScreen 替换，
    // 用户从设置页 push 的登录页返回后看到的是空登录页（bug）。
    final prevState = _state;
    _state = AuthState.authenticating;
    _error = null;
    notifyListeners();

    // YouTube Music: no server URL / credentials required
    if (serverFamily == 'youtube') {
      serverUrl = 'https://music.youtube.com';
    }

    final isJellyfin = serverFamily == 'jellyfin';
    String? jellyfinToken;
    String? jellyfinUserId;

    if (isJellyfin) {
      final tmpConfig = ServerConfig(
        serverUrl: serverUrl,
        username: username,
        password: password,
        allowSelfSignedCertificates: allowSelfSignedCertificates,
        serverFamily: 'jellyfin',
      );
      final jf = JellyfinService()..configure(tmpConfig);
      final authResp = await jf.authenticate(username, password);
      if (authResp == null) {
        _error = 'Jellyfin authentication failed. Check your credentials.';
        // 已登录时添加配置失败：恢复原状态（MainScreen 不被替换），
        // 与下方 ping 失败/catch 路径一致（见 login() 开头注释）——
        // 否则设置页添加 Jellyfin 失败会把整个设置栈换成登录页。
        _state =
            prevState == AuthState.authenticated ? prevState : AuthState.error;
        notifyListeners();
        return false;
      }
      jellyfinToken = authResp['AccessToken'] as String?;
      final user = authResp['User'] as Map<String, dynamic>?;
      jellyfinUserId = user?['Id'] as String?;
      if (jellyfinToken == null || jellyfinUserId == null) {
        _error = 'Jellyfin returned an unexpected response.';
        _state =
            prevState == AuthState.authenticated ? prevState : AuthState.error;
        notifyListeners();
        return false;
      }
    }

    final config = ServerConfig(
      serverUrl: serverUrl,
      localUrl: localUrl,
      username: username,
      password: password,
      useLegacyAuth: useLegacyAuth,
      allowSelfSignedCertificates: allowSelfSignedCertificates,
      customCertificatePath: customCertificatePath,
      clientCertificatePath: clientCertificatePath,
      clientCertificatePassword: clientCertificatePassword,
      name: profileName,
      serverFamily: serverFamily,
      apiToken: jellyfinToken,
      userId: jellyfinUserId,
    );

    try {
      await _subsonicService.configure(config);
      await _subsonicService.resolveActiveUrl();

      final pingResult = await _pingWithFailover();
      if (pingResult.success) {
        debugPrint(
            '[Auth] Login OK — type=${pingResult.serverType} version=${pingResult.serverVersion}');
        debugPrint('[Auth] State: authenticating → authenticated');

        // 道理鱼：Subsonic 层 ping 通过后，后台登录自研 /api 层拿 JWT
        // （歌词/随机歌依赖）。失败不阻塞登录——Subsonic 浏览/播放仍可用，
        // 仅歌词/随机歌降级走兜底。
        if (serverFamily == 'daoliyu') {
          final apiOk = await _subsonicService.loginToApi();
          debugPrint('[Auth] 道理鱼 API login: $apiOk');
        }

        final updatedConfig = config.copyWith(
          serverType: pingResult.serverType,
          serverVersion: pingResult.serverVersion,
          apiToken: _subsonicService.apiJwtOrNull,
          userId: _subsonicService.apiUserId,
        );
        _config = updatedConfig;
        await _storageService.saveServerConfig(updatedConfig);
        _state = AuthState.authenticated;
        // login() 不走 _verifyConnection，必须在此注册封面缓存 key 的
        // (服务器, 账号) 命名空间，否则首次登录会话内 serverId 为空，
        // 重启后 key 变化导致已缓存封面全部失效重下。
        registerCoverCacheServerId(_subsonicService.coverCacheServerId);
        notifyListeners();

        // 保存到 profile 列表（await + 日志：此前 fire-and-forget 失败不可见，
        // 用户登录成功但服务列表看不到新服务器）。
        try {
          await _storageService.saveProfile(updatedConfig);
          debugPrint('[Auth] Profile saved: ${updatedConfig.serverUrl}');
        } catch (e) {
          debugPrint('[Auth] ERROR saving profile: $e');
        }

        // 切换服务器成功：通知 UI 清空旧服务器缓存（队列持久化等），
        // 避免旧 Navidrome ID 请求新道理鱼服务器导致 404。
        _notifyServerSwitched();

        final offlineService = OfflineService();
        await offlineService.initialize();
        offlineService.flushPendingScrobbles(_subsonicService).catchError(
              (e) => debugPrint('Error flushing pending scrobbles: $e'),
            );
        return true;
      } else {
        _error =
            _formatError(pingResult.error ?? 'Failed to connect to server');
        debugPrint('[Auth] Login failed: $_error');
        // 已登录时添加配置失败：恢复原状态（MainScreen 不被替换），
        // 错误由登录页的 _loginError 展示；仅首次登录场景才进 error 态。
        // 关键：configure() 在 try 内已把 SubsonicService 切到新服务器，
        // 必须回滚到旧配置，否则用户返回首页后所有请求打失败的新服务器。
        if (prevState == AuthState.authenticated && _config != null) {
          await _subsonicService.configure(_config!);
          await _subsonicService.resolveActiveUrl();
        }
        _state =
            prevState == AuthState.authenticated ? prevState : AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = _formatError(e);
      debugPrint('[Auth] Login exception: $e');
      debugPrint('[Auth] State: authenticating → error (formatted: $_error)');
      // 同上：异常时回滚服务层配置，保持已登录会话继续可用。
      if (prevState == AuthState.authenticated && _config != null) {
        await _subsonicService.configure(_config!);
        await _subsonicService.resolveActiveUrl();
      }
      _state =
          prevState == AuthState.authenticated ? prevState : AuthState.error;
      notifyListeners();
      return false;
    }
  }

  String _formatError(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('SocketException') ||
        errorStr.contains('Connection refused') ||
        errorStr.contains('Connection failed') ||
        errorStr.contains('connection errored') ||
        errorStr.contains('Cannot connect')) {
      return 'Cannot connect to server. Check the URL and your internet connection.';
    } else if (errorStr.contains('HandshakeException') ||
        errorStr.contains('CERTIFICATE_VERIFY_FAILED') ||
        errorStr.contains('SSL certificate')) {
      return 'SSL certificate error. Enable "Allow Self-Signed Certificates" for custom CA servers.';
    } else if (errorStr.contains('TimeoutException') ||
        errorStr.contains('timed out')) {
      return 'Connection timed out. Check your server URL.';
    } else if (errorStr.contains('FormatException')) {
      return 'Invalid server URL format.';
    } else if (errorStr.contains('401') ||
        errorStr.contains('Unauthorized') ||
        errorStr.contains('Invalid username or password')) {
      return 'Invalid username or password.';
    } else if (errorStr.contains('404') ||
        errorStr.contains('Not Found') ||
        errorStr.contains('Server not found')) {
      return 'Server not found. Check your URL path.';
    } else {
      return errorStr
          .replaceAll('Exception:', '')
          .replaceAll('Network error:', '')
          .replaceAll(
              'This indicates an error which most likely cannot be solved by the library.',
              '')
          .trim();
    }
  }

  Future<void> setLocalOnlyMode(bool enabled) async {
    if (enabled) {
      _config = ServerConfig(
        serverUrl: 'local',
        username: 'local',
        password: '',
        serverType: 'local',
      );
      await _storageService.saveServerConfig(_config!);
      _state = AuthState.offlineMode;
    } else {
      _config = null;
      _state = AuthState.unauthenticated;
      await _storageService.clearAll();
    }
    notifyListeners();
  }

  bool get isLocalOnlyMode => _config?.serverType == 'local';

  Future<List<ServerConfig>> getSavedProfiles() =>
      _storageService.getSavedProfiles();

  Future<void> deleteProfile(ServerConfig profile) =>
      _storageService.deleteProfile(profile);

  /// 服务器切换/登录成功后回调（main.dart 接线）：清空依赖旧服务器 ID 的
  /// 本地缓存（播放队列持久化/首页推荐等），避免用 Navidrome 的旧歌曲 ID
  /// 请求道理鱼导致 404（诊断日志 confirmed）。
  void Function()? onServerSwitched;

  /// 登录成功或切换 profile 后调用，通知 UI 层清理旧服务器缓存。
  void _notifyServerSwitched() {
    onServerSwitched?.call();
  }

  Future<void> switchProfile(ServerConfig profile) async {
    final prevConfig = _config;
    final switched = prevConfig?.serverUrl != profile.serverUrl ||
        prevConfig?.username != profile.username;
    _error = null;
    _config = profile;
    try {
      await _storageService.saveServerConfig(profile);
      await _subsonicService.configure(profile);
      await _subsonicService.resolveActiveUrl();
      await _verifyConnection();
    } catch (e) {
      // 仿 login()：中途异常（saveServerConfig/configure/离线服务）时回滚，
      // 避免 config / 服务层 / 持久化三者不一致（_verifyConnection 内部
      // offlineService.initialize 等无兜底）。
      debugPrint('[Auth] switchProfile threw: $e');
      _error = _formatError(e);
      await _rollbackSwitch(prevConfig);
      return;
    }
    // 切换失败（服务器不可达/认证失败）：回滚并恢复会话，与 login() 的失败
    // 处理一致——否则用户被踢到 serverUnreachable 屏，且 _notifyServerSwitched
    // 还会清空当前服务器的队列与音乐库。
    if (!isAuthenticated) {
      debugPrint('[Auth] switchProfile failed — rolling back');
      await _rollbackSwitch(prevConfig);
      return;
    }
    // 道理鱼：切换 profile 也要登录自研 /api 层拿 JWT（歌词/随机歌依赖）。
    // 登录成功后才算完整切换到该服务器；失败不阻塞，仅歌词/随机降级。
    if (profile.serverFamily == 'daoliyu') {
      final apiOk = await _subsonicService.loginToApi();
      debugPrint('[Auth] switchProfile 道理鱼 API login: $apiOk');
      final updated = _config!.copyWith(
        apiToken: _subsonicService.apiJwtOrNull,
        userId: _subsonicService.apiUserId,
      );
      _config = updated;
      await _storageService.saveServerConfig(updated);
      await _storageService.saveProfile(updated);
    }
    if (switched) _notifyServerSwitched();
  }

  /// switchProfile 失败回滚：恢复旧会话；未登录（prevConfig==null，网关场景）
  /// 时清掉失败配置回到未登录态——否则失败的 profile 已被写盘并作为活跃配置，
  /// 下次冷启动会永久楔进 serverUnreachable，且失败原因无处展示。
  Future<void> _rollbackSwitch(ServerConfig? prevConfig) async {
    if (prevConfig != null) {
      _config = prevConfig;
      await _storageService.saveServerConfig(prevConfig);
      await _subsonicService.configure(prevConfig);
      await _subsonicService.resolveActiveUrl();
      // 封面缓存 key 命名空间跟随回滚后的服务器，避免用新 serverId 拼 key。
      registerCoverCacheServerId(_subsonicService.coverCacheServerId);
      _state = AuthState.authenticated;
    } else {
      _config = null;
      await _storageService.clearServerConfig();
      registerCoverCacheServerId('');
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> updateSelectedMusicFolderIds(List<String> ids) async {
    if (_config == null) return;
    final updated = _config!.copyWith(selectedMusicFolderIds: ids);
    _config = updated;
    await _subsonicService.configure(updated);
    await _storageService.saveServerConfig(updated);
    notifyListeners();
  }

  Future<void> logout() async {
    final offlineService = OfflineService();
    if (offlineService.isBackgroundDownloadActive) {
      offlineService.cancelBackgroundDownload();
    }

    // 保留磁盘封面缓存：同账号登出再登回直接命中；换账号/换服务器由语义化
    // key（含 serverId）或 URL 天然隔离，不会串图。仅清内存解码结果，避免
    // 旧账号封面残留。用户仍可在设置页手动清空封面缓存。
    PaintingBinding.instance.imageCache.clear();
    try {
      await BpmAnalyzerService().clearCache();
    } catch (_) {}
    try {
      await offlineService.deleteAllDownloads();
    } catch (_) {}
    try {
      await AndroidAutoService().dispose();
    } catch (_) {}
    try {
      await AndroidSystemService().dispose();
    } catch (_) {}
    try {
      await SamsungIntegrationService().dispose();
    } catch (_) {}
    try {
      await BluetoothAvrcpService().dispose();
    } catch (_) {}

    await _storageService.clearAll();

    // 登出后重置封面缓存 key 命名空间，避免旧账号 serverId 残留（切账号时
    // 新账号 _verifyConnection 成功前不应继续用旧 serverId 拼 key）。
    registerCoverCacheServerId('');

    _config = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }
}
