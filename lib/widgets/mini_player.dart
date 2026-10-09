import 'dart:io';
import 'dart:ui';
import 'package:flutter/cupertino.dart' hide RepeatMode;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/player_ui_settings_service.dart';
import '../theme/design_tokens.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../utils/screen_helper.dart';
import '../services/subsonic_service.dart';
import '../services/transcoding_service.dart';
import 'album_artwork.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onTap;

  const MiniPlayer({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDesktop =
        !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
    if (isDesktop) return const SizedBox.shrink();

    return Selector<PlayerProvider, (Song?, RadioStation?, bool)>(
      selector: (_, p) =>
          (p.currentSong, p.currentRadioStation, p.isPlayingRadio),
      builder: (context, data, _) {
        final (currentSong, currentRadioStation, isPlayingRadio) = data;

        if (currentSong == null && !isPlayingRadio) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        final String title;
        final String? subtitle;
        final String? coverArt;

        if (isPlayingRadio && currentRadioStation != null) {
          title = currentRadioStation.name;
          subtitle = AppLocalizations.of(context)!.internetRadioLive;
          coverArt = null;
        } else if (currentSong != null) {
          title = currentSong.title;
          subtitle = currentSong.artistParticipants != null &&
                  currentSong.artistParticipants!.isNotEmpty
              ? currentSong.artistParticipants!.map((a) => a.name).join(', ')
              : currentSong.artist;
          // Normalize to the album cover (same key as song list tiles) so the
          // mini bar hits the same cache entry the list already filled.
          coverArt = Provider.of<LibraryProvider>(context, listen: false)
              .effectiveCoverArt(currentSong);
        } else {
          return const SizedBox.shrink();
        }

        final Widget row = _MiniPlayerRow(
          title: title,
          subtitle: subtitle,
          coverArt: coverArt,
          isPlayingRadio: isPlayingRadio,
        );

        // 玻璃样式固定（`liquidGlass` 用户开关已删除，方案 §7 ⑭）。
        // 迷你播放条属于**小面积固定元素**，允许毛玻璃；sigma 取 12 而非 24
        // 是为省 GPU —— 这条每帧都在渲染。
        return RepaintBoundary(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: LuoboGlass.blurBar,
                  sigmaY: LuoboGlass.blurBar,
                ),
                child: GestureDetector(
                  onTap: onTap,
                  child: Container(
                    // 显式撑满：父级 Column 默认 crossAxisAlignment.center，传下来的
                    // 是松宽度约束（同 SettingsSubPage 踩过的坑）。这里原本靠
                    // `_MiniPlayerRow` 内部的 Row 撑开，写明确更稳。
                    width: double.infinity,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.45)
                          : Colors.white.withValues(alpha: 0.62),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.14)
                            : Colors.white.withValues(alpha: 0.85),
                        width: 0.8,
                      ),
                    ),
                    child: Stack(
                      children: [
                        row,
                        // 底部细进度线。
                        // ⚠️ 原来默认（非玻璃）分支里有一条 LinearProgressIndicator
                        // 显示播放进度，随「删 liquidGlass 用户开关」一并被删掉了 ——
                        // 迷你条上没有进度，就等于「不点开播放页不知道听到哪了」。
                        // 只包一层 Selector，避免整条播放条跟着进度每帧重建。
                        Positioned(
                          left: 14,
                          right: 14,
                          bottom: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(1.5),
                            child: SizedBox(
                              height: 2.5,
                              child: Selector<PlayerProvider, double>(
                                selector: (_, p) => p.progress,
                                builder: (_, progress, __) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ColoredBox(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.18)
                                          : Colors.black.withValues(
                                              alpha: 0.10,
                                            ),
                                    ),
                                    FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: const ColoredBox(
                                        color: LuoboAccent.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Cached adaptive font sizes for the mini player title, keyed by
/// `title|width`, so the row doesn't re-measure on every rebuild.
final Map<String, double> _titleSizeCache = {};

/// Measures a single-line text width at the given font size.
double _textWidth(String text, TextStyle base, double fontSize) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: base.copyWith(fontSize: fontSize)),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  )..layout();
  return painter.width;
}

class _MiniPlayerRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? coverArt;
  final bool isPlayingRadio;

  const _MiniPlayerRow({
    required this.title,
    required this.subtitle,
    required this.coverArt,
    required this.isPlayingRadio,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (isPlayingRadio)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 24),
            )
          else
            GestureDetector(
              onLongPress: () => _showTranscodeToast(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _networkBorderColor(context),
                    width: 1.5,
                  ),
                ),
                child: AlbumArtwork(
                  coverArt: coverArt,
                  size: 44,
                  borderRadius: 6,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title shrinks down to 12px so longer titles stay fully
                // visible; only extreme lengths fall back to ellipsis.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final baseStyle = theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ) ??
                        const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600);
                    final baseSize = baseStyle.fontSize ?? 16;
                    // Cache the computed font size per (title, width) so the
                    // mini player doesn't re-measure on every rebuild.
                    final cacheKey = '$title|${constraints.maxWidth.round()}';
                    final cached = _titleSizeCache[cacheKey];
                    final double size;
                    if (cached != null) {
                      size = cached;
                    } else {
                      var s = baseSize;
                      while (s > 12 &&
                          _textWidth(title, baseStyle, s) >
                              constraints.maxWidth) {
                        s -= 1;
                      }
                      if (_titleSizeCache.length > 500) {
                        _titleSizeCache.clear();
                      }
                      _titleSizeCache[cacheKey] = s;
                      size = s;
                    }
                    return Text(
                      title,
                      style: baseStyle.copyWith(fontSize: size),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    );
                  },
                ),
                if (subtitle != null)
                  Row(
                    children: [
                      if (isPlayingRadio) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      Expanded(
                        child: Text(
                          isPlayingRadio
                              ? AppLocalizations.of(context)!.internetRadio
                              : subtitle!,
                          style: theme.textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          _MiniPlayerControls(isRadio: isPlayingRadio),
        ],
      ),
    );
  }
}

class _MiniPlayerControls extends StatelessWidget {
  final bool isRadio;

  const _MiniPlayerControls({this.isRadio = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Selector<PlayerProvider, (bool, bool, bool)>(
      selector: (_, p) => (p.isPlaying, p.hasNext, p.isPlayingAudiobook),
      builder: (context, data, _) {
        final (isPlaying, hasNext, isAudiobook) = data;
        final provider = context.read<PlayerProvider>();
        final playerUiSettings = PlayerUiSettingsService();

        return ValueListenableBuilder<bool>(
          valueListenable: playerUiSettings.showMiniPlayerHeartNotifier,
          builder: (context, showHeart, _) {
            return ValueListenableBuilder<bool>(
              valueListenable: playerUiSettings.showMiniPlayerRepeatNotifier,
              builder: (context, showRepeat, _) {
                return ValueListenableBuilder<bool>(
                  valueListenable:
                      playerUiSettings.showMiniPlayerShuffleNotifier,
                  builder: (context, showShuffle, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 有声书（B8/B10）：隐藏收藏/shuffle/repeat（章节无收藏语义、
                        // 强制顺序播放）。
                        if (showHeart && !isRadio && !isAudiobook)
                          Selector<PlayerProvider, bool>(
                            selector: (_, p) => p.currentSong?.starred == true,
                            builder: (context, isStarred, _) {
                              return IconButton(
                                onPressed: provider.toggleFavorite,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  isStarred
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  size:
                                      ScreenHelper.miniPlayerIconSize(context),
                                ),
                                color:
                                    isStarred ? AppTheme.appleMusicRed : color,
                              );
                            },
                          ),

                        if (showShuffle && !isRadio && !isAudiobook)
                          Selector<PlayerProvider, bool>(
                            selector: (_, p) => p.shuffleEnabled,
                            builder: (context, shuffleEnabled, _) {
                              return IconButton(
                                onPressed: provider.toggleShuffle,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(
                                  CupertinoIcons.shuffle,
                                  size:
                                      ScreenHelper.miniPlayerIconSize(context),
                                ),
                                color: shuffleEnabled
                                    ? Theme.of(context).colorScheme.primary
                                    : color,
                              );
                            },
                          ),

                        IconButton(
                          onPressed: provider.togglePlayPause,
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 40, minHeight: 40),
                          icon: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: ScreenHelper.miniPlayerPlayIconSize(context),
                          ),
                          color: color,
                        ),

                        if (showRepeat && !isRadio && !isAudiobook)
                          Selector<PlayerProvider, RepeatMode>(
                            selector: (_, p) => p.repeatMode,
                            builder: (context, repeatMode, _) {
                              IconData icon;
                              bool active = repeatMode != RepeatMode.off;
                              if (repeatMode == RepeatMode.one) {
                                icon = CupertinoIcons.repeat_1;
                              } else {
                                icon = CupertinoIcons.repeat;
                              }
                              return IconButton(
                                onPressed: provider.toggleRepeat,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 36, minHeight: 36),
                                icon: Icon(icon,
                                    size: ScreenHelper.miniPlayerIconSize(
                                        context)),
                                color: active
                                    ? Theme.of(context).colorScheme.primary
                                    : color,
                              );
                            },
                          ),

                        if (!isRadio)
                          IconButton(
                            onPressed: hasNext ? provider.skipNext : null,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                                minWidth: 36, minHeight: 36),
                            icon: Icon(Icons.skip_next_rounded,
                                size: ScreenHelper.miniPlayerSkipIconSize(
                                    context)),
                            color: color,
                          ),
                      ],
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
}

/// Semi-transparent border color for the mini player artwork showing
/// whether the server connection is local (Wi‑Fi / LAN, green) or remote
/// (WAN, orange). Deliberately subtle so it doesn't steal attention.
Color _networkBorderColor(BuildContext context) {
  final isLan =
      Provider.of<SubsonicService>(context, listen: false).isUsingLocalUrl;
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isLan
      ? (isDark ? const Color(0x804CAF50) : const Color(0x4D43A047))
      : (isDark ? const Color(0x80FB8C00) : const Color(0x4DFB8C00));
}

/// Currently visible transcode toast (replaced on re-trigger so repeated
/// long-presses don't stack toasts).
OverlayEntry? _transcodeToastEntry;

/// Non-blocking toast shown when long-pressing the mini player artwork: the
/// current song's original file info plus the actual transcode state of the
/// stream being played (settings-implied when transcoding is enabled but the
/// stream isn't transcoded yet). Fades in, stays ~2s, then fades out; taps
/// outside the card fall through to the UI underneath (tapping the card
/// itself dismisses it early).
void _showTranscodeToast(BuildContext context) {
  final player = Provider.of<PlayerProvider>(context, listen: false);
  final song = player.currentSong;
  if (song == null) return;

  final transcoding = Provider.of<TranscodingService>(context, listen: false);
  final theme = Theme.of(context);
  final l10n = AppLocalizations.of(context)!;

  // Original file info.
  final fileParts = <String>[];
  final format = song.suffix?.toUpperCase() ?? '';
  if (format.isNotEmpty) fileParts.add(format);
  if (song.bitRate != null && song.bitRate! > 0) {
    fileParts.add('${song.bitRate} kbps');
  }
  if (song.formattedSize.isNotEmpty) fileParts.add(song.formattedSize);
  final fileInfo = fileParts.join(' · ');
  final sampleInfo = song.formattedSampleRate;
  final depthInfo = song.bitDepth != null ? '${song.bitDepth} bit' : '';

  // Transcode status — actual for the current stream, settings-implied
  // otherwise. Network type is shown as a leading icon + label group.
  //
  // ⚠️ 与 `utils/connection_status.dart`（账号卡用的短形态）**故意不合并**：
  // 这里问的是「**当前流**转没转码」，而 song_tile 的 `_QualityInfo` 问的是
  // 「**这首歌**（可能不是当前曲目）会怎样」—— 两个不同的问题，硬合会丢语义。
  // 三处共享的只有**橙色深浅档**，那部分已收敛到 `LuoboAccent.warnFor`。
  final isDark = theme.brightness == Brightness.dark;
  // 网络信息前置成组（图标 + 文字），状态描述在后，避免行尾孤立图标。
  final isWifi = transcoding.currentConnectionType == ConnectionType.wifi;
  final network = isWifi ? l10n.networkWifi : l10n.networkMobile;
  final String statusLabel;
  final Color statusColor;
  if (player.isActiveStreamTranscoded) {
    statusLabel = l10n.transcodedToNoNetwork(
      TranscodeFormat.getLabel(player.activeStreamFormat ?? ''),
      player.activeStreamBitrate ?? 0,
    );
    statusColor = LuoboAccent.warnFor(isDark);
  } else if (transcoding.getCurrentBitrate() != null) {
    statusLabel = l10n.transcodingInProgress(
      TranscodeFormat.getLabel(transcoding.getCurrentFormat() ?? ''),
      transcoding.getCurrentBitrate() ?? 0,
    );
    statusColor = LuoboAccent.warnFor(isDark);
  } else {
    statusLabel = l10n.noTranscoding;
    statusColor = theme.colorScheme.primary;
  }

  // Insert into the root overlay so the toast floats above every screen, and
  // keep a reference to replace it on re-trigger instead of stacking.
  _transcodeToastEntry?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) => Center(
      child: _TranscodeToast(
        title: song.title,
        fileInfo: fileInfo,
        sampleInfo: sampleInfo,
        depthInfo: depthInfo,
        statusLabel: statusLabel,
        statusColor: statusColor,
        network: network,
        networkIcon: isWifi ? Icons.wifi_rounded : Icons.signal_cellular_alt,
        networkColor: isWifi ? Colors.green : Colors.orange,
        onDismiss: () {
          if (_transcodeToastEntry == entry) _transcodeToastEntry = null;
          if (entry.mounted) entry.remove();
        },
      ),
    ),
  );
  _transcodeToastEntry = entry;
  Overlay.of(context, rootOverlay: true).insert(entry);
}

/// Auto-dismissing toast card rendered in the screen center, styled like the
/// app's centered SnackBar toasts (inverseSurface + rounded bar). Fades in on
/// insertion and fades out before removal. The card itself is the only
/// tappable area (tapping it dismisses early); everything around it passes
/// through to the UI underneath.
class _TranscodeToast extends StatefulWidget {
  final String title;
  final String fileInfo;
  final String sampleInfo;
  final String depthInfo;
  final String statusLabel;
  final Color statusColor;
  final String network;
  final IconData networkIcon;
  final Color networkColor;
  final VoidCallback onDismiss;

  const _TranscodeToast({
    required this.title,
    required this.fileInfo,
    required this.sampleInfo,
    required this.depthInfo,
    required this.statusLabel,
    required this.statusColor,
    required this.network,
    required this.networkIcon,
    required this.networkColor,
    required this.onDismiss,
  });

  @override
  State<_TranscodeToast> createState() => _TranscodeToastState();
}

class _TranscodeToastState extends State<_TranscodeToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 180),
  );

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    Future<void>.delayed(const Duration(seconds: 2), () async {
      if (!mounted) return;
      await _controller.reverse();
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sampleInfo = widget.sampleInfo;
    final depthInfo = widget.depthInfo;
    return FadeTransition(
      opacity: _controller,
      child: GestureDetector(
        onTap: () {
          _controller.reverse().whenComplete(() {
            if (mounted) _dismiss();
          });
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Material(
            // SnackBar 观感：inverseSurface 深色圆角条，与刷新提示
            // （refresh_feedback.dart 的居中 SnackBar）视觉统一。
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            color: theme.colorScheme.inverseSurface,
            elevation: 6,
            shadowColor: Colors.black.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onInverseSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.fileInfo.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.fileInfo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onInverseSurface,
                      ),
                    ),
                  ],
                  if (sampleInfo.isNotEmpty || depthInfo.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      [sampleInfo, depthInfo]
                          .where((s) => s.isNotEmpty)
                          .join(' · '),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onInverseSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        widget.networkIcon,
                        size: 16,
                        color: widget.networkColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.network,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onInverseSurface.withValues(
                            alpha: 0.7,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.statusLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: widget.statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
