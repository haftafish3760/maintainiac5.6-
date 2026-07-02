part of 'expense_receipt_parser.dart';

enum PrivacySafeReceiptEventType {
  receiptCaptureStarted,
  receiptCaptureCompleted,
  receiptCaptureAbandoned,
  receiptCaptureFailed,
  receiptOcrGood,
  receiptOcrReview,
  receiptOcrPartial,
  receiptOcrBlocked,
  receiptParserGood,
  receiptParserReview,
  receiptParserPoor,
  inventoryCatalogMatchWeak,
  receiptTotalsMismatch,
}

PrivacySafeReceiptEventType _typeForOcrSeverity(
  ReceiptOcrReviewSeverity severity,
) {
  return switch (severity) {
    ReceiptOcrReviewSeverity.good => PrivacySafeReceiptEventType.receiptOcrGood,
    ReceiptOcrReviewSeverity.review =>
      PrivacySafeReceiptEventType.receiptOcrReview,
    ReceiptOcrReviewSeverity.partial =>
      PrivacySafeReceiptEventType.receiptOcrPartial,
    ReceiptOcrReviewSeverity.blocked =>
      PrivacySafeReceiptEventType.receiptOcrBlocked,
  };
}

PrivacySafeReceiptEventType _typeForParseResult(
  ExpenseReceiptParseResult result,
) {
  final diagnostics = result.diagnostics;
  if (!diagnostics.reconciled &&
      diagnostics.detectedLineCount > 0 &&
      diagnostics.expectedSubtotalOrTotal != null) {
    return PrivacySafeReceiptEventType.receiptTotalsMismatch;
  }
  if (diagnostics.hasCompleteExplicitTotals &&
      !diagnostics.taxMathReconciled) {
    return PrivacySafeReceiptEventType.receiptTotalsMismatch;
  }
  if (diagnostics.materialLineCount > 0 && diagnostics.hasUnmatchedMaterials) {
    return PrivacySafeReceiptEventType.inventoryCatalogMatchWeak;
  }
  return switch (result.quality.label) {
    'Good' => PrivacySafeReceiptEventType.receiptParserGood,
    'Review' => PrivacySafeReceiptEventType.receiptParserReview,
    _ => PrivacySafeReceiptEventType.receiptParserPoor,
  };
}

String _qualityBucket(double confidence) {
  if (confidence >= .84) return 'high';
  if (confidence >= .58) return 'medium';
  return 'low';
}

String _totalsMathStatus(ExpenseReceiptParseDiagnostics diagnostics) {
  if (!diagnostics.hasCompleteExplicitTotals) return 'incomplete';
  return diagnostics.taxMathReconciled ? 'matched' : 'mismatch';
}

String? _parserReviewCause(ExpenseReceiptParseResult result) {
  final diagnostics = result.diagnostics;
  if (!result.hasUsableData) return 'receipt_parser_no_usable_fields';
  if (_hasDuplicateOverlapWarning(result)) {
    return 'receipt_possible_duplicate_overlap';
  }
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
  if (_wasFieldInferred(result.fieldConfidences['subtotal'])) {
    return 'receipt_subtotal_inferred';
  }
  if (_wasFieldInferred(result.fieldConfidences['tax'])) {
    return 'receipt_tax_inferred';
  }
  if (_wasFieldInferred(result.fieldConfidences['total'])) {
    return 'receipt_total_inferred';
  }
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

bool _hasDuplicateOverlapWarning(ExpenseReceiptParseResult result) {
  return result.warnings.any((warning) {
    final normalized = warning.toLowerCase();
    return normalized.contains('possible repeated receipt line') ||
        normalized.contains('check long-receipt overlap');
  });
}

List<String> _fieldReviewKeys(ExpenseReceiptParseResult result) {
  return List<String>.unmodifiable(
    result.fieldConfidences.values
        .where((field) => field.needsReview)
        .map((field) => _safeToken(field.fieldKey))
        .take(12),
  );
}

bool _wasFieldInferred(ExpenseReceiptFieldConfidence? field) {
  return field != null && field.reason.toLowerCase().contains('inferred');
}

bool _usedFallbackDate(ExpenseReceiptParseResult result) {
  final field = result.fieldConfidences['date'];
  return field != null &&
      field.reason.toLowerCase().contains('selected day as a fallback');
}

String _focusBucket(double focusScore) {
  if (focusScore >= 14) return 'sharp';
  if (focusScore >= 8) return 'usable';
  if (focusScore > 0) return 'soft';
  return 'unknown';
}

String _readabilityBucket(int reviewScore) {
  if (reviewScore >= 82) return 'high';
  if (reviewScore >= 58) return 'review';
  if (reviewScore > 0) return 'poor';
  return 'unknown';
}

String _safeToken(String value) {
  final clean = value.trim().toLowerCase();
  if (clean.isEmpty) return 'receipts';
  return clean.replaceAll(RegExp(r'[^a-z0-9_]+'), '_');
}
