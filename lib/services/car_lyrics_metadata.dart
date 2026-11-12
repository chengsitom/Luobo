/// 「蓝牙/车机歌词」的媒体信息构造（纯函数，可单测）。
///
/// 背景：部分车机（以及 CarLife 一类投射）只把**媒体标题**当成主行展示，副标题
/// 字段（`DISPLAY_SUBTITLE`）根本不读。实测最稳的做法是反过来利用这一点：
///
/// | 字段 | 平时 | 开启后 |
/// |---|---|---|
/// | 标题 | 歌名 | **当前歌词行** |
/// | 艺人 | 艺人 | 「歌名 - 艺人」 |
/// | 专辑 | 专辑名 | 「歌名 - 艺人」（保留可识别性，否则只剩一句歌词） |
///
/// 这样车机屏就会随播放逐句刷新，而用户仍能从艺人/专辑行看出是哪首歌。
///
/// 注意：这是**有损**替换——真正的专辑名在车机上不再可见。所以它是可开关的
/// 选项（默认关），且只作用于蓝牙链路。
library;

/// 车机上要发布的三段文本。
class CarLyricMetadata {
  const CarLyricMetadata({
    required this.title,
    required this.artist,
    required this.album,
  });

  final String title;
  final String artist;
  final String album;

  @override
  String toString() => 'CarLyricMetadata($title / $artist / $album)';
}

/// 艺人/专辑行显示的「歌名 - 艺人」。艺人缺失时退化为歌名。
///
/// `Unknown Artist` 视为缺失：服务端没写艺人时到处是这串占位，把它带到车机上
/// 只会浪费半行空间。
String carTrackLabel({required String songTitle, String? artist}) {
  final title = songTitle.trim();
  var name = (artist ?? '').trim();
  if (name.toLowerCase() == 'unknown artist') name = '';
  if (name.isEmpty) return title;
  if (title.isEmpty) return name;
  return '$title - $name';
}

/// 生成开启「蓝牙歌词」后要发布的媒体信息；没有歌词行时返回 null
/// （调用方据此回落成正常 metadata，车机就会显示歌名）。
CarLyricMetadata? buildCarLyricMetadata({
  required String? line,
  required String songTitle,
  String? artist,
}) {
  final trimmed = (line ?? '').trim();
  if (trimmed.isEmpty) return null;
  final label = carTrackLabel(songTitle: songTitle, artist: artist);
  return CarLyricMetadata(title: trimmed, artist: label, album: label);
}
