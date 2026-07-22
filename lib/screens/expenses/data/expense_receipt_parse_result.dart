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

  double get lineSubtotal => lines.fold(0, (sum, line) => sum + line.subtotal);

  double get receiptSubtotal => enteredSubtotal ?? lineSubtotal;

  double get receiptTax {
    if (enteredTax != null) return enteredTax!;
    if (enteredTotal != null && enteredSubtotal != null) {
      return enteredTotal! - enteredSubtotal!;
    }
    return 0;
  }

  double get receiptTotal => enteredTotal ?? receiptSubtotal + receiptTax;

  double get receiptAdjustment => receiptTotal - lineSubtotal;

  double? get effectiveTaxRate {
    final subtotal = receiptSubtotal;
    if (subtotal <= 0 || receiptTax == 0) return null;
    return receiptTax / subtotal;
  }

  double get businessLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.businessAmount);

  double get personalLineSubtotal =>
      lines.fold(0, (sum, line) => sum + line.personalAmount);

  double get businessAdjustmentBase =>
      lines.fold(0, (sum, line) => sum + _positiveOnly(line.businessAmount));

  double get personalAdjustmentBase =>
      lines.fold(0, (sum, line) => sum + _positiveOnly(line.personalAmount));

  double get receiptAdjustmentBase =>
      businessAdjustmentBase + personalAdjustmentBase;

  double get businessTotal =>
      businessLineSubtotal +
      _allocatedReceiptAdjustment(businessAdjustmentBase);

  double get personalTotal =>
      personalLineSubtotal +
      _allocatedReceiptAdjustment(personalAdjustmentBase);

  double totalForLine(ExpenseReceiptLineRecord line) {
    return line.subtotal + _allocatedReceiptAdjustment(line.subtotal);
  }

  double businessTotalForLine(ExpenseReceiptLineRecord line) {
    return line.businessAmount +
        _allocatedReceiptAdjustment(_positiveOnly(line.businessAmount));
  }

  double personalTotalForLine(ExpenseReceiptLineRecord line) {
    return line.personalAmount +
        _allocatedReceiptAdjustment(_positiveOnly(line.personalAmount));
  }

  double _allocatedReceiptAdjustment(double adjustmentBase) {
    final totalBase = receiptAdjustmentBase;
    if (totalBase <= 0 || receiptAdjustment == 0 || adjustmentBase <= 0) {
      return 0;
    }
    return receiptAdjustment * (adjustmentBase / totalBase);
  }

  double _positiveOnly(double value) {
    return value > 0 ? value : 0;
  }

  ExpenseReceiptParseResult copyWith({
    String? merchantName,
    DateTime? receiptDate,
    int? receiptTimeMinutes,
    double? enteredSubtotal,
    double? enteredTax,
    double? enteredTotal,
    Map<String, ExpenseReceiptFieldConfidence>? fieldConfidences,
    List<ExpenseReceiptLineRecord>? lines,
    List<ExpenseReceiptLineReview>? lineReviews,
    List<String>? warnings,
    ExpenseReceiptParseDiagnostics? diagnostics,
  }) {
    return ExpenseReceiptParseResult(
      sourceText: sourceText,
      merchantName: merchantName ?? this.merchantName,
      receiptDate: receiptDate ?? this.receiptDate,
      receiptTimeMinutes: receiptTimeMinutes ?? this.receiptTimeMinutes,
      enteredSubtotal: enteredSubtotal ?? this.enteredSubtotal,
      enteredTax: enteredTax ?? this.enteredTax,
      enteredTotal: enteredTotal ?? this.enteredTotal,
      quality: quality,
      fieldConfidences: fieldConfidences ?? this.fieldConfidences,
      maintenanceHints: maintenanceHints,
      lines: lines ?? this.lines,
      lineReviews: lineReviews ?? this.lineReviews,
      warnings: warnings ?? this.warnings,
      diagnostics: diagnostics ?? this.diagnostics,
    );
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
