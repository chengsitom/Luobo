// 日志脱敏工具。
//
// 封面与流媒体 URL 会把凭据直接放在 query 里：
// - Subsonic 明文认证 `u=` / `p=`，token 认证 `t=` + `s=`(salt)
// - 道理鱼自研流 `/api/tracks/{id}/stream?token=<JWT>`
// - 封面票据 `/api/cover?...&ticket=<JWT>`
//
// 实测 flutter run 日志里曾把服务器明文密码整段打印出来（图片加载异常
// 对象的 `toString()` 会带上完整请求 URL）。这类日志常被直接贴给别人排查，
// 因此凡是输出 URL / 网络异常的地方，都必须先经过 redactSecretsInText。
//
// 只盖掉敏感参数的值，保留 `id` / `size` / `v` / `c` / `f` 等参数，
// 这样 401 / 404 的诊断信息仍然完整可定位。

/// 匹配 URL query 中的敏感参数（大小写不敏感），group 1 为「参数名=」。
///
/// 用 `[?&]` 锚定参数起点，避免误伤 `size=`（`s=` 要求后面紧跟 `=`）。
final RegExp _sensitiveQueryParam = RegExp(
  r'([?&](?:p|t|s|u|pw|pass|password|token|ticket|apiKey|api_key|salt|auth|sig|signature)=)[^&\s]*',
  caseSensitive: false,
);

/// 把 [text] 中所有 URL 的敏感参数值替换为 `***`。
///
/// 对整段文本做匹配而不是先解析 URL：图片加载异常通常把 URL 嵌在描述文字
/// 中间（例如 `HTTP request failed, statusCode: 401, https://...`），
/// 无法当作单个 URL 解析。
String redactSecretsInText(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(
    _sensitiveQueryParam,
    (m) => '${m[1]}***',
  );
}
