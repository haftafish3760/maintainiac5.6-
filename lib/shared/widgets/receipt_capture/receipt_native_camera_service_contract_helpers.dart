part of 'receipt_native_camera_service.dart';

Map<String, Object?> _sessionArguments(
  ReceiptNativeCameraSessionConfig config,
) {
  final settings = config.settings;
  return {
    'engine': config.nativeCapabilities.engine.name,
    'uiLocale': _receiptCameraUiLocale(),
    'settingsContractVersion': 'receipt_native_camera_settings_v1',
    ..._nativeControlContract(config),
    'deviceTier': config.deviceTier.name,
    'devicePolicyLabel': config.devicePolicyLabel,
    'capabilityPolicyCodes': config.capabilityPolicyCodes,
    ...config.cloudAssistPlan.toPrivacySafeDiagnostics(),
    ...config.installRecommendation.toPrivacySafeDiagnostics(),
    ...config.receiptBrainRecommendation.toPrivacySafeDiagnostics(),
    ...config.receiptBrainFootprintSummary.toPrivacySafeDiagnostics(),
    ...config.parserPackRoutingPlan.toPrivacySafeDiagnostics(),
    'localOnlyCapturePolicy': config.localOnlyCapturePolicy,
    'localOnlyBaseFlowCanRunNow':
        config.localOnlyAcceptanceGate.baseFlowCanRunLocallyNow,
    'localOnlyHeavyPacksMayBlockCapture':
        config.heavyReceiptPacksMayBlockCapture,
    'localOnlyCloudAssistMayBlockCapture': config.cloudAssistMayBlockCapture,
    'localOnlyCameraMustStayAvailableBeforePacks':
        !config.heavyReceiptPacksMayBlockCapture,
    'localOnlyProofSaveMustStayAvailableBeforePacks':
        config.localOnlyAcceptanceGate.canSaveReceiptProof,
    'localOnlyBasicReviewMustStayAvailableBeforePacks':
        config.localOnlyAcceptanceGate.canOpenBasicLocalReview,
    'manualShutterAlwaysAvailable': settings.manualShutterAlwaysAvailable,
    'manualCapturePolicy': 'guidance_advisory_manual_shutter_always_allowed',
    'guidanceBlockingPolicy':
        'quality_guidance_warns_never_blocks_manual_capture',
    'manualCaptureBlockPolicy':
        'only_busy_closing_no_camera_or_inactive_surface',
    'closeCapturedPhotoPolicy': config.closeCapturedPhotoPolicy,
    'closeDuringCapturePolicy': config.closeDuringCapturePolicy,
    'closeNoPhotoPolicy': config.closeNoPhotoPolicy,
    'capturedPhotoReviewDestination': config.capturedPhotoReviewDestination,
    'autoCaptureEnabled': config.autoCaptureEnabled,
    'autoCaptureAllowed': config.autoCaptureAllowed,
    'autoCapturePolicy': config.autoCapturePolicy,
    'autoCaptureStableFrameTarget': config.autoCaptureStableFrameTarget,
    'autoCaptureMaxMotionScore': config.autoCaptureMaxMotionScore,
    'autoCaptureMinBrightness': config.autoCaptureMinBrightness,
    'autoCaptureMaxBrightness': config.autoCaptureMaxBrightness,
    'autoCaptureCooldownMs': config.autoCaptureCooldownMs,
    'assistedReceiptFill': settings.assistedReceiptFill,
    'reviewDepth': settings.reviewDepth.name,
    'longReceiptMode': settings.longReceiptMode,
    'tapFocusEnabled': false,
    'tapToFocusPolicy': config.tapToFocusPolicy,
    'focusStrategyPolicy': config.focusStrategyPolicy,
    'focusReadabilityFallbackPolicy': config.focusReadabilityFallbackPolicy,
    'readabilityGuidancePolicy': config.readabilityGuidancePolicy,
    'continuousFocusEnabled': config.continuousFocusEnabled,
    'receiptCameraQualityBaseline': settings.meetsReceiptCameraQualityBaseline,
    'pinchZoomEnabled': config.pinchZoomEnabled,
    'zoomGesturePolicy': config.zoomGesturePolicy,
    'exposureSliderEnabled': config.exposureSliderEnabled,
    'exposureResetEnabled': config.exposureResetEnabled,
    'autoExposureAssistEnabled': config.autoExposureAssistEnabled,
    'previewExposurePolicy': config.previewExposurePolicy,
    'preCaptureExposurePolicy': config.preCaptureExposurePolicy,
    'previewBrightnessGuardPolicy': config.previewBrightnessGuardPolicy,
    'shutterSpeedPolicy': config.shutterSpeedPolicy,
    'focusLockEnabled': false,
    'exposureLockEnabled': false,
    'whiteBalanceLockEnabled': false,
    'minZoom': config.minZoom,
    'maxZoom': config.maxZoom,
    'initialZoomRatio': config.initialZoomRatio,
    'minExposureOffset': config.minExposureOffset,
    'maxExposureOffset': config.maxExposureOffset,
    'focusMode': settings.focusMode.name,
    'exposureMode': settings.exposureMode.name,
    'whiteBalanceMode': settings.whiteBalanceMode.name,
    'flashMode': settings.flashMode.name,
    'preferMacroWhenHelpful': settings.preferMacroWhenHelpful,
    'imageFormat': settings.imageFormat.name,
    'liveAnalysisEnabled': config.liveAnalysisEnabled,
    'edgeDetectionEnabled': config.edgeDetectionEnabled,
    'edgeOverlayEnabled': config.edgeOverlayEnabled,
    'perspectiveCorrectionEnabled': config.perspectiveCorrectionEnabled,
    'motionBlurWarningEnabled': settings.motionBlurWarningEnabled,
    'glareWarningEnabled': settings.glareWarningEnabled,
    'dirtyLensWarningEnabled': settings.dirtyLensWarningEnabled,
    'lowLightWarningEnabled': settings.lowLightWarningEnabled,
    'shadowWarningEnabled': settings.shadowWarningEnabled,
    'tooFarTooCloseWarningEnabled': settings.tooFarTooCloseWarningEnabled,
    'receiptFullyVisibleWarningEnabled':
        settings.receiptFullyVisibleWarningEnabled,
    'textTooSmallWarningEnabled': settings.textTooSmallWarningEnabled,
    'previousSectionGhostGuideEnabled':
        settings.previousSectionGhostGuideEnabled,
    'manualCropAfterCapture': settings.manualCropAfterCapture,
    'autoCropSuggestionEnabled': config.autoCropSuggestionEnabled,
    'grayscalePreviewEnabled': config.grayscalePreviewEnabled,
    'contrastBoostEnabled': config.contrastBoostEnabled,
    'sharpeningEnabled': config.sharpeningEnabled,
    'shadowReductionEnabled': config.shadowReductionEnabled,
    'adaptiveThresholdEnabled': config.adaptiveThresholdEnabled,
    'orientationCorrectionEnabled': config.orientationCorrectionEnabled,
    'saveOriginalTemporarily': settings.saveOriginalTemporarily,
    'queueAcceptedCaptureLocally': settings.queueAcceptedCaptureLocally,
    'ocrUsesOriginalFirst': settings.ocrUsesOriginalFirst,
    'receiptPhotoBackupEnabled': settings.receiptPhotoBackupEnabled,
    'dataSaverLevel': settings.dataSaverLevel.name,
    'askSavedProofSizeEachReceipt': settings.askSavedProofSizeEachReceipt,
    'storageSafetyLevel': config.storageSafetyLevel.name,
    'storageConstrained': config.storageConstrained,
    'storageSafetyReason': config.storageSafetyReason,
    'cameraStorageBand': config.cameraStoragePolicy.band.name,
    'cameraStoragePolicyCode': config.cameraStoragePolicy.policyCode,
    'cameraStorageFreeMb': config.cameraStoragePolicy.freeStorageMb,
    'cameraStorageBelowSupportedFloor':
        config.cameraStoragePolicy.isBelowSupportedFloor,
    'cameraStorageCloudReliefRecommended':
        config.cameraStoragePolicy.cloudReliefRecommended,
    'cameraStorageCompletionPolicy':
        config.cameraStoragePolicy.completionPolicyCode,
    'cameraStorageNeverBlocksCompletion': config.storageCanNeverBlockCompletion,
    'receiptBackupConnectionLabel': 'Backup account not connected',
    'receiptBackupQuotaBytes': 0,
    'receiptBackupUsedBytes': 0,
    'workloadProtectionPolicy': config.workloadProtectionPolicy,
    'maxSectionCount': config.maxSectionCount,
    'analysisGapMs': config.analysisGapMs,
    'readyHoldMs': config.readyHoldMs,
    'assistedShotCount': config.assistedShotCount,
    'bestShotCandidateCount': config.bestShotCandidateCount,
    'cameraResolutionTier': config.cameraResolutionTier.name,
    'cameraWorkloadTier': config.cameraWorkloadTier.name,
    'maxLocalPhotoBytes': config.maxLocalPhotoBytes,
    'nativeCaptureMemoryPolicy': config.nativeCaptureMemoryPolicy,
    'maxLiveAnalysisPixels': config.maxLiveAnalysisPixels,
    'maxCleanupPixels': config.maxCleanupPixels,
    'maxStitchOutputPixels': config.maxStitchOutputPixels,
    'maxStitchOutputHeight': config.maxStitchOutputHeight,
    if (config.hasPreviousSectionGuide) ..._previousSectionArguments(config),
    if (config.hasNextSectionGuide) ..._nextSectionArguments(config),
  };
}

String _receiptCameraUiLocale() {
  final locale = PlatformDispatcher.instance.locale;
  final language = locale.languageCode.toLowerCase();
  final country = locale.countryCode?.toUpperCase();
  if (language == 'fr') return 'fr-CA';
  if (language == 'es') return 'es-US';
  return country == 'CA' ? 'en-CA' : 'en-US';
}

Map<String, Object?> _nextSectionArguments(
  ReceiptNativeCameraSessionConfig config,
) {
  return {
    'nextSectionGuidePhotoPath': config.nextSectionGuidePhotoPath,
    'nextSectionGhostGuidePolicy':
        'next_section_top_context_ghost_at_bottom_repeat_3_to_5_lines',
    'nextSectionGhostGuidePlacement': 'bottom_ghost_slice',
    'nextSectionGhostGuideMatchTarget': 'next_section_top_lines',
    'nextSectionGhostSourceStartFraction': 0.0,
    'nextSectionGhostSourceHeightFraction': 0.20,
    'nextSectionGhostOverlayTopFraction': 0.80,
    'nextSectionGhostOverlayHeightFraction': 0.20,
    'nextSectionGhostOpacity': 0.28,
  };
}

Map<String, Object?> _previousSectionArguments(
  ReceiptNativeCameraSessionConfig config,
) {
  return {
    'previousSectionGuidePhotoPath': config.previousSectionGuidePhotoPath,
    'previousSectionReasonCode': config.previousSectionGuideReasonCode,
    'previousSectionGhostGuidePolicy': config.previousSectionGhostGuidePolicy,
    'previousSectionGhostGuideUsesNextContext':
        config.previousSectionGuideUsesNextContext,
    'previousSectionGhostGuideRepeatLineTarget':
        config.previousSectionGhostGuideRepeatLineTarget,
    'previousSectionGhostGuidePlacement':
        config.previousSectionGhostGuidePlacement,
    'previousSectionGhostGuideMatchTarget':
        config.previousSectionGhostGuideMatchTarget,
    'previousSectionGhostSourceStartFraction':
        config.previousSectionGhostSourceStartFractionOrDefault,
    'previousSectionGhostSourceHeightFraction':
        config.previousSectionGhostSourceHeightFractionOrDefault,
    'previousSectionGhostOverlayTopFraction':
        config.previousSectionGhostOverlayTopFractionOrDefault,
    'previousSectionGhostOverlayHeightFraction':
        config.previousSectionGhostOverlayHeightFractionOrDefault,
    'previousSectionGhostOpacity': config.previousSectionGhostOpacityOrDefault,
    'previousSectionGhostSlicePercent': config.previousSectionGhostSlicePercent,
    'previousSectionGuidance': config.previousSectionGuideGuidance,
    'previousSectionMissingBottomAndTotals':
        config.previousSectionGuideMissingBottomAndTotals,
  };
}

Map<String, Object?> _nativeControlContract(
  ReceiptNativeCameraSessionConfig config,
) {
  return {
    'nativeCameraSurfaceContractVersion': 'receipt_native_surface_v1',
    'captureSurfaceExpected': _expectedCaptureSurface(config),
    'nativeCameraIdentityExpected': 'maintainiac_in_app_receipt_camera',
    'nativeCaptureUiContractExpected':
        'maintainiac_custom_receipt_capture_ui_v1',
    'nativePreviewOwnership': 'maintainiac_owns_preview_and_controls',
    'stockCameraUiAllowed': false,
    'stockCameraUiUsed': false,
    'stockCameraUiPolicy': 'blocked_as_primary_backup_path_labels_if_used',
    'phoneCameraBackupAllowed': true,
    'phoneCameraBackupRole': 'fallback_only',
    'nativeControlContractVersion': 'receipt_native_controls_v1',
    'controlDiagnosticsPrivacyScope': 'summary_only_no_receipt_content',
    'nativeControlContractTags': config.nativeControlContractTags,
    'manualCapturePolicy': 'guidance_advisory_manual_shutter_always_allowed',
    'guidanceBlockingPolicy':
        'quality_guidance_warns_never_blocks_manual_capture',
    'manualCaptureBlockPolicy':
        'only_busy_closing_no_camera_or_inactive_surface',
    'closeCapturedPhotoPolicy': config.closeCapturedPhotoPolicy,
    'closeDuringCapturePolicy': config.closeDuringCapturePolicy,
    'closeNoPhotoPolicy': config.closeNoPhotoPolicy,
    'capturedPhotoReviewDestination': config.capturedPhotoReviewDestination,
    'tapFocusControlExpected': false,
    'tapToFocusPolicy': config.tapToFocusPolicy,
    'continuousFocusExpected': config.continuousFocusEnabled,
    'focusStrategyPolicy': config.focusStrategyPolicy,
    'focusReadabilityFallbackPolicy': config.focusReadabilityFallbackPolicy,
    'pinchZoomControlExpected': config.pinchZoomEnabled,
    'zoomGesturePolicy': config.zoomGesturePolicy,
    'exposureSliderControlExpected': config.exposureSliderEnabled,
    'exposureResetControlExpected': config.exposureResetEnabled,
    'previewExposurePolicy': config.previewExposurePolicy,
    'preCaptureExposurePolicy': config.preCaptureExposurePolicy,
    'previewBrightnessGuardPolicy': config.previewBrightnessGuardPolicy,
    'shutterSpeedPolicy': config.shutterSpeedPolicy,
    'autoCapturePolicy': config.autoCapturePolicy,
    'autoCaptureStableFrameTarget': config.autoCaptureStableFrameTarget,
    'autoCaptureMaxMotionScore': config.autoCaptureMaxMotionScore,
    'autoCaptureMinBrightness': config.autoCaptureMinBrightness,
    'autoCaptureMaxBrightness': config.autoCaptureMaxBrightness,
    'autoCaptureCooldownMs': config.autoCaptureCooldownMs,
    'settingsControlExpected': true,
    'backControlExpected': true,
    'torchControlExpected': config.nativeCapabilities.supportsTorch,
    'focusLockControlExpected': false,
    'exposureLockControlExpected': false,
    'whiteBalanceLockControlExpected': false,
  };
}

String _expectedCaptureSurface(ReceiptNativeCameraSessionConfig config) {
  return switch (config.nativeCapabilities.engine) {
    ReceiptNativeCameraEngine.cameraX => 'maintainiac_native_android',
    ReceiptNativeCameraEngine.avFoundation => 'maintainiac_native_ios',
    ReceiptNativeCameraEngine.unavailable => 'maintainiac_native_unavailable',
  };
}

void _verifyMaintainiacReceiptSurface(
  ReceiptNativeCameraSessionConfig config,
  Map<String, Object?> nativeDiagnostics,
) {
  if (nativeDiagnostics['stockCameraUiUsed'] == true) {
    throw const ReceiptNativeCameraUnavailableException(
      'Maintainiac receipt camera cannot accept a stock camera UI capture.',
    );
  }
  final expectedSurface = _expectedCaptureSurface(config);
  final actualSurface = nativeDiagnostics['captureSurface']?.toString().trim();
  if (actualSurface != null &&
      actualSurface.isNotEmpty &&
      actualSurface != expectedSurface) {
    throw ReceiptNativeCameraUnavailableException(
      'Maintainiac receipt camera expected $expectedSurface but received $actualSurface.',
    );
  }
  final identity = nativeDiagnostics['nativeCameraIdentity']?.toString().trim();
  if (identity != null &&
      identity.isNotEmpty &&
      identity != 'maintainiac_in_app_receipt_camera') {
    throw ReceiptNativeCameraUnavailableException(
      'Maintainiac receipt camera expected the in-app receipt camera but received $identity.',
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is Iterable) {
    return value
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList(growable: false);
  }
  return const [];
}

List<String> _safeNativeCaptureIds(Object? value, int maxCount) {
  if (maxCount <= 0 || value is! Iterable) return const [];
  final safeIds = <String>[];
  for (final entry in value.take(maxCount)) {
    final safeId = _safeNativeCaptureId(entry.toString(), safeIds.length);
    if (safeId.isNotEmpty) safeIds.add(safeId);
  }
  return List.unmodifiable(safeIds);
}

String _safeNativeCaptureId(String value, int index) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final validNativeId = RegExp(
    r'^[A-Za-z0-9][A-Za-z0-9_-]{0,71}(\.[A-Za-z0-9]{1,8})?$',
  );
  if (validNativeId.hasMatch(trimmed)) return trimmed;
  return 'native_capture_${index + 1}';
}

String _platformCloseAction(Object? details) {
  if (details is Map) {
    final value = details['closeAction']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return 'unknown_cancel';
}
