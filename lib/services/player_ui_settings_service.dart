import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class PlayerUiSettingsService {
  static const String _keyShowMiniPlayerHeart = 'mini_player_show_heart';
  static const String _keyAlbumArtCornerRadius = 'artwork_corner_radius';
  static const String _keyArtworkShape = 'artwork_shape';
  static const String _keyArtworkShadow = 'artwork_shadow';
  static const String _keyArtworkShadowColor = 'artwork_shadow_color';
  static const String _keyLiveSearch = 'search_live_search';
  static const String _keyAutoCarModeEntry = 'player_auto_car_mode_entry';

  static final PlayerUiSettingsService _instance =
      PlayerUiSettingsService._internal();
  factory PlayerUiSettingsService() => _instance;
  PlayerUiSettingsService._internal();

  SharedPreferences? _prefs;

  final ValueNotifier<bool> showMiniPlayerHeartNotifier = ValueNotifier(false);
  final ValueNotifier<bool> liveSearchNotifier = ValueNotifier(true);

  /// 播放页停留 30s 自动进入车载模式（默认开）。
  final ValueNotifier<bool> autoCarModeEntryNotifier = ValueNotifier(true);
  final ValueNotifier<double> albumArtCornerRadiusNotifier = ValueNotifier(8.0);

  final ValueNotifier<String> artworkShapeNotifier = ValueNotifier('rounded');

  final ValueNotifier<String> artworkShadowNotifier = ValueNotifier('soft');

  final ValueNotifier<String> artworkShadowColorNotifier = ValueNotifier(
    'black',
  );

  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    showMiniPlayerHeartNotifier.value = getShowMiniPlayerHeart();
    albumArtCornerRadiusNotifier.value = getAlbumArtCornerRadius();
    artworkShapeNotifier.value = getArtworkShape();
    artworkShadowNotifier.value = getArtworkShadow();
    artworkShadowColorNotifier.value = getArtworkShadowColor();
    liveSearchNotifier.value = getLiveSearch();
    autoCarModeEntryNotifier.value = getAutoCarModeEntry();
  }

  Future<void> setShowMiniPlayerHeart(bool show) async {
    await initialize();
    await _prefs!.setBool(_keyShowMiniPlayerHeart, show);
    showMiniPlayerHeartNotifier.value = show;
  }

  bool getShowMiniPlayerHeart() {
    return _prefs?.getBool(_keyShowMiniPlayerHeart) ?? false;
  }

  Future<void> setAlbumArtCornerRadius(double radius) async {
    await initialize();
    await _prefs!.setDouble(_keyAlbumArtCornerRadius, radius);
    albumArtCornerRadiusNotifier.value = radius;
  }

  double getAlbumArtCornerRadius() {
    return _prefs?.getDouble(_keyAlbumArtCornerRadius) ?? 8.0;
  }

  Future<void> setArtworkShape(String shape) async {
    await initialize();
    await _prefs!.setString(_keyArtworkShape, shape);
    artworkShapeNotifier.value = shape;
  }

  String getArtworkShape() {
    return _prefs?.getString(_keyArtworkShape) ?? 'rounded';
  }

  Future<void> setArtworkShadow(String shadow) async {
    await initialize();
    await _prefs!.setString(_keyArtworkShadow, shadow);
    artworkShadowNotifier.value = shadow;
  }

  String getArtworkShadow() {
    return _prefs?.getString(_keyArtworkShadow) ?? 'soft';
  }

  Future<void> setArtworkShadowColor(String color) async {
    await initialize();
    await _prefs!.setString(_keyArtworkShadowColor, color);
    artworkShadowColorNotifier.value = color;
  }

  String getArtworkShadowColor() {
    return _prefs?.getString(_keyArtworkShadowColor) ?? 'black';
  }

  Future<void> setLiveSearch(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyLiveSearch, enabled);
    liveSearchNotifier.value = enabled;
  }

  Future<void> setAutoCarModeEntry(bool enabled) async {
    await initialize();
    await _prefs!.setBool(_keyAutoCarModeEntry, enabled);
    autoCarModeEntryNotifier.value = enabled;
  }

  bool getAutoCarModeEntry() {
    return _prefs?.getBool(_keyAutoCarModeEntry) ?? true;
  }

  bool getLiveSearch() {
    return _prefs?.getBool(_keyLiveSearch) ?? true;
  }

  void dispose() {
    showMiniPlayerHeartNotifier.dispose();
    liveSearchNotifier.dispose();
    autoCarModeEntryNotifier.dispose();
    albumArtCornerRadiusNotifier.dispose();
    artworkShapeNotifier.dispose();
    artworkShadowNotifier.dispose();
    artworkShadowColorNotifier.dispose();
  }
}
