import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/album.dart';
import '../../models/artist.dart';
import '../../providers/library_provider.dart';
import '../../theme/design_tokens.dart';
import '../../utils/image_cache.dart';
import '../../utils/navigation_helper.dart';
import '../../screens/album_screen.dart';
import '../../screens/artist_screen.dart';
import '../album_artwork.dart';

/// 专辑行（64dp）：方形封面 48 r6 + 名称 16/600 +「艺术家 · 年份」12 + chevron。
/// 专辑列表页与**搜索结果「专辑」tab**共用。
class AlbumListTile extends StatelessWidget {
  final Album album;

  /// 跳转前回调（搜索页用它记录搜索历史）。
  final VoidCallback? onBeforeNavigate;

  const AlbumListTile({super.key, required this.album, this.onBeforeNavigate});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final l10n = AppLocalizations.of(context)!;
    final subtitle = [
      if ((album.artist ?? '').isNotEmpty) album.artist!,
      if (album.year != null) l10n.albumYear(album.year!),
    ].join(' · ');

    return InkWell(
      onTap: () {
        onBeforeNavigate?.call();
        NavigationHelper.push(context, AlbumScreen(albumId: album.id));
      },
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AlbumArtwork(coverArt: album.coverArt, size: 48, borderRadius: 6),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      album.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18, color: c.fg3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 歌手行（64dp）：圆形头像 48 + 名字 16/600 +「N 首歌 · M 张专辑」12 + chevron。
/// 歌手列表页与**搜索结果「歌手」tab**共用（对齐 fnos v12_0023）。
class ArtistListTile extends StatelessWidget {
  final Artist artist;
  final int songCount;
  final int albumCount;

  /// 跳转前回调（搜索页用它记录搜索历史）。
  final VoidCallback? onBeforeNavigate;

  const ArtistListTile({
    super.key,
    required this.artist,
    required this.songCount,
    required this.albumCount,
    this.onBeforeNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return InkWell(
      onTap: () {
        onBeforeNavigate?.call();
        NavigationHelper.push(context, ArtistScreen(artistId: artist.id));
      },
      child: SizedBox(
        height: 64,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _ArtistAvatar(artist: artist),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.body.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      AppLocalizations.of(context)!
                          .artistStats(songCount, albumCount),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: LuoboType.caption.copyWith(color: c.fg2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 18, color: c.fg3),
            ],
          ),
        ),
      ),
    );
  }
}

/// 圆形头像 48：网络图（artistImageUrl / coverArt / 专辑封面）→ 首字母占位。
class _ArtistAvatar extends StatelessWidget {
  final Artist artist;

  const _ArtistAvatar({required this.artist});

  @override
  Widget build(BuildContext context) {
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final cover = libraryProvider.resolveArtistCover(artist);
    final url = cover.hasImage
        ? cover.imageUrl
        : (cover.hasFallback ? cover.fallbackImageUrl : null);

    Widget placeholder() => _LetterAvatar(name: artist.name);

    return SizedBox(
      width: 48,
      height: 48,
      child: ClipOval(
        child: url == null || url.isEmpty
            ? placeholder()
            : CachedNetworkImage(
                imageUrl: url,
                cacheManager: coverCacheManager,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 120),
                fadeOutDuration: Duration.zero,
                placeholder: (_, __) => placeholder(),
                errorWidget: (_, __, ___) {
                  if (cover.hasFallback && cover.fallbackImageUrl != url) {
                    return CachedNetworkImage(
                      imageUrl: cover.fallbackImageUrl!,
                      cacheManager: coverCacheManager,
                      fit: BoxFit.cover,
                      fadeInDuration: const Duration(milliseconds: 120),
                      placeholder: (_, __) => placeholder(),
                      errorWidget: (_, __, ___) => placeholder(),
                    );
                  }
                  return placeholder();
                },
              ),
      ),
    );
  }
}

class _LetterAvatar extends StatelessWidget {
  final String name;

  const _LetterAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final letter = name.isEmpty ? '#' : name[0].toUpperCase();
    return Container(
      color: c.card,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: LuoboType.body.copyWith(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: c.fg2,
        ),
      ),
    );
  }
}
