part of 'expense_receipt_parser.dart';

class ExpenseReceiptParseResult {
  const ExpenseReceiptParseResult({
    required this.sourceText,
    required this.lines,
    this.lineReviews = const [],
    this.merchantName,
    this.receiptDate,
    this.receiptTimeMinutes,
    this.enteredSubtotal,
    this.enteredTax,
    this.enteredTotal,
    this.quality = const ExpenseReceiptParseQuality(
      confidence: 0,
      needsReview: true,
      reasons: ['Receipt text has not been parsed yet.'],
    ),
    this.fieldConfidences = const {},
    this.maintenanceHints = const [],
    this.warnings = const [],
    this.diagnostics = const ExpenseReceiptParseDiagnostics(),
  });

  final String sourceText;
  final String? merchantName;
  final DateTime? receiptDate;
  final int? receiptTimeMinutes;
  final double? enteredSubtotal;
  final double? enteredTax;
  final double? enteredTotal;
  final ExpenseReceiptParseQuality quality;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;
  final List<ExpenseReceiptMaintenanceHint> maintenanceHints;
  final List<ExpenseReceiptLineRecord> lines;
  final List<ExpenseReceiptLineReview> lineReviews;
  final List<String> warnings;
  final ExpenseReceiptParseDiagnostics diagnostics;

  bool get hasUsableData {
    return merchantName != null ||
        receiptDate != null ||
        receiptTimeMinutes != null ||
        enteredSubtotal != null ||
        enteredTax != null ||
        enteredTotal != null ||
        lines.isNotEmpty;
  }

  ReceiptProcessingSnapshot processingSnapshot({
    ReceiptProcessingSource source = ReceiptProcessingSource.importedText,
    ReceiptSaveDestination destination = ReceiptSaveDestination.expenseOnly,
  }) {
    return ReceiptProcessingSnapshot(
      source: source,
      stage: ReceiptProcessingStage.parsed,
      destination: destination,
      lineCount: lines.length,
      needsReview: quality.needsReview,
      warningCount: warnings.length,
    );
  }
}

class ExpenseReceiptParseDiagnostics {
  const ExpenseReceiptParseDiagnostics({
    this.parserDepth = ReceiptParserDepth.inventoryMatching,
    this.maxCatalogCandidates = 80,
    this.detectedLineCount = 0,
    this.reviewLineCount = 0,
    this.catalogMatchedLineCount = 0,
    this.materialLineCount = 0,
    this.unmatchedMaterialLineCount = 0,
    this.negativeLineCount = 0,
    this.adjustmentLineCount = 0,
    this.lineSubtotal = 0,
    this.expectedSubtotalOrTotal,
    this.reconciliationDifference,
    this.taxMathDifference,
    this.reconciled = false,
    this.taxMathReconciled = false,
    this.hasExplicitSubtotal = false,
    this.hasExplicitTax = false,
    this.hasExplicitTotal = false,
    this.fieldConfidences = const {},
  });

  final ReceiptParserDepth parserDepth;
  final int maxCatalogCandidates;
  final int detectedLineCount;
  final int reviewLineCount;
  final int catalogMatchedLineCount;
  final int materialLineCount;
  final int unmatchedMaterialLineCount;
  final int negativeLineCount;
  final int adjustmentLineCount;
  final double lineSubtotal;
  final double? expectedSubtotalOrTotal;
  final double? reconciliationDifference;
  final double? taxMathDifference;
  final bool reconciled;
  final bool taxMathReconciled;
  final bool hasExplicitSubtotal;
  final bool hasExplicitTax;
  final bool hasExplicitTotal;
  final Map<String, ExpenseReceiptFieldConfidence> fieldConfidences;

  bool get hasLines => detectedLineCount > 0;
  bool get hasCatalogMatches => catalogMatchedLineCount > 0;
  bool get hasUnmatchedMaterials => unmatchedMaterialLineCount > 0;
  bool get hasAdjustments => adjustmentLineCount > 0;
  bool get hasCompleteExplicitTotals =>
      hasExplicitSubtotal && hasExplicitTax && hasExplicitTotal;

  ExpenseReceiptFieldConfidence? confidenceForField(String fieldKey) {
    return fieldConfidences[fieldKey];
  }

  double get reviewRatio {
    if (detectedLineCount == 0) return 0;
    return reviewLineCount / detectedLineCount;
  }

  bool get needsHeavyReview {
    return !reconciled ||
        (hasCompleteExplicitTotals && !taxMathReconciled) ||
        reviewRatio > .5 ||
        hasUnmatchedMaterials;
  }

  String get lineSummaryLabel {
    if (detectedLineCount == 0) return 'No line items parsed';
    final review = reviewLineCount == 0
        ? 'none need review'
        : '$reviewLineCount need review';
    return '$detectedLineCount parsed, $review';
  }

  String get catalogSummaryLabel {
    if (parserDepth != ReceiptParserDepth.inventoryMatching) {
      return 'Catalog matching skipped';
    }
    if (materialLineCount == 0) return 'No material lines';
    return '$catalogMatchedLineCount of $materialLineCount material lines matched';
  }

  String get reconciliationLabel {
    final expected = expectedSubtotalOrTotal;
    if (expected == null || detectedLineCount == 0) {
      return 'No subtotal reconciliation';
    }
    final diff = reconciliationDifference ?? 0;
    if (reconciled) return 'Line total matches receipt total';
    return 'Line total differs by \$${diff.abs().toStringAsFixed(2)}';
  }

  String get totalsMathLabel {
    if (!hasCompleteExplicitTotals) return 'Receipt total math incomplete';
    final diff = taxMathDifference ?? 0;
    if (taxMathReconciled) return 'Subtotal plus tax matches total';
    return 'Subtotal plus tax differs by \$${diff.abs().toStringAsFixed(2)}';
  }

  String get trustLabel {
    if (detectedLineCount == 0) return 'Totals only';
    if (!needsHeavyReview) return 'Ready to review';
    if (!reconciled || (hasCompleteExplicitTotals && !taxMathReconciled)) {
      return 'Needs receipt math review';
    }
    if (reviewRatio > .5) return 'Needs line review';
    if (hasUnmatchedMaterials) return 'Needs catalog review';
    return 'Needs review';
  }

  ExpenseReceiptParseDiagnostics copyWith({
    Map<String, ExpenseReceiptFieldConfidence>? fieldConfidences,
  }) {
    return ExpenseReceiptParseDiagnostics(
      parserDepth: parserDepth,
      maxCatalogCandidates: maxCatalogCandidates,
      detectedLineCount: detectedLineCount,
      reviewLineCount: reviewLineCount,
      catalogMatchedLineCount: catalogMatchedLineCount,
      materialLineCount: materialLineCount,
      unmatchedMaterialLineCount: unmatchedMaterialLineCount,
      negativeLineCount: negativeLineCount,
      adjustmentLineCount: adjustmentLineCount,
      lineSubtotal: lineSubtotal,
      expectedSubtotalOrTotal: expectedSubtotalOrTotal,
      reconciliationDifference: reconciliationDifference,
      taxMathDifference: taxMathDifference,
      reconciled: reconciled,
      taxMathReconciled: taxMathReconciled,
      hasExplicitSubtotal: hasExplicitSubtotal,
      hasExplicitTax: hasExplicitTax,
      hasExplicitTotal: hasExplicitTotal,
      fieldConfidences: fieldConfidences ?? this.fieldConfidences,
    );
  }
}

class ExpenseReceiptFieldConfidence {
  const ExpenseReceiptFieldConfidence({
    required this.fieldKey,
    required this.confidence,
    required this.needsReview,
    required this.reason,
  });

  final String fieldKey;
  final double confidence;
  final bool needsReview;
  final String reason;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get confidencePercentLabel => '${(confidence * 100).round()}%';
}

class ExpenseReceiptParseQuality {
  const ExpenseReceiptParseQuality({
    required this.confidence,
    required this.needsReview,
    required this.reasons,
  });

  final double confidence;
  final bool needsReview;
  final List<String> reasons;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get confidencePercentLabel => '${(confidence * 100).round()}%';
}

class ExpenseReceiptMaintenanceHint {
  const ExpenseReceiptMaintenanceHint({
    required this.itemName,
    required this.serviceType,
    required this.confidence,
    required this.evidence,
    this.detail,
    this.oilWeight,
    this.intervalMiles,
    this.intervalMonths,
    this.serviceOdometer,
    this.dueOdometer,
  });

  final String itemName;
  final String serviceType;
  final String? detail;
  final String? oilWeight;
  final int? intervalMiles;
  final int? intervalMonths;
  final int? serviceOdometer;
  final int? dueOdometer;
  final double confidence;
  final List<String> evidence;

  bool get needsReview => confidence < .84;

  String get label {
    if (confidence >= .84) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }
}

class ExpenseReceiptLineReview {
  const ExpenseReceiptLineReview({
    required this.lineId,
    required this.confidence,
    required this.needsReview,
    required this.reason,
    this.catalogItemName,
    this.catalogItemPath,
    this.catalogMatchConfidence,
    this.catalogMatchedTerms = const [],
  });

  final String lineId;
  final double confidence;
  final bool needsReview;
  final String reason;
  final String? catalogItemName;
  final String? catalogItemPath;
  final double? catalogMatchConfidence;
  final List<String> catalogMatchedTerms;

  bool get hasCatalogMatch => (catalogItemName ?? '').trim().isNotEmpty;

  String get label {
    if (confidence >= .84 && !needsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get guidance {
    return switch (label) {
      'Good' => 'Matched with strong confidence.',
      'Review' => 'Review this line before saving.',
      _ => 'Low confidence. Correct the category or receipt text.',
    };
  }
}
