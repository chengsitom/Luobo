import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/utils/log_redaction.dart';
import 'package:luobo/utils/image_cache.dart';
import 'package:luobo/services/diagnostics/network_interceptor.dart';

/// 日志脱敏回归：flutter run 日志里曾把服务器明文密码整段打印出来，
/// 这里锁死「敏感参数必须盖掉、诊断参数必须保留」两条底线。
void main() {
  group('redactSecretsInText', () {
    test('Subsonic 明文认证 u/p 被打码，诊断参数保留', () {
      const url = 'https://example.com:10010/rest/getCoverArt'
          '?u=chengsitom&v=1.16.1&c=Musly&f=json'
          '&p=superSecret123&id=album%3Aalb_abc&size=300';
      final out = redactSecretsInText(url);
      expect(out, isNot(contains('superSecret123')));
      expect(out, isNot(contains('chengsitom')));
      expect(out, contains('p=***'));
      expect(out, contains('u=***'));
      // 这些信息要留着定位问题
      expect(out, contains('id=album%3Aalb_abc'));
      expect(out, contains('size=300'));
      expect(out, contains('c=Musly'));
      expect(out, contains('v=1.16.1'));
      expect(out, contains('f=json'));
    });

    test('token 认证 t=/s= 与道理鱼 JWT token=/ticket= 全部打码', () {
      const url = 'https://example.com/api/cover?path=%2FMusic%2Fa.jpg'
          '&size=600&ticket=eyJhbGciOiJIUzI1NiJ9.payload.sig';
      final out = redactSecretsInText(url);
      expect(out, isNot(contains('eyJhbGciOiJIUzI1NiJ9')));
      expect(out, contains('ticket=***'));
      expect(out, contains('size=600'));

      const subsonicToken =
          'https://example.com/rest/ping?u=me&t=deadbeef&s=1234abcd&v=1.16.1';
      final out2 = redactSecretsInText(subsonicToken);
      expect(out2, isNot(contains('deadbeef')));
      expect(out2, isNot(contains('1234abcd')));
      expect(out2, contains('t=***'));
      expect(out2, contains('s=***'));
    });

    test('流媒体 URL 的 token 打码', () {
      const url =
          'https://example.com/api/tracks/trk_1/stream?token=eyJhbGciOi.sig';
      final out = redactSecretsInText(url);
      expect(out, isNot(contains('eyJhbGciOi')));
      expect(out, contains('token=***'));
      expect(out, contains('trk_1'));
    });

    test('关键回归：URL 嵌在异常描述文本里也必须脱敏', () {
      // 旧 sanitizeQueryUrl 用 Uri.parse 解析整段字符串会失败并原样返回，
      // 图片加载异常的 toString() 恰好就是这种格式。
      const err = 'Network image fallback error: HTTP request failed, '
          'statusCode: 401, https://example.com/rest/getCoverArt'
          '?u=me&p=plainTextPassword&id=album%3Aalb_x&size=300';
      final out = redactSecretsInText(err);
      expect(out, isNot(contains('plainTextPassword')));
      expect(out, contains('p=***'));
      expect(out, contains('statusCode: 401'));
      expect(out, contains('size=300'));
    });

    test('size= 不会被 s= 误伤；空串/普通文本原样返回', () {
      const url = 'https://example.com/rest/getCoverArt?id=al-1&size=300&s=xyz';
      final out = redactSecretsInText(url);
      expect(out, contains('size=300'));
      expect(out, isNot(contains('xyz')));
      expect(redactSecretsInText(''), '');
      expect(redactSecretsInText('plain log line'), 'plain log line');
    });

    test('老入口 sanitizeQueryUrl 与新实现行为一致且覆盖 token', () {
      const url = 'https://example.com/rest/ping?u=me&p=pass123&v=1.16.1';
      expect(sanitizeQueryUrl(url), redactSecretsInText(url));
      final withToken = sanitizeQueryUrl(
          'https://example.com/api/tracks/x/stream?token=secret.jwt');
      expect(withToken, isNot(contains('secret.jwt')));
      expect(withToken, contains('token=***'));
    });
  });

  group('CoverFailureCache', () {
    setUp(CoverFailureCache.clear);
    tearDown(CoverFailureCache.clear);

    test('未记录时不拦截，记录后在 TTL 内直接命中', () {
      expect(CoverFailureCache.isFailed('album:alb_x'), isFalse);
      CoverFailureCache.markFailed('album:alb_x');
      expect(CoverFailureCache.isFailed('album:alb_x'), isTrue);
    });

    test('不同封面 id 互不影响，clear 后恢复', () {
      CoverFailureCache.markFailed('album:alb_x');
      expect(CoverFailureCache.isFailed('album:alb_y'), isFalse);
      CoverFailureCache.clear();
      expect(CoverFailureCache.isFailed('album:alb_x'), isFalse);
    });
  });

  group('播放页高清图的缓存隔离', () {
    test('1200px 与 300px 落在不同 cacheKey，不会冲掉已预热的低清图', () {
      // 冷启秒出依赖 300px 磁盘预热缓存始终可用；高清图必须另占一个 key，
      // 否则播放页取高清会把列表页/placeholder 用的低清缓存覆盖掉。
      const low = 'https://example.com/rest/getCoverArt'
          '?u=me&p=x&id=album%3Aalb_1&size=300';
      const hi = 'https://example.com/rest/getCoverArt'
          '?u=me&p=x&id=album%3Aalb_1&size=1200';
      final lowKey = coverArtCacheKeyFromUrl(low);
      final hiKey = coverArtCacheKeyFromUrl(hi);
      expect(hiKey, isNot(equals(lowKey)));
      expect(lowKey, endsWith('-300'));
      expect(hiKey, endsWith('-1200'));
    });
  });
}
