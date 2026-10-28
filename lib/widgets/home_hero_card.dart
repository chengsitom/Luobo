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
  /// - 标题换行走**智能断行**（断在分隔符 / 两行均衡），见 [_HeroTitleText]。
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

/// 卡面标题：默认普通省略；可换行（`titleMaxLines >= 2`）时走**智能断行**。
///
/// 背景：常规贪心换行按宽度切，会把「xxx喜欢的音乐」从中间隔断（前一行满、后一行
/// 只剩两个字），右对齐时右下角还会缺一块。2026-10-27 重写为：
///
/// 1. 一行放得下 → **不拆**（长名字才有资格换两行）；
/// 2. 两行也放不下 → 有间隔号就**只留 `·` 前的主标题**再重排（道理鱼「心动歌单」的
///    「下班后的慢慢走·今日流行、华语、第1815辑」这种 20+ 字名字，卡面永远排不下），
///    实在没有可用的分节符才退回普通两行省略；
/// 3. 否则先用二分求出**可行分界区间**（前缀放得下 + 后缀放得下），再在区间内逐点
///    打分挑最自然的分界：分隔符（空格 / `·` / 中英文标点 / 括号）之后 +10，
///    中英交界 +8（`cheng / 喜欢的音乐`），把英文/数字单词劈开 −5，其余按两行宽度
///    均衡度 `1 - |w1-w2|/maxWidth` 排序，同分取靠后（第一行更长）。
///
/// 结果显式插入 `\n` 交给 Text 渲染 —— 不依赖引擎的换行点，右对齐/左对齐都稳定。
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
    if (maxLines < 2) {
      return _oneLine(text, align);
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
        if (widthOf(text) <= maxWidth) return _oneLine(text, align);

        // 两行能排下 → 智能断行。
        final split = _bestSplit(text, maxWidth, widthOf);
        if (split != null) return _twoLines(text, split, align);

        // 两行都排不下：靠「断行」救不了 —— 道理鱼「心动歌单」形如
        // 「下班后的慢慢走·今日流行、华语、第1815辑」（21 字），151dp 卡两行只装得下
        // 约 12 字，任何断法都会从词中间切断。退一步**只显示 `·` 前的主标题**
        // （「今日流行、华语、第1815辑」是每日轮换的样板尾巴，信息价值低）；
        // 主标题自己也排不下时才走普通两行省略。
        final primary = _primarySegment(text);
        if (primary != null) {
          if (widthOf(primary) <= maxWidth) return _oneLine(primary, align);
          final primarySplit = _bestSplit(primary, maxWidth, widthOf);
          if (primarySplit != null) {
            return _twoLines(primary, primarySplit, align);
          }
        }

        // 都不行 → 普通两行省略。
        return Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: style,
        );
      },
    );
  }

  Widget _oneLine(String s, TextAlign align) => Text(
        s,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      );

  Widget _twoLines(String s, int split, TextAlign align) => Text(
        '${s.substring(0, split).trimRight()}\n'
        '${s.substring(split).trimLeft()}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: align,
        style: style,
      );

  /// 「主标题·今天的分类、期号」→ `主标题`。间隔号太靠前 / 太靠后都不当分节符。
  static String? _primarySegment(String s) {
    for (final sep in const ['·', '｜', '|']) {
      final i = s.indexOf(sep);
      if (i >= 2 && i < s.length - 1) {
        final head = s.substring(0, i).trim();
        if (head.isNotEmpty) return head;
      }
    }
    return null;
  }

  /// 在可行区间里挑「最自然」的分界点，返回分界下标；两行排不下返回 null。
  ///
  /// 打分：断在分隔符（空格 / 中英文标点 / 间隔号）之后 **+10** ＞ 一切；把英文/
  /// 数字单词劈开 **−5**；其余按两行宽度均衡度 `1 - |w1-w2|/maxWidth` 排序，同分取
  /// **靠后**的分界（第一行更长）。
  static int? _bestSplit(
    String s,
    double maxWidth,
    double Function(String) widthOf,
  ) {
    int binarySearch(bool Function(int) ok, int lo, int hi) {
      var result = -1;
      while (lo <= hi) {
        final mid = (lo + hi) ~/ 2;
        if (ok(mid)) {
          result = mid;
          lo = mid + 1;
        } else {
          hi = mid - 1;
        }
      }
      return result;
    }

    // 最大分界点：第一行放得下（长度单调 → 二分）。
    final maxSplit = binarySearch(
      (i) => widthOf(s.substring(0, i)) <= maxWidth,
      1,
      s.length - 1,
    );
    if (maxSplit <= 0) return null;

    // 最小分界点：第二行放得下。
    var minSplit = s.length;
    {
      var lo = 1;
      var hi = s.length - 1;
      while (lo <= hi) {
        final mid = (lo + hi) ~/ 2;
        if (widthOf(s.substring(mid)) <= maxWidth) {
          minSplit = mid;
          hi = mid - 1;
        } else {
          lo = mid + 1;
        }
      }
    }
    if (maxSplit < minSplit) return null;

    const boundaryChars = ' ·/|、，,：:—-」）)>>';
    final asciiWord = RegExp(r'[A-Za-z0-9]');
    // 中日韩文字（含扩展 A）—— 用来识别「中英交界」这个天然断点。
    final cjk = RegExp(r'[\u3400-\u4dbf\u4e00-\u9fff]');

    var bestSplit = minSplit;
    var bestScore = double.negativeInfinity;
    for (var i = minSplit; i <= maxSplit; i++) {
      final prev = s[i - 1];
      final next = s[i];
      final w1 = widthOf(s.substring(0, i));
      final w2 = widthOf(s.substring(i));
      var score = 1 - (w1 - w2).abs() / maxWidth;

      if (boundaryChars.contains(prev)) score += 10;
      final prevAscii = asciiWord.hasMatch(prev);
      final nextAscii = asciiWord.hasMatch(next);
      if (prevAscii && nextAscii) score -= 5; // 词内断开
      // 中英交界是**天然断点**（「cheng / 喜欢的音乐」）：西文与汉字本来就不该连读，
      // 只按宽度均衡会把「cheng喜 / 欢的音乐」切在词中间。
      final prevCjk = cjk.hasMatch(prev);
      final nextCjk = cjk.hasMatch(next);
      if ((prevAscii && nextCjk) || (prevCjk && nextAscii)) score += 8;
      // 同分时取**靠后**的分界（第一行更长）：右对齐卡面右上角更满，
      // 也让「窗边刚/好有阳光」变成「窗边刚好/有阳光」。
      if (score >= bestScore) {
        bestScore = score;
        bestSplit = i;
      }
    }
    return bestSplit;
  }
}
