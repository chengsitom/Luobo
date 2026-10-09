import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;

/// Luobo 图标映射层。
///
/// **所有代码只引用 `AppIcons.xxx`，不直接引用 `CupertinoIcons` / `Icons`。**
/// 这样将来换图标集（或给桌面端单独换一套）只需要改这一个文件。
///
/// ## 为什么现在映射到 Cupertino / Material
///
/// 方案 §7 ⑮ 定的是「Lucide + `AppIcons` 映射层」。但实测
/// `lucide_icons 0.257.0` 与当前 Flutter **不兼容** ——
/// 新版 `IconData` 已是 `final class`，包里的
/// `class LucideIconData extends IconData` 直接编译失败（`flutter analyze`
/// 抓不到，`flutter test` 才暴露）。因此本轮**先落地映射层**，
/// 底层暂用项目既有的 Cupertino / Material 图标；等有兼容的线性图标包
/// （或自建 SVG 图标字体）时，**只改本文件**即可整体切换。
///
/// ⚠️ **「更多」有两种形态，别混用**（§2.3）：
/// - [moreH]（横向 `···`）—— **顶部悬浮圆钮内**
/// - [moreV]（纵向 `⋮`）—— **行内右侧**
///
/// ⚠️ 项目现状：`song_tile.dart` 用的是 `Icons.more_horiz`（横向），
/// 按 fnos 的**行内**规范应改为 [moreV]（纵向）。
abstract final class AppIcons {
  // ── 导航 ──────────────────────────────────────────────────────────────────
  static const IconData back = CupertinoIcons.chevron_back;
  static const IconData forward = CupertinoIcons.chevron_forward;
  static const IconData down = CupertinoIcons.chevron_down;

  /// 排序方向（直线箭头，区别于 chevron）。
  static const IconData arrowUp = CupertinoIcons.arrow_up;
  static const IconData arrowDown = CupertinoIcons.arrow_down;
  static const IconData close = CupertinoIcons.xmark;
  static const IconData moreH = CupertinoIcons.ellipsis;
  static const IconData moreV = CupertinoIcons.ellipsis_vertical;
  static const IconData check = CupertinoIcons.checkmark_alt;
  static const IconData search = CupertinoIcons.search;

  // ── 底栏 ──────────────────────────────────────────────────────────────────
  static const IconData home = CupertinoIcons.house;
  static const IconData library = CupertinoIcons.collections;
  static const IconData settings = CupertinoIcons.gear;

  // ── 播放 ──────────────────────────────────────────────────────────────────
  static const IconData play = CupertinoIcons.play_fill;
  static const IconData pause = CupertinoIcons.pause_fill;
  static const IconData skipBack = CupertinoIcons.backward_fill;
  static const IconData skipForward = CupertinoIcons.forward_fill;
  static const IconData repeat = CupertinoIcons.repeat;
  static const IconData shuffle = CupertinoIcons.shuffle;
  static const IconData queue = CupertinoIcons.music_note_list;
  static const IconData volume = CupertinoIcons.volume_up;
  static const IconData headphones = CupertinoIcons.headphones;
  static const IconData disc = CupertinoIcons.music_albums;

  /// 车载入口（**必须保持可见，不埋进「更多」**，§2.10）。
  static const IconData car = Icons.directions_car;

  // ── 内容 ──────────────────────────────────────────────────────────────────
  static const IconData music = CupertinoIcons.music_note;
  static const IconData album = CupertinoIcons.music_albums;
  static const IconData artist = CupertinoIcons.person;
  static const IconData genre = CupertinoIcons.waveform;
  static const IconData playlist = CupertinoIcons.music_note_list;
  static const IconData radio = CupertinoIcons.antenna_radiowaves_left_right;
  static const IconData book = CupertinoIcons.book;
  static const IconData heart = CupertinoIcons.heart;
  static const IconData heartFilled = CupertinoIcons.heart_fill;
  static const IconData star = CupertinoIcons.star;

  // ── 设置 · 播放与音质 ─────────────────────────────────────────────────────
  static const IconData playback = CupertinoIcons.play_circle;
  static const IconData streaming = CupertinoIcons.waveform;
  static const IconData playerUi = CupertinoIcons.slider_horizontal_3;
  static const IconData storage = CupertinoIcons.arrow_down_circle;
  static const IconData cache = CupertinoIcons.folder;

  // ── 设置 · 外观与显示 ─────────────────────────────────────────────────────
  static const IconData appearance = CupertinoIcons.paintbrush;
  static const IconData language = CupertinoIcons.globe;
  static const IconData themeLight = CupertinoIcons.sun_max;
  static const IconData themeDark = CupertinoIcons.moon_stars;

  // ── 设置 · 服务器 ─────────────────────────────────────────────────────────
  static const IconData server = CupertinoIcons.cloud;
  static const IconData scan = CupertinoIcons.viewfinder;
  static const IconData globe = CupertinoIcons.globe;
  static const IconData lock = CupertinoIcons.lock;
  static const IconData user = CupertinoIcons.person;
  static const IconData users = CupertinoIcons.person_2;
  static const IconData logout = CupertinoIcons.arrow_right_square;
  static const IconData tower = CupertinoIcons.antenna_radiowaves_left_right;

  // ── 设置 · AI 与智能 ──────────────────────────────────────────────────────
  static const IconData ai = CupertinoIcons.sparkles;
  static const IconData model = Icons.memory_rounded;
  static const IconData recommend = CupertinoIcons.chart_bar;

  // ── 设置 · 支持与关于 ─────────────────────────────────────────────────────
  static const IconData help = CupertinoIcons.question_circle;
  static const IconData info = CupertinoIcons.info;
  static const IconData shield = CupertinoIcons.lock_shield;
  static const IconData changelog = CupertinoIcons.doc_text;
  static const IconData diagnostics = Icons.monitor_heart_outlined;

  // ── 操作 ──────────────────────────────────────────────────────────────────
  static const IconData plus = CupertinoIcons.plus;
  static const IconData upload = CupertinoIcons.square_arrow_up;
  static const IconData trash = CupertinoIcons.trash;
  static const IconData edit = CupertinoIcons.pencil;
  static const IconData share = CupertinoIcons.share;
  static const IconData refresh = CupertinoIcons.refresh;
  static const IconData eye = CupertinoIcons.eye;
  static const IconData eyeOff = CupertinoIcons.eye_slash;

  // ── 列表控件 ──────────────────────────────────────────────────────────────
  static const IconData sort = CupertinoIcons.arrow_up_arrow_down;
  static const IconData viewList = CupertinoIcons.list_bullet;
  static const IconData viewGrid = CupertinoIcons.square_grid_2x2;
  static const IconData filter = CupertinoIcons.slider_horizontal_3;
  static const IconData folder = CupertinoIcons.folder;

  // ── 网络与状态 ────────────────────────────────────────────────────────────
  static const IconData wifi = Icons.wifi_rounded;
  static const IconData cell = Icons.signal_cellular_alt;
  static const IconData offline = CupertinoIcons.wifi_slash;

  // ── 空态插画用（大尺寸） ───────────────────────────────────────────────────
  static const IconData emptyDoc = CupertinoIcons.doc_text;
  static const IconData emptyMusic = CupertinoIcons.music_note;
  static const IconData emptySearch = CupertinoIcons.search;
}
