import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 守护「缓存所有 BPM」按钮确实接上了实现。
///
/// 2026-11-25 清理下线功能时发现：按钮 onTap 是空回调 `() {}`，
/// 且 `_isCaching/_currentProgress/_totalSongs` 被声明为 final，
/// 即使接上实现也无法驱动进度条。这里做源码结构守护，防止回退。
void main() {
  test('缓存所有 BPM 按钮有真实回调、进度字段可变', () {
    final source =
        File('lib/screens/settings_storage_tab.dart').readAsStringSync();

    expect(
      RegExp(r"onTap:\s*_isCaching\s*\?\s*null\s*:\s*\(\)\s*\{\s*\}")
          .hasMatch(source),
      isFalse,
      reason: '缓存所有 BPM 按钮不能是空回调',
    );
    expect(
      source.contains('() => _cacheAllBPMs()'),
      isTrue,
      reason: '缓存所有 BPM 按钮应调用 _cacheAllBPMs()',
    );

    for (final field in ['_isCaching', '_currentProgress', '_totalSongs']) {
      expect(
        RegExp(r'\bfinal\s+(bool|int)\s+' + field + r'\s*=').hasMatch(source),
        isFalse,
        reason: '$field 必须可变才能更新进度',
      );
    }
  });
}
