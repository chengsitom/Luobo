import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/image_cache.dart';
import '../widgets/album_artwork.dart';
import '../widgets/pressable_scale.dart';

/// 每日推荐大卡（§5.1 模块 1）。
///
/// 通栏渐变横幅：背景优先取主推封面主色渐变（暗化 35% 保证白字可读）；
/// 封面主色过亮（如纯白封面）或取色失败时回退 red→pink 强调渐变。
class DailyRecommendationCard extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? coverArt;

  /// 封面图片 URL（用于取色；与 [coverArt] 为同一首歌）。
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback onPlayAll;
  final double height;

  const DailyRecommendationCard({
    super.key,
    required this.title,
    this.subtitle,
    this.coverArt,
    this.imageUrl,
    required this.onTap,
    required this.onPlayAll,
    this.height = 200,
  });

  @override
  State<DailyRecommendationCard> createState() =>
      _DailyRecommendationCardState();
}

class _DailyRecommendationCardState extends State<DailyRecommendationCard> {
  /// 封面取色后的暗化主色；null 表示回退红色渐变。
  Color? _palette;

  /// 纯白等亮色封面回退的亮度阈值（过亮则不用，避免白底白字）。
  static const double _maxLuminance = 0.5;

  @override
  void initState() {
    super.initState();
    _extractPalette();
  }

  @override
  void didUpdateWidget(covariant DailyRecommendationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _extractPalette();
    }
  }

  Future<void> _extractPalette() async {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) {
      if (_palette != null && mounted) setState(() => _palette = null);
      return;
    }
    try {
      final palette = await PaletteGenerator.fromImageProvider(
        // 与展示图同一 300 URL + coverCacheManager，命中共享磁盘缓存
        // （图片缓存文档 §4.2/§4.3：取色不重复下载）。
        CachedNetworkImageProvider(url,
            cacheManager: coverCacheManager,
            cacheKey: coverArtCacheKeyFromUrl(url)),
        maximumColorCount: 12,
      );
      // 取色标准：优先 vibrant（最鲜艳、最有辨识度），再回落 dominant。
      // 避免红黑等双色封面因黑色像素多而取成纯黑背景（用户反馈）。
      final color = palette.vibrantColor?.color ?? palette.dominantColor?.color;
      if (color == null || color.computeLuminance() > _maxLuminance) {
        if (_palette != null && mounted) setState(() => _palette = null);
        return;
      }
      // 主色暗化 45%，保证白色文字可读（Apple Music 自适应背景做法）。
      final darkened = Color.lerp(color, Colors.black, 0.45)!;
      if (!mounted || darkened == _palette) return;
      setState(() => _palette = darkened);
    } catch (_) {
      if (_palette != null && mounted) setState(() => _palette = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _palette != null
        ? LinearGradient(
            colors: [
              // 0.45 暗化 → 原色：色差明显，渐变肉眼可见（用户反馈之前不明显）。
              Color.lerp(_palette, Colors.black, 0.45)!,
              _palette!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            // 回退：红 → 紫红（不再是「红→红」不可见）。
            colors: [AppTheme.appleMusicRed, Color(0xFFA02E8C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    return PressableScale(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: widget.height,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: gradient,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: widget.onPlayAll,
                    style: FilledButton.styleFrom(
                      backgroundColor: isDark ? Colors.black : Colors.white,
                      foregroundColor:
                          isDark ? Colors.white : AppTheme.appleMusicRed,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      AppLocalizations.of(context)!.playAll,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (widget.coverArt != null && widget.coverArt!.isNotEmpty) ...[
              const SizedBox(width: 16),
              AlbumArtwork(
                coverArt: widget.coverArt,
                size: 96,
                borderRadius: 16,
                shadow: BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
