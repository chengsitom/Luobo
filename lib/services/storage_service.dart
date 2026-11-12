import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/server_config.dart';

class StorageService {
  static const String _serverConfigKey = 'server_config';
  static const String _serverProfilesKey = 'server_profiles';
  static const String _lastPlayedKey = 'last_played';
  static const String _queueKey = 'queue';
  static const String _queueIndexKey = 'queue_index';
  static const String _shuffleModeKey = 'shuffle_mode';
  static const String _repeatModeKey = 'repeat_mode';
  static const String _gaplessPlaybackKey = 'gapless_playback';
  static const String _lrcLibFallbackKey = 'lrclib_fallback';
  static const String _neteaseFallbackKey = 'netease_fallback';
  static const String _bluetoothLyricsInTitleKey = 'bluetooth_lyrics_in_title';
  static const String _volumeKey = 'volume';
  static const String _lastActiveBaseUrlKey = 'last_active_base_url';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<void> saveServerConfig(ServerConfig config) async {
    final prefs = await _prefs;
    await prefs.setString(_serverConfigKey, json.encode(config.toJson()));
  }

  Future<ServerConfig?> getServerConfig() async {
    final prefs = await _prefs;
    final configJson = prefs.getString(_serverConfigKey);
    if (configJson != null) {
      return ServerConfig.fromJson(json.decode(configJson));
    }
    return null;
  }

  /// The base URL (remote or LAN) last successfully resolved by
  /// `SubsonicService.resolveActiveUrl` — used to skip the LAN probe on cold
  /// start when the previous session already ended on the remote URL.
  Future<String?> getLastActiveBaseUrl() async {
    final prefs = await _prefs;
    return prefs.getString(_lastActiveBaseUrlKey);
  }

  Future<void> saveLastActiveBaseUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(_lastActiveBaseUrlKey, url);
  }

  Future<void> clearServerConfig() async {
    final prefs = await _prefs;
    await prefs.remove(_serverConfigKey);
  }

  Future<List<ServerConfig>> getSavedProfiles() async {
    final prefs = await _prefs;
    final json = prefs.getString(_serverProfilesKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List<dynamic>;
    return list
        .map((e) => ServerConfig.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveProfile(ServerConfig config) async {
    final profiles = await getSavedProfiles();
    final idx = profiles.indexWhere(
      (p) => p.serverUrl == config.serverUrl && p.username == config.username,
    );
    if (idx >= 0) {
      profiles[idx] = config;
    } else {
      profiles.add(config);
    }
    final prefs = await _prefs;
    await prefs.setString(
      _serverProfilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> deleteProfile(ServerConfig config) async {
    final profiles = await getSavedProfiles();
    profiles.removeWhere(
      (p) => p.serverUrl == config.serverUrl && p.username == config.username,
    );
    final prefs = await _prefs;
    await prefs.setString(
      _serverProfilesKey,
      jsonEncode(profiles.map((p) => p.toJson()).toList()),
    );
  }

  Future<void> saveLastPlayed(String songId) async {
    final prefs = await _prefs;
    await prefs.setString(_lastPlayedKey, songId);
  }

  Future<String?> getLastPlayed() async {
    final prefs = await _prefs;
    return prefs.getString(_lastPlayedKey);
  }

  Future<void> saveQueue(List<Map<String, dynamic>> queue) async {
    final prefs = await _prefs;
    await prefs.setString(_queueKey, json.encode(queue));
  }

  Future<List<Map<String, dynamic>>> getQueue() async {
    final prefs = await _prefs;
    final queueJson = prefs.getString(_queueKey);
    if (queueJson != null) {
      final list = json.decode(queueJson) as List;
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  Future<void> saveQueueIndex(int index) async {
    final prefs = await _prefs;
    await prefs.setInt(_queueIndexKey, index);
  }

  Future<int> getQueueIndex() async {
    final prefs = await _prefs;
    return prefs.getInt(_queueIndexKey) ?? 0;
  }

  Future<void> saveShuffleMode(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_shuffleModeKey, enabled);
  }

  Future<bool> getShuffleMode() async {
    final prefs = await _prefs;
    return prefs.getBool(_shuffleModeKey) ?? false;
  }

  Future<void> saveRepeatMode(int mode) async {
    final prefs = await _prefs;
    await prefs.setInt(_repeatModeKey, mode);
  }

  Future<int> getRepeatMode() async {
    final prefs = await _prefs;
    return prefs.getInt(_repeatModeKey) ?? 0;
  }

  Future<void> saveGaplessPlayback(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_gaplessPlaybackKey, enabled);
  }

  Future<bool> getGaplessPlayback() async {
    final prefs = await _prefs;
    return prefs.getBool(_gaplessPlaybackKey) ?? true;
  }

  Future<void> saveLrcLibFallback(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_lrcLibFallbackKey, enabled);
  }

  Future<bool> getLrcLibFallback() async {
    final prefs = await _prefs;
    return prefs.getBool(_lrcLibFallbackKey) ?? false;
  }

  Future<void> saveNeteaseFallback(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_neteaseFallbackKey, enabled);
  }

  Future<bool> getNeteaseFallback() async {
    final prefs = await _prefs;
    return prefs.getBool(_neteaseFallbackKey) ?? true;
  }

  /// 蓝牙/车机歌词：把歌词写进媒体**标题**（默认开，见
  /// `services/car_lyrics_metadata.dart`）。
  ///
  /// 2026-11-12 按需求方决定改为默认开：目标用户就是「蓝牙车机 + 想看歌词」，
  /// 让他们自己去设置里找开关等于功能不存在。代价（手机通知栏标题也变歌词）
  /// 已在设置项副标题里写明，不想要可以关。
  Future<void> saveBluetoothLyricsInTitle(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool(_bluetoothLyricsInTitleKey, enabled);
  }

  Future<bool> getBluetoothLyricsInTitle() async {
    final prefs = await _prefs;
    return prefs.getBool(_bluetoothLyricsInTitleKey) ?? true;
  }

  Future<void> saveVolume(double volume) async {
    final prefs = await _prefs;
    await prefs.setDouble(_volumeKey, volume);
  }

  Future<double> getVolume() async {
    final prefs = await _prefs;
    return prefs.getDouble(_volumeKey) ?? 1.0;
  }

  Future<void> saveDiscordRpcEnabled(bool enabled) async {
    final prefs = await _prefs;
    await prefs.setBool('discord_rpc_enabled', enabled);
  }

  Future<bool> getDiscordRpcEnabled() async {
    final prefs = await _prefs;
    return prefs.getBool('discord_rpc_enabled') ?? true; 
  }

  Future<void> saveDiscordRpcStateStyle(String style) async {
    final prefs = await _prefs;
    await prefs.setString('discord_rpc_state_style', style);
  }

  Future<String> getDiscordRpcStateStyle() async {
    final prefs = await _prefs;
    return prefs.getString('discord_rpc_state_style') ?? 'artist';
  }

  // ── AI Playlist ─────────────────────────────────────────────────────

  Future<void> saveAiBaseUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString('ai_base_url', url);
  }

  Future<String> getAiBaseUrl() async {
    final prefs = await _prefs;
    return prefs.getString('ai_base_url') ?? 'https://api.deepseek.com';
  }

  Future<void> saveDeepSeekApiKey(String key) async {
    final prefs = await _prefs;
    await prefs.setString('deepseek_api_key', key);
  }

  Future<String?> getDeepSeekApiKey() async {
    final prefs = await _prefs;
    return prefs.getString('deepseek_api_key');
  }

  Future<void> saveAiModel(String model) async {
    final prefs = await _prefs;
    await prefs.setString('ai_model', model);
  }

  Future<String> getAiModel() async {
    final prefs = await _prefs;
    return prefs.getString('ai_model') ?? 'deepseek-v4-flash';
  }

  Future<void> clearAll() async {
    final prefs = await _prefs;
    await prefs.clear();
  }
}
