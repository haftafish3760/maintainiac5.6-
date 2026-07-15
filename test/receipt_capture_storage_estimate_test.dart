import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_quota.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test('balanced proof estimate reports approximate cloud photo capacity', () {
    final estimate = ReceiptCaptureStorageEstimate(
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      cloudQuota: CloudBackupQuotaPolicy.check(
        entitlement: const CloudBackupEntitlement(
          planId: 'test',
          displayName: 'Test',
          quotaBytes: 100 * 1024 * 1024,
          dailySyncLimit: 4,
          immediateSyncAllowed: false,
          policyVersion: 1,
        ),
        usedBytes: 10 * 1024 * 1024,
        pendingBytes: 0,
        backupEnabled: true,
      ),
    );

    expect(estimate.estimatedBytesPerSavedProof, 900 * 1024);
    expect(estimate.estimatedProofBytesForCapture, 900 * 1024);
    expect(estimate.estimatedOriginalBytesForCapture, 24 * 1024 * 1024);
    expect(estimate.estimatedBytesPerSavedProofLabel, '900 KB');
    expect(
      estimate.approximatePhotosRemainingLabel,
      'About 102 more photos at this setting',
    );
    expect(estimate.asksEveryReceiptRecommended, isFalse);
    expect(
      estimate.toPrivacySafeDiagnostics(),
      containsPair('receiptStorageEstimateDataSaverLevel', 'balanced'),
    );
  });

  test('multi-photo long receipt estimate scales proof and original sizes', () {
    final estimate = ReceiptCaptureStorageEstimate(
      dataSaverLevel: ReceiptDataSaverLevel.light,
      photoCount: 4,
      averageOriginalPhotoBytes: 18 * 1024 * 1024,
      cloudQuota: CloudBackupQuotaPolicy.check(
        entitlement: const CloudBackupEntitlement(
          planId: 'test',
          displayName: 'Test',
          quotaBytes: 1024 * 1024 * 1024,
          dailySyncLimit: 4,
          immediateSyncAllowed: false,
          policyVersion: 1,
        ),
        usedBytes: 200 * 1024 * 1024,
        pendingBytes: 0,
        backupEnabled: true,
      ),
    );

    expect(estimate.estimatedBytesPerSavedProof, 1350 * 1024);
    expect(estimate.estimatedProofBytesForCapture, 5400 * 1024);
    expect(estimate.estimatedOriginalBytesForCapture, 72 * 1024 * 1024);
    expect(estimate.estimatedOriginalBytesForCaptureLabel, '72.0 MB');
    expect(
      estimate.approximatePhotosRemainingLabel,
      'About 625 more photos at this setting',
    );
  });

  test('original photos stay local by default and recommend asking', () {
    final estimate = ReceiptCaptureStorageEstimate(
      dataSaverLevel: ReceiptDataSaverLevel.original,
      cloudQuota: CloudBackupQuotaPolicy.check(
        entitlement: const CloudBackupEntitlement(
          planId: 'test',
          displayName: 'Test',
          quotaBytes: 100 * 1024 * 1024,
          dailySyncLimit: 4,
          immediateSyncAllowed: false,
          policyVersion: 1,
        ),
        usedBytes: 0,
        pendingBytes: 0,
        backupEnabled: true,
      ),
    );

    expect(estimate.storesOriginalByDefault, isTrue);
    expect(estimate.estimatedBytesPerSavedProof, 24 * 1024 * 1024);
    expect(estimate.estimatedCloudBackedProofsRemaining, 0);
    expect(estimate.asksEveryReceiptRecommended, isTrue);
    expect(
      estimate.approximatePhotosRemainingLabel,
      'Original photos stay local unless you choose backup',
    );
  });

  test('over-limit cloud quota recommends per-receipt review', () {
    final estimate = ReceiptCaptureStorageEstimate(
      dataSaverLevel: ReceiptDataSaverLevel.strong,
      cloudQuota: CloudBackupQuotaPolicy.check(
        entitlement: const CloudBackupEntitlement(
          planId: 'test',
          displayName: 'Test',
          quotaBytes: 100 * 1024 * 1024,
          dailySyncLimit: 4,
          immediateSyncAllowed: false,
          policyVersion: 1,
        ),
        usedBytes: 99 * 1024 * 1024,
        pendingBytes: 3 * 1024 * 1024,
        backupEnabled: true,
      ),
    );

    expect(estimate.estimatedCloudBackedProofsRemaining, 0);
    expect(estimate.asksEveryReceiptRecommended, isTrue);
    expect(
      estimate.approximatePhotosRemainingLabel,
      'No cloud proof room at this setting',
    );
  });

  test('local-only backup never reports cloud photo capacity', () {
    final estimate = ReceiptCaptureStorageEstimate(
      dataSaverLevel: ReceiptDataSaverLevel.maximum,
      cloudQuota: CloudBackupQuotaPolicy.check(
        entitlement: const CloudBackupEntitlement.localOnly(),
        usedBytes: 0,
        pendingBytes: 0,
      ),
    );

    expect(estimate.estimatedCloudBackedProofsRemaining, 0);
    expect(estimate.approximatePhotosRemainingLabel, 'Cloud backup off');
    expect(estimate.asksEveryReceiptRecommended, isTrue);
  });
}
