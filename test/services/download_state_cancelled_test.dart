import 'package:flutter_test/flutter_test.dart';
import 'package:luobo/services/offline_service.dart';

void main() {
  group('DownloadState.cancelled', () {
    test('defaults to false', () {
      expect(DownloadState().cancelled, isFalse);
    });

    test('copyWith preserves cancelled when not specified', () {
      final cancelled = DownloadState(
        isDownloading: true,
        totalCount: 10,
        cancelled: true,
      );
      final updated = cancelled.copyWith(isDownloading: false);
      expect(updated.cancelled, isTrue);
      expect(updated.isDownloading, isFalse);
    });

    test('copyWith can clear cancelled for a fresh batch', () {
      final cancelled = DownloadState(totalCount: 10, cancelled: true);
      final fresh = cancelled.copyWith(cancelled: false, totalCount: 5);
      expect(fresh.cancelled, isFalse);
      expect(fresh.totalCount, 5);
    });

    test('cancelled state can coexist with failedCount from in-flight tasks',
        () {
      // 取消时，在途任务返回 false 计入 failedCount；终态卡应看 cancelled
      // 而非 failedCount 决定文案，这里保证两者能同时存在且不互相覆盖。
      final state = DownloadState(
        isDownloading: false,
        totalCount: 10,
        successCount: 3,
        failedCount: 2,
        cancelled: true,
      );
      expect(state.cancelled, isTrue);
      expect(state.failedCount, 2);
      expect(state.successCount, 3);
    });
  });
}
