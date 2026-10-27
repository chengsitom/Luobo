import '../models/artist.dart';
import '../providers/library_provider.dart';

/// 歌手的歌曲数 / 专辑数统计（列表副题与排序共用）。
///
/// 只按 `song.artistId` 统计会缺两类：①服务端 artists 与 tracks 的 id 体系
/// 不一致（道理鱼）；②合唱曲里非第一顺位的歌手。所以同时按名字统计并取较大值。
class ArtistStats {
  const ArtistStats._();

  static Map<String, int> songCounts(
    List<Artist> artists,
    LibraryProvider libraryProvider,
  ) {
    final idCounts = <String, int>{};
    final nameCounts = <String, int>{};
    final albumIdSums = <String, int>{};
    final albumNameSums = <String, int>{};

    void addName(String name) {
      final key = name.trim().toLowerCase();
      if (key.isEmpty) return;
      nameCounts[key] = (nameCounts[key] ?? 0) + 1;
    }

    for (final song in libraryProvider.cachedAllSongs) {
      final id = song.artistId;
      if (id != null && id.isNotEmpty) {
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
      final participants = song.artistParticipants;
      if (participants != null && participants.isNotEmpty) {
        for (final p in participants) {
          addName(p.name);
        }
      } else {
        final artistName = song.artist;
        if (artistName != null && artistName.isNotEmpty) {
          for (final part
              in artistName.split(RegExp(r'\s*(?:/|,|&|、|;)\s*'))) {
            addName(part);
          }
        }
      }
    }

    for (final album in libraryProvider.cachedAllAlbums) {
      final count = album.songCount ?? 0;
      if (count <= 0) continue;
      final id = album.artistId;
      if (id != null && id.isNotEmpty) {
        albumIdSums[id] = (albumIdSums[id] ?? 0) + count;
      }
      final name = album.artist?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        albumNameSums[name] = (albumNameSums[name] ?? 0) + count;
      }
    }

    return {
      for (final artist in artists)
        artist.id: _max4(
          idCounts[artist.id] ?? 0,
          nameCounts[artist.name.trim().toLowerCase()] ?? 0,
          albumIdSums[artist.id] ?? 0,
          albumNameSums[artist.name.trim().toLowerCase()] ?? 0,
        ),
    };
  }

  static Map<String, int> albumCounts(
    List<Artist> artists,
    LibraryProvider libraryProvider,
  ) {
    final idCounts = <String, int>{};
    final nameCounts = <String, int>{};
    for (final album in libraryProvider.cachedAllAlbums) {
      final id = album.artistId;
      if (id != null && id.isNotEmpty) {
        idCounts[id] = (idCounts[id] ?? 0) + 1;
      }
      final name = album.artist?.trim().toLowerCase();
      if (name != null && name.isNotEmpty) {
        nameCounts[name] = (nameCounts[name] ?? 0) + 1;
      }
    }
    return {
      for (final artist in artists)
        artist.id: artist.albumCount ??
            _max(
              idCounts[artist.id] ?? 0,
              nameCounts[artist.name.trim().toLowerCase()] ?? 0,
            ),
    };
  }

  static int _max(int a, int b) => a > b ? a : b;

  static int _max4(int a, int b, int c, int d) =>
      _max(_max(a, b), _max(c, d));
}
