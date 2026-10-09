import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../services/subsonic_service.dart';
import '../services/player_ui_settings_service.dart';
import '../utils/image_cache.dart';

bool isLocalFilePath(String? s) {
  if (s == null || s.isEmpty) return false;
  if (s.startsWith('/')) return true;
  if (s.length > 2 && s[1] == ':') return true;
  return false;
}

class _ImageUrlCache {
  static String getUrl(SubsonicService service, String? coverArt) {
    if (coverArt == null || coverArt.isEmpty) return '';
    // One size for every scene: a cover always maps to the same URL, so the
    // server-side resize cache and the client disk/memory cache each keep a
    // single entry per cover.
    return service.getCoverArtUrl(coverArt, size: kCoverArtRequestSize);
  }
}

class AlbumArtwork extends StatelessWidget {
  final String? coverArt;
  final double size;

  final double? borderRadius;
  final BoxShadow? shadow;

  final bool preserveAspectRatio;

  const AlbumArtwork({
    super.key,
    this.coverArt,
    this.size = 150,
    this.borderRadius,
    this.shadow,
    this.preserveAspectRatio = false,
  });

  @override
  Widget build(BuildContext context) {
    final svc = PlayerUiSettingsService();
    return ValueListenableBuilder<String>(
      valueListenable: svc.artworkShapeNotifier,
      builder: (context, shape, _) {
        return ValueListenableBuilder<double>(
          valueListenable: svc.albumArtCornerRadiusNotifier,
          builder: (context, globalRadius, _) {
            return ValueListenableBuilder<String>(
              valueListenable: svc.artworkShadowNotifier,
              builder: (context, shadowLevel, _) {
                return ValueListenableBuilder<String>(
                  valueListenable: svc.artworkShadowColorNotifier,
                  builder: (context, shadowColor, _) {
                    final resolvedRadius = borderRadius ??
                        (shape == 'circle'
                            ? 9999.0
                            : shape == 'square'
                                ? 0.0
                                : globalRadius);
                    return _buildContent(
                      context,
                      resolvedRadius,
                      shadowLevel,
                      shadowColor,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  BoxShadow? _resolvedShadow(
    BuildContext context,
    double resolvedRadius,
    String shadowLevel,
    String shadowColor,
    bool isDark,
  ) {
    if (shadow != null) return shadow;
    if (shadowLevel == 'none') return null;
    final Color color;
    switch (shadowColor) {
      case 'accent':
        color = Theme.of(context).colorScheme.primary;
        break;
      default:
        color = Colors.black;
    }
    double opacity;
    double blur;
    Offset offset;
    switch (shadowLevel) {
      case 'medium':
        opacity = isDark ? 0.35 : 0.25;
        blur = size / 6;
        offset = Offset(0, size / 20);
        break;
      case 'strong':
        opacity = isDark ? 0.55 : 0.40;
        blur = size / 4;
        offset = Offset(0, size / 12);
        break;
      default:
        opacity = isDark ? 0.22 : 0.14;
        blur = size / 10;
        offset = Offset(0, size / 30);
    }
    return BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: blur,
      offset: offset,
    );
  }

  Widget _buildContent(
    BuildContext context,
    double resolvedRadius,
    String shadowLevel,
    String shadowColor,
  ) {
    final validSize = size.isFinite && !size.isNaN ? size : 150.0;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resolvedShadow = _resolvedShadow(
      context,
      resolvedRadius,
      shadowLevel,
      shadowColor,
      isDark,
    );

    if (preserveAspectRatio) {
      return Container(
        constraints: BoxConstraints(maxWidth: validSize),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(resolvedRadius),
          boxShadow: resolvedShadow != null ? [resolvedShadow] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(resolvedRadius),
          child: _buildImageNatural(isDark),
        ),
      );
    }

    return Container(
      width: validSize,
      height: validSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(resolvedRadius),
        boxShadow:
            resolvedShadow != null && validSize > 60 ? [resolvedShadow] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(resolvedRadius),
        child: _buildImage(isDark),
      ),
    );
  }

  Widget _buildImageNatural(bool isDark) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.contain,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    return Builder(
      builder: (context) {
        final imageUrl = _ImageUrlCache.getUrl(
          Provider.of<SubsonicService>(context, listen: false),
          coverArt,
        );
        if (imageUrl.isEmpty) return _buildPlaceholder(isDark);
        return CachedNetworkImage(
          cacheManager: coverCacheManager,
          imageUrl: imageUrl,
          // Semantic key (coverArt-<serverId>-<id>-300): stable across password
          // changes, per-server isolated, queryable by id. See image_cache.dart.
          cacheKey: coverArtCacheKey(coverArt!),
          fit: BoxFit.contain,
          memCacheWidth: kCoverArtRequestSize,
          memCacheHeight: kCoverArtRequestSize,
          maxWidthDiskCache: kCoverArtRequestSize,
          maxHeightDiskCache: kCoverArtRequestSize,
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (ctx, url) => _buildPlaceholder(isDark),
          errorWidget: (ctx, err, stack) {
            debugPrint('AlbumArtwork error (natural): $err');
            return _buildNetworkImageFallback(imageUrl, isDark, BoxFit.contain);
          },
        );
      },
    );
  }

  Widget _buildImage(bool isDark) {
    if (coverArt == null || coverArt!.isEmpty) return _buildPlaceholder(isDark);

    if (isLocalFilePath(coverArt)) {
      final artFile = File(coverArt!);
      return Image.file(
        artFile,
        key: ValueKey(coverArt),
        fit: BoxFit.cover,
        cacheWidth: kCoverArtRequestSize,
        cacheHeight: kCoverArtRequestSize,
        errorBuilder: (ctx, err, stack) => _buildPlaceholder(isDark),
      );
    }

    return Builder(
      builder: (context) {
        final imageUrl = _ImageUrlCache.getUrl(
          Provider.of<SubsonicService>(context, listen: false),
          coverArt,
        );
        if (imageUrl.isEmpty) return _buildPlaceholder(isDark);
        return CachedNetworkImage(
          cacheManager: coverCacheManager,
          imageUrl: imageUrl,
          cacheKey: coverArtCacheKey(coverArt!),
          fit: BoxFit.cover,
          memCacheWidth: kCoverArtRequestSize,
          memCacheHeight: kCoverArtRequestSize,
          maxWidthDiskCache: kCoverArtRequestSize,
          maxHeightDiskCache: kCoverArtRequestSize,
          fadeInDuration: const Duration(milliseconds: 100),
          fadeOutDuration: Duration.zero,
          useOldImageOnUrlChange: true,
          placeholder: (ctx, url) => _buildPlaceholder(isDark),
          errorWidget: (ctx, err, stack) {
            debugPrint('AlbumArtwork error: $err');
            return _buildNetworkImageFallback(imageUrl, isDark, BoxFit.cover);
          },
        );
      },
    );
  }

  Widget _buildNetworkImageFallback(String url, bool isDark, BoxFit fit) {
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (ctx, err, stack) {
        debugPrint('Network image fallback error: $err');
        return _buildPlaceholder(isDark);
      },
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF2A2A2A), const Color(0xFF1A1A1A)]
              : [Colors.grey.shade300, Colors.grey.shade200],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.music_note_rounded,
          size: (size / 3).clamp(16.0, 60.0),
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }
}
