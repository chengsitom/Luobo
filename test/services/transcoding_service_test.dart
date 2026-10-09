import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/transcoding_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TranscodingService LAN override (rule 1: 局域网链接 → 一定不转码)', () {
    late TranscodingService ts;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      ts = TranscodingService();
      // 让构造器里的 _loadSettings()（异步读 prefs）先落定，避免与后续
      // setter 写入交错。
      await Future<void>.delayed(Duration.zero);
    });

    test('LAN: forced original even when transcoding is enabled with a bitrate',
        () async {
      ts.setLanStateSource(() => true);
      await ts.setEnabled(true);
      await ts.setManualBitrate(TranscodeBitrate.kbps192);
      await ts.setFormat(TranscodeFormat.mp3);

      expect(ts.isLanOverrideActive, isTrue);
      expect(ts.currentBitRate, TranscodeBitrate.original);
      expect(ts.getCurrentBitrate(), isNull);
      expect(ts.getCurrentFormat(), isNull);
    });

    test('LAN: original even when transcoding is disabled', () async {
      ts.setLanStateSource(() => true);

      expect(ts.currentBitRate, TranscodeBitrate.original);
      expect(ts.getCurrentBitrate(), isNull);
      expect(ts.getCurrentFormat(), isNull);
    });

    test('non-LAN: settings apply (manual bitrate)', () async {
      ts.setLanStateSource(() => false);
      await ts.setEnabled(true);
      await ts.setManualBitrate(TranscodeBitrate.kbps192);
      await ts.setFormat(TranscodeFormat.mp3);

      expect(ts.isLanOverrideActive, isFalse);
      expect(ts.currentBitRate, TranscodeBitrate.kbps192);
      expect(ts.getCurrentBitrate(), TranscodeBitrate.kbps192);
      expect(ts.getCurrentFormat(), TranscodeFormat.mp3);
    });

    test('non-LAN disabled: no transcoding regardless of manual bitrate',
        () async {
      ts.setLanStateSource(() => false);
      await ts.setManualBitrate(TranscodeBitrate.kbps192);

      expect(ts.getCurrentBitrate(), isNull);
      expect(ts.getCurrentFormat(), isNull);
    });

    test(
        'non-LAN enabled with Original bitrate but a format: format-only '
        'transcode signal (drives _willTranscode routing)', () async {
      ts.setLanStateSource(() => false);
      await ts.setEnabled(true);
      // Manual 模式下的等价构造（smart 模式的 WiFi=Original 需 connectivity
      // 插件，单测不可用；getter 逻辑两者相同）。
      await ts.setManualBitrate(TranscodeBitrate.original);
      await ts.setFormat(TranscodeFormat.mp3);

      expect(ts.getCurrentBitrate(), isNull);
      expect(ts.getCurrentFormat(), TranscodeFormat.mp3);
    });

    test('LAN override flips live with the source callback', () async {
      var lan = false;
      ts.setLanStateSource(() => lan);
      await ts.setEnabled(true);
      await ts.setManualBitrate(TranscodeBitrate.kbps192);

      expect(ts.getCurrentBitrate(), TranscodeBitrate.kbps192);
      lan = true;
      expect(ts.getCurrentBitrate(), isNull);
      expect(ts.currentBitRate, TranscodeBitrate.original);
      lan = false;
      expect(ts.getCurrentBitrate(), TranscodeBitrate.kbps192);
    });
  });
}
