part of 'receipt_native_camera_contract.dart';

class ReceiptNativeCameraSessionConfig {
  const ReceiptNativeCameraSessionConfig({
    required this.settings,
    required this.nativeCapabilities,
    required this.deviceTier,
    required this.devicePolicyLabel,
    required this.capabilityPolicyCodes,
    required this.cloudAssistPlan,
    required this.installRecommendation,
    required this.receiptBrainRecommendation,
    required this.receiptBrainFootprintSummary,
    required this.parserPackRoutingPlan,
    required this.storageSafetyLevel,
    required this.storageConstrained,
    required this.autoCaptureAllowed,
    required this.liveAnalysisEnabled,
    required this.edgeDetectionEnabled,
    required this.autoCaptureEnabled,
    required this.maxSectionCount,
    required this.analysisGapMs,
    required this.readyHoldMs,
    required this.autoCaptureStableFrameTarget,
    required this.autoCaptureMaxMotionScore,
    required this.autoCaptureMinBrightness,
    required this.autoCaptureMaxBrightness,
    required this.autoCaptureCooldownMs,
    required this.assistedShotCount,
    required this.bestShotCandidateCount,
    required this.cameraResolutionTier,
    required this.cameraWorkloadTier,
    required this.maxLocalPhotoBytes,
    required this.tapFocusEnabled,
    required this.pinchZoomEnabled,
    required this.exposureSliderEnabled,
    required this.exposureResetEnabled,
    required this.autoExposureAssistEnabled,
    required this.continuousFocusEnabled,
    required this.focusLockEnabled,
    required this.exposureLockEnabled,
    required this.whiteBalanceLockEnabled,
    required this.minZoom,
    required this.maxZoom,
    required this.minExposureOffset,
    required this.maxExposureOffset,
    required this.maxLiveAnalysisPixels,
    required this.maxCleanupPixels,
    required this.maxStitchOutputPixels,
    required this.maxStitchOutputHeight,
    required this.edgeOverlayEnabled,
    required this.perspectiveCorrectionEnabled,
    required this.autoCropSuggestionEnabled,
    required this.contrastBoostEnabled,
    required this.sharpeningEnabled,
    required this.shadowReductionEnabled,
    required this.adaptiveThresholdEnabled,
    required this.grayscalePreviewEnabled,
    required this.orientationCorrectionEnabled,
    this.previousSectionGuidePhotoPath,
    this.previousSectionReasonCode,
    this.previousSectionGuidance,
    this.previousSectionGhostSourceStartFraction,
    this.previousSectionGhostSourceHeightFraction,
    this.previousSectionGhostOverlayTopFraction,
    this.previousSectionGhostOverlayHeightFraction,
    this.previousSectionGhostOpacity,
  });

  final ReceiptNativeCameraSettings settings;
  final ReceiptNativeCameraCapabilities nativeCapabilities;
  final ReceiptCapabilityTier deviceTier;
  final String devicePolicyLabel;
  final List<String> capabilityPolicyCodes;
  final ReceiptCloudAssistPlan cloudAssistPlan;
  final ReceiptFeatureInstallRecommendation installRecommendation;
  final ReceiptBrainDeploymentRecommendation receiptBrainRecommendation;
  final ReceiptBrainFootprintSummary receiptBrainFootprintSummary;
  final ReceiptParserPackRoutingPlan parserPackRoutingPlan;
  final ReceiptDataSaverLevel storageSafetyLevel;
  final bool storageConstrained;
  final bool autoCaptureAllowed;
  final bool liveAnalysisEnabled;
  final bool edgeDetectionEnabled;
  final bool autoCaptureEnabled;
  final int maxSectionCount;
  final int analysisGapMs;
  final int readyHoldMs;
  final int autoCaptureStableFrameTarget;
  final double autoCaptureMaxMotionScore;
  final double autoCaptureMinBrightness;
  final double autoCaptureMaxBrightness;
  final int autoCaptureCooldownMs;
  final int assistedShotCount;
  final int bestShotCandidateCount;
  final ReceiptCameraResolutionTier cameraResolutionTier;
  final ReceiptCameraWorkloadTier cameraWorkloadTier;
  final int maxLocalPhotoBytes;
  final bool tapFocusEnabled;
  final bool pinchZoomEnabled;
  final bool exposureSliderEnabled;
  final bool exposureResetEnabled;
  final bool autoExposureAssistEnabled;
  final bool continuousFocusEnabled;
  final bool focusLockEnabled;
  final bool exposureLockEnabled;
  final bool whiteBalanceLockEnabled;
  final double minZoom;
  final double maxZoom;
  final double minExposureOffset;
  final double maxExposureOffset;
  final int maxLiveAnalysisPixels;
  final int maxCleanupPixels;
  final int maxStitchOutputPixels;
  final int maxStitchOutputHeight;
  final bool edgeOverlayEnabled;
  final bool perspectiveCorrectionEnabled;
  final bool autoCropSuggestionEnabled;
  final bool contrastBoostEnabled;
  final bool sharpeningEnabled;
  final bool shadowReductionEnabled;
  final bool adaptiveThresholdEnabled;
  final bool grayscalePreviewEnabled;
  final bool orientationCorrectionEnabled;
  final String? previousSectionGuidePhotoPath;
  final String? previousSectionReasonCode;
  final String? previousSectionGuidance;
  final double? previousSectionGhostSourceStartFraction;
  final double? previousSectionGhostSourceHeightFraction;
  final double? previousSectionGhostOverlayTopFraction;
  final double? previousSectionGhostOverlayHeightFraction;
  final double? previousSectionGhostOpacity;

  bool get manualCaptureAvailable => settings.manualShutterAlwaysAvailable;
  bool get interruptionSafe => settings.protectsInterruptedCapture;
  bool get ocrSourceProtected => settings.ocrUsesOriginalFirst;
  String get closeCapturedPhotoPolicy {
    return 'back_returns_captured_sections_before_cancel';
  }

  String get closeDuringCapturePolicy {
    return 'wait_for_in_flight_capture_then_return_review';
  }

  String get closeNoPhotoPolicy {
    return 'back_without_photo_cancels_without_creating_expense';
  }

  String get capturedPhotoReviewDestination {
    return 'receipt_photo_review_then_receipt_details';
  }

  String get nativeCaptureMemoryPolicy {
    if (storageSafetyLevel == ReceiptDataSaverLevel.maximum) {
      return 'tiny_local_proof_original_for_ocr_then_cleanup';
    }
    if (storageConstrained) {
      return 'small_local_proof_original_for_ocr_then_cleanup';
    }
    if (deviceTier == ReceiptCapabilityTier.light) {
      return 'older_phone_bounded_original_for_ocr_then_cleanup';
    }
    return 'bounded_original_for_ocr_then_cleanup';
  }

  String get storageSafetyReason {
    if (!storageConstrained) return 'normal';
    return storageSafetyLevel == ReceiptDataSaverLevel.maximum
        ? 'tight_storage_tiny_proofs'
        : 'low_storage_small_proofs';
  }

  ReceiptLocalOnlyAcceptanceGate get localOnlyAcceptanceGate {
    return receiptBrainFootprintSummary.localOnlyAcceptanceGate;
  }

  String get localOnlyCapturePolicy {
    final gate = localOnlyAcceptanceGate;
    if (gate.baseFlowCanRunLocallyNow) {
      return gate.optionalPacksDeferredBeforeCapture
          ? 'capture_save_basic_review_now_optional_packs_later'
          : 'capture_save_basic_review_now_base_only';
    }
    if (gate.requiresHeavyOfflinePackBeforeCapture) {
      return 'blocked_heavy_pack_required_before_capture';
    }
    if (gate.requiresCloudAssistBeforeCapture) {
      return 'blocked_cloud_required_before_capture';
    }
    return 'blocked_base_receipt_flow_incomplete';
  }

  bool get heavyReceiptPacksMayBlockCapture {
    return !localOnlyAcceptanceGate.baseFlowCanRunLocallyNow ||
        localOnlyAcceptanceGate.requiresHeavyOfflinePackBeforeCapture;
  }

  bool get cloudAssistMayBlockCapture {
    return !localOnlyAcceptanceGate.baseFlowCanRunLocallyNow ||
        localOnlyAcceptanceGate.requiresCloudAssistBeforeCapture;
  }

  String get workloadProtectionPolicy {
    if (storageSafetyLevel == ReceiptDataSaverLevel.maximum) {
      return 'maximum_storage_saver_light_workload';
    }
    if (storageConstrained) {
      return 'storage_saver_light_workload';
    }
    if (deviceTier == ReceiptCapabilityTier.light) {
      return 'older_phone_light_workload';
    }
    if (cameraWorkloadTier == ReceiptCameraWorkloadTier.flagship) {
      return 'flagship_full_workload';
    }
    return 'balanced_workload';
  }

  String get previewExposurePolicy {
    if (!exposureSliderEnabled) return 'native_auto_metering_no_manual_slider';
    if (autoExposureAssistEnabled) {
      return 'receipt_paper_metering_safe_auto_lift_manual_slider';
    }
    return 'receipt_paper_metering_manual_slider';
  }

  String get preCaptureExposurePolicy {
    if (!exposureSliderEnabled) return 'native_auto_metering_no_manual_slider';
    if (autoExposureAssistEnabled) {
      return 'receipt_paper_metering_dim_rescue_v2_manual_slider';
    }
    return 'receipt_paper_metering_manual_slider';
  }

  String get previewBrightnessGuardPolicy {
    if (deviceTier == ReceiptCapabilityTier.light || storageConstrained) {
      return 'avoid_dark_preview_lightweight_sampling';
    }
    return 'avoid_dark_preview_full_receipt_sampling';
  }

  String get shutterSpeedPolicy {
    if (autoCaptureEnabled) {
      return 'prefer_fast_document_shutter_auto_capture_when_stable';
    }
    return 'prefer_fast_document_shutter_manual_capture_anytime';
  }

  String get tapToFocusPolicy {
    return 'continuous_focus_primary_no_tap_focus';
  }

  String get focusStrategyPolicy {
    if (settings.usesContinuousFocusPrimary && continuousFocusEnabled) {
      return 'continuous_focus_primary_no_tap_assist';
    }
    if (settings.usesContinuousFocusPrimary) {
      return 'continuous_focus_unavailable_readability_review_required';
    }
    return 'non_continuous_focus_requires_device_review';
  }

  String get readabilityGuidancePolicy {
    if (liveAnalysisEnabled && settings.hasReceiptReadabilityGuidance) {
      return 'live_readability_guides_blur_glare_light_edges_and_text_size';
    }
    return 'saved_photo_readability_review_required';
  }

  String get zoomGesturePolicy {
    if (!pinchZoomEnabled) return 'pinch_zoom_unavailable_keep_native_scale';
    return 'pinch_zoom_receipt_preview_${minZoom.toStringAsFixed(1)}_to_${maxZoom.toStringAsFixed(1)}';
  }

  List<String> get nativeControlContractTags {
    final tags = <String>[
      'settings',
      'back',
      'manual_shutter',
      'review_next',
      'receipt_guidance',
      'safe_close',
    ];
    if (pinchZoomEnabled) tags.add('pinch_zoom');
    if (exposureSliderEnabled) tags.add('brightness_slider');
    if (exposureResetEnabled) tags.add('brightness_reset');
    if (autoExposureAssistEnabled) tags.add('auto_brightness_assist');
    if (continuousFocusEnabled &&
        readabilityGuidancePolicy ==
            'live_readability_guides_blur_glare_light_edges_and_text_size') {
      tags.add('readability_guidance');
    }
    if (continuousFocusEnabled) {
      tags.add('continuous_focus');
    } else {
      tags.add('focus_readability_review');
    }
    if (focusLockEnabled) tags.add('focus_lock');
    if (exposureLockEnabled) tags.add('brightness_lock');
    if (whiteBalanceLockEnabled) tags.add('white_balance_lock');
    if (nativeCapabilities.supportsTorch) tags.add('receipt_light');
    if (edgeOverlayEnabled) tags.add('edge_overlay');
    if (hasPreviousSectionGuide) tags.add('previous_section_ghost');
    return List.unmodifiable(tags);
  }

  String get autoCapturePolicy {
    if (!settings.autoCaptureEnabled) {
      return 'off_by_default_manual_shutter_primary';
    }
    if (!autoCaptureAllowed) {
      return 'requested_but_blocked_manual_shutter_primary';
    }
    return 'optional_after_${autoCaptureStableFrameTarget}_steady_edge_light_frames';
  }
}
