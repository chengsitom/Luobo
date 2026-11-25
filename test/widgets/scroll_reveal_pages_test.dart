import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 守护「二级页顶栏标题随滚动渐显」的全局约定：
/// 页面初始只有返回圆钮，上滑后才显示标题胶囊。
///
/// 2026-11-23 用户反馈「某些页面仍旧默认就是 title 内容」——排查发现
/// radio / listening_report 纯列表二级页写死了 `AppBar(title:)`，
/// 绕开了全局的 ScrollRevealScaffold。这里做源码结构守护：这些页面必须走
/// ScrollRevealScaffold，且不得再写死 `AppBar(`。
///
/// 行为层（初始无标题 → 上滑显示）由 test/widgets/settings_sub_page_test.dart
/// 与 ScrollRevealScaffold 自身覆盖；本文件只钉「没写回旧写法」。
void main() {
  const pages = <String, String>{
    '电台页': 'lib/screens/radio_screen.dart',
    '听歌报告页': 'lib/screens/listening_report_screen.dart',
  };

  pages.forEach((label, path) {
    test('$path 使用渐显标题封装、不再写死 AppBar(title:)', () {
      final source = File(path).readAsStringSync();

      expect(
        source.contains('ScrollRevealScaffold'),
        isTrue,
        reason: '$label 应统一走 ScrollRevealScaffold（上滑才显标题）',
      );
      expect(
        RegExp(r'\bAppBar\s*\(').hasMatch(source),
        isFalse,
        reason: '$label 不应再写死 AppBar（会导致默认就显示标题）',
      );
    });
  });
}
