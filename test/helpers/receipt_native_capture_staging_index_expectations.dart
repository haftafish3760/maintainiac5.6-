import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_recovery_store.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

Future<void> expectAcceptedNativeCaptureRecoveryIndex({
  required ReceiptNativeCaptureRecoveryStore recoveryIndex,
  required ReceiptNativeCaptureStagingResult staged,
  required Map manifest,
}) async {
  expect(recoveryIndex.entries, hasLength(1));
  final indexEntry = recoveryIndex.entries.single;
  expect(indexEntry.sessionId, manifest['sessionId']);
  expect(indexEntry.manifestPath, staged.recoveryManifestPath);
  expect(indexEntry.captureDiagnostics['whiteBalanceLockEnabled'], isFalse);
  expect(
    indexEntry.captureDiagnostics['whiteBalanceLockStatus'],
    'not_requested',
  );
  expect(indexEntry.engineName, 'cameraX');
  expect(indexEntry.dataSaverLevelName, ReceiptDataSaverLevel.strong.name);
  expect(indexEntry.photoCount, 1);
  expect(indexEntry.stagedPhotoPaths, staged.photoPaths);
  expect(indexEntry.attachments.single.path, staged.photoPaths.single);
  expect(
    indexEntry.recoverySafety['schema'],
    'native_capture_recovery_safety_v1',
  );
  expect(indexEntry.recoverySafety['manifestBacked'], isTrue);
  expect(indexEntry.recoverySafety['hiveIndexSaved'], isTrue);
  expect(indexEntry.recoverySafety['localStagedPhotoCount'], 1);
  expect(indexEntry.recoverySafety['localExistingPhotoCount'], 1);
  expect(indexEntry.recoverySafety['allLocalPhotosExist'], isTrue);
  expect(
    indexEntry.recoverySafety['privacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    indexEntry.recoverySafety['contentPolicy'],
    'no_receipt_text_no_customer_content',
  );
  expect(
    indexEntry.recoverySafety['attachmentState'],
    'staged_not_attached_until_user_accepts',
  );
  expect(
    indexEntry.recoverySafety['resumeAction'],
    'resume_review_before_receipt_details',
  );
  expect(
    indexEntry.recoverySafety['resumeCheckpoint'],
    'after_native_capture_before_ocr',
  );
  expect(
    indexEntry.recoverySafety['ocrSourcePolicy'],
    'original_staged_photo_used_before_data_saver_copy',
  );
  expect(
    indexEntry.recoverySafety['cleanupPolicy'],
    'discard_only_after_accept_or_user_discard_or_old_cleanup',
  );
  expect(
    indexEntry.recoverySafety['writeOrder'],
    'copy_photo_then_manifest_then_hive_index',
  );
  expect(
    indexEntry.recoverySafety['interruptionGuarantee'],
    'resume_review_keeps_photos_available_before_receipt_details',
  );
  expect(
    indexEntry.recoverySafety['coveredInterruptions'],
    containsAll([
      'app_backgrounded_after_capture',
      'phone_call_after_capture',
      'camera_closed_before_review',
      'review_closed_before_attach',
    ]),
  );
  expect(
    indexEntry.recoverySafety['userSafeExit'],
    'local_recovery_kept_until_accept_or_discard',
  );
  expect(
    indexEntry.captureDiagnostics['captureQualityMode'],
    'maximizeQuality',
  );
  expect(
    indexEntry.captureDiagnostics['devicePolicyLabel'],
    'flagship_receipt_camera',
  );
  expect(
    indexEntry.captureDiagnostics['cloudAssistPlan'],
    'local_ocr_cloud_ocr_cloud_inventory_optional',
  );
  expect(indexEntry.captureDiagnostics['localOcrAvailable'], isTrue);
  expect(indexEntry.captureDiagnostics['localOcrMode'], 'lean_local_ocr');
  expect(indexEntry.captureDiagnostics['cloudOcrOptional'], isTrue);
  expect(indexEntry.captureDiagnostics['cloudInventoryOptional'], isTrue);
  expect(
    indexEntry.captureDiagnostics['cloudAssistRequiresExplicitChoice'],
    isTrue,
  );
  expect(
    indexEntry.captureDiagnostics['localOnlyCapturePolicy'],
    'capture_save_basic_review_now_optional_packs_later',
  );
  expect(indexEntry.captureDiagnostics['localOnlyBaseFlowCanRunNow'], isTrue);
  expect(
    indexEntry.captureDiagnostics['localOnlyHeavyPacksMayBlockCapture'],
    isFalse,
  );
  expect(
    indexEntry.captureDiagnostics['receiptBrainFirstInstallBoundaryCode'],
    'ready_base_first_cloud_assist_optional_later',
  );
  expect(
    indexEntry
        .captureDiagnostics['receiptBrainFirstInstallCanRunOnLowStoragePhones'],
    isTrue,
  );
  expect(
    indexEntry.captureDiagnostics['localOnlyCloudAssistMayBlockCapture'],
    isFalse,
  );
  expect(
    indexEntry
        .captureDiagnostics['localOnlyCameraMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    indexEntry
        .captureDiagnostics['localOnlyProofSaveMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(
    indexEntry
        .captureDiagnostics['localOnlyBasicReviewMustStayAvailableBeforePacks'],
    isTrue,
  );
  expect(indexEntry.captureDiagnostics['localCatalogMatchLimit'], 250);
  expect(indexEntry.captureDiagnostics['localInventoryCacheLimit'], 1000);
  expect(indexEntry.captureDiagnostics['cameraWorkloadTier'], 'flagship');
  expect(indexEntry.captureDiagnostics['readyHoldMs'], 520);
  expect(indexEntry.captureDiagnostics['maxLiveAnalysisPixels'], 2200000);
  expect(indexEntry.captureDiagnostics['sessionMaxZoom'], 8.0);
  expect(
    indexEntry.captureDiagnostics['nativeControlContractVersion'],
    'receipt_native_controls_v1',
  );
  expect(
    indexEntry.captureDiagnostics['nativeCameraSurfaceContractVersion'],
    'receipt_native_surface_v1',
  );
  expect(
    indexEntry.captureDiagnostics['captureSurface'],
    'maintainiac_native_android',
  );
  expect(
    indexEntry.captureDiagnostics['nativeCameraIdentity'],
    'maintainiac_in_app_receipt_camera',
  );
  expect(
    indexEntry.captureDiagnostics['nativeCaptureUiContract'],
    'maintainiac_custom_receipt_capture_ui_v1',
  );
  expect(indexEntry.captureDiagnostics['stockCameraUiAllowed'], isFalse);
  expect(indexEntry.captureDiagnostics['stockCameraUiUsed'], isFalse);
  expect(
    indexEntry.captureDiagnostics['controlDiagnosticsPrivacyScope'],
    'summary_only_no_receipt_content',
  );
  expect(
    indexEntry.captureDiagnostics['visibleControlSet'],
    contains('manual_shutter'),
  );
  expect(
    indexEntry.captureDiagnostics['visibleControlSet'],
    contains('section_ghost_guide'),
  );
  expect(
    indexEntry.captureDiagnostics['previewDominanceTarget'],
    'receipt_preview_75_80_percent',
  );
  expect(indexEntry.captureDiagnostics['tapFocusControlExpected'], isFalse);
  expect(indexEntry.captureDiagnostics['pinchZoomControlExpected'], isTrue);
  expect(
    indexEntry.captureDiagnostics['exposureSliderControlExpected'],
    isTrue,
  );
  expect(indexEntry.captureDiagnostics['exposureResetControlExpected'], isTrue);
  expect(indexEntry.captureDiagnostics['settingsControlExpected'], isTrue);
  expect(indexEntry.captureDiagnostics['backControlExpected'], isTrue);
  expect(indexEntry.captureDiagnostics['torchControlExpected'], isTrue);
  expect(indexEntry.captureDiagnostics['latestCapturedPhotoHeight'], 4032);
  expect(indexEntry.captureDiagnostics['latestCapturedAverageLuma'], 102.4);
  expect(indexEntry.captureDiagnostics['latestCapturedEdgeScore'], 18.6);
  expect(
    indexEntry.captureDiagnostics['latestCapturedByteBucket'],
    'normal_1mb_to_3mb',
  );
  expect(
    indexEntry.captureDiagnostics['latestCapturedQualitySignal'],
    'review_before_saving',
  );
  expect(
    indexEntry.captureDiagnostics['latestCapturedExposureMismatch'],
    'live_ok_capture_dim',
  );
  expect(
    indexEntry.captureDiagnostics['latestBrightnessBucket'],
    'dark_assisted',
  );
  expect(indexEntry.captureDiagnostics['latestShadowScore'], 164.0);
  expect(
    indexEntry.captureDiagnostics['latestReadabilitySignal'],
    'shadow_risk',
  );
  expect(
    indexEntry.captureDiagnostics['exposureAssistStatus'],
    'auto_adjusted',
  );
  expect(
    indexEntry.captureDiagnostics['lastAutoExposureDecision'],
    'waiting_for_receipt_target',
  );
  expect(
    indexEntry.captureDiagnostics['lastPreCaptureExposureDecision'],
    'brightening_before_capture',
  );
  expect(indexEntry.captureDiagnostics['preCaptureExposureAdjustmentCount'], 1);
  expect(
    indexEntry.captureDiagnostics['lastAutoExposureBrightnessBucket'],
    'dark_assisted',
  );
  expect(
    indexEntry.captureDiagnostics['lastAutoExposureCandidate'],
    'brighten',
  );
  expect(indexEntry.captureDiagnostics['autoExposureCandidateFrameCount'], 2);
  expect(
    indexEntry.captureDiagnostics['latestFramingConfidence'],
    'usable_edges',
  );
  expect(indexEntry.captureDiagnostics['latestEdgeCoverage'], 0.64);
  expect(
    indexEntry.captureDiagnostics['latestPerspectiveReadiness'],
    'perspective_ready_safe_bounds',
  );
  expect(indexEntry.captureDiagnostics['edgeDetectionEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['edgeOverlayEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['shadowWarningEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['textTooSmallWarningEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['autoCropSuggestionEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['orientationCorrectionEnabled'], isTrue);
  expect(indexEntry.captureDiagnostics['tapFocusCount'], 2);
  expect(indexEntry.captureDiagnostics['tapFocusSuppressedAfterZoomCount'], 1);
  expect(indexEntry.captureDiagnostics['zoomChangeCount'], 3);
  expect(indexEntry.captureDiagnostics['manualExposureChangeCount'], 1);
  expect(indexEntry.captureDiagnostics['lastFocusStatus'], 'requested');
  expect(indexEntry.captureDiagnostics['autoCaptureTriggerCount'], 1);
  expect(indexEntry.captureDiagnostics['latestAutoCaptureStatus'], 'capturing');
  expect(
    indexEntry.captureDiagnostics['captureReadinessCode'],
    'auto_capture_ready',
  );
  expect(
    indexEntry.captureDiagnostics['captureReadinessLabel'],
    'Receipt looks steady. Taking photo.',
  );
  expect(indexEntry.captureDiagnostics['manualCaptureAllowed'], isTrue);
  expect(indexEntry.captureDiagnostics['stableFrameCount'], 3);
  expect(indexEntry.captureDiagnostics['requiredStableFrames'], 3);
  expect(indexEntry.captureDiagnostics['closeRetryCount'], 1);
  expect(
    indexEntry.captureDiagnostics['closeAction'],
    'done_returned_captured_sections',
  );
  expect(indexEntry.captureDiagnostics['pendingCloseAfterCapture'], isTrue);
  expect(indexEntry.captureDiagnostics['closeResultDelivered'], isTrue);
  expect(indexEntry.captureDiagnostics['autoCaptureAllowed'], isTrue);
  expect(indexEntry.captureDiagnostics['autoCaptureCurrentlyAllowed'], isTrue);
  expect(indexEntry.captureDiagnostics['closingCamera'], isFalse);
  expect(indexEntry.captureDiagnostics['storageSafetyLevel'], 'maximum');
  expect(indexEntry.captureDiagnostics['storageConstrained'], isTrue);
  expect(
    indexEntry.captureDiagnostics['storageSafetyReason'],
    'tight_storage_tiny_proofs',
  );
  expect(indexEntry.captureDiagnostics['maxLocalPhotoBytes'], 6291456);
  expect(
    indexEntry.captureDiagnostics['nativeCaptureMemoryPolicy'],
    'tiny_local_proof_temporary_source_for_ocr_then_cleanup',
  );
  expect(indexEntry.captureDiagnostics.containsKey('receiptText'), isFalse);
  expect(indexEntry.toMap().toString(), isNot(contains('LOWE')));
  expect(indexEntry.toMap().toString(), isNot(contains('receiptText')));

  final recoveredRecords = await const ReceiptNativeCaptureStaging()
      .recoverableNativeCaptures();
  expect(recoveredRecords, hasLength(1));
  final recovered = recoveredRecords.single;
  expect(recovered.existingPhotoCount, 1);
  expect(recovered.missingPhotoCount, 0);
  expect(recovered.hasCompleteLocalRecovery, isTrue);
  expect(recovered.recoveryStorageStatus, 'all_photos_available');
  expect(
    recovered.privacySafeRecoveryEvidenceLabel,
    contains('storageStatus=all_photos_available'),
  );
}
