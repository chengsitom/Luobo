import 'package:flutter/material.dart';

import 'playlist_form_sheet.dart';


/// 新建歌单命名对话框（公共版，`playlists_screen` 与 `song_tile` 的
/// 「添加到歌单」选择器共用，见 `docs/歌曲列表弹窗对标飞牛技术方案.md` §4.3）。
///
/// 已改为 fnos 模态表单（圆 × + 居中标题 + 玫红实心圆 ✓ + 输入卡，
/// `playlist_form_sheet.dart`）；调用方 API 不变。
Future<void> showCreatePlaylistDialog(BuildContext context) =>
    showPlaylistFormSheet(context);
