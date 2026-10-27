import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_icons.dart';
import '../../theme/design_tokens.dart';
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
///   body: ListView(padding: EdgeInsets.only(top: listTopInset(context)), ...),
/// )
/// ```
/// ⚠️ 页面 body/滚动内容要自带 `MediaQuery.padding.top + 56` 的顶部留白，
/// 否则首行会被圆钮压住。
///
/// 2026-10-24 起支持 [title]：传了标题就把返回圆钮换成**「返回 + 标题」胶囊**
/// （同歌手详情折叠后的形态，见 `artist_screen.dart` 的 `_buildBackPill`），
/// 标题不再单独占一行居中显示 —— 设置页全体子页面走这一套。
class LuoboListTopBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Widget> actions;

  /// 非空 → 返回钮渲染成「返回 + 标题」胶囊（左侧）；空 → 只有 40dp 圆钮。
  final String? title;

  /// 顶栏透明时状态栏图标的明暗 —— 只有「整页是相机/深色底」的页面需要传
  /// （如扫码页），普通页面保持默认（跟随主题）。
  final SystemUiOverlayStyle? systemOverlayStyle;

  const LuoboListTopBar({
    super.key,
    this.actions = const [],
    this.title,
    this.systemOverlayStyle,
  });

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.isNotEmpty;

    return AppBar(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: systemOverlayStyle,
      automaticallyImplyLeading: false,
      titleSpacing: 16,
      title: Align(
        alignment: Alignment.centerLeft,
        child: hasTitle
            ? LuoboBackTitlePill(title: title!)
            : LuoboTopCircleButton(
                icon: AppIcons.back,
                onTap: () => Navigator.of(context).maybePop(),
              ),
      ),
      actions: [...actions, const SizedBox(width: 16)],
    );
  }
}

/// 「返回 + 标题」胶囊（40dp 高、左右圆角 20）—— 顶栏里替代「返回圆钮 + 居中
/// 标题」两件套：标题跟着返回钮走，页面因此不再有第二条标题栏。
///
/// 视觉与歌手详情折叠后的返回胶囊一致（40dp、白 0.72 / 黑 0.45、0.8 描边、
/// 17dp 箭头、15/w600 标题），只是这里**始终**显示标题（静态页无需随滚动展开）。
class LuoboBackTitlePill extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  const LuoboBackTitlePill({super.key, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = isDark ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: onTap ?? () => Navigator.of(context).maybePop(),
      child: Container(
        height: 40,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.black.withValues(alpha: 0.45)
              : Colors.white.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 10),
            Icon(AppIcons.back, size: 17, color: fg),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: LuoboType.body.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
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

/// **滚动内容**的顶部净空：给 body 里的 `ListView`/`CustomScrollView` 的
/// `padding.top` 加分（`top: 16 + listScrollTopInset(context)`）。
///
/// 与 [listTopInset] 的分工（**别用错，两者差 56**）：
/// - 滚动视图在 **Scaffold body 内**构造（设置 tab 身体 `SettingsDisplayTab` 等，
///   作为 `body:` 独立 widget 传入）→ 用本函数：Scaffold 已把「状态栏 + 56」
///   写进 body 的 `MediaQuery.padding.top`，直接取用即可。
/// - 滚动视图与 `SettingsSubPage` 在**同一个 build** 里构造（`body: ListView(...)`
///   直接写在页面里，如「关于」「服务器详情」「已连接的服务器」）→ 该 context 还在
///   Scaffold 之上，MediaQuery 只有状态栏高度，必须用 [listTopInset]（自己加 56）。
///
/// ⚠️ 顶栏净空必须落在**滚动视图自己的 padding** 里，不能用外层 `Padding` 包 body：
/// 外层 `Padding` 会让滚动视图整体下移、内容在顶栏下沿被裁断，滚动时看起来就是
/// 「一条不透明导航栏」（2026-10-24 用户指出「播放器界面滑动后还是有不透明导航栏」）。
double listScrollTopInset(BuildContext context) =>
    MediaQuery.paddingOf(context).top;

/// 顶栏右侧的圆形搜索钮（40dp，同返回钮）。
class LuoboTopSearchButton extends StatelessWidget {
  final VoidCallback onTap;

  const LuoboTopSearchButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LuoboTopCircleButton(icon: AppIcons.search, onTap: onTap);
  }
}
