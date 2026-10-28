import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/heart_playlist.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/heart_playlist_row.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'heart_playlist_detail_screen.dart';

/// 心动歌单列表页（仅道理鱼服务器）。
///
/// 视觉骨架：透明顶栏（返回 + 标题胶囊 / 换一批圆钮）→ 文字页头 → 12 条
/// 「2×2 封面拼图 + 名称/描述/标签/时长」列表行。列表接口不传 `refresh`
/// 时返回同一批，因此每次进入不会重新生成。
class HeartPlaylistsScreen extends StatefulWidget {
  const HeartPlaylistsScreen({super.key});

  @override
  State<HeartPlaylistsScreen> createState() => _HeartPlaylistsScreenState();
}

class _HeartPlaylistsScreenState extends State<HeartPlaylistsScreen> {
  HeartPlaylistBatch? _batch;
  Map<String, String> _covers = const {};
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  /// 每次加载/换一批自增；旧批次的封面票据晚到时直接丢弃，避免覆盖新列表。
  int _loadSerial = 0;

  /// 上滑超过这个距离后，返回钮才带上「心动歌单」标题。
  static const double _titleRevealOffset = 64;

  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _showTopTitle = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _showTopTitle.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final offset = _scrollController.offset;
    // 8dp 回滞：阈值附近来回滚动时不闪烁。
    final show = _showTopTitle.value
        ? offset > _titleRevealOffset - 8
        : offset > _titleRevealOffset;
    if (show != _showTopTitle.value) _showTopTitle.value = show;
  }

  Future<void> _load({bool refresh = false}) async {
    // 首次加载未完成时忽略「换一批」，避免两个请求互相覆盖。
    if (_refreshing || (_loading && refresh)) return;
    final serial = ++_loadSerial;
    if (!refresh) _showTopTitle.value = false;
    setState(() {
      if (refresh) {
        _refreshing = true;
      } else {
        _loading = true;
      }
      _error = null;
    });

    final service = Provider.of<SubsonicService>(context, listen: false);
    final token = refresh
        ? '${DateTime.now().millisecondsSinceEpoch}-'
            '${Random().nextInt(1 << 31)}'
        : null;
    final batch = await service.getHeartPlaylists(count: 12, refresh: token);

    if (!mounted || serial != _loadSerial) return;

    if (batch == null) {
      if (refresh && _batch != null && mounted) {
        showLuoboToast(
          context,
          message: '换一批失败，请稍后重试',
          tone: LuoboToastTone.info,
        );
      }
      setState(() {
        _loading = false;
        _refreshing = false;
        _error = '加载失败，请检查网络后重试';
      });
      return;
    }

    final paths = <String>{};
    for (final playlist in batch.playlists) {
      for (final url in playlist.coverUrls) {
        final path = _pathOf(url);
        if (path != null) paths.add(path);
      }
    }
    if (batch.playlists.isEmpty) _showTopTitle.value = false;

    // 先把列表放出来，再分批换封面票据：12 组 × 4 张 = 48 张图，
    // 等全部票据到位再渲染会让首屏白等好几秒。
    setState(() {
      _batch = batch;
      _covers = const {};
      _loading = false;
      _refreshing = false;
    });

    final allPaths = paths.toList();
    for (var i = 0; i < allPaths.length; i += 12) {
      final chunk = allPaths.skip(i).take(12).toList();
      final covers = await service.fetchDaoliyuCoverTickets(chunk);
      if (!mounted || serial != _loadSerial) return;
      if (covers.isEmpty) continue;
      setState(() => _covers = {..._covers, ...covers});
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    // 与设置页/所有二级页同一套底部净空；不要写死 100。
    final bottomPadding = LuoboSpacing.pageBottomWithStrip(context);
    return Scaffold(
      backgroundColor: c.bg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ValueListenableBuilder<bool>(
          valueListenable: _showTopTitle,
          builder: (context, showTitle, _) => LuoboListTopBar(
            // 顶部先只显示返回圆钮；上滑到页头标题快被顶栏盖住时，
            // 再换成「返回 + 心动歌单」胶囊（与歌手详情折叠后的行为一致）。
            title: showTitle ? '心动歌单' : null,
            actions: [
              Tooltip(
                message: '换一批',
                child: LuoboTopCircleButton(
                  icon: AppIcons.refresh,
                  onTap: () => _load(refresh: true),
                ),
              ),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: Theme.of(context).colorScheme.primary,
        onRefresh: () => _load(refresh: true),
        child: _buildBody(context, c, bottomPadding),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    LuoboColors c,
    double bottomPadding,
  ) {
    if (_loading) return _buildSkeleton(context, c, bottomPadding);

    final batch = _batch;
    if (batch == null || batch.playlists.isEmpty) {
      return ListView(
        padding: EdgeInsets.only(
          top: listTopInset(context) + 40,
          left: 20,
          right: 20,
          bottom: bottomPadding,
        ),
        children: [
          LuoboEmptyState(
            icon: AppIcons.heart,
            message: _error ??
                '还没有心动歌单\n去道理鱼 Web 首页打开一次心动歌单，'
                    '或先补齐歌曲的风格 / 场景标签',
            action: TextButton.icon(
              onPressed: () => _load(refresh: true),
              icon: const Icon(AppIcons.refresh, size: 16),
              label: const Text('重试'),
            ),
          ),
        ],
      );
    }

    final issue = batch.playlists.first.issueLabel ?? '每日更新';
    final updated = _updatedLabel(batch.generatedAt);

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.only(
            top: listTopInset(context) + 8,
            left: 20,
            right: 20,
            bottom: bottomPadding,
          ),
          // 0 = 页头，1 = 间距，之后每项一张歌单卡。
          // 用 builder 而不是 children：12 行一次全建会同时发 48 张封面请求，
          // 远程 NAS 上首屏会被这堆请求拖慢；builder 只建可视区附近的几行。
          itemCount: batch.playlists.length + 2,
          itemBuilder: (context, index) {
            if (index == 0) {
              return _Header(
                count: batch.playlists.length,
                issue: issue,
                updated: updated,
              );
            }
            if (index == 1) return const SizedBox(height: 18);
            final playlist = batch.playlists[index - 2];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: HeartPlaylistRow(
                playlist: playlist,
                coverUrls: _resolvedCovers(playlist),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        HeartPlaylistDetailScreen(playlist: playlist),
                  ),
                ),
              ),
            );
          },
        ),
        if (_refreshing)
          Positioned(
            left: 0,
            right: 0,
            top: listTopInset(context) - 2,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: Theme.of(context).colorScheme.primary,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }

  Widget _buildSkeleton(
    BuildContext context,
    LuoboColors c,
    double bottomPadding,
  ) {
    return ListView(
      padding: EdgeInsets.only(
        top: listTopInset(context) + 8,
        left: 20,
        right: 20,
        bottom: bottomPadding,
      ),
      children: [
        Container(
          height: 22,
          width: 120,
          alignment: Alignment.centerLeft,
          child: Container(
            width: 120,
            height: 22,
            decoration: BoxDecoration(
              color: c.divider.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
        const SizedBox(height: 18),
        for (var i = 0; i < 6; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 108,
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: c.divider.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(LuoboRadius.tile),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _skeletonLine(c, widthFactor: 0.92),
                        const SizedBox(height: 8),
                        _skeletonLine(c, widthFactor: 0.65),
                        const SizedBox(height: 8),
                        _skeletonLine(c, widthFactor: 0.4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _skeletonLine(LuoboColors c, {required double widthFactor}) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: Container(
        height: 10,
        decoration: BoxDecoration(
          color: c.divider.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }

  List<String> _resolvedCovers(HeartPlaylist playlist) {
    return playlist.coverUrls.map((url) {
      final path = _pathOf(url);
      if (path == null) return '';
      return _covers[path] ?? '';
    }).toList();
  }

  static String? _pathOf(String url) {
    try {
      return Uri.parse(url).queryParameters['path'];
    } catch (_) {
      return null;
    }
  }

  static String? _updatedLabel(DateTime? generatedAt) {
    if (generatedAt == null) return null;
    final local = generatedAt.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '更新于 ${local.month} 月 ${local.day} 日 $hh:$mm';
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.count,
    required this.issue,
    required this.updated,
  });

  final int count;
  final String issue;
  final String? updated;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final meta = [
      issue,
      if (updated != null) updated!,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '今日心动',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '为你组合的 $count 组歌单',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.4,
            color: c.fg,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '根据你的曲库风格与场景，每天换一批',
          style: TextStyle(fontSize: 13, color: c.fg2),
        ),
        const SizedBox(height: 6),
        Text(
          meta,
          style: TextStyle(fontSize: 11, color: c.fg3),
        ),
      ],
    );
  }
}
