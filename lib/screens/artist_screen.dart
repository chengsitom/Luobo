import 'package:flutter/material.dart';
import '../widgets/luobo/luobo_toast.dart';
import '../l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import 'album_screen.dart';

class ArtistScreen extends StatefulWidget {
  final String artistId;

  const ArtistScreen({super.key, required this.artistId});

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Artist? _artist;
  List<Song> _topSongs = [];
  List<Album> _albums = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtistDetails();
  }

  Future<void> _loadArtistDetails() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );

    if (libraryProvider.isLocalOnlyMode) {
      try {
        final artist = libraryProvider.artists.firstWhere(
          (a) => a.id == widget.artistId,
          orElse: () => Artist(id: widget.artistId, name: 'Unknown Artist'),
        );
        final albums = await libraryProvider.getArtistAlbums(widget.artistId);

        final topSongs = libraryProvider.cachedAllSongs
            .where((s) => s.artistId == widget.artistId)
            .toList();

        if (mounted) {
          setState(() {
            _artist = artist;
            _topSongs = topSongs;
            _albums = albums;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
      return;
    }

    // ── Server mode: cache-first ──
    // Render immediately from the local library cache (artists / albums /
    // songs synced into SQLite), then refresh from the server in the
    // background so repeated entries don't block on the network.
    final cachedArtist = libraryProvider.artists.firstWhere(
      (a) => a.id == widget.artistId,
      orElse: () => Artist(id: widget.artistId, name: ''),
    );
    final cachedAlbums = libraryProvider.cachedAllAlbums
        .where((a) => a.artistId == widget.artistId)
        .toList();
    final cachedSongs = libraryProvider.cachedAllSongs
        .where((s) => s.artistId == widget.artistId)
        .toList();

    final hasCache = cachedArtist.name.isNotEmpty ||
        cachedAlbums.isNotEmpty ||
        cachedSongs.isNotEmpty;

    if (hasCache && mounted) {
      var artist = cachedArtist;
      if (artist.name.isEmpty) {
        final nameFromAlbum =
            cachedAlbums.isNotEmpty ? (cachedAlbums.first.artist ?? '') : '';
        artist = Artist(
          id: widget.artistId,
          name: nameFromAlbum.isNotEmpty
              ? nameFromAlbum
              : (cachedSongs.isNotEmpty
                  ? (cachedSongs.first.artist ?? '')
                  : ''),
        );
      }
      setState(() {
        _artist = artist;
        _albums = cachedAlbums;
        _topSongs = cachedSongs.take(50).toList();
        _isLoading = false;
      });
    }

    // Background refresh with fresh server data; never blocks the UI.
    await _loadArtistFromServer();
  }

  Future<void> _loadArtistFromServer() async {
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = libraryProvider.subsonicService;

    Artist? artist;
    List<Song> topSongs = [];
    List<Album> albums = [];

    try {
      artist = await subsonicService.getArtist(widget.artistId);
    } catch (e) {
      debugPrint('Error loading artist ${widget.artistId}: $e');
    }

    try {
      topSongs = await subsonicService.getArtistTopSongs(
        widget.artistId,
        artist: artist,
      );
    } catch (e) {
      debugPrint('Error loading top songs for ${widget.artistId}: $e');
    }

    try {
      albums = await subsonicService.getArtistAlbums(
        widget.artistId,
        artist: artist,
      );
    } catch (e) {
      debugPrint('Error loading albums for ${widget.artistId}: $e');
    }

    if (albums.isEmpty) {
      albums = libraryProvider.cachedAllAlbums
          .where((a) => a.artistId == widget.artistId)
          .toList();
    }
    if (topSongs.isEmpty) {
      topSongs = libraryProvider.cachedAllSongs
          .where((s) => s.artistId == widget.artistId)
          .take(50)
          .toList();
    }

    if (!mounted) return;
    setState(() {
      if (artist != null) _artist = artist;
      _topSongs = topSongs;
      _albums = albums;
      _isLoading = false;
    });
  }

  Future<void> _addArtistToQueue() async {
    if (_albums.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);
    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    final subsonicService = libraryProvider.subsonicService;

    final messenger = ScaffoldMessenger.of(context);
    final loc = AppLocalizations.of(context);

    try {
      final songsToQueue = <Song>[];
      for (final album in _albums) {
        final albumSongs = libraryProvider.isLocalOnlyMode
            ? libraryProvider.cachedAllSongs
                .where((s) => s.albumId == album.id)
                .toList()
            : await subsonicService.getAlbumSongs(album.id);

        songsToQueue.addAll(albumSongs);
      }

      if (songsToQueue.isNotEmpty) {
        playerProvider.addAllToQueue(songsToQueue);
      }

      if (!mounted) return;

      final addedToQueueMessage =
          loc?.addedArtistToQueue ?? 'Added artist to Queue';
      showLuoboToast(
      context,
      message: addedToQueueMessage,
      tone: LuoboToastTone.info,
    );
    } catch (e) {
      if (!mounted) return;

      final addedToQueueErrorMessage =
          loc?.addedArtistToQueueError ?? 'Failed adding artist to Queue';
      showLuoboToast(
      context,
      message: addedToQueueErrorMessage,
      tone: LuoboToastTone.info,
    );
    }
  }

  void _playTopSongs({bool shuffle = false}) {
    if (_topSongs.isEmpty) return;

    final playerProvider = Provider.of<PlayerProvider>(context, listen: false);

    var songs = List<Song>.from(_topSongs);
    if (shuffle) {
      songs.shuffle();
    }

    playerProvider.playSong(songs.first, playlist: songs, startIndex: 0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_artist == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(AppLocalizations.of(context)!.artistDataNotFound),
        ),
      );
    }

    final libraryProvider = Provider.of<LibraryProvider>(
      context,
      listen: false,
    );
    // Fall back to one of the artist's album covers when the server has no
    // artist image, so the header isn't an empty gradient.
    final artistCover = libraryProvider.getArtistCoverArt(_artist!);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 200,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(_artist!.name),
              background: artistCover != null
                  ? ShaderMask(
                      shaderCallback: (rect) {
                        return LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                        ).createShader(
                          Rect.fromLTRB(0, 0, rect.width, rect.height),
                        );
                      },
                      blendMode: BlendMode.dstIn,
                      child: AlbumArtwork(
                        coverArt: artistCover,
                        size: 200,
                      ),
                    )
                  : Container(
                      color: AppTheme.appleMusicRed.withValues(alpha: 0.15),
                      child: const Center(
                        child: Icon(
                          CupertinoIcons.mic_fill,
                          size: 64,
                          color: AppTheme.appleMusicRed,
                        ),
                      ),
                    ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.queue_music_rounded),
                tooltip: AppLocalizations.of(context)!.addToQueue,
                onPressed: _albums.isEmpty ? null : () => _addArtistToQueue(),
              ),
            ],
          ),
          if (_topSongs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _PlayButton(
                        icon: CupertinoIcons.play_fill,
                        label: AppLocalizations.of(context)!.play,
                        onTap: () => _playTopSongs(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _PlayButton(
                        icon: CupertinoIcons.shuffle,
                        label: AppLocalizations.of(context)!.shuffle,
                        onTap: () => _playTopSongs(shuffle: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_topSongs.isNotEmpty) ...[
                    Text(
                      AppLocalizations.of(context)!.topSongs,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _topSongs.take(5).length,
                      itemBuilder: (context, index) {
                        final song = _topSongs[index];
                        return SongTile(
                          song: song,
                          playlist: _topSongs,
                          index: index,
                          showAlbum: true,
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                  Builder(
                    builder: (context) {
                      // Categorize albums by song count
                      final albums = _albums
                          .where((a) => (a.songCount ?? 0) >= 7)
                          .toList();
                      final eps = _albums.where((a) {
                        final count = a.songCount ?? 0;
                        return count >= 3 && count <= 6;
                      }).toList();
                      final singles = _albums
                          .where((a) => (a.songCount ?? 0) <= 2)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (albums.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.sectionAlbums,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: albums.length,
                              itemBuilder: (context, index) {
                                final album = albums[index];
                                return AlbumCard(
                                  album: album,
                                  size: double.infinity,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AlbumScreen(albumId: album.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (eps.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.sectionEPs,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: eps.length,
                              itemBuilder: (context, index) {
                                final album = eps[index];
                                return AlbumCard(
                                  album: album,
                                  size: double.infinity,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AlbumScreen(albumId: album.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 24),
                          ],
                          if (singles.isNotEmpty) ...[
                            Text(
                              AppLocalizations.of(context)!.sectionSingles,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: singles.length,
                              itemBuilder: (context, index) {
                                final album = singles[index];
                                return AlbumCard(
                                  album: album,
                                  size: double.infinity,
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AlbumScreen(albumId: album.id),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PlayButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = Theme.of(context).colorScheme.primary;

    return Material(
      color: accent.withValues(alpha: isDark ? 0.15 : 0.1),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
