import 'dart:io';

/// 连接失败的 IPv6 归因诊断。
///
/// 背景（2026-11-12）：家宽只有公网 IPv6，服务器通过 Lucky 反代暴露一个
/// **AAAA-only** 的域名。在家一切正常，但一旦在**没有 IPv6 的网络**（公司/
/// 校园 WiFi、机场、部分 VPN）打开 App，就只会看到「连接超时」——用户完全看不出
/// 是「这个网络没有 IPv6」，很容易怀疑服务器挂了（连开发自己也误判过一次，
/// 因为 `nslookup` 默认查 A 记录，对 AAAA-only 域名会报 "No answer"）。
///
/// 判定逻辑很简单，但要两个条件同时成立：
/// 1. 域名**只**解析出 IPv6（有 A 记录就说明走 IPv4 也能连）；
/// 2. 本机**没有公网 IPv6 地址**（只有链路本地/ULA/回环都算没有）。
enum Ipv6Diagnosis {
  /// 有 A 记录，或本机具备公网 IPv6 —— 连不上不是 IPv6 的锅。
  notAnIpv6Issue,

  /// 服务器地址只解析到 IPv6，而当前网络没有公网 IPv6。
  serverIpv6OnlyNoLocalIpv6,

  /// 域名解析不出来（域名失效 / DNS 被拦），属于另一类问题。
  dnsFailed,

  /// 探测本身出错（超时等），不下结论。
  unknown,
}

/// 纯判定（可单测）。
Ipv6Diagnosis decideIpv6Diagnosis({
  required bool hasIpv4,
  required bool hasIpv6,
  required bool hasLocalGlobalIpv6,
}) {
  if (hasIpv4) return Ipv6Diagnosis.notAnIpv6Issue;
  if (!hasIpv6) return Ipv6Diagnosis.dnsFailed;
  return hasLocalGlobalIpv6
      ? Ipv6Diagnosis.notAnIpv6Issue
      : Ipv6Diagnosis.serverIpv6OnlyNoLocalIpv6;
}

typedef AddressLookup = Future<List<InternetAddress>> Function(String host);
typedef InterfaceLister = Future<List<NetworkInterface>> Function();

/// 带网络探测的诊断入口；依赖可注入，便于测试。
class Ipv6Reachability {
  Ipv6Reachability._();

  /// 整个探测的硬上限：本来就处在「连不上」的状态，不能让它再拖住 UI。
  static const Duration timeout = Duration(seconds: 4);

  static Future<Ipv6Diagnosis> diagnose(
    String host, {
    AddressLookup? lookup,
    InterfaceLister? listInterfaces,
  }) async {
    if (host.isEmpty) return Ipv6Diagnosis.unknown;
    try {
      final addresses = await (lookup ?? InternetAddress.lookup)(host)
          .timeout(timeout);
      final hasIpv4 =
          addresses.any((a) => a.type == InternetAddressType.IPv4);
      final hasIpv6 =
          addresses.any((a) => a.type == InternetAddressType.IPv6);
      // 有 A 记录就不用再查本机网卡了，省一次系统调用。
      final hasLocalV6 =
          hasIpv4 ? true : await hasPublicIpv6(listInterfaces: listInterfaces);
      return decideIpv6Diagnosis(
        hasIpv4: hasIpv4,
        hasIpv6: hasIpv6,
        hasLocalGlobalIpv6: hasLocalV6,
      );
    } on SocketException {
      return Ipv6Diagnosis.dnsFailed;
    } catch (_) {
      return Ipv6Diagnosis.unknown;
    }
  }

  /// 本机是否有**公网** IPv6 地址。
  ///
  /// 排除：回环、链路本地（fe80::/10）、唯一本地地址（fc00::/7）。后者虽然
  /// 是 IPv6，但不可路由到公网，拿它去连 AAAA-only 的公网域名一样会超时。
  static Future<bool> hasPublicIpv6({InterfaceLister? listInterfaces}) async {
    try {
      final interfaces = await (listInterfaces ?? _listInterfaces)()
          .timeout(timeout);
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (addr.type != InternetAddressType.IPv6) continue;
          if (addr.isLoopback) continue;
          if (_isLinkLocal(addr)) continue;
          if (_isUniqueLocal(addr)) continue;
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<List<NetworkInterface>> _listInterfaces() =>
      NetworkInterface.list(
        includeLoopback: false,
        includeLinkLocal: false,
        type: InternetAddressType.IPv6,
      );

  static bool _isLinkLocal(InternetAddress addr) {
    final raw = addr.rawAddress;
    return raw.length >= 2 && raw[0] == 0xfe && (raw[1] & 0xc0) == 0x80;
  }

  static bool _isUniqueLocal(InternetAddress addr) {
    final raw = addr.rawAddress;
    return raw.length >= 1 && (raw[0] & 0xfe) == 0xfc;
  }
}
