part of '../../receipts/receipt_ocr_contract.dart';

enum ReceiptOcrParserLineKind {
  vendorCandidate,
  dateCandidate,
  itemCandidate,
  subtotalCandidate,
  taxCandidate,
  totalCandidate,
  tenderCandidate,
  receiptMetadata,
  barcodeOrId,
  other,
}

enum ReceiptOcrParserExpenseFamily {
  materials,
  fuel,
  vehicleSupplies,
  foodOrGrocery,
  businessSupplies,
  service,
  generalExpense,
  receiptSummary,
  receiptHeader,
  tenderOrMetadata,
  unknown,
}

class ReceiptOcrParserLineLocation {
  const ReceiptOcrParserLineLocation({
    required this.sectionNumber,
    required this.sectionLineNumber,
  });

  final int sectionNumber;
  final int sectionLineNumber;

  int get safeSectionNumber => sectionNumber < 1 ? 1 : sectionNumber;
  int get safeSectionLineNumber =>
      sectionLineNumber < 1 ? 1 : sectionLineNumber;
  String get label => safeSectionNumber <= 1
      ? 'source line $safeSectionLineNumber'
      : 'section $safeSectionNumber line $safeSectionLineNumber';

  Map<String, Object?> toMap() {
    return {
      'sectionNumber': safeSectionNumber,
      'sectionLineNumber': safeSectionLineNumber,
      'label': label,
    };
  }
}

class ReceiptOcrParserLineSignal {
  const ReceiptOcrParserLineSignal({
    required this.index,
    required this.text,
    required this.kind,
    this.amountCandidates = const [],
    this.traits = const [],
    this.confidence = 0,
    this.reviewReason = 'Line was not classified.',
    this.sourceLocation,
    this.expenseFamily = ReceiptOcrParserExpenseFamily.unknown,
    this.parserHint = 'unknown',
  });

  final int index;
  final String text;
  final ReceiptOcrParserLineKind kind;
  final List<double> amountCandidates;
  final List<String> traits;
  final double confidence;
  final String reviewReason;
  final ReceiptOcrParserLineLocation? sourceLocation;
  final ReceiptOcrParserExpenseFamily expenseFamily;
  final String parserHint;

  bool get hasAmount => amountCandidates.isNotEmpty;
  bool get needsReview => confidence < .84;
  bool hasTrait(String trait) => traits.contains(trait);
  bool get hasQuantityOrUnitSignal => hasTrait('quantity_or_unit');
  bool get hasSkuLikeSignal => hasTrait('sku_like');
  bool get hasGenericDescription => hasTrait('generic_description');
  bool get hasSafeTerminalLineAmount => hasTrait('safe_terminal_line_amount');
  bool get hasEmbeddedAmountReviewRisk => hasTrait('embedded_amount_review');
  bool get hasUnitPriceOrQuantityAmountSignal =>
      hasTrait('unit_or_quantity_amounts_present');
  bool get hasSeparatorlessMoneyInference =>
      hasTrait('separatorless_money_inferred');
  bool get hasSplitCentsMoneyInference =>
      hasTrait('split_cents_money_inferred');
  double? get terminalLineAmount => _terminalReceiptAmount(text);
  double? get safeExpenseAmount =>
      hasSafeTerminalLineAmount ? terminalLineAmount : null;
  bool get isInventoryPrepCandidate =>
      isLikelyReceiptItem &&
      safeExpenseAmount != null &&
      hasSafeTerminalLineAmount &&
      !hasGenericDescription &&
      (hasQuantityOrUnitSignal ||
          hasSkuLikeSignal ||
          expenseFamily == ReceiptOcrParserExpenseFamily.materials);
  bool get isMaterialCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.materials;
  bool get isFuelCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.fuel;
  bool get hasFuelQuantitySignal => hasTrait('fuel_quantity_signal');
  bool get hasFuelUnitPriceSignal => hasTrait('fuel_unit_price_signal');
  bool get hasFuelDetailSignals =>
      isFuelCandidate && hasFuelQuantitySignal && hasFuelUnitPriceSignal;
  bool get isVehicleSupplyCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.vehicleSupplies;
  bool get isParserReadyField =>
      !needsReview &&
      (kind != ReceiptOcrParserLineKind.itemCandidate ||
          hasSafeTerminalLineAmount) &&
      (kind == ReceiptOcrParserLineKind.vendorCandidate ||
          kind == ReceiptOcrParserLineKind.dateCandidate ||
          isLikelySummary ||
          isLikelyReceiptItem);
  bool get isParserReviewField =>
      needsReview &&
      (kind == ReceiptOcrParserLineKind.vendorCandidate ||
          kind == ReceiptOcrParserLineKind.dateCandidate ||
          isLikelySummary ||
          isLikelyReceiptItem);
  double? get primaryAmount => isLikelyReceiptItem
      ? safeExpenseAmount ??
            (amountCandidates.isEmpty ? null : amountCandidates.last)
      : amountCandidates.isEmpty
      ? null
      : amountCandidates.last;
  String get normalizedText => _normalizeReceiptParserLineText(text);
  String get stableLineId =>
      'ocr_line_${index.toString().padLeft(3, '0')}_$roleLabel';
  String get sourceLocationLabel => sourceLocation?.label ?? '';
  String get expenseFamilyToken => _receiptExpenseFamilyToken(expenseFamily);
  String get parserBucketId =>
      needsReview ? '${roleLabel}_needs_review' : '${roleLabel}_ready';
  bool get isLikelyReceiptItem =>
      kind == ReceiptOcrParserLineKind.itemCandidate;
  bool get isLikelyHeader =>
      kind == ReceiptOcrParserLineKind.vendorCandidate ||
      kind == ReceiptOcrParserLineKind.dateCandidate;
  bool get isLikelySummary =>
      kind == ReceiptOcrParserLineKind.subtotalCandidate ||
      kind == ReceiptOcrParserLineKind.taxCandidate ||
      kind == ReceiptOcrParserLineKind.totalCandidate;
  bool get isLikelyTender => kind == ReceiptOcrParserLineKind.tenderCandidate;
  bool get isLikelyMetadata =>
      kind == ReceiptOcrParserLineKind.receiptMetadata ||
      kind == ReceiptOcrParserLineKind.barcodeOrId;
  String get roleLabel {
    return switch (kind) {
      ReceiptOcrParserLineKind.vendorCandidate => 'vendor',
      ReceiptOcrParserLineKind.dateCandidate => 'date',
      ReceiptOcrParserLineKind.itemCandidate => 'item',
      ReceiptOcrParserLineKind.subtotalCandidate => 'subtotal',
      ReceiptOcrParserLineKind.taxCandidate => 'tax',
      ReceiptOcrParserLineKind.totalCandidate => 'total',
      ReceiptOcrParserLineKind.tenderCandidate => 'tender',
      ReceiptOcrParserLineKind.receiptMetadata => 'metadata',
      ReceiptOcrParserLineKind.barcodeOrId => 'barcode_or_id',
      ReceiptOcrParserLineKind.other => 'other',
    };
  }
}

class ReceiptOcrParserLineDraft {
  const ReceiptOcrParserLineDraft({
    required this.stableLineId,
    required this.lineNumber,
    required this.text,
    required this.role,
    required this.parserBucket,
    required this.amount,
    required this.confidence,
    required this.needsReview,
    required this.reviewReason,
    required this.traits,
    this.sourceLocation,
    this.expenseFamily = ReceiptOcrParserExpenseFamily.unknown,
    this.parserHint = 'unknown',
  });

  factory ReceiptOcrParserLineDraft.fromSignal(
    ReceiptOcrParserLineSignal signal,
  ) {
    return ReceiptOcrParserLineDraft(
      stableLineId: signal.stableLineId,
      lineNumber: signal.index + 1,
      text: signal.text,
      role: signal.roleLabel,
      parserBucket: signal.parserBucketId,
      amount: signal.primaryAmount,
      confidence: signal.confidence,
      needsReview: signal.needsReview,
      reviewReason: signal.reviewReason,
      traits: signal.traits,
      sourceLocation: signal.sourceLocation,
      expenseFamily: signal.expenseFamily,
      parserHint: signal.parserHint,
    );
  }

  final String stableLineId;
  final int lineNumber;
  final String text;
  final String role;
  final String parserBucket;
  final double? amount;
  final double confidence;
  final bool needsReview;
  final String reviewReason;
  final List<String> traits;
  final ReceiptOcrParserLineLocation? sourceLocation;
  final ReceiptOcrParserExpenseFamily expenseFamily;
  final String parserHint;

  bool get isItem => role == 'item';
  bool get isSummary => role == 'subtotal' || role == 'tax' || role == 'total';
  bool get isHeader => role == 'vendor' || role == 'date';
  bool get isMetadata => role == 'metadata' || role == 'barcode_or_id';
  bool get isInventoryPrepCandidate =>
      traits.contains('candidate_inventory_prep');
  bool get isMaterialCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.materials;
  bool get isFuelCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.fuel;
  bool get isVehicleSupplyCandidate =>
      expenseFamily == ReceiptOcrParserExpenseFamily.vehicleSupplies;
  bool get hasAmount => amount != null;
  String get lineLabel => 'Line $lineNumber';
  String get sourceLocationLabel => sourceLocation?.label ?? '';
  String get sourceFirstLineLabel =>
      sourceLocationLabel.isEmpty ? lineLabel : sourceLocationLabel;
  String get proofLineReferenceLabel {
    final source = sourceLocationLabel;
    return source.isEmpty ? lineLabel : '$lineLabel, $source';
  }

  String get expenseFamilyToken => _receiptExpenseFamilyToken(expenseFamily);
  String get customerProofDefaultVisibility {
    if (isMetadata || role == 'tender') return 'redact_by_default';
    if (isHeader || isSummary || isItem) return 'review_for_customer_proof';
    return 'review_before_customer_share';
  }

  Map<String, Object?> toLocalReviewMap() {
    return {
      'stableLineId': stableLineId,
      'lineNumber': lineNumber,
      'sourceFirstLineLabel': sourceFirstLineLabel,
      'text': text,
      'role': role,
      'parserBucket': parserBucket,
      if (amount != null) 'amount': amount,
      'confidence': confidence,
      'needsReview': needsReview,
      'reviewReason': reviewReason,
      'traits': traits,
      'expenseFamily': expenseFamilyToken,
      'parserHint': parserHint,
      if (sourceLocation != null) 'sourceLocation': sourceLocation!.toMap(),
    };
  }

  Map<String, Object?> toPrivacySafeSummaryMap() {
    return {
      'stableLineId': stableLineId,
      'lineNumber': lineNumber,
      'sourceFirstLineLabel': sourceFirstLineLabel,
      'role': role,
      'parserBucket': parserBucket,
      'hasAmount': hasAmount,
      'needsReview': needsReview,
      'confidenceBucket': _receiptParserConfidenceBucket(confidence),
      'traitCount': traits.length,
      'expenseFamily': expenseFamilyToken,
      'parserHint': parserHint,
      'proofLineReferenceLabel': proofLineReferenceLabel,
      'customerProofDefaultVisibility': customerProofDefaultVisibility,
      if (sourceLocation != null)
        'sourceSectionNumber': sourceLocation!.sectionNumber,
      if (sourceLocation != null)
        'sourceSectionLineNumber': sourceLocation!.sectionLineNumber,
    };
  }
}
