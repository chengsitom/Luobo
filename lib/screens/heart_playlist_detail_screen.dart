import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/heart_playlist.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/heart_playlist_row.dart';
import '../widgets/luobo/empty_state.dart';
import '../widgets/luobo/hero_detail_header.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../widgets/luobo/sheet_shell.dart';
import '../widgets/song_tile.dart';

/// 心动歌单详情：头部 2×2 拼图 + 名称/描述/标签 + 播放全部/随机播放 +
/// 右上角保存歌单 + 曲目列表。
///
/// 曲目只能从详情接口取（`/heart-playlists/{id}` 一次返回全部 `tracks`），
/// 列表接口没有曲目。
class HeartPlaylistDetailScreen extends StatefulWidget {
  const HeartPlaylistDetailScreen({
    super.key,
    required this.playlist,
  });

  /// 列表页传入的元数据（无曲目）；详情页再用 id 拉完整数据。
  final HeartPlaylist playlist;

  @override
  State<HeartPlaylistDetailScreen> createState() =>
      _HeartPlaylistDetailScreenState();
}

class _HeartPlaylistDetailScreenState extends State<HeartPlaylistDetailScreen> {
  late HeartPlaylist _detail = widget.playlist;
  Map<String, String> _covers = const {};
  bool _loadingTracks = true;
  bool _saving = false;
  String? _error;

  /// 上滑超过这个距离（大约把 168dp 拼图滑出视口）后，返回钮才带上歌单名。
  static const double _titleRevealOffset = 160;

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

  Future<void> _load() async {
    final service = Provider.of<SubsonicService>(context, listen: false);
    final detail = await service.getHeartPlaylistDetail(widget.playlist.id);
    final source = detail ?? widget.playlist;

    final paths = <String>{};
    for (final url in source.coverUrls) {
      final path = _pathOf(url);
      if (path != null) paths.add(path);
    }
    final covers = await service.fetchDaoliyuCoverTickets(paths.toList());

    if (!mounted) return;
    setState(() {
      _detail = source;
      _covers = covers;
      _loadingTracks = false;
      _error = detail == null ? '曲目加载失败，请返回重试' : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final alreadySaved = context.select<LibraryProvider, bool>(
      (library) => library.playlists.any((p) => p.name == _detail.name),
    );
    // 二级页底部是悬浮播放条：显式 padding 的 sliver 不会自动吃到
    // `MediaQuery.padding.bottom`，最后一行会被播放条压住。
    // 用设置页/所有二级页同一套净空 helper，不要写死 100。
    final bottomPadding = LuoboSpacing.pageBottomWithStrip(context);
    return Scaffold(
      backgroundColor: c.bg,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: ValueListenableBuilder<bool>(
          valueListenable: _showTopTitle,
          builder: (context, showTitle, _) => LuoboListTopBar(
            // 顶部先只显示返回圆钮；上滑到封面/标题快被顶栏盖住时，
            // 才换成「返回 + 歌单名」胶囊。
            title: showTitle ? _detail.name : null,
            actions: [
              Tooltip(
                message: alreadySaved ? '已保存' : '保存歌单',
                child: LuoboTopCircleButton(
                  icon: _saving
                      ? Icons.hourglass_top_rounded
                      : alreadySaved
                          ? Icons.playlist_add_check_rounded
                          : Icons.playlist_add_rounded,
                  onTap: _save,
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context, c)),
          if (_loadingTracks)
            const SliverToBoxAdapter(
              child: SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_error != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: LuoboEmptyState(
                  icon: AppIcons.heart,
                  message: _error!,
                  action: TextButton.icon(
                    onPressed: _load,
                    icon: const Icon(AppIcons.refresh, size: 16),
                    label: const Text('重试'),
                  ),
                ),
              ),
            )
          else if (_detail.tracks.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: LuoboEmptyState(
                  icon: AppIcons.emptyMusic,
                  message: '这组歌单暂时没有曲目',
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final songs = _detail.tracks;
                  return SongTile(
                    song: songs[index],
                    playlist: songs,
                    index: index,
                    showAlbum: true,
                  );
                },
                childCount: _detail.tracks.length,
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: bottomPadding)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, LuoboColors c) {
    final accent = Theme.of(context).colorScheme.primary;
    final tags = <String>[
      ..._detail.genres,
      ..._detail.scenes,
    ].take(6).toList();

    return Padding(
      padding: EdgeInsets.only(
        top: listTopInset(context) + 8,
        left: 20,
        right: 20,
        bottom: 12,
      ),
      child: Column(
        children: [
          Center(
            child: HeartCoverMosaic(
              urls: _resolvedCovers(),
              size: 168,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            _detail.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
              letterSpacing: -0.4,
              color: c.fg,
            ),
          ),
          if (_detail.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _detail.description,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: c.fg2,
              ),
            ),
          ],
          if (tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final tag in tags) HeartTag(text: tag),
              ],
            ),
          ],
          if (_detail.metaLabel.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _detail.metaLabel,
              style: TextStyle(fontSize: 11, color: c.fg3),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  label: '播放全部',
                  icon: AppIcons.play,
                  filled: true,
                  color: accent,
                  onTap: _loadingTracks ? null : _playAll,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionPill(
                  label: '随机播放',
                  icon: AppIcons.shuffle,
                  filled: false,
                  color: accent,
                  onTap: _loadingTracks ? null : _shuffleAll,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _playAll() {
    final songs = _detail.tracks;
    if (songs.isEmpty) return;
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      songs.first,
      playlist: songs,
      startIndex: 0,
      forcePlay: true,
    );
  }

  void _shuffleAll() {
    final songs = List.of(_detail.tracks);
    if (songs.isEmpty) return;
    songs.shuffle(Random());
    Provider.of<PlayerProvider>(context, listen: false).playSong(
      songs.first,
      playlist: songs,
      startIndex: 0,
      forcePlay: true,
    );
  }

  Future<void> _save() async {
    final detail = _detail;
    if (_saving) return;
    if (detail.trackIds.isEmpty) {
      showLuoboToast(
        context,
        message: '曲目还没加载完',
        tone: LuoboToastTone.info,
      );
      return;
    }

    final library = Provider.of<LibraryProvider>(context, listen: false);
    if (library.playlists.any((p) => p.name == detail.name)) {
      showLuoboToast(
        context,
        message: '这个歌单已经保存过了',
        tone: LuoboToastTone.info,
      );
      return;
    }

    final count =
        detail.trackCount > 0 ? detail.trackCount : detail.trackIds.length;
    final ok = await showLuoboConfirmSheet(
      context: context,
      title: '保存歌单',
      message: '将「${detail.name}」保存为你的歌单？\n共 $count 首。',
      confirmLabel: '保存',
    );
    if (ok != true || !mounted) return;

    // 二次确认期间可能已被保存，再查一次，避免重复建同名歌单。
    if (library.playlists.any((p) => p.name == detail.name)) {
      showLuoboToast(
        context,
        message: '这个歌单已经保存过了',
        tone: LuoboToastTone.info,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await library.createPlaylist(detail.name, songIds: detail.trackIds);
      if (!mounted) return;
      showLuoboToast(
        context,
        message: '歌单「${detail.name}」已保存',
        tone: LuoboToastTone.info,
      );
    } catch (e) {
      if (mounted) {
        showLuoboToast(
          context,
          message: '保存失败，请稍后重试',
          tone: LuoboToastTone.info,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  List<String> _resolvedCovers() {
    return _detail.coverUrls.map((url) {
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
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.icon,
    required this.filled,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);
    final enabled = onTap != null;
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: filled ? color : c.card,
        borderRadius: BorderRadius.circular(LuoboRadius.pill),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 46,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: filled ? Colors.white : c.fg,
                ),
                const SizedBox(width: 7),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: filled ? Colors.white : c.fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
