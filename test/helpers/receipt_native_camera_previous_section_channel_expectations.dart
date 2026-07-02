import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';

void expectPreviousSectionGuideChannelArguments(
  Map<dynamic, dynamic> sentArguments,
  dynamic result,
) {
  expect(result.originalPhotoPaths, ['/tmp/new-section.jpg']);
  expect(
    sentArguments['previousSectionGuidePhotoPath'],
    '/tmp/section-one.jpg',
  );
  expect(
    sentArguments['previousSectionReasonCode'],
    'missing_bottom_edge_and_totals',
  );
  expect(sentArguments['previousSectionGuidance'], 'Add Bottom Section');
  expect(
    sentArguments['previousSectionGhostGuidePolicy'],
    'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
  );
  expect(
    sentArguments['previousSectionGhostGuideRepeatLineTarget'],
    'repeat_3_to_5_readable_lines',
  );
  expect(
    sentArguments['previousSectionGhostGuidePlacement'],
    'top_ghost_slice',
  );
  expect(
    sentArguments['previousSectionGhostGuideMatchTarget'],
    'subtotal_total_and_final_lines',
  );
  expect(sentArguments['previousSectionGhostSourceStartFraction'], .80);
  expect(sentArguments['previousSectionGhostSourceHeightFraction'], .20);
  expect(sentArguments['previousSectionGhostOverlayTopFraction'], 0);
  expect(sentArguments['previousSectionGhostOverlayHeightFraction'], .20);
  expect(sentArguments['previousSectionGhostOpacity'], .36);
  expect(sentArguments['previousSectionGhostSlicePercent'], 20);
  expect(sentArguments['previousSectionMissingBottomAndTotals'], isTrue);
  expect(sentArguments['previousSectionGhostGuideEnabled'], isTrue);
  expect(sentArguments['longReceiptMode'], isTrue);
  expect(sentArguments['autoExposureAssistEnabled'], isTrue);
  expect(sentArguments['autoCaptureAllowed'], isFalse);
  expect(
    sentArguments['settingsContractVersion'],
    'receipt_native_camera_settings_v1',
  );
  expect(
    sentArguments['nativeCameraSurfaceContractVersion'],
    'receipt_native_surface_v1',
  );
  expect(sentArguments['captureSurfaceExpected'], 'maintainiac_native_android');
  expect(
    sentArguments['nativeCameraIdentityExpected'],
    'maintainiac_in_app_receipt_camera',
  );
  expect(
    sentArguments['nativeCaptureUiContractExpected'],
    'maintainiac_custom_receipt_capture_ui_v1',
  );
  expect(
    sentArguments['nativePreviewOwnership'],
    'maintainiac_owns_preview_and_controls',
  );
  expect(sentArguments['stockCameraUiAllowed'], isFalse);
  expect(sentArguments['stockCameraUiUsed'], isFalse);
  expect(
    sentArguments['stockCameraUiPolicy'],
    'blocked_as_primary_backup_path_labels_if_used',
  );
  expect(sentArguments['phoneCameraBackupAllowed'], isTrue);
  expect(sentArguments['phoneCameraBackupRole'], 'fallback_only');
  expect(sentArguments['deviceTier'], ReceiptCapabilityTier.medium.name);
  expect(sentArguments['devicePolicyLabel'], 'balanced_receipt_camera');
  expect(sentArguments['cloudAssistPlan'], 'local_ocr_only');
  expect(sentArguments['ocrDecisionPolicy'], 'local_default_only');
  expect(sentArguments['localOcrAvailable'], isTrue);
  expect(sentArguments['localOcrMode'], 'full_local_ocr');
  expect(sentArguments['localOcrDefault'], isTrue);
  expect(sentArguments['cloudOcrOptional'], isFalse);
  expect(sentArguments['cloudInventoryOptional'], isFalse);
  expect(sentArguments['cloudAssistRequiresExplicitChoice'], isFalse);
  expect(sentArguments['cloudAssistRequiresInternet'], isFalse);
  expect(sentArguments['cameraCaptureCloudRequired'], isFalse);
  expect(sentArguments['receiptReviewCloudRequired'], isFalse);
  expect(
    sentArguments['localOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(sentArguments['localOnlyBaseFlowCanRunNow'], isTrue);
  expect(sentArguments['localOnlyHeavyPacksMayBlockCapture'], isFalse);
  expect(sentArguments['localOnlyCloudAssistMayBlockCapture'], isFalse);
  expect(sentArguments['localOnlyCameraMustStayAvailableBeforePacks'], isTrue);
  expect(
    sentArguments['localOnlyProofSaveMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    sentArguments['localOnlyBasicReviewMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    sentArguments['receiptBrainFirstInstallBoundaryCode'],
    'ready_base_first_optional_local_pack_later',
  );
  expect(
    sentArguments['receiptBrainFirstInstallBoundaryActionCode'],
    'ship_base_then_offer_optional_local_pack',
  );
  expect(
    sentArguments['receiptBrainFirstInstallCanRunOnLowStoragePhones'],
    isTrue,
  );
  expect(sentArguments['receiptInstallMode'], 'optional_receipt_packs_allowed');
  expect(sentArguments['receiptInstallOptionalLocalDownloadAllowed'], isTrue);
  expect(sentArguments['receiptInstallCloudFallbackSuggested'], isFalse);
  expect(
    sentArguments['receiptInstallMaxOptionalLocalBytes'],
    100 * 1024 * 1024,
  );
  expect(
    sentArguments['receiptInstallReason'],
    'comfortable_storage_explicit_optional_packs',
  );
  expect(sentArguments['parserDepth'], ReceiptParserDepth.lineItems.name);
  expect(sentArguments['localParserScope'], 'line_items_local');
  expect(sentArguments['localCatalogMatchLimit'], 1500);
  expect(sentArguments['localInventoryCacheLimit'], 5000);
  expect(sentArguments['capabilityPolicyCodes'], [
    'native_edge_signals_unavailable',
    'auto_capture_policy_disabled',
    'live_analysis_policy_disabled',
  ]);
  expect(result.captureDiagnostics['capabilityPolicyCodes'], [
    'native_edge_signals_unavailable',
    'auto_capture_policy_disabled',
    'live_analysis_policy_disabled',
  ]);
  expect(
    result.captureDiagnostics['receiptInstallMode'],
    'optional_receipt_packs_allowed',
  );
  expect(
    result.captureDiagnostics['receiptInstallOptionalLocalDownloadAllowed'],
    isTrue,
  );
  expect(sentArguments['tapFocusEnabled'], isTrue);
  expect(
    sentArguments['tapToFocusPolicy'],
    'tap_receipt_text_focus_and_meter_exposure',
  );
  expect(sentArguments['pinchZoomEnabled'], isTrue);
  expect(
    sentArguments['zoomGesturePolicy'],
    'pinch_zoom_receipt_preview_1.0_to_6.0',
  );
  expect(sentArguments['exposureSliderEnabled'], isTrue);
  expect(sentArguments['exposureResetEnabled'], isTrue);
  expect(
    sentArguments['previewExposurePolicy'],
    'receipt_paper_metering_safe_auto_lift_manual_slider',
  );
  expect(
    sentArguments['preCaptureExposurePolicy'],
    'receipt_paper_metering_dim_rescue_v2_manual_slider',
  );
  expect(
    sentArguments['previewBrightnessGuardPolicy'],
    'avoid_dark_preview_full_receipt_sampling',
  );
  expect(
    sentArguments['shutterSpeedPolicy'],
    'prefer_fast_document_shutter_manual_capture_anytime',
  );
  expect(
    sentArguments['autoCapturePolicy'],
    'off_by_default_manual_shutter_primary',
  );
  expect(
    sentArguments['closeCapturedPhotoPolicy'],
    'back_returns_captured_sections_before_cancel',
  );
  expect(
    sentArguments['closeDuringCapturePolicy'],
    'wait_for_in_flight_capture_then_return_review',
  );
  expect(
    sentArguments['closeNoPhotoPolicy'],
    'back_without_photo_cancels_without_creating_expense',
  );
  expect(
    sentArguments['capturedPhotoReviewDestination'],
    'receipt_photo_review_then_receipt_details',
  );
  expect(sentArguments['focusLockEnabled'], isTrue);
  expect(sentArguments['exposureLockEnabled'], isTrue);
  expect(sentArguments['whiteBalanceLockEnabled'], isTrue);
  expect(
    sentArguments['nativeControlContractVersion'],
    'receipt_native_controls_v1',
  );
  expect(sentArguments['nativeControlContractTags'], [
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
    sentArguments['controlDiagnosticsPrivacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    sentArguments['manualCapturePolicy'],
    'guidance_advisory_manual_shutter_always_allowed',
  );
  expect(
    sentArguments['guidanceBlockingPolicy'],
    'quality_guidance_warns_never_blocks_manual_capture',
  );
  expect(
    sentArguments['manualCaptureBlockPolicy'],
    'only_busy_closing_no_camera_or_inactive_surface',
  );
  expect(sentArguments['tapFocusControlExpected'], isTrue);
  expect(sentArguments['pinchZoomControlExpected'], isTrue);
  expect(sentArguments['exposureSliderControlExpected'], isTrue);
  expect(sentArguments['exposureResetControlExpected'], isTrue);
  expect(sentArguments['settingsControlExpected'], isTrue);
  expect(sentArguments['backControlExpected'], isTrue);
  expect(sentArguments['torchControlExpected'], isTrue);
  expect(sentArguments['focusLockControlExpected'], isTrue);
  expect(sentArguments['exposureLockControlExpected'], isTrue);
  expect(sentArguments['whiteBalanceLockControlExpected'], isTrue);
}
