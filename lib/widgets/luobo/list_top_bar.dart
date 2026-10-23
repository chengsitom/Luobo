import 'package:flutter/material.dart';

import '../../theme/app_icons.dart';
import 'hero_detail_header.dart';

/// 列表页顶栏 —— **与收藏页同款**（用户 2026-10-23：「顶部导航栏要和收藏页
/// 一样的效果」）：
///
/// **没有实色栏、没有居中标题**，只有一排悬浮的 40dp 圆钮（左返回 + 右动作），
/// 内容从圆钮下方流过。用法：
/// ```dart
/// Scaffold(
///   extendBodyBehindAppBar: true,
///   appBar: LuoboListTopBar(actions: [...]),
///   body: ListView(padding: EdgeInsets.only(top: 顶部留白 + 56), ...),
/// )
/// ```
/// ⚠️ 页面 body/滚动内容要自带 `MediaQuery.padding.top + 56` 的顶部留白，
/// 否则首行会被圆钮压住。
class LuoboListTopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> actions;

  const LuoboListTopBar({super.key, this.actions = const []});

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: LuoboTopCircleButton(
            icon: AppIcons.back,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      title: const SizedBox.shrink(),
      actions: [...actions, const SizedBox(width: 16)],
    );
  }
}

/// 顶部留白：状态栏 + 顶栏（56）。给列表页的滚动内容用，避免首行被圆钮压住。
///
/// ⚠️ **必须在 Scaffold 之外调用**（`build` 顶部算好再传进去）。
/// 实测：`extendBodyBehindAppBar: true` 时，Scaffold 会把 AppBar 高度叠加进
/// **body 的 `MediaQuery.padding.top`**（body 内 padding = 状态栏 + 56）——
/// 在 body/Consumer 内部调用本函数会把顶栏算两遍，内容整体下沉 56dp
/// （歌手列表「离顶部很远」就是这个原因）。
double listTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top + 56;

/// 顶栏右侧的圆形搜索钮（40dp，同返回钮）。
class LuoboTopSearchButton extends StatelessWidget {
  final VoidCallback onTap;

  const LuoboTopSearchButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LuoboTopCircleButton(icon: AppIcons.search, onTap: onTap);
  }
}
