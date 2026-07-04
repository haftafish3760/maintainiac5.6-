part of 'receipt_capture_flow.dart';

List<String> _nativeCameraUiDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.nativeCameraUiHealthCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    'native_camera_ui_health_available',
    'native_camera_ui_${_signalToken(result.nativeCameraUiHealthOutcome)}',
    for (final entry in counts.entries)
      'native_camera_ui_${_signalToken(entry.key)}',
  });
}

List<String> _nativeCameraUiRiskFlagsFor(ReceiptPhotoReviewResult result) {
  final counts = result.nativeCameraUiHealthCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    for (final entry in counts.entries)
      if (_isNativeCameraUiRisk(entry.key))
        'native_camera_ui_${_signalToken(entry.key)}',
    if (_isNativeCameraUiRisk(result.nativeCameraUiHealthOutcome))
      'native_camera_ui_${_signalToken(result.nativeCameraUiHealthOutcome)}',
  });
}

List<String> _nativeCloseCapturedPhotoDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.nativeCloseCapturedPhotoOutcomeCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    'native_close_captured_photo_outcome_available',
    'native_close_captured_photo_${_signalToken(result.nativeCloseCapturedPhotoHealthOutcome)}',
    for (final entry in counts.entries)
      'native_close_captured_photo_${_signalToken(entry.key)}',
  });
}

List<String> _nativeCloseCapturedPhotoRiskFlagsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.nativeCloseCapturedPhotoOutcomeCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    for (final entry in counts.entries)
      if (_isNativeCloseCapturedPhotoRisk(entry.key))
        'native_close_captured_photo_${_signalToken(entry.key)}',
    if (_isNativeCloseCapturedPhotoRisk(
      result.nativeCloseCapturedPhotoHealthOutcome,
    ))
      'native_close_captured_photo_${_signalToken(result.nativeCloseCapturedPhotoHealthOutcome)}',
  });
}

List<String> _nativeCaptureSourcePolicyDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.nativeCaptureSourcePolicyCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    'native_capture_source_health_available',
    'native_capture_source_${_signalToken(result.nativeCaptureSourcePolicyOutcome)}',
    for (final entry in counts.entries)
      'native_capture_source_${_signalToken(entry.key)}',
  });
}

List<String> _nativeReceiptCameraSurfaceDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final surfaceCounts = result.nativeReceiptCameraSurfaceActualCounts;
  final verificationCounts =
      result.nativeReceiptCameraSurfaceVerificationCounts;
  final identityCounts = result.nativeCameraIdentityCounts;
  if (surfaceCounts.isEmpty &&
      verificationCounts.isEmpty &&
      identityCounts.isEmpty) {
    return const [];
  }
  return List.unmodifiable({
    'native_capture_surface_health_available',
    if (result.nativeReceiptCameraSurfaceOutcome != 'unknown')
      'native_capture_surface_${_signalToken(result.nativeReceiptCameraSurfaceOutcome)}',
    if (result.nativeReceiptCameraSurfaceVerificationOutcome != 'unknown')
      'native_capture_surface_verified_${_signalToken(result.nativeReceiptCameraSurfaceVerificationOutcome)}',
    if (result.nativeCameraIdentityOutcome != 'unknown')
      'native_capture_identity_${_signalToken(result.nativeCameraIdentityOutcome)}',
    for (final entry in surfaceCounts.entries)
      'native_capture_surface_${_signalToken(entry.key)}',
    for (final entry in verificationCounts.entries)
      'native_capture_surface_verified_${_signalToken(entry.key)}',
    for (final entry in identityCounts.entries)
      'native_capture_identity_${_signalToken(entry.key)}',
  });
}

List<String> _nativeCaptureSourcePolicyRiskFlagsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.nativeCaptureSourcePolicyCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    if ((counts['document_scanner_backup'] ?? 0) > 0)
      'ocr_source_document_scanner_backup',
    if ((counts['storage_saver_native'] ?? 0) > 0)
      'ocr_source_native_capture_storage_saver',
    if ((counts['older_phone_native'] ?? 0) > 0)
      'ocr_source_native_capture_older_phone',
    if ((counts['phone_camera_backup'] ?? 0) > 0)
      'ocr_source_phone_camera_backup',
  });
}

List<String> _receiptBrainDocumentSignalsFor(ReceiptPhotoReviewResult result) {
  final releaseCounts = result.receiptBrainReleaseActionCounts;
  final installCounts = result.receiptBrainInstallDistributionCounts;
  final storageCounts = result.receiptBrainStorageClassCounts;
  final localOcrCounts = result.receiptBrainLocalOcrModeCounts;
  if (releaseCounts.isEmpty &&
      installCounts.isEmpty &&
      storageCounts.isEmpty &&
      localOcrCounts.isEmpty) {
    return const [];
  }
  return List.unmodifiable({
    'receipt_brain_mode_available',
    if (result.receiptBrainReleaseActionOutcome !=
        'receipt_brain_action_unknown')
      'receipt_brain_release_${_signalToken(result.receiptBrainReleaseActionOutcome)}',
    if (result.receiptBrainInstallDistributionOutcome !=
        'receipt_brain_install_unknown')
      'receipt_brain_install_${_signalToken(result.receiptBrainInstallDistributionOutcome)}',
    for (final entry in releaseCounts.entries)
      'receipt_brain_release_${_signalToken(entry.key)}',
    for (final entry in installCounts.entries)
      'receipt_brain_install_${_signalToken(entry.key)}',
    for (final entry in storageCounts.entries)
      'receipt_brain_storage_${_signalToken(entry.key)}',
    for (final entry in localOcrCounts.entries)
      'receipt_brain_local_ocr_${_signalToken(entry.key)}',
  });
}

List<String> _receiptBrainRiskFlagsFor(ReceiptPhotoReviewResult result) {
  final releaseCounts = result.receiptBrainReleaseActionCounts;
  final installCounts = result.receiptBrainInstallDistributionCounts;
  final storageCounts = result.receiptBrainStorageClassCounts;
  final localOcrCounts = result.receiptBrainLocalOcrModeCounts;
  if (releaseCounts.isEmpty &&
      installCounts.isEmpty &&
      storageCounts.isEmpty &&
      localOcrCounts.isEmpty) {
    return const [];
  }
  final blocksRequiredBase =
      (releaseCounts['move_heavy_receipt_work_to_optional_packs_before_release'] ??
              0) >
          0 ||
      (installCounts['required_base_blocked_until_optionalized'] ?? 0) > 0;
  final defersOptionalPacks =
      (releaseCounts['ship_lean_base_and_defer_optional_receipt_packs'] ?? 0) >
      0;
  final hasCriticalStorage = (storageCounts['critical'] ?? 0) > 0;
  final hasLowStorage = (storageCounts['low'] ?? 0) > 0;
  final usesLeanLocalOcr = (localOcrCounts['lean_local_ocr'] ?? 0) > 0;
  return List.unmodifiable({
    if (blocksRequiredBase) 'ocr_source_receipt_brain_required_base_blocked',
    if (defersOptionalPacks) 'ocr_source_receipt_brain_optional_packs_deferred',
    if (hasCriticalStorage) 'ocr_source_receipt_brain_critical_storage',
    if (hasLowStorage) 'ocr_source_receipt_brain_low_storage',
    if (usesLeanLocalOcr) 'ocr_source_receipt_brain_lean_local_ocr',
  });
}

bool _isNativeCameraUiRisk(String value) {
  final token = _signalToken(value);
  return token.contains('incomplete') ||
      token.contains('missing') ||
      token.contains('regressed') ||
      token.contains('unknown') ||
      token.contains('review_required') ||
      token.contains('close_deferred') ||
      token.contains('close_retry') ||
      token.contains('capture_failed_after_close') ||
      token.contains('capture_failed_returned_existing_sections') ||
      token.contains('closed_without_photo') ||
      token.contains('close_already_delivered') ||
      token.contains('waiting_for_in_flight_capture');
}

bool _isNativeCloseCapturedPhotoRisk(String value) {
  final token = _signalToken(value);
  return token == 'capture_failed_after_close' ||
      token == 'capture_failed_returned_existing_sections' ||
      token == 'closed_without_photo' ||
      token == 'close_already_delivered' ||
      token == 'waiting_for_in_flight_capture' ||
      token == 'close_outcome_unknown';
}
