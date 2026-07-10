import '../../backup/cloud_backup_quota.dart';
import 'receipt_capture_models.dart';

class ReceiptCaptureStorageEstimate {
  const ReceiptCaptureStorageEstimate({
    required this.dataSaverLevel,
    required this.cloudQuota,
    this.averageOriginalPhotoBytes = 24 * 1024 * 1024,
    this.photoCount = 1,
  });

  final ReceiptDataSaverLevel dataSaverLevel;
  final CloudBackupQuotaCheck cloudQuota;
  final int averageOriginalPhotoBytes;
  final int photoCount;

  ReceiptProofTargetSizePolicy get proofPolicy =>
      dataSaverLevel.proofTargetSizePolicy;

  int get safePhotoCount => photoCount < 1 ? 1 : photoCount;
  int get safeAverageOriginalPhotoBytes => averageOriginalPhotoBytes < 1
      ? 24 * 1024 * 1024
      : averageOriginalPhotoBytes;

  int get estimatedBytesPerSavedProof {
    if (proofPolicy.keepsOriginalLocalOnly) {
      return safeAverageOriginalPhotoBytes;
    }
    return proofPolicy.targetBytes;
  }

  int get estimatedProofBytesForCapture =>
      estimatedBytesPerSavedProof * safePhotoCount;

  int get estimatedOriginalBytesForCapture =>
      safeAverageOriginalPhotoBytes * safePhotoCount;

  int get estimatedCloudBackedProofsRemaining {
    if (cloudQuota.isLocalOnly || !proofPolicy.cloudBackupDefaultAllowed) {
      return 0;
    }
    final bytes = estimatedBytesPerSavedProof;
    if (bytes <= 0) return 0;
    return cloudQuota.remainingAfterSaveBytes ~/ bytes;
  }

  bool get storesOriginalByDefault => proofPolicy.keepsOriginalLocalOnly;
  bool get asksEveryReceiptRecommended =>
      dataSaverLevel == ReceiptDataSaverLevel.original ||
      proofPolicy.requiresReadabilityReview ||
      cloudQuota.wouldExceedCloudTier;

  String get estimatedBytesPerSavedProofLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedBytesPerSavedProof);
  String get estimatedProofBytesForCaptureLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedProofBytesForCapture);
  String get estimatedOriginalBytesForCaptureLabel =>
      ReceiptStorageFormatter.formatBytes(estimatedOriginalBytesForCapture);

  String get approximatePhotosRemainingLabel {
    if (cloudQuota.isLocalOnly) return 'Cloud backup off';
    if (!proofPolicy.cloudBackupDefaultAllowed) {
      return 'Original photos stay local unless you choose backup';
    }
    final count = estimatedCloudBackedProofsRemaining;
    if (count <= 0) return 'No cloud proof room at this setting';
    return 'About $count more ${count == 1 ? 'photo' : 'photos'} at this setting';
  }

  String get userFacingSummary {
    final source = storesOriginalByDefault
        ? 'keeps the original local photo'
        : 'saves about $estimatedBytesPerSavedProofLabel per proof photo';
    final original =
        'A full camera photo may be about $estimatedOriginalBytesForCaptureLabel for this capture before proof compression.';
    return '$source. $original $approximatePhotosRemainingLabel.';
  }

  Map<String, Object?> toPrivacySafeDiagnostics() {
    return {
      'receiptStorageEstimateDataSaverLevel': dataSaverLevel.name,
      'receiptStorageEstimatePolicyCode': proofPolicy.policyCode,
      'receiptStorageEstimatePhotoCount': safePhotoCount,
      'receiptStorageEstimateBytesPerProof': estimatedBytesPerSavedProof,
      'receiptStorageEstimateProofBytesForCapture':
          estimatedProofBytesForCapture,
      'receiptStorageEstimateOriginalBytesForCapture':
          estimatedOriginalBytesForCapture,
      'receiptStorageEstimateCloudBackedProofsRemaining':
          estimatedCloudBackedProofsRemaining,
      'receiptStorageEstimateAskEveryReceiptRecommended':
          asksEveryReceiptRecommended,
      'receiptStorageEstimateSummary': userFacingSummary,
    };
  }
}
