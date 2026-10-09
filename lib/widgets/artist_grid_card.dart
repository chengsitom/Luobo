import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/artist.dart';
import '../providers/library_provider.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/image_cache.dart';
import 'pressable_scale.dart';
import 'artist_collage_cover.dart';
import 'artist_placeholder.dart';

/// 艺术家方形网格卡（音乐库-艺术家 tab 用，网易云/QQ 风）。
/// 封面走 `LibraryProvider.resolveArtistCover` 5 级解析链路：
/// artistImageUrl 直链 → coverArt → 专辑单图 → 2×2 拼贴 → 渐变首字母。
/// 与首页在用的圆形 `ArtistCard` 独立，互不影响。
class ArtistGridCard extends StatefulWidget {
  final Artist artist;

  /// 本地累计播放次数（常听 shelf 小字用）；null 时退化为专辑数。
  final int? playCount;

  final VoidCallback? onTap;
  final VoidCallback? onPlayPressed;

  const ArtistGridCard({
    super.key,
    required this.artist,
    this.playCount,
    this.onTap,
    this.onPlayPressed,
  });

  @override
  State<ArtistGridCard> createState() => _ArtistGridCardState();
}

class _ArtistGridCardState extends State<ArtistGridCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final cover = libraryProvider.resolveArtistCover(widget.artist);
    final secondaryText =
        isDark ? AppTheme.darkSecondaryText : AppTheme.lightSecondaryText;

    return PressableScale(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AnimatedScale(
                    scale: _isHovered ? 1.03 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _ArtistGridCover(
                        cover: cover,
                        borderRadius: 10,
                      ),
                    ),
                  ),
                  if (_isHovered && widget.onPlayPressed != null)
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: widget.onPlayPressed,
                            customBorder: const CircleBorder(),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 名字 + 副标题固定 44px 文本区：行高与字体缩放无关，杜绝
              // GridView cell 固定高度下的 bottom overflow。
              SizedBox(
                height: 44,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.artist.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    _buildSubtitle(context, secondaryText),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, Color secondaryText) {
    final l10n = AppLocalizations.of(context);
    final playCount = widget.playCount;
    if (playCount != null && playCount > 0) {
      return Text(
        l10n?.playsCount(playCount) ?? '$playCount',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: secondaryText,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    final albumCount = widget.artist.albumCount;
    if (albumCount != null) {
      return Text(
        l10n?.albumsCount(albumCount) ?? '$albumCount',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: secondaryText,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }
    return const SizedBox.shrink();
  }
}

/// 常听 shelf 横版长方形卡：**纯渐变背景**（不加载网络图，更快更统一）+
/// 首字母居中 + 名字/播放次数叠在框内底部。两排横滑网格用。
class ArtistShelfCard extends StatelessWidget {
  final Artist artist;
  final int? playCount;
  final VoidCallback? onTap;

  const ArtistShelfCard({
    super.key,
    required this.artist,
    this.playCount,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return PressableScale(
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ArtistPlaceholder(name: artist.name),
              // 底部渐变遮罩，保证白字在任意渐变色上可读。
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black38],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artist.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (playCount != null && playCount! > 0)
                      Text(
                        l10n?.playsCount(playCount!) ?? '$playCount',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 图加载失败诊断（限 3 条防刷屏）：输出失败 URL 与错误，用于定位
/// 外部直链（artistImageUrl）为何加载失败。
int _coverImageErrorLogCount = 0;
void _logCoverImageError(String url, Object err) {
  if (_coverImageErrorLogCount >= 3) return;
  _coverImageErrorLogCount++;
  debugPrint('[ArtistCover] 图加载失败: url=$url err=$err');
}

/// 按 `ArtistCover` 结果择一渲染：网络图 → 2×2 拼贴 → 渐变占位。
/// 网络图加载失败时降级到渐变占位（解析链路兜底，不破图）。
class _ArtistGridCover extends StatelessWidget {
  final ArtistCover cover;
  final double borderRadius;

  const _ArtistGridCover({required this.cover, required this.borderRadius});

  @override
  Widget build(BuildContext context) {
    if (cover.hasImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _CoverImage(
          url: cover.imageUrl!,
          cover: cover,
          borderRadius: borderRadius,
        ),
      );
    }
    if (cover.hasCollage) {
      return ArtistCollageCover(
        coverArtIds: cover.collageCovers,
        borderRadius: borderRadius,
        placeholderName: cover.name,
      );
    }
    return ArtistPlaceholder(
      name: cover.name,
      borderRadius: borderRadius,
    );
  }
}

/// 方形封面图（带降级链）：主 URL 失败 → fallback 专辑封面 → 2×2 拼贴 → 渐变。
/// 外部直链（artistImageUrl）常有防盗链/网络失败，降级链保证不直接变渐变。
class _CoverImage extends StatelessWidget {
  final String url;
  final ArtistCover cover;
  final double borderRadius;

  const _CoverImage({
    required this.url,
    required this.cover,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: coverCacheManager,
      cacheKey: coverArtCacheKeyFromUrl(url),
      fit: BoxFit.cover,
      memCacheWidth: kCoverArtRequestSize,
      memCacheHeight: kCoverArtRequestSize,
      maxWidthDiskCache: kCoverArtRequestSize,
      maxHeightDiskCache: kCoverArtRequestSize,
      fadeInDuration: const Duration(milliseconds: 100),
      fadeOutDuration: Duration.zero,
      placeholder: (ctx, url) => ArtistPlaceholder(
        name: cover.name,
        borderRadius: borderRadius,
      ),
      errorWidget: (ctx, url, err) {
        _logCoverImageError(url, err);
        // 主 URL 失败 → fallback 专辑封面（再次失败 → 拼贴/渐变）。
        if (url != cover.fallbackImageUrl && cover.hasFallback) {
          return _CoverImage(
            url: cover.fallbackImageUrl!,
            cover: cover,
            borderRadius: borderRadius,
          );
        }
        if (cover.hasCollage) {
          return ArtistCollageCover(
            coverArtIds: cover.collageCovers,
            borderRadius: borderRadius,
            placeholderName: cover.name,
          );
        }
        return ArtistPlaceholder(
          name: cover.name,
          borderRadius: borderRadius,
        );
      },
    );
  }
}
