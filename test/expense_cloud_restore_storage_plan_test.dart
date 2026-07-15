import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_codec.dart';
import 'package:maintaniac/screens/expenses/data/expense_cloud_restore_storage_plan.dart';

void main() {
  const estimate = ExpenseCloudRestoreEstimate(
    recordCount: 4,
    proofCount: 2,
    cloudProofCount: 2,
    metadataOnlyProofCount: 0,
    knownProofBytes: 600,
    proofsWithUnknownSize: 0,
  );

  test('full restore reserves installed and temporary proof storage', () {
    final plan = ExpenseCloudRestoreStoragePlan.forMode(
      mode: ExpenseCloudRestoreMode.full,
      estimate: estimate,
      structuredRecordBytes: 100,
      availableBytes: 1400,
    );

    expect(plan.knownDownloadBytes, 700);
    expect(plan.installedBytes, 700);
    expect(plan.temporaryBytes, 700);
    expect(plan.requiredAvailableBytes, 1400);
    expect(plan.canStart, isTrue);
  });

  test('smart and records-only restore do not reserve proof downloads', () {
    for (final mode in [
      ExpenseCloudRestoreMode.smart,
      ExpenseCloudRestoreMode.recordsOnly,
    ]) {
      final plan = ExpenseCloudRestoreStoragePlan.forMode(
        mode: mode,
        estimate: estimate,
        structuredRecordBytes: 100,
        availableBytes: 200,
      );

      expect(plan.knownDownloadBytes, 100);
      expect(plan.requiredAvailableBytes, 200);
      expect(plan.canStart, isTrue);
    }
  });

  test('full restore refuses unknown proof size or insufficient storage', () {
    const unknownProofEstimate = ExpenseCloudRestoreEstimate(
      recordCount: 1,
      proofCount: 1,
      cloudProofCount: 1,
      metadataOnlyProofCount: 0,
      knownProofBytes: 0,
      proofsWithUnknownSize: 1,
    );
    final unknown = ExpenseCloudRestoreStoragePlan.forMode(
      mode: ExpenseCloudRestoreMode.full,
      estimate: unknownProofEstimate,
      availableBytes: 100000,
    );
    final lowStorage = ExpenseCloudRestoreStoragePlan.forMode(
      mode: ExpenseCloudRestoreMode.full,
      estimate: estimate,
      availableBytes: 1199,
      structuredRecordBytes: 100,
    );

    expect(unknown.canStart, isFalse);
    expect(lowStorage.hasEnoughAvailableStorage, isFalse);
    expect(lowStorage.canStart, isFalse);
  });
}
