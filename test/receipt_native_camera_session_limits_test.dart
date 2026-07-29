import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_assistance_policy.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_capture_models.dart';
import 'package:maintaniac/shared/widgets/receipt_capture/receipt_native_camera_contract.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'session honors device storage pressure even with balanced user setting',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        cameraCount: 3,
        hasRearCamera: true,
        supportsYuvLiveFrames: true,
        supportsNativeEdgeSignals: true,
      );
      final storagePressedDevice = const ReceiptDeviceCapability.highCapacity()
          .withStoragePressure(ReceiptDeviceStorageClass.low);

      final config =
          const ReceiptNativeCameraSettings(
            autoCaptureEnabled: true,
            dataSaverLevel: ReceiptDataSaverLevel.balanced,
          ).sessionFor(
            deviceCapability: storagePressedDevice,
            nativeCapabilities: native,
          );

      expect(config.storageConstrained, isTrue);
      expect(config.storageSafetyLevel, ReceiptDataSaverLevel.strong);
      expect(config.storageSafetyReason, 'low_storage_small_proofs');
      expect(config.maxSectionCount, 5);
      expect(config.autoCaptureAllowed, isFalse);
      expect(config.autoCaptureEnabled, isFalse);
      expect(config.ocrSourceProtected, isTrue);
      expect(
        config.cloudAssistPlan.planCode,
        'local_ocr_cloud_ocr_cloud_inventory_optional',
      );
      expect(config.cloudAssistPlan.localOcrAvailable, isTrue);
      expect(config.cloudAssistPlan.localOcrMode, 'lean_local_ocr');
      expect(config.cloudAssistPlan.cloudOcrOptional, isTrue);
      expect(config.cloudAssistPlan.cloudInventoryOptional, isTrue);
      expect(config.cloudAssistPlan.requiresExplicitUserChoice, isTrue);
      expect(config.cloudAssistPlan.localCatalogMatchLimit, 500);
      expect(config.cloudAssistPlan.localInventoryCacheLimit, 1500);
      expect(
        config.installRecommendation.modeCode,
        'small_optional_pack_allowed',
      );
      expect(config.installRecommendation.optionalLocalDownloadAllowed, isTrue);
      expect(config.installRecommendation.cloudFallbackSuggested, isTrue);
      expect(
        config.receiptBrainRecommendation.modeCode,
        'base_local_reader_small_pack_optional',
      );
      expect(
        config.receiptBrainRecommendation.baseCaptureAlwaysAvailable,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.localReceiptReaderDefault,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.optionalLocalPackAllowed,
        isTrue,
      );
      expect(
        config.receiptBrainRecommendation.optionalLocalPackBytes,
        24 * 1024 * 1024,
      );
      expect(config.receiptBrainRecommendation.assistFallbackAllowed, isTrue);
      expect(config.parserPackRoutingPlan.localFirstCategoryCodes, [
        'fuel',
        'general_expense',
      ]);
      expect(config.parserPackRoutingPlan.optionalLocalCategoryCodes, [
        'general_expense',
      ]);
      expect(config.parserPackRoutingPlan.assistFallbackCategoryCodes, [
        'fuel',
        'general_expense',
        'materials_inventory',
      ]);
    },
  );

  test('session carries previous section guide only for long receipt flow', () {
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
    );
    final withGuide = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
      previousSectionGuidePhotoPath: ' /tmp/receipt-section-1.jpg ',
      previousSectionReasonCode: ' missing_bottom_edge_and_totals ',
      previousSectionGuidance: ' Add the bottom receipt section. ',
    );
    final guideDisabled =
        const ReceiptNativeCameraSettings(
          previousSectionGhostGuideEnabled: false,
        ).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        );
    final longReceiptDisabled =
        const ReceiptNativeCameraSettings(longReceiptMode: false).sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        );

    expect(withGuide.hasPreviousSectionGuide, isTrue);
    expect(
      withGuide.previousSectionGuidePhotoPath,
      '/tmp/receipt-section-1.jpg',
    );
    expect(
      withGuide.previousSectionGuideReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(withGuide.previousSectionGuideMissingBottomAndTotals, isTrue);
    expect(
      withGuide.previousSectionGhostGuidePolicy,
      'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(
      withGuide.previousSectionGhostGuideRepeatLineTarget,
      'repeat_3_to_5_readable_lines',
    );
    expect(withGuide.previousSectionGhostGuidePlacement, 'top_ghost_slice');
    expect(
      withGuide.previousSectionGhostGuideMatchTarget,
      'subtotal_total_and_final_lines',
    );
    expect(withGuide.previousSectionGhostSourceStartFractionOrDefault, .80);
    expect(withGuide.previousSectionGhostSourceHeightFractionOrDefault, .20);
    expect(withGuide.previousSectionGhostOverlayTopFractionOrDefault, 0);
    expect(withGuide.previousSectionGhostOverlayHeightFractionOrDefault, .20);
    expect(withGuide.previousSectionGhostOpacityOrDefault, .36);
    expect(withGuide.previousSectionGhostSlicePercent, 20);
    expect(
      withGuide.previousSectionGuideGuidance,
      'Add the bottom receipt section.',
    );
    final bottomGuideWithoutCopy = const ReceiptNativeCameraSettings()
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
          previousSectionReasonCode: 'missing_bottom_edge_and_totals',
        );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('repeat 3-5 readable lines'),
    );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('top ghost slice'),
    );
    expect(
      bottomGuideWithoutCopy.previousSectionGuideGuidance,
      contains('subtotal, total, and final lines can be matched'),
    );
    expect(guideDisabled.hasPreviousSectionGuide, isFalse);
    expect(longReceiptDisabled.hasPreviousSectionGuide, isFalse);
    expect(longReceiptDisabled.maxSectionCount, 1);
    expect(
      longReceiptDisabled.capabilityPolicyCodes,
      contains('long_receipt_mode_disabled'),
    );

    final uppercaseBottomReason = const ReceiptNativeCameraSettings()
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
          previousSectionReasonCode: ' MISSING_BOTTOM_EDGE_AND_TOTALS ',
        );
    expect(
      uppercaseBottomReason.previousSectionGuideReasonCode,
      'missing_bottom_edge_and_totals',
    );
    expect(
      uppercaseBottomReason.previousSectionGhostGuidePolicy,
      'bottom_overlap_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(
      uppercaseBottomReason.previousSectionGhostGuideMatchTarget,
      'subtotal_total_and_final_lines',
    );

    final topRetakeGuide = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
      previousSectionGuidePhotoPath: '/tmp/receipt-section-2.jpg',
      previousSectionReasonCode: 'retake_top_with_next_context',
      previousSectionGhostSourceStartFraction: 0,
      previousSectionGhostSourceHeightFraction: .20,
      previousSectionGhostOverlayTopFraction: 0,
      previousSectionGhostOverlayHeightFraction: .20,
      previousSectionGhostOpacity: .32,
    );
    expect(topRetakeGuide.previousSectionGuideUsesNextContext, isTrue);
    expect(
      topRetakeGuide.previousSectionGhostGuidePolicy,
      'next_section_top_context_ghost_at_top_repeat_3_to_5_lines',
    );
    expect(
      topRetakeGuide.previousSectionGhostGuideMatchTarget,
      'next_section_top_lines',
    );
    expect(topRetakeGuide.previousSectionGhostSourceStartFractionOrDefault, 0);
    expect(
      topRetakeGuide.previousSectionGhostSourceHeightFractionOrDefault,
      .20,
    );
    expect(topRetakeGuide.previousSectionGhostOverlayTopFractionOrDefault, 0);
    expect(
      topRetakeGuide.previousSectionGhostOverlayHeightFractionOrDefault,
      .20,
    );
    expect(topRetakeGuide.previousSectionGhostOpacityOrDefault, .32);
    expect(topRetakeGuide.previousSectionGhostSlicePercent, 20);

    final malformedFractionsGuide = const ReceiptNativeCameraSettings()
        .sessionFor(
          deviceCapability: const ReceiptDeviceCapability.highCapacity(),
          nativeCapabilities: native,
          previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
          previousSectionReasonCode: 'missing_bottom_edge_and_totals',
          previousSectionGhostSourceStartFraction: -.45,
          previousSectionGhostSourceHeightFraction: .98,
          previousSectionGhostOverlayTopFraction: .82,
          previousSectionGhostOverlayHeightFraction: double.nan,
          previousSectionGhostOpacity: 1.7,
        );
    expect(
      malformedFractionsGuide.previousSectionGhostSourceStartFractionOrDefault,
      .65,
    );
    expect(
      malformedFractionsGuide.previousSectionGhostSourceHeightFractionOrDefault,
      .20,
    );
    expect(
      malformedFractionsGuide.previousSectionGhostOverlayTopFractionOrDefault,
      .30,
    );
    expect(
      malformedFractionsGuide
          .previousSectionGhostOverlayHeightFractionOrDefault,
      .20,
    );
    expect(malformedFractionsGuide.previousSectionGhostOpacityOrDefault, .62);
    expect(malformedFractionsGuide.previousSectionGhostSlicePercent, 20);
  });

  test('session rejects unsafe previous section guide photo paths', () {
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
    );

    for (final unsafePath in [
      'receipt-section-1.jpg',
      'https://example.test/receipt-section-1.jpg',
      'file:///tmp/receipt-section-1.jpg',
      '/tmp/receipt-section-1.txt',
      '/tmp/receipt-section-1.jpg\u0000.png',
    ]) {
      final config = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: unsafePath,
        previousSectionReasonCode: 'missing_bottom_edge_and_totals',
        previousSectionGuidance: 'Continue the receipt.',
        previousSectionGhostOpacity: .36,
      );

      expect(config.hasPreviousSectionGuide, isFalse);
      expect(config.previousSectionGuidePhotoPath, isNull);
      expect(config.previousSectionGuideReasonCode, 'none');
      expect(config.previousSectionGhostGuidePolicy, 'not_requested');
      expect(config.previousSectionGhostOpacity, isNull);
    }

    final uppercaseImagePath = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
      previousSectionGuidePhotoPath: ' /tmp/receipt-section-1.HEIC ',
    );
    expect(uppercaseImagePath.hasPreviousSectionGuide, isTrue);
    expect(
      uppercaseImagePath.previousSectionGuidePhotoPath,
      '/tmp/receipt-section-1.HEIC',
    );
  });

  test(
    'session bounds previous section ghost guide fractions to usable values',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        hasRearCamera: true,
      );

      final tooSmall = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionGhostSourceStartFraction: 0,
        previousSectionGhostSourceHeightFraction: 0,
        previousSectionGhostOverlayTopFraction: 0,
        previousSectionGhostOverlayHeightFraction: 0,
        previousSectionGhostOpacity: 0,
      );
      final tooLarge = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionGhostSourceStartFraction: 1,
        previousSectionGhostSourceHeightFraction: 1,
        previousSectionGhostOverlayTopFraction: 1,
        previousSectionGhostOverlayHeightFraction: 1,
        previousSectionGhostOpacity: 1,
      );

      expect(tooSmall.previousSectionGhostSourceStartFractionOrDefault, .65);
      expect(tooSmall.previousSectionGhostSourceHeightFractionOrDefault, .15);
      expect(tooSmall.previousSectionGhostOverlayTopFractionOrDefault, 0);
      expect(tooSmall.previousSectionGhostOverlayHeightFractionOrDefault, .15);
      expect(tooSmall.previousSectionGhostOpacityOrDefault, .18);
      expect(tooSmall.previousSectionGhostSlicePercent, 15);

      expect(tooLarge.previousSectionGhostSourceStartFractionOrDefault, .92);
      expect(tooLarge.previousSectionGhostSourceHeightFractionOrDefault, .20);
      expect(tooLarge.previousSectionGhostOverlayTopFractionOrDefault, .30);
      expect(tooLarge.previousSectionGhostOverlayHeightFractionOrDefault, .20);
      expect(tooLarge.previousSectionGhostOpacityOrDefault, .62);
      expect(tooLarge.previousSectionGhostSlicePercent, 20);
    },
  );

  test('session rejects non-finite previous section ghost guide fractions', () {
    const native = ReceiptNativeCameraCapabilities(
      engine: ReceiptNativeCameraEngine.cameraX,
      available: true,
      cameraPermissionGranted: true,
      hasRearCamera: true,
    );

    final config = const ReceiptNativeCameraSettings().sessionFor(
      deviceCapability: const ReceiptDeviceCapability.highCapacity(),
      nativeCapabilities: native,
      previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
      previousSectionGhostSourceStartFraction: double.nan,
      previousSectionGhostSourceHeightFraction: double.infinity,
      previousSectionGhostOverlayTopFraction: double.negativeInfinity,
      previousSectionGhostOverlayHeightFraction: double.nan,
      previousSectionGhostOpacity: double.infinity,
    );

    expect(config.hasPreviousSectionGuide, isTrue);
    expect(config.previousSectionGhostSourceStartFraction, isNull);
    expect(config.previousSectionGhostSourceHeightFraction, isNull);
    expect(config.previousSectionGhostOverlayTopFraction, isNull);
    expect(config.previousSectionGhostOverlayHeightFraction, isNull);
    expect(config.previousSectionGhostOpacity, isNull);
    expect(config.previousSectionGhostSourceStartFractionOrDefault, .80);
    expect(config.previousSectionGhostSourceHeightFractionOrDefault, .20);
    expect(config.previousSectionGhostOverlayTopFractionOrDefault, 0);
    expect(config.previousSectionGhostOverlayHeightFractionOrDefault, .20);
    expect(config.previousSectionGhostOpacityOrDefault, .32);
    expect(config.previousSectionGhostSlicePercent, 20);
  });

  test(
    'session config getters reject direct non-finite ghost guide values',
    () {
      const native = ReceiptNativeCameraCapabilities(
        engine: ReceiptNativeCameraEngine.cameraX,
        available: true,
        cameraPermissionGranted: true,
        hasRearCamera: true,
      );
      final base = const ReceiptNativeCameraSettings().sessionFor(
        deviceCapability: const ReceiptDeviceCapability.highCapacity(),
        nativeCapabilities: native,
        previousSectionGuidePhotoPath: '/tmp/receipt-section-1.jpg',
        previousSectionReasonCode: 'missing_bottom_edge_and_totals',
      );
      final config = _copySessionWithGhostFractions(
        base,
        sourceStart: double.nan,
        sourceHeight: double.infinity,
        overlayTop: double.negativeInfinity,
        overlayHeight: double.nan,
        opacity: double.infinity,
      );

      expect(config.previousSectionGhostSourceStartFractionOrDefault, .80);
      expect(config.previousSectionGhostSourceHeightFractionOrDefault, .20);
      expect(config.previousSectionGhostOverlayTopFractionOrDefault, 0);
      expect(config.previousSectionGhostOverlayHeightFractionOrDefault, .20);
      expect(config.previousSectionGhostOpacityOrDefault, .36);
      expect(config.previousSectionGhostSlicePercent, 20);
    },
  );
}

ReceiptNativeCameraSessionConfig _copySessionWithGhostFractions(
  ReceiptNativeCameraSessionConfig base, {
  required double sourceStart,
  required double sourceHeight,
  required double overlayTop,
  required double overlayHeight,
  required double opacity,
}) {
  return ReceiptNativeCameraSessionConfig(
    settings: base.settings,
    nativeCapabilities: base.nativeCapabilities,
    deviceTier: base.deviceTier,
    devicePolicyLabel: base.devicePolicyLabel,
    capabilityPolicyCodes: base.capabilityPolicyCodes,
    cloudAssistPlan: base.cloudAssistPlan,
    installRecommendation: base.installRecommendation,
    receiptBrainRecommendation: base.receiptBrainRecommendation,
    receiptBrainFootprintSummary: base.receiptBrainFootprintSummary,
    parserPackRoutingPlan: base.parserPackRoutingPlan,
    storageSafetyLevel: base.storageSafetyLevel,
    storageConstrained: base.storageConstrained,
    autoCaptureAllowed: base.autoCaptureAllowed,
    liveAnalysisEnabled: base.liveAnalysisEnabled,
    edgeDetectionEnabled: base.edgeDetectionEnabled,
    autoCaptureEnabled: base.autoCaptureEnabled,
    maxSectionCount: base.maxSectionCount,
    analysisGapMs: base.analysisGapMs,
    readyHoldMs: base.readyHoldMs,
    autoCaptureStableFrameTarget: base.autoCaptureStableFrameTarget,
    autoCaptureMaxMotionScore: base.autoCaptureMaxMotionScore,
    autoCaptureMinBrightness: base.autoCaptureMinBrightness,
    autoCaptureMaxBrightness: base.autoCaptureMaxBrightness,
    autoCaptureCooldownMs: base.autoCaptureCooldownMs,
    assistedShotCount: base.assistedShotCount,
    bestShotCandidateCount: base.bestShotCandidateCount,
    cameraResolutionTier: base.cameraResolutionTier,
    cameraWorkloadTier: base.cameraWorkloadTier,
    maxLocalPhotoBytes: base.maxLocalPhotoBytes,
    tapFocusEnabled: base.tapFocusEnabled,
    pinchZoomEnabled: base.pinchZoomEnabled,
    exposureSliderEnabled: base.exposureSliderEnabled,
    exposureResetEnabled: base.exposureResetEnabled,
    autoExposureAssistEnabled: base.autoExposureAssistEnabled,
    continuousFocusEnabled: base.continuousFocusEnabled,
    focusLockEnabled: base.focusLockEnabled,
    exposureLockEnabled: base.exposureLockEnabled,
    whiteBalanceLockEnabled: base.whiteBalanceLockEnabled,
    minZoom: base.minZoom,
    maxZoom: base.maxZoom,
    initialZoomRatio: base.initialZoomRatio,
    minExposureOffset: base.minExposureOffset,
    maxExposureOffset: base.maxExposureOffset,
    maxLiveAnalysisPixels: base.maxLiveAnalysisPixels,
    maxCleanupPixels: base.maxCleanupPixels,
    maxStitchOutputPixels: base.maxStitchOutputPixels,
    maxStitchOutputHeight: base.maxStitchOutputHeight,
    edgeOverlayEnabled: base.edgeOverlayEnabled,
    perspectiveCorrectionEnabled: base.perspectiveCorrectionEnabled,
    autoCropSuggestionEnabled: base.autoCropSuggestionEnabled,
    contrastBoostEnabled: base.contrastBoostEnabled,
    sharpeningEnabled: base.sharpeningEnabled,
    shadowReductionEnabled: base.shadowReductionEnabled,
    adaptiveThresholdEnabled: base.adaptiveThresholdEnabled,
    grayscalePreviewEnabled: base.grayscalePreviewEnabled,
    orientationCorrectionEnabled: base.orientationCorrectionEnabled,
    previousSectionGuidePhotoPath: base.previousSectionGuidePhotoPath,
    previousSectionReasonCode: base.previousSectionReasonCode,
    previousSectionGuidance: base.previousSectionGuidance,
    previousSectionGhostSourceStartFraction: sourceStart,
    previousSectionGhostSourceHeightFraction: sourceHeight,
    previousSectionGhostOverlayTopFraction: overlayTop,
    previousSectionGhostOverlayHeightFraction: overlayHeight,
    previousSectionGhostOpacity: opacity,
  );
}
