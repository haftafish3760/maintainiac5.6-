part of 'receipt_capture_flow.dart';

List<String> _ocrSourceRiskFlagsFor(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final flags = <String>{};
  if (result.dataSaverLevel == ReceiptDataSaverLevel.strong ||
      result.dataSaverLevel == ReceiptDataSaverLevel.maximum) {
    flags.add('ocr_source_small_proof_copy_review_required');
    flags.add('ocr_source_proof_data_saver_${result.dataSaverLevel.name}');
  }
  final quality = _qualityForOcrSourceIndex(result, index);
  if (quality != null) {
    flags.add(
      'ocr_source_quality_action_${_signalToken(quality.reviewActionCode)}',
    );
    flags.add(
      'ocr_source_quality_family_${_signalToken(quality.reviewActionFamily)}',
    );
    if (quality.shouldRetakeBeforeOcr) flags.add('ocr_source_retake_risk');
    if (quality.needsReview) flags.add('ocr_source_needs_review');
    if (quality.isTooDark || quality.isUnderexposedForReceipt) {
      flags.add('ocr_source_dark');
    }
    if (quality.isSoft || quality.isVerySoft) flags.add('ocr_source_soft');
    if (quality.isPoorlyFramed) flags.add('ocr_source_possible_cutoff');
  }
  if (result.stitchResult.usedFallback) {
    flags.add('ocr_stitch_fallback_multiple_sources');
  }
  if (!result.stitchResult.hasValidOcrSourceContract ||
      !result.ocrSourcePathsMatchStitchContract) {
    flags.add('ocr_source_stitch_contract_review_required');
    flags.add(
      'ocr_source_stitch_contract_${_signalToken(result.stitchResult.ocrSourceContractCode)}',
    );
  }
  if (!result.ocrSourcePathsMatchStitchContract) {
    flags.add('ocr_source_stitch_result_contract_mismatch');
  }
  if (result.stitchResult.failedPairLabel.isNotEmpty) {
    flags.add(
      'ocr_source_stitch_failed_pair_${_signalToken(result.stitchResult.failedPairLabel)}',
    );
  }
  if (result.stitchResult.reviewFocusPairLabel.isNotEmpty) {
    flags.add(
      'ocr_source_stitch_review_focus_pair_${_signalToken(result.stitchResult.reviewFocusPairLabel)}',
    );
  }
  if (result.usedSavedProofAsOcrSourceFallback) {
    flags.add('ocr_source_fallback_saved_proof_review_required');
  }
  if (result.receiptProofStoragePolicyOutcome ==
      'saved_proof_ocr_fallback_review') {
    flags.add('ocr_source_saved_proof_fallback_review');
  }
  if (result.receiptProofStoragePolicyOutcome ==
      'temporary_full_quality_source_guard_review') {
    flags.add('ocr_source_temporary_full_quality_guard_review');
  }
  if (result.receiptSectionOrderNeedsReview) {
    flags.add('ocr_source_section_order_review_required');
    flags.add(
      'ocr_source_section_order_action_${_signalToken(result.receiptSectionOrderReviewActionCode)}',
    );
    if (result.stitchResult.failedPairLabel.isNotEmpty) {
      flags.add(
        'ocr_source_section_order_failed_pair_${_signalToken(result.stitchResult.failedPairLabel)}',
      );
    }
  }
  flags.add(
    'ocr_source_first_${_signalToken(result.ocrSourceFirstDecisionCode)}',
  );
  flags.add(
    'ocr_source_match_readiness_${_signalToken(result.nextReviewMatchReadinessOutcome)}',
  );
  for (final warning in _savedPhotoWarningsForOcrSourceIndex(result, index)) {
    flags.add('ocr_source_${_signalToken(warning.code)}');
    flags.add('ocr_source_action_${_signalToken(warning.actionCode)}');
    flags.add('ocr_source_parser_risk_${_signalToken(warning.parserRiskCode)}');
    if (warning.isCritical) flags.add('ocr_source_native_critical_review');
  }
  _addScannerRiskFlags(result, index, flags);
  _addNativeRecoveryRiskFlags(result, index, flags);
  flags.addAll(_nativeCameraUiRiskFlagsFor(result));
  flags.addAll(_nativeCloseCapturedPhotoRiskFlagsFor(result));
  flags.addAll(_nativeCaptureSourcePolicyRiskFlagsFor(result));
  flags.addAll(_receiptContinuationHandoffRiskFlagsFor(result));
  flags.addAll(_receiptCompletionHandoffRiskFlagsFor(result));
  flags.addAll(_ocrSourceContinuationRiskFlagsFor(result, index));
  flags.addAll(_receiptBrainRiskFlagsFor(result));
  return List.unmodifiable(flags);
}

void _addScannerRiskFlags(
  ReceiptPhotoReviewResult result,
  int index,
  Set<String> flags,
) {
  final preparation =
      _receiptPhotoMapValue(
        result.preparationDiagnosticsByOcrPath,
        result.ocrSourcePhotoPaths[index],
      ) ??
      const {};
  final scannerDecisionCodes = preparation['scannerDecisionCodes'];
  if (scannerDecisionCodes is! Iterable) return;
  for (final rawCode in scannerDecisionCodes) {
    final code = _signalToken(rawCode.toString());
    if (code.contains('quality_guard') ||
        code.contains('decode_failed') ||
        code.contains('skipped')) {
      flags.add('ocr_source_$code');
    }
  }
}

void _addNativeRecoveryRiskFlags(
  ReceiptPhotoReviewResult result,
  int index,
  Set<String> flags,
) {
  for (final diagnostics in _diagnosticsForOcrSourceIndex(result, index)) {
    final recoveryStatus = _signalToken(
      diagnostics['nativeRecoveryResumeStatus']?.toString() ?? '',
    );
    if (recoveryStatus != 'unknown') {
      flags.add('ocr_source_native_recovery_$recoveryStatus');
    }
    if (diagnostics['nativeRecoveryMultipleSections'] == true) {
      flags.add('ocr_source_native_recovery_multiple_sections');
    }
    if (diagnostics['userEditedPhoto'] == true) {
      _addEditedPhotoRiskFlags(diagnostics, flags);
    }
    final freshness = _signalToken(
      diagnostics['nativeRecoveryFreshness']?.toString() ?? '',
    );
    if (freshness == 'stale' || freshness == 'very_stale') {
      flags.add('ocr_source_native_recovery_$freshness');
    }
    final storageStatus = _signalToken(
      diagnostics['nativeRecoveryStorageStatus']?.toString() ?? '',
    );
    if (storageStatus == 'partial_photos_available' ||
        storageStatus == 'photos_missing') {
      flags.add('ocr_source_native_recovery_$storageStatus');
    }
  }
}

void _addEditedPhotoRiskFlags(
  Map<String, Object?> diagnostics,
  Set<String> flags,
) {
  final editAction = _photoEditActionSignalToken(
    diagnostics['photoEditAction'],
  );
  final sourceSelection = diagnostics['photoEditReplacedOriginal'] == true
      ? 'edited_copy_selected'
      : 'accepted_source_retained';
  flags.add('ocr_source_review_photo_edited');
  flags.add('ocr_source_review_photo_edit_$editAction');
  flags.add('ocr_source_review_photo_edit_source_selected');
  flags.add('ocr_source_review_photo_edit_source_selected_$sourceSelection');
  if (diagnostics['photoEditReplacedOriginal'] == true) {
    flags.add('ocr_source_review_photo_edit_replaced_original');
    flags.add('ocr_source_review_photo_edit_replaced_original_$editAction');
  }
}

List<ReceiptNativeSavedPhotoReviewWarning> _savedPhotoWarningsForOcrSourceIndex(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final diagnostics = _diagnosticsForOcrSourceIndex(result, index);
  return diagnostics
      .map(ReceiptNativeSavedPhotoReviewWarning.maybeFromDiagnostics)
      .whereType<ReceiptNativeSavedPhotoReviewWarning>()
      .toList(growable: false);
}

List<Map<String, Object?>> _diagnosticsForOcrSourceIndex(
  ReceiptPhotoReviewResult result,
  int index,
) {
  if (result.ocrSourcePhotoPaths.length == 1 && result.photoPaths.length > 1) {
    return [
      for (final path in result.photoPaths)
        ?_receiptPhotoMapValue(result.captureDiagnosticsByPhotoPath, path),
    ];
  }
  if (index < 0 || index >= result.ocrSourcePhotoPaths.length) {
    return const [];
  }
  final ocrSourcePath = result.ocrSourcePhotoPaths[index];
  var diagnostics = _receiptPhotoMapValue(
    result.captureDiagnosticsByPhotoPath,
    ocrSourcePath,
  );
  if (diagnostics == null && index < result.photoPaths.length) {
    diagnostics = _receiptPhotoMapValue(
      result.captureDiagnosticsByPhotoPath,
      result.photoPaths[index],
    );
  }
  return diagnostics == null ? const [] : [diagnostics];
}

T? _receiptPhotoMapValue<T>(Map<String, T> valuesByPath, String path) {
  final normalizedPath = normalizedReceiptPhotoPath(path);
  if (normalizedPath == null) return null;
  for (final entry in valuesByPath.entries) {
    if (normalizedReceiptPhotoPath(entry.key) == normalizedPath) {
      return entry.value;
    }
  }
  return null;
}
