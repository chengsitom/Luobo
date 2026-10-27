import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';

import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';
import 'pressable_scale.dart';

/// 首页**流体大卡**（顶部「漫游 / 收藏」与「你的歌单」共用）—— 对标飞牛音乐首页
/// 的大卡与 Apple Music「Made For You」Mix 卡。
///
/// 形态：`FluidBackground` 铺满 + 底部渐变遮罩 + **卡面中上部一个视觉主体** +
/// 左下角文字（大标题 + 可选副标题）。主体二选一：
/// - [icon]：入口卡（漫游 = 罗盘 / 收藏 = 实心心），**图标是卡面主体**；
/// - [monogram]：歌单卡的首字字母牌 —— 歌单**没有可用的封面**（一个歌单里有很多首歌，
///   单张封面代表不了它），用名字首字当「作品」既每张不同、又不依赖封面
///   （Apple Music 的 Mix 卡也是「渐变 + 一个大号半透明图形」，不是单张封面）。
///
/// 尺寸由调用方给（首页两行都是 151×184dp，飞牛首页实测值）。
class HomeHeroCard extends StatelessWidget {
  const HomeHeroCard({
    super.key,
    this.icon,
    this.monogram,
    required this.title,
    this.titleMaxLines = 1,
    this.subtitle,
    this.imageUrl,
    this.colors,
    this.seed = 0,
    this.alignEnd = false,
    this.onTap,
    this.onLongPress,
  });

  /// 卡面主体的**图标**（入口卡用）。与 [monogram] 二选一。
  final IconData? icon;

  /// 卡面主体的**首字字母牌**（歌单卡用）。与 [icon] 二选一，优先。
  final String? monogram;

  /// 底部主标题（默认左下角；[alignEnd] = true 时右下角）。
  final String title;

  /// 标题最多几行（歌单名可能较长，用 2；入口卡 1 行足够）。
  final int titleMaxLines;

  /// 标题下方/上方副标题（白 75%）。为 null 或空白时不占位。
  final String? subtitle;

  /// 取色源（封面 URL）。[colors] 有值时忽略。
  ///
  /// ⚠️ 它**只是取色源，卡面不显示封面图**（卡面显示的是流体场）。
  final String? imageUrl;

  /// 固定 4 色，跳过取色（「漫游」卡用，配色来自 `RoamingPalettes`）。
  final List<Color>? colors;

  /// 流动纹样 seed。
  final double seed;

  /// 文字块靠右（歌单卡，2026-10-24 用户要求）：
  /// - 标题 / 副标题整体移到**右下角**；
  /// - 标题换行时**优先占满第二行**（第一行留短），见 [_HeroTitleText]。
  final bool alignEnd;

  final VoidCallback? onTap;

  /// 长按回调（「漫游」卡长按选续播方式）。
  final VoidCallback? onLongPress;

  /// 圆角 —— 飞牛首页大卡实测 ≈15dp，取最接近的 token 档位（14）。
  static const double radius = LuoboRadius.card;

  /// 图标直径 —— 飞牛实测 ≈52dp。
  static const double iconSize = 52;

  /// 图标不透明度 —— 2026-10-09 用户要求「降低一点」（原 0.92）。
  ///
  /// 图标是**卡面作品**而不是要抢戏的控件，压到 0.65 后与流体底的融合更接近飞牛
  /// （飞牛实测约 0.4，但 Luobo 的流体更亮更饱和，0.4 会太糊，取 0.65）。
  static const double iconOpacity = 0.65;

  /// 首字字母牌字号 —— 比图标大，读作「卡面作品」而非「小图标」。
  static const double monogramSize = 64;

  /// 卡面主体的对齐 —— 略高于正中（飞牛实测图标中心在 ≈36% 高），给底部文字留位。
  static const Alignment artworkAlignment = Alignment(0, -0.25);

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    final hasFixedColors = colors != null;
    final subtitle = this.subtitle;
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
            borderRadius: radius,
            seed: seed,
          ),
          // 底部渐变遮罩：**只压下半部**（配方见 `docs/流沙流体背景技术文档.md` §2，
          // 勿换成包内 `showScrim` —— 那是整幅暗化，会把「看得出在流动」的
          // 空间对比度压掉）。
          const DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(radius)),
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x8C000000)],
              ),
            ),
          ),
          _buildArtwork(),
          Align(
            alignment:
                alignEnd ? Alignment.bottomRight : Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  // 副题在上、主标题在下（2026-10-24 用户拍板：收藏/歌单卡
                  // 「N 首」放名称上面）。⚠️ 用 trim 判空：纯空白串会渲染出
                  // 一行空行 + 间距。
                  if (subtitle != null && subtitle.trim().isNotEmpty) ...[
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
                      // 复用 caption 的 12px，但要覆写行高（caption 默认 1.5 会撑开）。
                      style: LuoboType.caption.copyWith(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 3),
                  ],
                  _HeroTitleText(
                    text: title,
                    maxLines: titleMaxLines,
                    alignEnd: alignEnd,
                    style: LuoboType.heroCardTitle.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 卡面主体：首字字母牌（歌单卡）优先，其次图标（入口卡），都没有就不画。
  Widget _buildArtwork() {
    final monogram = this.monogram;
    if (monogram != null && monogram.trim().isNotEmpty) {
      return Align(
        alignment: artworkAlignment,
        child: Text(
          monogram,
          maxLines: 1,
          style: TextStyle(
            fontSize: monogramSize,
            fontWeight: FontWeight.w700,
            height: 1,
            // 半透明大字 —— 是「卡面作品」而不是要读的文字（Apple Music Mix 卡做法）。
            color: Colors.white.withValues(alpha: 0.22),
          ),
        ),
      );
    }
    final icon = this.icon;
    if (icon == null) return const SizedBox.shrink();
    return Align(
      alignment: artworkAlignment,
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white.withValues(alpha: iconOpacity),
        shadows: [
          Shadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// 卡面标题：默认普通省略；[alignEnd] + 可换行时走**「第二行优先占满」**断行。
///
/// 背景（2026-10-24 用户）：歌单名很长换行时，常规贪心换行是「第一行满、第二行
/// 留短」，右对齐后右下角会缺一块。用户要求反过来 —— **第二行尽量占满、第一行
/// 留短**。做法：`TextPainter` **从末尾往前**二分找「最大的、能放进一行的后缀」
/// 当第二行，余下部分当第一行，显式插入 `\n` 交给右对齐渲染。
///
/// 英文/数字不劈在单词中间：分界点落在词内时向后找最近的空格（第二行会短一点）。
/// 标题超过两行容量时退回普通两行省略。
class _HeroTitleText extends StatelessWidget {
  const _HeroTitleText({
    required this.text,
    required this.style,
    required this.maxLines,
    required this.alignEnd,
  });

  final String text;
  final TextStyle style;
  final int maxLines;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    final align = alignEnd ? TextAlign.right : TextAlign.left;
    if (!alignEnd || maxLines < 2) {
      return Text(
        text,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (maxWidth <= 0 || text.isEmpty) {
          return Text(text, style: style, textAlign: align);
        }

        final direction = Directionality.of(context);
        final scaler = MediaQuery.textScalerOf(context);
        double widthOf(String s) {
          final painter = TextPainter(
            text: TextSpan(text: s, style: style),
            textDirection: direction,
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          return painter.width;
        }

        // 一行放得下 → 不拆。
        if (widthOf(text) <= maxWidth) {
          return Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: style,
          );
        }

        // 找**最小的分界点**（= 最长的第二行），使第二行能放进一行。
        var lo = 1;
        var hi = text.length;
        var split = text.length; // 空后缀也算「放得下」，兜底
        while (lo <= hi) {
          final mid = (lo + hi) ~/ 2;
          if (widthOf(text.substring(mid)) <= maxWidth) {
            split = mid;
            hi = mid - 1;
          } else {
            lo = mid + 1;
          }
        }

        var head = split > 0 ? text.substring(0, split).trimRight() : '';
        var tail =
            split < text.length ? text.substring(split).trimLeft() : '';

        // 英文/数字别劈在单词中间：分界点在词内时向后找最近的空格
        // （第二行会短一点，但可读性优先）；前提是第一行仍放得下。
        if (split > 0 && split < text.length) {
          final wordChar = RegExp(r'[A-Za-z0-9]');
          final touchesWord = wordChar.hasMatch(text[split - 1]) &&
              wordChar.hasMatch(text[split]);
          if (touchesWord) {
            final space = text.indexOf(' ', split);
            if (space != -1) {
              final newHead = text.substring(0, space).trimRight();
              if (widthOf(newHead) <= maxWidth) {
                head = newHead;
                tail = text.substring(space).trimLeft();
              }
            }
          }
        }

        // 第一行还放不下（标题超过两行的容量）→ 退回普通两行省略。
        if (head.isEmpty || widthOf(head) > maxWidth) {
          return Text(
            text,
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
            textAlign: align,
            style: style,
          );
        }

        return Text(
          '$head\n$tail',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: style,
        );
      },
    );
  }
}
