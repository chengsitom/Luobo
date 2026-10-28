import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/heart_playlist.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../utils/image_cache.dart';

/// 心动歌单列表行：左侧 2×2 封面拼图 + 右侧名称/描述/标签/时长。
///
/// 设计取舍：
/// - 名称通常 20+ 字，2 列网格会大量截断，所以用**纵向列表**；
/// - 2×2 拼图是 Web 心动歌单的识别符号，保留；
/// - 行内不放播放按钮，避免「点行」和「点播放」两个目标打架。
class HeartPlaylistRow extends StatelessWidget {
  const HeartPlaylistRow({
    super.key,
    required this.playlist,
    required this.coverUrls,
    required this.onTap,
  });

  final HeartPlaylist playlist;

  /// 已带票据的 4 个封面 URL；空串 / 不足 4 个时用占位块补齐。
  final List<String> coverUrls;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final tags = <String>[
      ...playlist.genres,
      ...playlist.scenes,
    ].take(4).toList();

    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeartCoverMosaic(urls: coverUrls, size: 84),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      playlist.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: c.fg,
                      ),
                    ),
                    if (playlist.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        playlist.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.3,
                          color: c.fg2,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          for (final tag in tags) HeartTag(text: tag),
                        ],
                      ),
                    ],
                    if (playlist.metaLabel.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        playlist.metaLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: c.fg3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(top: 28),
                child: Icon(
                  AppIcons.forward,
                  size: 16,
                  color: c.fg3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HeartTag extends StatelessWidget {
  const HeartTag({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          color: accent,
        ),
      ),
    );
  }
}

/// 2×2 封面拼图。URL 不足 4 个时循环补齐；空串走占位块。
class HeartCoverMosaic extends StatelessWidget {
  const HeartCoverMosaic({super.key, required this.urls, required this.size});

  final List<String> urls;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final tiles = List<String>.generate(
      4,
      (i) => urls.isEmpty ? '' : urls[i % urls.length],
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(LuoboRadius.tile),
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, c, tiles[0])),
                  const SizedBox(width: 2),
                  Expanded(child: _tile(context, c, tiles[1])),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _tile(context, c, tiles[2])),
                  const SizedBox(width: 2),
                  Expanded(child: _tile(context, c, tiles[3])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(BuildContext context, LuoboColors c, String url) {
    if (url.isEmpty) return _placeholder(c);
    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      cacheManager: coverCacheManager,
      cacheKey: _cacheKey(url),
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (_, __) => _placeholder(c),
      errorWidget: (_, __, ___) => _placeholder(c),
    );
  }

  Widget _placeholder(LuoboColors c) {
    return ColoredBox(
      color: c.divider.withValues(alpha: 0.6),
      child: Center(
        child: Icon(AppIcons.music, size: 14, color: c.fg3),
      ),
    );
  }

  /// 票据每 120s 换一次；缓存键去掉 ticket，并按 (服务器, path, size) 归一，
  /// 这样 LAN↔公网切换、重复进页面都不会重新下载同一张图。
  String _cacheKey(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.queryParameters['path'];
      final size = uri.queryParameters['size'] ?? '100';
      if (path != null && path.isNotEmpty) {
        return 'heart-cover-$coverCacheServerId-$path-$size';
      }
    } catch (_) {
      // 解析失败走下面的兜底键。
    }
    final i = url.indexOf('ticket=');
    return i > 0 ? url.substring(0, i) : url;
  }
}
