import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../l10n/app_localizations.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../services/local_music_service.dart';
import '../theme/app_theme.dart';
import '../utils/screen_helper.dart';
import 'qr_scanner_screen.dart';

enum _LoginErrorType {
  ssl,
  credentials,
  notFound,
  timeout,
  connection,
  format,
  generic,
}

class LoginScreen extends StatefulWidget {
  /// When provided, the form is pre-filled with this server config so the
  /// user can edit an existing connection (pushed from settings).
  final ServerConfig? initialConfig;

  const LoginScreen({super.key, this.initialConfig});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _localServerController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverFocusNode = FocusNode();
  final _localServerFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _useLegacyAuth = false;
  bool _allowSelfSignedCertificates = false;
  bool _obscurePassword = true;
  bool _showAdvancedOptions = false;
  String _serverFamily = 'subsonic'; // 'subsonic' | 'jellyfin' | 'youtube'
  String? _customCertificatePath;
  String? _customCertificateName;
  final _profileNameController = TextEditingController();

  String? _clientCertificatePath;
  String? _clientCertificateName;
  final _clientCertPasswordController = TextEditingController();
  bool _obscureClientCertPassword = true;
  bool _isScanning = false;
  double _scanProgress = 0.0;
  String _scanStatus = '';

  String? _loginError;

  @override
  void initState() {
    super.initState();

    _serverController.addListener(_clearError);
    _localServerController.addListener(_clearError);
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _profileNameController.addListener(_clearError);

    _prefillFromConfig(widget.initialConfig);
  }

  /// Pre-fills the form with an existing server config so the screen can be
  /// used to edit a saved connection (opened from the settings page).
  void _prefillFromConfig(ServerConfig? config) {
    if (config == null) return;
    _serverController.text =
        config.serverUrl == 'local' ? '' : config.serverUrl;
    _localServerController.text = config.localUrl ?? '';
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _profileNameController.text = config.name ?? '';
    _serverFamily =
        config.serverFamily.isEmpty ? 'subsonic' : config.serverFamily;
    // 道理鱼只认明文 p=，从已存 profile 恢复表单时同样强制。
    _useLegacyAuth = config.useLegacyAuth || config.serverFamily == 'daoliyu';
    _allowSelfSignedCertificates = config.allowSelfSignedCertificates;
    _customCertificatePath = config.customCertificatePath;
    if (config.customCertificatePath != null) {
      _customCertificateName =
          config.customCertificatePath!.split(Platform.pathSeparator).last;
    }
    _clientCertificatePath = config.clientCertificatePath;
    if (config.clientCertificatePath != null) {
      _clientCertificateName =
          config.clientCertificatePath!.split(Platform.pathSeparator).last;
    }
    _clientCertPasswordController.text = config.clientCertificatePassword ?? '';
  }

  void _clearError() {
    if (_loginError != null && mounted) {
      setState(() => _loginError = null);
    }
  }

  /// Pops this screen when it was pushed onto the navigation stack (e.g.
  /// opened from the settings page to add/edit a profile), so the user
  /// returns to the previous screen instead of being stranded on the login
  /// page. On first launch this screen is the root route — nothing to pop.
  void _popIfPushed() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  _LoginErrorType _categoriseError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('ssl') ||
        lower.contains('certificate') ||
        lower.contains('handshake') ||
        lower.contains('tls')) {
      return _LoginErrorType.ssl;
    }
    if (lower.contains('invalid username') ||
        lower.contains('wrong password') ||
        lower.contains('unauthorized') ||
        lower.contains('401')) {
      return _LoginErrorType.credentials;
    }
    if (lower.contains('not found') ||
        lower.contains('404') ||
        lower.contains('url path')) {
      return _LoginErrorType.notFound;
    }
    if (lower.contains('timed out') || lower.contains('timeout')) {
      return _LoginErrorType.timeout;
    }
    if (lower.contains('cannot connect') ||
        lower.contains('connection refused') ||
        lower.contains('network') ||
        lower.contains('socket')) {
      return _LoginErrorType.connection;
    }
    if (lower.contains('url format') || lower.contains('http')) {
      return _LoginErrorType.format;
    }
    return _LoginErrorType.generic;
  }

  Widget _buildErrorCard(ThemeData theme) {
    final error = _loginError;
    if (error == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;

    final type = _categoriseError(error);

    IconData icon;
    Color color;
    String? hint;

    switch (type) {
      case _LoginErrorType.ssl:
        icon = CupertinoIcons.lock_slash;
        color = const Color(0xFFFF9500);
        if (!_allowSelfSignedCertificates) {
          hint = l10n.enableSelfSignedCertsHint;
        }
      case _LoginErrorType.credentials:
        icon = CupertinoIcons.person_badge_minus;
        color = AppTheme.appleMusicRed;
        hint = l10n.checkCredentialsHint;
      case _LoginErrorType.notFound:
        icon = CupertinoIcons.question_circle;
        color = const Color(0xFFFF9500);
        hint = l10n.verifyServerUrlHint;
      case _LoginErrorType.timeout:
        icon = CupertinoIcons.timer;
        color = const Color(0xFFFF9500);
        hint = l10n.serverTimeoutHint;
      case _LoginErrorType.connection:
        icon = CupertinoIcons.wifi_slash;
        color = const Color(0xFFFF9500);
        hint = null;
      case _LoginErrorType.format:
        icon = CupertinoIcons.link;
        color = const Color(0xFFFF9500);
        hint = l10n.serverUrlMustStartWith;
      case _LoginErrorType.generic:
        icon = CupertinoIcons.exclamationmark_triangle;
        color = AppTheme.appleMusicRed;
        hint = null;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    error,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.copy_rounded,
                      size: 16, color: color.withValues(alpha: 0.7)),
                  tooltip: l10n.copyError,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: error));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.errorCopiedToClipboard),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        width: 260,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
            if (type == _LoginErrorType.ssl &&
                !_allowSelfSignedCertificates) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 30),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _allowSelfSignedCertificates = true;
                      _loginError = null;
                    });
                  },
                  child: Text(
                    Platform.isIOS || Platform.isAndroid
                        ? l10n.tapToEnableSelfSignedCerts
                        : l10n.clickToEnableSelfSignedCerts,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: color,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serverController.removeListener(_clearError);
    _localServerController.removeListener(_clearError);
    _usernameController.removeListener(_clearError);
    _passwordController.removeListener(_clearError);
    _profileNameController.removeListener(_clearError);
    _serverController.dispose();
    _localServerController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _profileNameController.dispose();
    _clientCertPasswordController.dispose();
    _serverFocusNode.dispose();
    _localServerFocusNode.dispose();
    _usernameFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickClientCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx', 'pem'],
        dialogTitle: AppLocalizations.of(context)!.selectClientCertificate,
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _clientCertificatePath = result.files.single.path;
          _clientCertificateName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!
                  .failedToSelectClientCert(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickCertificateFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pem', 'crt', 'cer', 'p12', 'pfx', 'der'],
        dialogTitle: AppLocalizations.of(context)!.selectCertificate,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _customCertificatePath = result.files.single.path;
          _customCertificateName = result.files.single.name;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(
                context,
              )!
                  .failedToSelectCertificate(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _login() async {
    // YouTube Music requires no credentials — skip form validation
    if (_serverFamily != 'youtube') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _loginError = null);

    var serverUrl = _serverFamily == 'youtube'
        ? 'https://music.youtube.com'
        : _serverController.text.trim();
    final localUrl = _localServerController.text.trim();

    // Accept at least one URL (LAN-only without WAN is valid).
    if (_serverFamily != 'youtube' && serverUrl.isEmpty && localUrl.isEmpty) {
      setState(
        () => _loginError = '请至少填写一个服务器地址（远程或局域网）',
      );
      return;
    }

    // If only the LAN (local) URL was provided, use it as the primary
    // server url so the app can connect from home. Keep it also as localUrl
    // (double-store) so the LAN rule — always original, no transcoding —
    // stays active for LAN-only setups. Also matches re-saves of a LAN-only
    // profile (both fields hold the same address, see _prefillFromConfig).
    final isLanOnly = _serverFamily != 'youtube' &&
        localUrl.isNotEmpty &&
        (serverUrl.isEmpty || localUrl == serverUrl);
    if (isLanOnly && serverUrl.isEmpty) {
      serverUrl = localUrl;
    }

    if (_serverFamily != 'youtube' &&
        serverUrl.isNotEmpty &&
        !serverUrl.startsWith('http://') &&
        !serverUrl.startsWith('https://')) {
      setState(
        () =>
            _loginError = AppLocalizations.of(context)!.serverUrlMustStartWith,
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileName = _profileNameController.text.trim();
    // Only pass localUrl if it differs from serverUrl (avoids pointless
    // LAN-probe when the user only configured a single address) — except for
    // LAN-only configs, where localUrl == serverUrl is required so the LAN
    // override (always original) stays active.
    final effectiveLocalUrl =
        (localUrl.isNotEmpty && (localUrl != serverUrl || isLanOnly))
            ? localUrl
            : null;
    bool success = false;
    try {
      success = await authProvider.login(
        serverUrl: serverUrl,
        localUrl: effectiveLocalUrl,
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        useLegacyAuth: _useLegacyAuth,
        allowSelfSignedCertificates: _allowSelfSignedCertificates,
        customCertificatePath: _customCertificatePath,
        clientCertificatePath: _clientCertificatePath,
        clientCertificatePassword: _clientCertPasswordController.text.isEmpty
            ? null
            : _clientCertPasswordController.text,
        profileName: profileName.isEmpty ? null : profileName,
        serverFamily: _serverFamily,
      );
    } catch (e) {
      // login() 内部已兜底返回 false，此处防御异常（如 configure 阶段抛出），
      // 避免 _login() 静默中断导致"无提示、卡 loading"。
      debugPrint('[Login] login() threw: $e');
      success = false;
    }

    if (success && mounted) {
      // 先取 root messenger，pop 后再显示——避免 SnackBar 因 LoginScreen
      // context 随 pop 销毁而被吞（此前 show 在 pop 前，用户看不到成功提示）。
      final messenger = ScaffoldMessenger.of(context);
      // 跳转首页：弹到根路由。从设置页添加配置时，导航栈是
      // [AuthWrapper, SettingsRootScreen, SettingsServerTab, LoginScreen]，
      // popUntil(isFirst) 全部弹出 → AuthWrapper 因 state=authenticated 显示
      // MainScreen 首页；首次登录时根路由已是 first，无副作用。
      Navigator.of(context).popUntil((route) => route.isFirst);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.connectedSuccessfully,
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (!success && mounted) {
      setState(
        () => _loginError = authProvider.error ??
            AppLocalizations.of(context)!.failedToConnectToServer,
      );
    }
  }

  Future<void> _scanQrCode() async {
    final config = await Navigator.push<ServerConfig>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (config == null || !mounted) return;

    // Fill in the form fields from scanned config
    _serverController.text = config.serverUrl;
    _localServerController.text = config.localUrl ?? '';
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _profileNameController.text = config.name ?? '';
    setState(() {
      _serverFamily = config.serverFamily;
      // 道理鱼只认明文 p=，从已存 profile / 扫描配置恢复时同样强制。
      _useLegacyAuth = config.useLegacyAuth || config.serverFamily == 'daoliyu';
      _allowSelfSignedCertificates = config.allowSelfSignedCertificates;
    });

    // Auto-login with scanned config
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final success = await authProvider.login(
      serverUrl: config.serverUrl,
      localUrl: config.localUrl,
      username: config.username,
      password: config.password,
      useLegacyAuth: config.useLegacyAuth || config.serverFamily == 'daoliyu',
      allowSelfSignedCertificates: config.allowSelfSignedCertificates,
      profileName: config.name,
      serverFamily: config.serverFamily,
    );

    if (!success && mounted) {
      setState(
        () => _loginError = authProvider.error ??
            AppLocalizations.of(context)!.failedToConnectToServer,
      );
    } else if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.qrConfigImported),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // 与表单登录一致：弹到根路由显示首页。
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _useLocalFiles() async {
    final localService = Provider.of<LocalMusicService>(context, listen: false);

    final granted = await localService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.storagePermissionRequired,
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (Platform.isIOS) {
      setState(() {
        _isScanning = true;
        _scanProgress = 0.0;
        _scanStatus = AppLocalizations.of(context)!.selectMusicFiles;
      });
      try {
        final added = await localService.pickAndAddFiles();
        if (mounted) {
          if (localService.songs.isNotEmpty) {
            final authProvider =
                Provider.of<AuthProvider>(context, listen: false);
            await authProvider.setLocalOnlyMode(true);
            _popIfPushed();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(added == 0
                    ? AppLocalizations.of(context)!.noFilesSelected
                    : AppLocalizations.of(context)!.noMusicFilesFound),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } finally {
        if (mounted) setState(() => _isScanning = false);
      }
      return;
    }

    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanStatus = AppLocalizations.of(context)!.startingScan;
    });

    void updateProgress() {
      if (mounted) {
        setState(() {
          _scanProgress = localService.scanProgress;
          _scanStatus = localService.scanStatus;
        });
      }
    }

    localService.addListener(updateProgress);

    try {
      await localService.scanForMusic();

      if (mounted) {
        if (localService.songs.isNotEmpty) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          await authProvider.setLocalOnlyMode(true);
          _popIfPushed();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.noMusicFilesFound),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } finally {
      localService.removeListener(updateProgress);
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final isLoading = authProvider.state == AuthState.authenticating;
    final theme = Theme.of(context);
    final isBusy = isLoading || _isScanning;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(ScreenHelper.loginPadding(context)),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(
                            child: Container(
                              width: ScreenHelper.loginLogoSize(context),
                              height: ScreenHelper.loginLogoSize(context),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.appleMusicRed.withValues(
                                      alpha: 0.4,
                                    ),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Transform.translate(
                                  offset: const Offset(0, 8),
                                  child: Image.asset(
                                    'assets/logobig.png',
                                    width: ScreenHelper.loginLogoSize(context),
                                    height: ScreenHelper.loginLogoSize(context),
                                    fit: BoxFit.fill,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            AppLocalizations.of(context)!.appName,
                            style: theme.textTheme.displayLarge?.copyWith(
                              fontSize: ScreenHelper.isSmallScreen(context)
                                  ? 32
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppLocalizations.of(context)!
                                .connectToServerSubtitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightSecondaryText,
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SavedProfilesSwitcher(
                            onProfileSelected: (profile) async {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              await authProvider.switchProfile(profile);
                              if (mounted && authProvider.error != null) {
                                setState(
                                  () => _loginError = authProvider.error,
                                );
                              }
                            },
                            onProfileDeleted: (profile) async {
                              final authProvider = Provider.of<AuthProvider>(
                                context,
                                listen: false,
                              );
                              await authProvider.deleteProfile(profile);
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          _ServerFamilyToggle(
                            serverFamily: _serverFamily,
                            onChanged: (v) => setState(() {
                              _serverFamily = v;
                              // 道理鱼只认明文 p=，切到 daoliyu 时强制开启 legacy auth。
                              _useLegacyAuth = v == 'daoliyu';
                            }),
                          ),
                          const SizedBox(height: 16),
                          if (_serverFamily == 'youtube') ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF0000).withAlpha(20),
                                border: Border.all(
                                  color: const Color(0xFFFF0000).withAlpha(80),
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    CupertinoIcons.info_circle,
                                    color: Color(0xFFFF0000),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      AppLocalizations.of(
                                        context,
                                      )!
                                          .youtubeMusicDescription,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white70
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            TextFormField(
                              controller: _serverController,
                              focusNode: _serverFocusNode,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _localServerFocusNode.requestFocus(),
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.serverUrl,
                                hintText:
                                    AppLocalizations.of(context)!.serverUrlHint,
                                prefixIcon: const Icon(CupertinoIcons.globe),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                final url = (value ?? '').trim();
                                // 远程与局域网都为空才提示（支持仅局域网配置）——
                                // 与 _login() 的「至少填一个地址」校验一致，避免
                                // 空表单提交时只走 submit-time 的硬编码中文提示。
                                if (url.isEmpty &&
                                    _localServerController.text
                                        .trim()
                                        .isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .pleaseEnterServerUrl;
                                }
                                if (url.isNotEmpty &&
                                    !url.startsWith('http://') &&
                                    !url.startsWith('https://')) {
                                  return AppLocalizations.of(context)!
                                      .invalidUrlFormat;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _localServerController,
                              focusNode: _localServerFocusNode,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _usernameFocusNode.requestFocus(),
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!.lanUrl,
                                hintText:
                                    AppLocalizations.of(context)!.lanUrlHint,
                                prefixIcon: const Icon(CupertinoIcons.wifi),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return null;
                                final url = value.trim();
                                if (!url.startsWith('http://') &&
                                    !url.startsWith('https://')) {
                                  return AppLocalizations.of(context)!
                                      .invalidUrlFormat;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              focusNode: _usernameFocusNode,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              onFieldSubmitted: (_) =>
                                  _passwordFocusNode.requestFocus(),
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.username,
                                prefixIcon: const Icon(CupertinoIcons.person),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .pleaseEnterUsername;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              focusNode: _passwordFocusNode,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) {
                                if (!isBusy) _login();
                              },
                              decoration: InputDecoration(
                                labelText:
                                    AppLocalizations.of(context)!.password,
                                prefixIcon: const Icon(CupertinoIcons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? CupertinoIcons.eye
                                        : CupertinoIcons.eye_slash,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return AppLocalizations.of(context)!
                                      .pleaseEnterPassword;
                                }
                                return null;
                              },
                            ),
                          ],
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CupertinoSwitch(
                                value: _useLegacyAuth,
                                activeTrackColor: AppTheme.appleMusicRed,
                                onChanged: _serverFamily == 'daoliyu'
                                    ? null // 道理鱼强制明文认证，不可关闭
                                    : (value) {
                                        setState(() {
                                          _useLegacyAuth = value;
                                        });
                                      },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .legacyAuthentication,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .legacyAuthSubtitle,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              CupertinoSwitch(
                                value: _allowSelfSignedCertificates,
                                activeTrackColor: AppTheme.appleMusicRed,
                                onChanged: (value) {
                                  setState(() {
                                    _allowSelfSignedCertificates = value;
                                  });
                                },
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppLocalizations.of(context)!
                                          .allowSelfSignedCerts,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      AppLocalizations.of(context)!
                                          .allowSelfSignedSubtitle,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          InkWell(
                            onTap: () {
                              setState(() {
                                _showAdvancedOptions = !_showAdvancedOptions;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _showAdvancedOptions
                                      ? CupertinoIcons.chevron_down
                                      : CupertinoIcons.chevron_right,
                                  size: 18,
                                  color: theme.textTheme.bodyMedium?.color,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  AppLocalizations.of(context)!.advancedOptions,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showAdvancedOptions) ...[
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _profileNameController,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: AppLocalizations.of(context)!
                                    .profileNameLabel,
                                hintText: AppLocalizations.of(context)!
                                    .profileNameHint,
                                prefixIcon: const Icon(CupertinoIcons.tag),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.brightness == Brightness.dark
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFF2F2F7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppLocalizations.of(context)!
                                        .customTlsCertificate,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .customCertificateSubtitle,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  if (_customCertificateName != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? const Color(0xFF3C3C3E)
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            CupertinoIcons.doc_fill,
                                            size: 20,
                                            color: AppTheme.appleMusicRed,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _customCertificateName!,
                                              style: theme.textTheme.bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              CupertinoIcons.xmark_circle_fill,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _customCertificatePath = null;
                                                _customCertificateName = null;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _pickCertificateFile,
                                        icon: const Icon(
                                          CupertinoIcons.doc_on_clipboard,
                                        ),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .selectCertificateFile,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.appleMusicRed,
                                          side: BorderSide(
                                            color: AppTheme.appleMusicRed
                                                .withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)!
                                        .clientCertificate,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    AppLocalizations.of(
                                      context,
                                    )!
                                        .clientCertificateSubtitle,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 12),
                                  if (_clientCertificateName != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color:
                                            theme.brightness == Brightness.dark
                                                ? const Color(0xFF3C3C3E)
                                                : Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.security_rounded,
                                            size: 20,
                                            color: AppTheme.appleMusicRed,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _clientCertificateName!,
                                              style: theme.textTheme.bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              CupertinoIcons.xmark_circle_fill,
                                              size: 20,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _clientCertificatePath = null;
                                                _clientCertificateName = null;
                                                _clientCertPasswordController
                                                    .clear();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _clientCertPasswordController,
                                      obscureText: _obscureClientCertPassword,
                                      decoration: InputDecoration(
                                        hintText: AppLocalizations.of(
                                          context,
                                        )!
                                            .clientCertPassword,
                                        prefixIcon: const Icon(
                                          CupertinoIcons.lock,
                                          size: 20,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _obscureClientCertPassword
                                                ? CupertinoIcons.eye
                                                : CupertinoIcons.eye_slash,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(() {
                                            _obscureClientCertPassword =
                                                !_obscureClientCertPassword;
                                          }),
                                        ),
                                        isDense: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 10,
                                        ),
                                      ),
                                    ),
                                  ] else
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton.icon(
                                        onPressed: _pickClientCertificate,
                                        icon:
                                            const Icon(Icons.security_rounded),
                                        label: Text(
                                          AppLocalizations.of(
                                            context,
                                          )!
                                              .selectClientCertificate,
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor:
                                              AppTheme.appleMusicRed,
                                          side: BorderSide(
                                            color: AppTheme.appleMusicRed
                                                .withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),
                          _buildErrorCard(theme),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.appleMusicRed,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      AppLocalizations.of(context)!.connect,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Expanded(child: Divider()),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  AppLocalizations.of(context)!.or,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppTheme.lightSecondaryText,
                                  ),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton.icon(
                              onPressed: isBusy ? null : _scanQrCode,
                              icon:
                                  const Icon(CupertinoIcons.qrcode_viewfinder),
                              label: Text(
                                AppLocalizations.of(context)!.scanQrCode,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.appleMusicRed,
                                side: const BorderSide(
                                    color: AppTheme.appleMusicRed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          if (!Platform.isIOS) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: OutlinedButton.icon(
                                onPressed: isBusy ? null : _useLocalFiles,
                                icon: _isScanning
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            AppTheme.appleMusicRed,
                                          ),
                                        ),
                                      )
                                    : const Icon(CupertinoIcons.folder),
                                label: Text(
                                  _isScanning
                                      ? _scanStatus
                                      : AppLocalizations.of(context)!
                                          .useLocalFiles,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.appleMusicRed,
                                  side: const BorderSide(
                                      color: AppTheme.appleMusicRed),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                          if (!Platform.isIOS && _isScanning) ...[
                            const SizedBox(height: 12),
                            LinearProgressIndicator(
                              value: _scanProgress > 0 ? _scanProgress : null,
                              backgroundColor:
                                  AppTheme.appleMusicRed.withValues(
                                alpha: 0.2,
                              ),
                              color: AppTheme.appleMusicRed,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (Navigator.of(context).canPop())
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(CupertinoIcons.xmark),
                  tooltip: AppLocalizations.of(context)!.close,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavedProfilesSwitcher extends StatefulWidget {
  final Future<void> Function(ServerConfig) onProfileSelected;
  final Future<void> Function(ServerConfig) onProfileDeleted;

  const _SavedProfilesSwitcher({
    required this.onProfileSelected,
    required this.onProfileDeleted,
  });

  @override
  State<_SavedProfilesSwitcher> createState() => _SavedProfilesSwitcherState();
}

class _SavedProfilesSwitcherState extends State<_SavedProfilesSwitcher> {
  Future<List<ServerConfig>>? _profilesFuture;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _reload();
    }
  }

  void _reload() {
    _profilesFuture = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).getSavedProfiles();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ServerConfig>>(
      future: _profilesFuture,
      builder: (context, snap) {
        final profiles = snap.data ?? [];
        if (profiles.isEmpty) return const SizedBox.shrink();

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final l10n = AppLocalizations.of(context)!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.savedProfiles,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: profiles.map((profile) {
                final label = profile.name?.isNotEmpty == true
                    ? profile.name!
                    : '${profile.username}@${Uri.tryParse(profile.serverUrl)?.host ?? profile.serverUrl}';
                return InputChip(
                  avatar: const Icon(
                    CupertinoIcons.person_crop_circle,
                    size: 18,
                  ),
                  label: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  tooltip: '${profile.username} – ${profile.serverUrl}',
                  onPressed: () async {
                    await widget.onProfileSelected(profile);
                    if (mounted) setState(_reload);
                  },
                  onDeleted: () async {
                    await widget.onProfileDeleted(profile);
                    if (mounted) setState(_reload);
                  },
                  deleteIcon: const Icon(CupertinoIcons.xmark_circle, size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.tapProfileToConnect,
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ServerFamilyToggle extends StatelessWidget {
  final String serverFamily;
  final ValueChanged<String> onChanged;

  const _ServerFamilyToggle({
    required this.serverFamily,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : Colors.black87;
    final l10n = AppLocalizations.of(context)!;

    final chips = [
      (
        label: 'Subsonic',
        family: 'subsonic',
        icon: CupertinoIcons.music_note,
        activeColor: const Color(0xFF6366F1),
      ),
      (
        label: 'Emby / Jellyfin',
        family: 'jellyfin',
        icon: CupertinoIcons.tv,
        activeColor: const Color(0xFF6366F1),
      ),
      (
        label: '道理鱼',
        family: 'daoliyu',
        icon: CupertinoIcons.music_note_list,
        activeColor: const Color(0xFF6366F1),
      ),
      // (
      //   label: 'YouTube Music',
      //   family: 'youtube',
      //   icon: CupertinoIcons.play_rectangle,
      //   activeColor: const Color(0xFFFF0000),
      // ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.serverType,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips.map((c) {
            final selected = serverFamily == c.family;
            return GestureDetector(
              onTap: () => onChanged(c.family),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected
                      ? c.activeColor.withAlpha(30)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected
                        ? c.activeColor
                        : (isDark ? Colors.white24 : Colors.black26),
                    width: selected ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      c.icon,
                      size: 16,
                      color: selected ? c.activeColor : labelColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      c.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                        color: selected ? c.activeColor : labelColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
