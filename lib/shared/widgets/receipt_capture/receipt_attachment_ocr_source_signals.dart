part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentOcrSourceSignals
    on _SharedReceiptAttachmentPanelState {
  List<String> ocrSourceDocumentSignalsFor(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final path = result.ocrSourcePhotoPaths[index];
    final preparation =
        _previousReceiptPhotoMapValue(
          result.preparationDiagnosticsByOcrPath,
          path,
        ) ??
        const {};
    final signals = <String>{
      'receipt_ocr_source_photo',
      'ocr_reads_prepared_source_not_saved_backup',
      'ocr_reads_clear_source_before_saved_proof',
      'ocr_source_first_${attachmentSignalToken(result.ocrSourceFirstDecisionCode)}',
      'ocr_source_first_outcome_${attachmentSignalToken(result.ocrSourceFirstOutcome)}',
      'ocr_source_review_risk_${attachmentSignalToken(result.ocrSourceReviewRiskCode)}',
      'ocr_source_review_requirement_${attachmentSignalToken(result.ocrSourceReviewRequirement)}',
      'linked_module_$_receiptAttachmentLinkedModule',
      'data_saver_${result.dataSaverLevel.name}',
      'proof_data_saver_${result.dataSaverLevel.name}',
      'receipt_review_depth_${attachmentSignalToken(result.nativeReceiptReviewDepth)}',
      'receipt_handoff_${attachmentSignalToken(result.acceptedPhotoHandoffOutcome)}',
      'receipt_handoff_warning_${attachmentSignalToken(result.acceptedPhotoWarningProfile)}',
      'receipt_section_order_${attachmentSignalToken(result.receiptSectionOrderOutcome)}',
      'receipt_section_order_action_${attachmentSignalToken(result.receiptSectionOrderReviewActionCode)}',
      'receipt_handoff_stitch_${attachmentSignalToken(result.stitchResult.status.name)}',
      'receipt_match_readiness_${attachmentSignalToken(result.nextReviewMatchReadinessOutcome)}',
      'receipt_proof_storage_${attachmentSignalToken(result.receiptProofStoragePolicyOutcome)}',
    };
    for (final entry in result.receiptProofStoragePolicyCounts.entries) {
      signals.add('receipt_proof_storage_${attachmentSignalToken(entry.key)}');
    }
    if (result.hasPossiblePartialReceiptPhotos) {
      signals.add('receipt_handoff_possible_partial_receipt');
    }
    if (result.receiptSectionOrderNeedsReview) {
      signals.add('receipt_section_order_review_required');
    }
    if (result.usesSeparateOcrSourceCopies) {
      signals.add('receipt_handoff_separate_ocr_source');
    }
    if (result.usedSavedProofAsOcrSourceFallback) {
      signals.add('receipt_handoff_ocr_source_fallback_saved_proof');
    }
    final scannerDecisionCodes = preparation['scannerDecisionCodes'];
    if (scannerDecisionCodes is Iterable) {
      for (final rawCode in scannerDecisionCodes) {
        final code = attachmentSignalToken(rawCode.toString());
        if (code != 'unknown') signals.add('scanner_decision_$code');
      }
    }
    final ocrSourcePath = preparation['ocrSourcePath']?.toString().trim();
    if (ocrSourcePath != null && ocrSourcePath.isNotEmpty) {
      signals.add('ocr_source_artifact_available');
    }
    if (result.stitchResult.didStitch) signals.add('stitched_ocr_source');
    if (result.stitchResult.usedFallback) {
      signals.add('multiple_ocr_sources_fallback');
    }
    if (!result.stitchResult.hasValidOcrSourceContract) {
      signals.add('stitch_ocr_source_contract_review_required');
    }
    signals.add(
      'stitch_overlap_${attachmentSignalToken(result.stitchResult.overlapCoverageCode)}',
    );
    signals.add(
      'stitch_ocr_source_contract_${attachmentSignalToken(result.stitchResult.ocrSourceContractCode)}',
    );
    signals.add(
      'stitch_source_${attachmentSignalToken(result.stitchResult.sourcePreservationCode)}',
    );
    signals.addAll(nativeCameraUiDocumentSignalsFor(result));
    signals.addAll(nativeCloseCapturedPhotoDocumentSignalsFor(result));
    signals.addAll(nativeCaptureSourcePolicyDocumentSignalsFor(result));
    signals.addAll(nativeReceiptCameraSurfaceDocumentSignalsFor(result));
    signals.addAll(receiptBrainDocumentSignalsFor(result));
    signals.addAll(receiptCoverageDecisionDocumentSignalsFor(result, index));
    signals.addAll(receiptContinuationHandoffDocumentSignalsFor(result));
    signals.addAll(receiptCompletionHandoffDocumentSignalsFor(result));
    signals.addAll(ocrSourceContinuationDocumentSignalsFor(result, index));
    for (final diagnostics in diagnosticsForOcrSourceIndex(result, index)) {
      final recoveryStatus = attachmentSignalToken(
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
        final editAction = attachmentPhotoEditActionToken(
          diagnostics['photoEditAction'],
        );
        final sourceSelection = diagnostics['photoEditReplacedOriginal'] == true
            ? 'edited_copy_selected'
            : 'original_source_retained';
        signals.add('review_photo_edited');
        signals.add('review_photo_edit_$editAction');
        signals.add('review_photo_edit_source_selected');
        signals.add('review_photo_edit_source_selected_$sourceSelection');
        if (diagnostics['photoEditReplacedOriginal'] == true) {
          signals.add('review_photo_edit_replaced_original');
          signals.add('review_photo_edit_replaced_original_$editAction');
        }
      }
    }
    final quality = qualityForOcrSourceIndex(result, index);
    if (quality != null) {
      signals.add(
        'ocr_quality_score_${qualityScoreBucket(quality.reviewScore)}',
      );
    }
    return List.unmodifiable(signals);
  }

  List<String> receiptCoverageDecisionDocumentSignalsFor(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final signals = <String>{};
    for (final diagnostics in diagnosticsForOcrSourceIndex(result, index)) {
      final decision = ReceiptPhotoCoverageDecision.fromSignals(
        quality: qualityForOcrSourceIndex(result, index),
        diagnostics: diagnostics,
      );
      signals.add(
        'receipt_coverage_${attachmentSignalToken(decision.reasonCode)}',
      );
      signals.add(
        'receipt_coverage_status_${attachmentSignalToken(decision.status.name)}',
      );
      signals.add(
        'receipt_coverage_evidence_${attachmentSignalToken(decision.evidenceContractCode)}',
      );
      signals.add(
        'receipt_coverage_rationale_${attachmentSignalToken(decision.evidenceRationaleCode)}',
      );
      signals.add(
        'receipt_coverage_contract_${attachmentSignalToken(decision.continuationCaptureContractCode)}',
      );
      if (decision.isMissingBottomEdgeAndTotals) {
        signals.add('receipt_coverage_bottom_edge_and_totals_missing_together');
        signals.add(
          'receipt_coverage_evidence_bottom_edge_missing_plus_totals_text_missing',
        );
        signals.add(
          'receipt_coverage_rationale_edge_missing_and_totals_text_missing',
        );
      }
    }
    return List.unmodifiable(signals);
  }

  List<String> ocrSourceContinuationDocumentSignalsFor(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final signals = <String>{};
    for (final diagnostics in diagnosticsForOcrSourceIndex(result, index)) {
      if (diagnostics['previousSectionGuideRequested'] == true) {
        signals.add('receipt_continuation_previous_section_guide_requested');
      }
      if (diagnostics['previousSectionGuidePhotoAvailable'] == true) {
        signals.add(
          'receipt_continuation_ghost_guide_previous_photo_available',
        );
      }
      if (diagnostics['previousSectionMissingBottomAndTotals'] == true) {
        signals.add('receipt_continuation_ocr_missing_bottom_totals');
        signals.add('receipt_continuation_missing_bottom_edge_and_totals');
      }
      if (diagnostics['previousSectionGuidanceAvailable'] == true) {
        signals.add('receipt_continuation_guidance_available');
      }
      final reason = attachmentSignalToken(
        _firstAttachmentContinuationSignalValue(
              diagnostics['previousSectionReasonCode'],
              diagnostics['phoneCameraBackupPreviousSectionReasonCode'],
            ) ??
            '',
      );
      if (reason != 'unknown') {
        signals.add('receipt_continuation_reason_$reason');
      }
      final source = attachmentSignalToken(
        diagnostics['receiptContinuationSource']?.toString() ?? '',
      );
      if (source != 'unknown' && source != 'none') {
        signals.add('receipt_continuation_source_$source');
      }
      final ghostStatus = attachmentSignalToken(
        diagnostics['receiptContinuationGhostGuideStatus']?.toString() ?? '',
      );
      if (ghostStatus != 'unknown' && ghostStatus != 'not_requested') {
        signals.add('receipt_continuation_ghost_$ghostStatus');
      }
      final ghostPolicy = attachmentSignalToken(
        _firstAttachmentContinuationSignalValue(
              diagnostics['previousSectionGhostGuidePolicy'],
              diagnostics['phoneCameraBackupPreviousSectionGhostGuidePolicy'],
            ) ??
            '',
      );
      if (ghostPolicy != 'unknown' && ghostPolicy != 'not_requested') {
        signals.add('receipt_continuation_ghost_policy_$ghostPolicy');
      }
    }
    return List.unmodifiable(signals);
  }
}

String? _firstAttachmentContinuationSignalValue(
  Object? primary,
  Object? fallback,
) {
  final primaryText = primary?.toString().trim();
  if (primaryText != null && primaryText.isNotEmpty) return primaryText;
  final fallbackText = fallback?.toString().trim();
  if (fallbackText != null && fallbackText.isNotEmpty) return fallbackText;
  return null;
}
