import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';

import 'receipt_native_capture_staging_recovery_safety_expectations.dart';

void expectAcceptedNativeCaptureRecoveryManifest(
  Map manifest,
  List<String> stagedPhotoPaths,
) {
  expect(manifest['schema'], 'maintainiac_native_receipt_capture_recovery_v1');
  expect(manifest['engine'], 'cameraX');
  expect(manifest['dataSaverLevel'], ReceiptDataSaverLevel.strong.name);
  expect(manifest['photoCount'], 1);
  expect(manifest['stagedPhotoPaths'], contains(stagedPhotoPaths.single));
  expect(
    (manifest['captureDiagnostics'] as Map)['captureQualityMode'],
    'maximizeQuality',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['devicePolicyLabel'],
    'flagship_receipt_camera',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['cloudAssistPlan'],
    'local_ocr_cloud_ocr_cloud_inventory_optional',
  );
  expect((manifest['captureDiagnostics'] as Map)['localOcrAvailable'], isTrue);
  expect(
    (manifest['captureDiagnostics'] as Map)['localOcrMode'],
    'lean_local_ocr',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['parserDepth'],
    'inventoryMatching',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['localParserScope'],
    'inventory_matching_local',
  );
  expect((manifest['captureDiagnostics'] as Map)['cloudOcrOptional'], isTrue);
  expect(
    (manifest['captureDiagnostics'] as Map)['cloudInventoryOptional'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['cloudAssistRequiresExplicitChoice'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['localCatalogMatchLimit'],
    250,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['localInventoryCacheLimit'],
    1000,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['cameraWorkloadTier'],
    'flagship',
  );
  expect((manifest['captureDiagnostics'] as Map)['readyHoldMs'], 520);
  expect(
    (manifest['captureDiagnostics'] as Map)['maxLiveAnalysisPixels'],
    2200000,
  );
  expect((manifest['captureDiagnostics'] as Map)['sessionMaxZoom'], 8.0);
  expect(
    (manifest['captureDiagnostics'] as Map)['nativeControlContractVersion'],
    'receipt_native_controls_v1',
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['nativeCameraSurfaceContractVersion'],
    'receipt_native_surface_v1',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['captureSurface'],
    'maintainiac_native_android',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['nativeCameraIdentity'],
    'maintainiac_in_app_receipt_camera',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['nativeCaptureUiContract'],
    'maintainiac_custom_receipt_capture_ui_v1',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['stockCameraUiAllowed'],
    isFalse,
  );
  expect((manifest['captureDiagnostics'] as Map)['stockCameraUiUsed'], isFalse);
  expect(
    (manifest['captureDiagnostics'] as Map)['controlDiagnosticsPrivacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['tapFocusControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['pinchZoomControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['exposureSliderControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['exposureResetControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['settingsControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['backControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['torchControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['focusLockControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['exposureLockControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['whiteBalanceLockControlExpected'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['whiteBalanceLockEnabled'],
    isTrue,
  );
  expect((manifest['captureDiagnostics'] as Map)['whiteBalanceMode'], 'locked');
  expect(
    (manifest['captureDiagnostics'] as Map)['whiteBalanceLockStatus'],
    'locked',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestCapturedPhotoWidth'],
    3024,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestCapturedAverageLuma'],
    102.4,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestCapturedEdgeScore'],
    18.6,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestCapturedMegapixelBucket'],
    'high_9mp_to_18mp',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestBrightnessBucket'],
    'dark_assisted',
  );
  expect((manifest['captureDiagnostics'] as Map)['latestShadowScore'], 164.0);
  expect(
    (manifest['captureDiagnostics'] as Map)['latestReadabilitySignal'],
    'shadow_risk',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['exposureAssistStatus'],
    'auto_adjusted',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['previewExposurePolicy'],
    'receipt_paper_metering_safe_auto_lift_manual_slider',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['preCaptureExposurePolicy'],
    'receipt_paper_metering_dim_rescue_v2_manual_slider',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['lastAutoExposureDecision'],
    'waiting_for_receipt_target',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['lastPreCaptureExposureDecision'],
    'brightening_before_capture',
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['preCaptureExposureAdjustmentCount'],
    1,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['lastAutoExposureBrightnessBucket'],
    'dark_assisted',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['lastAutoExposureCandidate'],
    'brighten',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['autoExposureCandidateFrameCount'],
    2,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['latestFramingConfidence'],
    'usable_edges',
  );
  expect((manifest['captureDiagnostics'] as Map)['latestEdgeCoverage'], 0.64);
  expect(
    (manifest['captureDiagnostics'] as Map)['latestPerspectiveReadiness'],
    'perspective_ready_safe_bounds',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['edgeDetectionEnabled'],
    isTrue,
  );
  expect((manifest['captureDiagnostics'] as Map)['edgeOverlayEnabled'], isTrue);
  expect(
    (manifest['captureDiagnostics'] as Map)['shadowWarningEnabled'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['textTooSmallWarningEnabled'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['autoCropSuggestionEnabled'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['orientationCorrectionEnabled'],
    isTrue,
  );
  expect((manifest['captureDiagnostics'] as Map)['tapFocusCount'], 2);
  expect((manifest['captureDiagnostics'] as Map)['zoomChangeCount'], 3);
  expect(
    (manifest['captureDiagnostics'] as Map)['manualExposureChangeCount'],
    1,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['lastFocusStatus'],
    'requested',
  );
  expect((manifest['captureDiagnostics'] as Map)['autoCaptureTriggerCount'], 1);
  expect(
    (manifest['captureDiagnostics'] as Map)['latestAutoCaptureStatus'],
    'capturing',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['captureReadinessCode'],
    'auto_capture_ready',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['captureReadinessLabel'],
    'Receipt looks steady. Taking photo.',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['manualCaptureAllowed'],
    isTrue,
  );
  expect((manifest['captureDiagnostics'] as Map)['stableFrameCount'], 3);
  expect((manifest['captureDiagnostics'] as Map)['requiredStableFrames'], 3);
  expect(
    (manifest['captureDiagnostics'] as Map)['closeAction'],
    'done_returned_captured_sections',
  );
  expect((manifest['captureDiagnostics'] as Map)['closeRetryCount'], 1);
  expect(
    (manifest['captureDiagnostics'] as Map)['pendingCloseAfterCapture'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['closeResultDelivered'],
    isTrue,
  );
  expect((manifest['captureDiagnostics'] as Map)['autoCaptureAllowed'], isTrue);
  expect(
    (manifest['captureDiagnostics'] as Map)['autoCaptureCurrentlyAllowed'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['manualCapturePolicy'],
    'guidance_advisory_manual_shutter_always_allowed',
  );
  expect((manifest['captureDiagnostics'] as Map)['closingCamera'], isFalse);
  expect(
    (manifest['captureDiagnostics'] as Map)['storageSafetyLevel'],
    'maximum',
  );
  expect((manifest['captureDiagnostics'] as Map)['storageConstrained'], isTrue);
  expect(
    (manifest['captureDiagnostics'] as Map)['storageSafetyReason'],
    'tight_storage_tiny_proofs',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['maxLocalPhotoBytes'],
    6291456,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['nativeCaptureMemoryPolicy'],
    'tiny_local_proof_original_for_ocr_then_cleanup',
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['receiptLocalOnlyAcceptanceStatusCode'],
    'ready_local_first_optional_packs_deferred',
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['receiptLocalOnlyBaseFlowCanRunNow'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['receiptLocalOnlyBlocksLowStorageUsers'],
    isFalse,
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['receiptLocalOnlyEvidenceCodes'],
    contains('capture_available_in_base'),
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['localOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(
    (manifest['captureDiagnostics'] as Map)['localOnlyBaseFlowCanRunNow'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['receiptBrainFirstInstallBoundaryCode'],
    'ready_base_first_cloud_assist_optional_later',
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['receiptBrainFirstInstallCanRunOnLowStoragePhones'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['localOnlyHeavyPacksMayBlockCapture'],
    isFalse,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['localOnlyCloudAssistMayBlockCapture'],
    isFalse,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['localOnlyCameraMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['localOnlyProofSaveMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    (manifest['captureDiagnostics']
        as Map)['localOnlyBasicReviewMustStayAvailableBeforePacks'],
    isTrue,
  );
  expectNativeCaptureRecoverySafety(manifest);
}
