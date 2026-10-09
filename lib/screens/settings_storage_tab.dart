import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../utils/byte_format.dart';
import '../utils/image_cache.dart';
import '../providers/library_provider.dart';
import '../services/bpm_analyzer_service.dart';
import '../services/cache_settings_service.dart';
import '../services/local_music_service.dart';
import '../services/offline_service.dart';
import '../theme/app_theme.dart';
import '../theme/design_tokens.dart';
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
  bool _musicCacheEnabled = true;
  final bool _isCaching = false;
  final int _currentProgress = 0;
  final int _totalSongs = 0;
  int _downloadedCount = 0;
  String _downloadedSize = '0 B';
  String _imageCacheSize = '—';
  int _parallelDownloads = 3;
  bool _keepScreenOn = true;

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
    });
  }

  Future<void> _loadSettings() async {
    await _cacheSettings.initialize();
    await _offlineService.initialize();
    await _loadOfflineInfo();
    await _loadCacheSizes();

    setState(() {
      _imageCacheEnabled = _cacheSettings.getImageCacheEnabled();
      _musicCacheEnabled = _cacheSettings.getMusicCacheEnabled();
      _parallelDownloads = _offlineService.getParallelDownloadsCount();
      _keepScreenOn = _offlineService.getKeepScreenOn();
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
      padding: const EdgeInsets.symmetric(vertical: 16),
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
            _buildDivider(),
            _buildCacheToggle(
              icon: CupertinoIcons.music_note,
              title: AppLocalizations.of(context)!.musicCacheTitle,
              subtitle: AppLocalizations.of(context)!.musicCacheSubtitle,
              value: _musicCacheEnabled,
              onChanged: _toggleMusicCache,
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
            _buildOfflineInfo(),
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

  void _toggleMusicCache(bool value) async {
    setState(() => _musicCacheEnabled = value);
    await _cacheSettings.setMusicCacheEnabled(value);
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.addedFolder(path))),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.folderRemoved)),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.storagePermissionRequired)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allCacheCleared)),
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
      showChevron: false,
    );
  }

  Widget _buildDeleteDownloadsButton() {
    return LuoboRow(
      icon: CupertinoIcons.trash_fill,
      title: AppLocalizations.of(context)!.deleteDownloads,
      danger: true,
      onTap: () async {
        await _offlineService.deleteAllDownloads();
        await _loadOfflineInfo();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.downloadsDeleted),
            ),
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

  Widget _buildCacheAllButton() {
    return Column(
      children: [
        _buildDivider(),
        LuoboRow(
          title: AppLocalizations.of(context)!.cacheAllBpms,
          trailing: _isCaching ? const CupertinoActivityIndicator() : null,
          onTap: _isCaching ? null : () {},
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.bpmCacheCleared),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
