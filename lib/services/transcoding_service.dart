import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'diagnostics/diagnostics.dart';

class TranscodeBitrate {
  static const int original = 0;
  static const int kbps64 = 64;
  static const int kbps128 = 128;
  static const int kbps192 = 192;
  static const int kbps256 = 256;
  static const int kbps320 = 320;

  static const List<int> options = [
    original,
    kbps64,
    kbps128,
    kbps192,
    kbps256,
    kbps320,
  ];

  static String getLabel(int bitrate) {
    if (bitrate == original) return 'Original (No Transcoding)';
    return '$bitrate kbps';
  }
}

class TranscodeFormat {
  static const String original = 'raw';
  static const String mp3 = 'mp3';
  static const String opus = 'opus';
  static const String aac = 'aac';

  static const List<String> options = [original, mp3, opus, aac];

  static String getLabel(String format) {
    switch (format) {
      case original:
        return 'Original';
      case mp3:
        return 'MP3';
      case opus:
        return 'Opus';
      case aac:
        return 'AAC';
      default:
        return format.toUpperCase();
    }
  }
}

enum ConnectionType { wifi, mobile }

class TranscodingService extends ChangeNotifier {
  static const String _wifiBitrateKey = 'transcoding_wifi_bitrate';
  static const String _mobileBitrateKey = 'transcoding_mobile_bitrate';
  static const String _formatKey = 'transcoding_format';
  static const String _enabledKey = 'transcoding_enabled';
  static const String _connectionTypeKey = 'transcoding_connection_type';
  static const String _smartEnabledKey = 'transcoding_smart_enabled';
  static const String _manualBitrateKey = 'transcoding_manual_bitrate';

  int _wifiBitrate = TranscodeBitrate.original;
  int _mobileBitrate = TranscodeBitrate.kbps192;
  int _manualBitrate = TranscodeBitrate.kbps192;
  String _format = TranscodeFormat.mp3;
  bool _enabled = false;
  bool _smartEnabled = false;
  ConnectionType _currentConnectionType = ConnectionType.wifi;

  /// LAN override: when the active server connection is a LAN (local) URL,
  /// transcoding is forced off regardless of the WiFi/mobile settings (rule 1:
  /// 局域网链接 → 一定不转码). The source callback is wired to
  /// SubsonicService.isUsingLocalUrl in main.dart and read lazily on every
  /// bitrate/format decision, so a LAN↔remote switch takes effect without an
  /// explicit refresh.
  bool Function()? _isLanOverride;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  int get wifiBitrate => _wifiBitrate;
  int get mobileBitrate => _mobileBitrate;
  int get manualBitrate => _manualBitrate;
  // Smart mode: bitrate follows the current connection type (WiFi quality on
  // WiFi, mobile quality on cellular). Manual mode: a single fixed bitrate is
  // always used, regardless of the network.
  int get currentBitRate {
    // LAN connection: always original, regardless of the settings (rule 1).
    if (_isLanOverride?.call() ?? false) return TranscodeBitrate.original;
    return _smartEnabled
        ? (_currentConnectionType == ConnectionType.wifi
            ? _wifiBitrate
            : _mobileBitrate)
        : _manualBitrate;
  }

  String get format => _format;
  bool get enabled => _enabled;
  bool get smartEnabled => _smartEnabled;
  ConnectionType get currentConnectionType => _currentConnectionType;

  TranscodingService() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _wifiBitrate = prefs.getInt(_wifiBitrateKey) ?? TranscodeBitrate.original;
    _mobileBitrate =
        prefs.getInt(_mobileBitrateKey) ?? TranscodeBitrate.kbps192;
    _format = prefs.getString(_formatKey) ?? TranscodeFormat.mp3;
    _enabled = prefs.getBool(_enabledKey) ?? false;
    _smartEnabled = prefs.getBool(_smartEnabledKey) ?? false;
    _manualBitrate =
        prefs.getInt(_manualBitrateKey) ?? TranscodeBitrate.kbps192;
    final connectionIndex = prefs.getInt(_connectionTypeKey) ?? 0;
    _currentConnectionType = ConnectionType.values[connectionIndex];

    if (_smartEnabled) {
      await _initConnectivityWatcher();
    }

    notifyListeners();
  }

  Future<void> _initConnectivityWatcher() async {
    final result = await Connectivity().checkConnectivity();
    _updateConnectionType(result);

    _connectivitySub?.cancel();
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen(_updateConnectionType);
  }

  void _updateConnectionType(List<ConnectivityResult> results) {
    final newType = results.contains(ConnectivityResult.wifi)
        ? ConnectionType.wifi
        : ConnectionType.mobile;

    if (newType != _currentConnectionType) {
      final from = _currentConnectionType.name;
      final bitrateBefore = getCurrentBitrate();
      _currentConnectionType = newType;
      DiagnosticsService.instance.rotateNetSession(newType.name);
      DiagnosticsService.instance.record(
        EventType.netSwitch,
        LogLevel.info,
        {
          'from': from,
          'to': newType.name,
          'smartEnabled': _smartEnabled,
          'bitrateBefore': bitrateBefore,
          'bitrateAfter': getCurrentBitrate(),
        },
      );
      debugPrint(
        '[Transcoding] Network changed → ${newType.name} '
        '(bitrate: ${getCurrentBitrate() ?? "original"})',
      );
      notifyListeners();
    }
  }

  void _stopConnectivityWatcher() {
    _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
    notifyListeners();
  }

  Future<void> setSmartEnabled(bool value) async {
    if (!value) {
      // Leaving smart mode: pin the fixed bitrate to the one currently in
      // effect so playback behavior stays continuous.
      _manualBitrate = _currentConnectionType == ConnectionType.wifi
          ? _wifiBitrate
          : _mobileBitrate;
    }
    _smartEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_smartEnabledKey, value);
    if (value) {
      await _initConnectivityWatcher();
    } else {
      _stopConnectivityWatcher();
      await prefs.setInt(_manualBitrateKey, _manualBitrate);
    }
    notifyListeners();
  }

  Future<void> setWifiBitrate(int bitrate) async {
    _wifiBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_wifiBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setMobileBitrate(int bitrate) async {
    _mobileBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_mobileBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setFormat(String format) async {
    _format = format;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_formatKey, format);
    notifyListeners();
  }

  Future<void> setManualBitrate(int bitrate) async {
    _manualBitrate = bitrate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_manualBitrateKey, bitrate);
    notifyListeners();
  }

  Future<void> setConnectionType(ConnectionType type) async {
    _currentConnectionType = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_connectionTypeKey, type.index);
    notifyListeners();
  }

  /// Wires the LAN-state source (SubsonicService.isUsingLocalUrl). The value
  /// is read lazily on every bitrate/format decision, so a LAN↔remote switch
  /// takes effect as soon as SubsonicService notifies the change.
  void setLanStateSource(bool Function() isLan) {
    _isLanOverride = isLan;
  }

  /// Refresh hook called by SubsonicService whenever the active URL changes
  /// (LAN↔remote). Re-reads the LAN source lazily and re-broadcasts so the
  /// settings page / song tiles / toasts pick up the new effective bitrate.
  void onNetworkPathChanged() {
    notifyListeners();
  }

  /// Whether the active server connection is a LAN (local URL). When true,
  /// transcoding is forced off (rule 1) — surfaced in the streaming settings
  /// so the "Original despite a set bitrate" state isn't confusing.
  bool get isLanOverrideActive => _isLanOverride?.call() ?? false;

  int? getCurrentBitrate() {
    if (!_enabled) return null;
    final bitrate = currentBitRate;
    return bitrate == TranscodeBitrate.original ? null : bitrate;
  }

  String? getCurrentFormat() {
    // LAN connection: no transcoding format is requested (rule 1).
    if (_isLanOverride?.call() ?? false) return null;
    if (!_enabled) return null;
    return _format == TranscodeFormat.original ? null : _format;
  }

  @override
  void dispose() {
    _stopConnectivityWatcher();
    super.dispose();
  }
}
