import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fluid_mesh_background/fluid_mesh_background.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../providers/player_provider.dart';
import '../services/diagnostics/diagnostics.dart';
import '../theme/app_theme.dart';
import '../utils/image_cache.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/widgets.dart';

/// 通用歌曲列表页：首页「每日推荐 / 场景 Mix / 你的最爱 / 探索发现」详情页。
///
/// 布局（多轮反馈收敛）：
/// - 顶部 hero（约屏高 38%）：背景为**封面取色的流沙流体场**（2026-09-23 由
///   「封面取色红→紫红渐变」改来）；内容仅一句随机 slogan，放在接近底部位置
///   （大标题去掉，导航栏 34pt 标题承担列表名）
/// - 三键（随机播放 / 播放 / 加入当前播放列表）紧跟 hero 下方
/// - 歌曲列表一体滚动；背景默认主题
///
/// 流体细节见 `docs/流沙流体背景技术文档.md`，本页接入决策见
/// `docs/首页重构技术方案.md` §5.9。
class SongListScreen extends StatefulWidget {
  final String title;
  final List<Song> songs;

  /// 候选 slogan 组（每次进入随机展示一句）。
  final List<String> slogans;

  /// 首歌封面图片 URL，作为 hero 流沙流体的取色源。
  final String? imageUrl;

  const SongListScreen({
    super.key,
    required this.title,
    required this.songs,
    this.slogans = const [],
    this.imageUrl,
  });

  @override
  State<SongListScreen> createState() => _SongListScreenState();
}

class _SongListScreenState extends State<SongListScreen> {
  String? _slogan;

  /// 流沙流体的 4 个取色（来自 [FluidPalette]，与 `FluidBackground` 内部同一份
  /// 缓存），用于派生折叠态导航栏底色。
  List<Color>? _meshColors;

  /// 折叠态导航栏底色的亮度上限：超过则回退品牌紫，保证白色标题可读
  /// （纯白封面等）。
  static const double _maxBarLuminance = 0.5;

  /// 折叠态导航栏底色的暗化量：≈ 原「vibrant 暗化 45% → 再暗化 20%」。
  static const double _barDarken = 0.56;

  bool _modeRecorded = false;

  double get _heroHeight => MediaQuery.of(context).size.height * 0.38;

  /// 流体取色源：复用 App 封面磁盘/内存缓存，**不为取色额外下载**。
  ImageProvider? get _coverProvider {
    final url = widget.imageUrl;
    if (url == null || url.isEmpty) return null;
    return CachedNetworkImageProvider(
      url,
      cacheManager: coverCacheManager,
      cacheKey: coverArtCacheKeyFromUrl(url),
    );
  }

  @override
  void initState() {
    super.initState();
    // 每次进入页面随机选一句 slogan。
    if (widget.slogans.isNotEmpty) {
      _slogan = widget.slogans[Random().nextInt(widget.slogans.length)];
    }
    _resolveMeshColors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _recordModeOnce();
  }

  @override
  void didUpdateWidget(covariant SongListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolveMeshColors();
    }
  }

  /// 命中 [FluidPalette] 缓存则同步上色（首帧即正确），否则异步取色。
  Future<void> _resolveMeshColors() async {
    final url = widget.imageUrl;
    final provider = _coverProvider;
    final cached = FluidPalette.instance.cached(FluidPalette.keyFor(provider));
    if (cached != null) {
      if (mounted) setState(() => _meshColors = cached);
      return;
    }
    final colors = await FluidPalette.instance.colorsFor(provider);
    // 取色期间封面源可能已变（复用本 State 的场合）。
    if (!mounted || url != widget.imageUrl) return;
    setState(() => _meshColors = colors);
  }

  /// 折叠后导航栏底色（流体在 `parallax` 折叠模式下会淡出，故须纯色兜底）。
  Color get _collapsedBarColor {
    final base = _meshColors?.first;
    if (base == null || base.computeLuminance() > _maxBarLuminance) {
      return const Color(0xFFA02E8C);
    }
    return Color.lerp(base, Colors.black, _barDarken)!;
  }

  /// 记录本页 hero 用了流体背景（把 `frame.jank` 归属到实际渲染路径）。
  ///
  /// 放到帧后，确保 route observer 已写入当前路由。
  void _recordModeOnce() {
    if (_modeRecorded) return;
    _modeRecorded = true;
    final hasCover = widget.imageUrl?.isNotEmpty ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      DiagnosticsService.instance.record(
        EventType.animActive,
        LogLevel.info,
        {
          'anim': 'songListHeroFluidBackground',
          'songs': widget.songs.length,
          'cover': hasCover,
          'clock': 'monotonic',
        },
      );
    });
  }

  void _playAll() {
    if (widget.songs.isEmpty) return;
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      widget.songs.first,
      playlist: widget.songs,
      startIndex: 0,
    );
  }

  void _playShuffle() {
    if (widget.songs.isEmpty) return;
    final shuffled = [...widget.songs]..shuffle();
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      shuffled.first,
      playlist: shuffled,
      startIndex: 0,
    );
  }

  void _addToQueue() {
    if (widget.songs.isEmpty) return;
    Provider.of<PlayerProvider>(context, listen: false)
        .addAllToQueue(widget.songs);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.addedToQueue),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: _heroHeight,
            // 折叠后与 hero 底部同调（流体随 parallax 折叠淡出，露出此底色）。
            backgroundColor: _collapsedBarColor,
            foregroundColor: Colors.white,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面取色的流沙流体场（`fluid_mesh_background` 包）。单实例：
                  // 自建时钟即可，被其他路由完全覆盖时由 ModalRoute 关 TickerMode。
                  // **不传 showScrim**：模块那层整幅 0.42→0.70 暗化会把空间对比度
                  // 砍掉约 55%（离屏实测 0.113 → 0.051），流动感几乎被抹平；改用
                  // 下面的分区遮罩，只暗化真正压字的两块。
                  FluidBackground(imageProvider: _coverProvider),
                  const _HeroScrim(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 30),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Text(
                        _slogan ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildHeaderButtons(context, l10n)),
          if (widget.songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  l10n.noContentAvailable,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: widget.songs.length,
              itemBuilder: (context, index) {
                final song = widget.songs[index];
                return SongTile(
                  song: song,
                  playlist: widget.songs,
                  index: index,
                  showArtist: true,
                );
              },
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  /// Apple Music 式三键：左随机 / 中播放 / 右加入当前播放列表（跟随滚动）。
  Widget _buildHeaderButtons(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: _SideAction(
              icon: Icons.shuffle_rounded,
              label: l10n.shuffle,
              onTap: _playShuffle,
            ),
          ),
          _PlayCircle(onTap: _playAll),
          Expanded(
            child: _SideAction(
              icon: Icons.playlist_add_rounded,
              label: l10n.addToCurrentQueue,
              onTap: _addToQueue,
            ),
          ),
        ],
      ),
    );
  }
}

/// hero 的**分区**遮罩：只暗化顶部（34pt 标题所在）与底部（slogan 所在）两块，
/// **中段完全不加**。
///
/// 为什么不用模块自带的 `showScrim`：它是整幅 0.42→0.70 的线性暗化，会把整页
/// 空间对比度砍掉约 55%（离屏实测 0.113 → 0.051）。而「看得出在流动」靠的正是
/// 对比度——流动量本身并不小（hero 5s 像素变化 75.6%，还高于卡片的 62.6%）。
/// 整幅暗化等于让中段白挨一刀。
class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  /// 顶部暗化块占 hero 的高度比例。
  ///
  /// 0.58 而非更小：导航栏标题 + 状态栏实测占到屏高约 35%，且渐变必须**在压字
  /// 区域内保持足够暗**（端值 0.48→0.50 与改造前整幅遮罩在该区间等暗）。
  static const double topFactor = 0.58;

  /// 底部暗化块占 hero 的高度比例。
  static const double bottomFactor = 0.40;

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: topFactor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // 前 66% 基本等暗（覆盖标题），之后快速放开。
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0.48),
                      Color.fromRGBO(0, 0, 0, 0.50),
                      Color.fromRGBO(0, 0, 0, 0),
                    ],
                    stops: [0.0, 0.66, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: bottomFactor,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // 到 slogan 所在位置才压到 0.62（与改造前等暗）。
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0),
                      Color.fromRGBO(0, 0, 0, 0.62),
                      Color.fromRGBO(0, 0, 0, 0.78),
                    ],
                    stops: [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SideAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SideAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return PressableScale(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: onSurface, size: 26),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: onSurface),
          ),
        ],
      ),
    );
  }
}

/// 中央大播放圆钮（Apple Music 详情页风格）。
class _PlayCircle extends StatelessWidget {
  final VoidCallback onTap;

  const _PlayCircle({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: const BoxDecoration(
          color: AppTheme.appleMusicRed,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }
}
