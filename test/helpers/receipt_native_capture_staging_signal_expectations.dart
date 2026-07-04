import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_capture_staging.dart';

Future<void> expectAcceptedNativeCaptureStagingSignals(
  ReceiptNativeCaptureStagingResult staged,
) async {
  final diagnostics =
      staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]!;
  expect(diagnostics['cameraResolutionTier'], 'max');
  expect(diagnostics['cameraWorkloadTier'], 'flagship');
  expect(diagnostics['latestCapturedPhotoHeight'], 4032);
  expect(diagnostics['latestCapturedAverageLuma'], 102.4);
  expect(diagnostics['latestCapturedEdgeScore'], 18.6);
  expect(diagnostics['latestCapturedMegapixelBucket'], 'high_9mp_to_18mp');
  expect(diagnostics['latestCapturedByteBucket'], 'normal_1mb_to_3mb');
  expect(diagnostics['latestCapturedBrightnessBucket'], 'captured_dim');
  expect(diagnostics['latestCapturedSharpnessBucket'], 'captured_sharp');
  expect(diagnostics['latestCapturedQualitySignal'], 'review_before_saving');
  expect(diagnostics['latestCapturedExposureMismatch'], 'live_ok_capture_dim');
  expect(diagnostics['latestBrightnessBucket'], 'dark_assisted');
  expect(diagnostics['latestShadowScore'], 164.0);
  expect(diagnostics['latestReadabilitySignal'], 'shadow_risk');
  expect(diagnostics['exposureAssistStatus'], 'auto_adjusted');
  expect(diagnostics['lastAutoExposureDecision'], 'waiting_for_receipt_target');
  expect(diagnostics['lastAutoExposureBrightnessBucket'], 'dark_assisted');
  expect(diagnostics['lastAutoExposureCandidate'], 'brighten');
  expect(diagnostics['autoExposureCandidateFrameCount'], 2);
  expect(diagnostics['latestFramingConfidence'], 'usable_edges');
  expect(diagnostics['latestEdgeCoverage'], 0.64);
  expect(
    diagnostics['latestPerspectiveReadiness'],
    'perspective_ready_safe_bounds',
  );
  expect(diagnostics['tapFocusCount'], 2);
  expect(diagnostics['tapFocusSuppressedAfterZoomCount'], 1);
  expect(diagnostics['zoomChangeCount'], 3);
  expect(diagnostics['manualExposureChangeCount'], 1);
  expect(diagnostics['preCaptureExposureAbortCount'], 1);
  expect(
    diagnostics['lastPreCaptureExposureAbortReason'],
    'camera_surface_inactive',
  );
  expect(diagnostics['lastFocusStatus'], 'requested');
  expect(diagnostics['analysisGapMs'], 380);
  expect(diagnostics['readyHoldMs'], 520);
  expect(diagnostics['assistedShotCount'], 5);
  expect(diagnostics['bestShotCandidateCount'], 5);
  expect(diagnostics['maxLiveAnalysisPixels'], 2200000);
  expect(diagnostics['maxCleanupPixels'], 14000000);
  expect(diagnostics['maxStitchOutputPixels'], 18000000);
  expect(diagnostics['maxStitchOutputHeight'], 24000);
  expect(diagnostics['sessionMinZoom'], 1.0);
  expect(diagnostics['sessionMaxZoom'], 8.0);
  expect(diagnostics['sessionMinExposureOffset'], -2.0);
  expect(diagnostics['sessionMaxExposureOffset'], 2.0);
  expect(
    diagnostics['nativeControlContractVersion'],
    'receipt_native_controls_v1',
  );
  expect(
    diagnostics['nativeCameraSurfaceContractVersion'],
    'receipt_native_surface_v1',
  );
  expect(diagnostics['captureSurface'], 'maintainiac_native_android');
  expect(
    diagnostics['nativeCaptureUiContract'],
    'maintainiac_custom_receipt_capture_ui_v1',
  );
  expect(diagnostics['stockCameraUiUsed'], isFalse);
  expect(diagnostics['tapFocusControlExpected'], isFalse);
  expect(diagnostics['settingsControlExpected'], isTrue);
  expect(diagnostics['autoCaptureTriggerCount'], 1);
  expect(diagnostics['latestAutoCaptureStatus'], 'capturing');
  expect(diagnostics['captureReadinessCode'], 'auto_capture_ready');
  expect(
    diagnostics['captureReadinessLabel'],
    'Receipt looks steady. Taking photo.',
  );
  expect(diagnostics['manualCaptureAllowed'], isTrue);
  expect(diagnostics['stableFrameCount'], 3);
  expect(diagnostics['requiredStableFrames'], 3);
  expect(diagnostics['pendingCloseAfterCapture'], isTrue);
  expect(diagnostics['closeAction'], 'done_returned_captured_sections');
  expect(diagnostics['closeResultDelivered'], isTrue);
  expect(diagnostics['lastBackDispatchPath'], 'top_bar_back_button');
  expect(diagnostics['autoCaptureAllowed'], isTrue);
  expect(diagnostics['autoCaptureCurrentlyAllowed'], isTrue);
  expect(diagnostics['closingCamera'], isFalse);
  expect(diagnostics['storageSafetyLevel'], 'maximum');
  expect(diagnostics['storageConstrained'], isTrue);
  expect(diagnostics['storageSafetyReason'], 'tight_storage_tiny_proofs');
  expect(diagnostics['edgeDetectionEnabled'], isTrue);
  expect(diagnostics['edgeOverlayEnabled'], isTrue);
  expect(diagnostics['shadowWarningEnabled'], isTrue);
  expect(diagnostics['textTooSmallWarningEnabled'], isTrue);
  expect(diagnostics['autoCropSuggestionEnabled'], isTrue);
  expect(diagnostics['orientationCorrectionEnabled'], isTrue);
  expect(
    staged.captureDiagnosticsByPhotoPath[staged.photoPaths.single]?.containsKey(
      'receiptText',
    ),
    isFalse,
  );
}
