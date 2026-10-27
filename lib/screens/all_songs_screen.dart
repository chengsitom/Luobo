import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../providers/library_provider.dart';
import '../models/models.dart';
import '../utils/navigation_helper.dart';
import '../utils/song_sort.dart';
import '../widgets/widgets.dart';
import '../theme/app_icons.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/anchored_menu.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/song_divider.dart';
import '../l10n/app_localizations.dart';
import 'search_screen.dart';

class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  List<Song> _songs = [];
  List<Song> _sortedSongs = [];
  bool _isLoading = true;
  final ScrollController _scrollController = ScrollController();
  SongSortField _sortField = SongSortField.title;
  bool _sortAscending = true;

  // 多选整屏接管（§4.5）：长按进入，行按 index 选中。

  /// 锚定菜单的锚点：「共 N 首」行里的排序入口。
  final _sortAnchorHeader = GlobalKey();
  LibraryProvider? _libraryProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCachedData());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _libraryProvider?.removeListener(_onLibraryChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  void _onLibraryChanged() {
    if (!mounted) return;
    final provider = _libraryProvider;
    if (provider == null) return;
    final songs = provider.cachedAllSongs;
    if (songs.length != _songs.length || songs.isEmpty != _songs.isEmpty) {
      setState(() {
        _songs = songs;
        _sortSongs();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCachedData() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    _libraryProvider = libraryProvider;
    libraryProvider.addListener(_onLibraryChanged);

    // Returns immediately when the cache is empty; the background sync
    // notifies this screen via _onLibraryChanged when data is ready.
    await libraryProvider.ensureLibraryLoaded();

    if (mounted) {
      setState(() {
        _songs = libraryProvider.cachedAllSongs;
        _sortSongs();
        _isLoading = false;
      });
    }
  }

  void _sortSongs() {
    _sortedSongs = sortSongs(_songs, _sortField, ascending: _sortAscending);
  }

  bool _showsDirection(SongSortField field) => songSortShowsDirection(field);

  String _fieldLabel(AppLocalizations l10n, SongSortField field) {
    switch (field) {
      case SongSortField.title:
        return l10n.sortFieldTitle;
      case SongSortField.artist:
        return l10n.artists;
      case SongSortField.album:
        return l10n.albums;
      case SongSortField.recentlyAdded:
        return l10n.recentlyAdded;
    }
  }

  /// 锚定毛玻璃菜单（设计稿 §2.3 范式①；实测规格见
  /// `docs/锚定浮层与列表页排序技术方案.md` §2）。
  ///
  /// 交互：点**已选中**字段 = 翻转方向；点**其它**字段 = 切换字段（保持方向）。
  Future<void> _showSortOptions(GlobalKey anchor) async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showLuoboAnchoredMenu<SongSortField>(
      context: context,
      anchorKey: anchor,
      selected: _sortField,
      items: [
        for (final field in SongSortField.values)
          LuoboAnchoredMenuItem(
            value: field,
            label: _fieldLabel(l10n, field),
            // 方向箭头**只在选中项**上出现（未选中项什么都不带）。
            trailing: (field == _sortField && _showsDirection(field))
                ? Icon(
                    _sortAscending ? AppIcons.arrowUp : AppIcons.arrowDown,
                    size: 15,
                    color: LuoboAccent.accent,
                  )
                : null,
          ),
      ],
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (picked == _sortField) {
        if (_showsDirection(picked)) _sortAscending = !_sortAscending;
      } else {
        _sortField = picked;
      }
    });
    _sortSongs();
  }

  /// 多选（fnos v1_0064：点击/长按后弹**全屏 sheet**选择，不是页面内模式）。
  void _openMultiSelect() {
    if (_sortedSongs.isEmpty) return;
    showMultiSelectSheet(context, songs: _sortedSongs);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      // 与收藏页同款：透明顶栏 + 悬浮圆钮（无实色栏、无标题）。
      extendBodyBehindAppBar: true,
      appBar: LuoboListTopBar(
        actions: [
          LuoboTopSearchButton(
            onTap: () =>
                NavigationHelper.push(context, const SearchScreen()),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _songs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.music_note_outlined,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noSongsFound,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  // 整页滚动：留白 + 计数行都在列表里，内容从悬浮圆钮下方流过
                  //（与歌手/专辑列表一致）。
                  padding: EdgeInsets.only(
                    top: listTopInset(context),
                    bottom: 100,
                  ),
                  itemCount: _sortedSongs.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    l10n.songsTotal(_sortedSongs.length),
                                    style: LuoboType.body.copyWith(
                                      fontSize: 14,
                                      color: LuoboColors.of(context).fg2,
                                    ),
                                  ),
                                ),
                                // fnos：计数行右侧只有「排序 + 多选」两个图标。
                                GestureDetector(
                                  key: _sortAnchorHeader,
                                  onTap: () =>
                                      _showSortOptions(_sortAnchorHeader),
                                  child: Icon(
                                    Icons.sort_rounded,
                                    size: 22,
                                    color: LuoboColors.of(context).fg2,
                                  ),
                                ),
                                const SizedBox(width: 18),
                                GestureDetector(
                                  onTap: _openMultiSelect,
                                  child: Icon(
                                    Icons.checklist_rounded,
                                    size: 22,
                                    color: LuoboColors.of(context).fg2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    }
                    final i = index - 1;
                    return Column(
                      children: [
                        SongTile(
                          song: _sortedSongs[i],
                          playlist: _sortedSongs,
                          index: i,
                          showAlbum: true,
                          onLongPress: _openMultiSelect,
                        ),
                        if (i < _sortedSongs.length - 1)
                          const LuoboSongDivider(),
                      ],
                    );
                  },
                ),
    );
  }
}
