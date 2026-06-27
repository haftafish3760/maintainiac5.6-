import 'expense_receipt_parser.dart';
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
      failedAt: _failedAtFor(cause),
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

  static String _failedAtFor(String cause) {
    return switch (cause) {
      'receipt_parser_no_usable_fields' =>
        'after_ocr_text_before_receipt_fields',
      'receipt_line_total_mismatch' => 'receipt_line_reconciliation',
      'receipt_subtotal_tax_total_mismatch' => 'receipt_total_math_check',
      'receipt_totals_only_no_line_items' => 'receipt_line_detection',
      'receipt_total_missing' => 'receipt_total_detection',
      'receipt_subtotal_inferred' => 'receipt_total_math_inference',
      'receipt_tax_inferred' => 'receipt_total_math_inference',
      'receipt_total_inferred' => 'receipt_total_math_inference',
      'receipt_date_missing' => 'receipt_date_detection',
      'receipt_date_used_fallback' => 'receipt_date_fallback',
      'receipt_merchant_missing' => 'receipt_merchant_detection',
      'inventory_catalog_match_weak' => 'inventory_catalog_matching',
      'receipt_lines_need_review' => 'receipt_line_classification',
      _ => 'receipt_parser_quality_check',
    };
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
      _fieldReviewEvidence(result),
    ].join('_');
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
}
