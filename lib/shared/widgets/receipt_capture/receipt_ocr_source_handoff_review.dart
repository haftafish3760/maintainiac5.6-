part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrSourceHandoffReview on ReceiptOcrSourceHandoffSummary {
  String get status {
    if (handoffSignalCounts.containsKey(
      'receipt_handoff_possible_partial_receipt',
    )) {
      return 'possible_partial_receipt';
    }
    if (handoffSignalCounts.containsKey(
      'receipt_handoff_critical_quality_retake_recommended',
    )) {
      return 'critical_quality_retake_recommended';
    }
    if (handoffSignalCounts.containsKey(
      'receipt_handoff_needs_review_before_ocr',
    )) {
      return 'needs_review_before_ocr';
    }
    if (hasStitchContractReviewRisk) {
      return 'stitch_contract_review_required';
    }
    if (stitchSignalCounts.containsKey('multiple_ocr_sources_fallback')) {
      return 'ordered_sections_stitch_fallback';
    }
    if (hasMissingBottomEdgeAndTotalsEvidence) {
      return 'missing_bottom_edge_and_totals';
    }
    if (stitchSignalCounts.containsKey('stitched_ocr_source') ||
        stitchSignalCounts.containsKey('receipt_handoff_stitch_stitched')) {
      return 'stitched_ocr_source';
    }
    if (hasSavedPhotoBottomQualityRisk ||
        hasSavedPhotoDarkOrExposureRisk ||
        hasSavedPhotoSoftBlurRisk ||
        hasSavedPhotoGlareRisk ||
        hasSavedPhotoHazyLensRisk ||
        hasSavedPhotoShadowRisk ||
        hasBackupCaptureSourceRisk) {
      return 'scanner_prep_review_needed';
    }
    if (hasScannerPrepReviewRisk) return 'scanner_prep_review_needed';
    if (handoffSignalCounts.containsKey(
      'receipt_handoff_ready_for_receipt_review',
    )) {
      return 'ready_for_receipt_review';
    }
    return hasSignals ? 'handoff_signals_present' : 'no_handoff_signals';
  }

  String get sourceFirstDecisionStatus {
    for (final token in const [
      'ocr_source_first_ocr_source_missing_block_review',
      'ocr_source_first_saved_proof_fallback_review_required',
      'ocr_source_first_prepared_receipt_source_before_saved_proof',
      'ocr_source_first_temporary_full_quality_source_before_saved_proof',
      'ocr_source_first_separate_receipt_source_before_saved_proof',
      'ocr_source_first_accepted_receipt_source_before_saved_proof',
    ]) {
      if ((sourceFirstDecisionCounts[token] ?? 0) > 0) return token;
    }
    return 'ocr_source_first_unknown';
  }

  String get sourceFirstOutcomeStatus {
    for (final token in const [
      'ocr_source_first_outcome_ocr_source_not_ready',
      'ocr_source_first_outcome_fallback_saved_proof_review_required',
      'ocr_source_first_outcome_prepared_source_ready',
      'ocr_source_first_outcome_temporary_full_quality_ready',
      'ocr_source_first_outcome_separate_source_ready',
      'ocr_source_first_outcome_saved_source_matched_original',
    ]) {
      if ((sourceFirstOutcomeCounts[token] ?? 0) > 0) return token;
    }
    return 'ocr_source_first_outcome_unknown';
  }

  String get sourceReviewRiskStatus {
    for (final token in const [
      'ocr_source_review_risk_ocr_source_missing_manual_entry_required',
      'ocr_source_review_risk_saved_proof_ocr_fallback_review_required',
      'ocr_source_review_risk_scanner_preparation_review_required',
      'ocr_source_review_risk_ocr_source_ready',
    ]) {
      if ((sourceSignalCounts[token] ?? 0) > 0 ||
          (riskFlagCounts[token] ?? 0) > 0) {
        return token;
      }
    }
    return 'ocr_source_review_risk_unknown';
  }

  String get sourceReviewRequirementStatus {
    for (final token in const [
      'ocr_source_review_requirement_manual_review_required_before_saving_receipt',
      'ocr_source_review_requirement_standard_user_confirmation_required',
    ]) {
      if ((sourceSignalCounts[token] ?? 0) > 0 ||
          (riskFlagCounts[token] ?? 0) > 0) {
        return token;
      }
    }
    return 'ocr_source_review_requirement_unknown';
  }

  String get reviewDepthStatus {
    if ((reviewDepthSignalCounts['receipt_review_depth_detailedlines'] ?? 0) >
            0 ||
        (reviewDepthSignalCounts['receipt_review_depth_detailed_lines'] ?? 0) >
            0) {
      return 'detailed_lines';
    }
    if ((reviewDepthSignalCounts['receipt_review_depth_pricesonly'] ?? 0) > 0 ||
        (reviewDepthSignalCounts['receipt_review_depth_prices_only'] ?? 0) >
            0) {
      return 'prices_only';
    }
    if (reviewDepthSignalCounts.isNotEmpty) return 'review_depth_unknown';
    return 'review_depth_not_reported';
  }

  String get warningProfileStatus {
    for (final token in const [
      'receipt_handoff_warning_saved_photo_brightness_assist_failed_dark',
      'receipt_handoff_warning_saved_photo_darker_than_preview',
      'receipt_handoff_warning_saved_photo_soft_blur_risk',
      'receipt_handoff_warning_saved_photo_brighter_than_preview',
      'receipt_handoff_warning_saved_photo_glare_risk',
      'receipt_handoff_warning_saved_photo_bottom_too_dark',
      'receipt_handoff_warning_saved_photo_bottom_soft',
      'receipt_handoff_warning_saved_photo_dirty_lens_or_haze',
      'receipt_handoff_warning_saved_photo_shadow_risk',
      'receipt_handoff_warning_saved_photo_brightness_assist_still_dim',
      'receipt_handoff_warning_saved_photo_dimmer_than_preview',
    ]) {
      if ((handoffWarningProfileCounts[token] ?? 0) > 0) return token;
    }
    return 'receipt_handoff_warning_saved_photo_ok';
  }

  String get reviewCueStatus {
    final warning = warningProfileStatus;
    if (warning != 'receipt_handoff_warning_saved_photo_ok') {
      return warning.replaceFirst('receipt_handoff_warning_', '');
    }
    return status;
  }

  bool get hasSavedPhotoDarkOrExposureRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_darker_than_preview',
        'ocr_source_saved_photo_brightness_assist_failed_dark',
        'ocr_source_saved_photo_brightness_assist_still_dim',
        'ocr_source_saved_photo_dimmer_than_preview',
        'ocr_source_action_retake_with_more_light',
        'ocr_source_action_turn_on_light_or_retake',
        'ocr_source_action_check_text_or_add_light',
        'ocr_source_action_review_or_add_light',
        'ocr_source_parser_risk_ocr_text_or_total_may_fail',
        'ocr_source_parser_risk_ocr_text_may_need_review',
        'photo_quality_photo_is_too_dark',
        'photo_quality_photo_is_darker_than_ideal_for_receipt_assistance',
      ]) >
      0;

  bool get hasSavedPhotoSoftBlurRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_soft_blur_risk',
        'ocr_source_action_retake_hold_steady',
        'ocr_source_parser_risk_ocr_item_prices_may_fail',
        'photo_quality_photo_looks_blurry',
      ]) >
      0;

  bool get hasSavedPhotoGlareRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_brighter_than_preview',
        'ocr_source_saved_photo_glare_risk',
        'ocr_source_action_reduce_brightness_or_glare',
        'ocr_source_action_reduce_glare_or_retake',
        'ocr_source_parser_risk_ocr_washed_out_text_may_fail',
        'photo_quality_photo_has_glare_or_is_too_bright',
        'photo_quality_photo_is_bright_check_for_glare_before_continuing',
      ]) >
      0;

  bool get hasSavedPhotoBottomQualityRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_bottom_too_dark',
        'ocr_source_saved_photo_bottom_soft',
        'ocr_source_action_check_bottom_or_raise_brightness',
        'ocr_source_action_check_bottom_or_retake',
        'ocr_source_parser_risk_ocr_bottom_total_may_fail',
        'ocr_source_parser_risk_ocr_bottom_lines_may_fail',
      ]) >
      0;

  bool get hasSavedPhotoHazyLensRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_dirty_lens_or_haze',
        'ocr_source_action_wipe_lens_or_retake',
        'ocr_source_parser_risk_ocr_hazy_text_may_fail',
      ]) >
      0;

  bool get hasSavedPhotoShadowRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_shadow_risk',
        'ocr_source_action_move_to_even_light_or_retake',
        'ocr_source_parser_risk_ocr_shadowed_text_may_fail',
      ]) >
      0;

  bool get hasBackupCaptureSourceRisk =>
      _countForAny(photoQualityRiskCounts, const [
        'ocr_source_saved_photo_document_scanner_backup',
        'ocr_source_saved_photo_phone_camera_backup',
        'ocr_source_action_review_backup_scan_crop',
        'ocr_source_action_review_phone_backup_focus',
        'ocr_source_parser_risk_ocr_backup_scan_crop_may_need_review',
        'ocr_source_parser_risk_ocr_phone_backup_focus_may_need_review',
      ]) >
      0;

  bool get hasSectionOrderReviewRisk =>
      _countForAny(sectionOrderSignalCounts, const [
        'receipt_section_order_review_required',
        'ocr_source_section_order_review_required',
      ]) >
      0;

  bool get hasStitchContractReviewRisk =>
      stitchSignalCounts.containsKey(
        'stitch_ocr_source_contract_review_required',
      ) ||
      _countForPrefix(photoQualityRiskCounts, 'ocr_source_stitch_contract_') >
          0;

  String get sourceQualityReviewStatus {
    if (sourceReviewRiskStatus ==
            'ocr_source_review_risk_ocr_source_missing_manual_entry_required' ||
        sourceReviewRiskStatus ==
            'ocr_source_review_risk_saved_proof_ocr_fallback_review_required') {
      return 'ocr_source_fallback_review_required';
    }
    if (hasMissingBottomEdgeAndTotalsEvidence) {
      return 'missing_bottom_edge_and_totals_first';
    }
    if (hasStitchContractReviewRisk) {
      return 'stitch_contract_review_required';
    }
    if (hasSectionOrderReviewRisk) return 'section_order_review_required';
    if (hasSavedPhotoBottomQualityRisk) return 'saved_bottom_quality_review';
    if (hasSavedPhotoDarkOrExposureRisk) return 'saved_dark_exposure_review';
    if (hasSavedPhotoSoftBlurRisk) return 'saved_soft_blur_review';
    if (hasSavedPhotoGlareRisk) return 'saved_glare_review';
    if (hasSavedPhotoHazyLensRisk) return 'saved_hazy_lens_review';
    if (hasSavedPhotoShadowRisk) return 'saved_shadow_review';
    if (hasBackupCaptureSourceRisk) return 'backup_capture_review';
    if (hasScannerPrepReviewRisk) return 'scanner_prep_review_needed';
    return 'source_quality_ready_or_not_reported';
  }

  String get sourceQualityReviewAction {
    return switch (sourceQualityReviewStatus) {
      'missing_bottom_edge_and_totals_first' =>
        'add_bottom_section_with_ghost_slice',
      'ocr_source_fallback_review_required' =>
        'review_or_enter_receipt_manually',
      'section_order_review_required' => 'review_receipt_section_order',
      'stitch_contract_review_required' => 'review_receipt_stitch_sources',
      'saved_bottom_quality_review' => 'check_bottom_or_add_photo',
      'saved_dark_exposure_review' => 'retake_or_raise_brightness',
      'saved_soft_blur_review' => 'retake_hold_steady',
      'saved_glare_review' => 'reduce_glare_or_retake',
      'saved_hazy_lens_review' => 'wipe_lens_or_retake',
      'saved_shadow_review' => 'move_to_even_light_or_retake',
      'backup_capture_review' => 'check_backup_capture_crop_focus_totals',
      'scanner_prep_review_needed' => 'review_scanner_preparation',
      _ => 'review_receipt_if_needed',
    };
  }

  Map<String, Object?> get privacySafeContract {
    return Map.unmodifiable({
      'schema': 'receipt_ocr_source_handoff_v1',
      'status': status,
      if (handoffSignalCounts.isNotEmpty)
        'handoffSignalCounts': handoffSignalCounts,
      if (sourceFirstDecisionCounts.isNotEmpty)
        'sourceFirstDecisionCounts': sourceFirstDecisionCounts,
      if (sourceFirstDecisionCounts.isNotEmpty)
        'sourceFirstDecisionStatus': sourceFirstDecisionStatus,
      if (sourceFirstOutcomeCounts.isNotEmpty)
        'sourceFirstOutcomeCounts': sourceFirstOutcomeCounts,
      if (sourceFirstOutcomeCounts.isNotEmpty)
        'sourceFirstOutcomeStatus': sourceFirstOutcomeStatus,
      if (sourceReviewRiskStatus != 'ocr_source_review_risk_unknown')
        'sourceReviewRiskStatus': sourceReviewRiskStatus,
      if (sourceReviewRequirementStatus !=
          'ocr_source_review_requirement_unknown')
        'sourceReviewRequirementStatus': sourceReviewRequirementStatus,
      if (handoffWarningProfileCounts.isNotEmpty)
        'handoffWarningProfileCounts': handoffWarningProfileCounts,
      if (handoffWarningProfileCounts.isNotEmpty)
        'warningProfileStatus': warningProfileStatus,
      if (handoffWarningProfileCounts.isNotEmpty)
        'reviewCueStatus': reviewCueStatus,
      if (reviewDepthSignalCounts.isNotEmpty)
        'reviewDepthSignalCounts': reviewDepthSignalCounts,
      if (reviewDepthSignalCounts.isNotEmpty)
        'reviewDepthStatus': reviewDepthStatus,
      if (sectionOrderSignalCounts.isNotEmpty)
        'sectionOrderSignalCounts': sectionOrderSignalCounts,
      if (sourceQualityReviewStatus != 'source_quality_ready_or_not_reported')
        'sourceQualityReviewStatus': sourceQualityReviewStatus,
      if (sourceQualityReviewStatus != 'source_quality_ready_or_not_reported')
        'sourceQualityReviewAction': sourceQualityReviewAction,
      if (stitchSignalCounts.isNotEmpty)
        'stitchSignalCounts': stitchSignalCounts,
      if (scannerDecisionCounts.isNotEmpty)
        'scannerDecisionCounts': scannerDecisionCounts,
      if (captureSourceSignalCounts.isNotEmpty)
        'captureSourceSignalCounts': captureSourceSignalCounts,
      if (coverageSignalCounts.isNotEmpty)
        'coverageSignalCounts': coverageSignalCounts,
      if (continuationSignalCounts.isNotEmpty)
        'continuationSignalCounts': continuationSignalCounts,
      if (hasMissingBottomEdgeAndTotalsEvidence)
        'missingBottomTotalsEvidenceCode': missingBottomTotalsEvidenceCode,
      if (hasMissingBottomEdgeAndTotalsEvidence)
        'missingBottomTotalsEvidenceLabel': missingBottomTotalsEvidenceLabel,
      if (hasMissingBottomEdgeAndTotalsEvidence)
        'missingBottomTotalsEvidenceFamilyCount':
            missingBottomTotalsEvidenceFamilyCount,
      if (hasGhostSliceAlignmentContract)
        'ghostSliceAlignmentStatus': ghostSliceAlignmentStatus,
      if (hasGhostSliceAlignmentContract)
        'ghostSliceReviewInstruction': ghostSliceReviewInstruction,
      if (hasGhostSliceAlignmentContract)
        'ghostSlicePlacement': hasTopGhostSlicePlacement
            ? 'top_ghost_slice'
            : 'unknown',
      if (hasGhostSliceAlignmentContract)
        'ghostSliceRepeatTarget': hasRepeatLineGhostTarget
            ? 'repeat_3_to_5_readable_lines'
            : 'unknown',
      if (hasGhostSliceAlignmentContract)
        'ghostSliceMatchTarget': hasSubtotalTotalFinalLineMatchTarget
            ? 'subtotal_total_and_final_lines'
            : 'unknown',
      if (completionSignalCounts.isNotEmpty)
        'completionSignalCounts': completionSignalCounts,
      if (photoQualityRiskCounts.isNotEmpty)
        'photoQualityRiskCounts': photoQualityRiskCounts,
      if (riskFlagCounts.isNotEmpty) 'riskFlagCounts': riskFlagCounts,
    });
  }

  bool get hasScannerPrepReviewRisk {
    for (final risk in photoQualityRiskCounts.keys) {
      if (_isScannerPreparationRiskToken(risk)) return true;
    }
    for (final risk in riskFlagCounts.keys) {
      if (_isScannerPreparationRiskToken(risk)) return true;
    }
    return false;
  }

  int _countForAny(Map<String, int> counts, List<String> keys) {
    var total = 0;
    for (final key in keys) {
      total += counts[key] ?? 0;
    }
    return total;
  }

  int _countForPrefix(Map<String, int> counts, String prefix) {
    var total = 0;
    for (final entry in counts.entries) {
      if (entry.key.startsWith(prefix)) total += entry.value;
    }
    return total;
  }
}

bool _isScannerPreparationRiskToken(String value) {
  final normalized = value.toLowerCase();
  if (!normalized.startsWith('ocr_source_')) return false;
  return normalized.contains('quality_guard') ||
      normalized.contains('decode_failed') ||
      normalized.contains('skipped');
}

void _incrementOcrHandoffCount(Map<String, int> counts, String token) {
  if (token.isEmpty) return;
  counts[token] = (counts[token] ?? 0) + 1;
}

String _safeOcrHandoffToken(String value) {
  final buffer = StringBuffer();
  var lastWasUnderscore = false;
  for (final unit in value.trim().toLowerCase().codeUnits) {
    final isAlphaNumeric =
        (unit >= 97 && unit <= 122) || (unit >= 48 && unit <= 57);
    if (isAlphaNumeric) {
      buffer.writeCharCode(unit);
      lastWasUnderscore = false;
      continue;
    }
    if (!lastWasUnderscore) {
      buffer.write('_');
      lastWasUnderscore = true;
    }
  }
  return buffer.toString().replaceAll(RegExp(r'^_+|_+$'), '');
}

bool _isOcrCaptureSourceSignal(String token) {
  return token.startsWith('native_capture_source_') ||
      token.startsWith('native_capture_surface_') ||
      token.startsWith('native_capture_identity_');
}
