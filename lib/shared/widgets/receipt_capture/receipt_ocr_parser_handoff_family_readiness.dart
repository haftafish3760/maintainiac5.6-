part of '../../receipts/receipt_ocr_contract.dart';

extension ReceiptOcrParserHandoffFamilyReadiness on ReceiptOcrParserHandoff {
  Map<String, List<String>> get itemLineIdsByExpenseFamily {
    final result = <String, List<String>>{};
    for (final line in itemLines) {
      final family = _receiptExpenseFamilyToken(line.expenseFamily);
      result.putIfAbsent(family, () => <String>[]).add(line.stableLineId);
    }
    return Map.unmodifiable({
      for (final entry in result.entries)
        entry.key: List<String>.unmodifiable(entry.value),
    });
  }

  List<String> get presentExpenseFamilies {
    final families = expenseFamilyCounts.entries.toList()
      ..sort((left, right) {
        final countCompare = right.value.compareTo(left.value);
        if (countCompare != 0) return countCompare;
        return left.key.compareTo(right.key);
      });
    return List<String>.unmodifiable(families.map((entry) => entry.key));
  }

  String get dominantExpenseFamily {
    final families = presentExpenseFamilies;
    return families.isEmpty ? 'none' : families.first;
  }

  bool get hasMixedExpenseFamilies => presentExpenseFamilies.length > 1;

  String get itemExpenseFamilyStatus {
    if (itemLines.isEmpty) return 'no_item_families';
    if (hasMixedExpenseFamilies) return 'mixed_item_families';
    if (dominantExpenseFamily == 'general_expense') {
      return 'single_general_expense_family';
    }
    return 'single_${dominantExpenseFamily}_family';
  }

  String get itemExpenseFamilySummaryLabel {
    final families = presentExpenseFamilies;
    if (families.isEmpty) return 'No local item family hints';
    final visible = families
        .take(3)
        .map(_receiptExpenseFamilyDisplayLabel)
        .join(', ');
    final extra = families.length > 3 ? ', +${families.length - 3} more' : '';
    final prefix = hasMixedExpenseFamilies
        ? 'Mixed receipt families'
        : 'Receipt family';
    return '$prefix: $visible$extra';
  }

  Map<String, Object?> get itemExpenseFamilyDiagnostics {
    return Map.unmodifiable({
      'status': itemExpenseFamilyStatus,
      'dominantExpenseFamily': dominantExpenseFamily,
      'presentExpenseFamilies': presentExpenseFamilies,
      'expenseFamilyCounts': expenseFamilyCounts,
      'itemLineIdsByExpenseFamily': itemLineIdsByExpenseFamily,
      'mixedExpenseFamilies': hasMixedExpenseFamilies,
      'summaryLabel': itemExpenseFamilySummaryLabel,
    });
  }

  bool get hasMixedClassificationSummaryBasis =>
      primaryTotalAmount != null ||
      primarySubtotalAmount != null ||
      summaryLines.isNotEmpty;

  String get mixedClassificationReadinessStatus {
    if (lines.isEmpty) return 'no_text';
    if (itemLines.isEmpty) return 'needs_line_items';
    if (parserReadyLineCount == 0) return 'needs_safe_item_prices';
    if (!hasMixedClassificationSummaryBasis) return 'needs_receipt_total';
    if (needsSourceSectionContinuityReview) return 'needs_section_order_review';
    if (needsLineSequenceReview) return 'needs_line_order_review';
    if (hasCompleteSummaryAmounts && !summaryMathReconciled) {
      return 'needs_summary_math_review';
    }
    if (reviewItemLineCount > 0) return 'ready_with_line_review';
    return 'ready';
  }

  bool get mixedClassificationReady =>
      mixedClassificationReadinessStatus == 'ready' ||
      mixedClassificationReadinessStatus == 'ready_with_line_review';

  String get mixedClassificationEvidenceLabel {
    return switch (mixedClassificationReadinessStatus) {
      'ready' =>
        'mixed_classification_ready: line prices and receipt total are ready',
      'ready_with_line_review' =>
        'mixed_classification_review: some line prices need review before split totals are trusted',
      'needs_receipt_total' =>
        'mixed_classification_needs_total: add/check the bottom totals section',
      'needs_line_items' =>
        'mixed_classification_needs_lines: no item lines were safe enough',
      'needs_safe_item_prices' =>
        'mixed_classification_needs_safe_prices: item lines need review before classification',
      'needs_section_order_review' =>
        'mixed_classification_needs_section_order: receipt sections need review',
      'needs_line_order_review' =>
        'mixed_classification_needs_line_order: receipt line order needs review',
      'needs_summary_math_review' =>
        'mixed_classification_needs_math_review: subtotal, tax, and total need review',
      'no_text' => 'mixed_classification_no_text: no readable receipt text',
      _ => 'mixed_classification_needs_review',
    };
  }

  Map<String, Object?> get mixedClassificationEvidenceDiagnostics {
    return Map.unmodifiable({
      'status': mixedClassificationReadinessStatus,
      'ready': mixedClassificationReady,
      'itemLineCount': itemLines.length,
      'readyItemLineCount': parserReadyLineCount,
      'reviewItemLineCount': reviewItemLineCount,
      'summaryLineCount': summaryLines.length,
      'hasSummaryBasis': hasMixedClassificationSummaryBasis,
      'summaryMathStatus': summaryMathStatus,
      'lineSequenceStatus': lineSequenceStatus,
      'sourceSectionContinuityStatus': sourceSectionContinuityStatus,
      'sourceSectionCount': sourceSectionCount,
    });
  }
}
