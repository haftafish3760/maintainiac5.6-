import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'helpers/receipt_native_quality_warning_expectations.dart';

void main() {
  test('photo review result flags bridged dim and glare capture wording', () {
    expectBridgedDimGlareCaptureWarnings();
  });

  test('uploaded receipt photos are tracked as imported capture source', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const [
        '/tmp/advance-email-top.png',
        '/tmp/advance-email-bottom.png',
      ],
      ocrSourcePhotoPaths: const [
        '/tmp/advance-email-top-ocr.png',
        '/tmp/advance-email-bottom-ocr.png',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/advance-email-top-ocr.png',
        '/tmp/advance-email-bottom-ocr.png',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/advance-email-top.png': {
          'captureFlow': 'existing_receipt_photo_import',
          'existingPhotoImportUsed': true,
          'existingPhotoImportRole': 'user_selected_receipt_photo',
        },
        '/tmp/advance-email-bottom.png': {
          'captureFlow': 'existing_receipt_photo_import',
          'existingPhotoImportUsed': true,
          'existingPhotoImportRole': 'user_selected_receipt_photo',
        },
      },
    );

    expect(
      result.nativeCaptureSourcePolicyCounts,
      containsPair('existing_photo_import', 2),
    );
    expect(result.nativeCaptureSourcePolicyOutcome, 'existing_photo_import');
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nativeCaptureSourcePolicyCounts',
        result.nativeCaptureSourcePolicyCounts,
      ),
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('captureSource=existing_photo_import'),
    );
  });

  test(
    'document scanner backup is tracked as fallback-only capture source',
    () {
      final result = ReceiptPhotoReviewResult(
        photoPaths: const ['/tmp/document-scanner-proof.jpg'],
        ocrSourcePhotoPaths: const ['/tmp/document-scanner-proof.jpg'],
        dataSaverLevel: ReceiptDataSaverLevel.balanced,
        stitchResult: ReceiptStitchResult.notNeeded([
          '/tmp/document-scanner-proof.jpg',
        ]),
        captureDiagnosticsByPhotoPath: const {
          '/tmp/document-scanner-proof.jpg': {
            'captureFlow': 'document_scanner_backup_receipt_photo',
            'documentScannerBackupUsed': true,
            'documentScannerBackupRole': 'fallback_only',
            'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
            'stockCameraUiAllowedAsPrimary': false,
          },
        },
      );

      expect(
        result.nativeCaptureSourcePolicyCounts,
        containsPair('document_scanner_backup', 1),
      );
      expect(
        result.nativeCaptureSourcePolicyOutcome,
        'document_scanner_backup',
      );
      expect(
        result.savedPhotoWarningCounts,
        containsPair('saved_photo_document_scanner_backup', 1),
      );
      expect(
        result.savedPhotoWarningActionCounts,
        containsPair('review_backup_scan_crop', 1),
      );
      expect(
        result.savedPhotoParserRiskCounts,
        containsPair('ocr_backup_scan_crop_may_need_review', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('saved_photo_action_review_backup_scan_crop', 1),
      );
      expect(
        result.receiptReaderHandoffCounts,
        containsPair('parser_risk_ocr_backup_scan_crop_may_need_review', 1),
      );
      expect(result.acceptedPhotoWarningProfile, 'saved_photo_ok');
    },
  );

  test('phone backup capture keeps focus review handoff counts', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/phone-backup-proof.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/phone-backup-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/phone-backup-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/phone-backup-proof.jpg': {
          'captureFlow': 'phone_camera_backup_receipt_photo',
          'phoneCameraBackupUsed': true,
          'phoneCameraBackupRole': 'fallback_only',
          'backupCaptureAuthorizedBy': 'maintainiac_native_unavailable',
          'stockCameraUiAllowedAsPrimary': false,
        },
      },
    );

    expect(
      result.savedPhotoWarningCounts,
      containsPair('saved_photo_phone_camera_backup', 1),
    );
    expect(
      result.savedPhotoWarningActionCounts,
      containsPair('review_phone_backup_focus', 1),
    );
    expect(
      result.savedPhotoParserRiskCounts,
      containsPair('ocr_phone_backup_focus_may_need_review', 1),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('saved_photo_action_review_phone_backup_focus', 1),
    );
    expect(
      result.receiptReaderHandoffCounts,
      containsPair('parser_risk_ocr_phone_backup_focus_may_need_review', 1),
    );
    expect(result.acceptedPhotoWarningProfile, 'saved_photo_ok');
  });

  test('photo review result tracks preview parity watch without blocking', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/readable-but-darker.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/readable-but-darker-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/readable-but-darker-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/readable-but-darker.jpg': {
          'latestCapturedPreviewParitySignal':
              'saved_photo_darker_than_preview_watch',
          'latestCapturedLiveToSavedLumaDeltaBucket':
              'saved_darker_than_preview',
          'latestCapturedBrightnessBucket': 'captured_readable',
          'capturedLightingEvidence': 'lighting_readable',
          'manualCapturePolicy':
              'guidance_advisory_manual_shutter_always_allowed',
          'nativeCaptureReviewTransitionPolicy':
              'captured_photos_must_open_review_then_receipt_details',
          'nativeCaptureReviewTransitionTarget':
              'receipt_photo_review_next_to_receipt_details',
          'nativeCaptureReviewDiscardPolicy':
              'never_discard_captured_photo_on_back',
          'latestCapturedAverageLuma': 118.0,
          'latestCapturedEdgeScore': 10.0,
        },
      },
    );

    expect(
      result.nativeCameraUiHealthCounts['preview_saved_darker_than_live_watch'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['captured_lighting_evidence_lighting_readable'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['manual_capture_not_blocked_by_quality_guidance'],
      1,
    );
    expect(
      result.acceptedPhotoWarningProfile,
      'saved_photo_dimmer_than_preview',
    );
    expect(
      result.savedPhotoWarningCounts['saved_photo_dimmer_than_preview'],
      1,
    );
    expect(result.savedPhotoWarningCauseCounts, {
      'saved_photo_dim_or_live_to_saved_mismatch': 1,
    });
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Check readability, then add light or retake if needed.',
    );
    expect(
      result.privacySafeOcrHandoffEvidenceLabel,
      contains('ui=preview_saved_darker_than_live_watch'),
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_preview_saved_darker_than_live_watch'],
      1,
    );
  });

  test('photo review result carries capture readiness counts', () {
    const quality = ReceiptPhotoQualityCheck(
      width: 1800,
      height: 2600,
      focusScore: 15,
      brightness: 148,
      contrast: 36,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: true,
    );
    final readiness = quality.captureReadiness(
      autoCaptureEnabled: true,
      stableFrameCount: 3,
      requiredStableFrames: 3,
    );
    const reviewQuality = ReceiptPhotoQualityCheck(
      width: 1600,
      height: 2200,
      focusScore: 7,
      brightness: 132,
      contrast: 30,
      cropScore: .70,
      textBandScore: 12,
      isLikelyReadable: false,
    );
    final reviewReadiness = reviewQuality.captureReadiness(
      autoCaptureEnabled: true,
      stableFrameCount: 4,
      requiredStableFrames: 3,
    );
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/auto-ready.jpg', '/tmp/review-quality.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/auto-ready-ocr.jpg',
        '/tmp/review-quality-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/auto-ready-ocr.jpg',
        '/tmp/review-quality-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: {
        '/tmp/auto-ready.jpg': readiness.diagnostics,
        '/tmp/review-quality.jpg': reviewReadiness.diagnostics,
      },
    );

    expect(
      result.nativeCameraUiHealthCounts['capture_readiness_auto_capture_ready'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['capture_readiness_manual_only_quality_review'],
      1,
    );
    expect(result.captureReadinessCounts, {
      'auto_capture_ready': 1,
      'manual_only_quality_review': 1,
    });
    expect(result.manualCaptureAllowedCount, 2);
    expect(result.autoCaptureAllowedCount, 1);
    expect(result.nativeCameraUiHealthCounts['manual_capture_allowed'], 2);
    expect(result.nativeCameraUiHealthCounts['auto_capture_allowed'], 1);
    expect(result.nativeCameraUiHealthCounts['auto_capture_held_back'], 1);
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_capture_readiness_auto_capture_ready'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_capture_readiness_manual_only_quality_review'],
      1,
    );
  });

  test('photo review result summarizes native exposure control outcomes', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/dim-assisted.jpg', '/tmp/manual-bright.jpg'],
      ocrSourcePhotoPaths: const [
        '/tmp/dim-assisted-ocr.jpg',
        '/tmp/manual-bright-ocr.jpg',
      ],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/dim-assisted-ocr.jpg',
        '/tmp/manual-bright-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/dim-assisted.jpg': {
          'preCaptureExposurePolicy':
              'receipt_paper_metering_dim_rescue_v2_manual_slider',
          'preCaptureExposureOutcome': 'lifted_for_dim_receipt',
          'selectedExposureBucket': 'exposure_baseline',
        },
        '/tmp/manual-bright.jpg': {
          'preCaptureExposurePolicy': 'receipt_paper_metering_manual_slider',
          'preCaptureExposureOutcome': 'kept_native_auto',
          'selectedExposureBucket': 'exposure_brighter',
        },
      },
    );

    expect(
      result
          .nativeCameraUiHealthCounts['exposure_policy_receipt_paper_metering_dim_rescue_v2_manual_slider'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['pre_capture_exposure_lifted_for_dim_receipt'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['pre_capture_exposure_lifted_dim_receipt'],
      1,
    );
    expect(
      result
          .nativeCameraUiHealthCounts['pre_capture_exposure_kept_native_auto'],
      1,
    );
    expect(
      result.nativeCameraUiHealthCounts['pre_capture_exposure_native_auto_ok'],
      1,
    );
    expect(result.nativeCameraUiHealthCounts['manual_brightness_baseline'], 1);
    expect(
      result.nativeCameraUiHealthCounts['manual_brightness_user_raised'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_pre_capture_exposure_lifted_dim_receipt'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['native_camera_ui_manual_brightness_user_raised'],
      1,
    );
    expect(
      result.privacySafeReceiptReaderHandoffMetadata,
      containsPair(
        'nativeCameraUiHealthCounts',
        result.nativeCameraUiHealthCounts,
      ),
    );
  });

  test('photo review result summarizes critical saved-photo warnings', () {
    final result = ReceiptPhotoReviewResult(
      photoPaths: const ['/tmp/dark.jpg', '/tmp/soft.jpg'],
      ocrSourcePhotoPaths: const ['/tmp/dark-ocr.jpg', '/tmp/soft-ocr.jpg'],
      dataSaverLevel: ReceiptDataSaverLevel.balanced,
      stitchResult: ReceiptStitchResult.notNeeded([
        '/tmp/dark-ocr.jpg',
        '/tmp/soft-ocr.jpg',
      ]),
      captureDiagnosticsByPhotoPath: const {
        '/tmp/dark.jpg': {
          'latestCapturedExposureMismatch':
              'pre_capture_brightened_still_too_dark',
          'latestCapturedBrightnessBucket': 'captured_too_dark',
        },
        '/tmp/soft.jpg': {
          'latestCapturedQualitySignal': 'retake_blur_risk',
          'latestCapturedSharpnessBucket': 'captured_soft_blur_risk',
        },
      },
    );

    expect(result.hasSavedPhotoQualityWarning, isTrue);
    expect(result.savedPhotoWarningCodes, [
      'saved_photo_brightness_assist_failed_dark',
      'saved_photo_soft_blur_risk',
    ]);
    expect(result.savedPhotoWarningSeverities, ['critical', 'critical']);
    expect(result.savedPhotoWarningSeverityCounts, {'critical': 2});
    expect(result.savedPhotoWarningCounts, {
      'saved_photo_brightness_assist_failed_dark': 1,
      'saved_photo_soft_blur_risk': 1,
    });
    expect(result.savedPhotoParserRiskCounts, {
      'ocr_item_prices_may_fail': 1,
      'ocr_text_or_total_may_fail': 1,
    });
    expect(result.savedPhotoWarningReviewActionLabels, [
      'Turn on receipt light or retake',
      'Retake while holding steady',
    ]);
    expect(
      result.acceptedPhotoWarningReviewActionLabel,
      'Turn on receipt light or retake',
    );
    expect(
      result.acceptedPhotoWarningProfile,
      'saved_photo_brightness_assist_failed_dark',
    );
    expect(
      result.acceptedPhotoHandoffActionLabel,
      'Retake with the receipt light before reviewing receipt lines.',
    );
    expect(
      result.receiptReaderHandoffCounts['parser_risk_ocr_item_prices_may_fail'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['parser_risk_ocr_text_or_total_may_fail'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['saved_photo_action_turn_on_light_or_retake'],
      1,
    );
    expect(
      result
          .receiptReaderHandoffCounts['saved_photo_action_retake_hold_steady'],
      1,
    );
  });
}
