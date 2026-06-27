import '../widgets/receipt_capture/receipt_capture_models.dart';
import 'cloud_backup_quota.dart';

enum CloudBackupFileAction {
  uploadAsIs,
  useOptimizedCopy,
  deferUntilOptimized,
  localOnlyTooLarge,
}

class CloudBackupFilePlan {
  const CloudBackupFilePlan({
    required this.action,
    required this.originalBytes,
    required this.estimatedCloudBytes,
    required this.reason,
  });

  final CloudBackupFileAction action;
  final int originalBytes;
  final int estimatedCloudBytes;
  final String reason;

  bool get shouldUploadNow =>
      action == CloudBackupFileAction.uploadAsIs ||
      action == CloudBackupFileAction.useOptimizedCopy;

  bool get needsOptimizationBeforeCloud =>
      action == CloudBackupFileAction.deferUntilOptimized ||
      action == CloudBackupFileAction.useOptimizedCopy;
}

class CloudBackupPdfPolicy {
  const CloudBackupPdfPolicy._();

  static const freeTierImmediatePdfBytes = 8 * 1024 * 1024;
  static const freeTierDeferredPdfBytes = 20 * 1024 * 1024;
  static const generatedPdfImmediateBytes = 4 * 1024 * 1024;
  static const optimizedScannedPdfRatio = .45;
  static const optimizedGeneratedPdfRatio = .92;

  static CloudBackupFilePlan planAttachment({
    required ReceiptAttachmentRecord attachment,
    CloudBackupTier tier = CloudBackupTier.freeTrial,
    bool generatedPdf = false,
  }) {
    final originalBytes = attachment.byteSize ?? 0;
    if (originalBytes <= 0) {
      return const CloudBackupFilePlan(
        action: CloudBackupFileAction.localOnlyTooLarge,
        originalBytes: 0,
        estimatedCloudBytes: 0,
        reason: 'Missing file size. Keep local until the proof can be checked.',
      );
    }
    if (!attachment.isPdf) {
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.uploadAsIs,
        originalBytes: originalBytes,
        estimatedCloudBytes: originalBytes,
        reason: 'Not a PDF proof.',
      );
    }
    return planPdfBytes(
      byteSize: originalBytes,
      tier: tier,
      generatedPdf: generatedPdf,
      pageCount: attachment.pageCount,
      dataSaverLevel: attachment.dataSaverLevel,
    );
  }

  static CloudBackupFilePlan planPdfBytes({
    required int byteSize,
    CloudBackupTier tier = CloudBackupTier.freeTrial,
    bool generatedPdf = false,
    int? pageCount,
    ReceiptDataSaverLevel dataSaverLevel = ReceiptDataSaverLevel.original,
  }) {
    final originalBytes = byteSize < 0 ? 0 : byteSize;
    if (originalBytes == 0) {
      return const CloudBackupFilePlan(
        action: CloudBackupFileAction.localOnlyTooLarge,
        originalBytes: 0,
        estimatedCloudBytes: 0,
        reason: 'Empty PDF files are not cloud backup candidates.',
      );
    }
    if (tier.hasCloudStorage && originalBytes > tier.quotaBytes) {
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.localOnlyTooLarge,
        originalBytes: originalBytes,
        estimatedCloudBytes: originalBytes,
        reason: 'This PDF is larger than the current cloud tier.',
      );
    }
    if (generatedPdf) {
      final estimated = _estimatedBytes(
        originalBytes,
        optimizedGeneratedPdfRatio,
      );
      if (originalBytes <= generatedPdfImmediateBytes) {
        return CloudBackupFilePlan(
          action: CloudBackupFileAction.uploadAsIs,
          originalBytes: originalBytes,
          estimatedCloudBytes: originalBytes,
          reason: 'Generated PDF is small enough to upload as-is.',
        );
      }
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.useOptimizedCopy,
        originalBytes: originalBytes,
        estimatedCloudBytes: estimated,
        reason: 'Generated PDF should be optimized before cloud backup.',
      );
    }
    if (originalBytes <= freeTierImmediatePdfBytes &&
        dataSaverLevel != ReceiptDataSaverLevel.original) {
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.uploadAsIs,
        originalBytes: originalBytes,
        estimatedCloudBytes: originalBytes,
        reason: 'Receipt PDF is already within the free-tier immediate range.',
      );
    }
    if (originalBytes <= freeTierImmediatePdfBytes && (pageCount ?? 1) <= 10) {
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.uploadAsIs,
        originalBytes: originalBytes,
        estimatedCloudBytes: originalBytes,
        reason: 'Receipt PDF is small enough for cloud backup.',
      );
    }
    final estimated = _estimatedBytes(originalBytes, optimizedScannedPdfRatio);
    if (originalBytes <= freeTierDeferredPdfBytes) {
      return CloudBackupFilePlan(
        action: CloudBackupFileAction.deferUntilOptimized,
        originalBytes: originalBytes,
        estimatedCloudBytes: estimated,
        reason: 'Receipt PDF should be optimized or page-selected first.',
      );
    }
    return CloudBackupFilePlan(
      action: CloudBackupFileAction.localOnlyTooLarge,
      originalBytes: originalBytes,
      estimatedCloudBytes: estimated,
      reason: 'Receipt PDF is too large for automatic free-tier backup.',
    );
  }

  static int _estimatedBytes(int originalBytes, double ratio) {
    return (originalBytes * ratio).round().clamp(1, originalBytes);
  }
}
