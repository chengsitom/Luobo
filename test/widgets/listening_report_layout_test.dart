import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 听歌报告版式守护：
/// 1. Hero 统计区时长字符串最长，必须给它额外宽度，否则被 ellipsis 截成
///    「3 小时 3...」；
/// 2. ListView 底部必须计入悬浮播放条净空，否则第 04 章最后一张卡被压住。
void main() {
  const path = 'lib/screens/listening_report_screen.dart';

  test('Hero 累计聆听有双倍宽度、底部计入条带净空', () {
    final source = File(path).readAsStringSync();

    expect(
      RegExp(r'Expanded\(\s*flex:\s*2,\s*child:\s*_HeroStat\(\s*value:\s*duration')
          .hasMatch(source),
      isTrue,
      reason: '累计聆听字符串最长，需要 flex: 2 才不会被截断',
    );
    // scrollPadding 内部会自动叠加一次 MediaQuery.padding.bottom（含悬浮条带），
    // 所以这里只能传设计留白 pageBottom。若传 pageBottomWithStrip，条带净空
    // 会被加两次，底部多出一整条播放条的空白（2026-11-25 审查发现）。
    expect(
      source.contains('bottom: LuoboSpacing.pageBottom,'),
      isTrue,
      reason: '报告页底部用 scrollPadding + 纯设计留白，条带净空由 scrollPadding 内部加',
    );
    expect(
      source.contains('bottom: LuoboSpacing.pageBottomWithStrip(context)'),
      isFalse,
      reason: '不得在 scrollPadding 里再传 pageBottomWithStrip，否则条带净空重复叠加',
    );
  });

  test('条件渲染的卡片列表统一走 _spacedCards，避免双倍间距', () {
    final source = File(path).readAsStringSync();

    // 01 / 03 / 04 三个多卡片章节都必须用统一间距方法。
    expect(
      RegExp(r'\.\.\._spacedCards\(\[').allMatches(source).length,
      greaterThanOrEqualTo(3),
      reason: '多卡片章节应统一用 _spacedCards 插入 12dp，不要各自写 SizedBox',
    );
    // 03 章节曾经的 bug：陪伴卡「后加 12」+「那一天」「前加 12」→ 24dp。
    // 用 flexible 正则而非精确缩进，避免 dart format 调整换行后误报。
    expect(
      RegExp(r'_CompanionCard\(\s*companionDays:').hasMatch(source),
      isTrue,
      reason: '陪伴卡应作为参数进入 _spacedCards 列表',
    );
  });
}
