import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/music_folder.dart';
import '../models/server_config.dart';
import '../providers/auth_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../utils/local_library_launcher.dart';
import '../widgets/luobo/capsule_button.dart';
import '../widgets/luobo/glass_circle_button.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';
import '../widgets/luobo/sheet_shell.dart';
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

/// 连接表单页（登录第 2 步）：分组卡片 + 填充式无边框输入。
///
/// 三种进入方式：
/// - 登录网关页「＋ 添加服务器」→ [initialConfig] 为空，标题「添加服务器」
/// - 设置「已保存配置」二级页编辑 → [initialConfig] 非空，标题「编辑服务器」
/// - `LoginScreen(initialConfig:)` 兼容入口（旧调用点保留）
///
/// 服务器类型默认「自动检测」：按 subsonic 通道登录（Subsonic/Jellyfin/
/// 道理鱼均接受该通道），成功后展示以 ping 自报的 serverType 为准
/// （`ServerFamilyInfo.of` 兜底显示），不新增网络行为。
class ServerFormScreen extends StatefulWidget {
  final ServerConfig? initialConfig;

  /// 「扫码添加」带回来的配置：走**添加流程**的预填
  /// （不进编辑态、跳过类型网格，用户可先核对地址与账号再连接）。
  final ServerConfig? prefillConfig;

  const ServerFormScreen({super.key, this.initialConfig, this.prefillConfig});

  @override
  State<ServerFormScreen> createState() => _ServerFormScreenState();
}

class _ServerFormScreenState extends State<ServerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  final _localServerController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _profileNameController = TextEditingController();
  final _serverFocusNode = FocusNode();
  final _localServerFocusNode = FocusNode();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  bool _useLegacyAuth = false;
  bool _allowSelfSignedCertificates = false;
  bool _obscurePassword = true;
  bool _showAdvancedOptions = false;

  /// 'auto' | 'subsonic' | 'jellyfin' | 'daoliyu'（'youtube' 仅防御性保留，
  /// 兼容历史 profile，UI 上不可选）。
  String _serverFamily = 'auto';

  /// 添加流程（B3）：是否已选定服务器类型。
  /// 未选定时先显示**类型网格**，选定后才进入表单（设计稿 B3 的提示原文：
  /// 「选定类型后进入表单填写地址与账号」）。编辑流程直接进表单。
  bool _typeChosen = false;

  String? _customCertificatePath;
  String? _customCertificateName;
  String? _clientCertificatePath;
  String? _clientCertificateName;
  final _clientCertPasswordController = TextEditingController();
  bool _obscureClientCertPassword = true;

  String? _loginError;

  // ── 音乐库范围（§9.6：并入本页，并从多选改为**单选**） ──────────────────
  /// 「全部」哨兵值（对应 `selectedMusicFolderIds` 为空）。
  static const String _allFoldersId = '__all__';
  List<MusicFolder>? _folders;
  List<String> _selectedFolderIds = const [];
  bool _foldersRequested = false;

  bool get _isEdit => widget.initialConfig != null;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  /// 只有**正在编辑当前已连接的服务器**时才显示「音乐库范围」：
  /// `getMusicFolders()` 走当前登录态，对别的服务器会取到错的文件夹列表。
  bool get _canPickMusicFolder {
    final initial = widget.initialConfig;
    if (initial == null) return false;
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return auth.config?.serverUrl == initial.serverUrl &&
        auth.config?.username == initial.username;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_foldersRequested || !_canPickMusicFolder) return;
    _foldersRequested = true;
    _selectedFolderIds =
        widget.initialConfig?.selectedMusicFolderIds ?? const [];
    _loadMusicFolders();
  }

  Future<void> _loadMusicFolders() async {
    final subsonic = Provider.of<SubsonicService>(context, listen: false);
    final folders = await subsonic.getMusicFolders();
    if (!mounted) return;
    setState(() => _folders = folders);
  }

  /// 「音乐库范围」行 —— 单值（Subsonic 的 `musicFolderId` 本就是单值参数）。
  ///
  /// ⚠️ 存着的 id 若已不在服务端返回的列表里（服务端删了该文件夹），
  /// **显示原 id 而不是「全部」** —— 静默回落会让人以为范围已经是全部。
  Widget _musicFolderTile() {
    final l10n = AppLocalizations.of(context)!;
    final folders = _folders;
    final id =
        _selectedFolderIds.isEmpty ? _allFoldersId : _selectedFolderIds.first;

    String value;
    if (id == _allFoldersId) {
      value = l10n.filterAll;
    } else {
      value = id;
      for (final folder in folders ?? const <MusicFolder>[]) {
        if (folder.id == id) {
          value = folder.name;
          break;
        }
      }
    }

    return LuoboRow(
      icon: AppIcons.folder,
      title: l10n.musicFoldersDialogTitle,
      value: folders == null ? null : value,
      showChevron: folders != null,
      onTap: folders == null ? null : _showMusicFolderSheet,
    );
  }

  /// 单选 Sheet（设计稿 D1 范式）。
  Future<void> _showMusicFolderSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final folders = _folders;
    if (folders == null) return;

    final currentId =
        _selectedFolderIds.isEmpty ? _allFoldersId : _selectedFolderIds.first;

    final selected = await showLuoboPickerSheet<String>(
      context: context,
      title: l10n.musicFoldersDialogTitle,
      selected: currentId,
      options: [
        (value: _allFoldersId, label: l10n.filterAll),
        for (final folder in folders) (value: folder.id, label: folder.name),
      ],
    );
    if (selected == null || !mounted) return;

    final ids = selected == _allFoldersId ? <String>[] : <String>[selected];
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .updateSelectedMusicFolderIds(ids);
    } catch (e) {
      debugPrint('[ServerForm] save music folder failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.operationFailed),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _selectedFolderIds = ids);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.musicFoldersSaved),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _serverController.addListener(_clearError);
    _localServerController.addListener(_clearError);
    _usernameController.addListener(_clearError);
    _passwordController.addListener(_clearError);
    _profileNameController.addListener(_clearError);
    _prefillFromConfig(widget.initialConfig ?? widget.prefillConfig);
    if (widget.prefillConfig != null) _typeChosen = true;
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

  /// 预填已有配置（编辑模式）。
  void _prefillFromConfig(ServerConfig? config) {
    if (config == null) return;
    _serverController.text =
        config.serverUrl == 'local' ? '' : config.serverUrl;
    _localServerController.text = config.localUrl ?? '';
    _usernameController.text = config.username;
    _passwordController.text = config.password;
    _profileNameController.text = config.name ?? '';
    _serverFamily = _normalizeFamily(config.serverFamily);
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

  /// 历史 profile 可能带 'youtube' 等家族，保留原值防御性处理；
  /// 未知/空家族归为「自动检测」。
  String _normalizeFamily(String family) {
    const known = {'subsonic', 'jellyfin', 'daoliyu', 'youtube'};
    return known.contains(family) ? family : 'auto';
  }

  void _clearError() {
    if (_loginError != null && mounted) {
      setState(() => _loginError = null);
    }
  }

  // ── 服务器类型网格（设计稿 B3「添加服务器」第一步） ────────────────────

  bool get _showTypePicker => !_isEdit && !_typeChosen;

  Widget _buildTypePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);

    Widget tile({
      required String family,
      required String label,
      required IconData icon,
      required Color color,
    }) {
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() {
            _serverFamily = family;
            // 道理鱼只认明文 p=，选中即强制 legacy 认证。
            _useLegacyAuth = family == 'daoliyu';
            _typeChosen = true;
          }),
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(LuoboRadius.tile),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration:
                      BoxDecoration(color: color, shape: BoxShape.circle),
                  child: Icon(icon, color: LuoboAccent.onAccent, size: 17),
                ),
                const SizedBox(height: 7),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: LuoboType.caption.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: c.fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: c.bg,
      appBar: AppBar(
        // 与设计体系二级页对齐：玻璃圆返回 + 15px 居中标题。
        // （本路由是**全屏表单流**，表单步骤同样用这套页头 —— 两步形态一致，
        //  故不套 `SettingsSubPage`，否则同路由内页头会跳变。）
        leading: const GlassBackButton(),
        title: Text(
          l10n.addServer,
          style: LuoboType.navTitle.copyWith(color: c.fg),
        ),
        centerTitle: true,
        backgroundColor: c.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: LuoboSpacing.pageX),
            child: GlassCircleButton(
              icon: AppIcons.scan,
              tooltip: l10n.scanQrCode,
              onPressed: _scanToPrefill,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          LuoboSpacing.pageX,
          LuoboSpacing.pageY,
          LuoboSpacing.pageX,
          LuoboSpacing.pageBottom,
        ),
        children: [
          LuoboSectionHeader(l10n.serverType),
          LuoboCard(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: LuoboSpacing.rowX,
                  vertical: LuoboSpacing.rowY,
                ),
                child: Row(
                  children: [
                    tile(
                      family: 'auto',
                      label: l10n.serverTypeAuto,
                      icon: AppIcons.ai,
                      color: LuoboAccent.accent,
                    ),
                    const SizedBox(width: 9),
                    tile(
                      family: 'subsonic',
                      label: l10n.serverTypeSubsonic,
                      icon: AppIcons.music,
                      color: LuoboAccent.familySubsonic,
                    ),
                    const SizedBox(width: 9),
                    tile(
                      family: 'jellyfin',
                      label: l10n.serverTypeJellyfin,
                      icon: AppIcons.radio,
                      color: LuoboAccent.familyJellyfin,
                    ),
                    const SizedBox(width: 9),
                    tile(
                      family: 'daoliyu',
                      label: l10n.serverTypeDaoliyu,
                      icon: AppIcons.playlist,
                      color: LuoboAccent.familyDaoliyu,
                    ),
                  ],
                ),
              ),
            ],
          ),
          LuoboHint(l10n.serverTypeGridHint),
          LuoboSectionHeader(l10n.otherWays),
          LuoboCard(
            children: [
              LuoboRow(
                icon: AppIcons.scan,
                title: l10n.scanQrCode,
                onTap: _scanToPrefill,
              ),
              const LuoboDivider(indent: LuoboDivider.withIcon),
              LuoboRow(
                icon: AppIcons.folder,
                title: l10n.useLocalFiles,
                onTap: _useLocalLibrary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 「其他方式 → 使用本地音乐文件」。
  ///
  /// ⚠️ 该流程会 `setLocalOnlyMode(true)`，即**断开当前服务器**改用本地曲库
  /// （从「已连接的服务器」页进来时这属于破坏性操作），所以先弹确认框。
  Future<void> _useLocalLibrary() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.useLocalFilesConfirmTitle),
        content: Text(l10n.useLocalFilesConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    // 与登录网关页共用同一份实现（utils/local_library_launcher.dart）。
    final switched = await launchLocalLibrary(context);
    if (!mounted || !switched) return;
    // 已切到本地模式：路由栈上这些「服务器」页面已无意义，回到根。
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  /// 扫码后**预填表单**（而不是直接登录）——添加流程里用户应先确认地址与账号。
  Future<void> _scanToPrefill() async {
    final config = await Navigator.push<ServerConfig>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (config == null || !mounted) return;
    setState(() {
      _prefillFromConfig(config);
      _typeChosen = true;
    });
  }

  // ── 登录 ────────────────────────────────────────────────────────────

  Future<void> _login() async {
    // 保持 'auto' 原值传给 login()：按 subsonic 通道登录（Jellyfin 的
    // subsonic 兼容端点同样接受密码认证），并把 'auto' 落盘——下次编辑仍显示
    // 「自动检测」，与用户选择一致（未知家族在下游均按 subsonic 处理）。
    final effectiveFamily = _serverFamily;

    // YouTube Music requires no credentials — skip form validation
    if (effectiveFamily != 'youtube') {
      if (!_formKey.currentState!.validate()) return;
    }

    setState(() => _loginError = null);

    var serverUrl = effectiveFamily == 'youtube'
        ? 'https://music.youtube.com'
        : _serverController.text.trim();
    final localUrl = _localServerController.text.trim();

    // 两字段皆空已由服务器地址字段 validator（pleaseEnterServerUrl）拦截，
    // 无需在此重复处理（旧 login_screen 的硬编码中文兜底为不可达分支，已移除）。

    // 仅填局域网地址时，把它同时作为主地址（见旧 login_screen.dart 注释：
    // 保证 LAN-only 配置的「不转码」规则生效，且重存 profile 时两字段一致）。
    final isLanOnly = effectiveFamily != 'youtube' &&
        localUrl.isNotEmpty &&
        (serverUrl.isEmpty || localUrl == serverUrl);
    if (isLanOnly && serverUrl.isEmpty) {
      serverUrl = localUrl;
    }

    if (effectiveFamily != 'youtube' &&
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
        serverFamily: effectiveFamily,
      );
    } catch (e) {
      // login() 内部已兜底返回 false，此处防御异常，避免卡 loading。
      debugPrint('[Login] login() threw: $e');
      success = false;
    }

    if (!mounted) return;

    if (success) {
      // 先取 root messenger，pop 后再显示——避免 SnackBar 因 context 随
      // pop 销毁而被吞。
      final messenger = ScaffoldMessenger.of(context);
      // 统一 pop 回来源页（设置二级页 / 网关），带回 true 触发列表刷新：
      // - 设置二级页新增：回列表并刷新，不再被 popUntil 甩回首页；
      // - 网关（根）场景：pop 后 AuthWrapper 已按 state 换成 MainScreen，
      //   与 popUntil(isFirst) 效果一致。
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.connectedSuccessfully),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(
        () => _loginError = authProvider.error ??
            AppLocalizations.of(context)!.failedToConnectToServer,
      );
    }
  }

  // ── 证书选择（与旧登录页一致） ───────────────────────────────────────

  Future<void> _pickClientCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx', 'pem'],
        dialogTitle: AppLocalizations.of(context)!.selectClientCertificate,
      );
      if (result != null && result.files.single.path != null && mounted) {
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
              AppLocalizations.of(context)!
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

      if (result != null && result.files.single.path != null && mounted) {
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

  // ── 服务器类型底部弹层 ──────────────────────────────────────────────

  String get _serverFamilyLabel {
    final l10n = AppLocalizations.of(context)!;
    return switch (_serverFamily) {
      'subsonic' => l10n.serverTypeSubsonic,
      'jellyfin' => l10n.serverTypeJellyfin,
      'daoliyu' => l10n.serverTypeDaoliyu,
      // 历史 youtube profile 防御性保留（与 ServerFamilyInfo 文案一致）。
      'youtube' => 'YouTube Music',
      _ => l10n.serverTypeAuto,
    };
  }

  Future<void> _showServerTypeSheet() async {
    final l10n = AppLocalizations.of(context)!;
    final options = [
      (
        family: 'auto',
        label: l10n.serverTypeAuto,
        subtitle: l10n.serverTypeAutoSubtitle,
        icon: CupertinoIcons.sparkles,
        color: LuoboAccent.accent,
      ),
      (
        family: 'subsonic',
        label: l10n.serverTypeSubsonic,
        subtitle: null,
        icon: CupertinoIcons.music_note,
        color: LuoboAccent.familySubsonic,
      ),
      (
        family: 'jellyfin',
        label: l10n.serverTypeJellyfin,
        subtitle: null,
        icon: CupertinoIcons.tv,
        color: LuoboAccent.familyJellyfin,
      ),
      (
        family: 'daoliyu',
        label: l10n.serverTypeDaoliyu,
        subtitle: null,
        icon: CupertinoIcons.music_note_list,
        color: LuoboAccent.familyDaoliyu,
      ),
    ];

    // 单选 Sheet（设计稿 D1 范式）：居中标题 + 每项一张独立白卡 + 玫红勾。
    // ⚠️ 未选中项**什么都不带**（不带 chevron）——带 chevron 会让人以为
    // 「点进去还有一层」（§2.3 铁律）。
    final selected = await showLuoboSheet<String>(
      context: context,
      title: l10n.selectServerType,
      builder: (sheetContext) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final opt in options)
            LuoboSheetRow(
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: opt.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(LuoboRadius.avatar),
                ),
                child: Icon(opt.icon, color: opt.color, size: 17),
              ),
              title: opt.label,
              subtitle: opt.subtitle,
              selected: _serverFamily == opt.family,
              showChevron: false,
              onTap: () => Navigator.of(sheetContext).pop(opt.family),
            ),
        ],
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _serverFamily = selected;
        // 道理鱼只认明文 p=，选中即强制 legacy 认证（开关同步禁用）。
        _useLegacyAuth = selected == 'daoliyu';
      });
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isLoading =
        Provider.of<AuthProvider>(context).state == AuthState.authenticating;

    // 添加流程第一步：先选服务器类型（设计稿 B3）。
    if (_showTypePicker) return _buildTypePicker(context);

    return Scaffold(
      // 与搜索页一致：窗口不随键盘缩放（resize 在此设备上会留下「键盘上方
      // 空白带 + 内容被顶起」）。底部字段可见性改由滚动区键盘高度留白 +
      // 输入框 scrollPadding 保证。
      resizeToAvoidBottomInset: false,
      backgroundColor:
          _isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
      appBar: AppBar(
        // 与设计体系二级页对齐（同路由的类型网格步骤用的是同一套页头）。
        leading: const GlassBackButton(),
        title: Text(
          _isEdit ? l10n.editServer : l10n.addServer,
          style: LuoboType.navTitle.copyWith(color: LuoboColors.of(context).fg),
        ),
        centerTitle: true,
        backgroundColor:
            _isDark ? AppTheme.darkBackground : AppTheme.lightBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        // 点击空白区域收起键盘（输入框等子级点击优先命中，不受影响）。
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          // Android 15+ 强制 edge-to-edge：键盘弹出时 MediaQuery.viewPadding 会
          // 镜像键盘高度，底部 SafeArea 若再避让会造成「键盘上方空白带 + 内容
          // 被顶起」。键盘弹出时禁用底部避让（Scaffold 已按 viewInsets 缩放 body），
          // 收起时恢复以避开系统导航条。
          bottom: MediaQuery.viewInsetsOf(context).bottom == 0,
          child: SingleChildScrollView(
            // 拖动页面时顺带收起键盘。
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              // 底部按键盘高度留白：窗口不缩放，靠滚动把内容抬到键盘上方。
              16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: Align(
              // 内容顶部对齐：键盘弹出时输入框自动滚动到键盘上方，
              // 不再因垂直居中在键盘与内容之间留下空白。
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 无分组标题、无白卡外壳：参考物（飞牛「新建歌单」表单）就是
                      // 「标签在上 + 一摞独立白块」，块间 20dp。
                      _urlField(
                        controller: _serverController,
                        focusNode: _serverFocusNode,
                        label: l10n.serverUrl,
                        hint: l10n.serverUrlHint,
                        icon: CupertinoIcons.globe,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _localServerFocusNode.requestFocus(),
                        validator: (value) {
                          final url = (value ?? '').trim();
                          if (url.isEmpty &&
                              _localServerController.text.trim().isEmpty) {
                            return l10n.pleaseEnterServerUrl;
                          }
                          if (url.isNotEmpty &&
                              !url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            return l10n.invalidUrlFormat;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),
                      _urlField(
                        controller: _localServerController,
                        focusNode: _localServerFocusNode,
                        label: l10n.lanUrl,
                        hint: l10n.lanUrlHint,
                        icon: CupertinoIcons.wifi,
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _usernameFocusNode.requestFocus(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return null;
                          }
                          final url = value.trim();
                          if (!url.startsWith('http://') &&
                              !url.startsWith('https://')) {
                            return l10n.invalidUrlFormat;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),
                      _serverTypeTile(),
                      // 「音乐库范围」并入本页（§9.6 拍板）：语义上是**服务器属性**，
                      // 不是内容管理。仅当编辑的正是**当前连接**时才有数据来源
                      // —— getMusicFolders() 走的是当前登录态，对别的服务器会取错。
                      if (_canPickMusicFolder) ...[
                        const SizedBox(height: _fieldGap),
                        _groupCard([_musicFolderTile()]),
                      ],
                      const SizedBox(height: _fieldGap),
                      _urlField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        label: l10n.username,
                        hint: l10n.usernameHint,
                        icon: CupertinoIcons.person,
                        autocorrect: false,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) =>
                            _passwordFocusNode.requestFocus(),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.pleaseEnterUsername;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: _fieldGap),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _fieldLabel(l10n.password),
                          TextFormField(
                            controller: _passwordController,
                            focusNode: _passwordFocusNode,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!isLoading) _login();
                            },
                            scrollPadding: EdgeInsets.only(
                              bottom:
                                  MediaQuery.viewInsetsOf(context).bottom + 16,
                            ),
                            decoration: _filledDecoration(
                              hint: l10n.passwordHint,
                              icon: CupertinoIcons.lock,
                              suffix: IconButton(
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
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.pleaseEnterPassword;
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _advancedExpander(theme),
                      if (_showAdvancedOptions) ...[
                        const SizedBox(height: 16),
                        _groupCard(_advancedChildren(theme, l10n)),
                      ],
                      // ⚠️ 这两处间距不能省：`_buildErrorCard` 在无错误时返回
                      // `SizedBox.shrink()`，没有间距的话「高级选项」行会**紧贴**
                      // 主按钮（真机实测只剩 3.7dp）。
                      const SizedBox(height: 16),
                      _buildErrorCard(theme),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: LuoboCapsuleButton(
                          label: l10n.connect,
                          style: LuoboCapsuleStyle.primary,
                          onPressed: isLoading ? null : _login,
                        ),
                      ),
                      if (isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          l10n.formLocalOnlyNote,
                          textAlign: TextAlign.center,
                          style: LuoboType.caption.copyWith(
                            color: LuoboColors.of(context).fg2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 分组卡片 / 字段 ────────────────────────────────────────────────

  /// 分组卡 —— 设计体系 `LuoboCard`（白 / `#1C1C1E`、圆角 16、无阴影）。
  Widget _groupCard(List<Widget> children) {
    return SizedBox(
      width: double.infinity,
      child: LuoboCard(children: children),
    );
  }

  /// 高级选项区行间分隔线：通栏无缩进（该区为纯文本行/区块，无左对齐图标）。
  Widget _advancedDivider() => const LuoboDivider();

  /// 填充式输入块 —— 飞牛「新建歌单」表单实测复刻。
  ///
  /// 飞牛实测（1080px @3x，`06-歌曲菜单与信息/新建歌单-模态表单.jpg`）：
  /// - 块体**白底**（`#FFFFFF`，与卡片同色），不是灰底 —— 飞牛全站没有
  ///   「灰底内嵌输入框」这种元素，页面上一切面都是卡片色。
  /// - 块高 **52dp**；圆角与卡片同档（约 13–14dp，`LuoboRadius.field`）。
  /// - **标签在块外、块的上一行**（近黑 14dp，距块 8dp），块内只有
  ///   灰色占位符 —— 不是 Material 的浮动 label。
  ///
  /// ⚠️ 飞牛的页面左右边距是 20dp，本页沿用设计体系的 `LuoboSpacing.pageX`
  /// （16dp）—— 全站统一优先，不为一页破例。
  ///
  /// ⚠️ **图标槽压到 40、上下内边距 14**：默认 `prefixIconConstraints` 是
  /// 48×48、`contentPadding` 上下各 16，实测块高 56dp（比飞牛高 4dp）；
  /// 压到 40/14 后块高 52dp，与飞牛一致。
  /// （图标槽最小高度必须给 0，否则 48 的最小高会把整行重新撑回 56。）
  InputDecoration _filledDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
    Color? fill,
  }) {
    final c = LuoboColors.of(context);
    return InputDecoration(
      hintText: hint,
      // 飞牛实测占位符是 `#7E7E7E`（≈ fg2），不是更浅的 fg3 ——
      // 标签已经搬到块外，块内这行灰字就是字段的全部说明，不能太淡。
      hintStyle: LuoboType.body.copyWith(color: c.fg2),
      prefixIcon: Icon(icon, size: 18, color: c.fg2),
      prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 0),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      filled: true,
      // 页面级字段 = 白块；卡**内**的字段（高级选项）仍用灰底，
      // 否则白底叠白卡会整个消失。
      fillColor: fill ?? c.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(LuoboRadius.field),
        borderSide: BorderSide.none,
      ),
    );
  }

  /// 字段标签 —— 在输入块**上方**（飞牛形态），近黑 14dp / w500，
  /// 与块左对齐（块外再让 4dp，和飞牛的 24.7dp vs 20dp 同构）。
  Widget _fieldLabel(String text) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(text, style: LuoboType.body.copyWith(color: c.fg)),
    );
  }

  /// 输入块之间的竖向间隙 —— 飞牛「新建歌单」实测块高 52dp、节距 72dp，
  /// 箭头音乐「编辑服务器」实测块间距 19.7dp，取整 20。
  static const double _fieldGap = 20;

  /// 单个输入块 —— **标签在上 + 独立白块**（不包在白卡里）。
  Widget _urlField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    bool autocorrect = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onFieldSubmitted,
    FormFieldValidator<String>? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _fieldLabel(label),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          autocorrect: autocorrect,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          // resize:false 下键盘不挤压窗口：聚焦时把字段滚到键盘上方，
          // 默认 scrollPadding(20) 只会滚到屏幕底、被键盘盖住。
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          decoration: _filledDecoration(hint: hint, icon: icon),
          validator: validator,
        ),
      ],
    );
  }

  Widget _serverTypeTile() {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: AppIcons.server,
      title: l10n.serverType,
      value: _serverFamilyLabel,
      // 有状态值也要显示 chevron（与「音质偏好」那类「值 ›」行一致）。
      showChevron: true,
      onTap: _showServerTypeSheet,
    );
  }

  // ── 高级选项 ────────────────────────────────────────────────────────

  Widget _advancedExpander(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: () {
        setState(() => _showAdvancedOptions = !_showAdvancedOptions);
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
            l10n.advancedOptions,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _advancedChildren(ThemeData theme, AppLocalizations l10n) {
    return [
      _switchRow(
        title: l10n.legacyAuthentication,
        subtitle: l10n.legacyAuthSubtitle,
        value: _useLegacyAuth,
        onChanged: _serverFamily == 'daoliyu'
            ? null
            : (v) => setState(() => _useLegacyAuth = v),
      ),
      _advancedDivider(),
      _switchRow(
        title: l10n.allowSelfSignedCerts,
        subtitle: l10n.allowSelfSignedSubtitle,
        value: _allowSelfSignedCertificates,
        onChanged: (v) => setState(() => _allowSelfSignedCertificates = v),
      ),
      _advancedDivider(),
      _certSection(
        title: l10n.customTlsCertificate,
        subtitle: l10n.customCertificateSubtitle,
        fileName: _customCertificateName,
        onPick: _pickCertificateFile,
        onClear: () => setState(() {
          _customCertificatePath = null;
          _customCertificateName = null;
        }),
        selectLabel: l10n.selectCertificateFile,
        icon: CupertinoIcons.doc_fill,
      ),
      _advancedDivider(),
      _clientCertSection(theme, l10n),
      _advancedDivider(),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: TextFormField(
          controller: _profileNameController,
          autocorrect: false,
          scrollPadding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
          ),
          decoration: _filledDecoration(
            hint: l10n.profileNameHint,
            icon: CupertinoIcons.tag,
            // 这个字段在**白卡内部**，白底叠白卡会消失 —— 仍用灰底。
            fill: LuoboColors.of(context).divider,
          ),
        ),
      ),
    ];
  }

  Widget _switchRow({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _isDark
                        ? AppTheme.darkSecondaryText
                        : AppTheme.lightSecondaryText,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: AppTheme.appleMusicRed,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  /// 自定义 TLS 证书 / 客户端证书共用的「标题 + 说明 + 选择文件」区块。
  Widget _certSection({
    required String title,
    required String subtitle,
    required String? fileName,
    required VoidCallback onPick,
    required VoidCallback onClear,
    required String selectLabel,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (fileName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF3C3C3E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 20, color: AppTheme.appleMusicRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      CupertinoIcons.xmark_circle_fill,
                      size: 20,
                    ),
                    onPressed: onClear,
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPick,
                icon: Icon(icon),
                label: Text(selectLabel),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.appleMusicRed,
                  side: BorderSide(
                    color: AppTheme.appleMusicRed.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _clientCertSection(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.clientCertificate,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.clientCertificateSubtitle,
            style: TextStyle(
              fontSize: 12,
              color: _isDark
                  ? AppTheme.darkSecondaryText
                  : AppTheme.lightSecondaryText,
            ),
          ),
          const SizedBox(height: 12),
          if (_clientCertificateName != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isDark ? const Color(0xFF3C3C3E) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isDark ? AppTheme.darkDivider : AppTheme.lightDivider,
                ),
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
                      style: const TextStyle(fontSize: 14),
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
                        _clientCertPasswordController.clear();
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
              // 与其它输入框一致：resize:false 下聚焦时滚到键盘上方。
              scrollPadding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
              ),
              decoration: InputDecoration(
                hintText: l10n.clientCertPassword,
                prefixIcon: const Icon(CupertinoIcons.lock, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureClientCertPassword
                        ? CupertinoIcons.eye
                        : CupertinoIcons.eye_slash,
                    size: 20,
                  ),
                  onPressed: () => setState(() {
                    _obscureClientCertPassword = !_obscureClientCertPassword;
                  }),
                ),
                isDense: true,
                filled: true,
                fillColor:
                    _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
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
                icon: const Icon(Icons.security_rounded),
                label: Text(l10n.selectClientCertificate),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.appleMusicRed,
                  side: BorderSide(
                    color: AppTheme.appleMusicRed.withValues(alpha: 0.5),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── 错误卡（沿用旧登录页的分类提示） ─────────────────────────────────

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
        width: double.infinity,
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
                  icon: Icon(
                    Icons.copy_rounded,
                    size: 16,
                    color: color.withValues(alpha: 0.7),
                  ),
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
}
