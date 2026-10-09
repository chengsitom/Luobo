/// Luobo 设计体系 · Token 全表。
///
/// 取值来源：设计稿 `~/Downloads/fnosmusic/设计稿/04-C1-地基组件总览.png`
/// 与 `docs/视觉与交互对标飞牛音乐技术方案.md` §2.1 / §2.9。
///
/// ⚠️ **改这里 = 改全 App**。页面里不要再写死颜色 / 圆角 / 时长 / 玻璃参数。
/// ⚠️ 深色模式**只换颜色，不换结构**（圆角 / 间距 / 字阶 / 玻璃模糊值完全相同）。
library;

import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 颜色
// ─────────────────────────────────────────────────────────────────────────────

/// 按主题亮度取色。`LuoboColors.of(context).card`。
@immutable
class LuoboColors {
  const LuoboColors({
    required this.bg,
    required this.card,
    required this.fg,
    required this.fg2,
    required this.fg3,
    required this.divider,
    required this.pillFill,
    required this.glassTint,
    required this.glassBorder,
    required this.glassShadow,
    required this.isDark,
  });

  /// 页面底色。
  final Color bg;

  /// 卡片底色（分组卡 / sheet / 行）。
  final Color card;

  /// 主文字 / 主图标。
  final Color fg;

  /// 副文字：状态值、副标题、行下说明。
  final Color fg2;

  /// 三级文字：chevron、占位符。
  final Color fg3;

  /// 分隔线。
  final Color divider;

  /// 独立胶囊按钮底色（如「退出登录」）。
  final Color pillFill;

  /// 玻璃 tint（叠在 `backdrop-filter` 之上）。
  final Color glassTint;

  /// 玻璃描边（0.8px）。
  final Color glassBorder;

  /// 玻璃元素阴影。
  final List<BoxShadow> glassShadow;

  final bool isDark;

  static const LuoboColors light = LuoboColors(
    bg: Color(0xFFF2F2F7),
    card: Color(0xFFFFFFFF),
    fg: Color(0xFF000000),
    fg2: Color(0xFF8E8E93),
    fg3: Color(0xFFC7C7CC),
    divider: Color(0xFFE5E5EA),
    pillFill: Color(0xFFE5E5E7),
    glassTint: Color(0xA6FFFFFF), // white .65
    glassBorder: Color(0xCCFFFFFF), // white .80
    glassShadow: [
      BoxShadow(color: Color(0x24000000), blurRadius: 28, offset: Offset(0, 6)),
    ],
    isDark: false,
  );

  static const LuoboColors dark = LuoboColors(
    bg: Color(0xFF121212),
    card: Color(0xFF1C1C1E),
    fg: Color(0xFFFFFFFF),
    fg2: Color(0xFF98989E),
    fg3: Color(0xFF6B6B6B),
    divider: Color(0xFF38383A),
    pillFill: Color(0xFF2C2C2E),
    glassTint: Color(0x80000000), // black .50
    glassBorder: Color(0x1AFFFFFF), // white .10
    glassShadow: [
      BoxShadow(color: Color(0x80000000), blurRadius: 28, offset: Offset(0, 6)),
    ],
    isDark: true,
  );

  static LuoboColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

/// 语义色。**不随主题变**（深色下同样是玫红）。
abstract final class LuoboAccent {
  /// 强调色：选中态 / 勾 / 危险 / chip / 图标。**不做大面积填充**。
  static const Color accent = Color(0xFFF0305C);

  /// 强调色淡底（chip、淡底图标块、危险按钮底）。
  static Color soft([double alpha = 0.12]) => accent.withValues(alpha: alpha);

  /// 网络：WiFi / 蜂窝。
  static const Color wifi = Color(0xFF34C759);
  static const Color cell = Color(0xFFFF9500);

  /// 转码中 / 已转码（橙）。
  static const Color warnLight = Color(0xFFE65100);
  static const Color warnDark = Color(0xFFFFB74D);

  static Color warn(BuildContext context) =>
      warnFor(Theme.of(context).brightness == Brightness.dark);

  /// 没有 `BuildContext` 的场景（纯数据层 / 已算出 isDark）用这个重载。
  /// [warn] 内部转调它，保证深浅档只有一处定义。
  static Color warnFor(bool isDark) => isDark ? warnDark : warnLight;

  /// 服务端状态正常。
  ///
  /// ⚠️ 与 [wifi] 当前同值，但**语义不同**（服务器健康 vs 网络类型），
  /// 独立声明 —— 否则改网络色会静默连带状态指示色。
  static const Color ok = Color(0xFF34C759);

  /// 强调色的**浅端** —— 渐变头图 / App 图标用（设计稿 `03-设置二级页全量` A7）。
  static const Color accentLight = Color(0xFFFF6B6B);

  /// 叠加在**强调色 / 服务器色渐变之上**的前景色（白）。
  static const Color onAccent = Colors.white;

  /// 账号卡头像渐变（根页账号卡）。
  static const List<Color> avatarGradient = [
    Color(0xFF7FD4C1),
    Color(0xFF5BC0DE),
  ];

  /// 服务器家族品牌色（类型网格 / 徽标）。
  ///
  /// ⚠️ 与 `widgets/server_profile_card.dart` 的 `ServerFamilyInfo` 是同一组色值。
  /// 那个文件与**登录网关页共用、不许改**，所以色值在此处再声明一份作为页面侧
  /// 的单一来源；改动时两处要一起改。
  static const Color familySubsonic = Color(0xFF6366F1);
  static const Color familyJellyfin = Color(0xFFA970FF);
  static const Color familyDaoliyu = Color(0xFF34C759);
}

// ─────────────────────────────────────────────────────────────────────────────
// 圆角
// ─────────────────────────────────────────────────────────────────────────────

/// 圆角只有 4 档，别再造新值。
abstract final class LuoboRadius {
  /// 卡片 / 行 / 小方块。**飞牛实测 42px @3x ≈ 14dp**。
  static const double card = 14;

  /// 分组容器（大卡）。
  static const double group = 20;

  /// 胶囊（底栏 / 按钮 / chip / 输入胶囊）。
  static const double pill = 30;

  /// 圆形。
  static const double full = 999;

  // ── 组件内部圆角 ─────────────────────────────────────────────────────────
  // 上面 4 档是**页面级**圆角；下面是**组件内部**的小圆角，取自设计稿。
  // 页面里不要再写死这些值。

  /// 输入框（设计稿 B2 `.inp`）。
  static const double field = 13;

  /// 类型网格 tile（设计稿 B3 `.tile`）。
  static const double tile = 14;

  /// Sheet 内的行卡。
  static const double sheetRow = 14;

  /// 头像 / 服务器徽标。
  static const double avatar = 10;

  /// 小徽章 / 图标块。
  static const double badge = 8;

  /// 关于页 App 图标。
  static const double appIcon = 18;

  /// 把手 / 细条。
  static const double handle = 2;

  /// 开关轨道。
  static const double switchTrack = 10;

  static BorderRadius get cardR => BorderRadius.circular(card);
  static BorderRadius get groupR => BorderRadius.circular(group);
  static BorderRadius get pillR => BorderRadius.circular(pill);

  /// Sheet 顶部圆角（与 [group] 同值，引用以免各改各的）。
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(group),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 间距
// ─────────────────────────────────────────────────────────────────────────────

abstract final class LuoboSpacing {
  /// 页面左右边距。
  static const double pageX = 16;

  /// 行内左右内边距（飞牛实测 48px @3x = 16dp）。
  static const double rowX = 16;

  /// 行上下内边距（单行行高 ≈ 52）。
  static const double rowY = 13;

  /// 行图标位宽（不含与文字的间距）。
  static const double iconSlot = 20;

  /// 图标与文字的间距（飞牛实测：文字起点 46.3dp = 16 + 20 + 10）。
  static const double iconGap = 10;

  /// 卡与卡之间（飞牛实测 42px @3x = 14dp；设计稿写 15，取 15）。
  static const double cardGap = 15;

  /// 小节标题与卡的间距。
  static const double sectionGap = 7;

  /// 行下说明与卡的视觉间距（负外边距让说明贴紧上方卡）。
  static const double hintGap = 9;

  /// 卡片内**非标准行**内容的上下内边距（账号卡 / 色点行等）。
  static const double cardPadY = 16;

  /// 二级页 `ListView` 的顶部留白。
  static const double pageY = 8;

  /// 二级页 `ListView` 的底部留白。
  static const double pageBottom = 32;

  /// 渐变头图（服务器详情）的上下内边距。
  static const double headerY = 22;

  /// 锚定菜单的每项高度（飞牛排序浮层实测 129px/2 项 ≈ 64dp）。
  static const double menuItemHeight = 64;

  /// 分隔线缩进（左右各一份）。
  ///
  /// ⚠️ **飞牛实测：分隔线与行内边距对齐（左右各 16dp），不缩进到文字起点** ——
  /// 有图标时也一样（分隔线从图标左边穿过）。早先设计稿写的「缩进到文字起点 43」
  /// 是错的，已按实测修正。
  static const double dividerInsetWithIcon = rowX;
  static const double dividerInsetPlain = rowX;

  /// 单行 / 双行行高（飞牛实测单行 149px @3x ≈ 50dp）。
  static const double rowHeight = 50;
  static const double rowHeightTwoLine = 62;
}

// ─────────────────────────────────────────────────────────────────────────────
// 字阶
// ─────────────────────────────────────────────────────────────────────────────

abstract final class LuoboType {
  /// 大标题页标题（当前只被设置根页使用）。
  ///
  /// ⚠️ 飞牛实测（2026-10-08 同机复核，见 `docs/设置页重构技术方案.md` §9.21.1）：
  /// 字号 **20dp**（墨宽 113 vs 参照 115）、字重 **Semibold(600)**（墨密度 0.488 与
  /// Semibold 参照**完全吻合**）→ 由 `w700` 改为 `w600`。
  static const TextStyle display = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    height: 1.1,
  );

  /// 二级页居中标题（飞牛实测 ≈17–17.5dp / Semibold(600)）。
  static const TextStyle navTitle = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
  );

  /// 行主文字。
  ///
  /// ⚠️ 飞牛实测（同机同字体、量同一串「服务器」）：墨宽 122 vs 本实现 123 → **字号一致**；
  /// 但墨密度 0.396 vs 0.337、笔画 5.50px vs 4.55px → **飞牛重约一档**。故补 `w500`。
  static const TextStyle body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// 状态值 / 右侧值（飞牛实测 ≈14dp，**与行标题同号**，只靠灰色区分）。
  static const TextStyle value = TextStyle(fontSize: 14);

  /// 小节标题。
  ///
  /// ⚠️ 飞牛设置族**没有小节标题**（11 张截图逐张看过），本项**无对标**，保持原值。
  static const TextStyle section = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w500,
  );

  /// 副标题 / 行下说明 / 空态文案（飞牛实测 **12dp**：副标题「公网连接」墨宽 141 ÷ 3.92 字）。
  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.5);

  /// 胶囊按钮文字。
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  /// 区块标题（首页「最近播放」等）。
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  /// 账号卡用户名（根页账号卡）。
  static const TextStyle accountName = TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
  );

  // ── 组件内部字阶 ─────────────────────────────────────────────────────────
  // 上面是页面级字阶；下面是组件 / 局部的小字号，取自设计稿。

  /// 服务器详情头图的服务器名。
  static const TextStyle headerTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
  );

  /// 头图副标题 / 小字说明。
  static const TextStyle headerCaption = TextStyle(fontSize: 11.5);

  /// 版本号标签（关于页）。
  static const TextStyle versionTag = TextStyle(fontSize: 12.5);

  /// 账号卡头像里的首字母（根页）。
  static const TextStyle avatarInitial = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  /// 流体卡内的**主行**（叠在流体内，纯白）—— `FluidCardOverlay` 用。
  ///
  /// 15px/w600 原先写死在组件里；本轮字体对齐把硬编码字号收敛到 token，故补此项。
  static const TextStyle cardOverlayTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  /// 徽章文字（服务器行「已连接」）。
  static const TextStyle badge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 玻璃
// ─────────────────────────────────────────────────────────────────────────────

abstract final class LuoboGlass {
  /// 底栏 / 圆钮 / 浮层。
  static const double blur = 24;

  /// 迷你播放条（降档省 GPU，见 `mini_player.dart` 注释）。
  static const double blurBar = 12;

  /// 玻璃描边宽度。
  static const double borderWidth = 0.8;

  /// 玻璃圆钮直径（飞牛 / 箭头实测 119px @3x ≈ 40dp）。
  static const double circleButtonSize = 40;

  /// 底栏高度。
  static const double navHeight = 56;

  /// 底栏选中态实心圆直径。
  ///
  /// 飞牛实测只有 ~20dp（**指示器**级），38 是「大按钮」观感、明显更重；
  /// 折中取 30（图标 20 + 四周 5dp），既靠近飞牛又不至于装不下图标。
  static const double navBubbleSize = 30;

  /// 专辑封面槽直径。
  static const double navArtSize = 34;

  /// ⚠️ 深色玻璃圆钮的可见性来自「模糊 + 描边 + 阴影」，**tint 是黑色几乎不可见**。
  /// 因此它**不能放在纯色深色平面上**。纯色深底场景用 [LuoboGlass.needsStrongBorder]。
  static bool needsStrongBorder(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  /// 深色纯底场景下加强的描边色。
  static const Color strongBorderDark = Color(0x33FFFFFF); // white .20
}

// ─────────────────────────────────────────────────────────────────────────────
// 动效
// ─────────────────────────────────────────────────────────────────────────────

abstract final class LuoboMotion {
  /// 微交互：按下缩放、图标切换、勾选。
  static const Duration micro = Duration(milliseconds: 150);

  /// 浮层：底部 sheet、锚定菜单、遮罩。
  static const Duration sheet = Duration(milliseconds: 250);

  /// 页面转场。
  static const Duration page = Duration(milliseconds: 300);

  /// 进场。
  static const Curve enter = Curves.easeOutCubic;

  /// 出场。
  static const Curve exit = Curves.easeInCubic;

  /// 弹性 —— **仅用于收藏 ♡**（唯一允许「有情绪」的地方）。
  static const Curve playful = Curves.easeOutBack;

  /// 遮罩色（浮层背后）。
  static const Color scrim = Color(0x6B000000); // black .42
}

// ─────────────────────────────────────────────────────────────────────────────
// 便捷扩展
// ─────────────────────────────────────────────────────────────────────────────

extension LuoboColorsX on BuildContext {
  /// `context.lc.card`
  LuoboColors get lc => LuoboColors.of(this);
}
