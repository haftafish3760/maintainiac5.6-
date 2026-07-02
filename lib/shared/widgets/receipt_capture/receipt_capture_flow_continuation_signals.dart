part of 'receipt_capture_flow.dart';

List<String> _receiptCoverageDecisionDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final signals = <String>{};
  for (final diagnostics in _diagnosticsForOcrSourceIndex(result, index)) {
    final decision = ReceiptPhotoCoverageDecision.fromSignals(
      quality: _qualityForOcrSourceIndex(result, index),
      diagnostics: diagnostics,
    );
    signals.add('receipt_coverage_${_signalToken(decision.reasonCode)}');
    signals.add(
      'receipt_coverage_status_${_signalToken(decision.status.name)}',
    );
    signals.add(
      'receipt_coverage_evidence_${_signalToken(decision.evidenceContractCode)}',
    );
    signals.add(
      'receipt_coverage_rationale_${_signalToken(decision.evidenceRationaleCode)}',
    );
    signals.add(
      'receipt_coverage_contract_${_signalToken(decision.continuationCaptureContractCode)}',
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

List<String> _ocrSourceContinuationDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final signals = <String>{};
  for (final diagnostics in _diagnosticsForOcrSourceIndex(result, index)) {
    if (diagnostics['previousSectionGuideRequested'] == true) {
      signals.add('receipt_continuation_previous_section_guide_requested');
    }
    if (diagnostics['previousSectionGuidePhotoAvailable'] == true) {
      signals.add('receipt_continuation_ghost_guide_previous_photo_available');
    }
    if (diagnostics['previousSectionMissingBottomAndTotals'] == true) {
      signals.add('receipt_continuation_ocr_missing_bottom_totals');
      signals.add('receipt_continuation_missing_bottom_edge_and_totals');
    }
    if (diagnostics['previousSectionGuidanceAvailable'] == true) {
      signals.add('receipt_continuation_guidance_available');
    }
    final reason = _signalToken(
      diagnostics['previousSectionReasonCode']?.toString() ?? '',
    );
    if (reason != 'unknown') {
      signals.add('receipt_continuation_reason_$reason');
    }
    final source = _signalToken(
      diagnostics['receiptContinuationSource']?.toString() ?? '',
    );
    if (source != 'unknown' && source != 'none') {
      signals.add('receipt_continuation_source_$source');
    }
    final ghostStatus = _signalToken(
      diagnostics['receiptContinuationGhostGuideStatus']?.toString() ?? '',
    );
    if (ghostStatus != 'unknown' && ghostStatus != 'not_requested') {
      signals.add('receipt_continuation_ghost_$ghostStatus');
    }
    final ghostPolicy = _signalToken(
      diagnostics['previousSectionGhostGuidePolicy']?.toString() ?? '',
    );
    if (ghostPolicy != 'unknown' && ghostPolicy != 'not_requested') {
      signals.add('receipt_continuation_ghost_policy_$ghostPolicy');
    }
  }
  return List.unmodifiable(signals);
}

List<String> _receiptContinuationHandoffDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.receiptContinuationSignalCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    'receipt_continuation_handoff_${_signalToken(result.receiptContinuationHandoffStatus)}',
    for (final entry in counts.entries)
      'receipt_continuation_handoff_${_signalToken(entry.key)}',
  });
}

List<String> _receiptContinuationHandoffRiskFlagsFor(
  ReceiptPhotoReviewResult result,
) {
  if (!result.hasOcrRequestedBottomSectionContinuation) return const [];
  return const ['ocr_source_continuation_ocr_requested_bottom_section_review'];
}

List<String> _receiptCompletionHandoffDocumentSignalsFor(
  ReceiptPhotoReviewResult result,
) {
  final counts = result.receiptCompletionChoiceCounts;
  if (counts.isEmpty) return const [];
  return List.unmodifiable({
    'receipt_completion_${_signalToken(result.receiptCompletionReviewOutcome)}',
    for (final entry in counts.entries)
      'receipt_completion_${_signalToken(entry.key)}',
  });
}

List<String> _receiptCompletionHandoffRiskFlagsFor(
  ReceiptPhotoReviewResult result,
) {
  if (!result.userConfirmedPossiblePartialReceiptComplete) return const [];
  return const ['ocr_source_completion_continue_anyway_review'];
}

List<String> _ocrSourceContinuationRiskFlagsFor(
  ReceiptPhotoReviewResult result,
  int index,
) {
  final flags = <String>{};
  for (final diagnostics in _diagnosticsForOcrSourceIndex(result, index)) {
    if (diagnostics['previousSectionMissingBottomAndTotals'] == true) {
      flags.add('ocr_source_continuation_missing_bottom_totals_review');
    }
    final ghostStatus = _signalToken(
      diagnostics['receiptContinuationGhostGuideStatus']?.toString() ?? '',
    );
    if (ghostStatus == 'reason_without_prior_photo') {
      flags.add('ocr_source_continuation_reason_without_prior_photo');
    }
    if (ghostStatus == 'ready_with_previous_photo') {
      flags.add('ocr_source_continuation_ghost_guide_ready');
    }
    final ghostPolicy = _signalToken(
      diagnostics['previousSectionGhostGuidePolicy']?.toString() ?? '',
    );
    if (ghostPolicy == 'bottom_overlap_ghost_at_top_repeat_3_to_5_lines') {
      flags.add('ocr_source_continuation_bottom_overlap_ghost_policy');
    }
  }
  return List.unmodifiable(flags);
}
