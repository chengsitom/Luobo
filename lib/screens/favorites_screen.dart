import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/glass_surface.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/subsonic_service.dart';
import '../services/playback_context_tracker.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';

/// 收藏页 —— **只列收藏的歌曲**。
///
/// 2026-10-08 拍板：**砍掉「专辑」tab**（连带 `LikedAlbumsScreen` 页面与音乐库
/// 「喜欢的专辑」入口）。理由是用户找不到入口、且收藏专辑没有使用价值。
/// 于是「收藏」的语义收窄为「收藏歌曲」（`starred.songs`），首页那张「收藏」卡的
/// 计数与这里从此同义。
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<Song> _favoriteSongs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    final subsonicService = Provider.of<SubsonicService>(
      context,
      listen: false,
    );

    try {
      final starred = await subsonicService.getStarred();
      if (mounted) {
        setState(() {
          _favoriteSongs = starred.songs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.favorites)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildSongsList(),
    );
  }

  Widget _buildSongsList() {
    if (_favoriteSongs.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.favorite_border, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(l10n.noFavoriteSongs),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 150),
      itemCount: _favoriteSongs.length,
      itemBuilder: (context, index) {
        final song = _favoriteSongs[index];
        return SongTile(
          song: song,
          playlist: _favoriteSongs,
          index: index,
          showAlbum: true,
          // 逐首播放也记录「最近播放的收藏列表」。
          onTap: () {
            _recordPlayback();
            Provider.of<PlayerProvider>(context, listen: false).playSong(
              song,
              playlist: _favoriteSongs,
              startIndex: index,
            );
          },
          onLongPress: () =>
              _showRemoveFromFavoritesDialog(context, song, index),
        );
      },
    );
  }

  /// 记录「最近播放的收藏列表」（首页最近播放混合区，§5.1）。
  void _recordPlayback() {
    final l10n = AppLocalizations.of(context)!;
    Provider.of<PlaybackContextTracker>(context, listen: false).record(
      kind: 'starred',
      id: 'starred',
      name: l10n.favorites,
      coverArts: _favoriteCovers(),
    );
  }

  List<String> _favoriteCovers() {
    final seen = <String>{};
    final out = <String>[];
    for (final song in _favoriteSongs) {
      final cover = song.coverArt;
      if (cover != null && cover.isNotEmpty && seen.add(cover)) {
        out.add(cover);
        if (out.length == 4) break;
      }
    }
    return out;
  }

  Future<void> _showRemoveFromFavoritesDialog(
    BuildContext context,
    Song song,
    int index,
  ) async {
    showGlassBottomSheet(
      context: context,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1C1C1E),
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white30,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.heart_broken, color: Colors.red),
                title: Text(
                  AppLocalizations.of(context)!.removeFromFavorites,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await _removeFromFavorites(song, index);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _removeFromFavorites(Song song, int index) async {
    // ⚠️ 必须走 `LibraryProvider.unstar`（它内部会 `loadStarred()` 刷新 `_starred`）：
    // 直连 `subsonicService.unstar` 时 provider 缓存不刷新，首页「收藏」卡的计数与
    // 随机取色会一直停在旧值，直到冷启动。
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    try {
      await libraryProvider.unstar(songId: song.id);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _favoriteSongs.removeAt(index);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.removedFromFavorites),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}
