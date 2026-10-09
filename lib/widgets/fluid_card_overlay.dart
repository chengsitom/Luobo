import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';

import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';
import 'pressable_scale.dart';

/// 流体卡上的**「文字叠在流体内」层**（Apple Music 形态）——
/// 底部渐变遮罩 + 左下角白字，供「快速开始」三张卡与「你的歌单」卡共用。
///
/// 用法：`Stack(fit: StackFit.expand, children: [FluidBackground(...), FluidCardOverlay(...)])`
/// —— `FluidBackground` **没有 `child` 槽位**，所以叠字只能由宿主侧 `Stack` 完成。
///
/// ⚠️ **遮罩只压下半部，不要换成包内的 `showScrim`**：`showScrim` 是整幅暗化
/// （`_ScrimOverlay`，黑 0.42→0.70），会把不压字的上半部一起压暗，而空间对比度
/// 正是「看得出在流动」的来源。二级页 hero 已踩过同一个坑（实测中段空间对比度
/// 整幅 0.023 → 分区 0.068）。
/// 配方见 `docs/流沙流体背景技术文档.md` §2。
///
/// **排版规则（2026-10-08 用户要求「歌单里的数字和下面一行的字体和漫游的 2 行对齐」）**：
/// 三个参数按 `count → title → subtitle` 的顺序排成若干行，**第一行用主字阶
/// （15px / w600 / 纯白）、其余行用次字阶（12px / 白 75%）**。于是：
/// - 「漫游」卡（无 count）→ 主行 = 标题、次行 = 副标题，与改动前**完全一致**；
/// - 「歌单 / 收藏 / 你的歌单」卡（有 count）→ 主行 = 数字、次行 = 名称，
///   与「漫游」的两行逐行对齐。
class FluidCardOverlay extends StatelessWidget {
  const FluidCardOverlay({
    super.key,
    required this.title,
    this.count,
    this.subtitle,
    this.radius = _radius,
  });

  final String title;

  /// 数字/短状态值：排在**标题上一行**。有它时它就是主行（数字在上、名称在下）。
  final String? count;

  /// 标题下方副标题。为 null 或空串时不占位。
  final String? subtitle;

  /// 必须与底下的 `FluidBackground.borderRadius` 一致，否则遮罩圆角会露出直角。
  final double radius;

  /// 主行字阶 —— 与「漫游」卡标题同款（走 token，见 `LuoboType.cardOverlayTitle`）。
  static final TextStyle _primary =
      LuoboType.cardOverlayTitle.copyWith(color: Colors.white);

  @override
  Widget build(BuildContext context) {
    final secondary = Colors.white.withValues(alpha: 0.75);
    // ⚠️ 用 trim 判空：纯空白串（如 " "）过 isNotEmpty 会渲染出一行空行 + 2px 间距。
    final lines = <String>[
      if (count != null && count!.trim().isNotEmpty) count!,
      title,
      if (subtitle != null && subtitle!.trim().isNotEmpty) subtitle!,
    ];

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            gradient: const LinearGradient(
              begin: Alignment.center,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x8C000000)],
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < lines.length; i++) ...[
                  if (i > 0) const SizedBox(height: 2),
                  Text(
                    lines[i],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: i == 0
                        ? _primary
                        // 次行复用 caption 的 12px，但要覆写行高（caption 默认 1.5
                        // 会把两行间距撑开）与颜色。
                        : LuoboType.caption.copyWith(
                            height: 1,
                            color: secondary,
                          ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// **方形流体卡** —— `FluidBackground` 铺满 + [FluidCardOverlay] 叠字，供
/// 「快速开始」的横滑卡与「你的歌单」的横滑卡**共用同一份实现**。
///
/// ⚠️ 抽出来的理由：这两处早先是两份逐行相同的 `Stack[FluidBackground(...)
/// + FluidCardOverlay(...)]`（含 `CachedNetworkImageProvider` 的缓存参数），
/// 已经出现过「一边圆角 8、一边 12」的漂移。流体卡的圆角/遮罩/取色源只有这一份。
///
/// 尺寸由调用方给（两处都是 150dp 正方形）。
class FluidCard extends StatelessWidget {
  const FluidCard({
    super.key,
    required this.title,
    this.count,
    this.subtitle,
    this.imageUrl,
    this.colors,
    this.seed = 0,
    this.onTap,
    this.onLongPress,
  });

  final String title;

  /// 见 [FluidCardOverlay.count]。
  final String? count;

  /// 见 [FluidCardOverlay.subtitle]。
  final String? subtitle;

  /// 取色源（封面 URL）。[colors] 有值时忽略。
  final String? imageUrl;

  /// 固定 4 色，跳过取色（「漫游」卡用）。
  final List<Color>? colors;

  final double seed;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasFixedColors = colors != null;
    return PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FluidBackground(
            // 复用 App 的封面缓存，避免为背景再下载一次同一张封面。
            imageProvider: hasFixedColors || url == null || url.isEmpty
                ? null
                : CachedNetworkImageProvider(
                    url,
                    cacheManager: coverCacheManager,
                    cacheKey: coverArtCacheKeyFromUrl(url),
                  ),
            colors: colors,
            borderRadius: _radius,
            seed: seed,
          ),
          FluidCardOverlay(title: title, count: count, subtitle: subtitle),
        ],
      ),
    );
  }
}

/// 流体卡圆角 —— 与 [FluidCardOverlay.radius] 必须同值。
const double _radius = 12;
