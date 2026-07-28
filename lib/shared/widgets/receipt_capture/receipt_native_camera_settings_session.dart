part of 'receipt_native_camera_contract.dart';

extension ReceiptNativeCameraSettingsSession on ReceiptNativeCameraSettings {
  bool get protectsInterruptedCapture =>
      saveOriginalTemporarily && queueAcceptedCaptureLocally;

  ReceiptNativeCameraSessionConfig sessionFor({
    required ReceiptDeviceCapability deviceCapability,
    required ReceiptNativeCameraCapabilities nativeCapabilities,
    String? previousSectionGuidePhotoPath,
    String? nextSectionGuidePhotoPath,
    String? previousSectionReasonCode,
    String? previousSectionGuidance,
    double? previousSectionGhostSourceStartFraction,
    double? previousSectionGhostSourceHeightFraction,
    double? previousSectionGhostOverlayTopFraction,
    double? previousSectionGhostOverlayHeightFraction,
    double? previousSectionGhostOpacity,
  }) {
    final deviceTier = deviceCapability.tier;
    final lightDevice = deviceTier == ReceiptCapabilityTier.light;
    final heavyweightDevice = deviceTier == ReceiptCapabilityTier.heavyweight;
    final storageSafetyLevel = _strongerNativeCameraDataSaverLevel(
      dataSaverLevel,
      deviceCapability.recommendedDataSaverLevel,
    );
    final storageConstrained =
        storageSafetyLevel == ReceiptDataSaverLevel.strong ||
        storageSafetyLevel == ReceiptDataSaverLevel.maximum;
    final maxSectionCount = longReceiptMode
        ? _nativeCameraSectionLimitForStorage(
            deviceCapability.maxLocalPhotoCount,
            storageSafetyLevel,
          )
        : 1;
    final autoCaptureAllowed =
        edgeDetectionEnabled &&
        nativeCapabilities.supportsNativeEdgeSignals &&
        !lightDevice &&
        !storageConstrained;
    final liveAnalysisAllowed =
        liveYuvAnalysisEnabled &&
        nativeCapabilities.supportsYuvLiveFrames &&
        !lightDevice;
    final effectiveEdgeDetection =
        edgeDetectionEnabled &&
        (nativeCapabilities.supportsNativeEdgeSignals || !lightDevice);
    final effectiveAutoCropSuggestion =
        autoCropSuggestionEnabled && effectiveEdgeDetection && !lightDevice;
    final heavyCleanupAllowed = !lightDevice && !storageConstrained;
    final effectiveTapFocus = false;
    // Capability preflight can run before the platform has bound the rear
    // camera (and has reported a 1x-only range on real capable phones).
    // Keep the user's pinch setting enabled; each native camera resolves the
    // live lens range after binding and safely reports a locked range when
    // zoom genuinely is unavailable. Disabling this here turns a bad
    // preflight result into a dead pinch gesture on the capture screen.
    final effectivePinchZoom = pinchZoomEnabled;
    final effectiveExposureSlider =
        exposureSliderEnabled &&
        nativeCapabilities.supportsExposureCompensation &&
        nativeCapabilities.maxExposureOffset >
            nativeCapabilities.minExposureOffset;
    final effectiveExposureAssist =
        autoExposureAssistEnabled && effectiveExposureSlider;
    final effectiveContinuousFocus = nativeCapabilities.supportsContinuousFocus;
    final effectiveFocusLock = false;
    final effectiveExposureLock = false;
    final effectiveWhiteBalanceLock = false;
    final effectiveZoomMin = effectivePinchZoom
        ? nativeCapabilities.minZoom
        : 1.0;
    final effectiveZoomMax = effectivePinchZoom
        ? nativeCapabilities.maxZoom
        : 1.0;
    // A receipt camera must never open already zoomed. Start at the native
    // wide framing and let the user deliberately pinch toward the receipt.
    final effectiveInitialZoom = (effectivePinchZoom
            ? effectiveZoomMin
            : 1.0)
        .clamp(effectiveZoomMin, effectiveZoomMax)
        .toDouble();
    final effectiveExposureMin = effectiveExposureSlider
        ? nativeCapabilities.minExposureOffset
        : 0.0;
    final effectiveExposureMax = effectiveExposureSlider
        ? nativeCapabilities.maxExposureOffset
        : 0.0;
    final workloadTier = storageConstrained
        ? ReceiptCameraWorkloadTier.light
        : deviceCapability.cameraWorkloadTier;
    final maxLiveAnalysisPixels = liveAnalysisAllowed
        ? workloadTier.maxLiveAnalysisPixels
        : 0;
    final maxCleanupPixels = storageConstrained
        ? ReceiptCameraWorkloadTier.light.maxCleanupPixels
        : deviceCapability.maxCleanupPixels;
    final analysisGapMs =
        deviceCapability.liveAnalysisGapMs +
        (lightDevice ? 320 : 0) +
        (storageConstrained ? 160 : 0);
    final cloudAssistPlan = deviceCapability.cloudAssistPlanFor(
      dataSaverLevel: storageSafetyLevel,
    );
    final installStorageClass = _nativeCameraInstallStorageClassFor(
      storageSafetyLevel,
    );
    final installRecommendation = cloudAssistPlan.footprintPlan
        .installRecommendationForStorageClass(installStorageClass);
    final receiptBrainRecommendation = deviceCapability
        .receiptBrainRecommendationFor(
          installStorageClass,
          cloudAssistPlan: cloudAssistPlan,
        );
    final receiptBrainFootprintSummary = deviceCapability
        .receiptBrainFootprintSummaryFor(
          installStorageClass,
          cloudAssistPlan: cloudAssistPlan,
        );
    final parserPackRoutingPlan = cloudAssistPlan.parserPackRoutingPlan;
    final readyHoldMs =
        deviceCapability.readyHoldMs +
        (lightDevice ? 220 : 0) +
        (heavyweightDevice && !storageConstrained ? -80 : 0);
    final capabilityPolicyCodes = _nativeCameraCapabilityPolicyCodes(
      lightDevice: lightDevice,
      storageConstrained: storageConstrained,
      nativeCapabilities: nativeCapabilities,
      autoCaptureAllowed: autoCaptureAllowed,
      liveAnalysisAllowed: liveAnalysisAllowed,
      effectiveEdgeDetection: effectiveEdgeDetection,
      effectivePinchZoom: effectivePinchZoom,
      effectiveExposureSlider: effectiveExposureSlider,
      effectiveExposureAssist: effectiveExposureAssist,
      effectiveContinuousFocus: effectiveContinuousFocus,
      heavyCleanupAllowed: heavyCleanupAllowed,
      longReceiptMode: longReceiptMode,
    );
    final previousGuidePhotoPath = receiptNativeCameraLocalImagePathOrNull(
      previousSectionGuidePhotoPath,
    );
    final nextGuidePhotoPath = receiptNativeCameraLocalImagePathOrNull(
      nextSectionGuidePhotoPath,
    );
    final normalizedPreviousReason = previousSectionReasonCode
        ?.trim()
        .toLowerCase();
    final hasPreviousGuide =
        previousSectionGhostGuideEnabled &&
        longReceiptMode &&
        previousGuidePhotoPath != null;

    return ReceiptNativeCameraSessionConfig(
      settings: this,
      nativeCapabilities: nativeCapabilities,
      deviceTier: deviceTier,
      devicePolicyLabel: _nativeCameraDevicePolicyLabel(
        tier: deviceTier,
        storageConstrained: storageConstrained,
      ),
      capabilityPolicyCodes: capabilityPolicyCodes,
      cloudAssistPlan: cloudAssistPlan,
      installRecommendation: installRecommendation,
      receiptBrainRecommendation: receiptBrainRecommendation,
      receiptBrainFootprintSummary: receiptBrainFootprintSummary,
      parserPackRoutingPlan: parserPackRoutingPlan,
      storageSafetyLevel: storageSafetyLevel,
      storageConstrained: storageConstrained,
      autoCaptureAllowed: autoCaptureAllowed,
      liveAnalysisEnabled: liveAnalysisAllowed,
      edgeDetectionEnabled: effectiveEdgeDetection,
      autoCaptureEnabled: autoCaptureEnabled && autoCaptureAllowed,
      maxSectionCount: maxSectionCount,
      analysisGapMs: analysisGapMs,
      readyHoldMs: readyHoldMs < 500 ? 500 : readyHoldMs,
      autoCaptureStableFrameTarget: autoCaptureAllowed ? 3 : 0,
      autoCaptureMaxMotionScore: 7.5,
      autoCaptureMinBrightness: 112,
      autoCaptureMaxBrightness: 238,
      autoCaptureCooldownMs: autoCaptureAllowed ? 2600 : 0,
      assistedShotCount: deviceCapability.assistedCameraShotCount,
      bestShotCandidateCount: storageConstrained
          ? deviceCapability.bestShotCandidateCount.clamp(1, 3).toInt()
          : deviceCapability.bestShotCandidateCount,
      cameraResolutionTier: deviceCapability.cameraResolutionTier,
      cameraWorkloadTier: workloadTier,
      maxLocalPhotoBytes: deviceCapability.maxLocalPhotoBytes,
      tapFocusEnabled: effectiveTapFocus,
      pinchZoomEnabled: effectivePinchZoom,
      exposureSliderEnabled: effectiveExposureSlider,
      exposureResetEnabled: exposureResetEnabled && effectiveExposureSlider,
      autoExposureAssistEnabled: effectiveExposureAssist,
      continuousFocusEnabled: effectiveContinuousFocus,
      focusLockEnabled: effectiveFocusLock,
      exposureLockEnabled: effectiveExposureLock,
      whiteBalanceLockEnabled: effectiveWhiteBalanceLock,
      minZoom: effectiveZoomMin,
      maxZoom: effectiveZoomMax,
      initialZoomRatio: effectiveInitialZoom,
      minExposureOffset: effectiveExposureMin,
      maxExposureOffset: effectiveExposureMax,
      maxLiveAnalysisPixels: maxLiveAnalysisPixels,
      maxCleanupPixels: maxCleanupPixels,
      maxStitchOutputPixels: deviceCapability.stitchLimits.maxOutputPixels,
      maxStitchOutputHeight: deviceCapability.stitchLimits.maxOutputHeight,
      edgeOverlayEnabled: edgeOverlayEnabled && effectiveEdgeDetection,
      perspectiveCorrectionEnabled:
          perspectiveCorrectionEnabled && effectiveEdgeDetection,
      autoCropSuggestionEnabled: effectiveAutoCropSuggestion,
      contrastBoostEnabled: contrastBoostEnabled,
      sharpeningEnabled: sharpeningEnabled && !lightDevice,
      shadowReductionEnabled: shadowReductionEnabled && heavyCleanupAllowed,
      adaptiveThresholdEnabled: adaptiveThresholdEnabled,
      grayscalePreviewEnabled: grayscalePreviewEnabled,
      orientationCorrectionEnabled: orientationCorrectionEnabled,
      previousSectionGuidePhotoPath: hasPreviousGuide
          ? previousGuidePhotoPath
          : null,
      nextSectionGuidePhotoPath:
          normalizedPreviousReason ==
                  'retake_middle_with_previous_next_context' &&
              hasPreviousGuide &&
              nextGuidePhotoPath != null &&
              nextGuidePhotoPath != previousGuidePhotoPath
          ? nextGuidePhotoPath
          : null,
      previousSectionReasonCode:
          hasPreviousGuide &&
              previousSectionReasonCode != null &&
              previousSectionReasonCode.trim().isNotEmpty
          ? previousSectionReasonCode.trim()
          : null,
      previousSectionGuidance:
          hasPreviousGuide &&
              previousSectionGuidance != null &&
              previousSectionGuidance.trim().isNotEmpty
          ? previousSectionGuidance.trim()
          : null,
      previousSectionGhostSourceStartFraction: hasPreviousGuide
          ? _boundedNativeCameraFraction(
              previousSectionGhostSourceStartFraction,
            )
          : null,
      previousSectionGhostSourceHeightFraction: hasPreviousGuide
          ? _boundedNativeCameraFraction(
              previousSectionGhostSourceHeightFraction,
            )
          : null,
      previousSectionGhostOverlayTopFraction: hasPreviousGuide
          ? _boundedNativeCameraFraction(previousSectionGhostOverlayTopFraction)
          : null,
      previousSectionGhostOverlayHeightFraction: hasPreviousGuide
          ? _boundedNativeCameraFraction(
              previousSectionGhostOverlayHeightFraction,
            )
          : null,
      previousSectionGhostOpacity: hasPreviousGuide
          ? _boundedNativeCameraFraction(previousSectionGhostOpacity)
          : null,
      cameraStoragePolicy: deviceCapability.cameraStoragePolicy,
    );
  }
}
