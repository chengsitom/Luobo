import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/byte_format.dart';
import '../utils/image_cache.dart';
import '../utils/navigation_helper.dart';
import 'downloaded_songs_screen.dart';
import '../providers/library_provider.dart';
import '../services/bpm_analyzer_service.dart';
import '../services/cache_settings_service.dart';
import '../services/local_music_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../widgets/luobo/list_top_bar.dart';
import '../widgets/luobo/luobo_card.dart';
import '../widgets/luobo/luobo_tile.dart';

class SettingsStorageTab extends StatefulWidget {
  const SettingsStorageTab({super.key});

  @override
  State<SettingsStorageTab> createState() => _SettingsStorageTabState();
}

class _SettingsStorageTabState extends State<SettingsStorageTab> {
  final _bpmAnalyzer = BpmAnalyzerService();
  final _cacheSettings = CacheSettingsService();
  final _offlineService = OfflineService();

  bool _imageCacheEnabled = true;
  bool _isCaching = false;
  int _currentProgress = 0;
  int _totalSongs = 0;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';
  // 下载任务进度（与 BPM 缓存进度 _currentProgress/_totalSongs 分开）
  bool _isDownloading = false;
  int _downloadDone = 0;
  int _downloadTotal = 0;
  int _downloadFailed = 0;
  String _imageCacheSize = '—';
  int _parallelDownloads = 3;
  bool _keepScreenOn = true;
  bool _wifiOnlyDownload = false;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _setupDownloadListener();
  }

  @override
  void dispose() {
    _offlineService.downloadState.removeListener(_onDownloadStateChanged);
    super.dispose();
  }

  void _setupDownloadListener() {
    _offlineService.downloadState.addListener(_onDownloadStateChanged);
  }

  void _onDownloadStateChanged() {
    if (!mounted) return;
    final state = _offlineService.downloadState.value;
    setState(() {
      _downloadedCount = state.downloadedCount;
      _isDownloading = state.isDownloading;
      _downloadDone = state.currentProgress;
      _downloadTotal = state.totalCount;
      _downloadFailed = state.failedCount;
    });
  }

  Future<void> _loadSettings() async {
    await _cacheSettings.initialize();
    await _offlineService.initialize();
    await _loadOfflineInfo();
    await _loadCacheSizes();

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _parallelDownloads = _offlineService.getParallelDownloadsCount();
      _keepScreenOn = _offlineService.getKeepScreenOn();
      _wifiOnlyDownload = _offlineService.getWifiOnly();
    });
  }

  Future<void> _loadCacheSizes() async {
    final diskBytes = await coverCacheDirSize();
    if (!mounted) return;
    setState(() {
      _imageCacheSize = formatBytes(diskBytes);
    });
  }

  Future<void> _loadOfflineInfo() async {
    final count = _offlineService.getDownloadedCount();
    final size = await _offlineService.getDownloadedSize();
    if (mounted) {
      setState(() {
        _downloadedCount = count;
        _downloadedSize = formatBytes(size);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: LuoboSpacing.scrollPadding(context, top: 16 + listScrollTopInset(context), bottom: 16),
      children: [
        _buildSection(
          title: AppLocalizations.of(context)!.sectionCacheSettings,
          children: [
            _buildCacheToggle(
              icon: CupertinoIcons.photo,
              title: AppLocalizations.of(context)!.imageCacheTitle,
              subtitle: AppLocalizations.of(context)!.imageCacheSubtitle,
              value: _imageCacheEnabled,
              onChanged: _toggleImageCache,
            ),
          ],
        ),
        _buildSection(
          title: AppLocalizations.of(context)!.sectionCacheCleanup,
          children: [
            _buildCacheSizeTile(
              icon: CupertinoIcons.photo,
              title: AppLocalizations.of(context)!.imageCacheTitle,
              value: _imageCacheSize,
            ),
            _buildDivider(),
            _buildClearAllCacheButton(),
          ],
        ),
        _buildSection(
          title: AppLocalizations.of(context)!.sectionOfflineDownloads,
          children: [
            _buildParallelDownloadsTile(),
            _buildDivider(),
            _buildKeepScreenOnTile(),
            _buildDivider(),
            _buildWifiOnlyTile(),
            _buildDivider(),
            _buildOfflineInfo(),
            if (_isDownloading) ...[
              _buildDivider(),
              _buildDownloadProgress(),
            ],
            _buildDivider(),
            _buildDeleteDownloadsButton(),
          ],
        ),
        _buildLocalMusicSection(),
        _buildSection(
          title: AppLocalizations.of(context)!.sectionBpmAnalysis,
          children: [
            _buildBPMCacheInfo(),
            if (_isCaching) _buildCachingProgress(),
            _buildCacheAllButton(),
            _buildClearCacheButton(),
          ],
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        LuoboSectionHeader(title),
        LuoboCard(children: children),
      ],
    );
  }

  Widget _buildDivider() => const LuoboDivider(indent: LuoboDivider.withIcon);

  Widget _buildCacheToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return LuoboRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      showChevron: false,
      trailing: LuoboSwitch(value: value, onChanged: onChanged),
    );
  }

  void _toggleImageCache(bool value) async {
    setState(() => _imageCacheEnabled = value);
    await _cacheSettings.setImageCacheEnabled(value);
    if (!value) await coverCacheManager.emptyCache();
  }

  Widget _buildLocalMusicSection() {
    return Consumer<LocalMusicService>(
      builder: (context, localMusic, _) {
        final l10n = AppLocalizations.of(context)!;
        final customPaths = localMusic.customScanPaths;

        return _buildSection(
          title: l10n.localMusicLibrary,
          children: [
            // Merge toggle
            LuoboRow(
              icon: CupertinoIcons.music_albums,
              title: l10n.mergeLocalLibrary,
              subtitle: l10n.mergeLocalLibrarySubtitle,
              showChevron: false,
              trailing: LuoboSwitch(
                value: context.watch<LibraryProvider>().mergeLocalLibrary,
                onChanged: (value) {
                  final libraryProvider = context.read<LibraryProvider>();
                  if (value) {
                    // Enable merge mode
                    libraryProvider.setLocalMusicService(localMusic,
                        mergeWithServer: true);
                  } else {
                    // Disable merge mode
                    libraryProvider.setMergeLocalLibrary(false);
                  }
                },
              ),
            ),
            _buildDivider(),
            // Local music stats
            LuoboRow(
              icon: CupertinoIcons.music_note,
              title: l10n.localMusicStats,
              subtitle: localMusic.isScanning ? localMusic.scanStatus : null,
              value: '${localMusic.songCount} ${l10n.songs.toLowerCase()}',
              showChevron: false,
            ),
            _buildDivider(),
            // Add folder button
            LuoboRow(
              icon: CupertinoIcons.plus,
              title: l10n.addMusicFolder,
              onTap: () => _addMusicFolder(context, localMusic),
            ),
            // Show custom paths
            if (customPaths.isNotEmpty) ...[
              _buildDivider(),
              ...customPaths.map(
                (path) => LuoboRow(
                  icon: CupertinoIcons.folder_fill,
                  title: path.split('/').last,
                  subtitle: path,
                  showChevron: false,
                  trailing: IconButton(
                    icon: const Icon(
                      CupertinoIcons.delete,
                      color: LuoboAccent.accent,
                      size: 20,
                    ),
                    onPressed: () =>
                        _removeMusicFolder(context, localMusic, path),
                  ),
                ),
              ),
            ],
            _buildDivider(),
            // Rescan button
            LuoboRow(
              icon: CupertinoIcons.refresh,
              title: l10n.rescanLocalMusic,
              onTap: localMusic.isScanning
                  ? null
                  : () => _rescanLocalMusic(context, localMusic),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addMusicFolder(
      BuildContext context, LocalMusicService service) async {
    final path = await service.pickMusicDirectory();
    if (path == null) return;
    if (!mounted) return;
    showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.addedFolder(path),
      tone: LuoboToastTone.info,
    );
    // Trigger a rescan if merge mode is enabled
    final libraryProvider = context.read<LibraryProvider>();
    if (libraryProvider.mergeLocalLibrary) {
      service.scanForMusic();
    }
  }

  Future<void> _removeMusicFolder(
      BuildContext context, LocalMusicService service, String path) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.removeFolder),
        content: Text(AppLocalizations.of(context)!.removeFolderConfirm(path)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.remove,
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await service.removeCustomScanPath(path);
    if (!mounted) return;
    showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.folderRemoved,
      tone: LuoboToastTone.info,
    );
  }

  Widget _buildKeepScreenOnTile() {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: CupertinoIcons.bolt_fill,
      title: l10n.keepScreenOnDuringDownload,
      subtitle: l10n.keepScreenOnDuringDownloadSubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _keepScreenOn,
        onChanged: (value) async {
          setState(() => _keepScreenOn = value);
          await _offlineService.setKeepScreenOn(value);
        },
      ),
    );
  }

  Widget _buildWifiOnlyTile() {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: CupertinoIcons.wifi,
      title: l10n.downloadWifiOnly,
      subtitle: l10n.downloadWifiOnlySubtitle,
      showChevron: false,
      trailing: LuoboSwitch(
        value: _wifiOnlyDownload,
        onChanged: (value) async {
          setState(() => _wifiOnlyDownload = value);
          await _offlineService.setWifiOnly(value);
        },
      ),
    );
  }

  Widget _buildParallelDownloadsTile() {
    final l10n = AppLocalizations.of(context)!;
    return LuoboRow(
      icon: CupertinoIcons.arrow_down_to_line,
      title: l10n.parallelDownloads,
      subtitle: l10n.parallelDownloadsSubtitle,
      value: '$_parallelDownloads',
      onTap: _showParallelDownloadsDialog,
    );
  }

  Future<void> _showParallelDownloadsDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.parallelDownloads),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [1, 2, 3, 4, 5].map((count) {
            final isSelected = count == _parallelDownloads;
            return ListTile(
              title: Text(
                  '$count ${count == 1 ? l10n.downloadSingular : l10n.downloadPlural}'),
              subtitle: count == 1
                  ? Text(l10n.slowerButStable)
                  : count == 5
                      ? Text(l10n.fasterButMoreData)
                      : null,
              leading: Icon(
                isSelected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color:
                    isSelected ? Theme.of(context).colorScheme.primary : null,
              ),
              onTap: () => Navigator.pop(context, count),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
        ],
      ),
    );

    if (selected != null && selected != _parallelDownloads) {
      await _offlineService.setParallelDownloadsCount(selected);
      setState(() {
        _parallelDownloads = selected;
      });
    }
  }

  Future<void> _rescanLocalMusic(
      BuildContext context, LocalMusicService service) async {
    if (service.isScanning) return;

    // Request permission first
    final hasPermission = await service.requestPermission();
    if (!hasPermission) {
      if (mounted) {
        showLuoboToast(
      context,
      message: AppLocalizations.of(context)!.storagePermissionRequired,
      tone: LuoboToastTone.info,
    );
      }
      return;
    }

    await service.scanForMusic();
  }

  Widget _buildCacheSizeTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return LuoboRow(
      icon: icon,
      title: title,
      value: value,
      showChevron: false,
    );
  }

  Future<bool> _confirmClear(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3B30)),
                child: Text(AppLocalizations.of(context)!.clearAllCache),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _buildClearAllCacheButton() {
    return LuoboRow(
      icon: CupertinoIcons.trash_fill,
      title: AppLocalizations.of(context)!.clearAllCache,
      danger: true,
      onTap: _clearAllCache,
    );
  }

  Future<void> _clearAllCache() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await _confirmClear(
      l10n.clearAllCache,
      '将清除封面图片和 BPM 缓存，封面会在下次使用时重新下载。',
    );
    if (!confirmed || !mounted) return;

    await coverCacheManager.emptyCache();
    await _bpmAnalyzer.clearCache();
    if (mounted) {
      showLuoboToast(
      context,
      message: l10n.allCacheCleared,
      tone: LuoboToastTone.info,
    );
      await _loadCacheSizes();
      setState(() {});
    }
  }

  Widget _buildOfflineInfo() {
    return LuoboRow(
      icon: CupertinoIcons.arrow_down_circle,
      title: AppLocalizations.of(context)!.downloadedSongs,
      value: AppLocalizations.of(
        context,
      )!
          .downloadedStats(_downloadedCount, _downloadedSize),
      onTap: () async {
        await NavigationHelper.push(
          context,
          const DownloadedSongsScreen(),
        );
        // 从已下载页删除歌曲返回后，刷新统计数字。
        if (mounted) await _loadOfflineInfo();
      },
    );
  }

  Widget _buildDeleteDownloadsButton() {
    return LuoboRow(
      icon: CupertinoIcons.trash_fill,
      title: AppLocalizations.of(context)!.deleteDownloads,
      danger: true,
      onTap: () async {
        final l10n = AppLocalizations.of(context)!;
        final confirmed = await _confirmClear(
          l10n.deleteDownloads,
          l10n.deleteDownloadsConfirm,
        );
        if (confirmed != true || !mounted) return;
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        if (mounted) {
          showLuoboToast(
            context,
            message: l10n.downloadsDeleted,
            tone: LuoboToastTone.info,
          );
        }
      },
    );
  }

  Widget _buildBPMCacheInfo() {
    final cachedCount = _bpmAnalyzer.getCachedCount();
    return LuoboRow(
      icon: CupertinoIcons.speedometer,
      title: AppLocalizations.of(context)!.cachedBpms,
      value: '$cachedCount',
      showChevron: false,
    );
  }

  /// 后台下载进度条：显示 已完成/总数 + 失败数，让批量下载不再"点了就没影"。
  Widget _buildDownloadProgress() {
    final progress = _downloadTotal > 0 ? _downloadDone / _downloadTotal : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '下载中 $_downloadDone / $_downloadTotal'
            '${_downloadFailed > 0 ? ' · $_downloadFailed 失败' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: _isDark ? AppTheme.darkCard : AppTheme.lightDivider,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCachingProgress() {
    final progress = _totalSongs > 0 ? _currentProgress / _totalSongs : 0.0;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: LinearProgressIndicator(
        value: progress,
        backgroundColor: _isDark ? AppTheme.darkCard : AppTheme.lightDivider,
        valueColor: AlwaysStoppedAnimation<Color>(
          Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _cacheAllBPMs() async {
    final l10n = AppLocalizations.of(context)!;
    final songs = context.read<LibraryProvider>().cachedAllSongs;
    if (songs.isEmpty) {
      showLuoboToast(
        context,
        message: l10n.libraryEmpty,
        tone: LuoboToastTone.info,
      );
      return;
    }

    setState(() {
      _isCaching = true;
      _currentProgress = 0;
      _totalSongs = songs.length;
    });

    try {
      await _bpmAnalyzer.cacheAllBPM(
        songs,
        onProgress: (current, total) {
          if (!mounted) return;
          setState(() {
            _currentProgress = current;
            _totalSongs = total;
          });
        },
      );
      if (!mounted) return;
      showLuoboToast(
        context,
        message: '${l10n.done} · ${l10n.cachedBpms} ${_bpmAnalyzer.getCachedCount()}',
        tone: LuoboToastTone.success,
      );
    } catch (e) {
      if (!mounted) return;
      showLuoboToast(
        context,
        message: '${l10n.operationFailed}: $e',
        tone: LuoboToastTone.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCaching = false;
          _currentProgress = 0;
          _totalSongs = 0;
        });
      }
    }
  }

  Widget _buildCacheAllButton() {
    return Column(
      children: [
        _buildDivider(),
        LuoboRow(
          title: AppLocalizations.of(context)!.cacheAllBpms,
          trailing: _isCaching ? const CupertinoActivityIndicator() : null,
          onTap: _isCaching ? null : () => _cacheAllBPMs(),
        ),
      ],
    );
  }

  Widget _buildClearCacheButton() {
    return Column(
      children: [
        _buildDivider(),
        LuoboRow(
          title: AppLocalizations.of(context)!.clearBpmCache,
          danger: true,
          onTap: () async {
            final l10n = AppLocalizations.of(context)!;
            final confirmed = await _confirmClear(
              l10n.clearBpmCache,
              '将清除本地 BPM 分析结果，下次播放时会重新分析。',
            );
            if (!confirmed || !mounted) return;
            await _bpmAnalyzer.clearCache();
            setState(() {});
            if (mounted) {
              showLuoboToast(
      context,
      message: l10n.bpmCacheCleared,
      tone: LuoboToastTone.info,
    );
            }
          },
        ),
      ],
    );
  }
}
