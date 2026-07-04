import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

import 'helpers/expense_screen_telemetry_harness.dart';

void main() {
  installExpenseTelemetryHiveLifecycle('expense_screen_telemetry_test_');

  test('allows only content-free receipt camera health metadata', () {
    final sanitized = ExpenseTelemetryPolicy.sanitize(
      ExpenseTelemetryEvent(
        type: ExpenseTelemetryEventType.ocrStarted,
        metadata: const {
          'source': 'expenses',
          'captureFlow': 'receipt_photo_review',
          'savedProofCount': 2,
          'ocrSourceCount': 1,
          'captureDiagnosticsCount': 2,
          'settingsContractVersion': 'receipt_native_camera_settings_v1',
          'settingsContractVersionBuckets': {
            'receipt_native_camera_settings_v1': 1,
          },
          'cloudAssistPlan': 'local_ocr_cloud_ocr_optional',
          'ocrDecisionPolicy': 'local_default_cloud_optional',
          'localOcrAvailable': true,
          'localOcrMode': 'lean_local_ocr',
          'localOcrDefault': true,
          'cloudOcrOptional': true,
          'cloudInventoryOptional': false,
          'cloudAssistRequiresExplicitChoice': true,
          'cloudAssistRequiresInternet': true,
          'cameraCaptureCloudRequired': false,
          'receiptReviewCloudRequired': false,
          'localCatalogMatchLimit': 250,
          'localInventoryCacheLimit': 1000,
          'parserPackCodes': ['core_receipt_text_v1', 'cloud_ocr_assist_v1'],
          'optionalLocalParserPackCodes': <String>[],
          'cloudFallbackParserPackCodes': ['cloud_ocr_assist_v1'],
          'parserPackAccuracyBands': {
            'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
            'cloud_ocr_assist_v1': 'cloud_ocr_best_available_provider',
          },
          'estimatedOptionalLocalPackBytes': 0,
          'userFacingPackDisclosureLabel':
              'No extra local parser download is required for this setup. '
              'Cloud OCR/parser fallback needs internet and must be chosen by '
              'the user. Accuracy disclosures: core_receipt_text_v1: '
              'ocr_text_95_99_when_photo_readable; cloud_ocr_assist_v1: '
              'cloud_ocr_best_available_provider.',
          'dataSaverLevel': 'maximum',
          'capturedPhotoMegapixelBuckets': {'high_9mp_to_18mp': 1},
          'capturedPhotoByteBuckets': {'normal_1mb_to_3mb': 1},
          'capturedPhotoBrightnessBuckets': {'captured_dim': 1},
          'capturedPhotoSharpnessBuckets': {'captured_sharp': 1},
          'capturedPhotoQualitySignals': {'review_before_saving': 1},
          'capturedPhotoExposureMismatches': {'live_ok_capture_dim': 1},
          'capturedPhotoBottomBrightnessBuckets': {'bottom_dim': 1},
          'capturedPhotoBottomEdgeScoreBuckets': {'bottom_edge_usable': 1},
          'capturedPhotoVerticalQualitySignals': {
            'bottom_darker_than_upper': 1,
          },
          'nativeCameraEngineBuckets': {'cameraX': 1},
          'nativeReceiptCameraSurfaceActualBuckets': {
            'maintainiac_native_android': 1,
          },
          'nativeReceiptCameraSurfaceVerificationBuckets': {
            'maintainiac_custom_surface_verified': 1,
          },
          'nativeCameraIdentityBuckets': {
            'maintainiac_in_app_receipt_camera': 1,
          },
          'nativeControlContractVersionBuckets': {
            'receipt_native_controls_v1': 1,
          },
          'nativeDevicePolicyBuckets': {'storage_saver_receipt_camera': 1},
          'nativeCameraWorkloadTierBuckets': {'light': 1},
          'nativeCameraResolutionTierBuckets': {'medium': 1},
          'nativeRecoveryFreshnessBuckets': {'stale': 1},
          'nativeRecoveryStorageStatusBuckets': {'partial_photos_available': 1},
          'capabilityPolicyCodeCounts': {'storage_constrained_small_proofs': 1},
          'nativeCaptureSourcePolicyCounts': {'storage_saver_native': 1},
          'capturedPhotoWidthMax': 3024,
          'capturedPhotoHeightMax': 4032,
          'brightnessBuckets': {'normal': 1, 'dark': 1},
          'readabilitySignalBuckets': {'readable': 1},
          'autoExposureDecisionBuckets': {'waiting_for_receipt_target': 1},
          'preCaptureExposureDecisionBuckets': {
            'brightening_before_capture': 1,
          },
          'preCaptureExposureAdjustmentTotal': 1,
          'preCaptureExposureAbortTotal': 1,
          'preCaptureExposureAbortReasonBuckets': {
            'camera_surface_inactive': 1,
          },
          'acceptedPhotoQualityOutcomeCounts': {'needs_review_before_ocr': 1},
          'acceptedPhotoHandoffOutcome': 'needs_review_before_ocr',
          'autoExposureBrightnessBuckets': {'dark_assisted': 1},
          'autoExposureCandidateBuckets': {'brighten': 1},
          'autoExposureCandidateFrameTotal': 2,
          'exposureAssistStatuses': {'auto_adjusted': 1},
          'framingConfidenceBuckets': {'usable': 2},
          'perspectiveReadinessBuckets': {
            'perspective_ready_safe_bounds': 1,
            'perspective_skipped_cut_off_risk': 1,
          },
          'photoCoverageStatuses': {'likelyCutOff': 1, 'likelyComplete': 1},
          'photoCoverageReasons': {
            'native_cut_off_risk': 1,
            'framing_ok_readable': 1,
          },
          'photoCoverageNeedsMoreCount': 1,
          'hasPossiblePartialReceiptPhotos': true,
          'focusStatusBuckets': {'requested': 1},
          'autoCaptureStatusBuckets': {'manual_only': 1},
          'closeActionBuckets': {'done_returned_captured_sections': 1},
          'backDispatchPathBuckets': {'top_bar_back_button': 1},
          'pendingCloseAfterCaptureCount': 1,
          'closeResultDeliveredCount': 1,
          'autoCaptureAllowedCount': 1,
          'autoCaptureCurrentlyAllowedCount': 1,
          'storageSafetyLevelBuckets': {'maximum': 1},
          'storageSafetyReasonBuckets': {'tight_storage_tiny_proofs': 1},
          'storageConstrainedCount': 1,
          'photoEditActions': {'manual_crop': 1, 'manual_rotate': 1},
          'savedPhotoWarningCounts': {'saved_photo_dimmer_than_preview': 1},
          'savedPhotoWarningCauseCounts': {
            'saved_photo_dim_or_live_to_saved_mismatch': 1,
          },
          'savedPhotoWarningSeverityCounts': {'warning': 1},
          'savedPhotoWarningActionCounts': {'review_or_add_light': 1},
          'savedPhotoParserRiskCounts': {'ocr_text_may_need_review': 1},
          'receiptRequiredBaseFootprintStatusCounts': {'review': 1},
          'receiptRequiredBaseFootprintCanShipCounts': {'true': 1},
          'receiptRequiredBaseFootprintReviewCounts': {'true': 1},
          'receiptRequiredBaseFootprintBlockingReasonCounts': <String, int>{},
          'receiptRequiredBaseFootprintReviewReasonCounts': {
            'full_offline_brain_over_100mb_optional_only': 1,
          },
          'hasSavedPhotoQualityWarning': true,
          'userEditedPhotoCount': 2,
          'edgeDetectionEnabledCount': 2,
          'tapFocusTotal': 3,
          'zoomGestureStartTotal': 2,
          'zoomChangeTotal': 1,
          'zoomUnavailableTotal': 1,
          'zoomStatusBuckets': {'zoom_changed': 2, 'camera_unavailable': 1},
          'tapFocusControlExpectedCount': 0,
          'continuousFocusExpectedCount': 1,
          'pinchZoomControlExpectedCount': 1,
          'exposureSliderControlExpectedCount': 1,
          'exposureResetControlExpectedCount': 1,
          'settingsControlExpectedCount': 1,
          'backControlExpectedCount': 1,
          'torchControlExpectedCount': 1,
          'settingsOpenTotal': 2,
          'scannerCleanupUsedCount': 1,
          'cleanupActionCount': 3,
          'cleanupActions': ['auto_orient', 'scanner_cleanup'],
          'stitchStatus': 'stitched',
          'stitchFallbackReason': 'stitched',
          'stitchConfidenceBucket': 'high',
          'stitchPairDiagnosticCounts': {'zoom_adjusted': 1},
          'ocrSourceHandoffStatus': 'stitched_ocr_source',
          'ocrSourceHandoffSignalCounts': {
            'receipt_handoff_ready_for_receipt_review': 1,
          },
          'ocrSourceStitchSignalCounts': {'stitched_ocr_source': 1},
          'ocrSourceScannerDecisionCounts': {
            'scanner_decision_ocr_source_enhanced_selected': 1,
          },
          'ocrSourceCaptureSourceSignalCounts': {
            'native_capture_source_maintainiac_native_camera': 1,
          },
          'ocrSourcePhotoQualityRiskCounts': {
            'ocr_source_saved_photo_dimmer_than_preview': 1,
          },
          'selectedReceiptLinePurpose': 'clientProof',
          'selectedReceiptLineCount': 3,
          'excludedReceiptLineCount': 2,
          'clientProofReviewLineCount': 1,
          'redactedReceiptLineCount': 2,
          'clientProofRedactionPlanStatus': 'review_required',
          'clientProofVisibleLineCount': 1,
          'clientProofHiddenLineCount': 2,
          'clientProofPlanReviewLineCount': 1,
        },
      ),
    );

    final metadata = sanitized['metadata'] as Map<String, Object?>;
    expect(metadata['captureFlow'], 'receipt_photo_review');
    expect(metadata['capturedPhotoMegapixelBuckets'], {'high_9mp_to_18mp': 1});
    expect(metadata['capturedPhotoByteBuckets'], {'normal_1mb_to_3mb': 1});
    expect(metadata['capturedPhotoBrightnessBuckets'], {'captured_dim': 1});
    expect(metadata['capturedPhotoSharpnessBuckets'], {'captured_sharp': 1});
    expect(metadata['capturedPhotoQualitySignals'], {
      'review_before_saving': 1,
    });
    expect(metadata['capturedPhotoExposureMismatches'], {
      'live_ok_capture_dim': 1,
    });
    expect(metadata['capturedPhotoBottomBrightnessBuckets'], {'bottom_dim': 1});
    expect(metadata['capturedPhotoBottomEdgeScoreBuckets'], {
      'bottom_edge_usable': 1,
    });
    expect(metadata['capturedPhotoVerticalQualitySignals'], {
      'bottom_darker_than_upper': 1,
    });
    expect(metadata['nativeCameraEngineBuckets'], {'cameraX': 1});
    expect(metadata['nativeReceiptCameraSurfaceActualBuckets'], {
      'maintainiac_native_android': 1,
    });
    expect(metadata['nativeReceiptCameraSurfaceVerificationBuckets'], {
      'maintainiac_custom_surface_verified': 1,
    });
    expect(metadata['nativeCameraIdentityBuckets'], {
      'maintainiac_in_app_receipt_camera': 1,
    });
    expect(metadata['zoomGestureStartTotal'], 2);
    expect(metadata['zoomChangeTotal'], 1);
    expect(metadata['zoomUnavailableTotal'], 1);
    expect(metadata['zoomStatusBuckets'], {
      'zoom_changed': 2,
      'camera_unavailable': 1,
    });
    expect(
      metadata['settingsContractVersion'],
      'receipt_native_camera_settings_v1',
    );
    expect(metadata['settingsContractVersionBuckets'], {
      'receipt_native_camera_settings_v1': 1,
    });
    expect(metadata['cloudAssistPlan'], 'local_ocr_cloud_ocr_optional');
    expect(metadata['ocrDecisionPolicy'], 'local_default_cloud_optional');
    expect(metadata['localOcrAvailable'], isTrue);
    expect(metadata['localOcrMode'], 'lean_local_ocr');
    expect(metadata['localOcrDefault'], isTrue);
    expect(metadata['cloudOcrOptional'], isTrue);
    expect(metadata['cloudInventoryOptional'], isFalse);
    expect(metadata['cloudAssistRequiresExplicitChoice'], isTrue);
    expect(metadata['cloudAssistRequiresInternet'], isTrue);
    expect(metadata['cameraCaptureCloudRequired'], isFalse);
    expect(metadata['receiptReviewCloudRequired'], isFalse);
    expect(metadata['localCatalogMatchLimit'], 250);
    expect(metadata['localInventoryCacheLimit'], 1000);
    expect(metadata['parserPackCodes'], [
      'core_receipt_text_v1',
      'cloud_ocr_assist_v1',
    ]);
    expect(metadata['optionalLocalParserPackCodes'], <String>[]);
    expect(metadata['cloudFallbackParserPackCodes'], ['cloud_ocr_assist_v1']);
    expect(metadata['parserPackAccuracyBands'], {
      'core_receipt_text_v1': 'ocr_text_95_99_when_photo_readable',
      'cloud_ocr_assist_v1': 'cloud_ocr_best_available_provider',
    });
    expect(metadata['estimatedOptionalLocalPackBytes'], 0);
    expect(
      metadata['userFacingPackDisclosureLabel'],
      'No extra local parser download is required for this setup. '
      'Cloud OCR/parser fallback needs internet and must be chosen by the '
      'user. Accuracy disclosures: core_receipt_text_v1: '
      'ocr_text_95_99_when_photo_readable; cloud_ocr_assist_v1: '
      'cloud_ocr_best_available_provider.',
    );
    expect(metadata['selectedReceiptLinePurpose'], 'clientProof');
    expect(metadata['selectedReceiptLineCount'], 3);
    expect(metadata['excludedReceiptLineCount'], 2);
    expect(metadata['clientProofReviewLineCount'], 1);
    expect(metadata['redactedReceiptLineCount'], 2);
    expect(metadata['clientProofRedactionPlanStatus'], 'review_required');
    expect(metadata['clientProofVisibleLineCount'], 1);
    expect(metadata['clientProofHiddenLineCount'], 2);
    expect(metadata['clientProofPlanReviewLineCount'], 1);
    expect(metadata['dataSaverLevel'], 'maximum');
    expect(metadata['nativeDevicePolicyBuckets'], {
      'storage_saver_receipt_camera': 1,
    });
    expect(metadata['nativeCameraWorkloadTierBuckets'], {'light': 1});
    expect(metadata['nativeCameraResolutionTierBuckets'], {'medium': 1});
    expect(metadata['capabilityPolicyCodeCounts'], {
      'storage_constrained_small_proofs': 1,
    });
    expect(metadata['nativeCaptureSourcePolicyCounts'], {
      'storage_saver_native': 1,
    });
    expect(metadata['capturedPhotoWidthMax'], 3024);
    expect(metadata['capturedPhotoHeightMax'], 4032);
    expect(metadata['photoEditActions'], {
      'manual_crop': 1,
      'manual_rotate': 1,
    });
    expect(metadata['savedPhotoWarningCounts'], {
      'saved_photo_dimmer_than_preview': 1,
    });
    expect(metadata['savedPhotoWarningCauseCounts'], {
      'saved_photo_dim_or_live_to_saved_mismatch': 1,
    });
    expect(metadata['savedPhotoWarningSeverityCounts'], {'warning': 1});
    expect(metadata['savedPhotoWarningActionCounts'], {
      'review_or_add_light': 1,
    });
    expect(metadata['savedPhotoParserRiskCounts'], {
      'ocr_text_may_need_review': 1,
    });
    expect(metadata['hasSavedPhotoQualityWarning'], isTrue);
    expect(metadata['autoExposureDecisionBuckets'], {
      'waiting_for_receipt_target': 1,
    });
    expect(metadata['preCaptureExposureDecisionBuckets'], {
      'brightening_before_capture': 1,
    });
    expect(metadata['preCaptureExposureAdjustmentTotal'], 1);
    expect(metadata['preCaptureExposureAbortTotal'], 1);
    expect(metadata['preCaptureExposureAbortReasonBuckets'], {
      'camera_surface_inactive': 1,
    });
    expect(metadata['acceptedPhotoQualityOutcomeCounts'], {
      'needs_review_before_ocr': 1,
    });
    expect(metadata['acceptedPhotoHandoffOutcome'], 'needs_review_before_ocr');
    expect(metadata['autoExposureBrightnessBuckets'], {'dark_assisted': 1});
    expect(metadata['autoExposureCandidateBuckets'], {'brighten': 1});
    expect(metadata['autoExposureCandidateFrameTotal'], 2);
    expect(metadata['cleanupActions'], ['auto_orient', 'scanner_cleanup']);
    expect(metadata['userEditedPhotoCount'], 2);
    expect(metadata['closeActionBuckets'], {
      'done_returned_captured_sections': 1,
    });
    expect(metadata['backDispatchPathBuckets'], {'top_bar_back_button': 1});
    expect(metadata['pendingCloseAfterCaptureCount'], 1);
    expect(metadata['perspectiveReadinessBuckets'], {
      'perspective_ready_safe_bounds': 1,
      'perspective_skipped_cut_off_risk': 1,
    });
    expect(metadata['photoCoverageStatuses'], {
      'likelyCutOff': 1,
      'likelyComplete': 1,
    });
    expect(metadata['photoCoverageReasons'], {
      'native_cut_off_risk': 1,
      'framing_ok_readable': 1,
    });
    expect(metadata['photoCoverageNeedsMoreCount'], 1);
    expect(metadata['hasPossiblePartialReceiptPhotos'], isTrue);
    expect(metadata['closeResultDeliveredCount'], 1);
    expect(metadata['autoCaptureAllowedCount'], 1);
    expect(metadata['autoCaptureCurrentlyAllowedCount'], 1);
    expect(metadata['storageSafetyLevelBuckets'], {'maximum': 1});
    expect(metadata['storageSafetyReasonBuckets'], {
      'tight_storage_tiny_proofs': 1,
    });
    expect(metadata['storageConstrainedCount'], 1);
    expect(metadata['ocrSourceHandoffStatus'], 'stitched_ocr_source');
    expect(metadata['ocrSourceHandoffSignalCounts'], {
      'receipt_handoff_ready_for_receipt_review': 1,
    });
    expect(metadata['ocrSourceStitchSignalCounts'], {'stitched_ocr_source': 1});
    expect(metadata['ocrSourceScannerDecisionCounts'], {
      'scanner_decision_ocr_source_enhanced_selected': 1,
    });
    expect(metadata['ocrSourceCaptureSourceSignalCounts'], {
      'native_capture_source_maintainiac_native_camera': 1,
    });
    expect(metadata['ocrSourcePhotoQualityRiskCounts'], {
      'ocr_source_saved_photo_dimmer_than_preview': 1,
    });

    expect(
      () => ExpenseTelemetryPolicy.sanitize(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: const {
            'cleanupActions': ['scanner cleanup with spaces'],
          },
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => ExpenseTelemetryPolicy.sanitize(
        ExpenseTelemetryEvent(
          type: ExpenseTelemetryEventType.ocrStarted,
          metadata: const {'storeName': 'LOWES'},
        ),
      ),
      throwsArgumentError,
    );
  });
}
