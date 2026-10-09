import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/theme/roaming_palettes.dart';

void main() {
  group('RoamingPalettes（漫游卡随机配色）', () {
    test('每组都是 4 色，且池子非空', () {
      expect(RoamingPalettes.all, isNotEmpty);
      for (final palette in RoamingPalettes.all) {
        expect(palette.length, 4, reason: '流体着色器恰好吃 4 色');
      }
    });

    test('pick 返回池内的组，索引与配色一致', () {
      final random = Random(1);
      for (var i = 0; i < 50; i++) {
        final (index, colors) = RoamingPalettes.pick(random);
        expect(index, inInclusiveRange(0, RoamingPalettes.all.length - 1));
        expect(colors, same(RoamingPalettes.all[index]));
      }
    });

    test('exclude 能避免连续两次抽到同一组', () {
      final random = Random(7);
      for (var i = 0; i < 50; i++) {
        final (index, _) = RoamingPalettes.pick(random, exclude: 0);
        expect(index, isNot(0));
      }
    });

    test('randomSeed 落在 [0, 2π)', () {
      final random = Random(3);
      for (var i = 0; i < 50; i++) {
        final seed = RoamingPalettes.randomSeed(random);
        expect(seed, greaterThanOrEqualTo(0));
        expect(seed, lessThan(2 * pi));
      }
    });
  });
}
