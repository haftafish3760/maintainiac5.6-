part of 'receipt_native_camera_contract.dart';

double? _boundedNativeCameraFraction(double? value) {
  if (value == null || value.isNaN || value.isInfinite) return null;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

List<String> _nativeCameraCapabilityPolicyCodes({
  required bool lightDevice,
  required bool storageConstrained,
  required ReceiptNativeCameraCapabilities nativeCapabilities,
  required bool autoCaptureAllowed,
  required bool liveAnalysisAllowed,
  required bool effectiveEdgeDetection,
  required bool effectiveTapFocus,
  required bool effectivePinchZoom,
  required bool effectiveExposureSlider,
  required bool effectiveExposureAssist,
  required bool effectiveContinuousFocus,
  required bool heavyCleanupAllowed,
  required bool longReceiptMode,
}) {
  final codes = <String>[
    if (!longReceiptMode) 'long_receipt_mode_disabled',
    if (lightDevice) 'light_device_reduced_live_work',
    if (storageConstrained) 'storage_constrained_small_proofs',
    if (!nativeCapabilities.supportsNativeEdgeSignals)
      'native_edge_signals_unavailable',
    if (!autoCaptureAllowed) 'auto_capture_policy_disabled',
    if (!liveAnalysisAllowed) 'live_analysis_policy_disabled',
    if (!effectiveEdgeDetection) 'edge_detection_policy_disabled',
    if (!effectiveTapFocus) 'tap_focus_retired_continuous_focus_primary',
    if (!effectivePinchZoom) 'pinch_zoom_unavailable',
    if (!effectiveExposureSlider) 'exposure_slider_unavailable',
    if (!effectiveExposureAssist) 'auto_exposure_assist_unavailable',
    if (!effectiveContinuousFocus) 'continuous_focus_unavailable',
    if (!heavyCleanupAllowed) 'heavy_cleanup_policy_limited',
  ];
  if (codes.isEmpty) return const ['full_camera_assist_available'];
  return List.unmodifiable(codes);
}

String _nativeCameraDevicePolicyLabel({
  required ReceiptCapabilityTier tier,
  required bool storageConstrained,
}) {
  if (storageConstrained) return 'storage_saver_receipt_camera';
  return switch (tier) {
    ReceiptCapabilityTier.light => 'older_phone_safe_receipt_camera',
    ReceiptCapabilityTier.medium => 'balanced_receipt_camera',
    ReceiptCapabilityTier.heavyweight => 'flagship_receipt_camera',
  };
}

ReceiptDataSaverLevel _strongerNativeCameraDataSaverLevel(
  ReceiptDataSaverLevel selected,
  ReceiptDataSaverLevel recommended,
) {
  return _nativeCameraDataSaverRank(recommended) >
          _nativeCameraDataSaverRank(selected)
      ? recommended
      : selected;
}

int _nativeCameraDataSaverRank(ReceiptDataSaverLevel level) {
  return switch (level) {
    ReceiptDataSaverLevel.original => 0,
    ReceiptDataSaverLevel.light => 1,
    ReceiptDataSaverLevel.balanced => 2,
    ReceiptDataSaverLevel.strong => 3,
    ReceiptDataSaverLevel.maximum => 4,
  };
}

ReceiptDeviceStorageClass _nativeCameraInstallStorageClassFor(
  ReceiptDataSaverLevel storageSafetyLevel,
) {
  return switch (storageSafetyLevel) {
    ReceiptDataSaverLevel.maximum => ReceiptDeviceStorageClass.critical,
    ReceiptDataSaverLevel.strong => ReceiptDeviceStorageClass.low,
    ReceiptDataSaverLevel.original ||
    ReceiptDataSaverLevel.light ||
    ReceiptDataSaverLevel.balanced => ReceiptDeviceStorageClass.comfortable,
  };
}

int _nativeCameraSectionLimitForStorage(
  int deviceSectionLimit,
  ReceiptDataSaverLevel storageSafetyLevel,
) {
  final safeDeviceLimit = deviceSectionLimit <= 0 ? 1 : deviceSectionLimit;
  final storageLimit = switch (storageSafetyLevel) {
    ReceiptDataSaverLevel.maximum => 4,
    ReceiptDataSaverLevel.strong => 6,
    ReceiptDataSaverLevel.original ||
    ReceiptDataSaverLevel.light ||
    ReceiptDataSaverLevel.balanced => safeDeviceLimit,
  };
  return safeDeviceLimit < storageLimit ? safeDeviceLimit : storageLimit;
}
