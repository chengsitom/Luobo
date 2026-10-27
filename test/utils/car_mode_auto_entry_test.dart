import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/utils/car_mode_auto_entry.dart';

/// 播放页 30s 自动进车载的守卫逻辑单测：把"何时允许计时"的判断钉死，
/// 防止后续调整条件回归（见 code review 建议 4）。
void main() {
  group('shouldRunAutoCarModeTimer', () {
    test('普通歌曲播放中且无任何禁止条件时运行', () {
      expect(
        shouldRunAutoCarModeTimer(
          isPlaying: true,
          isPlayingRadio: false,
          isPlayingAudiobook: false,
          appBackgrounded: false,
          carModeOpen: false,
          lyricsShowing: false,
        ),
        true,
      );
    });

    test('设置里关掉自动进入车载 → 计时器不运行', () {
      expect(
        shouldRunAutoCarModeTimer(
          isPlaying: true,
          isPlayingRadio: false,
          isPlayingAudiobook: false,
          appBackgrounded: false,
          carModeOpen: false,
          lyricsShowing: false,
          autoEntryEnabled: false,
        ),
        false,
      );
    });

    test('未播放 / 电台播放 / 有声书播放时不运行', () {
      expect(
        shouldRunAutoCarModeTimer(
          isPlaying: false,
          isPlayingRadio: false,
          isPlayingAudiobook: false,
          appBackgrounded: false,
          carModeOpen: false,
          lyricsShowing: false,
        ),
        false,
      );
      expect(
        shouldRunAutoCarModeTimer(
          isPlaying: true,
          isPlayingRadio: true,
          isPlayingAudiobook: false,
          appBackgrounded: false,
          carModeOpen: false,
          lyricsShowing: false,
        ),
        false,
      );
      // 有声书播放中 → 不自动进车载（无歌词联动需求，§10）。
      expect(
        shouldRunAutoCarModeTimer(
          isPlaying: true,
          isPlayingRadio: false,
          isPlayingAudiobook: true,
          appBackgrounded: false,
          carModeOpen: false,
          lyricsShowing: false,
        ),
        false,
      );
    });

    test('退后台 / 车载页展示 / 歌词页展示任一成立即禁止', () {
      final base = {
        'isPlaying': true,
        'isPlayingRadio': false,
        'isPlayingAudiobook': false,
        'appBackgrounded': false,
        'carModeOpen': false,
        'lyricsShowing': false,
      };
      final cases = <Map<String, Object?>, bool>{
        {...base, 'appBackgrounded': true}: false,
        {...base, 'carModeOpen': true}: false,
        {...base, 'lyricsShowing': true}: false,
        {
          ...base,
          'appBackgrounded': true,
          'carModeOpen': true,
          'lyricsShowing': true,
        }: false,
      };
      cases.forEach((args, expected) {
        expect(
          shouldRunAutoCarModeTimer(
            isPlaying: args['isPlaying']! as bool,
            isPlayingRadio: args['isPlayingRadio']! as bool,
            isPlayingAudiobook: args['isPlayingAudiobook']! as bool,
            appBackgrounded: args['appBackgrounded']! as bool,
            carModeOpen: args['carModeOpen']! as bool,
            lyricsShowing: args['lyricsShowing']! as bool,
          ),
          expected,
        );
      });
    });
  });
}
