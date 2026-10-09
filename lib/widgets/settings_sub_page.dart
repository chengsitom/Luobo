import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'luobo/glass_circle_button.dart';

/// 设置二级页薄壳 —— **C1 二级页骨架**。
///
/// 设计稿：`~/Downloads/fnosmusic/设计稿/01-C1-二级页骨架对比.png`。
///
/// | | BEFORE（旧） | AFTER（本骨架） |
/// |---|---|---|
/// | 返回 | 裸箭头（无圆底） | **悬浮玻璃圆钮** |
/// | 标题 | 31px 左对齐（与首页撞脸） | **15px 居中** |
/// | 右上 | 无槽位 | **可选动作钮槽位** |
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
    this.headerHeight = 56,
  });

  final String title;
  final Widget body;

  /// 右上角动作钮（如保存 ✓）。会排在 [trailing] 左边。
  final List<Widget>? actions;

  /// 右上角单个动作钮（便捷）。
  final Widget? trailing;

  final double headerHeight;

  @override
  Widget build(BuildContext context) {
    final c = LuoboColors.of(context);

    final rightWidgets = <Widget>[
      ...?actions,
      if (trailing != null) trailing!,
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: Column(
        children: [
          ColoredBox(
            color: c.bg,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                // ⚠️ 必须显式给宽度：`Column` 默认 crossAxisAlignment.center，
                // 传下来的是**松宽度约束**；不写 width 的话这个 SizedBox 会收缩成
                // 「标题 + 左右 72」的宽度，`Stack`（StackFit.loose）跟着缩窄，
                // 于是 `Positioned(left/right: 16)` 变成相对窄条定位 —— 返回钮与
                // 右上动作钮会被挤到标题两侧，而不是贴屏幕边缘。
                width: double.infinity,
                height: headerHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 居中标题
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 72),
                      child: Text(
                        title,
                        style: LuoboType.navTitle.copyWith(color: c.fg),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // 左上悬浮圆返回
                    const Positioned(
                      left: LuoboSpacing.pageX,
                      child: GlassBackButton(),
                    ),
                    // 右上动作钮槽位
                    if (rightWidgets.isNotEmpty)
                      Positioned(
                        right: LuoboSpacing.pageX,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < rightWidgets.length; i++) ...[
                              if (i > 0) const SizedBox(width: 8),
                              rightWidgets[i],
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
