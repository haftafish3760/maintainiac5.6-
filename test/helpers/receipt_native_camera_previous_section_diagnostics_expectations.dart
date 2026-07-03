import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

void expectPreviousSectionGuideCaptureDiagnostics(
  dynamic result,
  Map<dynamic, dynamic> sentArguments,
) {
  expect(
    result.captureDiagnostics['nativeControlContractVersion'],
    'receipt_native_controls_v1',
  );
  expect(result.captureDiagnostics['nativeControlContractTags'], [
    'settings',
    'back',
    'manual_shutter',
    'review_next',
    'receipt_guidance',
    'safe_close',
    'tap_focus',
    'pinch_zoom',
    'brightness_slider',
    'brightness_reset',
    'auto_brightness_assist',
    'focus_lock',
    'brightness_lock',
    'white_balance_lock',
    'receipt_light',
    'edge_overlay',
    'previous_section_ghost',
  ]);
  expect(
    result.captureDiagnostics['nativeCameraSurfaceContractVersion'],
    'receipt_native_surface_v1',
  );
  expect(
    result.captureDiagnostics['captureSurfaceExpected'],
    'maintainiac_native_android',
  );
  expect(
    result.captureDiagnostics['nativeReceiptCameraSurfaceVerified'],
    isTrue,
  );
  expect(
    result.captureDiagnostics['nativeReceiptCameraSurfaceVerification'],
    'maintainiac_custom_surface_verified',
  );
  expect(
    result.captureDiagnostics['nativeReceiptCameraSurfaceActual'],
    'maintainiac_native_android',
  );
  expect(
    result.captureDiagnostics['nativeCameraIdentityExpected'],
    'maintainiac_in_app_receipt_camera',
  );
  expect(
    result.captureDiagnostics['nativeCaptureUiContractExpected'],
    'maintainiac_custom_receipt_capture_ui_v1',
  );
  expect(
    result.captureDiagnostics['nativePreviewOwnership'],
    'maintainiac_owns_preview_and_controls',
  );
  expect(result.captureDiagnostics['stockCameraUiAllowed'], isFalse);
  expect(result.captureDiagnostics['stockCameraUiUsed'], isFalse);
  expect(
    result.captureDiagnostics['stockCameraUiPolicy'],
    'blocked_as_primary_backup_path_labels_if_used',
  );
  expect(result.captureDiagnostics['phoneCameraBackupAllowed'], isTrue);
  expect(result.captureDiagnostics['phoneCameraBackupRole'], 'fallback_only');
  expect(
    result.captureDiagnostics['manualCapturePolicy'],
    'guidance_advisory_manual_shutter_always_allowed',
  );
  expect(
    result.captureDiagnostics['guidanceBlockingPolicy'],
    'quality_guidance_warns_never_blocks_manual_capture',
  );
  expect(
    result.captureDiagnostics['manualCaptureBlockPolicy'],
    'only_busy_closing_no_camera_or_inactive_surface',
  );
  expect(result.captureDiagnostics['tapFocusControlExpected'], isTrue);
  expect(
    result.captureDiagnostics['tapToFocusPolicy'],
    'tap_receipt_text_focus_and_meter_exposure',
  );
  expect(result.captureDiagnostics['pinchZoomControlExpected'], isTrue);
  expect(
    result.captureDiagnostics['zoomGesturePolicy'],
    'pinch_zoom_receipt_preview_1.0_to_6.0',
  );
  expect(result.captureDiagnostics['exposureSliderControlExpected'], isTrue);
  expect(
    result.captureDiagnostics['previewExposurePolicy'],
    'receipt_paper_metering_safe_auto_lift_manual_slider',
  );
  expect(
    result.captureDiagnostics['preCaptureExposurePolicy'],
    'receipt_paper_metering_dim_rescue_v2_manual_slider',
  );
  expect(
    result.captureDiagnostics['previewBrightnessGuardPolicy'],
    'avoid_dark_preview_full_receipt_sampling',
  );
  expect(
    result.captureDiagnostics['shutterSpeedPolicy'],
    'prefer_fast_document_shutter_manual_capture_anytime',
  );
  expect(result.captureDiagnostics['backControlExpected'], isTrue);
  expect(
    result.captureDiagnostics['closeCapturedPhotoPolicy'],
    'back_returns_captured_sections_before_cancel',
  );
  expect(
    result.captureDiagnostics['closeDuringCapturePolicy'],
    'wait_for_in_flight_capture_then_return_review',
  );
  expect(
    result.captureDiagnostics['closeNoPhotoPolicy'],
    'back_without_photo_cancels_without_creating_expense',
  );
  expect(
    result.captureDiagnostics['capturedPhotoReviewDestination'],
    'receipt_photo_review_then_receipt_details',
  );
  expect(result.captureDiagnostics['focusLockControlExpected'], isTrue);
  expect(result.captureDiagnostics['exposureLockControlExpected'], isTrue);
  expect(result.captureDiagnostics['whiteBalanceLockControlExpected'], isTrue);
  expect(
    result.captureDiagnostics['previousSectionReasonCode'],
    'missing_bottom_edge_and_totals',
  );
  expect(
    result.captureDiagnostics['previousSectionMissingBottomAndTotals'],
    isTrue,
  );
  expect(
    result.captureDiagnostics['previousSectionGhostGuidePolicy'],
    'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
  );
  expect(
    result.captureDiagnostics['previousSectionGhostSourceStartFraction'],
    .80,
  );
  expect(
    result.captureDiagnostics['previousSectionGhostSourceHeightFraction'],
    .20,
  );
  expect(result.captureDiagnostics['previousSectionGhostSlicePercent'], 20);
  expect(result.captureDiagnostics['previousSectionGuidanceAvailable'], isTrue);
  expect(result.captureDiagnostics['cloudAssistPlan'], 'local_ocr_only');
  expect(result.captureDiagnostics['ocrDecisionPolicy'], 'local_default_only');
  expect(result.captureDiagnostics['localOcrAvailable'], isTrue);
  expect(result.captureDiagnostics['localOcrMode'], 'full_local_ocr');
  expect(result.captureDiagnostics['localOcrDefault'], isTrue);
  expect(result.captureDiagnostics['cloudOcrOptional'], isFalse);
  expect(result.captureDiagnostics['cloudInventoryOptional'], isFalse);
  expect(
    result.captureDiagnostics['cloudAssistRequiresExplicitChoice'],
    isFalse,
  );
  expect(result.captureDiagnostics['cloudAssistRequiresInternet'], isFalse);
  expect(result.captureDiagnostics['cameraCaptureCloudRequired'], isFalse);
  expect(result.captureDiagnostics['receiptReviewCloudRequired'], isFalse);
  expect(
    result.captureDiagnostics['localOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(result.captureDiagnostics['localOnlyBaseFlowCanRunNow'], isTrue);
  expect(
    result.captureDiagnostics['localOnlyHeavyPacksMayBlockCapture'],
    isFalse,
  );
  expect(
    result.captureDiagnostics['localOnlyCloudAssistMayBlockCapture'],
    isFalse,
  );
  expect(
    result.captureDiagnostics['localOnlyCameraMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    result.captureDiagnostics['receiptBrainFirstInstallBoundaryCode'],
    'ready_base_first_optional_local_pack_later',
  );
  expect(
    result.captureDiagnostics['receiptBrainFirstInstallBoundaryActionCode'],
    'ship_base_then_offer_optional_local_pack',
  );
  expect(
    result
        .captureDiagnostics['receiptBrainFirstInstallCanRunOnLowStoragePhones'],
    isTrue,
  );
  expect(
    result.captureDiagnostics['localOnlyProofSaveMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    result
        .captureDiagnostics['localOnlyBasicReviewMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(sentArguments['minZoom'], 1.0);
  expect(sentArguments['maxZoom'], 6.0);
  expect(sentArguments['minExposureOffset'], -1.5);
  expect(sentArguments['maxExposureOffset'], 1.5);
  expect(
    sentArguments['storageSafetyLevel'],
    ReceiptDataSaverLevel.balanced.name,
  );
  expect(sentArguments['storageConstrained'], isFalse);
  expect(sentArguments['storageSafetyReason'], 'normal');
  expect(sentArguments['maxLocalPhotoBytes'], 12 * 1024 * 1024);
  expect(
    sentArguments['nativeCaptureMemoryPolicy'],
    'bounded_original_for_ocr_then_cleanup',
  );
  expect(sentArguments['workloadProtectionPolicy'], 'balanced_workload');
  expect(sentArguments['analysisGapMs'], 480);
  expect(sentArguments['readyHoldMs'], 700);
  expect(sentArguments['autoCaptureStableFrameTarget'], 0);
  expect(sentArguments['autoCaptureMaxMotionScore'], 7.5);
  expect(sentArguments['autoCaptureMinBrightness'], 112);
  expect(sentArguments['autoCaptureMaxBrightness'], 238);
  expect(sentArguments['autoCaptureCooldownMs'], 0);
  expect(sentArguments['assistedShotCount'], 4);
  expect(sentArguments['bestShotCandidateCount'], 3);
  expect(
    sentArguments['cameraResolutionTier'],
    ReceiptCameraResolutionTier.high.name,
  );
  expect(
    sentArguments['cameraWorkloadTier'],
    ReceiptCameraWorkloadTier.balanced.name,
  );
  expect(sentArguments['maxLiveAnalysisPixels'], 0);
  expect(sentArguments['maxCleanupPixels'], 10000000);
  expect(sentArguments['maxStitchOutputPixels'], 14000000);
  expect(sentArguments['maxStitchOutputHeight'], 18000);
  expect(sentArguments['edgeOverlayEnabled'], isTrue);
  expect(sentArguments['autoCropSuggestionEnabled'], isTrue);
  expect(sentArguments['shadowReductionEnabled'], isTrue);
}
