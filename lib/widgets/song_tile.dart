import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/artist_ref.dart';
import '../models/song.dart';
import '../utils/navigation_helper.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/player_ui_settings_service.dart';
import '../services/subsonic_service.dart';
import '../services/offline_service.dart';
import '../services/transcoding_service.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import 'album_artwork.dart';
import 'animated_equalizer.dart';
import 'dolby_atmos_badge.dart';
import 'luobo/action_grid.dart';
import 'luobo/create_playlist_dialog.dart';
import 'luobo/empty_state.dart';
import 'luobo/luobo_toast.dart';
import 'luobo/sheet_shell.dart';
import 'glass_surface.dart';
import 'multi_artist_widget.dart';
import 'pressable_scale.dart';
import '../screens/album_screen.dart';
import '../screens/artist_screen.dart';

/// 歌曲 `⋮` 菜单的调用来源（设计稿/09，规格见
/// `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.1）：
/// 菜单按来源**显式裁剪**，不靠运行时猜；缺参时 [SongTile.menuContext]
/// 默认 [SongMenuContext.list]（最全变体），避免漏项。
enum SongMenuContext {
  /// 列表页 / 首页：横排主操作 + 收藏 + 添加到歌单。
  list,

  /// 播放页：无横排主操作、无「收藏」（♡ 已在播放页常驻）。
  player,

  /// 歌单详情页内：同 [list]，多「从当前歌单移除」。
  playlist,

  /// 播放历史 / 最近播放页内：同 [list]，**无「收藏」行**
  /// （用户 2026-10-23：历史是收听记录，不该出现「从喜欢的歌曲中移除」；
  /// 与歌单变体的处理一致——收藏管理只留在收藏页/列表页）。
  history,
}

class SongTile extends StatelessWidget {
  final Song song;
  final List<Song>? playlist;
  final int? index;
  final bool showArtwork;
  final bool showArtist;
  final bool showAlbum;
  final bool showDuration;
  final bool showTrackNumber;
  final int titleMaxLines;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// `⋮` 菜单的调用来源（默认 [SongMenuContext.list]）。
  final SongMenuContext menuContext;

  /// 仅 [SongMenuContext.playlist] 需要：从当前歌单移除的回调
  /// （由调用方弹确认 + 执行移除；`null` 时菜单不出该项）。
  final VoidCallback? onRemoveFromPlaylist;

  /// 多选模式（§4.5）：为 true 时 leading 显示圆形选择框（替换播放中态覆盖层）、
  /// 隐藏 `⋮`，onTap 由页面接管（切换选中），onLongPress 忽略。
  final bool selectionMode;

  /// 多选模式下的选中态（玫红实心✓）。
  final bool selected;

  /// 行内垂直 padding（默认 0：dense 双行基准即 64dp，与 fnos 实测一致；
  /// ⚠️ 非 0 会**叠加**在 64 之上，别用来调行高）。
  final double contentVerticalPadding;

  const SongTile({
    super.key,
    required this.song,
    this.playlist,
    this.index,
    this.showArtwork = true,
    this.showArtist = true,
    this.showAlbum = false,
    this.showDuration = false,
    this.showTrackNumber = false,
    this.titleMaxLines = 1,
    this.onTap,
    this.onLongPress,
    this.menuContext = SongMenuContext.list,
    this.onRemoveFromPlaylist,
    this.selectionMode = false,
    this.selected = false,
    this.contentVerticalPadding = 0,
  });

  /// Cached adaptive font sizes for the `artist • album` subtitle,
  /// keyed by `text|width`, so scrolling lists don't re-measure.
  static final Map<String, double> _adaptiveSizeCache = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Selector<PlayerProvider, String?>(
      selector: (_, provider) => provider.currentSong?.id,
      builder: (context, currentSongId, _) {
        final isCurrentSong = currentSongId == song.id;

        return PressableScale(
          child: ListTile(
            // fnos 静态图实测：行距 **64dp**（Material 双行默认 72 → dense 收紧）。
            dense: true,
            // fnos 实测：⋮ 距右缘 ≈26dp → 右侧内边距压到 8；标题起点
            // = 16 + 封面 48 + 10 = 74dp（leading 间距 10）。
            contentPadding: EdgeInsets.only(
              left: 16,
              right: 8,
              top: contentVerticalPadding,
              bottom: contentVerticalPadding,
            ),
            horizontalTitleGap: 10,
            leading: _buildLeading(context, isCurrentSong),
            title: Text(
              song.title,
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 15),
              maxLines: titleMaxLines,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle:
                showArtist || showAlbum ? _buildSubtitleWidget(theme) : null,
            trailing: _buildTrailing(context),
            onTap: selectionMode
                ? (onTap ?? () {})
                : (onTap ?? () => _playSong(context)),
            onLongPress: selectionMode
                ? null
                : (onLongPress ?? () => _showOptions(context)),
          ),
        );
      },
    );
  }

  Widget? _buildLeading(BuildContext context, bool isCurrentSong) {
    if (selectionMode) {
      // 多选模式（§4.5）：圆形选择框（20，选中玫红实心✓）+ 封面 42。
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSelectionCheck(context),
          const SizedBox(width: 10),
          AlbumArtwork(
            coverArt: Provider.of<LibraryProvider>(context, listen: false)
                .effectiveCoverArt(song),
            size: 48,
            preserveAspectRatio: true,
          ),
        ],
      );
    }

    if (showTrackNumber && !showArtwork) {
      return SizedBox(
        width: 30,
        child: Center(
          child: isCurrentSong
              ? Selector<PlayerProvider, bool>(
                  selector: (ctx, p) => p.isPlaying,
                  builder: (ctx, isPlaying, __) => AnimatedEqualizer(
                    color: Theme.of(context).colorScheme.primary,
                    isPlaying: isPlaying,
                  ),
                )
              : Text(
                  // 序号行（设计稿/08 §3）：两位补零 + 等宽数字，对齐 fnos「01/02」。
                  '${song.track ?? index ?? 1}'.padLeft(2, '0'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightSecondaryText,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
        ),
      );
    }

    if (showArtwork) {
      return ValueListenableBuilder<String>(
        valueListenable: PlayerUiSettingsService().artworkShapeNotifier,
        builder: (context, shape, _) {
          return ValueListenableBuilder<double>(
            valueListenable:
                PlayerUiSettingsService().albumArtCornerRadiusNotifier,
            builder: (context, radius, _) {
              // Resolve the effective corner radius the same way
              // AlbumArtwork does, so the overlay and the quality tag stay
              // aligned with the artwork's actual shape.
              final resolvedRadius = shape == 'circle'
                  ? 9999.0
                  : shape == 'square'
                      ? 0.0
                      : radius;
              return Stack(
                children: [
                  AlbumArtwork(
                    // Song covers are the album cover; normalize so all songs
                    // of an album share the same cache key.
                    coverArt: Provider.of<LibraryProvider>(
                      context,
                      listen: false,
                    ).effectiveCoverArt(song),
                    size: 48,
                    preserveAspectRatio: true,
                  ),
                  if (isCurrentSong)
                    // 播放中态：封面覆盖暗色遮罩 + **均衡器动画**（用户 2026-10-22：
                    // 要动画不要播放 icon；恢复原 AnimatedEqualizer 方案）。
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(resolvedRadius),
                        ),
                        child: Center(
                          child: Selector<PlayerProvider, bool>(
                            selector: (ctx, p) => p.isPlaying,
                            builder: (ctx, isPlaying, __) => AnimatedEqualizer(
                              color: Colors.white,
                              isPlaying: isPlaying,
                            ),
                          ),
                        ),
                      ),
                    ),
                  // Quality tag (original file info / actual transcode state)
                  // overlaid on the artwork corner — takes no layout space.
                  _buildQualityTag(context, isCurrentSong, resolvedRadius) ??
                      const SizedBox.shrink(),
                ],
              );
            },
          );
        },
      );
    }

    return null;
  }

  /// 多选圆形选择框（§4.5）：未选 = 灰圈；选中 = 玫红实心 + 白勾。
  Widget _buildSelectionCheck(BuildContext context) {
    final c = LuoboColors.of(context);
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? LuoboAccent.accent : Colors.transparent,
        border: Border.all(
          color: selected ? LuoboAccent.accent : c.fg3,
          width: 1.8,
        ),
      ),
      child: selected
          ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
          : null,
    );
  }

  Widget _buildSubtitleWidget(ThemeData theme) {
    if (showArtist) {
      if (showAlbum && song.album != null) {
        // Merge artist + album into a single line. Shrink the font when it
        // doesn't fit instead of hard-splitting the width between the two.
        final artistLabel = _artistLabel();
        final fullText = '$artistLabel \u2022 ${song.album}';
        final baseStyle =
            theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12);
        final baseSize = baseStyle.fontSize ?? 12;
        return LayoutBuilder(
          builder: (context, constraints) {
            // Cache the computed font size per (text, width) so scrolling
            // lists don't re-measure the same subtitle on every frame.
            final cacheKey = '$fullText|${constraints.maxWidth.round()}';
            final cached = _adaptiveSizeCache[cacheKey];
            final double size;
            if (cached != null) {
              size = cached;
            } else {
              var s = baseSize;
              while (s > 10 &&
                  _textWidth(fullText, baseStyle, s) > constraints.maxWidth) {
                s -= 1;
              }
              if (_adaptiveSizeCache.length > 1000) {
                _adaptiveSizeCache.clear();
              }
              _adaptiveSizeCache[cacheKey] = s;
              size = s;
            }
            return Text(
              fullText,
              style: baseStyle.copyWith(fontSize: size),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            );
          },
        );
      }
      return MultiArtistWidget(
        artists: song.artistParticipants,
        artistFallback: song.artist,
        artistIdFallback: song.artistId,
        style: theme.textTheme.bodySmall,
        // 列表行里歌手名不响应点击（防误触进歌手页，2026-10-22）。
        enableTap: false,
      );
    }

    return Text(
      song.album ?? '',
      style: theme.textTheme.bodySmall,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _artistLabel() {
    final participants = song.artistParticipants;
    if (participants != null && participants.isNotEmpty) {
      return participants.map((a) => a.name).join(', ');
    }
    return song.artist ?? '';
  }

  static double _textWidth(String text, TextStyle base, double fontSize) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: base.copyWith(fontSize: fontSize)),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();
    return painter.width;
  }

  /// Serif ("文艺") typeface for the quality tag: Songti SC on Apple
  /// platforms, the platform serif on Android, Georgia elsewhere.
  static String _badgeSerifFont(TargetPlatform platform) {
    switch (platform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return 'Songti SC';
      case TargetPlatform.android:
        return 'serif';
      default:
        return 'Georgia';
    }
  }

  /// Compact sample rate for the badge (e.g. "96k", "44.1k"), empty when
  /// unknown.
  String _compactSampleRate() {
    final hz = song.samplingRate;
    if (hz == null || hz <= 0) return '';
    if (hz % 1000 == 0) return '${hz ~/ 1000}k';
    return '${(hz / 1000).toStringAsFixed(1)}k';
  }

  /// Tiny quality tag overlaid on the artwork's bottom-right corner, e.g.
  /// "FLAC·964" (original file info) or "Opus·192" in orange when the
  /// current song's actual stream is transcoded. Takes no layout space.
  Widget? _buildQualityTag(
    BuildContext context,
    bool isCurrentSong,
    double cornerRadius,
  ) {
    // The transcode snapshot is captured asynchronously after the
    // current-song notification (when the stream URL is actually built), so
    // watch it reactively: the tag flips to orange with the transcoded
    // bitrate as soon as the stream is transcoded, instead of only when the
    // tile happens to rebuild.
    return Selector<PlayerProvider, (bool, int?, String?)>(
      selector: (_, player) => (
        player.isActiveStreamTranscoded,
        player.activeStreamBitrate,
        player.activeStreamFormat,
      ),
      builder: (context, transcode, _) {
        final (isTranscoded, transcodeBitrate, transcodeFormat) = transcode;
        final effectiveTranscoded = isCurrentSong && isTranscoded;

        final format = effectiveTranscoded
            ? TranscodeFormat.getLabel(transcodeFormat ?? '')
            : (song.suffix?.toUpperCase() ?? '');
        final bitrate = effectiveTranscoded ? transcodeBitrate : song.bitRate;

        final parts = <String>[];
        if (format.isNotEmpty && format != 'Original') parts.add(format);
        if (bitrate != null && bitrate > 0) parts.add('$bitrate');
        // Compact sample rate (e.g. "96k") — the transcoded stream's sample
        // rate isn't tracked, so only show it for the original file.
        if (!effectiveTranscoded) {
          final sampleRate = _compactSampleRate();
          if (sampleRate.isNotEmpty) parts.add(sampleRate);
        }
        if (parts.isEmpty) return const SizedBox.shrink();
        final label = parts.join('·');

        // Gold highlight for hi-res originals (≥96 kHz / ≥24-bit).
        final isHiRes = !effectiveTranscoded &&
            (song.samplingRate ?? 0) >= 96000 &&
            (song.bitDepth ?? 24) >= 24;
        final badgeColor = effectiveTranscoded
            ? const Color(0xFFE65100)
            : isHiRes
                ? const Color(0xFFC9A227)
                : Colors.black;

        final l10n = AppLocalizations.of(context)!;
        final network = Provider.of<TranscodingService>(context, listen: false)
                    .currentConnectionType ==
                ConnectionType.wifi
            ? l10n.networkWifi
            : l10n.networkMobile;
        final tooltip = effectiveTranscoded
            ? l10n.transcodedTo(
                TranscodeFormat.getLabel(transcodeFormat ?? ''),
                transcodeBitrate ?? 0,
                network,
              )
            : l10n.noTranscoding;

        // Clip the tag against the artwork's own rounded shape (same radius)
        // so its bottom follows the image's rounded corners instead of square
        // edges spanning them. The clip covers the full artwork rect, so the
        // radius is not clamped down by the tag's own small height. The tag
        // itself stays a bottom-anchored bar with its natural height.
        return Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(cornerRadius),
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Tooltip(
                    message: tooltip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.65),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                      alignment: Alignment.center,
                      // Scale the label down when it doesn't fit (e.g. the
                      // appended sample rate makes it longer) instead of
                      // overflowing or clipping.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 7,
                            height: 1.2,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                            letterSpacing: 0.2,
                            color: Colors.white,
                            fontFamily: _badgeSerifFont(
                              Theme.of(context).platform,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (song.hasDolbyAtmos == true)
          const Padding(
            padding: EdgeInsets.only(right: 6),
            child: DolbyAtmosBadge(),
          ),
        if (showDuration)
          Text(
            song.formattedDuration,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (!selectionMode) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(AppIcons.moreV),
            iconSize: 18,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            color: Theme.of(context).textTheme.bodySmall?.color,
            onPressed: () => _showOptions(context),
          ),
        ],
      ],
    );
  }

  void _playSong(BuildContext context) {
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    playerProvider.playSong(song, playlist: playlist, startIndex: index);
  }

  void _showOptions(BuildContext context) {
    showSongMenuSheet(
      context,
      song: song,
      menuContext: menuContext,
      onRemoveFromPlaylist: onRemoveFromPlaylist,
    );
  }
}

class _SongOptionsSheet extends StatefulWidget {
  final Song song;
  final SongMenuContext menuContext;
  final VoidCallback? onRemoveFromPlaylist;

  const _SongOptionsSheet({
    required this.song,
    this.menuContext = SongMenuContext.list,
    this.onRemoveFromPlaylist,
  });

  @override
  State<_SongOptionsSheet> createState() => _SongOptionsSheetState();
}

class _SongOptionsSheetState extends State<_SongOptionsSheet> {
  late bool _isStarred;
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  final _offlineService = OfflineService();

  /// 竖列行规格（方案 §9）：行高 52（文字 20 + 上下 16）+ 卡间 gap 12。
  static const _rowPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 16);
  static const double _rowGap = 12;

  @override
  void initState() {
    super.initState();
    _isStarred = widget.song.starred ?? false;
    _checkDownloadStatus();
  }

  void _checkDownloadStatus() {
    _isDownloaded = _offlineService.isSongDownloaded(widget.song.id);
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final l10n = AppLocalizations.of(context)!;
    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final isPlayer = widget.menuContext == SongMenuContext.player;
    final isPlaylist = widget.menuContext == SongMenuContext.playlist;
    final coverArt = Provider.of<LibraryProvider>(context, listen: false)
        .effectiveCoverArt(song);

    // 三段式（设计稿/09）：上下文头 → 主操作横排（非 player）→ 竖列行。
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SongMenuHeader(song: song, coverArt: coverArt),
        if (!isPlayer) ...[
          const SizedBox(height: 15),
          LuoboActionGrid(
            items: [
              LuoboActionItem(
                icon: AppIcons.play,
                label: l10n.play,
                onTap: () {
                  Navigator.pop(context);
                  playerProvider.playSong(song);
                },
              ),
              LuoboActionItem(
                icon: AppIcons.skipForward,
                label: l10n.playNext,
                onTap: () {
                  playerProvider.addToQueueNext(song);
                  // 状态提醒（fnos：下一首播放也有 Toast）。
                  showLuoboToast(
                    context,
                    message: l10n.queuedAsNext,
                    tone: LuoboToastTone.info,
                  );
                  Navigator.pop(context);
                },
              ),
              LuoboActionItem(
                icon: AppIcons.queue,
                label: l10n.addToPlaybackQueue,
                onTap: () {
                  playerProvider.addToQueue(song);
                  // 状态提醒：加入播放队列（原先静默）。
                  showLuoboToast(
                    context,
                    message: l10n.addedToQueue,
                    tone: LuoboToastTone.info,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        // 专辑：xxx —— 有 albumId 才可点。
        LuoboSheetRow(
          title: l10n.albumLabel(song.album ?? '—'),
          contentPadding: _rowPadding,
          gap: _rowGap,
          trailing:
              const Icon(AppIcons.album, size: 18, color: LuoboAccent.accent),
          onTap: song.albumId == null
              ? null
              : () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumScreen(albumId: song.albumId!),
                    ),
                  );
                },
        ),
        // 歌手：xxx —— 有 artistId 才可点。
        LuoboSheetRow(
          title: l10n.artistLabel(song.artist ?? '—'),
          contentPadding: _rowPadding,
          gap: _rowGap,
          trailing:
              const Icon(AppIcons.artist, size: 18, color: LuoboAccent.accent),
          onTap: song.artistId == null
              ? null
              : () {
                  final nav = Navigator.of(context);
                  nav.pop();
                  _navigateToArtist(nav);
                },
        ),
        _buildDownloadTile(context),
        // 收藏行只在**列表页/收藏页变体**出现（用户 2026-10-22：歌单内 ⋮
        // 不应有「从喜欢的歌曲中移除」；收藏页的 ⋮ 需要它 → 保留。
        // 2026-10-23：播放历史同样不出该行）。
        if (widget.menuContext == SongMenuContext.list)
          LuoboSheetRow(
            title:
                _isStarred ? l10n.removeFromLikedSongs : l10n.addToLikedSongs,
            contentPadding: _rowPadding,
            gap: _rowGap,
            trailing: Icon(
              AppIcons.heart,
              size: 18,
              color: _isStarred
                  ? LuoboAccent.accent
                  : Theme.of(context).colorScheme.primary,
            ),
            onTap: () async {
              await _toggleFavorite(context);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
        LuoboSheetRow(
          title: l10n.addToPlaylist,
          contentPadding: _rowPadding,
          gap: _rowGap,
          trailing: const Icon(AppIcons.playlist,
              size: 18, color: LuoboAccent.accent),
          onTap: () {
            Navigator.pop(context);
            _showPlaylistPicker(context, song);
          },
        ),
        if (isPlaylist && widget.onRemoveFromPlaylist != null)
          LuoboSheetRow(
            title: l10n.removeFromPlaylist,
            contentPadding: _rowPadding,
            gap: _rowGap,
            trailing: const Icon(AppIcons.playlist,
                size: 18, color: LuoboAccent.accent),
            onTap: () {
              Navigator.pop(context);
              widget.onRemoveFromPlaylist!();
            },
          ),
        LuoboSheetRow(
          title: l10n.songInfo,
          contentPadding: _rowPadding,
          gap: 0,
          trailing:
              const Icon(AppIcons.info, size: 18, color: LuoboAccent.accent),
          onTap: () {
            Navigator.pop(context);
            showSongInfoSheet(context, song);
          },
        ),
      ],
    );
  }

  Widget _buildDownloadTile(BuildContext context) {
    final isOffline = Provider.of<AuthProvider>(context, listen: false).state ==
        AuthState.offlineMode;
    final l10n = AppLocalizations.of(context)!;

    if (_isDownloading) {
      // 下载进度行（竖列行规格 52 高）。
      return LuoboSheetRow(
        title: l10n.downloading((_downloadProgress * 100).toInt()),
        contentPadding: _rowPadding,
        gap: _rowGap,
        trailing: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            value: _downloadProgress > 0 ? _downloadProgress : null,
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    }

    if (_isDownloaded) {
      return LuoboSheetRow(
        title: l10n.downloaded,
        contentPadding: _rowPadding,
        gap: _rowGap,
        trailing: const Icon(
          Icons.download_done_rounded,
          size: 18,
          color: Colors.green,
        ),
        onTap: () async {
          final confirm = await showLuoboConfirmSheet(
            context: context,
            title: l10n.removeDownload,
            message: l10n.removeDownloadConfirm,
            confirmLabel: l10n.remove,
          );
          if (confirm == true) {
            await _offlineService.deleteSong(widget.song.id);
            if (mounted) {
              setState(() {
                _isDownloaded = false;
              });
              showLuoboToast(
                context,
                message: l10n.downloadRemoved,
                tone: LuoboToastTone.success,
              );
            }
          }
        },
      );
    }

    if (isOffline) return const SizedBox.shrink();

    return LuoboSheetRow(
      title: l10n.download,
      contentPadding: _rowPadding,
      gap: _rowGap,
      trailing: const Icon(
        Icons.download_rounded,
        size: 18,
        color: LuoboAccent.accent,
      ),
      onTap: () => _downloadSong(context),
    );
  }

  Future<void> _downloadSong(BuildContext context) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final success = await _offlineService.downloadSong(
        widget.song,
        subsonicService,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _isDownloading = false;
          _isDownloaded = success;
        });

        if (success) {
          showLuoboToast(
            context,
            message: l10n.downloadedTitle(widget.song.title),
            tone: LuoboToastTone.success,
          );
        } else {
          showLuoboToast(
            context,
            message: l10n.downloadFailed,
            tone: LuoboToastTone.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
        showLuoboToast(
          context,
          message: l10n.downloadError(e),
          tone: LuoboToastTone.error,
        );
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    try {
      if (_isStarred) {
        await subsonicService.unstar(id: widget.song.id);
        setState(() {
          _isStarred = false;
        });
        if (mounted) {
          // 可逆操作带「撤销」（设计稿/08 §6）：撤销 = 重新收藏。
          showLuoboToast(
            context,
            message: l10n.removedFromLikedSongs,
            tone: LuoboToastTone.info,
          );
        }
      } else {
        await subsonicService.star(id: widget.song.id);
        setState(() {
          _isStarred = true;
        });
        if (mounted) {
          showLuoboToast(
            context,
            message: l10n.addedToLikedSongs,
            tone: LuoboToastTone.success,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        showLuoboToast(
          context,
          message: '${l10n.error}: ${e.toString()}',
          tone: LuoboToastTone.error,
        );
      }
    }
  }

  void _navigateToArtist(NavigatorState nav) {
    final participants = widget.song.artistParticipants;

    if (participants != null && participants.length > 1) {
      final ctx = NavigationHelper.navigatorKey.currentContext;
      if (ctx == null) return;
      showGlassBottomSheet(
        context: ctx,
        builder: (sheetCtx) => ArtistsBottomSheet(
          artists: participants,
          onArtistTap: (artist) {
            Navigator.pop(sheetCtx);
            _pushArtist(nav, artist);
          },
        ),
      );
      return;
    }

    final single = participants?.firstOrNull;
    if (single != null) {
      _pushArtist(nav, single);
      return;
    }

    final artistId = widget.song.artistId;
    if (artistId != null && artistId.isNotEmpty) {
      nav.push(
        MaterialPageRoute(builder: (_) => ArtistScreen(artistId: artistId)),
      );
    }
  }

  void _pushArtist(NavigatorState nav, ArtistRef artist) {
    if (artist.id.isNotEmpty) {
      nav.push(
        MaterialPageRoute(builder: (_) => ArtistScreen(artistId: artist.id)),
      );
    }
  }

  void _showPlaylistPicker(BuildContext context, Song song) {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final l10n = AppLocalizations.of(context)!;

    // 设计稿/08 §5（规格见 `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.3）：
    // 无标题 + 保留把手；「新建歌单」行置顶（玫红圆角方 + 白＋）；
    // 已有歌单显示封面缩略图 + 「N 首」；无歌单时显示空态（EmptyState）。
    // ⚠️ isScrollControlled + 可滚动：歌单多时防止列表被 50% 屏高裁掉。
    showLuoboSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LuoboSheetRow(
              leading: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: LuoboAccent.accent,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(AppIcons.plus, size: 16, color: Colors.white),
              ),
              title: l10n.newPlaylist,
              showChevron: false,
              onTap: () {
                Navigator.of(ctx).pop();
                showCreatePlaylistDialog(context);
              },
            ),
            if (libraryProvider.playlists.isEmpty)
              const LuoboEmptyState(
                message: '还没有歌单，先建一个吧~',
              )
            else
              ...libraryProvider.playlists.map(
                (playlist) => LuoboSheetRow(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: SizedBox(
                      width: 38,
                      height: 38,
                      child: playlist.coverArt != null
                          ? AlbumArtwork(
                              coverArt: playlist.coverArt,
                              size: 38,
                              borderRadius: 7,
                            )
                          : Container(
                              color: LuoboAccent.soft(0.12),
                              child: const Icon(
                                CupertinoIcons.music_note_list,
                                size: 18,
                                color: LuoboAccent.accent,
                              ),
                            ),
                    ),
                  ),
                  title: playlist.name,
                  subtitle: l10n.songsCount(playlist.songCount ?? 0),
                  showChevron: false,
                  onTap: () async {
                    // ⚠️ 修复（2026-10-22）：原实现把 `context`/`mounted` 指向
                    // **⋮ 菜单 State**——菜单已 pop 后该 State 销毁，
                    // Provider.of 抛错、`if (!mounted)` 恒真、toast 全静默，
                    // 表现为「添加到歌单没生效」。同步取 provider 用 picker 的
                    // ctx（还活着），弹提示用根导航 context。
                    final subsonicService = Provider.of<SubsonicService>(
                      ctx,
                      listen: false,
                    );
                    final navCtx = NavigationHelper.navigatorKey.currentContext;
                    Navigator.pop(ctx);

                    try {
                      await subsonicService.updatePlaylist(
                        playlistId: playlist.id,
                        songIdsToAdd: [song.id],
                      );
                      await libraryProvider.loadPlaylists();

                      // 轻提示（设计稿/08 §6）：可逆操作带「撤销」——刚加的歌
                      // 在歌单末尾（下标 = 添加前的 songCount），按 index 移除。
                      if (navCtx == null) return;
                      showLuoboToast(
                        navCtx,
                        message: l10n.addedToPlaylist(
                          song.title,
                          playlist.name,
                        ),
                        tone: LuoboToastTone.success,
                        // 撤销已移除（2026-10-22）：
                        // 服务端 songIndexToRemove 不一定支持 + 索引会因缓存错位；
                        // fnos 的对应 Toast 也只有状态提示，无撤销。
                      );
                    } catch (e) {
                      debugPrint('Error adding song to playlist: $e');
                      if (navCtx == null) return;
                      showLuoboToast(
                        navCtx,
                        message: l10n.errorAddingToPlaylist(e),
                        tone: LuoboToastTone.error,
                      );
                    }
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// ⋮ 菜单的上下文头（设计稿/09）：封面 46 r9 + 歌名 15/600 + 歌手 12（方案 §9）。
class _SongMenuHeader extends StatelessWidget {
  final Song song;
  final String? coverArt;

  const _SongMenuHeader({required this.song, this.coverArt});

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return Row(
      children: [
        AlbumArtwork(coverArt: coverArt, size: 46),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: LuoboType.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (song.artist != null) ...[
                const SizedBox(height: 3),
                Text(
                  song.artist!,
                  style: LuoboType.caption.copyWith(color: c.fg2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// 只读歌曲信息卡（设计稿/09；规格见
/// `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.8）：
/// 「歌曲信息」入口的落点——**无输入框、无保存按钮、无修改歌手/风格选择器**
/// （后端无写标签接口，编辑一律不做）。可滚动。
///
/// 内容：大封面 150 + 歌名/歌手 → 技术参数横排卡（码率/采样率/位深，
/// **有值才显示**，全无则整卡隐藏）→ 只读信息行（专辑/年份/曲目序号/风格/
/// 格式/文件位置，**字段缺省整行隐藏**）。
Future<void> showSongInfoSheet(BuildContext context, Song song) {
  final l10n = AppLocalizations.of(context)!;
  final coverArt = Provider.of<LibraryProvider>(context, listen: false)
      .effectiveCoverArt(song);

  // 技术参数：值有才显示（方案 §7⑦：声道数无解析，用位深列）。
  final params = <(String, String)>[
    if (song.bitRate != null && song.bitRate! > 0)
      ('${song.bitRate} kbps', l10n.paramBitrate),
    if (song.formattedSampleRate.isNotEmpty)
      (song.formattedSampleRate, l10n.paramSampleRate),
    if (song.bitDepth != null) ('${song.bitDepth} bit', l10n.paramBitDepth),
  ];

  // 只读信息行：缺省整行隐藏。
  final rows = <(String, String)>[
    if (song.album != null && song.album!.isNotEmpty)
      (l10n.albums, song.album!),
    if (song.year != null) (l10n.year, '${song.year}'),
    if (song.track != null) (l10n.trackNumber(song.track!), ''),
    if (song.genre != null && song.genre!.isNotEmpty)
      (l10n.genreLabel, song.genre!),
    if (song.suffix != null && song.suffix!.isNotEmpty)
      (l10n.format, song.suffix!.toUpperCase()),
    if (song.path != null && song.path!.isNotEmpty)
      (l10n.fileLocation, song.path!),
  ];

  return showLuoboSheet(
    context: context,
    title: l10n.songInfo,
    isScrollControlled: true,
    builder: (ctx) => SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: AlbumArtwork(
              coverArt: coverArt,
              size: 150,
              borderRadius: 14,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            song.title,
            textAlign: TextAlign.center,
            style: LuoboType.navTitle.copyWith(fontSize: 17),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (song.artist != null) ...[
            const SizedBox(height: 4),
            Text(
              song.artist!,
              textAlign: TextAlign.center,
              style: LuoboType.caption.copyWith(
                color: LuoboColors.of(ctx).fg2,
              ),
            ),
          ],
          if (params.isNotEmpty) ...[
            const SizedBox(height: 14),
            // 技术参数横排卡：整宽、高 64、3 列等分（方案 §9）。
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: LuoboColors.of(ctx).card,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  for (final (i, p) in params.indexed) ...[
                    if (i > 0)
                      Container(
                        width: 0.5,
                        height: 36,
                        color: LuoboColors.of(ctx).divider,
                      ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            p.$1,
                            style: LuoboType.body.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.$2,
                            style: LuoboType.caption.copyWith(
                              color: LuoboColors.of(ctx).fg2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: LuoboColors.of(ctx).card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: LuoboType.body.copyWith(
                        color: LuoboColors.of(ctx).fg2,
                      ),
                    ),
                    if (row.$2.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          row.$2,
                          textAlign: TextAlign.right,
                          style: LuoboType.body,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

/// 歌曲 `⋮` 菜单的公共入口（设计稿/09）：`SongTile` 与**播放页**共用，
/// 按 [menuContext] 裁剪变体。统一走 `showLuoboSheet`（把手 + 圆角 20 +
/// 遮罩 .42 + root navigator——遮罩盖住播放条/底栏，见 sheet_shell.dart 注释）。
void showSongMenuSheet(
  BuildContext context, {
  required Song song,
  SongMenuContext menuContext = SongMenuContext.list,
  VoidCallback? onRemoveFromPlaylist,
}) {
  showLuoboSheet(
    context: context,
    // ⚠️ 必须放开高度 + 可滚动：showModalBottomSheet 默认只给 50% 屏高，
    // 三段式内容（上下文头 + 横排 + 7 行 ≈ 600dp）会直接裁掉末行
    // （「歌曲信息」看不见）。原 _SongOptionsSheet 的 SingleChildScrollView
    // 在 P0 重写时丢了，此修复补回。
    isScrollControlled: true,
    builder: (context) => SingleChildScrollView(
      child: _SongOptionsSheet(
        song: song,
        menuContext: menuContext,
        onRemoveFromPlaylist: onRemoveFromPlaylist,
      ),
    ),
  );
}
