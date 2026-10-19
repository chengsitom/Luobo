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

  /// 嵌套 Navigator 的**二级页深度**（`0` = 一级页）。
  ///
  /// 由 [secondaryDepthObserver] 在 `didPush` / `didPop` 维护。`main_screen` 用它决定
  /// 底部条带显示**底栏**（一级页）还是**播放条**（二级页）—— 两者**互斥**（§6.1）。
  ///
  /// ⚠️ **只有挂在嵌套 Navigator 上的路由才算**：`_openNowPlaying` 落的是 **root**
  /// navigator（播放页全屏不透明，本也不需要计入），`showLuoboSheet` 已
  /// `useRootNavigator: true`（§9.19.1）—— 两者都**不计入**，所以这个值干净地等于
  /// 「二级页层数」。
  static final ValueNotifier<int> secondaryDepth = ValueNotifier<int>(0);

  /// 维护 [secondaryDepth] 的观察者 —— 挂到 `main_screen` 的**嵌套** Navigator 上。
  ///
  /// 用**同一个实例**是刻意的：Navigator 会一直持有它，重复 `setState` 不会重复计数。
  static final NavigatorObserver secondaryDepthObserver =
      _SecondaryDepthObserver();
}

/// 见 [NavigationHelper.secondaryDepthObserver]。
class _SecondaryDepthObserver extends NavigatorObserver {
  void _bump(int delta) {
    final next = NavigationHelper.secondaryDepth.value + delta;
    NavigationHelper.secondaryDepth.value = next < 0 ? 0 : next;
  }

  /// 嵌套 Navigator 自己那条**初始**路由（`IndexedStack`）不算二级页 —— 它 `isFirst`。
  static bool _counts(Route<dynamic>? route) =>
      route != null && !route.isFirst;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_counts(route)) _bump(1);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_counts(route)) _bump(-1);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_counts(route)) _bump(-1);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final had = _counts(oldRoute);
    final has = _counts(newRoute);
    if (had && !has) _bump(-1);
    if (!had && has) _bump(1);
  }
}
