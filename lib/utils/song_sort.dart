import '../models/song.dart';

/// 排序**字段**（「字段 + 方向」两维度，替代原先 7 个扁平枚举值）。
///
/// 见 `docs/锚定浮层与列表页排序技术方案.md` §4。
/// [recentlyAdded] 自带方向（新的在前），不参与升/降切换。
enum SongSortField { title, artist, album, recentlyAdded }

/// 每个字段**一个** comparator（原来是 7 个 case 里升降各写一遍）。
int Function(Song, Song) songComparator(SongSortField field) {
  switch (field) {
    case SongSortField.title:
      return (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase());
    case SongSortField.artist:
      return (a, b) => (a.artist ?? '')
          .toLowerCase()
          .compareTo((b.artist ?? '').toLowerCase());
    case SongSortField.album:
      return (a, b) => (a.album ?? '')
          .toLowerCase()
          .compareTo((b.album ?? '').toLowerCase());
    case SongSortField.recentlyAdded:
      return (a, b) {
        final aCreated = a.created;
        final bCreated = b.created;
        if (aCreated == null && bCreated == null) return 0;
        if (aCreated == null) return 1;
        if (bCreated == null) return -1;
        return bCreated.compareTo(aCreated);
      };
  }
}

/// 按 [field] + [ascending] 排序（返回新列表，不改动入参）。
///
/// ⚠️ [SongSortField.recentlyAdded] 的 comparator **自带方向**（新的在前、
/// `created == null` 排最后），所以对它**不能再取反** —— 传进来的 [ascending]
/// 对它无效，与 [songSortShowsDirection] 隐藏方向箭头保持一致。
List<Song> sortSongs(
  List<Song> songs,
  SongSortField field, {
  bool ascending = true,
}) {
  final out = List<Song>.from(songs);
  if (field == SongSortField.recentlyAdded) {
    out.sort(songComparator(field));
    return out;
  }
  final compare = songComparator(field);
  out.sort((a, b) {
    final r = compare(a, b);
    return ascending ? r : -r;
  });
  return out;
}

/// `recentlyAdded` 不显示方向箭头（方向固定）。
bool songSortShowsDirection(SongSortField field) =>
    field != SongSortField.recentlyAdded;
