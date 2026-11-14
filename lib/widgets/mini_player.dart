import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide RepeatMode;
import 'package:provider/provider.dart';
import '../models/song.dart';
import '../models/radio_station.dart';
import '../providers/player_provider.dart';
import '../providers/library_provider.dart';
import '../services/player_ui_settings_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../theme/app_theme.dart';
import 'luobo/luobo_toast.dart';
import '../l10n/app_localizations.dart';
import '../utils/screen_helper.dart';
import '../services/transcoding_service.dart';
import 'album_artwork.dart';
import 'luobo/glass.dart';
import '../screens/now_playing_screen.dart';

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
        final colors = LuoboColors.of(context);

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
        //
        // 尺寸对齐飞牛（§6.3）：高 50dp、左右外边距 16dp、**圆角 = 高度/2 → 胶囊**。
        // 挂 `luoboToastAnchorKey`：`showLuoboToast`（轻提示）据此把
        // 提示条锚定在播放条上方（设计稿/08 §6）。
        return RepaintBoundary(
          key: luoboToastAnchorKey,
          child: Container(
            margin: const EdgeInsets.fromLTRB(
              LuoboGlass.barMarginX,
              4,
              LuoboGlass.barMarginX,
              0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(LuoboGlass.barRadius),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(LuoboGlass.barRadius),
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
                    height: LuoboGlass.barHeight,
                    decoration: BoxDecoration(
                      // 与底栏（`GlassPillNav`）共用同一套玻璃配方 —— 两者在同一条带里
                      // 互斥出现，深浅两态的 tint / 描边必须同源，否则切页会「变色」。
                      // 深色：浅色面纱渐变（飞牛深色胶囊比页面更亮，见 token 注释）。
                      color: isDark ? null : colors.glassTint,
                      gradient: isDark ? LuoboGlass.navTintDark : null,
                      borderRadius: BorderRadius.circular(LuoboGlass.barRadius),
                      border: Border.all(
                        color: isDark
                            ? LuoboGlass.navBorderDark
                            : colors.glassBorder,
                        width: LuoboGlass.borderWidth,
                      ),
                    ),
                    // ⚠️ 底部那条细进度线已删（§6.3）：条改成**胶囊**后贴底线会切过
                    // 全圆的端头；进度改画到**封面外圈**的细环上（见 `_BarArtwork`），
                    // 于是「对齐飞牛」与「二级页仍看得到进度」同时成立。
                    child: row,
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
              width: LuoboGlass.barArtSize,
              height: LuoboGlass.barArtSize,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF2D55), Color(0xFFFF6B35)],
                ),
                borderRadius: BorderRadius.circular(LuoboGlass.barArtRadius),
              ),
              child: const Icon(Icons.radio, color: Colors.white, size: 20),
            )
          else
            GestureDetector(
              onLongPress: () => _showTranscodeToast(context),
              child: _BarArtwork(coverArt: coverArt),
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

/// 播放条封面：**外圈进度环** + 贴封面的**转码描边**。
///
/// §6.2 的转码描边与 §6.3 的进度环都长在这个封面上 —— 合并成**一个** `CustomPaint`
/// 统一绘制，避免两层各自包 `RepaintBoundary` 互相覆盖，也省一次绘制。
///
/// 环**不贴封面**（与封面留 ~2dp 间隙，飞牛实测见 §6.1）；**暂停时环与进度冻结在原位**，
/// 不变暗、不隐藏（用户 2026-10-09 明确）。
class _BarArtwork extends StatelessWidget {
  const _BarArtwork({required this.coverArt});

  final String? coverArt;

  /// 外框总尺寸 = 封面 32 + 2×间隙 2 + 2×笔画 1.5 ≈ 39dp（§6.3 实测口径）。
  static const double _box =
      LuoboGlass.barArtSize + 2 * 2 + 2 * LuoboGlass.navArtRingWidth;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    return SizedBox(
      width: _box,
      height: _box,
      child: RepaintBoundary(
        child: CustomPaint(
          // ⚠️ 必须用 `foregroundPainter` 而不是 `painter`：
          // `painter` 画在 child **下面**，而「贴封面的转码描边」正好落在封面边缘
          // 内侧 —— 会被 32dp 的封面**整个盖住**（用户 2026-10-09 反馈
          // 「描边不是应该用转码/网络的颜色吗」，根因就是它压根没显示出来）。
          // 轨道环在封面**外面**，画在上面不受影响。
          foregroundPainter: _BarArtRingPainter(
            progress: context.select<PlayerProvider, double>((p) => p.progress),
            track: c.fg.withValues(alpha: LuoboGlass.ringTrackAlpha),
            fill: c.fg.withValues(alpha: LuoboGlass.ringProgressAlpha),
            artBorder: artworkBorderColor(context),
          ),
          child: Center(
            child: AlbumArtwork(
              coverArt: coverArt,
              size: LuoboGlass.barArtSize,
              borderRadius: LuoboGlass.barArtRadius,
            ),
          ),
        ),
      ),
    );
  }
}

/// 一次画完两件事：**外圈进度环**（灰轨道 + 深一档的填充）与**贴封面的转码描边**。
class _BarArtRingPainter extends CustomPainter {
  const _BarArtRingPainter({
    required this.progress,
    required this.track,
    required this.fill,
    required this.artBorder,
  });

  final double progress;
  final Color track;
  final Color fill;
  final Color artBorder;

  @override
  void paint(Canvas canvas, Size size) {
    const w = LuoboGlass.navArtRingWidth;
    const art = LuoboGlass.barArtSize;
    const artR = LuoboGlass.barArtRadius;
    const ringR = artR + 2;

    // ── 外圈进度环：与封面同形（圆角矩形），且**不贴封面** ──
    final ringRect = Rect.fromLTWH(
      w / 2,
      w / 2,
      size.width - w,
      size.height - w,
    );
    final ringPath = Path()
      ..addRRect(RRect.fromRectAndRadius(ringRect, const Radius.circular(ringR)));

    canvas.drawPath(
      ringPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = track,
    );

    final p = progress.clamp(0.0, 1.0);
    if (p > 0) {
      // ⚠️ **不能**对圆角矩形用 `drawArc` —— 那画出来的是**内切圆/椭圆**，
      // 会与圆角矩形的轨道错开，观感就是「进度描边是圆的、封面是方的」
      // （用户 2026-10-09 反馈）。改为沿轨道**路径**取一段长度。
      //
      // `RRect` 的路径起点在「上边、左上圆角结束处」，所以要先跳过
      // 「起点 → 上边中点」这一段，进度才是从 12 点起笔。
      // 该段长度 = 上边长的一半 = `ringRect.width / 2 - 圆角半径`
      // （**不是**绝对坐标 —— `extractPath` 的偏移是相对路径起点的）。
      _drawPathSegment(
        canvas,
        ringPath,
        p,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round
          ..color = fill,
        startOffset: ringRect.width / 2 - ringR,
      );
    }

    // ── 贴封面的转码描边 ──
    final artRect = Rect.fromLTWH(
      (size.width - art) / 2,
      (size.height - art) / 2,
      art,
      art,
    ).deflate(w / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(artRect, const Radius.circular(artR)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..color = artBorder,
    );
  }

  /// 沿 [path] 从 `startOffset` 处起笔、顺时针取 [fraction] 比例画出来（会绕回起点）。
  static void _drawPathSegment(
    Canvas canvas,
    Path path,
    double fraction,
    Paint paint, {
    required double startOffset,
  }) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final total = metric.length;
    if (total <= 0) return;

    final target = total * fraction;
    var drawn = 0.0;
    var cursor = startOffset % total;
    while (drawn < target) {
      final seg = math.min(target - drawn, total - cursor);
      if (seg <= 0) break;
      canvas.drawPath(metric.extractPath(cursor, cursor + seg), paint);
      drawn += seg;
      cursor = 0;
    }
  }

  @override
  bool shouldRepaint(_BarArtRingPainter old) =>
      old.progress != progress ||
      old.track != track ||
      old.fill != fill ||
      old.artBorder != artBorder;
}

class _MiniPlayerControls extends StatelessWidget {
  final bool isRadio;

  const _MiniPlayerControls({this.isRadio = false});

  /// 最右「歌曲列表」→ 播放队列浮层。
  ///
  /// 用播放条自己的 context 弹：播放条挂在 `Scaffold.bottomNavigationBar` 上，
  /// 它与 body 里的嵌套 Navigator 是**兄弟**子树 → 最近的 Navigator 就是根 Navigator，
  /// 遮罩会盖住条带本身（这正是期望行为）。
  void _openQueue(BuildContext context) => showQueueSheet(context);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : Colors.black;

    return Selector<PlayerProvider, (bool, bool, bool)>(
      selector: (_, p) => (p.isPlaying, p.isPlayingAudiobook, p.isRoamingQueue),
      builder: (context, data, _) {
        final (isPlaying, isAudiobook, isRoaming) = data;
        final provider = context.read<PlayerProvider>();
        final playerUiSettings = PlayerUiSettingsService();

        return ValueListenableBuilder<bool>(
          valueListenable: playerUiSettings.showMiniPlayerHeartNotifier,
          builder: (context, showHeart, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 有声书（B8/B10）：隐藏收藏（章节无收藏语义）。
                if (showHeart && !isRadio && !isAudiobook)
                  Selector<PlayerProvider, bool>(
                    selector: (_, p) => p.currentSong?.starred == true,
                    builder: (context, isStarred, _) {
                      return IconButton(
                        onPressed: provider.toggleFavorite,
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 34, minHeight: 34),
                        icon: Icon(
                          isStarred
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: ScreenHelper.miniPlayerIconSize(context),
                        ),
                        color: isStarred ? AppTheme.appleMusicRed : color,
                      );
                    },
                  ),

                IconButton(
                  onPressed: provider.togglePlayPause,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: ScreenHelper.miniPlayerPlayIconSize(context),
                  ),
                  color: color,
                ),

                // 最右（对齐飞牛）：漫游中是**漫游标识**、不可点；
                // 其余情况是「歌曲列表」，点开播放队列浮层。
                //
                // ⚠️ 播放条**不再放「下一首」**（用户 2026-10-23）：省下的
                // 宽度全给歌名，切歌走播放页 / 队列。
                if (!isRadio && isRoaming)
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      AppIcons.roam,
                      size: ScreenHelper.miniPlayerIconSize(context),
                      color: color,
                    ),
                  ),
                if (!isRadio && !isRoaming)
                  IconButton(
                    onPressed: () => _openQueue(context),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 34, minHeight: 34),
                    icon: Icon(
                      AppIcons.viewList,
                      size: ScreenHelper.miniPlayerIconSize(context),
                    ),
                    color: color,
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// 「当前流**已转码**」。与 [isStreamTranscoding] 一起构成转码判定，
/// **描边与长按浮层共用**，不写第二份（§6.2）。
bool _isStreamTranscoded(BuildContext context) => Provider.of<PlayerProvider>(
  context,
  listen: false,
).isActiveStreamTranscoded;

/// 「当前流**正在**转码」。
bool _isStreamTranscoding(BuildContext context) =>
    Provider.of<TranscodingService>(
      context,
      listen: false,
    ).getCurrentBitrate() !=
    null;

/// 播放条封面的**转码**描边色（§6.2）。
///
/// ⚠️ 原为**网络**维度（LAN 绿 / WAN 橙，且是硬编码 Material 的
/// `green600` / `orange700`）—— 用户 2026-10-09 反馈「一橙一绿不协调」，改为
/// **转码**维度：非转码 = 玫红 [LuoboAccent.accent]，转码 = 橙 [LuoboAccent.warnFor]。
/// 色值复用 `docs/设置页重构技术方案.md` §9.2.1 的已定表。
///
/// 为什么协调：玫红 + 橙是**相邻暖色**（≈350° / 30°），玫红是品牌色（底栏选中气泡、
/// 封面进度环用的都是它），橙**只在转码时出现** → 常态安静、异常才跳。
Color artworkBorderColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return (_isStreamTranscoded(context) || _isStreamTranscoding(context))
      ? LuoboAccent.warnFor(isDark)
      : LuoboAccent.accent;
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
  // 判定复用 [_isStreamTranscoded] / [_isStreamTranscoding]，与封面描边**同一份**（§6.2）。
  if (_isStreamTranscoded(context)) {
    statusLabel = l10n.transcodedToNoNetwork(
      TranscodeFormat.getLabel(player.activeStreamFormat ?? ''),
      player.activeStreamBitrate ?? 0,
    );
    statusColor = LuoboAccent.warnFor(isDark);
  } else if (_isStreamTranscoding(context)) {
    statusLabel = l10n.transcodingInProgress(
      TranscodeFormat.getLabel(transcoding.getCurrentFormat() ?? ''),
      transcoding.getCurrentBitrate() ?? 0,
    );
    statusColor = LuoboAccent.warnFor(isDark);
  } else {
    statusLabel = l10n.noTranscoding;
    // 与描边的「非转码」同一色（§9.2.1 的「不转码 = 强调色」），
    // 不用 `colorScheme.primary` —— 那是用户自选强调色，会与描边/底栏的固定玫红打架。
    statusColor = LuoboAccent.accent;
  }

  // 居中弹出（2026-10-24 用户改回；原为锚定在播放条封面上，见 §6.2）。
  // 插入 root overlay 以浮在所有页面之上；重触发时替换而不是叠加。
  final overlay = Overlay.of(context, rootOverlay: true);

  _transcodeToastEntry?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      final card = _TranscodeToast(
        title: song.title,
        fileInfo: fileInfo,
        sampleInfo: sampleInfo,
        depthInfo: depthInfo,
        statusLabel: statusLabel,
        statusColor: statusColor,
        network: network,
        networkIcon: isWifi ? Icons.wifi_rounded : Icons.signal_cellular_alt,
        networkColor: isWifi ? LuoboAccent.wifi : LuoboAccent.cell,
        onDismiss: () {
          if (_transcodeToastEntry == entry) _transcodeToastEntry = null;
          if (entry.mounted) entry.remove();
        },
      );

      // 屏幕正中（用户 2026-10-24 要求；不再贴播放条）。
      return Align(alignment: Alignment.center, child: card);
    },
  );
  _transcodeToastEntry = entry;
  overlay.insert(entry);
}

/// 长按播放条封面弹出的**转码信息卡**（§6.2）。
///
/// 材质用 [LuoboGlassSurface]（毛玻璃 + 圆角 20），与迷你播放条**同属玻璃材质**；
/// 定位由调用方**放在屏幕正中**（用户 2026-10-24 要求，原为锚定在封面上）。
/// 淡入 + 轻微上移，出场反向；~2s 后自动消失，点卡片可提前关。
/// 卡片自身是唯一的可点区域，四周的点击穿透到下层 UI。
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
    final c = LuoboColors.of(context);
    final sampleInfo = widget.sampleInfo;
    final depthInfo = widget.depthInfo;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: LuoboMotion.enter,
      reverseCurve: LuoboMotion.exit,
    );
    return FadeTransition(
      opacity: curved,
      // **淡入 + 轻微上移**，出场反向（§6.2）。
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: GestureDetector(
          onTap: () {
            _controller.reverse().whenComplete(() {
              if (mounted) _dismiss();
            });
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            // ⚠️ 原为 `Material` + `colorScheme.inverseSurface` 的居中深色条
            // （SnackBar 配方、圆角 4）—— 与设计体系（白卡/毛玻璃 + 圆角 14/20 +
            // 玫红点睛）完全不是一回事。
            // 现改为玻璃卡，**材质与迷你播放条同一套配方**（用户 2026-10-24 要求）：
            // blur 12（`blurBar`，省 GPU）+ 深色浅色面纱渐变 `navTintDark` +
            // 深色描边 `navBorderDark` + 同一条投影 —— 三者与 `MiniPlayer.build`
            // 里那条胶囊逐项对齐；差别只在圆角（卡片 groupR 20，不跟着做胶囊）。
            // ⚠️ 必须包一层 `Material`（透明）：本卡挂在 **root overlay** 上，
            // 祖先里没有 `Material` —— 不包的话里面的 `Text` 会落到 Flutter 的
            // 「无样式文本」调试样式（**黄字 + 双下划线**）。
            // 文档 §9.17 已记过这条教训：「写卡片容器一律用 `Material` 作卡体」。
            child: Material(
              type: MaterialType.transparency,
              child: LuoboGlassSurface(
                borderRadius: LuoboRadius.groupR,
                blur: LuoboGlass.blurBar,
                tintGradient: c.isDark ? LuoboGlass.navTintDark : null,
                borderColor: c.isDark ? LuoboGlass.navBorderDark : null,
                shadows: const [
                  BoxShadow(
                    color: Color(0x2E000000), // black .18，同播放条
                    blurRadius: 24,
                    offset: Offset(0, 6),
                  ),
                ],
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: LuoboType.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: c.fg,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.fileInfo.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.fileInfo,
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                    ],
                    if (sampleInfo.isNotEmpty || depthInfo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [sampleInfo, depthInfo]
                            .where((s) => s.isNotEmpty)
                            .join(' · '),
                        style: LuoboType.caption.copyWith(color: c.fg2),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(
                          widget.networkIcon,
                          size: 14,
                          color: widget.networkColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.network,
                          style: LuoboType.caption.copyWith(color: c.fg2),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.statusLabel,
                            style: LuoboType.caption.copyWith(
                              color: widget.statusColor,
                              fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
