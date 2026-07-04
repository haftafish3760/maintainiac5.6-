part of 'receipt_capture_models.dart';

List<String> _nativeExposureControlHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final policy = _diagnosticToken(
    diagnostics['preCaptureExposurePolicy']?.toString() ?? '',
  );
  final outcome = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.preCaptureExposureOutcome]
            ?.toString() ??
        '',
  );
  final selectedExposure = _diagnosticToken(
    diagnostics['selectedExposureBucket']?.toString() ?? '',
  );
  final skipReason = _diagnosticToken(
    diagnostics['lastPreCaptureExposureSkipReason']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (policy != 'unknown') 'exposure_policy_$policy',
    if (outcome != 'unknown') 'pre_capture_exposure_$outcome',
    if (outcome == 'lifted_for_dim_receipt')
      'pre_capture_exposure_lifted_dim_receipt',
    if (outcome == 'kept_native_auto') 'pre_capture_exposure_native_auto_ok',
    if (outcome == 'skipped') 'pre_capture_exposure_skipped',
    if (selectedExposure == 'exposure_brighter')
      'manual_brightness_user_raised'
    else if (selectedExposure == 'exposure_darker')
      'manual_brightness_user_lowered'
    else if (selectedExposure == 'exposure_baseline')
      'manual_brightness_baseline',
    if (skipReason != 'unknown') 'pre_capture_exposure_skip_$skipReason',
  ]);
}

List<String> _nativeFocusReadabilityHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  final tapFocusExpected = _diagnosticBool(
    diagnostics['tapFocusControlExpected'],
  );
  final continuousFocusExpected = _diagnosticBool(
    diagnostics['continuousFocusExpected'],
  );
  final focusPolicy = _diagnosticToken(
    diagnostics['focusStrategyPolicy']?.toString() ?? '',
  );
  final readabilityPolicy = _diagnosticToken(
    diagnostics['readabilityGuidancePolicy']?.toString() ?? '',
  );
  final qualityBaseline = _diagnosticBool(
    diagnostics['receiptCameraQualityBaseline'],
  );

  if (tapFocusExpected == true) {
    codes.add('tap_focus_retirement_regressed');
  } else if (tapFocusExpected == false) {
    codes.add('tap_focus_retired');
  }

  if (continuousFocusExpected == true) {
    codes.add('continuous_focus_expected');
  } else if (continuousFocusExpected == false) {
    codes.add('continuous_focus_missing');
  }

  if (focusPolicy == 'continuous_focus_primary_no_tap_assist') {
    codes.add('continuous_focus_primary_ready');
  } else if (focusPolicy != 'unknown') {
    codes.add('continuous_focus_primary_missing');
  }

  if (readabilityPolicy ==
      'live_readability_guides_blur_glare_light_edges_and_text_size') {
    codes.add('readability_guidance_live_ready');
  } else if (readabilityPolicy != 'unknown') {
    codes.add('readability_guidance_live_missing');
  }

  if (qualityBaseline == true) {
    codes.add('receipt_camera_quality_baseline_ready');
  } else if (qualityBaseline == false) {
    codes.add('receipt_camera_quality_baseline_missing');
  }

  return List.unmodifiable(codes);
}

List<String> _nativeCloseHealthCodes(Map<String, Object?> diagnostics) {
  final closeOutcome = _diagnosticToken(
    diagnostics['closeCapturedPhotoOutcome']?.toString() ?? '',
  );
  final closePolicy = _diagnosticToken(
    diagnostics['closeCapturedPhotoPolicy']?.toString() ?? '',
  );
  final closeAction = _diagnosticToken(
    diagnostics['closeAction']?.toString() ?? '',
  );
  return List.unmodifiable([
    if (closeOutcome != 'unknown') 'native_close_outcome_$closeOutcome',
    if (closePolicy != 'unknown') 'native_close_policy_$closePolicy',
    if (closeAction != 'unknown' && closeAction != 'open')
      'native_close_action_$closeAction',
    if (_diagnosticPositive(diagnostics['closeDuringCaptureCount']) ||
        diagnostics['pendingCloseAfterCapture'] == true)
      'native_close_deferred_during_capture',
    if (_diagnosticPositive(diagnostics['closeRequestCount']))
      'native_close_request_recorded',
    if (diagnostics['closeResultDelivered'] == true)
      'native_close_result_delivered',
    if (_diagnosticPositive(diagnostics['closeRetryCount']))
      'native_close_retry_after_result',
    if (_diagnosticPositive(diagnostics['closeNoPhotoCancelCount']) ||
        closeAction == 'back_no_photo_cancel' ||
        closeAction == 'done_no_photo_cancel')
      'native_close_no_photo_cancel',
    if (_diagnosticPositive(diagnostics['closeReturnedSectionsCount']) ||
        closeAction == 'back_returned_captured_sections' ||
        closeOutcome == 'back_returned_captured_sections' ||
        closeOutcome == 'next_returned_captured_sections')
      'native_close_returned_captured_sections',
    if (closeOutcome == 'capture_failed_after_close')
      'native_close_capture_failed_after_close',
    if (closeOutcome == 'capture_failed_returned_existing_sections')
      'native_close_capture_failed_returned_existing_sections',
    if (closeOutcome == 'closed_without_photo')
      'native_close_closed_without_photo',
    if (closeOutcome == 'close_already_delivered')
      'native_close_already_delivered',
    if (closeOutcome == 'waiting_for_in_flight_capture')
      'native_close_waiting_for_in_flight_capture',
  ]);
}

List<String> _nativeCapturePreviewParityHealthCodes(
  Map<String, Object?> diagnostics,
) {
  final codes = <String>[];
  final readiness = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.captureReadinessCode]
            ?.toString() ??
        '',
  );
  if (readiness != 'unknown') {
    codes.add('capture_readiness_$readiness');
  }
  if (diagnostics[ReceiptCaptureDiagnosticKeys.manualCaptureAllowed] == true) {
    codes.add('manual_capture_allowed');
  }
  if (diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureAllowed] == true) {
    codes.add('auto_capture_allowed');
  } else if (diagnostics[ReceiptCaptureDiagnosticKeys.autoCaptureEnabled] ==
      true) {
    codes.add('auto_capture_held_back');
  }
  final signal =
      diagnostics[ReceiptCaptureDiagnosticKeys
              .latestCapturedPreviewParitySignal]
          ?.toString()
          .trim();
  final bucket =
      diagnostics[ReceiptCaptureDiagnosticKeys
              .latestCapturedLiveToSavedLumaDeltaBucket]
          ?.toString()
          .trim();
  final lightingEvidence = _diagnosticToken(
    diagnostics[ReceiptCaptureDiagnosticKeys.capturedLightingEvidence]
            ?.toString() ??
        '',
  );
  if (lightingEvidence != 'unknown') {
    codes.add('captured_lighting_evidence_$lightingEvidence');
  }
  if (diagnostics['manualCapturePolicy'] ==
      'guidance_advisory_manual_shutter_always_allowed') {
    codes.add('manual_capture_not_blocked_by_quality_guidance');
  }
  if (signal == null && bucket == null) return List.unmodifiable(codes);
  if (signal == 'saved_photo_darker_than_preview_review_needed' ||
      bucket == 'saved_much_darker_than_preview') {
    codes.add('preview_saved_darker_than_live');
  } else if (signal == 'saved_photo_darker_than_preview_watch' ||
      bucket == 'saved_darker_than_preview') {
    codes.add('preview_saved_darker_than_live_watch');
  } else if (signal == 'saved_photo_brighter_than_preview_review_needed' ||
      bucket == 'saved_much_brighter_than_preview') {
    codes.add('preview_saved_brighter_than_live');
  } else if (signal == 'saved_photo_brighter_than_preview_watch' ||
      bucket == 'saved_brighter_than_preview') {
    codes.add('preview_saved_brighter_than_live_watch');
  } else if (signal == 'saved_photo_matches_preview' ||
      bucket == 'saved_matches_preview') {
    codes.add('preview_saved_parity_ok');
  } else {
    codes.add('preview_saved_parity_review');
  }
  return List.unmodifiable(codes);
}

Set<String> _nativeCaptureSourcePoliciesFor(Map<String, Object?> diagnostics) {
  final policies = <String>{};
  final captureFlow = diagnostics['captureFlow']?.toString().trim() ?? '';
  if (captureFlow == 'document_scanner_backup_receipt_photo' ||
      diagnostics['documentScannerBackupUsed'] == true) {
    policies.add('document_scanner_backup');
  }
  if (captureFlow == 'phone_camera_backup_receipt_photo' ||
      diagnostics['phoneCameraBackupUsed'] == true) {
    policies.add('phone_camera_backup');
  }
  if (diagnostics.containsKey('nativeRecoveryResumeStatus') ||
      diagnostics.containsKey('nativeRecoveryFreshness') ||
      diagnostics['nativeCaptureRecoveryAttachmentState'] ==
          'staged_not_attached') {
    policies.add('native_recovery');
  }
  final policy = diagnostics['nativeCaptureMemoryPolicy']?.toString().trim();
  final workloadProtection = diagnostics['workloadProtectionPolicy']
      ?.toString()
      .trim();
  final workload = diagnostics['cameraWorkloadTier']?.toString().trim();
  final surface = diagnostics['captureSurface']?.toString().trim() ?? '';
  final nativeCapture =
      surface.startsWith('maintainiac_native_') ||
      captureFlow == 'maintainiac_native_receipt_camera' ||
      policy != null;
  if (!nativeCapture) return policies;
  if (diagnostics['storageConstrained'] == true ||
      workloadProtection?.contains('storage_saver') == true ||
      policy?.contains('small_local_proof') == true ||
      policy?.contains('tiny_local_proof') == true) {
    policies.add('storage_saver_native');
  }
  if (workloadProtection?.contains('older_phone') == true ||
      policy?.contains('older_phone') == true ||
      workload == 'light') {
    policies.add('older_phone_native');
  }
  if (workloadProtection == 'flagship_full_workload') {
    policies.add('flagship_native');
  }
  if (workloadProtection == 'balanced_workload') {
    policies.add('balanced_native');
  }
  if (policies.isEmpty) policies.add('normal_native');
  return policies;
}

String _acceptedPhotoQualityOutcomeFor({
  ReceiptPhotoQualityCheck? quality,
  Map<String, Object?>? diagnostics,
}) {
  final nativeWarning =
      ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics(diagnostics);
  if (nativeWarning?.isCritical == true || quality?.hasCriticalIssue == true) {
    return 'critical_quality_retake_recommended';
  }
  final coverageDecision = ReceiptPhotoCoverageDecision.fromSignals(
    quality: quality,
    diagnostics: diagnostics,
  );
  if (coverageDecision.shouldPromptForMorePhotos) {
    return 'possible_partial_receipt';
  }
  if (nativeWarning != null || quality?.needsReview == true) {
    return 'needs_review_before_ocr';
  }
  if (quality == null && (diagnostics == null || diagnostics.isEmpty)) {
    return 'accepted_no_quality_signal';
  }
  return 'ready_for_receipt_review';
}

String _nativeControlSetHealthCode(String? controlSet) {
  if (controlSet == null || controlSet.isEmpty) {
    return 'native_control_signal_missing';
  }
  final controls = controlSet
      .split('|')
      .map((control) => control.trim())
      .where((control) => control.isNotEmpty)
      .toSet();
  const requiredControls = {'back', 'settings', 'manual_shutter', 'status'};
  return controls.containsAll(requiredControls)
      ? 'native_controls_ready'
      : 'native_controls_incomplete';
}

List<String> _nativeReadabilityVisibleHealthCodes(
  Map<String, Object?> diagnostics,
  String? controlSet,
) {
  final policy = _diagnosticToken(
    diagnostics['readabilityGuidancePolicy']?.toString() ?? '',
  );
  if (policy !=
      'live_readability_guides_blur_glare_light_edges_and_text_size') {
    return const [];
  }
  final controls = controlSet == null
      ? const <String>{}
      : controlSet
            .split('|')
            .map((control) => control.trim())
            .where((control) => control.isNotEmpty)
            .toSet();
  return List.unmodifiable([
    controls.contains('readability_guidance')
        ? 'readability_guidance_visible'
        : 'readability_guidance_visible_missing',
  ]);
}
