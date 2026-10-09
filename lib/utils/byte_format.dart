/// 字节数格式化（共享）。
///
/// 改造前这个逻辑散落在 `models/song.dart:formattedSize`、
/// `services/offline_service.dart` 等处各写一遍；新增的 App 设置页也要用，
/// 因此收敛到这里。**新代码统一用 [formatBytes]。**
String formatBytes(int bytes, {int decimals = 2}) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  return '${value.toStringAsFixed(unit == 0 ? 0 : decimals)} ${units[unit]}';
}
