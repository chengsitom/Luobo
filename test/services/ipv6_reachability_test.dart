import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/ipv6_reachability.dart';

void main() {
  group('decideIpv6Diagnosis', () {
    test('有 A 记录 → 不是 IPv6 的问题（本机有没有 IPv6 都无所谓）', () {
      expect(
        decideIpv6Diagnosis(
            hasIpv4: true, hasIpv6: false, hasLocalGlobalIpv6: false),
        Ipv6Diagnosis.notAnIpv6Issue,
      );
      expect(
        decideIpv6Diagnosis(
            hasIpv4: true, hasIpv6: true, hasLocalGlobalIpv6: false),
        Ipv6Diagnosis.notAnIpv6Issue,
      );
    });

    test('AAAA-only + 本机无公网 IPv6 → 命中（真实踩过的场景）', () {
      expect(
        decideIpv6Diagnosis(
            hasIpv4: false, hasIpv6: true, hasLocalGlobalIpv6: false),
        Ipv6Diagnosis.serverIpv6OnlyNoLocalIpv6,
      );
    });

    test('AAAA-only + 本机有公网 IPv6 → 不是 IPv6 的问题', () {
      expect(
        decideIpv6Diagnosis(
            hasIpv4: false, hasIpv6: true, hasLocalGlobalIpv6: true),
        Ipv6Diagnosis.notAnIpv6Issue,
      );
    });

    test('A/AAAA 都没有 → DNS 失败（域名失效/被拦），别归因到 IPv6', () {
      expect(
        decideIpv6Diagnosis(
            hasIpv4: false, hasIpv6: false, hasLocalGlobalIpv6: true),
        Ipv6Diagnosis.dnsFailed,
      );
    });
  });

  group('Ipv6Reachability.diagnose', () {
    test('AAAA-only + 本机无 IPv6 → 命中', () async {
      final d = await Ipv6Reachability.diagnose(
        'ipv6only.example.com',
        lookup: (_) async => [
          InternetAddress('2408:820c:8fac:f7f1::6c0', type: InternetAddressType.IPv6),
        ],
        listInterfaces: () async => [],
      );
      expect(d, Ipv6Diagnosis.serverIpv6OnlyNoLocalIpv6);
    });

    test('AAAA-only + 本机只有链路本地/ULA → 仍然命中（不可路由）', () async {
      final d = await Ipv6Reachability.diagnose(
        'ipv6only.example.com',
        lookup: (_) async => [
          InternetAddress('2408::1', type: InternetAddressType.IPv6),
        ],
        listInterfaces: () async => [
          _FakeInterface('en0', [
            InternetAddress('fe80::1', type: InternetAddressType.IPv6),
            InternetAddress('fd00::1', type: InternetAddressType.IPv6),
          ]),
        ],
      );
      expect(d, Ipv6Diagnosis.serverIpv6OnlyNoLocalIpv6);
    });

    test('AAAA-only + 本机有公网 IPv6 → 不命中', () async {
      final d = await Ipv6Reachability.diagnose(
        'ipv6only.example.com',
        lookup: (_) async => [
          InternetAddress('2408::1', type: InternetAddressType.IPv6),
        ],
        listInterfaces: () async => [
          _FakeInterface('en0', [
            InternetAddress('2408:820c::1234', type: InternetAddressType.IPv6),
          ]),
        ],
      );
      expect(d, Ipv6Diagnosis.notAnIpv6Issue);
    });

    test('有 A 记录 → 不查网卡直接放行', () async {
      var interfaceQueried = false;
      final d = await Ipv6Reachability.diagnose(
        'dual.example.com',
        lookup: (_) async => [
          InternetAddress('1.2.3.4'),
          InternetAddress('2408::1', type: InternetAddressType.IPv6),
        ],
        listInterfaces: () async {
          interfaceQueried = true;
          return [];
        },
      );
      expect(d, Ipv6Diagnosis.notAnIpv6Issue);
      expect(interfaceQueried, isFalse);
    });

    test('解析抛 SocketException → dnsFailed', () async {
      final d = await Ipv6Reachability.diagnose(
        'gone.example.com',
        lookup: (_) async => throw const SocketException('no such host'),
        listInterfaces: () async => [],
      );
      expect(d, Ipv6Diagnosis.dnsFailed);
    });

    test('空 host → unknown（不下结论）', () async {
      expect(await Ipv6Reachability.diagnose(''), Ipv6Diagnosis.unknown);
    });
  });
}

/// `NetworkInterface` 无法直接构造，测试里用最小实现替身。
class _FakeInterface implements NetworkInterface {
  _FakeInterface(this.name, this.addresses);

  @override
  final String name;

  @override
  final List<InternetAddress> addresses;

  @override
  int get index => 0;
}
