import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';

/// 连接失败时展示给用户的那句话。
///
/// 二选一：
/// 1. 已归因为「本网络没有 IPv6、服务器只有 AAAA」→ 用能指导动作的
///    [AppLocalizations.ipv6OnlyNetworkHint]（原文「连接超时」帮不上任何忙）；
/// 2. 其它情况 → 服务端/网络层给的原始错误，缺失时退回「连接失败」。
///
/// 放在这里而不是 `AuthProvider` 里：Provider 不该依赖 l10n（也不持有 context），
/// 而 6 个出口各写一遍三元表达式容易漂移。
String authErrorText(AppLocalizations l10n, AuthProvider auth) {
  if (auth.ipv6OnlyUnreachable) return l10n.ipv6OnlyNetworkHint;
  return auth.error ?? l10n.failedToConnectToServer;
}
