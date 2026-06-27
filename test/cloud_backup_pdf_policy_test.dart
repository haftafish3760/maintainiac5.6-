import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/backup/cloud_backup_pdf_policy.dart';
import 'package:maintaniac/shared/backup/cloud_backup_quota.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void main() {
  test('small receipt PDFs upload as-is on the free tier', () {
    final plan = CloudBackupPdfPolicy.planPdfBytes(
      byteSize: 2 * 1024 * 1024,
      pageCount: 2,
    );

    expect(plan.action, CloudBackupFileAction.uploadAsIs);
    expect(plan.estimatedCloudBytes, plan.originalBytes);
    expect(plan.shouldUploadNow, isTrue);
  });

  test('mid-size scanned receipt PDFs are deferred until optimized', () {
    final plan = CloudBackupPdfPolicy.planPdfBytes(
      byteSize: 12 * 1024 * 1024,
      pageCount: 16,
    );

    expect(plan.action, CloudBackupFileAction.deferUntilOptimized);
    expect(plan.needsOptimizationBeforeCloud, isTrue);
    expect(plan.shouldUploadNow, isFalse);
    expect(plan.estimatedCloudBytes, lessThan(plan.originalBytes));
  });

  test('receipt PDFs larger than the practical free-tier limit stay local', () {
    final plan = CloudBackupPdfPolicy.planPdfBytes(
      byteSize: 22 * 1024 * 1024,
      pageCount: 50,
    );

    expect(plan.action, CloudBackupFileAction.localOnlyTooLarge);
    expect(plan.shouldUploadNow, isFalse);
    expect(plan.reason, contains('too large'));
  });

  test('a PDF larger than the current tier is never auto uploaded', () {
    final plan = CloudBackupPdfPolicy.planPdfBytes(
      byteSize: CloudBackupTier.freeTrial.quotaBytes + 1,
      tier: CloudBackupTier.freeTrial,
    );

    expect(plan.action, CloudBackupFileAction.localOnlyTooLarge);
    expect(plan.reason, contains('larger than the current cloud tier'));
  });

  test('generated PDFs use a different optimization estimate', () {
    final plan = CloudBackupPdfPolicy.planPdfBytes(
      byteSize: 5 * 1024 * 1024,
      generatedPdf: true,
      pageCount: 3,
    );

    expect(plan.action, CloudBackupFileAction.useOptimizedCopy);
    expect(plan.estimatedCloudBytes, lessThan(plan.originalBytes));
    expect(plan.estimatedCloudBytes, greaterThan(plan.originalBytes ~/ 2));
  });

  test('non-PDF attachments are counted as-is', () {
    final plan = CloudBackupPdfPolicy.planAttachment(
      attachment: ReceiptAttachmentRecord(
        id: 'photo',
        path: '/proof/photo.jpg',
        kind: ReceiptAttachmentKind.photo,
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        createdAt: DateTime(2026, 6, 16),
        byteSize: 250000,
        fileHash: 'hash',
      ),
    );

    expect(plan.action, CloudBackupFileAction.uploadAsIs);
    expect(plan.estimatedCloudBytes, 250000);
  });
}
