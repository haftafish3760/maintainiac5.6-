import 'expense_receipt_parser.dart';
import 'expense_parser_failure_stage.dart';
import 'expense_screen_telemetry.dart';

enum ExpenseParserTelemetryOutcome { completed, needsReview, failed }

class ExpenseParserFailureDiagnostics {
  const ExpenseParserFailureDiagnostics._();

  static ExpenseParserTelemetryOutcome outcomeFor(
    ExpenseReceiptParseResult result,
  ) {
    if (!result.hasUsableData || result.quality.label == 'Poor') {
      return ExpenseParserTelemetryOutcome.failed;
    }
    if (diagnosticFor(result) != null) {
      return ExpenseParserTelemetryOutcome.needsReview;
    }
    return ExpenseParserTelemetryOutcome.completed;
  }

  static ExpenseFailureDiagnostic? diagnosticFor(
    ExpenseReceiptParseResult result,
  ) {
    final cause = _confirmedCauseFor(result);
    if (cause == null) return null;
    return ExpenseFailureDiagnostic(
      workflowStep: ExpenseWorkflowStep.receiptParser,
      failedAt: ExpenseParserFailureStage.failedAtFor(cause),
      confirmedCause: cause,
      causeStatus: ExpenseFailureCauseStatus.confirmed,
      evidence: _evidenceFor(result),
      missingEvidence: 'none',
    );
  }

  static String? failureKindFor(ExpenseReceiptParseResult result) {
    return diagnosticFor(result)?.confirmedCause;
  }

  static String? _confirmedCauseFor(ExpenseReceiptParseResult result) {
    final diagnostics = result.diagnostics;
    final ocrTaskCause = _ocrParserTaskCauseFor(diagnostics);
    if (ocrTaskCause != null) return ocrTaskCause;
    final ocrSectionCause = _ocrSourceSectionCauseFor(diagnostics);
    if (ocrSectionCause != null) return ocrSectionCause;
    final ocrReadinessCause = _ocrParserReadinessCauseFor(
      diagnostics.ocrParserReadinessStatus,
    );
    if (ocrReadinessCause != null) return ocrReadinessCause;
    final receiptBrainLimitCause = _receiptBrainParserLimitCauseFor(
      diagnostics,
    );
    if (receiptBrainLimitCause != null) return receiptBrainLimitCause;
    if (diagnostics.shouldOfferDetailedParserPack) {
      return 'receipt_parser_optional_detail_pack_available';
    }
    if (!result.hasUsableData) return 'receipt_parser_no_usable_fields';
    if (diagnostics.detectedLineCount > 0 &&
        diagnostics.expectedSubtotalOrTotal != null &&
        !diagnostics.reconciled) {
      return 'receipt_line_total_mismatch';
    }
    if (diagnostics.hasCompleteExplicitTotals &&
        !diagnostics.taxMathReconciled) {
      return 'receipt_subtotal_tax_total_mismatch';
    }
    if (diagnostics.detectedLineCount == 0) {
      if (diagnostics.parserDownstreamReadinessCount(
            'totals_found_no_safe_lines',
          ) >
          0) {
        return 'receipt_parser_totals_found_no_safe_lines';
      }
      return 'receipt_totals_only_no_line_items';
    }
    if (result.enteredTotal == null && result.enteredSubtotal == null) {
      return 'receipt_total_missing';
    }
    final inferredTotalCause = _inferredTotalCauseFor(result);
    if (inferredTotalCause != null) return inferredTotalCause;
    if (result.receiptDate == null) return 'receipt_date_missing';
    if (_usedFallbackDate(result)) return 'receipt_date_used_fallback';
    if ((result.merchantName ?? '').trim().isEmpty) {
      return 'receipt_merchant_missing';
    }
    if (diagnostics.hasUnmatchedMaterials) {
      return 'inventory_catalog_match_weak';
    }
    if (diagnostics.reviewRatio > .5) return 'receipt_lines_need_review';
    if (result.quality.needsReview) return 'receipt_parser_low_confidence';
    return null;
  }

  static String _evidenceFor(ExpenseReceiptParseResult result) {
    final diagnostics = result.diagnostics;
    return [
      'quality_${result.quality.label.toLowerCase()}',
      'confidence_${(result.quality.confidence * 100).round()}',
      'lines_${diagnostics.detectedLineCount}',
      'review_${diagnostics.reviewLineCount}',
      'materials_${diagnostics.materialLineCount}',
      'unmatched_${diagnostics.unmatchedMaterialLineCount}',
      'adjustments_${diagnostics.adjustmentLineCount}',
      'negative_${diagnostics.negativeLineCount}',
      'reconciled_${diagnostics.reconciled}',
      'tax_${diagnostics.taxMathReconciled}',
      'totals_${diagnostics.hasCompleteExplicitTotals}',
      _mathDifferenceEvidence(diagnostics),
      'ocr_readiness_${diagnostics.ocrParserReadinessStatus}',
      'ocr_downstream_${diagnostics.ocrDownstreamReadinessStatus}',
      'ocr_ready_${diagnostics.ocrParserReadyLineCount}',
      'ocr_review_${diagnostics.ocrParserReviewSignalCount}',
      'ocr_priced_${diagnostics.ocrPricedLineCount}',
      'ocr_structure_${diagnostics.ocrReceiptStructureStatus}',
      'ocr_sections_${diagnostics.ocrSourceSectionContinuityStatus}',
      'local_route_${diagnostics.localReceiptParserRoutingCode}',
      'local_kept_${diagnostics.keepsSimpleReceiptLocal}',
      'optional_pack_${diagnostics.shouldOfferDetailedParserPack}',
      'local_parser_evidence_${diagnostics.localParserEvidenceOutcome}',
      'brain_limit_${diagnostics.receiptBrainParserLimitOutcome}',
      _ocrParserTaskEvidence(diagnostics),
      _fieldReviewEvidence(result),
    ].join('_');
  }

  static String _mathDifferenceEvidence(
    ExpenseReceiptParseDiagnostics diagnostics,
  ) {
    final lineDifference = _differenceBucket(
      diagnostics.expectedSubtotalOrTotal == null
          ? null
          : diagnostics.lineSubtotal - diagnostics.expectedSubtotalOrTotal!,
    );
    final summaryDifference = _differenceBucket(diagnostics.taxMathDifference);
    final explicitFields = [
      if (diagnostics.hasExplicitSubtotal) 'subtotal',
      if (diagnostics.hasExplicitTax) 'tax',
      if (diagnostics.hasExplicitTotal) 'total',
    ];
    final explicitLabel = explicitFields.isEmpty
        ? 'explicit_none'
        : 'explicit_${explicitFields.join('|')}';
    return 'line_diff_$lineDifference'
        '_summary_diff_$summaryDifference'
        '_$explicitLabel';
  }

  static String _differenceBucket(double? difference) {
    if (difference == null) return 'unknown';
    final cents = (difference.abs() * 100).round();
    if (cents == 0) return 'zero';
    if (cents <= 25) return 'under_25c';
    if (cents <= 100) return 'under_1dollar';
    if (cents <= 500) return 'under_5dollars';
    if (cents <= 2000) return 'under_20dollars';
    return 'over_20dollars';
  }

  static String? _ocrParserTaskCauseFor(
    ExpenseReceiptParseDiagnostics diagnostics,
  ) {
    final tasks = diagnostics.ocrParserTaskCounts;
    if ((tasks['vendor_missing'] ?? 0) > 0) {
      return 'receipt_ocr_missing_vendor';
    }
    if ((tasks['date_missing'] ?? 0) > 0) return 'receipt_ocr_missing_date';
    if ((tasks['ocr_no_readable_text'] ?? 0) > 0) {
      return 'receipt_ocr_no_readable_text';
    }
    if ((tasks['photo_read_failed'] ?? 0) > 0) {
      return 'receipt_ocr_photo_read_failed';
    }
    if ((tasks['photo_tiny_text_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_tiny_text';
    }
    if ((tasks['photo_small_proof_review'] ?? 0) > 0) {
      return 'receipt_ocr_small_proof_copy';
    }
    if ((tasks['photo_retake_recommended_review'] ?? 0) > 0 ||
        (tasks['photo_quality_retake_family_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_retake_recommended';
    }
    if ((tasks['photo_crop_or_retake_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_crop_or_retake';
    }
    if ((tasks['photo_readability_or_closer_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_readability_or_closer';
    }
    if ((tasks['photo_saved_bottom_quality_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_saved_bottom_quality';
    }
    if ((tasks['photo_saved_dark_or_exposure_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_saved_dark_or_exposure';
    }
    if ((tasks['photo_saved_soft_blur_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_saved_soft_blur';
    }
    if ((tasks['photo_saved_glare_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_saved_glare';
    }
    if ((tasks['photo_quality_review'] ?? 0) > 0) {
      return 'receipt_ocr_photo_quality_review';
    }
    if ((tasks['long_receipt_section_gap'] ?? 0) > 0) {
      return 'receipt_ocr_long_receipt_section_gap';
    }
    if ((tasks['long_receipt_probable_overlap'] ?? 0) > 0) {
      return 'receipt_ocr_long_receipt_probable_overlap';
    }
    if ((tasks['long_receipt_duplicate_text'] ?? 0) > 0) {
      return 'receipt_ocr_long_receipt_duplicate_text';
    }
    if ((tasks['total_missing'] ?? 0) > 0) return 'receipt_ocr_missing_total';
    if ((tasks['summary_missing'] ?? 0) > 0) {
      return 'receipt_ocr_missing_summary';
    }
    if ((tasks['tax_missing'] ?? 0) > 0) return 'receipt_ocr_missing_tax';
    if ((tasks['item_price_missing'] ?? 0) > 0) {
      return 'receipt_ocr_no_priced_lines';
    }
    if ((tasks['item_price_ready_missing'] ?? 0) > 0) {
      return 'receipt_ocr_no_parser_ready_items';
    }
    if ((tasks['line_sequence_needs_review'] ?? 0) > 0) {
      return 'receipt_ocr_line_sequence_review';
    }
    if ((tasks['summary_math_needs_review'] ?? 0) > 0) {
      return 'receipt_ocr_summary_math_review';
    }
    if ((tasks['item_price_review_required'] ?? 0) > 0) {
      return 'receipt_ocr_parser_readiness_review';
    }
    return null;
  }

  static String? _receiptBrainParserLimitCauseFor(
    ExpenseReceiptParseDiagnostics diagnostics,
  ) {
    if (diagnostics.hasReceiptBrainBaseInstallStorageBlock) {
      return 'receipt_parser_base_install_blocks_low_storage';
    }
    if (!diagnostics.shouldOfferDetailedParserPack &&
        !diagnostics.hasParserCategoryPackLimits) {
      return null;
    }
    if (diagnostics.hasReceiptBrainFullOfflineTooLargeForStorage) {
      return 'receipt_parser_full_offline_too_large_optional_only';
    }
    if (diagnostics.hasReceiptBrainOptionalPackDeferredForStorage) {
      return 'receipt_parser_optional_pack_deferred_for_storage';
    }
    return null;
  }

  static String? _ocrParserReadinessCauseFor(String status) {
    return switch (status) {
      'missing_vendor' => 'receipt_ocr_missing_vendor',
      'missing_total' => 'receipt_ocr_missing_total',
      'no_priced_lines' => 'receipt_ocr_no_priced_lines',
      'no_item_lines' => 'receipt_ocr_no_item_lines',
      'no_parser_ready_items' => 'receipt_ocr_no_parser_ready_items',
      'needs_review' => 'receipt_ocr_parser_readiness_review',
      'no_text' => 'receipt_parser_no_usable_fields',
      'receipt_ready' || 'inventory_ready' || 'unknown' || '' => null,
      _ => 'receipt_ocr_parser_readiness_review',
    };
  }

  static String? _ocrSourceSectionCauseFor(
    ExpenseReceiptParseDiagnostics diagnostics,
  ) {
    if (!diagnostics.hasOcrSourceSectionReview) return null;
    return switch (diagnostics.ocrSourceSectionContinuityStatus) {
      'out_of_order_sections' => 'receipt_ocr_source_sections_out_of_order',
      'missing_first_section' ||
      'missing_section_gap' => 'receipt_ocr_source_sections_missing',
      'partial_source_sections' => 'receipt_ocr_source_sections_partial',
      _ => 'receipt_ocr_source_sections_partial',
    };
  }

  static String? _inferredTotalCauseFor(ExpenseReceiptParseResult result) {
    final fields = result.fieldConfidences;
    if (_wasFieldInferred(fields['subtotal'])) {
      return 'receipt_subtotal_inferred';
    }
    if (_wasFieldInferred(fields['tax'])) return 'receipt_tax_inferred';
    if (_wasFieldInferred(fields['total'])) return 'receipt_total_inferred';
    return null;
  }

  static bool _wasFieldInferred(ExpenseReceiptFieldConfidence? field) {
    return field != null && field.reason.toLowerCase().contains('inferred');
  }

  static bool _usedFallbackDate(ExpenseReceiptParseResult result) {
    final field = result.fieldConfidences['date'];
    return field != null &&
        field.reason.toLowerCase().contains('selected day as a fallback');
  }

  static String _fieldReviewEvidence(ExpenseReceiptParseResult result) {
    final reviewed = result.fieldConfidences.values
        .where((field) => field.needsReview)
        .map((field) => '${field.fieldKey}_${field.label.toLowerCase()}')
        .toList(growable: false);
    if (reviewed.isEmpty) return 'field_review_none';
    return 'field_review_${reviewed.take(6).join('|')}';
  }

  static String _ocrParserTaskEvidence(
    ExpenseReceiptParseDiagnostics diagnostics,
  ) {
    if (diagnostics.ocrParserTaskCounts.isEmpty) return 'ocr_tasks_none';
    final taskKeys = diagnostics.ocrParserTaskCounts.keys.toSet();
    final ordered = <String>[
      for (final task in _priorityOcrParserEvidenceTasks)
        if (taskKeys.remove(task)) task,
      ...((taskKeys.toList())..sort()),
    ];
    return 'ocr_tasks_${ordered.take(12).join('|')}';
  }

  static const List<String> _priorityOcrParserEvidenceTasks = [
    'photo_retake_recommended_review',
    'photo_quality_retake_family_review',
    'photo_crop_or_retake_review',
    'photo_readability_or_closer_review',
    'photo_saved_bottom_quality_review',
    'photo_saved_dark_or_exposure_review',
    'photo_saved_soft_blur_review',
    'photo_saved_glare_review',
    'photo_quality_review',
    'photo_read_failed',
    'photo_tiny_text_review',
    'photo_small_proof_review',
    'long_receipt_section_gap',
    'long_receipt_probable_overlap',
    'long_receipt_duplicate_text',
    'receipt_bottom_complete_ready',
    'receipt_summary_totals_ready',
    'receipt_footer_or_barcode_seen',
    'summary_missing',
    'total_missing',
    'tax_missing',
    'item_price_missing',
    'item_price_ready_missing',
    'item_price_review_required',
    'line_sequence_needs_review',
    'summary_math_needs_review',
  ];
}
