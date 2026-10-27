import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/subsonic_service.dart';

/// 道理鱼封面票据响应解析（`/api/library/cover-tickets` 结构未公开，
/// 解析必须是防御式的）。纯函数单测，不打网络。
void main() {
  group('parseCoverTicketPayload', () {
    final now = DateTime(2026, 10, 23, 12);

    test('{ticket, exp(毫秒时间戳)}', () {
      final exp = now.add(const Duration(minutes: 2));
      final parsed = SubsonicService.parseCoverTicketPayload(
        {'ticket': 'abc', 'exp': exp.millisecondsSinceEpoch},
        now,
      );
      expect(parsed?.$1, 'abc');
      expect(parsed?.$2.isAfter(now), isTrue);
    });

    test('{ticket, exp(秒级时间戳)}', () {
      final exp = now.add(const Duration(minutes: 2));
      final parsed = SubsonicService.parseCoverTicketPayload(
        {'ticket': 'abc', 'exp': exp.millisecondsSinceEpoch ~/ 1000},
        now,
      );
      expect(parsed?.$1, 'abc');
      expect(parsed!.$2.difference(now).inSeconds, closeTo(120, 2));
    });

    test('{tickets: [字符串]}', () {
      final parsed = SubsonicService.parseCoverTicketPayload(
        {'tickets': ['t1', 't2']},
        now,
      );
      expect(parsed?.$1, 't1');
      // 无有效期 → 兜底 100 秒
      expect(parsed!.$2.difference(now).inSeconds, 100);
    });

    test('{tickets: [{ticket, exp(剩余秒)}]}', () {
      final parsed = SubsonicService.parseCoverTicketPayload(
        {
          'tickets': [
            {'ticket': 'tk', 'exp': 90},
          ],
        },
        now,
      );
      expect(parsed?.$1, 'tk');
      expect(parsed!.$2.difference(now).inSeconds, closeTo(90, 1));
    });

    test('{value, expiresAt(ISO)}', () {
      final parsed = SubsonicService.parseCoverTicketPayload(
        {
          'tickets': [
            {
              'value': 'iso',
              'expiresAt': now.add(const Duration(minutes: 2)).toIso8601String(),
            },
          ],
        },
        now,
      );
      expect(parsed?.$1, 'iso');
      expect(parsed!.$2.isAfter(now), isTrue);
    });

    test('已过期 → 给 30 秒缓冲，避免死循环刷新', () {
      final parsed = SubsonicService.parseCoverTicketPayload(
        {'ticket': 'old', 'exp': now.subtract(const Duration(minutes: 5)).millisecondsSinceEpoch},
        now,
      );
      expect(parsed?.$1, 'old');
      expect(parsed!.$2.difference(now).inSeconds, 30);
    });

    test('无法解析 → null', () {
      expect(SubsonicService.parseCoverTicketPayload(null, now), isNull);
      expect(SubsonicService.parseCoverTicketPayload({}, now), isNull);
      expect(
        SubsonicService.parseCoverTicketPayload({'tickets': []}, now),
        isNull,
      );
      expect(
        SubsonicService.parseCoverTicketPayload({'ticket': ''}, now),
        isNull,
      );
    });
  });
}
