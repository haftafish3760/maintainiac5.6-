part of 'receipt_native_camera_contract.dart';

class ReceiptNativeCameraSettings {
  const ReceiptNativeCameraSettings({
    this.assistedReceiptFill = true,
    this.reviewDepth = ReceiptNativeReviewDepth.pricesOnly,
    this.longReceiptMode = true,
    this.manualShutterAlwaysAvailable = true,
    this.autoCaptureEnabled = false,
    this.tapFocusEnabled = true,
    this.pinchZoomEnabled = true,
    this.exposureSliderEnabled = true,
    this.exposureResetEnabled = true,
    this.autoExposureAssistEnabled = true,
    this.focusMode = ReceiptNativeFocusMode.continuous,
    this.exposureMode = ReceiptNativeExposureMode.auto,
    this.whiteBalanceMode = ReceiptNativeWhiteBalanceMode.auto,
    this.flashMode = ReceiptNativeFlashMode.off,
    this.preferMacroWhenHelpful = true,
    this.imageFormat = ReceiptNativeImageFormat.jpeg,
    this.liveYuvAnalysisEnabled = true,
    this.edgeDetectionEnabled = true,
    this.edgeOverlayEnabled = true,
    this.perspectiveCorrectionEnabled = true,
    this.motionBlurWarningEnabled = true,
    this.glareWarningEnabled = true,
    this.dirtyLensWarningEnabled = true,
    this.lowLightWarningEnabled = true,
    this.shadowWarningEnabled = true,
    this.tooFarTooCloseWarningEnabled = true,
    this.receiptFullyVisibleWarningEnabled = true,
    this.textTooSmallWarningEnabled = true,
    this.previousSectionGhostGuideEnabled = true,
    this.manualCropAfterCapture = true,
    this.autoCropSuggestionEnabled = true,
    this.grayscalePreviewEnabled = true,
    this.contrastBoostEnabled = true,
    this.sharpeningEnabled = true,
    this.shadowReductionEnabled = true,
    this.adaptiveThresholdEnabled = true,
    this.orientationCorrectionEnabled = true,
    this.saveOriginalTemporarily = true,
    this.queueAcceptedCaptureLocally = true,
    this.ocrUsesOriginalFirst = true,
    this.dataSaverLevel = ReceiptDataSaverLevel.balanced,
  });

  final bool assistedReceiptFill;
  final ReceiptNativeReviewDepth reviewDepth;
  final bool longReceiptMode;
  final bool manualShutterAlwaysAvailable;
  final bool autoCaptureEnabled;
  final bool tapFocusEnabled;
  final bool pinchZoomEnabled;
  final bool exposureSliderEnabled;
  final bool exposureResetEnabled;
  final bool autoExposureAssistEnabled;
  final ReceiptNativeFocusMode focusMode;
  final ReceiptNativeExposureMode exposureMode;
  final ReceiptNativeWhiteBalanceMode whiteBalanceMode;
  final ReceiptNativeFlashMode flashMode;
  final bool preferMacroWhenHelpful;
  final ReceiptNativeImageFormat imageFormat;
  final bool liveYuvAnalysisEnabled;
  final bool edgeDetectionEnabled;
  final bool edgeOverlayEnabled;
  final bool perspectiveCorrectionEnabled;
  final bool motionBlurWarningEnabled;
  final bool glareWarningEnabled;
  final bool dirtyLensWarningEnabled;
  final bool lowLightWarningEnabled;
  final bool shadowWarningEnabled;
  final bool tooFarTooCloseWarningEnabled;
  final bool receiptFullyVisibleWarningEnabled;
  final bool textTooSmallWarningEnabled;
  final bool previousSectionGhostGuideEnabled;
  final bool manualCropAfterCapture;
  final bool autoCropSuggestionEnabled;
  final bool grayscalePreviewEnabled;
  final bool contrastBoostEnabled;
  final bool sharpeningEnabled;
  final bool shadowReductionEnabled;
  final bool adaptiveThresholdEnabled;
  final bool orientationCorrectionEnabled;
  final bool saveOriginalTemporarily;
  final bool queueAcceptedCaptureLocally;
  final bool ocrUsesOriginalFirst;
  final ReceiptDataSaverLevel dataSaverLevel;

  bool get usesContinuousFocusPrimary =>
      focusMode == ReceiptNativeFocusMode.continuous;

  bool get tapFocusIsAssistOnly =>
      tapFocusEnabled && usesContinuousFocusPrimary;

  bool get hasExposureAndSharpnessGuidance =>
      autoExposureAssistEnabled &&
      exposureSliderEnabled &&
      exposureResetEnabled &&
      motionBlurWarningEnabled &&
      lowLightWarningEnabled &&
      glareWarningEnabled;

  bool get hasReceiptReadabilityGuidance =>
      liveYuvAnalysisEnabled &&
      edgeDetectionEnabled &&
      motionBlurWarningEnabled &&
      glareWarningEnabled &&
      lowLightWarningEnabled &&
      shadowWarningEnabled &&
      tooFarTooCloseWarningEnabled &&
      receiptFullyVisibleWarningEnabled &&
      textTooSmallWarningEnabled;

  String get receiptFocusStrategyCode {
    if (usesContinuousFocusPrimary && tapFocusIsAssistOnly) {
      return 'continuous_focus_primary_tap_assist_optional';
    }
    if (usesContinuousFocusPrimary) {
      return 'continuous_focus_primary_no_tap_assist';
    }
    return 'non_continuous_focus_requires_device_review';
  }

  bool get meetsReceiptCameraQualityBaseline =>
      usesContinuousFocusPrimary &&
      hasExposureAndSharpnessGuidance &&
      hasReceiptReadabilityGuidance;

  static List<ReceiptNativeCameraSettingDescriptor> get descriptors =>
      _receiptNativeCameraSettingDescriptors;
}
