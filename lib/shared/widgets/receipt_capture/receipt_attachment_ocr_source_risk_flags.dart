part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentOcrSourceRiskFlags
    on _SharedReceiptAttachmentPanelState {
  List<String> ocrSourceRiskFlagsFor(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final flags = <String>{};
    if (result.dataSaverLevel == ReceiptDataSaverLevel.strong ||
        result.dataSaverLevel == ReceiptDataSaverLevel.maximum) {
      flags.add('ocr_source_small_proof_copy_review_required');
      flags.add('ocr_source_proof_data_saver_${result.dataSaverLevel.name}');
    }
    final quality = qualityForOcrSourceIndex(result, index);
    if (quality != null) {
      flags.add(
        'ocr_source_quality_action_${attachmentSignalToken(quality.reviewActionCode)}',
      );
      flags.add(
        'ocr_source_quality_family_${attachmentSignalToken(quality.reviewActionFamily)}',
      );
      if (quality.shouldRetakeBeforeOcr) flags.add('ocr_source_retake_risk');
      if (quality.needsReview) flags.add('ocr_source_needs_review');
      if (quality.isTooDark || quality.isUnderexposedForReceipt) {
        flags.add('ocr_source_dark');
      }
      if (quality.isSoft || quality.isVerySoft) flags.add('ocr_source_soft');
      if (quality.isPoorlyFramed) flags.add('ocr_source_possible_cutoff');
    }
    for (final warning in savedPhotoWarningsForOcrSourceIndex(result, index)) {
      flags.add('ocr_source_${attachmentSignalToken(warning.code)}');
      flags.add(
        'ocr_source_action_${attachmentSignalToken(warning.actionCode)}',
      );
      flags.add(
        'ocr_source_parser_risk_${attachmentSignalToken(warning.parserRiskCode)}',
      );
      if (warning.isCritical) flags.add('ocr_source_native_critical_review');
    }
    final preparation =
        _previousReceiptPhotoMapValue(
          result.preparationDiagnosticsByOcrPath,
          result.ocrSourcePhotoPaths[index],
        ) ??
        const {};
    final scannerDecisionCodes = preparation['scannerDecisionCodes'];
    if (scannerDecisionCodes is Iterable) {
      for (final rawCode in scannerDecisionCodes) {
        final code = attachmentSignalToken(rawCode.toString());
        if (code.contains('quality_guard') ||
            code.contains('decode_failed') ||
            code.contains('skipped')) {
          flags.add('ocr_source_$code');
        }
      }
    }
    if (result.stitchResult.usedFallback) {
      flags.add('ocr_stitch_fallback_multiple_sources');
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
        'ocr_source_section_order_action_${attachmentSignalToken(result.receiptSectionOrderReviewActionCode)}',
      );
    }
    flags.add(
      'ocr_source_first_${attachmentSignalToken(result.ocrSourceFirstDecisionCode)}',
    );
    flags.add(
      'ocr_source_match_readiness_${attachmentSignalToken(result.nextReviewMatchReadinessOutcome)}',
    );
    for (final diagnostics in diagnosticsForOcrSourceIndex(result, index)) {
      final recoveryStatus = attachmentSignalToken(
        diagnostics['nativeRecoveryResumeStatus']?.toString() ?? '',
      );
      if (recoveryStatus != 'unknown') {
        flags.add('ocr_source_native_recovery_$recoveryStatus');
      }
      if (diagnostics['nativeRecoveryMultipleSections'] == true) {
        flags.add('ocr_source_native_recovery_multiple_sections');
      }
      if (diagnostics['userEditedPhoto'] == true) {
        final editAction = attachmentPhotoEditActionToken(
          diagnostics['photoEditAction'],
        );
        final sourceSelection = diagnostics['photoEditReplacedOriginal'] == true
            ? 'edited_copy_selected'
            : 'original_source_retained';
        flags.add('ocr_source_review_photo_edited');
        flags.add('ocr_source_review_photo_edit_$editAction');
        flags.add('ocr_source_review_photo_edit_source_selected');
        flags.add(
          'ocr_source_review_photo_edit_source_selected_$sourceSelection',
        );
        if (diagnostics['photoEditReplacedOriginal'] == true) {
          flags.add('ocr_source_review_photo_edit_replaced_original');
          flags.add(
            'ocr_source_review_photo_edit_replaced_original_$editAction',
          );
        }
      }
    }
    flags.addAll(ocrSourceContinuationRiskFlagsFor(result, index));
    flags.addAll(nativeCameraUiRiskFlagsFor(result));
    flags.addAll(nativeCloseCapturedPhotoRiskFlagsFor(result));
    flags.addAll(nativeCaptureSourcePolicyRiskFlagsFor(result));
    flags.addAll(receiptContinuationHandoffRiskFlagsFor(result));
    flags.addAll(receiptCompletionHandoffRiskFlagsFor(result));
    flags.addAll(receiptBrainRiskFlagsFor(result));
    return List.unmodifiable(flags);
  }
}
