part of 'receipt_attachment_panel.dart';

extension _ReceiptAttachmentOcrSourceContinuationSignals
    on _SharedReceiptAttachmentPanelState {
  List<String> receiptContinuationHandoffDocumentSignalsFor(
    ReceiptPhotoReviewResult result,
  ) {
    final counts = result.receiptContinuationSignalCounts;
    if (counts.isEmpty) return const [];
    return List.unmodifiable({
      'receipt_continuation_handoff_${attachmentSignalToken(result.receiptContinuationHandoffStatus)}',
      for (final entry in counts.entries)
        'receipt_continuation_handoff_${attachmentSignalToken(entry.key)}',
    });
  }

  List<String> receiptContinuationHandoffRiskFlagsFor(
    ReceiptPhotoReviewResult result,
  ) {
    if (!result.hasOcrRequestedBottomSectionContinuation) return const [];
    return const [
      'ocr_source_continuation_ocr_requested_bottom_section_review',
    ];
  }

  List<String> receiptCompletionHandoffDocumentSignalsFor(
    ReceiptPhotoReviewResult result,
  ) {
    final counts = result.receiptCompletionChoiceCounts;
    if (counts.isEmpty) return const [];
    return List.unmodifiable({
      'receipt_completion_${attachmentSignalToken(result.receiptCompletionReviewOutcome)}',
      for (final entry in counts.entries)
        'receipt_completion_${attachmentSignalToken(entry.key)}',
    });
  }

  List<String> receiptCompletionHandoffRiskFlagsFor(
    ReceiptPhotoReviewResult result,
  ) {
    if (!result.userConfirmedPossiblePartialReceiptComplete) return const [];
    return const ['ocr_source_completion_continue_anyway_review'];
  }

  List<String> ocrSourceContinuationRiskFlagsFor(
    ReceiptPhotoReviewResult result,
    int index,
  ) {
    final flags = <String>{};
    for (final diagnostics in diagnosticsForOcrSourceIndex(result, index)) {
      if (diagnostics['previousSectionMissingBottomAndTotals'] == true) {
        flags.add('ocr_source_continuation_missing_bottom_totals_review');
      }
      final ghostStatus = attachmentSignalToken(
        diagnostics['receiptContinuationGhostGuideStatus']?.toString() ?? '',
      );
      if (ghostStatus == 'reason_without_prior_photo') {
        flags.add('ocr_source_continuation_reason_without_prior_photo');
      }
      if (ghostStatus == 'ready_with_previous_photo') {
        flags.add('ocr_source_continuation_ghost_guide_ready');
      }
      final ghostPolicy = attachmentSignalToken(
        diagnostics['previousSectionGhostGuidePolicy']?.toString() ?? '',
      );
      if (ghostPolicy == 'bottom_overlap_ghost_at_top_repeat_3_to_5_lines') {
        flags.add('ocr_source_continuation_bottom_overlap_ghost_policy');
      }
    }
    return List.unmodifiable(flags);
  }
}
