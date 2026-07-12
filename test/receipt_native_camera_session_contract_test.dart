import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('session disables heavy live work on light phones', () {
    const settings = ReceiptNativeCameraSettings(autoCaptureEnabled: true);
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 2,
      hasRearCamera: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.olderPhone(),
      nativeCapabilities: native,
    );

    expect(config.manualCaptureAvailable, isTrue);
    expect(config.interruptionSafe, isTrue);
    expect(config.liveAnalysisEnabled, isFalse);
    expect(config.autoCaptureAllowed, isFalse);
    expect(config.autoCaptureEnabled, isFalse);
    expect(config.maxSectionCount, 4);
    expect(config.deviceTier, ReceiptCapabilityTier.light);
    expect(config.devicePolicyLabel, 'storage_saver_receipt_camera');
    expect(config.workloadProtectionPolicy, 'storage_saver_light_workload');
    expect(
      config.cloudAssistPlan.planCode,
      'local_ocr_cloud_ocr_cloud_inventory_optional',
    );
    expect(config.cloudAssistPlan.localOcrAvailable, isTrue);
    expect(config.cloudAssistPlan.localOcrMode, 'lean_local_ocr');
    expect(config.cloudAssistPlan.cloudOcrOptional, isTrue);
    expect(config.cloudAssistPlan.cloudInventoryOptional, isTrue);
    expect(config.cloudAssistPlan.requiresExplicitUserChoice, isTrue);
    expect(config.analysisGapMs, 1240);
    expect(config.readyHoldMs, 1120);
    expect(config.assistedShotCount, 2);
    expect(config.bestShotCandidateCount, 1);
    expect(config.cameraResolutionTier, ReceiptCameraResolutionTier.medium);
    expect(config.cameraWorkloadTier, ReceiptCameraWorkloadTier.light);
    expect(config.maxLocalPhotoBytes, 6 * 1024 * 1024);
    expect(
      config.nativeCaptureMemoryPolicy,
      'small_local_proof_temporary_source_for_ocr_then_cleanup',
    );
    expect(config.maxLiveAnalysisPixels, 0);
    expect(config.maxCleanupPixels, 6000000);
    expect(config.maxStitchOutputPixels, 9000000);
    expect(config.maxStitchOutputHeight, 14000);
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.edgeOverlayEnabled, isTrue);
    expect(config.autoCropSuggestionEnabled, isFalse);
    expect(config.sharpeningEnabled, isFalse);
    expect(config.shadowReductionEnabled, isFalse);
    expect(config.grayscalePreviewEnabled, isTrue);
  });

  test('session allows stronger live work on capable phones', () {
    const settings = ReceiptNativeCameraSettings(autoCaptureEnabled: true);
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      supportsTapFocus: true,
      supportsContinuousFocus: true,
      supportsFocusLock: true,
      supportsExposureCompensation: true,
      supportsExposureLock: true,
      supportsWhiteBalanceLock: true,
      supportsZoom: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
      minZoom: 1.0,
      maxZoom: 8.0,
      minExposureOffset: -2.0,
      maxExposureOffset: 2.0,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
    );

    expect(config.liveAnalysisEnabled, isTrue);
    expect(config.edgeDetectionEnabled, isTrue);
    expect(config.autoCaptureAllowed, isTrue);
    expect(config.autoCaptureEnabled, isTrue);
    expect(config.maxSectionCount, 12);
    expect(config.storageConstrained, isFalse);
    expect(config.storageSafetyLevel, ReceiptDataSaverLevel.balanced);
    expect(config.storageSafetyReason, 'normal');
    expect(config.workloadProtectionPolicy, 'flagship_full_workload');
    expect(config.deviceTier, ReceiptCapabilityTier.heavyweight);
    expect(config.devicePolicyLabel, 'flagship_receipt_camera');
    expect(config.cloudAssistPlan.planCode, 'local_ocr_only');
    expect(config.cloudAssistPlan.localOcrAvailable, isTrue);
    expect(config.cloudAssistPlan.localOcrMode, 'full_local_ocr');
    expect(config.cloudAssistPlan.cloudOcrOptional, isFalse);
    expect(config.cloudAssistPlan.cloudInventoryOptional, isFalse);
    expect(config.cloudAssistPlan.requiresExplicitUserChoice, isFalse);
    expect(config.analysisGapMs, 380);
    expect(config.readyHoldMs, 520);
    expect(config.autoCaptureStableFrameTarget, 3);
    expect(config.autoCaptureMaxMotionScore, 7.5);
    expect(config.autoCaptureMinBrightness, 112);
    expect(config.autoCaptureMaxBrightness, 238);
    expect(config.autoCaptureCooldownMs, 2600);
    expect(config.assistedShotCount, 5);
    expect(config.bestShotCandidateCount, 5);
    expect(config.cameraResolutionTier, ReceiptCameraResolutionTier.max);
    expect(config.cameraWorkloadTier, ReceiptCameraWorkloadTier.flagship);
    expect(config.maxLocalPhotoBytes, 20 * 1024 * 1024);
    expect(
      config.nativeCaptureMemoryPolicy,
      'bounded_temporary_source_for_ocr_then_cleanup',
    );
    expect(config.tapFocusEnabled, isFalse);
    expect(config.pinchZoomEnabled, isTrue);
    expect(config.exposureSliderEnabled, isTrue);
    expect(config.exposureResetEnabled, isTrue);
    expect(config.autoExposureAssistEnabled, isTrue);
    expect(
      config.previewExposurePolicy,
      'receipt_paper_metering_safe_auto_lift_manual_slider',
    );
    expect(
      config.preCaptureExposurePolicy,
      'receipt_paper_metering_dim_rescue_v2_manual_slider',
    );
    expect(
      config.previewBrightnessGuardPolicy,
      'avoid_dark_preview_full_receipt_sampling',
    );
    expect(
      config.shutterSpeedPolicy,
      'prefer_fast_document_shutter_auto_capture_when_stable',
    );
    expect(config.tapToFocusPolicy, 'continuous_focus_primary_no_tap_focus');
    expect(config.continuousFocusEnabled, isTrue);
    expect(
      config.focusStrategyPolicy,
      'continuous_focus_primary_no_tap_assist',
    );
    expect(
      config.focusReadabilityFallbackPolicy,
      'not_needed_native_camera_continuous_focus_primary',
    );
    expect(
      config.readabilityGuidancePolicy,
      'native_camera_baseline_neutral_receipt_guidance',
    );
    expect(config.zoomGesturePolicy, 'pinch_zoom_receipt_preview_1.0_to_8.0');
    expect(
      config.autoCapturePolicy,
      'optional_after_3_steady_edge_light_frames',
    );
    expect(config.nativeControlContractTags, [
      'settings',
      'back',
      'manual_shutter',
      'review_next',
      'receipt_guidance',
      'native_camera_baseline',
      'safe_close',
      'pinch_zoom',
      'brightness_slider',
      'brightness_reset',
      'auto_brightness_assist',
      'continuous_focus',
      'manual_focus_optional_future',
      'edge_overlay',
    ]);
    expect(config.focusLockEnabled, isFalse);
    expect(config.exposureLockEnabled, isFalse);
    expect(config.whiteBalanceLockEnabled, isFalse);
    expect(
      config.capabilityPolicyCodes,
      isNot(contains('lock_controls_retired_continuous_focus_primary')),
    );
    expect(
      config.capabilityPolicyCodes,
      contains('full_camera_assist_available'),
    );
    final sessionConfigSource = File(
      'lib/shared/widgets/receipt_capture/receipt_native_camera_session_config.dart',
    ).readAsStringSync();
    expect(sessionConfigSource, isNot(contains("tags.add('focus_lock')")));
    expect(sessionConfigSource, isNot(contains("tags.add('brightness_lock')")));
    expect(
      sessionConfigSource,
      isNot(contains("tags.add('white_balance_lock')")),
    );
    expect(config.minZoom, 1.0);
    expect(config.maxZoom, 8.0);
    expect(config.minExposureOffset, -2.0);
    expect(config.maxExposureOffset, 2.0);
    expect(config.maxLiveAnalysisPixels, 2600000);
    expect(config.maxCleanupPixels, 16000000);
    expect(config.maxStitchOutputPixels, 18000000);
    expect(config.maxStitchOutputHeight, 24000);
    expect(config.edgeOverlayEnabled, isTrue);
    expect(config.perspectiveCorrectionEnabled, isTrue);
    expect(config.autoCropSuggestionEnabled, isTrue);
    expect(config.sharpeningEnabled, isTrue);
    expect(config.shadowReductionEnabled, isTrue);
  });

  test('native capabilities reject non-finite platform numbers', () {
    final native = ReceiptNativeCameraCapabilities.fromMap({
      'engine': 'cameraX',
      'available': true,
      'cameraPermissionGranted': true,
      'hasRearCamera': true,
      'cameraCount': double.infinity,
      'minZoom': double.nan,
      'maxZoom': double.infinity,
      'minExposureOffset': double.negativeInfinity,
      'maxExposureOffset': double.nan,
      'maxStillWidth': double.infinity,
      'maxStillHeight': double.nan,
    });

    expect(native.canOpenReceiptCamera, isTrue);
    expect(native.cameraCount, 0);
    expect(native.minZoom, 1);
    expect(native.maxZoom, 1);
    expect(native.minExposureOffset, 0);
    expect(native.maxExposureOffset, 0);
    expect(native.maxStillWidth, 0);
    expect(native.maxStillHeight, 0);
  });

  test(
    'session forces legacy manual focus settings back to continuous focus',
    () {
      const settings = ReceiptNativeCameraSettings(
        tapFocusEnabled: true,
        focusMode: ReceiptNativeFocusMode.manual,
      );
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        cameraCount: 2,
        hasRearCamera: true,
        supportsTapFocus: true,
        supportsContinuousFocus: true,
        supportsManualFocusDistance: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );

      final config = settings.sessionFor(
        deviceCapability: const ReceiptDeviceCapability.standard(),
        nativeCapabilities: native,
      );

      expect(config.tapFocusEnabled, isFalse);
      expect(config.continuousFocusEnabled, isTrue);
      expect(
        config.focusStrategyPolicy,
        'continuous_focus_primary_no_tap_assist',
      );
      expect(
        config.focusReadabilityFallbackPolicy,
        'not_needed_native_camera_continuous_focus_primary',
      );
      expect(config.nativeControlContractTags, contains('continuous_focus'));
      expect(
        config.nativeControlContractTags,
        isNot(contains('focus_readability_review')),
      );
      expect(config.focusLockEnabled, isFalse);
      expect(config.exposureLockEnabled, isFalse);
      expect(config.whiteBalanceLockEnabled, isFalse);
      expect(
        config.capabilityPolicyCodes,
        isNot(contains('continuous_focus_unavailable')),
      );
    },
  );

  test(
    'session does not send fake camera controls when native lacks support',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        cameraCount: 1,
        hasRearCamera: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );

      final config = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.standard(),
        nativeCapabilities: native,
      );

      expect(config.tapFocusEnabled, isFalse);
      expect(config.pinchZoomEnabled, isFalse);
      expect(config.exposureSliderEnabled, isFalse);
      expect(config.exposureResetEnabled, isFalse);
      expect(config.autoExposureAssistEnabled, isFalse);
      expect(
        config.previewExposurePolicy,
        'native_auto_metering_no_manual_slider',
      );
      expect(config.tapToFocusPolicy, 'continuous_focus_primary_no_tap_focus');
      expect(config.continuousFocusEnabled, isFalse);
      expect(
        config.focusStrategyPolicy,
        'continuous_focus_unavailable_readability_review_required',
      );
      expect(
        config.focusReadabilityFallbackPolicy,
        'continuous_focus_unavailable_native_camera_review_required',
      );
      expect(
        config.zoomGesturePolicy,
        'pinch_zoom_unavailable_keep_native_scale',
      );
      expect(config.nativeControlContractTags, [
        'settings',
        'back',
        'manual_shutter',
        'review_next',
        'receipt_guidance',
        'native_camera_baseline',
        'safe_close',
        'focus_readability_review',
        'manual_focus_optional_future',
        'edge_overlay',
      ]);
      expect(config.focusLockEnabled, isFalse);
      expect(config.exposureLockEnabled, isFalse);
      expect(config.whiteBalanceLockEnabled, isFalse);
      expect(config.minZoom, 1.0);
      expect(config.maxZoom, 1.0);
      expect(config.minExposureOffset, 0.0);
      expect(config.maxExposureOffset, 0.0);
    },
  );

  test('session limits long receipt sections when proof storage is tiny', () {
    const settings = ReceiptNativeCameraSettings(
      autoCaptureEnabled: true,
      dataSaverLevel: ReceiptDataSaverLevel.maximum,
    );
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      cameraCount: 4,
      hasRearCamera: true,
      supportsYuvLiveFrames: true,
      supportsNativeEdgeSignals: true,
    );

    final config = settings.sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
    );

    expect(config.manualCaptureAvailable, isTrue);
    expect(config.ocrSourceProtected, isTrue);
    expect(config.storageConstrained, isTrue);
    expect(config.storageSafetyLevel, ReceiptDataSaverLevel.maximum);
    expect(config.storageSafetyReason, 'tight_storage_tiny_proofs');
    expect(
      config.workloadProtectionPolicy,
      'maximum_storage_saver_light_workload',
    );
    expect(config.maxSectionCount, 4);
    expect(config.liveAnalysisEnabled, isTrue);
    expect(config.autoCaptureAllowed, isFalse);
    expect(config.autoCaptureEnabled, isFalse);
    expect(config.devicePolicyLabel, 'storage_saver_receipt_camera');
    expect(config.analysisGapMs, 540);
    expect(config.readyHoldMs, 600);
    expect(config.bestShotCandidateCount, 3);
    expect(config.cameraWorkloadTier, ReceiptCameraWorkloadTier.light);
    expect(config.maxLiveAnalysisPixels, 900000);
    expect(config.maxCleanupPixels, 6000000);
    expect(config.shadowReductionEnabled, isFalse);
    expect(config.autoCropSuggestionEnabled, isTrue);
  });
}
