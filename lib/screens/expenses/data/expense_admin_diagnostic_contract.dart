import 'expense_screen_telemetry.dart';

enum ExpenseAdminDiagnosticConsentStatus { notRequested, granted, denied }

enum ExpenseAdminDiagnosticImageKind { none, redactedOcrSourcePreview }

enum ExpenseAdminDiagnosticPrivacyScope {
  metadataOnly,
  redactedImageNoReceiptText,
}

enum ExpenseAdminDiagnosticSourceHandling {
  metadataOnly,
  originalUsedLocallyPreviewDerivedOnly,
}

enum ExpenseAdminDiagnosticPrivateRegionHandling {
  notEvaluated,
  cropOrMaskUserIdentifyingRegions,
}

enum ExpenseAdminDiagnosticQualityProofPurpose { none, imageQualityReviewOnly }

class ExpenseAdminDiagnosticArtifact {
  const ExpenseAdminDiagnosticArtifact({
    required this.artifactId,
    required this.consentStatus,
    required this.imageKind,
    required this.privacyScope,
    required this.sourceHandling,
    required this.privateRegionHandling,
    required this.qualityProofPurpose,
    required this.retentionPolicy,
    required this.ocrSourceRole,
    required this.redactionStatus,
    required this.cropStatus,
    required this.blurBucket,
    required this.glareBucket,
    required this.readabilityBucket,
    required this.failureStage,
    this.deviceTier = 'unknown',
    this.osFamily = 'unknown',
    this.osVersionBucket = 'unknown',
    this.appVersionBucket = 'unknown',
    this.storageSafetyBucket = 'unknown',
    this.confirmedCause = 'unknown',
    this.failedAt = 'unknown',
    this.evidence = 'none',
  });

  factory ExpenseAdminDiagnosticArtifact.fromOcrFailure({
    required String artifactId,
    required ExpenseFailureDiagnostic diagnostic,
    required ExpenseAdminDiagnosticConsentStatus consentStatus,
    required String blurBucket,
    required String glareBucket,
    required String readabilityBucket,
    required String deviceTier,
    required String osFamily,
    required String osVersionBucket,
    required String appVersionBucket,
    required String storageSafetyBucket,
    String retentionPolicy = 'auto_delete_14_days',
  }) {
    return ExpenseAdminDiagnosticArtifact(
      artifactId: artifactId,
      consentStatus: consentStatus,
      imageKind: ExpenseAdminDiagnosticImageKind.redactedOcrSourcePreview,
      privacyScope:
          ExpenseAdminDiagnosticPrivacyScope.redactedImageNoReceiptText,
      sourceHandling: ExpenseAdminDiagnosticSourceHandling
          .originalUsedLocallyPreviewDerivedOnly,
      privateRegionHandling: ExpenseAdminDiagnosticPrivateRegionHandling
          .cropOrMaskUserIdentifyingRegions,
      qualityProofPurpose:
          ExpenseAdminDiagnosticQualityProofPurpose.imageQualityReviewOnly,
      retentionPolicy: retentionPolicy,
      ocrSourceRole: 'original_ocr_source',
      redactionStatus: 'redacted_private_regions',
      cropStatus: 'cropped_to_quality_evidence',
      blurBucket: blurBucket,
      glareBucket: glareBucket,
      readabilityBucket: readabilityBucket,
      failureStage: diagnostic.failedAt,
      deviceTier: deviceTier,
      osFamily: osFamily,
      osVersionBucket: osVersionBucket,
      appVersionBucket: appVersionBucket,
      storageSafetyBucket: storageSafetyBucket,
      confirmedCause: diagnostic.confirmedCause,
      failedAt: diagnostic.failedAt,
      evidence: _adminDiagnosticEvidenceBucket(diagnostic.evidence),
    );
  }

  final String artifactId;
  final ExpenseAdminDiagnosticConsentStatus consentStatus;
  final ExpenseAdminDiagnosticImageKind imageKind;
  final ExpenseAdminDiagnosticPrivacyScope privacyScope;
  final ExpenseAdminDiagnosticSourceHandling sourceHandling;
  final ExpenseAdminDiagnosticPrivateRegionHandling privateRegionHandling;
  final ExpenseAdminDiagnosticQualityProofPurpose qualityProofPurpose;
  final String retentionPolicy;
  final String ocrSourceRole;
  final String redactionStatus;
  final String cropStatus;
  final String blurBucket;
  final String glareBucket;
  final String readabilityBucket;
  final String failureStage;
  final String deviceTier;
  final String osFamily;
  final String osVersionBucket;
  final String appVersionBucket;
  final String storageSafetyBucket;
  final String confirmedCause;
  final String failedAt;
  final String evidence;

  Map<String, Object?> toTelemetryMetadata() {
    return ExpenseTelemetryPolicy.sanitizeMetadata({
      'adminDiagnosticArtifactSchema': 'expense_admin_diagnostic_artifact_v1',
      'adminDiagnosticArtifactId': artifactId,
      'adminDiagnosticConsentStatus': consentStatus.name,
      'adminDiagnosticRetentionPolicy': retentionPolicy,
      'adminDiagnosticPrivacyScope': privacyScope.name,
      'adminDiagnosticImageKind': imageKind.name,
      'adminDiagnosticOcrSourceRole': ocrSourceRole,
      'adminDiagnosticRedactionStatus': redactionStatus,
      'adminDiagnosticCropStatus': cropStatus,
      'adminDiagnosticBlurBucket': blurBucket,
      'adminDiagnosticGlareBucket': glareBucket,
      'adminDiagnosticReadabilityBucket': readabilityBucket,
      'adminDiagnosticFailureStage': failureStage,
      'adminDiagnosticDeviceTier': deviceTier,
      'adminDiagnosticOsFamily': osFamily,
      'adminDiagnosticOsVersionBucket': osVersionBucket,
      'adminDiagnosticAppVersionBucket': appVersionBucket,
      'adminDiagnosticStorageSafetyBucket': storageSafetyBucket,
      'adminDiagnosticConfirmedCause': confirmedCause,
      'adminDiagnosticFailedAt': failedAt,
      'adminDiagnosticEvidence': evidence,
    });
  }

  bool get canUploadImagePreview {
    return consentStatus == ExpenseAdminDiagnosticConsentStatus.granted &&
        imageKind == ExpenseAdminDiagnosticImageKind.redactedOcrSourcePreview &&
        privacyScope ==
            ExpenseAdminDiagnosticPrivacyScope.redactedImageNoReceiptText &&
        sourceHandling ==
            ExpenseAdminDiagnosticSourceHandling
                .originalUsedLocallyPreviewDerivedOnly &&
        privateRegionHandling ==
            ExpenseAdminDiagnosticPrivateRegionHandling
                .cropOrMaskUserIdentifyingRegions &&
        qualityProofPurpose ==
            ExpenseAdminDiagnosticQualityProofPurpose.imageQualityReviewOnly &&
        redactionStatus == 'redacted_private_regions' &&
        cropStatus == 'cropped_to_quality_evidence';
  }
}

String _adminDiagnosticEvidenceBucket(String evidence) {
  final source = evidence.contains('source_pdf')
      ? 'pdf'
      : evidence.contains('source_photo')
      ? 'photo'
      : evidence.contains('source_importedText')
      ? 'text'
      : 'unknown';
  final warningMatch = RegExp(r'warning_([A-Za-z0-9]+)').firstMatch(evidence);
  final warning = warningMatch == null ? 'none' : warningMatch.group(1)!;
  final targetMatch = RegExp(r'target_([A-Za-z0-9_]+)').firstMatch(evidence);
  final target = _adminDiagnosticTargetBucket(targetMatch?.group(1));
  return 'warning_${warning}_source_${source}_target_$target';
}

String _adminDiagnosticTargetBucket(String? rawTarget) {
  final target = rawTarget?.trim();
  if (target == null || target.isEmpty) return 'unknown';
  const safeTargets = <String>{
    'unknown',
    'receipt',
    'receipt_sections',
    'photo',
    'photo_quality',
    'ocr_source',
    'parser_handoff',
    'line_items',
    'total',
    'subtotal',
    'tax',
    'date',
  };
  return safeTargets.contains(target) ? target : 'unknown';
}
