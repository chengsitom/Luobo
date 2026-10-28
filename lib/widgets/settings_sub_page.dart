import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'luobo/scroll_reveal_scaffold.dart';

/// 设置二级页薄壳。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/01-C1-二级页骨架对比.png`。
///
/// 2026-10-24 用户拍板：**设置页与所有设置子页的顶栏统一成歌单列表页那一套**
/// （透明顶栏 + 悬浮圆钮，内容从钮下方流过）。
///
/// | | 旧（C1 骨架） | 现在 |
/// |---|---|---|
/// | 返回 | 玻璃圆钮 | 列表页 40dp 圆钮 |
/// | 标题 | 15px **居中**，单独占一条实色页头 | **收进返回胶囊**（同歌手详情折叠态） |
/// | 右上 | 槽位 | 列表页圆钮槽位 |
///
/// 2026-10-27 用户要求：**没上滑时不带标题**，上滑到一定程度再把标题收进返回胶囊。
/// 统一交给 [ScrollRevealScaffold] 处理，所有设置子页同时生效：
/// - 可滚动页面：初始只有返回圆钮，滚动超过阈值后显示「返回 + 标题」；
/// - 内容不满一屏：没有上滑机会，保留标题，避免短页面完全看不到页名。
///
/// 改这一处，**所有二级页同时生效**。各 tab 的身体（`SettingsPlaybackTab` 等）
/// 保持不变，只换外壳。
///
/// ⚠️ 二级页**没有底栏**（一级页才有）；若有歌曲在播，底部是悬浮播放条，
/// 由 `MainScreen` 之外的路由自行决定，本壳不负责。
class SettingsSubPage extends StatelessWidget {
  const SettingsSubPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.trailing,
  });

  final String title;
  final Widget body;

  /// 右上角动作钮（如保存 ✓）。会排在 [trailing] 左边。
  final List<Widget>? actions;

  /// 右上角单个动作钮（便捷）。
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    // ⚠️ body 不加外层 `Padding`：顶栏净空要落在**各 body 自己的滚动 padding**
    // 里（`listScrollTopInset`），内容才会从圆钮下方流过。包一层 Padding 会让
    // 滚动内容在顶栏下沿被裁断，看起来是一条不透明栏（2026-10-24 用户指出）。
    return ScrollRevealScaffold(
      title: title,
      body: body,
      actions: actions,
      trailing: trailing,
      backgroundColor: LuoboColors.of(context).bg,
    );
  }
}
