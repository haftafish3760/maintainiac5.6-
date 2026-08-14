part of 'receipt_assistance_policy.dart';

class ReceiptCameraRuntimeProfile {
  const ReceiptCameraRuntimeProfile({
    required this.tier,
    required this.liveGuidanceEnabled,
    required this.startAssistedEnabled,
    required this.autoCaptureEnabled,
    required this.longReceiptTipsEnabled,
    required this.resolutionTier,
    required this.assistedShotCount,
    required this.liveAnalysisGapMs,
    required this.readyHoldMs,
    required this.dataSaverLevel,
    this.notes = const [],
  });

  final ReceiptCapabilityTier tier;
  final bool liveGuidanceEnabled;
  final bool startAssistedEnabled;
  final bool autoCaptureEnabled;
  final bool longReceiptTipsEnabled;
  final ReceiptCameraResolutionTier resolutionTier;
  final int assistedShotCount;
  final int liveAnalysisGapMs;
  final int readyHoldMs;
  final ReceiptDataSaverLevel dataSaverLevel;
  final List<String> notes;

  String get modeLabel {
    if (autoCaptureEnabled) return 'Guided auto capture';
    if (startAssistedEnabled) return 'Guided manual capture';
    if (liveGuidanceEnabled) return 'Manual capture with guidance';
    return 'Manual capture';
  }

  String get summaryLabel {
    return '$modeLabel, ${resolutionTier.label.toLowerCase()} receipt camera, ${dataSaverLevel.shortLabel.toLowerCase()} saved proof.';
  }

  String get notesLabel {
    if (notes.isEmpty) {
      return 'Maintainiac is using the safest receipt camera behavior for this phone.';
    }
    return notes.join(' ');
  }
}

class ReceiptStitchDeviceLimits {
  const ReceiptStitchDeviceLimits({
    required this.maxOutputPixels,
    required this.maxOutputHeight,
    required this.maxTargetWidth,
    required this.comparisonWidth,
    required this.retryComparisonWidth,
    required this.evidenceTimeout,
    required this.nativeRegistrationAllowance,
    required this.totalPreviewTimeout,
    required this.processingTimeout,
  });

  final int maxOutputPixels;
  final int maxOutputHeight;
  final int maxTargetWidth;
  final int comparisonWidth;
  final int retryComparisonWidth;
  final Duration evidenceTimeout;
  final Duration nativeRegistrationAllowance;
  final Duration totalPreviewTimeout;
  final Duration processingTimeout;

  String get label {
    return '${(maxOutputPixels / 1000000).toStringAsFixed(1)} MP, max height $maxOutputHeight px';
  }
}
