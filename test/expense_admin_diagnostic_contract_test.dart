import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_admin_diagnostic_contract.dart';
import 'package:maintaniac/screens/expenses/data/expense_ocr_failure_diagnostics.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';
import 'package:maintaniac/shared/receipts/receipt_processing_contract.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture.dart';

void main() {
  test(
    'allows redacted OCR source quality artifact metadata for admin review',
    () {
      const artifact = ExpenseAdminDiagnosticArtifact(
        artifactId: 'ocr_source_preview_20260701T120000Z',
        consentStatus: ExpenseAdminDiagnosticConsentStatus.granted,
        imageKind: ExpenseAdminDiagnosticImageKind.redactedOcrSourcePreview,
        privacyScope:
            ExpenseAdminDiagnosticPrivacyScope.redactedImageNoReceiptText,
        sourceHandling: ExpenseAdminDiagnosticSourceHandling
            .originalUsedLocallyPreviewDerivedOnly,
        privateRegionHandling: ExpenseAdminDiagnosticPrivateRegionHandling
            .cropOrMaskUserIdentifyingRegions,
        qualityProofPurpose:
            ExpenseAdminDiagnosticQualityProofPurpose.imageQualityReviewOnly,
        retentionPolicy: 'auto_delete_14_days',
        ocrSourceRole: 'original_ocr_source',
        redactionStatus: 'redacted_private_regions',
        cropStatus: 'cropped_to_quality_evidence',
        blurBucket: 'soft_blur_medium',
        glareBucket: 'glare_low',
        readabilityBucket: 'readable_review',
        failureStage: 'receipt_ocr',
        deviceTier: 'lightweight',
        osFamily: 'android',
        osVersionBucket: 'android_12_to_13',
        appVersionBucket: 'maintainiac_5_6',
        storageSafetyBucket: 'low_storage_review',
      );

      final metadata = artifact.toTelemetryMetadata();

      expect(artifact.canUploadImagePreview, isTrue);
      expect(
        metadata['adminDiagnosticArtifactSchema'],
        'expense_admin_diagnostic_artifact_v1',
      );
      expect(metadata['adminDiagnosticOcrSourceRole'], 'original_ocr_source');
      expect(metadata['adminDiagnosticBlurBucket'], 'soft_blur_medium');
      expect(metadata['adminDiagnosticDeviceTier'], 'lightweight');
      expect(metadata['adminDiagnosticOsFamily'], 'android');
      expect(metadata['adminDiagnosticOsVersionBucket'], 'android_12_to_13');
      expect(metadata['adminDiagnosticAppVersionBucket'], 'maintainiac_5_6');
      expect(
        metadata['adminDiagnosticStorageSafetyBucket'],
        'low_storage_review',
      );
      expect(metadata.toString(), isNot(contains('receipt text')));
      expect(metadata.toString(), isNot(contains('/tmp/receipt.jpg')));
      expect(metadata.toString(), isNot(contains('Galaxy')));
      expect(metadata.toString(), isNot(contains('deviceId')));
    },
  );

  test(
    'blocks admin image upload when original receipt is not derived safely',
    () {
      const artifact = ExpenseAdminDiagnosticArtifact(
        artifactId: 'ocr_source_preview_20260701T120000Z',
        consentStatus: ExpenseAdminDiagnosticConsentStatus.granted,
        imageKind: ExpenseAdminDiagnosticImageKind.redactedOcrSourcePreview,
        privacyScope:
            ExpenseAdminDiagnosticPrivacyScope.redactedImageNoReceiptText,
        sourceHandling: ExpenseAdminDiagnosticSourceHandling.metadataOnly,
        privateRegionHandling:
            ExpenseAdminDiagnosticPrivateRegionHandling.notEvaluated,
        qualityProofPurpose: ExpenseAdminDiagnosticQualityProofPurpose.none,
        retentionPolicy: 'auto_delete_14_days',
        ocrSourceRole: 'original_ocr_source',
        redactionStatus: 'redacted_private_regions',
        cropStatus: 'cropped_to_quality_evidence',
        blurBucket: 'soft_blur_medium',
        glareBucket: 'glare_low',
        readabilityBucket: 'readable_review',
        failureStage: 'receipt_ocr',
      );

      expect(artifact.canUploadImagePreview, isFalse);
    },
  );

  test(
    'blocks raw receipt content and paths from admin telemetry metadata',
    () {
      expect(
        () => ExpenseTelemetryPolicy.sanitizeMetadata({
          'adminDiagnosticArtifactId': 'safe_token',
          'receiptImage': '/tmp/private-receipt.jpg',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitizeMetadata({
          'adminDiagnosticArtifactId': 'safe_token',
          'receiptText': 'PRIVATE STORE 123 MAIN ST',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitizeMetadata({
          'adminDiagnosticArtifactId': '/tmp/private-receipt.jpg',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitizeMetadata({
          'adminDiagnosticArtifactId': 'safe_token',
          'deviceId': 'abc-123-private-device',
        }),
        throwsArgumentError,
      );
      expect(
        () => ExpenseTelemetryPolicy.sanitizeMetadata({
          'adminDiagnosticArtifactId': 'safe_token',
          'deviceModel': 'Galaxy S25 Ultra',
        }),
        throwsArgumentError,
      );
    },
  );

  test('builds privacy-safe admin snapshot from OCR failure diagnostics', () {
    final diagnostic = ExpenseOcrFailureDiagnostics.fromOcrResult(
      ReceiptOcrResult(
        rawText: 'PRIVATE STORE\nTOTAL 51.68',
        parserText: 'PRIVATE STORE\nTOTAL 51.68',
        textByAttachmentId: const {'photo-1': 'PRIVATE STORE TOTAL 51.68'},
        source: ReceiptProcessingSource.photo,
        stats: const ReceiptOcrReadStats(photosRead: 1),
        warnings: const [
          'Receipt photo quality needs review: bottom text is soft.',
        ],
      ),
    );
    final artifact = ExpenseAdminDiagnosticArtifact.fromOcrFailure(
      artifactId: 'ocr_quality_artifact_20260702T064900Z',
      diagnostic: diagnostic,
      consentStatus: ExpenseAdminDiagnosticConsentStatus.granted,
      blurBucket: 'bottom_soft_blur_risk',
      glareBucket: 'glare_low',
      readabilityBucket: 'review_needed',
      deviceTier: 'lightweight',
      osFamily: 'android',
      osVersionBucket: 'android_12_to_13',
      appVersionBucket: 'maintainiac_5_6',
      storageSafetyBucket: 'low_storage_review',
    );
    final metadata = artifact.toTelemetryMetadata();
    final encoded = metadata.toString().toLowerCase();

    expect(artifact.canUploadImagePreview, isTrue);
    expect(
      metadata['adminDiagnosticConfirmedCause'],
      'receipt_photo_quality_needs_review',
    );
    expect(metadata['adminDiagnosticFailedAt'], 'during_photo_ocr_read');
    expect(metadata['adminDiagnosticEvidence'], contains('warn_photoQuality'));
    expect(metadata['adminDiagnosticBlurBucket'], 'bottom_soft_blur_risk');
    expect(metadata['adminDiagnosticDeviceTier'], 'lightweight');
    expect(
      metadata['adminDiagnosticStorageSafetyBucket'],
      'low_storage_review',
    );
    expect(encoded, isNot(contains('private store')));
    expect(encoded, isNot(contains('51.68')));
    expect(encoded, isNot(contains('photo-1')));
  });

  test('buckets admin evidence target without private receipt hints', () {
    const diagnostic = ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.receiptOcr,
      failedAt: 'during_photo_ocr_read',
      confirmedCause: 'receipt_photo_quality_needs_review',
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence:
          'warning_photoQuality_source_photo_target_private_store_lowes_998877',
    );
    final artifact = ExpenseAdminDiagnosticArtifact.fromOcrFailure(
      artifactId: 'ocr_quality_artifact_private_target_guard',
      diagnostic: diagnostic,
      consentStatus: ExpenseAdminDiagnosticConsentStatus.granted,
      blurBucket: 'soft_blur_medium',
      glareBucket: 'glare_low',
      readabilityBucket: 'review_needed',
      deviceTier: 'lightweight',
      osFamily: 'android',
      osVersionBucket: 'android_12_to_13',
      appVersionBucket: 'maintainiac_5_6',
      storageSafetyBucket: 'low_storage_review',
    );

    final encoded = artifact.toTelemetryMetadata().toString().toLowerCase();

    expect(
      artifact.toTelemetryMetadata()['adminDiagnosticEvidence'],
      'warn_photoQuality_src_photo_tgt_unknown',
    );
    expect(encoded, isNot(contains('private_store')));
    expect(encoded, isNot(contains('lowes')));
    expect(encoded, isNot(contains('998877')));
  });

  test('preserves safe glare quality bucket in admin evidence', () {
    const diagnostic = ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.receiptOcr,
      failedAt: 'during_photo_ocr_read',
      confirmedCause: 'receipt_photo_quality_needs_review',
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence:
          'warning_photoQuality_quality_saved_glare_review_source_photo_target_private_store_total_998877',
    );
    final artifact = ExpenseAdminDiagnosticArtifact.fromOcrFailure(
      artifactId: 'ocr_quality_artifact_glare_bucket',
      diagnostic: diagnostic,
      consentStatus: ExpenseAdminDiagnosticConsentStatus.granted,
      blurBucket: 'not_blurry',
      glareBucket: 'glare_high',
      readabilityBucket: 'review_needed',
      deviceTier: 'high',
      osFamily: 'android',
      osVersionBucket: 'android_14_to_15',
      appVersionBucket: 'maintainiac_5_6',
      storageSafetyBucket: 'normal_storage',
    );

    final metadata = artifact.toTelemetryMetadata();
    final encoded = metadata.toString().toLowerCase();

    expect(
      metadata['adminDiagnosticEvidence'],
      'warn_photoQuality_src_photo_tgt_unknown_q_saved_glare_review',
    );
    expect(encoded, contains('saved_glare_review'));
    expect(encoded, isNot(contains('private_store')));
    expect(encoded, isNot(contains('998877')));
  });
}
