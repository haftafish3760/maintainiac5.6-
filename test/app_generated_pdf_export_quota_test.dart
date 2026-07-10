import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/pdf/app_generated_pdf_export_quota.dart';

void main() {
  test('allows one free generated-PDF export per month', () async {
    final used = <String, int>{};
    final quota = AppGeneratedPdfExportQuotaService(
      readUsedExports: (monthKey) async => used[monthKey] ?? 0,
      writeUsedExports: (monthKey, count) async => used[monthKey] = count,
    );
    final day = DateTime(2026, 7, 9);

    expect((await quota.status(day)).freeExportsRemaining, 1);
    expect(await quota.canExport(day), isTrue);
    await quota.consumeExport(day);
    expect((await quota.status(day)).freeExportsRemaining, 0);
    expect(await quota.canExport(day), isFalse);
    await expectLater(
      quota.consumeExport(day),
      throwsA(
        isA<AppGeneratedPdfExportQuotaException>().having(
          (error) => error.reasonCode,
          'reasonCode',
          'monthly_export_limit_reached',
        ),
      ),
    );
  });

  test(
    'keeps months independent and supports a rewarded placeholder unlock',
    () async {
      final used = <String, int>{'2026-07': 1};
      final quota = AppGeneratedPdfExportQuotaService(
        readUsedExports: (monthKey) async => used[monthKey] ?? 0,
        writeUsedExports: (monthKey, count) async => used[monthKey] = count,
      );
      final july = DateTime(2026, 7, 9);
      final august = DateTime(2026, 8, 1);

      expect(await quota.canExport(august), isTrue);
      expect(await quota.canExport(july), isFalse);
      expect(await quota.unlockExportWithRewardedAdPlaceholder(july), isTrue);
      expect((await quota.status(july)).rewardedUnlockAvailable, isTrue);
      await quota.consumeExport(july);
      expect(await quota.canExport(july), isFalse);
      expect(used['2026-07'], 1);
    },
  );

  test(
    'normalizes negative persisted usage without mutating source data',
    () async {
      final quota = AppGeneratedPdfExportQuotaService(
        readUsedExports: (_) async => -4,
        writeUsedExports: (_, _) async {},
      );

      final status = await quota.status(DateTime(2026, 7, 9));
      expect(status.usedExports, 0);
      expect(status.freeExportsRemaining, 1);
    },
  );
}
