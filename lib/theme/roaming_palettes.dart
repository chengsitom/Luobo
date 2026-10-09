import 'dart:math';

import 'package:flutter/material.dart';

/// 首页「漫游」卡的随机配色池。
///
/// 漫游卡**没有天然封面**（它代表"整个曲库"，不是某张专辑），所以配色不能像其他
/// 流体卡那样从封面取色，而是从这份**手工挑选**的调色板里随机抽——目的是保证
/// 「每次换都好看」，而不是靠算法从图里碰运气。
///
/// 每组 4 色，配比照包内 `FluidPalette._select` 的思路：**2 个高饱和 + 2 个深色**。
/// 高饱和负责色彩识别度，深色负责让流体场有纵深——全亮会糊成一片，全暗会看不出
/// 在流动。`FluidBackground` 的着色器恰好吃 4 色（见包内 `applyUniforms` 的
/// uniform 索引 6..17）。
///
/// ⚠️ 不要改用 `FluidPalette.defaultColors`（那是一组深蓝紫）——与相邻两张彩色
/// 流体卡并排会显得「就它是灰的」。
class RoamingPalettes {
  RoamingPalettes._();

  /// 全部候选配色。新增时请保持「2 高饱和 + 2 深色」的配比。
  static const List<List<Color>> all = [
    // 1 玫红夜（品牌色系）
    [
      Color(0xFFFF2D55),
      Color(0xFFFF7AA2),
      Color(0xFF2B0A1A),
      Color(0xFF4A0F2C)
    ],
    // 2 极光青
    [
      Color(0xFF00E5C0),
      Color(0xFF5BD6E8),
      Color(0xFF062B2E),
      Color(0xFF0B3B4A)
    ],
    // 3 落日橙
    [
      Color(0xFFFF8A3D),
      Color(0xFFFFC46B),
      Color(0xFF3A1405),
      Color(0xFF5A2410)
    ],
    // 4 紫罗兰
    [
      Color(0xFF9B6BFF),
      Color(0xFFC9A7FF),
      Color(0xFF1A0B33),
      Color(0xFF2C1450)
    ],
    // 5 深海蓝
    [
      Color(0xFF2E7DFF),
      Color(0xFF6BB6FF),
      Color(0xFF061428),
      Color(0xFF0B2440)
    ],
    // 6 抹茶绿
    [
      Color(0xFF3DDC84),
      Color(0xFFA8E6A1),
      Color(0xFF0A2415),
      Color(0xFF123A22)
    ],
    // 7 樱桃红
    [
      Color(0xFFFF4D4D),
      Color(0xFFFF9A8B),
      Color(0xFF2A0808),
      Color(0xFF431010)
    ],
    // 8 薰衣草粉
    [
      Color(0xFFFF6EC7),
      Color(0xFFFFA8E0),
      Color(0xFF2A0A22),
      Color(0xFF43123A)
    ],
  ];

  /// 随机抽一组配色，返回 `(索引, 4 色)`。
  ///
  /// 传 [exclude]（上一次的索引）可避免连续两次抽到同一组——否则「回到首页换色」
  /// 有 1/8 的概率看起来没换。只有一组时直接返回它。
  static (int, List<Color>) pick(Random random, {int? exclude}) {
    if (all.length == 1) return (0, all.first);
    var index = random.nextInt(all.length);
    if (exclude != null && index == exclude) {
      index = (index + 1) % all.length;
    }
    return (index, all[index]);
  }

  /// 随机流动纹样 seed。
  ///
  /// seed 决定流动的**方向 / 噪声区域 / 扭曲相位**（见 `FluidBackground.seedForIndex`
  /// 的说明）。只换色不换 seed 的话，纹样会一直一模一样，看起来像"只是调了个色"。
  static double randomSeed(Random random) => random.nextDouble() * 2 * pi;
}
