part of 'receipt_assistance_policy.dart';

extension ReceiptDeviceCapabilityCamera on ReceiptDeviceCapability {
  ReceiptCameraWorkloadTier get cameraWorkloadTier {
    return workloadTier;
  }

  int get maxLiveAnalysisPixels => cameraWorkloadTier.maxLiveAnalysisPixels;

  int get maxCleanupPixels {
    final cleanupPixels = cameraWorkloadTier.maxCleanupPixels;
    final stitchPixels = stitchLimits.maxOutputPixels;
    return cleanupPixels < stitchPixels ? cleanupPixels : stitchPixels;
  }

  String get cameraWorkloadLabel => cameraWorkloadTier.label;

  ReceiptStitchDeviceLimits get stitchLimits {
    return switch (tier) {
      ReceiptCapabilityTier.light => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 9000000,
        maxOutputHeight: 14000,
        maxTargetWidth: 900,
        comparisonWidth: 320,
        retryComparisonWidth: 280,
        evidenceTimeout: Duration(seconds: 2),
        nativeRegistrationAllowance: Duration(milliseconds: 1200),
        totalPreviewTimeout: Duration(milliseconds: 8500),
        processingTimeout: Duration(milliseconds: 5300),
      ),
      ReceiptCapabilityTier.medium => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 14000000,
        maxOutputHeight: 18000,
        maxTargetWidth: 1200,
        comparisonWidth: 360,
        retryComparisonWidth: 280,
        evidenceTimeout: Duration(milliseconds: 2500),
        nativeRegistrationAllowance: Duration(milliseconds: 1600),
        totalPreviewTimeout: Duration(seconds: 9),
        processingTimeout: Duration(milliseconds: 4900),
      ),
      ReceiptCapabilityTier.heavyweight => const ReceiptStitchDeviceLimits(
        maxOutputPixels: 18000000,
        maxOutputHeight: 24000,
        // A 1240 px proof remains OCR-readable while avoiding the nonlinear
        // transform and JPEG cost that made flagship previews miss the
        // interaction deadline. It retains a quality step above the standard
        // tier, and originals remain untouched at full quality.
        maxTargetWidth: 1240,
        comparisonWidth: 400,
        retryComparisonWidth: 320,
        evidenceTimeout: Duration(seconds: 3),
        nativeRegistrationAllowance: Duration(milliseconds: 2200),
        // Leave enough time to encode a validated full-resolution composite
        // after registration while still keeping the complete preview under
        // the ten-second interaction ceiling.
        totalPreviewTimeout: Duration(milliseconds: 9800),
        processingTimeout: Duration(seconds: 8),
      ),
    };
  }

  ReceiptCameraRuntimeProfile cameraRuntimeProfileFor({
    required bool guidanceRequested,
    required bool startAssistedRequested,
    required bool autoCaptureRequested,
    required bool longReceiptTipsRequested,
  }) {
    final supportsGuidance = guidanceRequested;
    final supportsAssisted = switch (tier) {
      ReceiptCapabilityTier.light => false,
      ReceiptCapabilityTier.medium => startAssistedRequested,
      ReceiptCapabilityTier.heavyweight => startAssistedRequested,
    };
    final supportsAutoCapture = switch (tier) {
      ReceiptCapabilityTier.light => false,
      ReceiptCapabilityTier.medium => false,
      ReceiptCapabilityTier.heavyweight => autoCaptureRequested,
    };
    final effectiveStartAssisted = supportsGuidance && supportsAssisted;
    final effectiveAutoCapture = effectiveStartAssisted && supportsAutoCapture;
    final notes = <String>[
      if (!guidanceRequested) 'Live receipt guidance is off.',
      if (tier == ReceiptCapabilityTier.light && startAssistedRequested)
        'This device uses manual capture first to keep the camera responsive.',
      if (tier != ReceiptCapabilityTier.heavyweight && autoCaptureRequested)
        'Auto capture is held back on this device; tap the shutter when ready.',
      if (recommendedDataSaverLevel == ReceiptDataSaverLevel.maximum)
        'Storage is tight, so saved receipt proof copies use stronger space saving.',
    ];
    return ReceiptCameraRuntimeProfile(
      tier: tier,
      liveGuidanceEnabled: supportsGuidance,
      startAssistedEnabled: effectiveStartAssisted,
      autoCaptureEnabled: effectiveAutoCapture,
      longReceiptTipsEnabled: longReceiptTipsRequested,
      resolutionTier: cameraResolutionTier,
      assistedShotCount: assistedCameraShotCount,
      liveAnalysisGapMs: liveAnalysisGapMs,
      readyHoldMs: readyHoldMs,
      dataSaverLevel: recommendedDataSaverLevel,
      notes: notes,
    );
  }
}
