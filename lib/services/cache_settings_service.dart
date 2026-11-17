import 'package:shared_preferences/shared_preferences.dart';

/// Toggle for cover-image caching. BPM caching is intentionally always
/// enabled (negligible space). The old "music cache" toggle was removed:
/// online streams are never written to disk (LockCachingAudioSource was
/// retired to fix seek), so that switch had no effect.
class CacheSettingsService {
  static const String _keyImageCacheEnabled = 'cache_images_enabled';

  static final CacheSettingsService _instance =
      CacheSettingsService._internal();
  factory CacheSettingsService() => _instance;
  CacheSettingsService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setImageCacheEnabled(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyImageCacheEnabled, enabled);
  }

  bool getImageCacheEnabled() {
    return _prefs?.getBool(_keyImageCacheEnabled) ?? true;
  }
}
