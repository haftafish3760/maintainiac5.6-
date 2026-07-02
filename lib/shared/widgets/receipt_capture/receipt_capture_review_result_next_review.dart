part of 'receipt_capture_models.dart';

extension ReceiptPhotoReviewResultNextReview on ReceiptPhotoReviewResult {
  String get savedProofCountLabel {
    final count = photoPaths.length;
    return count == 1 ? '1 saved proof photo' : '$count saved proof photos';
  }

  bool get nextReviewUsesCombinedReceiptImage => stitchResult.didStitch;

  bool get nextReviewUsesOrderedSections =>
      stitchResult.usedFallback ||
      (!stitchResult.didStitch && ocrSourcePhotoPaths.length > 1);

  int get nextReviewSourceCount => ocrSourcePhotoPaths.length;

  String get nextReviewSourceLabel {
    if (nextReviewUsesCombinedReceiptImage) {
      return 'one combined receipt image';
    }
    if (nextReviewUsesOrderedSections) {
      return '$nextReviewSourceCount ordered receipt sections';
    }
    return nextReviewSourceCount == 1
        ? 'one receipt photo'
        : '$nextReviewSourceCount receipt photos';
  }

  String get nextReviewHandoffLabel {
    final safety = stitchResult.stitchSafetyLabel;
    if (needsAnotherReceiptSectionBeforeDetails) {
      if (firstPossiblePartialReceiptReasonCode ==
          'missing_bottom_edge_and_totals') {
        return '${_bottomGhostSliceHandoffInstruction(suffix: 'before receipt details unless this photo already shows the full receipt.')} $safety.';
      }
      return 'Add the next receipt section before receipt details unless this photo already shows the full receipt. $safety.';
    }
    if (nextReviewUsesCombinedReceiptImage) {
      return 'Next reviews $nextReviewSourceLabel. $safety.';
    }
    if (nextReviewUsesOrderedSections) {
      return 'Next reviews $nextReviewSourceLabel from top to bottom. $safety.';
    }
    return 'Next reviews $nextReviewSourceLabel. $safety.';
  }

  String get nextReviewDiagnosticLabel {
    final reason = stitchResult.diagnosticReasonLabel;
    final coverage = hasPossiblePartialReceiptPhotos
        ? 'possible_partial_receipt'
        : 'coverage_ok';
    final nextSection = needsAnotherReceiptSectionBeforeDetails
        ? 'needs_next_section'
        : 'details_ready';
    return '${stitchResult.status.name}:$reason:$coverage:$nextReviewSourceCount:$nextSection';
  }

  String get nextReviewMatchReadinessOutcome {
    if (!hasOcrSourcePhotos) return 'missing_ocr_source';
    if (needsAnotherReceiptSectionBeforeDetails) {
      return 'needs_next_receipt_section';
    }
    if (stitchResult.didStitch) return 'combined_receipt_image_ready';
    if (stitchResult.usedFallback) return 'ordered_sections_fallback_ready';
    if (nextReviewUsesOrderedSections) return 'ordered_sections_ready';
    return 'single_receipt_source_ready';
  }

  String get nextReviewMatchReadinessLabel {
    return switch (nextReviewMatchReadinessOutcome) {
      'combined_receipt_image_ready' =>
        'Photo match ready: one combined receipt image will be read.',
      'ordered_sections_fallback_ready' =>
        'Photo match fallback: ordered receipt sections will be read top to bottom.',
      'ordered_sections_ready' =>
        'Ordered receipt sections will be read top to bottom.',
      'missing_ocr_source' =>
        'No clear OCR source is ready for app-assisted receipt filling.',
      'needs_next_receipt_section' =>
        firstPossiblePartialReceiptReasonCode ==
                'missing_bottom_edge_and_totals'
            ? _bottomGhostSliceHandoffInstruction(
                suffix: 'or confirm this photo already shows the full receipt.',
              )
            : 'Add the next receipt section or confirm this photo already shows the full receipt.',
      _ => 'Single receipt source is ready for app-assisted review.',
    };
  }

  String get ocrSourceCountLabel {
    final count = ocrSourcePhotoPaths.length;
    if (count <= 0) return 'no clear OCR source';
    final source = stitchResult.didStitch ? 'combined OCR image' : 'OCR photo';
    return count == 1 ? '1 clear $source' : '$count clear ${source}s';
  }
}
