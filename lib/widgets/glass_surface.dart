import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

/// BackdropFilter-free solid bottom sheet. Kept as a drop-in replacement for
/// the previous frosted-glass wrapper so all call sites can switch back to
/// solid backgrounds without touching each file.
Future<T?> showGlassBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? backgroundColor,
}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => Container(
      decoration: BoxDecoration(
        // 2026-10-23：浅色弹层统一为页面灰底（fnos 弹层同色），
        // 不再用纯白（白底会让「页底-弹层」失去层级）。
        color: isDark ? const Color(0xFF1C1C1E) : LuoboColors.light.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: builder(context),
    ),
  );
}
