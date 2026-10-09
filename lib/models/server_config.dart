class ServerConfig {
  final String serverUrl;
  final String? localUrl;
  final String username;
  final String password;
  final bool useLegacyAuth;
  final bool allowSelfSignedCertificates;
  final List<String> selectedMusicFolderIds;
  final String? serverType;
  final String? serverVersion;
  final String? customCertificatePath;
  final String? clientCertificatePath;
  final String? clientCertificatePassword;
  final String? name;
  final String serverFamily;
  final String? apiToken;
  final String? userId;

  ServerConfig({
    required this.serverUrl,
    this.localUrl,
    required this.username,
    required this.password,
    this.useLegacyAuth = false,
    this.allowSelfSignedCertificates = false,
    this.selectedMusicFolderIds = const [],
    this.serverType,
    this.serverVersion,
    this.customCertificatePath,
    this.clientCertificatePath,
    this.clientCertificatePassword,
    this.name,
    this.serverFamily = 'subsonic',
    this.apiToken,
    this.userId,
  });

  bool get isJellyfin => serverFamily == 'jellyfin';

  factory ServerConfig.fromJson(Map<String, dynamic> json) {
    return ServerConfig(
      serverUrl: json['serverUrl'] ?? '',
      localUrl: json['localUrl'] as String?,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      useLegacyAuth: json['useLegacyAuth'] ?? false,
      allowSelfSignedCertificates: json['allowSelfSignedCertificates'] ?? false,
      selectedMusicFolderIds: (json['selectedMusicFolderIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serverType: json['serverType'],
      serverVersion: json['serverVersion'],
      customCertificatePath: json['customCertificatePath'],
      clientCertificatePath: json['clientCertificatePath'],
      clientCertificatePassword: json['clientCertificatePassword'],
      name: json['name'] as String?,
      serverFamily: json['serverFamily'] as String? ?? 'subsonic',
      apiToken: json['apiToken'] as String?,
      userId: json['userId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serverUrl': serverUrl,
      'localUrl': localUrl,
      'username': username,
      'password': password,
      'useLegacyAuth': useLegacyAuth,
      'allowSelfSignedCertificates': allowSelfSignedCertificates,
      'selectedMusicFolderIds': selectedMusicFolderIds,
      'serverType': serverType,
      'serverVersion': serverVersion,
      'customCertificatePath': customCertificatePath,
      'clientCertificatePath': clientCertificatePath,
      'clientCertificatePassword': clientCertificatePassword,
      'name': name,
      'serverFamily': serverFamily,
      'apiToken': apiToken,
      'userId': userId,
    };
  }

  ServerConfig copyWith({
    String? serverUrl,
    String? localUrl,
    String? username,
    String? password,
    bool? useLegacyAuth,
    bool? allowSelfSignedCertificates,
    List<String>? selectedMusicFolderIds,
    String? serverType,
    String? serverVersion,
    String? customCertificatePath,
    String? clientCertificatePath,
    String? clientCertificatePassword,
    String? name,
    String? serverFamily,
    String? apiToken,
    String? userId,
  }) {
    return ServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      localUrl: localUrl ?? this.localUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      useLegacyAuth: useLegacyAuth ?? this.useLegacyAuth,
      allowSelfSignedCertificates:
          allowSelfSignedCertificates ?? this.allowSelfSignedCertificates,
      selectedMusicFolderIds:
          selectedMusicFolderIds ?? this.selectedMusicFolderIds,
      serverType: serverType ?? this.serverType,
      serverVersion: serverVersion ?? this.serverVersion,
      customCertificatePath:
          customCertificatePath ?? this.customCertificatePath,
      clientCertificatePath:
          clientCertificatePath ?? this.clientCertificatePath,
      clientCertificatePassword:
          clientCertificatePassword ?? this.clientCertificatePassword,
      name: name ?? this.name,
      serverFamily: serverFamily ?? this.serverFamily,
      apiToken: apiToken ?? this.apiToken,
      userId: userId ?? this.userId,
    );
  }

  String get normalizedUrl {
    String url = serverUrl.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'https://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  String? get normalizedLocalUrl {
    if (localUrl == null || localUrl!.trim().isEmpty) return null;
    String url = localUrl!.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  bool get hasLocalUrl => localUrl != null && localUrl!.trim().isNotEmpty;

  /// 展示用名称：优先用户起的 [name]，否则回退 `用户名@主机`。
  ///
  /// ⚠️ 这是**单一来源**：`saved_profiles_screen` 与 `server_detail_page` 都取它。
  /// `widgets/server_profile_card.dart` 里还有一份同名私有 getter（那个文件与
  /// 登录网关页共用、不许改），改动时两处要一起改。
  String get displayName {
    if (name?.isNotEmpty == true) return name!;
    return '$username@${Uri.tryParse(serverUrl)?.host ?? serverUrl}';
  }

  bool get isValid {
    return serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;
  }
}
