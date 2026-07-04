part of 'expense_screen_telemetry.dart';

extension ExpenseTelemetryHealthSnapshotNativeCommandCenterMap
    on ExpenseTelemetryHealthSnapshot {
  Map<String, Object?> get nativeCameraCommandCenterMap {
    return {
      'nativeDevicePolicyCounts': nativeDevicePolicyCounts,
      'nativeCameraWorkloadTierCounts': nativeCameraWorkloadTierCounts,
      'nativeCameraResolutionTierCounts': nativeCameraResolutionTierCounts,
      'nativeRecoveryResumeStatusCounts': nativeRecoveryResumeStatusCounts,
      'nativeRecoveryFreshnessCounts': nativeRecoveryFreshnessCounts,
      'nativeRecoveryStorageStatusCounts': nativeRecoveryStorageStatusCounts,
      'nativeRecoveryRecoveredPhotoCount': nativeRecoveryRecoveredPhotoCount,
      'nativeRecoveryMultipleSectionCount': nativeRecoveryMultipleSectionCount,
      'nativePreCaptureExposureAbortCount': nativePreCaptureExposureAbortCount,
      'nativePreCaptureExposureAbortReasonCounts':
          nativePreCaptureExposureAbortReasonCounts,
      'nativeTapFocusControlExpectedCount': nativeTapFocusControlExpectedCount,
      'nativeContinuousFocusExpectedCount': nativeContinuousFocusExpectedCount,
      'nativePinchZoomControlExpectedCount':
          nativePinchZoomControlExpectedCount,
      'nativeExposureSliderControlExpectedCount':
          nativeExposureSliderControlExpectedCount,
      'nativeExposureResetControlExpectedCount':
          nativeExposureResetControlExpectedCount,
      'nativeSettingsControlExpectedCount': nativeSettingsControlExpectedCount,
      'nativeBackControlExpectedCount': nativeBackControlExpectedCount,
      'nativeTorchControlExpectedCount': nativeTorchControlExpectedCount,
      'nativeSettingsOpenCount': nativeSettingsOpenCount,
      'nativeZoomGestureStartCount': nativeZoomGestureStartCount,
      'nativeZoomChangeCount': nativeZoomChangeCount,
      'nativeZoomUnavailableCount': nativeZoomUnavailableCount,
      'nativeZoomStatusCounts': nativeZoomStatusCounts,
      'nativeBackDispatchPathCounts': nativeBackDispatchPathCounts,
      if (topNativeZoomStatus.isNotEmpty)
        'topNativeZoomStatus': topNativeZoomStatus,
      if (topNativePreCaptureExposureAbortReason.isNotEmpty)
        'topNativePreCaptureExposureAbortReason':
            topNativePreCaptureExposureAbortReason,
      if (topNativeBackDispatchPath.isNotEmpty)
        'topNativeBackDispatchPath': topNativeBackDispatchPath,
      if (topNativeCameraEngine.isNotEmpty)
        'topNativeCameraEngine': topNativeCameraEngine,
      if (topNativeReceiptCameraSurfaceActual.isNotEmpty)
        'topNativeReceiptCameraSurfaceActual':
            topNativeReceiptCameraSurfaceActual,
      if (topNativeReceiptCameraSurfaceVerification.isNotEmpty)
        'topNativeReceiptCameraSurfaceVerification':
            topNativeReceiptCameraSurfaceVerification,
      if (topNativeCameraIdentity.isNotEmpty)
        'topNativeCameraIdentity': topNativeCameraIdentity,
      if (topNativeSettingsContractVersion.isNotEmpty)
        'topNativeSettingsContractVersion': topNativeSettingsContractVersion,
      if (topNativeControlContractVersion.isNotEmpty)
        'topNativeControlContractVersion': topNativeControlContractVersion,
      if (topReceiptCloudAssistPlan.isNotEmpty)
        'topReceiptCloudAssistPlan': topReceiptCloudAssistPlan,
      if (topReceiptLocalOcrMode.isNotEmpty)
        'topReceiptLocalOcrMode': topReceiptLocalOcrMode,
      if (topReceiptParserDepth.isNotEmpty)
        'topReceiptParserDepth': topReceiptParserDepth,
      if (topReceiptParserPackCode.isNotEmpty)
        'topReceiptParserPackCode': topReceiptParserPackCode,
      if (topReceiptOptionalLocalParserPackCode.isNotEmpty)
        'topReceiptOptionalLocalParserPackCode':
            topReceiptOptionalLocalParserPackCode,
      if (topReceiptCloudFallbackParserPackCode.isNotEmpty)
        'topReceiptCloudFallbackParserPackCode':
            topReceiptCloudFallbackParserPackCode,
      if (topReceiptParserPackAccuracyBand.isNotEmpty)
        'topReceiptParserPackAccuracyBand': topReceiptParserPackAccuracyBand,
      if (topNativeDevicePolicy.isNotEmpty)
        'topNativeDevicePolicy': topNativeDevicePolicy,
      if (topNativeCameraWorkloadTier.isNotEmpty)
        'topNativeCameraWorkloadTier': topNativeCameraWorkloadTier,
      if (topNativeCameraResolutionTier.isNotEmpty)
        'topNativeCameraResolutionTier': topNativeCameraResolutionTier,
      if (topNativeRecoveryResumeStatus.isNotEmpty)
        'topNativeRecoveryResumeStatus': topNativeRecoveryResumeStatus,
      if (topNativeRecoveryFreshness.isNotEmpty)
        'topNativeRecoveryFreshness': topNativeRecoveryFreshness,
      if (topNativeRecoveryStorageStatus.isNotEmpty)
        'topNativeRecoveryStorageStatus': topNativeRecoveryStorageStatus,
      if (topNativeRecoveryAction.isNotEmpty)
        'topNativeRecoveryAction': topNativeRecoveryAction,
      'capabilityPolicyCodeCounts': capabilityPolicyCodeCounts,
      if (topCapabilityPolicyCode.isNotEmpty)
        'topCapabilityPolicyCode': topCapabilityPolicyCode,
      'nativeCaptureSourcePolicyCounts': nativeCaptureSourcePolicyCounts,
      if (topNativeCaptureSourcePolicy.isNotEmpty)
        'topNativeCaptureSourcePolicy': topNativeCaptureSourcePolicy,
      'stitchStatusCounts': stitchStatusCounts,
      'stitchFallbackReasonCounts': stitchFallbackReasonCounts,
      'stitchConfidenceBucketCounts': stitchConfidenceBucketCounts,
      'stitchPairDiagnosticCounts': stitchPairDiagnosticCounts,
      if (topStitchStatus.isNotEmpty) 'topStitchStatus': topStitchStatus,
      if (topStitchFallbackReason.isNotEmpty)
        'topStitchFallbackReason': topStitchFallbackReason,
      if (topStitchConfidenceBucket.isNotEmpty)
        'topStitchConfidenceBucket': topStitchConfidenceBucket,
      if (topStitchPairDiagnostic.isNotEmpty)
        'topStitchPairDiagnostic': topStitchPairDiagnostic,
    };
  }
}
