import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_screen_telemetry.dart';

void expectExpenseCommandCenterSummaryTelemetry(
  ExpenseTelemetryHealthSnapshot snapshot,
  Map<String, Object?> map,
  String encoded,
) {
  expect(map['schema'], 'expense_screen_telemetry_health_v1');
  expect(snapshot.screenOpenCount, 1);
  expect(snapshot.averageTimeSpentSeconds, 120);
  expect(snapshot.addExpenseAbandonmentRate, 1);
  expect(snapshot.ocrSuccessRate, 0);
  expect(snapshot.receiptPhotoCoverageStatusCounts, {
    'likelycutoff': 1,
    'likelycomplete': 1,
  });
  expect(snapshot.receiptPhotoCoverageReasonCounts, {
    'native_cut_off_risk': 1,
    'framing_ok_readable': 1,
  });
  expect(snapshot.receiptPhotoCoverageNeedsMoreCount, 1);
  expect(snapshot.receiptPhotoCoverageNeedsMoreRate, 1);
  expect(snapshot.topReceiptPhotoCoverageStatus, 'likelycutoff');
  expect(snapshot.topReceiptPhotoCoverageReason, 'native_cut_off_risk');
  expect(map['receiptPhotoCoverageNeedsMoreCount'], 1);
  expect(snapshot.savedPhotoWarningCounts, {
    'saved_photo_dimmer_than_preview': 1,
  });
  expect(snapshot.savedPhotoWarningCauseCounts, {
    'saved_photo_dim_or_live_to_saved_mismatch': 1,
  });
  expect(snapshot.savedPhotoWarningSeverityCounts, {'warning': 1});
  expect(snapshot.savedPhotoWarningActionCounts, {'review_or_add_light': 1});
  expect(snapshot.savedPhotoParserRiskCounts, {'ocr_text_may_need_review': 1});
  expect(snapshot.receiptRequiredBaseFootprintStatusCounts, {'review': 1});
  expect(snapshot.receiptRequiredBaseFootprintCanShipCounts, {'true': 1});
  expect(snapshot.receiptRequiredBaseFootprintReviewCounts, {'true': 1});
  expect(snapshot.receiptRequiredBaseFootprintBlockingReasonCounts, isEmpty);
  expect(snapshot.receiptRequiredBaseFootprintReviewReasonCounts, {
    'full_offline_brain_over_100mb_optional_only': 1,
  });
  expect(snapshot.topReceiptRequiredBaseFootprintStatus, 'review');
  expect(
    snapshot.topReceiptRequiredBaseFootprintReviewReason,
    'full_offline_brain_over_100mb_optional_only',
  );
  expect(map['receiptRequiredBaseFootprintStatusCounts'], {'review': 1});
  expect(map['topReceiptRequiredBaseFootprintStatus'], 'review');
  expect(snapshot.savedPhotoQualityWarningCount, 1);
  expect(snapshot.savedPhotoQualityWarningRate, 1);
  expect(snapshot.savedPhotoCriticalWarningCount, 0);
  expect(snapshot.savedPhotoCriticalWarningRate, 0);
  expect(snapshot.topSavedPhotoWarning, 'saved_photo_dimmer_than_preview');
  expect(
    snapshot.topSavedPhotoWarningCause,
    'saved_photo_dim_or_live_to_saved_mismatch',
  );
  expect(snapshot.topSavedPhotoWarningSeverity, 'warning');
  expect(snapshot.topSavedPhotoWarningActionCode, 'review_or_add_light');
  expect(snapshot.topSavedPhotoWarningAction, contains('lighting'));
  expect(snapshot.topSavedPhotoParserRisk, 'ocr_text_may_need_review');
  expect(snapshot.preCaptureExposureDecisionCounts, {
    'brightening_before_capture': 1,
  });
  expect(snapshot.preCaptureExposureAdjustmentCount, 1);
  expect(snapshot.preCaptureExposureAdjustmentRate, 1);
  expect(snapshot.nativePreCaptureExposureAbortCount, 1);
  expect(snapshot.nativePreCaptureExposureAbortReasonCounts, {
    'camera_surface_inactive': 1,
  });
  expect(snapshot.topPreCaptureExposureDecision, 'brightening_before_capture');
  expect(
    snapshot.topNativePreCaptureExposureAbortReason,
    'camera_surface_inactive',
  );
  expect(snapshot.autoExposureDecisionCounts, {'brightened_preview': 1});
  expect(snapshot.autoExposureBrightnessCounts, {'preview_dim': 1});
  expect(snapshot.autoExposureCandidateCounts, {'stable_receipt_text': 1});
  expect(snapshot.exposureAssistStatusCounts, {'active': 1});
  expect(snapshot.autoExposureCandidateFrameCount, 4);
  expect(snapshot.manualBrightnessChangeCount, 1);
  expect(snapshot.nativeTapFocusControlExpectedCount, 0);
  expect(snapshot.nativeContinuousFocusExpectedCount, 1);
  expect(snapshot.nativePinchZoomControlExpectedCount, 1);
  expect(snapshot.nativeExposureSliderControlExpectedCount, 1);
  expect(snapshot.nativeExposureResetControlExpectedCount, 1);
  expect(snapshot.nativeSettingsControlExpectedCount, 1);
  expect(snapshot.nativeBackControlExpectedCount, 1);
  expect(snapshot.nativeTorchControlExpectedCount, 1);
  expect(snapshot.nativeSettingsOpenCount, 2);
  expect(snapshot.nativeZoomGestureStartCount, 2);
  expect(snapshot.nativeZoomChangeCount, 1);
  expect(snapshot.nativeZoomUnavailableCount, 1);
  expect(snapshot.nativeCaptureReadinessCodeCounts, {
    'manual_only_quality_review': 1,
  });
  expect(snapshot.topNativeCaptureReadinessCode, 'manual_only_quality_review');
  expect(snapshot.nativeZoomStatusCounts, {
    'zoom_changed': 2,
    'camera_unavailable': 1,
  });
  expect(snapshot.topNativeZoomStatus, 'zoom_changed');
  expect(snapshot.nativeBackDispatchPathCounts, {'top_bar_back_button': 1});
  expect(snapshot.topNativeBackDispatchPath, 'top_bar_back_button');
  expect(snapshot.topAutoExposureDecision, 'brightened_preview');
  expect(snapshot.topAutoExposureBrightness, 'preview_dim');
  expect(snapshot.topAutoExposureCandidate, 'stable_receipt_text');
  expect(snapshot.topExposureAssistStatus, 'active');
  expect(snapshot.acceptedPhotoQualityOutcomeCounts, {
    'needs_review_before_ocr': 1,
  });
  expect(snapshot.topAcceptedPhotoQualityOutcome, 'needs_review_before_ocr');
  expect(snapshot.capturedPhotoBrightnessCounts, {'captured_dim': 1});
  expect(snapshot.capturedPhotoSharpnessCounts, {'captured_sharp': 1});
  expect(snapshot.capturedPhotoExposureMismatchCounts, {
    'live_ok_capture_dim': 1,
  });
  expect(snapshot.capturedPhotoQualitySignalCounts, {
    'review_before_saving': 1,
  });
  expect(snapshot.capturedPhotoBottomBrightnessCounts, {'bottom_dim': 1});
  expect(snapshot.capturedPhotoBottomEdgeScoreCounts, {
    'bottom_edge_usable': 1,
  });
  expect(snapshot.capturedPhotoVerticalQualitySignalCounts, {
    'bottom_darker_than_upper': 1,
  });
  expect(snapshot.topCapturedPhotoBrightness, 'captured_dim');
  expect(snapshot.topCapturedPhotoSharpness, 'captured_sharp');
  expect(snapshot.topCapturedPhotoExposureMismatch, 'live_ok_capture_dim');
  expect(snapshot.topCapturedPhotoQualitySignal, 'review_before_saving');
  expect(snapshot.topCapturedPhotoBottomBrightness, 'bottom_dim');
  expect(snapshot.topCapturedPhotoBottomEdgeScore, 'bottom_edge_usable');
  expect(
    snapshot.topCapturedPhotoVerticalQualitySignal,
    'bottom_darker_than_upper',
  );
  expect(snapshot.nativeCameraEngineCounts, {'camerax': 1});
  expect(snapshot.nativeReceiptCameraSurfaceActualCounts, {
    'maintainiac_native_android': 1,
  });
  expect(snapshot.nativeReceiptCameraSurfaceVerificationCounts, {
    'maintainiac_custom_surface_verified': 1,
  });
  expect(snapshot.nativeCameraIdentityCounts, {
    'maintainiac_in_app_receipt_camera': 1,
  });
  expect(snapshot.nativeSettingsContractVersionCounts, {
    'receipt_native_camera_settings_v1': 1,
  });
  expect(snapshot.nativeControlContractVersionCounts, {
    'receipt_native_controls_v1': 1,
  });
  expect(
    snapshot.topNativeControlContractVersion,
    'receipt_native_controls_v1',
  );
  expect(snapshot.receiptCloudAssistPlanCounts, {
    'local_ocr_cloud_ocr_cloud_inventory_optional': 1,
    'local_only': 2,
  });
  expect(snapshot.receiptLocalOcrModeCounts, {
    'lean_local_ocr': 1,
    'full_local_ocr': 2,
  });
  expect(snapshot.receiptParserDepthCounts, {'detailed': 1, 'price_only': 2});
  expect(snapshot.receiptParserPackCodeCounts, {
    'core_receipt_text_v1': 1,
    'general_expense_lines_v1': 1,
    'materials_inventory_regional_v1': 1,
  });
  expect(snapshot.receiptOptionalLocalParserPackCodeCounts, {
    'general_expense_lines_v1': 1,
  });
  expect(snapshot.receiptCloudFallbackParserPackCodeCounts, {
    'materials_inventory_regional_v1': 1,
    'cloud_ocr_assist_v1': 1,
  });
  expect(snapshot.receiptParserPackAccuracyBandCounts, {
    'ocr_text_95_99_when_photo_readable': 1,
    'parser_line_items_90_97_by_vendor_pattern': 1,
    'inventory_match_80_99_by_installed_trade_pack': 1,
  });
  expect(snapshot.receiptEstimatedOptionalLocalPackBytesTotal, 25165824);
  expect(snapshot.receiptEstimatedOptionalLocalPackBytesMax, 25165824);
  expect(snapshot.receiptCloudOcrOptionalCount, 3);
  expect(snapshot.receiptCloudInventoryOptionalCount, 3);
  expect(
    snapshot.topReceiptParserPackDisclosureLabel,
    'Optional local parser add-ons use about 24.0 MB. Cloud OCR/parser fallback needs internet and must be chosen by the user. Accuracy disclosures: core_receipt_text_v1: ocr_text_95_99_when_photo_readable; general_expense_lines_v1: parser_line_items_90_97_by_vendor_pattern; materials_inventory_regional_v1: inventory_match_80_99_by_installed_trade_pack.',
  );
  expect(snapshot.nativeDevicePolicyCounts, {
    'storage_saver_receipt_camera': 1,
  });
  expect(snapshot.nativeCameraWorkloadTierCounts, {'light': 1});
  expect(snapshot.nativeCameraResolutionTierCounts, {'medium': 1});
  expect(snapshot.nativeRecoveryResumeStatusCounts, {
    'resume_review_started': 1,
  });
  expect(snapshot.nativeRecoveryFreshnessCounts, {'stale': 1});
  expect(snapshot.nativeRecoveryStorageStatusCounts, {
    'partial_photos_available': 1,
  });
  expect(snapshot.nativeRecoveryRecoveredPhotoCount, 2);
  expect(snapshot.nativeRecoveryMultipleSectionCount, 1);
  expect(snapshot.topNativeCameraEngine, 'camerax');
  expect(
    snapshot.topNativeReceiptCameraSurfaceActual,
    'maintainiac_native_android',
  );
  expect(
    snapshot.topNativeReceiptCameraSurfaceVerification,
    'maintainiac_custom_surface_verified',
  );
  expect(snapshot.topNativeCameraIdentity, 'maintainiac_in_app_receipt_camera');
  expect(
    snapshot.topNativeSettingsContractVersion,
    'receipt_native_camera_settings_v1',
  );
  expect(snapshot.topReceiptCloudAssistPlan, 'local_only');
  expect(snapshot.topReceiptLocalOcrMode, 'full_local_ocr');
  expect(snapshot.topReceiptParserDepth, 'price_only');
  expect(snapshot.topReceiptParserPackCode, 'core_receipt_text_v1');
  expect(
    snapshot.topReceiptOptionalLocalParserPackCode,
    'general_expense_lines_v1',
  );
  expect(snapshot.topReceiptCloudFallbackParserPackCode, 'cloud_ocr_assist_v1');
  expect(
    snapshot.topReceiptParserPackAccuracyBand,
    'inventory_match_80_99_by_installed_trade_pack',
  );
  expect(snapshot.topNativeDevicePolicy, 'storage_saver_receipt_camera');
  expect(snapshot.topNativeCameraWorkloadTier, 'light');
  expect(snapshot.topNativeCameraResolutionTier, 'medium');
  expect(snapshot.topNativeRecoveryResumeStatus, 'resume_review_started');
  expect(snapshot.topNativeRecoveryFreshness, 'stale');
  expect(snapshot.topNativeRecoveryStorageStatus, 'partial_photos_available');
  expect(snapshot.topNativeRecoveryAction, contains('missing receipt photos'));
  expect(snapshot.capabilityPolicyCodeCounts, {
    'storage_constrained_small_proofs': 1,
  });
  expect(snapshot.topCapabilityPolicyCode, 'storage_constrained_small_proofs');
  expect(snapshot.nativeCaptureSourcePolicyCounts, {'storage_saver_native': 1});
  expect(snapshot.topNativeCaptureSourcePolicy, 'storage_saver_native');
  expect(snapshot.stitchStatusCounts, {'stitched': 1});
  expect(snapshot.stitchFallbackReasonCounts, {'stitched': 1});
  expect(snapshot.stitchConfidenceBucketCounts, {'high': 1});
  expect(snapshot.stitchPairDiagnosticCounts, {'zoom_adjusted': 1});
  expect(snapshot.topStitchStatus, 'stitched');
  expect(snapshot.topStitchFallbackReason, 'stitched');
  expect(snapshot.topStitchConfidenceBucket, 'high');
  expect(snapshot.topStitchPairDiagnostic, 'zoom_adjusted');
  expect(map['receiptParserPackCodeCounts'], {
    'core_receipt_text_v1': 1,
    'general_expense_lines_v1': 1,
    'materials_inventory_regional_v1': 1,
  });
  expect(map['receiptOptionalLocalParserPackCodeCounts'], {
    'general_expense_lines_v1': 1,
  });
  expect(map['receiptCloudFallbackParserPackCodeCounts'], {
    'materials_inventory_regional_v1': 1,
    'cloud_ocr_assist_v1': 1,
  });
  expect(map['receiptParserPackAccuracyBandCounts'], {
    'ocr_text_95_99_when_photo_readable': 1,
    'parser_line_items_90_97_by_vendor_pattern': 1,
    'inventory_match_80_99_by_installed_trade_pack': 1,
  });
  expect(map['receiptEstimatedOptionalLocalPackBytesTotal'], 25165824);
  expect(map['receiptEstimatedOptionalLocalPackBytesMax'], 25165824);
  expect(map['topReceiptParserPackCode'], 'core_receipt_text_v1');
  expect(
    map['topReceiptOptionalLocalParserPackCode'],
    'general_expense_lines_v1',
  );
  expect(map['topReceiptCloudFallbackParserPackCode'], 'cloud_ocr_assist_v1');
  expect(
    map['topReceiptParserPackAccuracyBand'],
    'inventory_match_80_99_by_installed_trade_pack',
  );
  expect(
    map['topReceiptParserPackDisclosureLabel'],
    'Optional local parser add-ons use about 24.0 MB. Cloud OCR/parser fallback needs internet and must be chosen by the user. Accuracy disclosures: core_receipt_text_v1: ocr_text_95_99_when_photo_readable; general_expense_lines_v1: parser_line_items_90_97_by_vendor_pattern; materials_inventory_regional_v1: inventory_match_80_99_by_installed_trade_pack.',
  );
  expect(map['savedPhotoQualityWarningCount'], 1);
  expect(map['savedPhotoQualityWarningRate'], 1);
  expect(map['savedPhotoWarningCauseCounts'], {
    'saved_photo_dim_or_live_to_saved_mismatch': 1,
  });
  expect(map['savedPhotoWarningSeverityCounts'], {'warning': 1});
  expect(map['savedPhotoWarningActionCounts'], {'review_or_add_light': 1});
  expect(map['savedPhotoParserRiskCounts'], {'ocr_text_may_need_review': 1});
  expect(map['savedPhotoCriticalWarningCount'], 0);
  expect(map['savedPhotoCriticalWarningRate'], 0);
  expect(
    map['topSavedPhotoWarningCause'],
    'saved_photo_dim_or_live_to_saved_mismatch',
  );
  expect(map['topSavedPhotoWarningSeverity'], 'warning');
  expect(map['topSavedPhotoWarningActionCode'], 'review_or_add_light');
  expect(map['topSavedPhotoWarningAction'], contains('lighting'));
  expect(map['topSavedPhotoParserRisk'], 'ocr_text_may_need_review');
  expect(map['preCaptureExposureDecisionCounts'], {
    'brightening_before_capture': 1,
  });
  expect(map['preCaptureExposureAdjustmentCount'], 1);
  expect(map['preCaptureExposureAdjustmentRate'], 1);
  expect(map['topPreCaptureExposureDecision'], 'brightening_before_capture');
  expect(map['autoExposureDecisionCounts'], {'brightened_preview': 1});
  expect(map['autoExposureBrightnessCounts'], {'preview_dim': 1});
  expect(map['autoExposureCandidateCounts'], {'stable_receipt_text': 1});
  expect(map['exposureAssistStatusCounts'], {'active': 1});
  expect(map['autoExposureCandidateFrameCount'], 4);
  expect(map['manualBrightnessChangeCount'], 1);
  expect(map['topAutoExposureDecision'], 'brightened_preview');
  expect(map['topAutoExposureBrightness'], 'preview_dim');
  expect(map['topAutoExposureCandidate'], 'stable_receipt_text');
  expect(map['topExposureAssistStatus'], 'active');
  expect(map['acceptedPhotoQualityOutcomeCounts'], {
    'needs_review_before_ocr': 1,
  });
  expect(map['topAcceptedPhotoQualityOutcome'], 'needs_review_before_ocr');
  expect(map['capturedPhotoBrightnessCounts'], {'captured_dim': 1});
  expect(map['capturedPhotoSharpnessCounts'], {'captured_sharp': 1});
  expect(map['capturedPhotoExposureMismatchCounts'], {
    'live_ok_capture_dim': 1,
  });
  expect(map['capturedPhotoQualitySignalCounts'], {'review_before_saving': 1});
  expect(map['capturedPhotoBottomBrightnessCounts'], {'bottom_dim': 1});
  expect(map['capturedPhotoBottomEdgeScoreCounts'], {'bottom_edge_usable': 1});
  expect(map['capturedPhotoVerticalQualitySignalCounts'], {
    'bottom_darker_than_upper': 1,
  });
  expect(map['topCapturedPhotoBrightness'], 'captured_dim');
  expect(map['topCapturedPhotoSharpness'], 'captured_sharp');
  expect(map['topCapturedPhotoExposureMismatch'], 'live_ok_capture_dim');
  expect(map['topCapturedPhotoQualitySignal'], 'review_before_saving');
  expect(map['topCapturedPhotoBottomBrightness'], 'bottom_dim');
  expect(map['topCapturedPhotoBottomEdgeScore'], 'bottom_edge_usable');
  expect(
    map['topCapturedPhotoVerticalQualitySignal'],
    'bottom_darker_than_upper',
  );
  expect(map['nativeCameraEngineCounts'], {'camerax': 1});
  expect(map['nativeReceiptCameraSurfaceActualCounts'], {
    'maintainiac_native_android': 1,
  });
  expect(map['nativeReceiptCameraSurfaceVerificationCounts'], {
    'maintainiac_custom_surface_verified': 1,
  });
  expect(map['nativeCameraIdentityCounts'], {
    'maintainiac_in_app_receipt_camera': 1,
  });
  expect(map['nativeSettingsContractVersionCounts'], {
    'receipt_native_camera_settings_v1': 1,
  });
  expect(map['nativeControlContractVersionCounts'], {
    'receipt_native_controls_v1': 1,
  });
  expect(map['topNativeControlContractVersion'], 'receipt_native_controls_v1');
  expect(map['nativeTapFocusControlExpectedCount'], 0);
  expect(map['nativeContinuousFocusExpectedCount'], 1);
  expect(map['nativePinchZoomControlExpectedCount'], 1);
  expect(map['nativeExposureSliderControlExpectedCount'], 1);
  expect(map['nativeZoomGestureStartCount'], 2);
  expect(map['nativeZoomChangeCount'], 1);
  expect(map['nativeZoomUnavailableCount'], 1);
  expect(map['nativeCaptureReadinessCodeCounts'], {
    'manual_only_quality_review': 1,
  });
  expect(map['topNativeCaptureReadinessCode'], 'manual_only_quality_review');
  expect(map['nativeZoomStatusCounts'], {
    'zoom_changed': 2,
    'camera_unavailable': 1,
  });
  expect(map['topNativeZoomStatus'], 'zoom_changed');
  expect(map['nativePreCaptureExposureAbortCount'], 1);
  expect(map['nativePreCaptureExposureAbortReasonCounts'], {
    'camera_surface_inactive': 1,
  });
  expect(
    map['topNativePreCaptureExposureAbortReason'],
    'camera_surface_inactive',
  );
  expect(map['nativeBackDispatchPathCounts'], {'top_bar_back_button': 1});
  expect(map['topNativeBackDispatchPath'], 'top_bar_back_button');
  expect(map['nativeExposureResetControlExpectedCount'], 1);
  expect(map['nativeSettingsControlExpectedCount'], 1);
  expect(map['nativeBackControlExpectedCount'], 1);
  expect(map['nativeTorchControlExpectedCount'], 1);
  expect(map['nativeSettingsOpenCount'], 2);
  expect(map['receiptCloudAssistPlanCounts'], {
    'local_ocr_cloud_ocr_cloud_inventory_optional': 1,
    'local_only': 2,
  });
  expect(map['receiptLocalOcrModeCounts'], {
    'lean_local_ocr': 1,
    'full_local_ocr': 2,
  });
  expect(map['receiptParserDepthCounts'], {'detailed': 1, 'price_only': 2});
  expect(map['receiptCloudOcrOptionalCount'], 3);
  expect(map['receiptCloudInventoryOptionalCount'], 3);
  expect(map['nativeDevicePolicyCounts'], {'storage_saver_receipt_camera': 1});
  expect(map['nativeCameraWorkloadTierCounts'], {'light': 1});
  expect(map['nativeCameraResolutionTierCounts'], {'medium': 1});
  expect(map['nativeRecoveryResumeStatusCounts'], {'resume_review_started': 1});
  expect(map['nativeRecoveryFreshnessCounts'], {'stale': 1});
  expect(map['nativeRecoveryStorageStatusCounts'], {
    'partial_photos_available': 1,
  });
  expect(map['nativeRecoveryRecoveredPhotoCount'], 2);
  expect(map['nativeRecoveryMultipleSectionCount'], 1);
  expect(map['topNativeCameraEngine'], 'camerax');
  expect(
    map['topNativeReceiptCameraSurfaceActual'],
    'maintainiac_native_android',
  );
  expect(
    map['topNativeReceiptCameraSurfaceVerification'],
    'maintainiac_custom_surface_verified',
  );
  expect(map['topNativeCameraIdentity'], 'maintainiac_in_app_receipt_camera');
  expect(
    map['topNativeSettingsContractVersion'],
    'receipt_native_camera_settings_v1',
  );
  expect(map['topReceiptCloudAssistPlan'], 'local_only');
  expect(map['topReceiptLocalOcrMode'], 'full_local_ocr');
  expect(map['topReceiptParserDepth'], 'price_only');
  expect(map['topNativeDevicePolicy'], 'storage_saver_receipt_camera');
  expect(map['topNativeCameraWorkloadTier'], 'light');
  expect(map['topNativeCameraResolutionTier'], 'medium');
  expect(map['topNativeRecoveryResumeStatus'], 'resume_review_started');
  expect(map['topNativeRecoveryFreshness'], 'stale');
  expect(map['topNativeRecoveryStorageStatus'], 'partial_photos_available');
  expect(map['topNativeRecoveryAction'], contains('missing receipt photos'));
  expect(map['capabilityPolicyCodeCounts'], {
    'storage_constrained_small_proofs': 1,
  });
  expect(map['topCapabilityPolicyCode'], 'storage_constrained_small_proofs');
  expect(map['nativeCaptureSourcePolicyCounts'], {'storage_saver_native': 1});
  expect(map['topNativeCaptureSourcePolicy'], 'storage_saver_native');
  expect(map['stitchStatusCounts'], {'stitched': 1});
  expect(map['stitchFallbackReasonCounts'], {'stitched': 1});
  expect(map['stitchConfidenceBucketCounts'], {'high': 1});
  expect(map['stitchPairDiagnosticCounts'], {'zoom_adjusted': 1});
  expect(map['topStitchStatus'], 'stitched');
  expect(map['topStitchFallbackReason'], 'stitched');
  expect(map['topStitchConfidenceBucket'], 'high');
  expect(map['topStitchPairDiagnostic'], 'zoom_adjusted');
  expect(snapshot.userCorrectionCount, 1);
  expect(snapshot.cloudBackupFailureRate, 1);
  expect(snapshot.syncFailureRate, 1);
  expect(snapshot.failureBreakdowns, isNotEmpty);
  expect(
    snapshot.failureBreakdowns.map((failure) => failure.confirmedCause),
    contains('no_readable_text'),
  );
  expect(snapshot.healthLabel, 'needs_attention');
  expect(encoded, isNot(contains('lowes')));
  expect(encoded, isNot(contains('customer')));
  expect(encoded, isNot(contains('99.99')));
}
