import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../models/song.dart';
import '../providers/library_provider.dart';
import '../providers/player_provider.dart';
import '../services/subsonic_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../utils/navigation_helper.dart';
import '../utils/artist_stats.dart';
import '../widgets/luobo/list_rows.dart';
import '../widgets/luobo/multi_select.dart';
import '../widgets/luobo/song_divider.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';
import 'artist_screen.dart';
import '../l10n/app_localizations.dart';
import '../services/player_ui_settings_service.dart';
import '../services/search_history_store.dart';

class SearchScreen extends StatefulWidget {
  /// 进入即聚焦（弹键盘）。桌面端把它当 tab 常驻时传 false，避免启动抢焦点。
  final bool autoFocus;

  const SearchScreen({super.key, this.autoFocus = true});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _resultPageController = PageController();
  final _focusNode = FocusNode();
  SearchResult? _searchResult;
  SearchResult? _autocompleteSuggestions;
  bool _isSearching = false;
  bool _isLoadingSuggestions = false;
  bool _showSuggestions = false;
  String _query = '';
  Timer? _debounceTimer;
  bool _liveSearch = true;

  /// 搜索历史（fnos v5_0016：chips 流式换行 + 垃圾桶清空，本地持久化）。
  final _historyStore = SearchHistoryStore();
  List<String> _history = [];

  /// 结果分段（fnos v8_0022：单曲 / 专辑 / 歌手 三 tab，带条数）。
  int _resultTab = 0;


  @override
  void initState() {
    super.initState();
    _liveSearch = PlayerUiSettingsService().getLiveSearch();
    PlayerUiSettingsService()
        .liveSearchNotifier
        .addListener(_onLiveSearchChanged);
    _loadHistory();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  Future<void> _loadHistory() async {
    final list = await _historyStore.load();
    if (mounted) setState(() => _history = list);
  }

  void _onLiveSearchChanged() {
    setState(() {
      _liveSearch = PlayerUiSettingsService().liveSearchNotifier.value;
    });
  }

  @override
  void dispose() {
    PlayerUiSettingsService()
        .liveSearchNotifier
        .removeListener(_onLiveSearchChanged);
    _searchController.dispose();
    _resultPageController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAutocomplete(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _autocompleteSuggestions = null;
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoadingSuggestions = true;
      _showSuggestions = true;
    });

    try {
      final libraryProvider = Provider.of<LibraryProvider>(
        context,
        listen: false,
      );
      final result = await libraryProvider.search(query);
      if (mounted && _searchController.text.trim() == query.trim()) {
        setState(() {
          _autocompleteSuggestions = result;
          _isLoadingSuggestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
        });
      }
    }
  }

  /// 搜索框右侧「取消」（设计稿/08 §2）：有输入 → 清空 + 收键盘；
  /// 无输入 → 退出搜索页（与 fnos 一致）。
  void _onCancelSearch() {
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _focusNode.unfocus();
      _onSearchChanged('');
    } else {
      Navigator.of(context).pop();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.isEmpty) {
      setState(() {
        _searchResult = null;
        _autocompleteSuggestions = null;
        _showSuggestions = false;
        _query = '';
      });
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (_liveSearch) {
        _search(value);
      } else {
        _loadAutocomplete(value);
      }
    });
  }

  Future<void> _search(String query, {bool recordHistory = false}) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResult = null;
        _query = '';
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _query = query;
      _showSuggestions = false;
      _resultTab = 0;
    });
    if (_resultPageController.hasClients) {
      _resultPageController.jumpToPage(0);
    }

    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    // 只有**明确提交**（回车/搜索）才写历史：实时搜索的防抖中间态不再入库，
    // 否则「周 / 周杰 / 周杰伦」会各存一条（用户 2026-10-23 反馈的乱历史）。
    if (recordHistory) {
      final list = await _historyStore.add(query);
      if (mounted) setState(() => _history = list);
    }

    try {
      final result = await libraryProvider.search(query);
      if (mounted && _query == query) {
        setState(() {
          _searchResult = result;
          _isSearching = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                expandedHeight: 120,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    AppLocalizations.of(context)!.searchTitle,
                    style: theme.appBarTheme.titleTextStyle,
                  ),
                  titlePadding: const EdgeInsets.only(left: 16, bottom: 60),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  // 设计稿/08 §2：白卡 r14 + 放大镜 + 框外「取消」（空态弱化 /
                  // 输入态强调）。替换原 CupertinoSearchTextField（灰底 r12，
                  // 与白卡一族的设计体系不一致）。
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppTheme.darkCard
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: isDark
                                  ? null
                                  : const [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              focusNode: _focusNode,
                              style: theme.textTheme.bodyLarge,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(
                                  context,
                                )!
                                    .searchPlaceholder,
                                hintStyle: theme.textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.lightSecondaryText,
                                    ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  size: 20,
                                  color: AppTheme.lightSecondaryText,
                                ),
                                border: InputBorder.none,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: _onSearchChanged,
                              onSubmitted: (value) {
                                setState(() => _showSuggestions = false);
                                _search(value, recordHistory: true);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _onCancelSearch,
                          child: Text(
                            AppLocalizations.of(context)!.cancel,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: _query.isEmpty
                                  ? AppTheme.lightSecondaryText
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isSearching)
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)!.albums,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 12),
                      HorizontalShimmerList(
                        count: 3,
                        child: const AlbumCardShimmer(size: 150),
                      ),
                      const SizedBox(height: 24),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)!.songs,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      ...List.generate(5, (_) => const SongTileShimmer()),
                    ],
                  ),
                )
              else if (_searchResult != null && !_searchResult!.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: true,
                  child: _buildSearchResults(),
                )
              else if (_query.isNotEmpty && _searchResult?.isEmpty == true)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          size: 64,
                          color: AppTheme.lightSecondaryText,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.noResults,
                          style: theme.textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.tryDifferentSearch,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.lightSecondaryText,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverToBoxAdapter(child: _buildHistorySection()),
            ],
          ),
          if (_showSuggestions && _searchController.text.isNotEmpty)
            Positioned(
              top: 120 + 56 + 8,
              left: 16,
              right: 16,
              child: _buildAutocompleteOverlay(isDark),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final result = _searchResult!;
    final l10n = AppLocalizations.of(context)!;
    final tabs = <(String, int)>[
      (l10n.songs, result.songs.length),
      (l10n.albums, result.albums.length),
      (l10n.artists, result.artists.length),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildResultTabBar(tabs),
        Expanded(
          child: PageView(
            controller: _resultPageController,
            onPageChanged: (i) => setState(() => _resultTab = i),
            children: [
              _buildSongsResultPage(result),
              _buildAlbumsResultPage(result),
              _buildArtistsResultPage(result),
            ],
          ),
        ),
      ],
    );
  }

  /// 结果分段控件（fnos v8_0022）：文字 16/600 + 右上角小号条数，
  /// 选中项下方 2dp 玫红短横线；点击/左右滑动都可切换。
  Widget _buildResultTabBar(List<(String, int)> tabs) {
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            if (i > 0) const SizedBox(width: 24),
            GestureDetector(
              onTap: () {
                setState(() => _resultTab = i);
                if (_resultPageController.hasClients) {
                  _resultPageController.animateToPage(
                    i,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tabs[i].$1,
                        style: LuoboType.body.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _resultTab == i ? c.fg : c.fg2,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${tabs[i].$2}',
                        style: LuoboType.caption.copyWith(
                          fontSize: 10,
                          color: _resultTab == i ? LuoboAccent.accent : c.fg3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 2,
                    width: _resultTab == i ? 22 : 0,
                    decoration: BoxDecoration(
                      color: LuoboAccent.accent,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Song> get _sortedResultSongs =>
      _searchResult?.songs ?? const <Song>[];

  /// 单曲 tab：玫红圆形播放钮（左）+ 排序（右）→ 64dp 歌曲行。
  Widget _buildSongsResultPage(SearchResult result) {
    final songs = _sortedResultSongs;
    if (songs.isEmpty) return const SizedBox.shrink();
    final c = LuoboColors.of(context);
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 10,
        bottom: LuoboSpacing.pageBottomWithStrip(context),
      ),
      itemCount: songs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _recordResultTap();
                    Provider.of<PlayerProvider>(context, listen: false)
                        .playSong(songs.first, playlist: songs, startIndex: 0);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: LuoboAccent.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.play_fill,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                const Spacer(),
                // 2026-10-23：这里不是排序，是**多选**（与全部歌曲页一致）。
                GestureDetector(
                  onTap: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    showMultiSelectSheet(context, songs: songs);
                  },
                  child: Icon(
                    Icons.checklist_rounded,
                    size: 22,
                    color: c.fg2,
                  ),
                ),
              ],
            ),
          );
        }
        final i = index - 1;
        return Column(
          children: [
            SongTile(
              song: songs[i],
              playlist: songs,
              index: i,
              onTap: () {
                _recordResultTap();
                Provider.of<PlayerProvider>(context, listen: false).playSong(
                  songs[i],
                  playlist: songs,
                  startIndex: i,
                );
              },
            ),
            if (i < songs.length - 1) const LuoboSongDivider(),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsResultPage(SearchResult result) {
    if (result.albums.isEmpty) return const SizedBox.shrink();
    // 与专辑列表页同款行式（不再用网格）。
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: LuoboSpacing.pageBottomWithStrip(context),
      ),
      itemCount: result.albums.length,
      itemBuilder: (context, index) {
        return Column(
          children: [
            AlbumListTile(
              album: result.albums[index],
              onBeforeNavigate: _recordResultTap,
            ),
            if (index < result.albums.length - 1) const LuoboSongDivider(),
          ],
        );
      },
    );
  }

  Widget _buildArtistsResultPage(SearchResult result) {
    if (result.artists.isEmpty) return const SizedBox.shrink();
    final libraryProvider =
        Provider.of<LibraryProvider>(context, listen: false);
    final songCounts = ArtistStats.songCounts(result.artists, libraryProvider);
    final albumCounts = ArtistStats.albumCounts(result.artists, libraryProvider);
    // 与歌手列表页同款行式（头像 + 名字 + 「N 首歌 · M 张专辑」）。
    return ListView.builder(
      padding: EdgeInsets.only(
        top: 8,
        bottom: LuoboSpacing.pageBottomWithStrip(context),
      ),
      itemCount: result.artists.length,
      itemBuilder: (context, index) {
        final artist = result.artists[index];
        return Column(
          children: [
            ArtistListTile(
              artist: artist,
              songCount: songCounts[artist.id] ?? 0,
              albumCount: albumCounts[artist.id] ?? 0,
              onBeforeNavigate: _recordResultTap,
            ),
            if (index < result.artists.length - 1) const LuoboSongDivider(),
          ],
        );
      },
    );
  }

  /// 点任意搜索结果时把当前搜索词落进历史（用户 2026-10-23：
  /// 实时搜索下一个字就出结果、但不会按回车，历史里就丢了）。
  void _recordResultTap() {
    // 点结果时先收键盘：否则列表/详情页会被键盘压住（用户 2026-10-23）。
    FocusManager.instance.primaryFocus?.unfocus();
    final query = _query.trim();
    if (query.isEmpty) return;
    _historyStore.add(query).then((list) {
      if (mounted) setState(() => _history = list);
    });
  }

  /// 搜索历史区块（fnos v5_0016）：标题 + 垃圾桶 + chips 流式换行。
  Widget _buildHistorySection() {
    if (_history.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final c = LuoboColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                l10n.searchHistory,
                style: LuoboType.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await _historyStore.clear();
                  if (!mounted) return;
                  setState(() => _history = []);
                  showLuoboToast(
                    context,
                    message: l10n.searchHistoryCleared,
                    tone: LuoboToastTone.info,
                  );
                },
                child: Icon(
                  CupertinoIcons.trash,
                  size: 18,
                  color: c.fg2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final term in _history)
                GestureDetector(
                  onTap: () {
                    _searchController.text = term;
                    _searchController.selection = TextSelection.collapsed(
                      offset: term.length,
                    );
                    setState(() => _showSuggestions = false);
                    _search(term);
                  },
                  // ⚠️ 不要用 Container(alignment:)：Align 会吃满整行宽度，
                  // 每个 chip 都会独占一行。Center(widthFactor: 1) 才能按文字
                  // 宽度自适应、恢复流式换行。
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Center(
                      widthFactor: 1,
                      child: Text(term, style: LuoboType.body),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAutocompleteOverlay(bool isDark) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: isDark ? AppTheme.darkCard : Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA),
            width: 1,
          ),
        ),
        child: _isLoadingSuggestions
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : _autocompleteSuggestions == null ||
                    _autocompleteSuggestions!.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noSuggestions,
                        style: TextStyle(
                          color: AppTheme.lightSecondaryText,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_autocompleteSuggestions!.artists.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              AppLocalizations.of(context)!.artists,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.lightSecondaryText,
                              ),
                            ),
                          ),
                          ..._autocompleteSuggestions!.artists.map(
                            (artist) => ListTile(
                              dense: true,
                              leading: Icon(
                                CupertinoIcons.person,
                                size: 20,
                                color: AppTheme.appleMusicRed,
                              ),
                              title: Text(
                                artist.name,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                setState(() => _showSuggestions = false);
                                NavigationHelper.push(
                                  context,
                                  ArtistScreen(artistId: artist.id),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_autocompleteSuggestions!.albums.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              AppLocalizations.of(context)!.albums,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.lightSecondaryText,
                              ),
                            ),
                          ),
                          ..._autocompleteSuggestions!.albums.map(
                            (album) => ListTile(
                              dense: true,
                              leading: Icon(
                                CupertinoIcons.music_albums,
                                size: 20,
                                color: AppTheme.appleMusicRed,
                              ),
                              title: Text(
                                album.name,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: album.artist != null
                                  ? Text(
                                      album.artist!,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _showSuggestions = false);
                                NavigationHelper.push(
                                  context,
                                  AlbumScreen(albumId: album.id),
                                );
                              },
                            ),
                          ),
                        ],
                        if (_autocompleteSuggestions!.songs.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Text(
                              AppLocalizations.of(context)!.songs,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.lightSecondaryText,
                              ),
                            ),
                          ),
                          ..._autocompleteSuggestions!.songs.map(
                            (song) => ListTile(
                              dense: true,
                              leading: Icon(
                                CupertinoIcons.music_note,
                                size: 20,
                                color: AppTheme.appleMusicRed,
                              ),
                              title: Text(
                                song.title,
                                style: const TextStyle(fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: song.artist != null
                                  ? Text(
                                      song.artist!,
                                      style: const TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () {
                                setState(() => _showSuggestions = false);
                                final playerProvider =
                                    Provider.of<PlayerProvider>(
                                  context,
                                  listen: false,
                                );
                                playerProvider.playSong(
                                  song,
                                  playlist: _autocompleteSuggestions!.songs,
                                  startIndex: _autocompleteSuggestions!.songs
                                      .indexOf(song),
                                );
                              },
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
      ),
    );
  }
}

