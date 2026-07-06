part of 'receipt_capture_flow.dart';

List<String> _ocrSourceDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final path = result.ocrSourcePhotoPaths[index];
  final preparation =
      _receiptPhotoMapValue(result.preparationDiagnosticsByOcrPath, path) ??
      const {};
  final signals = <String>{
    'receipt_ocr_source_photo',
    'ocr_source_first_${_signalToken(result.ocrSourceFirstDecisionCode)}',
    'ocr_source_first_outcome_${_signalToken(result.ocrSourceFirstOutcome)}',
    'ocr_source_review_risk_${_signalToken(result.ocrSourceReviewRiskCode)}',
    'ocr_source_review_requirement_${_signalToken(result.ocrSourceReviewRequirement)}',
    'data_saver_${result.dataSaverLevel.name}',
    'proof_data_saver_${result.dataSaverLevel.name}',
    'receipt_review_depth_${_signalToken(result.nativeReceiptReviewDepth)}',
    'receipt_handoff_${_signalToken(result.acceptedPhotoHandoffOutcome)}',
    'receipt_handoff_warning_${_signalToken(result.acceptedPhotoWarningProfile)}',
    'receipt_section_order_${_signalToken(result.receiptSectionOrderOutcome)}',
    'receipt_section_order_action_${_signalToken(result.receiptSectionOrderReviewActionCode)}',
    'receipt_handoff_stitch_${_signalToken(result.stitchResult.status.name)}',
    'receipt_match_readiness_${_signalToken(result.nextReviewMatchReadinessOutcome)}',
    'receipt_proof_storage_${_signalToken(result.receiptProofStoragePolicyOutcome)}',
  };
  for (final entry in result.receiptProofStoragePolicyCounts.entries) {
    signals.add('receipt_proof_storage_${_signalToken(entry.key)}');
  }
  if (result.hasPossiblePartialReceiptPhotos) {
    signals.add('receipt_handoff_possible_partial_receipt');
  }
  if (result.receiptSectionOrderNeedsReview) {
    signals.add('receipt_section_order_review_required');
    if (result.stitchResult.failedPairLabel.isNotEmpty) {
      signals.add(
        'receipt_section_order_failed_pair_${_signalToken(result.stitchResult.failedPairLabel)}',
      );
    }
  }
  if (result.usesSeparateOcrSourceCopies) {
    signals.add('receipt_handoff_separate_ocr_source');
  }
  if (result.usedSavedProofAsOcrSourceFallback) {
    signals.add('receipt_handoff_ocr_source_fallback_saved_proof');
    signals.add('ocr_reads_saved_proof_fallback_requires_review');
  }
  if (result.ocrReadsClearSourceBeforeSavedProof) {
    signals.add('ocr_reads_prepared_source_not_saved_backup');
    signals.add('ocr_reads_clear_source_before_saved_proof');
  }
  final scannerDecisionCodes = preparation['scannerDecisionCodes'];
  if (scannerDecisionCodes is Iterable) {
    for (final rawCode in scannerDecisionCodes) {
      final code = _signalToken(rawCode.toString());
      if (code != 'unknown') signals.add('scanner_decision_$code');
    }
  }
  if (result.stitchResult.didStitch) signals.add('stitched_ocr_source');
  if (result.stitchResult.usedFallback) {
    signals.add('multiple_ocr_sources_fallback');
  }
  if (!result.stitchResult.hasValidOcrSourceContract ||
      !result.ocrSourcePathsMatchStitchContract) {
    signals.add('stitch_ocr_source_contract_review_required');
  }
  if (!result.ocrSourcePathsMatchStitchContract) {
    signals.add('stitch_ocr_source_result_contract_mismatch');
  }
  signals.add(
    'stitch_overlap_${_signalToken(result.stitchResult.overlapCoverageCode)}',
  );
  signals.add(
    'stitch_ocr_source_contract_${_signalToken(result.stitchResult.ocrSourceContractCode)}',
  );
  signals.add(
    'stitch_source_${_signalToken(result.stitchResult.sourcePreservationCode)}',
  );
  signals.addAll(_nativeCameraUiDocumentSignalsFor(result));
  signals.addAll(_nativeCloseCapturedPhotoDocumentSignalsFor(result));
  signals.addAll(_nativeCaptureSourcePolicyDocumentSignalsFor(result));
  signals.addAll(_nativeReceiptCameraSurfaceDocumentSignalsFor(result));
  signals.addAll(_receiptBrainDocumentSignalsFor(result));
  signals.addAll(_receiptCoverageDecisionDocumentSignalsFor(result, index));
  signals.addAll(_receiptContinuationHandoffDocumentSignalsFor(result));
  signals.addAll(_receiptCompletionHandoffDocumentSignalsFor(result));
  signals.addAll(_ocrSourceContinuationDocumentSignalsFor(result, index));
  for (final diagnostics in _diagnosticsForOcrSourceIndex(result, index)) {
    final recoveryStatus = _signalToken(
      diagnostics['nativeRecoveryResumeStatus']?.toString() ?? '',
    );
    if (recoveryStatus != 'unknown') {
      signals.add('native_recovery_$recoveryStatus');
    }
    final recoveredCount = diagnostics['nativeRecoveryRecoveredPhotoCount'];
    if (recoveredCount is num &&
        recoveredCount.isFinite &&
        recoveredCount > 0) {
      signals.add('native_recovery_recovered_photos');
    }
    if (diagnostics['nativeRecoveryMultipleSections'] == true) {
      signals.add('native_recovery_multiple_sections');
    }
    if (diagnostics['userEditedPhoto'] == true) {
      final editAction = _photoEditActionSignalToken(
        diagnostics['photoEditAction'],
      );
      final sourceSelection = diagnostics['photoEditReplacedOriginal'] == true
          ? 'edited_copy_selected'
          : 'accepted_source_retained';
      signals.add('review_photo_edited');
      signals.add('review_photo_edit_$editAction');
      signals.add('review_photo_edit_source_selected');
      signals.add('review_photo_edit_source_selected_$sourceSelection');
      if (diagnostics['photoEditReplacedOriginal'] == true) {
        signals.add('review_photo_edit_replaced_original');
        signals.add('review_photo_edit_replaced_original_$editAction');
      }
    }
    final freshness = _signalToken(
      diagnostics['nativeRecoveryFreshness']?.toString() ?? '',
    );
    if (freshness != 'unknown') {
      signals.add('native_recovery_freshness_$freshness');
    }
    final storageStatus = _signalToken(
      diagnostics['nativeRecoveryStorageStatus']?.toString() ?? '',
    );
    if (storageStatus != 'unknown') {
      signals.add('native_recovery_storage_$storageStatus');
    }
  }
  return List.unmodifiable(signals);
}

String _photoEditActionSignalToken(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty) return 'manual_edit';
  final token = _signalToken(raw);
  return switch (token) {
    'manual_crop' ||
    'manual_rotate' ||
    'manual_edit' ||
    'auto_crop' ||
    'auto_rotate' ||
    'perspective_correction' ||
    'deskew' ||
    'brightness_cleanup' ||
    'contrast_cleanup' ||
    'shadow_cleanup' ||
    'grayscale_cleanup' => token,
    _ => 'invalid_photo_edit_action',
  };
}

Map<String, Object?> _receiptReaderHandoffDiagnosticsFor(
  ReceiptPhotoReviewResult result,
) {
  final nativeUiCounts = result.nativeCameraUiHealthCounts;
  final closeCounts = result.nativeCloseCapturedPhotoOutcomeCounts;
  return Map<String, Object?>.unmodifiable({
    'receiptReaderHandoffIntegrity': result.receiptReaderHandoffIntegrityLabel,
    'receiptDetailsHandoffIntegrity':
        result.receiptDetailsHandoffIntegrityLabel,
    'receiptReaderHandoffCounts': result.receiptReaderHandoffCounts,
    'receiptDetailsHandoffCounts': result.receiptDetailsHandoffCounts,
    'receiptReaderHandoffMetadata':
        result.privacySafeReceiptReaderHandoffMetadata,
    'receiptDetailsHandoffMetadata':
        result.privacySafeReceiptReaderHandoffMetadata,
    'receiptReaderHandoffOutcome': result.acceptedPhotoHandoffOutcome,
    'receiptDetailsHandoffOutcome': result.acceptedPhotoHandoffOutcome,
    'acceptedPhotoWarningProfile': result.acceptedPhotoWarningProfile,
    'receiptReaderHandoffActionLabel': result.acceptedPhotoHandoffActionLabel,
    'receiptDetailsHandoffActionLabel': result.acceptedPhotoHandoffActionLabel,
    'receiptReaderHandoffRoute': result.acceptedPhotoHandoffRoute,
    'receiptDetailsHandoffRoute': result.acceptedPhotoHandoffRoute,
    'receiptReaderHandoffNextScreen': result.acceptedPhotoHandoffNextScreen,
    'receiptDetailsHandoffNextScreen': result.acceptedPhotoHandoffNextScreen,
    'receiptReaderHandoffNextStepLabel':
        result.acceptedPhotoHandoffNextStepLabel,
    'receiptDetailsHandoffNextStepLabel':
        result.acceptedPhotoHandoffNextStepLabel,
    'receiptReaderHandoffOcrSourcePolicy':
        'read_temporary_full_quality_or_prepared_source_before_saved_proof',
    'receiptDetailsHandoffOcrSourcePolicy':
        'read_temporary_full_quality_or_prepared_source_before_saved_proof',
    'receiptReaderHandoffOcrSourceOutcome': result.ocrSourceFirstOutcome,
    'receiptDetailsHandoffOcrSourceOutcome': result.ocrSourceFirstOutcome,
    'receiptReaderHandoffOcrSourceActionLabel':
        result.ocrSourceFirstActionLabel,
    'receiptDetailsHandoffOcrSourceActionLabel':
        result.ocrSourceFirstActionLabel,
    'receiptReaderHandoffCompressionPolicy':
        'saved_proof_created_after_receipt_details_source',
    'receiptDetailsHandoffCompressionPolicy':
        'saved_proof_created_after_receipt_details_source',
    'receiptReaderHandoffMustOpenReceiptDetails':
        result.acceptedPhotoHandoffMustOpenReceiptDetails,
    'receiptDetailsHandoffMustOpenReceiptDetails':
        result.acceptedPhotoHandoffMustOpenReceiptDetails,
    'receiptReaderHandoffMustOpenFilledReview':
        result.acceptedPhotoHandoffMustOpenFilledReview,
    'receiptDetailsHandoffMustOpenFilledReview':
        result.acceptedPhotoHandoffMustOpenFilledReview,
    'receiptReaderHandoffUserAction': result.acceptedPhotoHandoffUserAction,
    'receiptDetailsHandoffUserAction': result.acceptedPhotoHandoffUserAction,
    'receiptReaderHandoffEvidence': result.acceptedPhotoHandoffEvidenceLabel,
    'receiptDetailsHandoffEvidence': result.acceptedPhotoHandoffEvidenceLabel,
    'receiptProofDataSaverLevel': result.dataSaverLevel.name,
    'nativeReceiptReviewDepth': result.nativeReceiptReviewDepth,
    if (nativeUiCounts.isNotEmpty)
      'nativeCameraUiHealthOutcome': result.nativeCameraUiHealthOutcome,
    if (nativeUiCounts.isNotEmpty) 'nativeCameraUiHealthCounts': nativeUiCounts,
    if (closeCounts.isNotEmpty)
      'nativeCloseCapturedPhotoHealthOutcome':
          result.nativeCloseCapturedPhotoHealthOutcome,
    if (closeCounts.isNotEmpty)
      'nativeCloseCapturedPhotoActionLabel':
          result.nativeCloseCapturedPhotoActionLabel,
    if (closeCounts.isNotEmpty)
      'nativeCloseCapturedPhotoOutcomeCounts': closeCounts,
  });
}

String _signalToken(String value) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return token.isEmpty ? 'unknown' : token;
}
