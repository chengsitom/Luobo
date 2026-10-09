import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class NavigationHelper {
  static final GlobalKey<NavigatorState> mobileNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> desktopNavigatorKey =
      GlobalKey<NavigatorState>();

  static bool get isDesktop {
    if (kIsWeb) return false;
    return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  static GlobalKey<NavigatorState> get navigatorKey {
    return isDesktop ? desktopNavigatorKey : mobileNavigatorKey;
  }

  static Future<T?> push<T>(BuildContext context, Widget page) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(MaterialPageRoute(builder: (_) => page));
    }
    return Navigator.of(
      context,
    ).push<T>(MaterialPageRoute(builder: (_) => page));
  }

  static Future<T?> pushRoute<T>(BuildContext context, Route<T> route) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      return nav.push<T>(route);
    }
    return Navigator.of(context).push<T>(route);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    final nav = navigatorKey.currentState;
    if (nav != null && nav.canPop()) {
      nav.pop<T>(result);
    } else {
      Navigator.of(context).pop<T>(result);
    }
  }

  static void popUntil(
    BuildContext context,
    bool Function(Route<dynamic>) predicate,
  ) {
    final nav = navigatorKey.currentState;
    if (nav != null) {
      nav.popUntil(predicate);
    } else {
      Navigator.of(context).popUntil(predicate);
    }
  }

  static void Function(int)? _onTabChanged;

  /// 当前 tab 索引（首页 = 0）。**可多播**，供页面订阅（例如首页「回到首页换
  /// 漫游卡配色」）。
  ///
  /// ⚠️ 与 [_onTabChanged] 并存，**别混用**：那个是**单槽**回调，已被 `main_screen`
  /// 占用，别处再调 [registerTabChangeCallback] 会直接顶掉它、打断切 tab。
  static final ValueNotifier<int> tabIndex = ValueNotifier<int>(0);

  static void registerTabChangeCallback(void Function(int) callback) {
    _onTabChanged = callback;
  }

  static void switchToTab(int index) {
    tabIndex.value = index;
    _onTabChanged?.call(index);
  }
}
