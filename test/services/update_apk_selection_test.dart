import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/update_service.dart';

ReleaseInfo _releaseWith(List<String> names) => ReleaseInfo(
      version: '9.9.9',
      tagName: 'v9.9.9',
      htmlUrl: 'https://example.com/release',
      body: '',
      assets: names
          .map((n) => ReleaseAsset(
                name: n,
                browserDownloadUrl: 'https://example.com/$n',
              ))
          .toList(),
    );

void main() {
  const allApks = [
    'app-arm64-v8a-release.apk',
    'app-armeabi-v7a-release.apk',
    'app-x86_64-release.apk',
    'app-release.apk',
  ];

  group('UpdateService.pickBestApkFor', () {
    test('picks arm64-v8a as first supported ABI', () {
      final picked = UpdateService.pickBestApkFor(
        _releaseWith(allApks),
        ['arm64-v8a', 'armeabi-v7a'],
      );
      expect(picked?.name, 'app-arm64-v8a-release.apk');
    });

    test('falls back to next supported ABI when first has no asset', () {
      final picked = UpdateService.pickBestApkFor(
        _releaseWith(['app-armeabi-v7a-release.apk', 'app-release.apk']),
        ['arm64-v8a', 'armeabi-v7a'],
      );
      expect(picked?.name, 'app-armeabi-v7a-release.apk');
    });

    test('falls back to universal apk when no ABI matches', () {
      final picked = UpdateService.pickBestApkFor(
        _releaseWith(allApks.reversed.toList()),
        ['mips'],
      );
      expect(picked?.name, 'app-release.apk');
    });

    test('returns null when no apk assets at all', () {
      final picked = UpdateService.pickBestApkFor(
        _releaseWith(['Luobo.dmg', 'README.md']),
        ['arm64-v8a'],
      );
      expect(picked, isNull);
    });

    test('ignores non-apk assets containing ABI substring', () {
      final picked = UpdateService.pickBestApkFor(
        _releaseWith(['arm64-v8a-symbols.txt', 'app-release.apk']),
        ['arm64-v8a'],
      );
      expect(picked?.name, 'app-release.apk');
    });
  });
}
