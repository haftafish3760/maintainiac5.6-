part of 'expense_receipt_entry_screen.dart';

class _ExpenseReceiptLine {
  const _ExpenseReceiptLine({
    this.id,
    required this.description,
    required this.category,
    required this.use,
    required this.quantity,
    required this.unitsPerPackage,
    required this.stockUnit,
    required this.subtotal,
    this.businessPercent,
    this.splitAllocationMethod = ExpenseSplitAllocationMethod.percentage,
    this.businessSplitValue,
    this.splitConfirmed = true,
    this.odometerReading,
    this.fuelType,
    this.fillType,
    this.unitPrice,
    this.rawReceiptText = '',
    this.catalogItemId,
    this.catalogItemName,
    this.catalogItemPath,
    this.catalogMatchConfidence,
    this.catalogMatchedTerms = const [],
    this.parserConfidence,
    this.parserReviewLabel,
    this.parserReviewReason,
    this.parserNeedsReview = false,
    this.ocrSourceLineId,
    this.ocrSourceLineNumber,
    this.ocrSourceSectionNumber,
    this.ocrSourceSectionLineNumber,
    this.parserExpenseFamily,
    this.parserHint,
  });

  factory _ExpenseReceiptLine.blank({
    _ExpenseLineUse use = _ExpenseLineUse.business,
    String category = 'Uncategorized',
  }) {
    return _ExpenseReceiptLine(
      description: '',
      category: category,
      use: use,
      quantity: 1,
      unitsPerPackage: 1,
      stockUnit: 'each',
      subtotal: 0,
      fuelType: category == 'Fuel' ? 'Gasoline' : null,
      fillType: category == 'Fuel' ? 'Full fill-up' : null,
    );
  }

  factory _ExpenseReceiptLine.fromLedgerLine(ExpenseReceiptLineRecord line) {
    return _ExpenseReceiptLine(
      id: line.id,
      description: line.description,
      category: line.category,
      use: switch (line.use) {
        ExpenseLineUse.business => _ExpenseLineUse.business,
        ExpenseLineUse.personal => _ExpenseLineUse.personal,
        ExpenseLineUse.split => _ExpenseLineUse.split,
        ExpenseLineUse.unclassified => _ExpenseLineUse.unclassified,
      },
      quantity: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      stockUnit: line.unit,
      subtotal: line.subtotal,
      businessPercent: line.businessPercent,
      splitAllocationMethod: line.splitAllocationMethod,
      businessSplitValue: line.businessSplitValue,
      splitConfirmed: line.splitConfirmed,
      odometerReading: line.odometerReading,
      fuelType: line.fuelType,
      fillType: line.fillType,
      unitPrice: line.unitPrice,
      rawReceiptText: line.rawReceiptText,
      catalogItemId: line.catalogItemId,
      catalogItemName: line.catalogItemName,
      catalogItemPath: line.catalogItemPath,
      catalogMatchConfidence: line.catalogMatchConfidence,
      catalogMatchedTerms: line.catalogMatchedTerms,
      parserConfidence: line.parserConfidence,
      parserReviewLabel: line.parserReviewLabel,
      parserReviewReason: line.parserReviewReason,
      parserNeedsReview: line.parserNeedsReview,
      ocrSourceLineId: line.ocrSourceLineId,
      ocrSourceLineNumber: line.ocrSourceLineNumber,
      ocrSourceSectionNumber: line.ocrSourceSectionNumber,
      ocrSourceSectionLineNumber: line.ocrSourceSectionLineNumber,
      parserExpenseFamily: line.parserExpenseFamily,
      parserHint: line.parserHint,
    );
  }

  final String? id;
  final String description;
  final String category;
  final _ExpenseLineUse use;
  final double quantity;
  final double unitsPerPackage;
  final String stockUnit;
  final double subtotal;
  final double? businessPercent;
  final ExpenseSplitAllocationMethod splitAllocationMethod;
  final double? businessSplitValue;
  final bool splitConfirmed;
  final int? odometerReading;
  final String? fuelType;
  final String? fillType;
  final double? unitPrice;
  final String rawReceiptText;
  final String? catalogItemId;
  final String? catalogItemName;
  final String? catalogItemPath;
  final double? catalogMatchConfidence;
  final List<String> catalogMatchedTerms;
  final double? parserConfidence;
  final String? parserReviewLabel;
  final String? parserReviewReason;
  final bool parserNeedsReview;
  final String? ocrSourceLineId;
  final int? ocrSourceLineNumber;
  final int? ocrSourceSectionNumber;
  final int? ocrSourceSectionLineNumber;
  final String? parserExpenseFamily;
  final String? parserHint;

  _ExpenseReceiptLine copyWith({
    String? category,
    String? description,
    _ExpenseLineUse? use,
    String? fuelType,
    String? fillType,
    String? stockUnit,
    String? rawReceiptText,
    String? catalogItemId,
    String? catalogItemName,
    String? catalogItemPath,
    double? catalogMatchConfidence,
    List<String>? catalogMatchedTerms,
    Object? businessPercent = _noBusinessPercentChange,
    ExpenseSplitAllocationMethod? splitAllocationMethod,
    Object? businessSplitValue = _noBusinessPercentChange,
    bool? splitConfirmed,
    double? parserConfidence,
    String? parserReviewLabel,
    String? parserReviewReason,
    bool? parserNeedsReview,
    String? ocrSourceLineId,
    int? ocrSourceLineNumber,
    int? ocrSourceSectionNumber,
    int? ocrSourceSectionLineNumber,
    String? parserExpenseFamily,
    String? parserHint,
  }) {
    return _ExpenseReceiptLine(
      id: id,
      description: description ?? this.description,
      category: category ?? this.category,
      use: use ?? this.use,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit ?? this.stockUnit,
      subtotal: subtotal,
      businessPercent: identical(businessPercent, _noBusinessPercentChange)
          ? this.businessPercent
          : businessPercent as double?,
      splitAllocationMethod:
          splitAllocationMethod ?? this.splitAllocationMethod,
      businessSplitValue:
          identical(businessSplitValue, _noBusinessPercentChange)
          ? this.businessSplitValue
          : businessSplitValue as double?,
      splitConfirmed: splitConfirmed ?? this.splitConfirmed,
      odometerReading: odometerReading,
      fuelType: fuelType ?? this.fuelType,
      fillType: fillType ?? this.fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText ?? this.rawReceiptText,
      catalogItemId: catalogItemId ?? this.catalogItemId,
      catalogItemName: catalogItemName ?? this.catalogItemName,
      catalogItemPath: catalogItemPath ?? this.catalogItemPath,
      catalogMatchConfidence:
          catalogMatchConfidence ?? this.catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms ?? this.catalogMatchedTerms,
      parserConfidence: parserConfidence ?? this.parserConfidence,
      parserReviewLabel: parserReviewLabel ?? this.parserReviewLabel,
      parserReviewReason: parserReviewReason ?? this.parserReviewReason,
      parserNeedsReview: parserNeedsReview ?? this.parserNeedsReview,
      ocrSourceLineId: ocrSourceLineId ?? this.ocrSourceLineId,
      ocrSourceLineNumber: ocrSourceLineNumber ?? this.ocrSourceLineNumber,
      ocrSourceSectionNumber:
          ocrSourceSectionNumber ?? this.ocrSourceSectionNumber,
      ocrSourceSectionLineNumber:
          ocrSourceSectionLineNumber ?? this.ocrSourceSectionLineNumber,
      parserExpenseFamily: parserExpenseFamily ?? this.parserExpenseFamily,
      parserHint: parserHint ?? this.parserHint,
    );
  }

  String get receiptProofRedactionAnchorCode {
    final sourceSection = ocrSourceSectionNumber;
    final sourceSectionLine = _expenseReceiptSafeLineNumber(
      ocrSourceSectionLineNumber,
    );
    final lineNumber = _expenseReceiptSafeLineNumber(ocrSourceLineNumber);
    final lineToken = sourceSectionLine != null
        ? 's${_expenseReceiptSafeSectionNumber(sourceSection).toString().padLeft(2, '0')}_l${sourceSectionLine.toString().padLeft(4, '0')}'
        : lineNumber != null
        ? 'l${lineNumber.toString().padLeft(4, '0')}'
        : _expenseReceiptPrivateSafeLineToken(ocrSourceLineId, id ?? '');
    final family = _expenseReceiptSafeToken(
      (parserExpenseFamily ?? category).trim(),
      fallback: 'expense',
    );
    return 'receipt_line_${lineToken}_${family}_${use.name}';
  }

  Map<String, Object?> get privacySafeLineReviewContract {
    final sectionLine = _expenseReceiptSafeLineNumber(
      ocrSourceSectionLineNumber,
    );
    final lineNumber = _expenseReceiptSafeLineNumber(ocrSourceLineNumber);
    return {
      'lineId': receiptProofRedactionAnchorCode,
      'lineNumberLabel': receiptProofLineReferenceLabel,
      'reviewMode': receiptReviewModeCode,
      'businessUse': use.name,
      'businessUseLabel': allocationSummary,
      'businessPercent': effectiveBusinessPercent,
      'personalPercent': effectivePersonalPercent,
      'splitAllocationMethod': splitAllocationMethod.name,
      'splitConfirmed': splitConfirmed,
      'hasDetailText': !isAllocationOnlyLine,
      'redactionAnchorCode': receiptProofRedactionAnchorCode,
      'ocrSourceLineNumber': ?lineNumber,
      'ocrSourceSectionLineNumber': ?sectionLine,
    };
  }

  bool get isAllocationOnlyLine =>
      _hasAllocationOnlyDescription && !hasReceiptLineDetailEvidence;

  String get receiptReviewModeCode =>
      isAllocationOnlyLine ? 'priceOnly' : 'detailedLine';

  bool get hasReceiptLineDetailEvidence =>
      !_hasAllocationOnlyDescription ||
      rawReceiptText.trim().isNotEmpty ||
      (catalogItemName ?? '').trim().isNotEmpty ||
      hasParserClassification;

  bool get _hasAllocationOnlyDescription {
    final clean = description.trim().toLowerCase();
    return clean.isEmpty ||
        clean == 'receipt item' ||
        clean == 'business receipt items' ||
        clean == 'personal receipt items' ||
        clean == 'split receipt items';
  }

  bool get hasParserClassification {
    return (parserExpenseFamily ?? '').trim().isNotEmpty ||
        (parserHint ?? '').trim().isNotEmpty;
  }

  String get parserExpenseFamilyLabel {
    final family = (parserExpenseFamily ?? '').trim();
    if (family.isEmpty) return '';
    return _expenseReceiptTokenLabel(family);
  }

  String get parserHintLabel {
    final hint = (parserHint ?? '').trim();
    if (hint.isEmpty) return '';
    return _expenseReceiptTokenLabel(hint);
  }

  String get parserClassificationLabel {
    final family = parserExpenseFamilyLabel;
    final hint = parserHintLabel;
    if (family.isEmpty) return hint;
    if (hint.isEmpty) return family;
    return '$family | $hint';
  }

  bool get hasReceiptEvidence {
    final evidence = receiptEvidenceText;
    return evidence.isNotEmpty && evidence != description.trim();
  }
}
