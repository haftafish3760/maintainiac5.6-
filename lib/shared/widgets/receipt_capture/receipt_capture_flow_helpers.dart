part of 'receipt_capture_flow.dart';

ReceiptNativeCameraSettings _cameraSettingsFor(
  ReceiptCaptureSettingsController? settings,
  ReceiptCaptureFlowOptions options,
) {
  final area = options.module.settingsArea;
  return receiptNativeCameraSettingsForCapture(
    settings: settings,
    assistedReceiptFill:
        options.forceAssistedReceiptFill ??
        (area == null ? false : settings?.appAssistedEnabledFor(area) ?? false),
    longReceiptMode: options.forceLongReceiptMode ?? false,
    autoCaptureEnabled:
        options.forceAutoCapture ?? settings?.cameraAutoCapture ?? false,
    reviewDepth: options.effectiveReviewDepth,
    dataSaverLevel:
        options.initialDataSaverLevel ??
        settings?.defaultDataSaverLevel ??
        ReceiptDataSaverLevel.balanced,
  );
}

ReceiptDataSaverLevel _stagedDataSaverLevelFor(
  ReceiptNativeCaptureResult capture, {
  required ReceiptCaptureFlowOptions options,
  required ReceiptCaptureSettingsController? settings,
}) {
  final nativeName = capture.captureDiagnostics['dataSaverLevel']
      ?.toString()
      .trim();
  for (final level in ReceiptDataSaverLevel.values) {
    if (level.name == nativeName) return level;
  }
  return options.initialDataSaverLevel ??
      settings?.defaultDataSaverLevel ??
      ReceiptDataSaverLevel.balanced;
}

Map<String, Map<String, Object?>> _withReviewOpeningDiagnostics(
  Map<String, Map<String, Object?>> diagnosticsByPath, {
  required String route,
  required String source,
  required int photoCount,
  required ReceiptCaptureFlowOptions options,
}) {
  return Map<String, Map<String, Object?>>.unmodifiable({
    for (final entry in diagnosticsByPath.entries)
      entry.key: Map<String, Object?>.unmodifiable({
        ...entry.value,
        'receiptReviewOpeningRoute': route,
        'receiptReviewOpeningSource': source,
        'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
        'maintainiacCustomCameraPrimary': true,
        'stockCameraUiAllowedAsPrimary': false,
        'phoneCameraBackupRole': 'fallback_only',
        'receiptReviewOpeningPolicy':
            'open_photo_review_before_ocr_or_receipt_form',
        'receiptReviewOpeningExpectedFirstAction':
            'next_or_add_photo_visible_before_scroll',
        'receiptReviewOpeningNextScreen':
            'receipt_details_store_date_total_tax_items',
        'receiptReviewOpeningPhotoCount': photoCount,
        ..._previousSectionGuideDiagnostics(options),
      }),
  });
}

Map<String, Object?> _diagnostics({
  required String stage,
  required String reason,
  required String action,
  required ReceiptNativeCameraCapabilities nativeCapabilities,
  required ReceiptCaptureFlowOptions options,
  Map<String, Object?> extraMetadata = const {},
}) {
  return Map<String, Object?>.unmodifiable({
    'captureFlow': 'maintainiac_shared_receipt_camera',
    'primaryCaptureFlow': 'maintainiac_native_receipt_camera',
    'maintainiacCustomCameraPrimary': true,
    'stockCameraUiAllowedAsPrimary': false,
    'phoneCameraBackupAllowed': true,
    'phoneCameraBackupRole': 'fallback_only',
    'fallbackCaptureRequiresUserAction': true,
    'receiptCaptureModule': options.module.storageName,
    'nativeCaptureFailureStage': stage,
    'nativeCaptureFailureReason': reason,
    'nativeCaptureRecoveryAction': action,
    'nativeCameraEngine': nativeCapabilities.engine.name,
    'nativeCameraAvailable': nativeCapabilities.available,
    'nativeCameraPermissionGranted': nativeCapabilities.cameraPermissionGranted,
    'nativeCameraHasRearCamera': nativeCapabilities.hasRearCamera,
    ..._previousSectionGuideDiagnostics(options),
    ...extraMetadata,
  });
}

Map<String, Object?> _previousSectionGuideDiagnostics(
  ReceiptCaptureFlowOptions options,
) {
  final reason = _trimmedOrNull(
    options.previousSectionReasonCode,
  )?.toLowerCase();
  final guidePhotoPath = receiptNativeCameraLocalImagePathOrNull(
    options.previousSectionGuidePhotoPath,
  );
  final guidance = _trimmedOrNull(options.previousSectionGuidance);
  final ghostSourceStartFraction = _boundedPreviousSectionGhostFraction(
    options.previousSectionGhostSourceStartFraction,
  );
  final ghostSourceHeightFraction = _boundedPreviousSectionGhostFraction(
    options.previousSectionGhostSourceHeightFraction,
  );
  final ghostOverlayTopFraction = _boundedPreviousSectionGhostFraction(
    options.previousSectionGhostOverlayTopFraction,
  );
  final ghostOverlayHeightFraction = _boundedPreviousSectionGhostFraction(
    options.previousSectionGhostOverlayHeightFraction,
  );
  final ghostOpacity = _boundedPreviousSectionGhostFraction(
    options.previousSectionGhostOpacity,
  );
  final missingBottomAndTotals = reason == 'missing_bottom_edge_and_totals';
  return Map<String, Object?>.unmodifiable({
    'previousSectionGuideRequested': reason != null || guidePhotoPath != null,
    'previousSectionGuidePhotoAvailable': guidePhotoPath != null,
    'previousSectionReasonCode': reason ?? 'none',
    'previousSectionMissingBottomAndTotals': missingBottomAndTotals,
    'previousSectionGuidanceAvailable': guidance != null,
    'previousSectionGhostSourceStartFraction': ghostSourceStartFraction,
    'previousSectionGhostSourceHeightFraction': ghostSourceHeightFraction,
    'previousSectionGhostOverlayTopFraction': ghostOverlayTopFraction,
    'previousSectionGhostOverlayHeightFraction': ghostOverlayHeightFraction,
    'previousSectionGhostOpacity': ghostOpacity,
    'previousSectionGhostSlicePercent': (ghostSourceHeightFraction * 100)
        .round(),
    'receiptContinuationSource': missingBottomAndTotals
        ? 'ocr_missing_bottom_totals'
        : reason == null
        ? 'none'
        : 'review_continuation',
    'receiptContinuationGhostGuideStatus': reason == null
        ? 'not_requested'
        : guidePhotoPath == null
        ? 'reason_without_prior_photo'
        : 'ready_with_previous_photo',
  });
}

double _boundedPreviousSectionGhostFraction(double? value) {
  if (value == null || !value.isFinite) return 0;
  if (value < 0) return 0;
  if (value > 1) return 1;
  return value;
}

ReceiptPhotoQualityCheck? _qualityForOcrSourceIndex(
  ReceiptPhotoReviewResult result,
  int index,
) {
  if (result.ocrSourcePhotoPaths.length == 1 && result.photoPaths.length > 1) {
    return _weakestPhotoQuality(
      result.photoPaths,
      result.photoQualityChecksByPath,
    );
  }
  if (index < 0 || index >= result.ocrSourcePhotoPaths.length) return null;
  final ocrSourcePath = result.ocrSourcePhotoPaths[index];
  final ocrQuality = _receiptPhotoMapValue(
    result.photoQualityChecksByPath,
    ocrSourcePath,
  );
  if (ocrQuality != null) return ocrQuality;
  if (index < result.photoPaths.length) {
    return _receiptPhotoMapValue(
      result.photoQualityChecksByPath,
      result.photoPaths[index],
    );
  }
  return null;
}

ReceiptPhotoQualityCheck? _weakestPhotoQuality(
  List<String> paths,
  Map<String, ReceiptPhotoQualityCheck> qualityByPath,
) {
  ReceiptPhotoQualityCheck? weakest;
  for (final path in paths) {
    final quality = _receiptPhotoMapValue(qualityByPath, path);
    if (quality == null) continue;
    if (weakest == null || quality.reviewScore < weakest.reviewScore) {
      weakest = quality;
    }
  }
  return weakest;
}

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String _nativeCapabilityFailureReason(
  ReceiptNativeCameraCapabilities capabilities,
) {
  if (!capabilities.available) return 'native_camera_not_available';
  if (!capabilities.cameraPermissionGranted) return 'permission_denied';
  if (!capabilities.hasRearCamera) return 'rear_camera_missing';
  return 'native_camera_not_ready';
}
