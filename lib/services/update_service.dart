import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'android_system_service.dart';

class ReleaseAsset {
  final String name;
  final String browserDownloadUrl;

  const ReleaseAsset({required this.name, required this.browserDownloadUrl});

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) => ReleaseAsset(
        name: json['name'] as String,
        browserDownloadUrl: json['browser_download_url'] as String,
      );
}

class ReleaseInfo {
  final String version;
  final String tagName;
  final String htmlUrl;

  final String body;
  final List<ReleaseAsset> assets;

  const ReleaseInfo({
    required this.version,
    required this.tagName,
    required this.htmlUrl,
    required this.body,
    required this.assets,
  });

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    final tag = json['tag_name'] as String? ?? '';
    return ReleaseInfo(
      version: tag.replaceFirst(RegExp(r'^v'), ''),
      tagName: tag,
      htmlUrl: json['html_url'] as String? ?? '',
      body: json['body'] as String? ?? '',
      assets: (json['assets'] as List<dynamic>?)
              ?.map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class UpdateService {
  static const String currentVersion = '1.1.28';

  static const String _apiUrl =
      'https://api.github.com/repos/chengsitom/Luobo/releases/latest';

  /// 最近一次检查到的新版本（null = 已是最新 / 尚未检查）。
  /// 冷启自动检查写入，设置页版本号行的角标与主动检查共享这份结果，
  /// 避免重复请求、也保证"弹窗提示有更新"和"角标提示有更新"口径一致。
  static final ValueNotifier<ReleaseInfo?> availableUpdate =
      ValueNotifier(null);

  /// 最近一次检查是否成功（用于区分"已是最新"和"网络失败"，后者不能谎报最新）。
  static bool lastCheckSucceeded = false;

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      headers: {
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
      },
    ),
  );

  static Future<ReleaseInfo?> checkForUpdate() async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(_apiUrl);
      final data = response.data;
      if (data == null) {
        // 2xx 但空响应体也按失败处理，否则沿用上次 lastCheckSucceeded=true
        // 会让主动检查谎报"已是最新版本"。
        debugPrint('UpdateService: empty response body');
        lastCheckSucceeded = false;
        return null;
      }

      final release = ReleaseInfo.fromJson(data);
      lastCheckSucceeded = true;
      if (_isNewer(release.version, currentVersion)) {
        availableUpdate.value = release;
        return release;
      }
      availableUpdate.value = null;
      return null;
    } catch (e) {
      debugPrint('UpdateService: check failed – $e');
      // 网络失败时不清空缓存：上次已知的新版本角标应保留。
      lastCheckSucceeded = false;
      return null;
    }
  }

  /// 按设备 ABI 从 release 资产中挑最合适的 APK。
  ///
  /// CI split-per-abi 产出 app-arm64-v8a-release.apk / app-armeabi-v7a-release.apk
  /// / app-x86_64-release.apk，另有通用 app-release.apk。按系统支持的 ABI
  /// 优先级匹配，找不到则回退通用包；都没有返回 null（调用方跳 release 页）。
  static Future<ReleaseAsset?> pickBestApk(ReleaseInfo release) async {
    return pickBestApkFor(release, await AndroidSystemService().getSupportedAbis());
  }

  /// 纯逻辑版（abis 由调用方提供），便于单测覆盖匹配与回退。
  static ReleaseAsset? pickBestApkFor(ReleaseInfo release, List<String> abis) {
    final apks = release.assets
        .where((a) => a.name.toLowerCase().endsWith('.apk'))
        .toList();
    if (apks.isEmpty) return null;

    // 从 CI 固定命名 app-{abi}-release.apk 中精确提取 abi 段再比对。
    // 不能用子串 contains：32 位 x86 设备的 "x86" 会命中 x86_64 的资产，
    // 下载到无法安装的 64 位包。
    final abiPattern = RegExp(r'^app-(.+)-release\.apk$', caseSensitive: false);
    for (final abi in abis) {
      for (final apk in apks) {
        final match = abiPattern.firstMatch(apk.name);
        if (match != null && match.group(1)!.toLowerCase() == abi.toLowerCase()) {
          return apk;
        }
      }
    }
    // 回退通用包：精确匹配 app-release.apk，避免误中 xxx-arm64-v8a 之类。
    for (final apk in apks) {
      if (apk.name.toLowerCase() == 'app-release.apk') return apk;
    }
    return null;
  }

  static bool _isNewer(String remote, String current) {
    try {
      List<int> parse(String v) =>
          v.split('.').map((p) => int.tryParse(p) ?? 0).toList();

      final r = parse(remote);
      final c = parse(current);
      final len = r.length > c.length ? r.length : c.length;
      while (r.length < len) {
        r.add(0);
      }
      while (c.length < len) {
        c.add(0);
      }

      for (int i = 0; i < len; i++) {
        if (r[i] > c[i]) return true;
        if (r[i] < c[i]) return false;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static String stripMarkdown(String md) {
    return md
        .replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '')
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`{1,3}(.*?)`{1,3}'), (m) => m.group(1) ?? '')
        .replaceAllMapped(
            RegExp(r'\[([^\]]+)\]\([^)]+\)'), (m) => m.group(1) ?? '')
        .replaceAll(RegExp(r'^---+$', multiLine: true), '─────────────')
        .trim();
  }
}
