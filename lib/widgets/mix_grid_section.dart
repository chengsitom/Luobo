import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';

import '../l10n/app_localizations.dart';
import '../services/diagnostics/diagnostics.dart';
import '../theme/app_theme.dart';
import '../utils/image_cache.dart';
import '../widgets/album_artwork.dart';
import '../widgets/fluid_card_overlay.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/section_header.dart';
import 'home_v2_tokens.dart';

/// 网格卡数据（§5.1 模块 3/6：为你制作 / 探索发现）。
class MixCardData {
  final String title;
  final String? subtitle;

  /// 数字/短状态值 —— 渲染在**标题上一行**（2026-10-08 用户要求：
  /// 「歌单和收藏的数字放到 xx喜欢的音乐 上面一行」）。为 null 时该行不占位。
  final String? count;

  final String? coverArt;

  /// 流体渐变背景的取色源（封面 URL）。[useFluidGradient] 为 true 时生效。
  final String? imageUrl;

  /// 是否圆形封面。仅在不使用流体渐变时生效（流体恒为方形圆角）。
  final bool round;

  /// 用「封面取色流体渐变」替代封面图（2026-09-23：为你制作 4 卡由 2×2
  /// 拼贴改为流体）。无 [imageUrl] 时回落到默认深色 mesh。
  final bool useFluidGradient;

  /// 直接用固定 4 色，**跳过从封面取色**。用于没有封面的卡——例如「漫游」卡
  /// （它代表整个曲库，配色从 `RoamingPalettes` 随机抽）。优先级高于 [imageUrl]。
  final List<Color>? fluidColors;

  /// 覆盖流动纹样 seed。为 null 时用 `FluidBackground.seedForIndex(index)`。
  final double? seed;

  final VoidCallback? onTap;

  /// 长按回调（如「漫游」卡长按选续播方式）。
  final VoidCallback? onLongPress;

  /// 占位态（如 Mix 暂无内容）：灰态封面 + 「生成中」，不可点击。
  final bool disabled;

  const MixCardData({
    required this.title,
    this.subtitle,
    this.count,
    this.coverArt,
    this.imageUrl,
    this.round = true,
    this.useFluidGradient = false,
    this.fluidColors,
    this.seed,
    this.onTap,
    this.onLongPress,
    this.disabled = false,
  });
}

/// 段落（可选标题 + 查看全部 + 卡片），替代旧首页的纵向文字行列表。
///
/// 两种排布，由 [cardWidth] 切换：
/// - **网格**（`cardWidth == null`）：`GridView` 固定列数，文字在卡**下方**。
/// - **横滑**（`cardWidth != null`）：一行固定宽度的**正方形**卡，文字**叠在流体内**
///   （Apple Music 那种）。首页「快速开始」小节用这个形态。
///
/// 内部用 [FluidBackgroundScope] 包住整段，让本段所有卡的流体背景**共用一个
/// 时钟**（一个 Ticker 而非每卡一个）。
class MixGridSection extends StatefulWidget {
  /// 段落标题。为 null 时不画 `SectionHeader`。
  final String? title;
  final List<MixCardData> cards;
  final VoidCallback? onSeeAllTap;
  final double hPad;
  final int columns;

  /// 网格卡宽高比。为 null 时沿用旧规则（2 列 0.74、其余 0.9）。**仅网格模式生效**。
  ///
  /// 3 列必须显式传 ≈0.70：单卡变窄后封面仍是 1:1，卡内「封面 + 标题 + 副标题」
  /// 的总高超过 `宽 / 0.9`，会 RenderFlex overflow。
  final double? childAspectRatio;

  /// 传了就切成**横滑模式**：一行固定 [cardWidth] 宽的**正方形**卡，文字叠在流体内。
  ///
  /// ⚠️ 横滑模式下 [columns] / [childAspectRatio] 都不生效；卡内文字形态也由本参数
  /// 隐含决定（不额外开一个「文字是否在流体内」的开关 —— 只服务一个调用方时，多一个
  /// 开关就多一种非法组合）。
  final double? cardWidth;

  const MixGridSection({
    super.key,
    this.title,
    required this.cards,
    this.onSeeAllTap,
    this.hPad = 16,
    this.columns = 2,
    this.childAspectRatio,
    this.cardWidth,
  });

  @override
  State<MixGridSection> createState() => _MixGridSectionState();
}

class _MixGridSectionState extends State<MixGridSection> {
  bool _modeRecorded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recordModeOnce();
  }

  /// 记录本段用了哪种流体背景。
  ///
  /// 用途：`frame.jank` / `frame.slow` 事件只带 `route`，而首页有多种背景模式，
  /// 无法归属。着色器**是否可用**另有一条 `fluidMeshShader` 事件（来自
  /// `fluid_mesh_background` 包的 `FluidBackgroundEvents`），两条合起来即可判断
  /// 本次运行的实际渲染路径。
  void _recordModeOnce() {
    if (_modeRecorded || widget.cards.isEmpty) return;
    _modeRecorded = true;
    final cards = widget.cards.length;
    // 放到帧后，确保 route observer 已写入当前路由。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DiagnosticsService.instance.record(
        EventType.animActive,
        LogLevel.info,
        {
          'anim': 'mixCardFluidBackground',
          'cards': cards,
          'clock': 'monotonic',
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = HomeV2Tokens.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (widget.cards.isEmpty) return const SizedBox.shrink();
    final title = widget.title;
    final cardWidth = widget.cardWidth;

    Widget cardAt(int index, {required bool overlayText}) {
      final data = widget.cards[index];
      return _MixCard(
        data: data,
        tokens: tokens,
        overlayText: overlayText,
        // 每张卡一套不同的流动图案（45° 方向步进 + 不同噪声区域）
        seed: data.seed ?? FluidBackground.seedForIndex(index),
      );
    }

    // 横滑：正方形卡 + 文字在流体内。`hPad` 交给 ListView 自己当 padding，
    // 这样卡片能滚到屏幕边缘（首张仍与标题左对齐）。
    final Widget body;
    if (cardWidth != null) {
      body = SizedBox(
        height: cardWidth,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: widget.hPad),
          itemCount: widget.cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) => SizedBox(
            width: cardWidth,
            height: cardWidth,
            child: cardAt(index, overlayText: true),
          ),
        ),
      );
    } else {
      final aspectRatio =
          widget.childAspectRatio ?? (widget.columns == 2 ? 0.74 : 0.9);
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.hPad),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: widget.columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: aspectRatio,
          ),
          itemCount: widget.cards.length,
          itemBuilder: (context, index) => cardAt(index, overlayText: false),
        ),
      );
    }

    return FluidBackgroundScope(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.hPad),
              child: SectionHeader(
                title: title,
                actionText: widget.onSeeAllTap != null ? l10n.seeAll : null,
                onActionTap: widget.onSeeAllTap,
              ),
            ),
            const SizedBox(height: 4),
          ],
          body,
        ],
      ),
    );
  }
}

class _MixCard extends StatelessWidget {
  final MixCardData data;
  final HomeV2Tokens tokens;

  /// 本卡的流体 seed（见 `FluidBackground.seedForIndex`）：决定流动图案。
  final double seed;

  /// 文字是否叠在流体内（Apple Music 形态）。由 [MixGridSection.cardWidth] 隐含决定。
  final bool overlayText;

  const _MixCard({
    required this.data,
    required this.tokens,
    required this.seed,
    this.overlayText = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    final subtitle = data.disabled ? l10n.generating : (data.subtitle ?? '');

    final Widget child;
    if (overlayText) {
      // 文字叠在流体内 —— 整卡（流体 + 遮罩 + 文字 + 按压）交给公共 `FluidCard`，
      // 「你的歌单」的横滑卡用的是同一个，避免两份各写一遍。
      return FluidCard(
        title: data.title,
        count: data.count,
        subtitle: subtitle,
        imageUrl: data.imageUrl,
        colors: data.fluidColors,
        seed: seed,
        onTap: data.disabled ? null : data.onTap,
        onLongPress: data.disabled ? null : data.onLongPress,
      );
    } else {
      Widget cover;
      if (data.disabled) {
        cover = Container(
          decoration: BoxDecoration(
            color: tokens.cardBorder.withValues(alpha: 0.4),
            shape: data.round ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: data.round ? null : BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.hourglass_top_rounded,
            color: tokens.secondaryText,
          ),
        );
      } else if (data.useFluidGradient) {
        // 封面取色的「流沙」流体场（`fluid_mesh_background` 包），替代 2×2 拼贴封面。
        // 时钟来自上层 FluidBackgroundScope；着色器不可用时包内自动回落。
        // 传 CachedNetworkImageProvider 是为了复用 App 的封面磁盘/内存缓存，
        // 避免为背景再下载一次同一张封面。
        //
        // [MixCardData.fluidColors] 有值时直接用它（跳过取色）。
        final url = data.imageUrl;
        final hasFixedColors = data.fluidColors != null;
        cover = FluidBackground(
          imageProvider: hasFixedColors || url == null || url.isEmpty
              ? null
              : CachedNetworkImageProvider(
                  url,
                  cacheManager: coverCacheManager,
                  cacheKey: coverArtCacheKeyFromUrl(url),
                ),
          colors: data.fluidColors,
          borderRadius: 12,
          seed: seed,
        );
      } else {
        cover = data.round
            ? ClipOval(
                child: AlbumArtwork(coverArt: data.coverArt, borderRadius: 0),
              )
            : AlbumArtwork(coverArt: data.coverArt, borderRadius: 12);
      }

      child = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1, child: cover),
          const SizedBox(height: 8),
          Text(
            data.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: tokens.secondaryText),
          ),
        ],
      );
    }

    return PressableScale(
      onTap: data.disabled ? null : data.onTap,
      onLongPress: data.disabled ? null : data.onLongPress,
      child: Opacity(opacity: data.disabled ? 0.7 : 1, child: child),
    );
  }
}

/// 播放按钮角标（网格卡右上角红色圆形播放键），供卡片 hover/常显。
class GridPlayBadge extends StatelessWidget {
  final VoidCallback onTap;

  const GridPlayBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.appleMusicRed,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}
