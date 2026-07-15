part of 'expense_ledger_models.dart';

const _maxExpenseReceiptLineNumber = 9999;
const _maxExpenseReceiptSectionNumber = 999;

enum ExpenseLineUse {
  unclassified('Needs classification'),
  business('Business'),
  personal('Personal'),
  split('Split');

  const ExpenseLineUse(this.label);

  final String label;

  static ExpenseLineUse fromName(String? name) {
    final normalizedName = name?.trim().toLowerCase();
    return ExpenseLineUse.values.firstWhere(
      (value) =>
          value.name == normalizedName ||
          value.label.toLowerCase() == normalizedName,
      orElse: () => ExpenseLineUse.unclassified,
    );
  }
}

enum ExpenseReceiptLineReviewMode {
  priceOnly('Price only'),
  detailedLine('Detailed line');

  const ExpenseReceiptLineReviewMode(this.label);

  final String label;
}

class ExpenseReceiptLineRecord {
  const ExpenseReceiptLineRecord({
    required this.id,
    required this.description,
    required this.category,
    required this.use,
    required this.quantity,
    required this.unitsPerPackage,
    required this.unit,
    required this.subtotal,
    this.businessPercent,
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

  factory ExpenseReceiptLineRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptLineRecord(
      id: _expenseString(map['id']),
      description: _expenseString(map['description']),
      category: _expenseString(map['category'], fallback: 'Uncategorized'),
      use: ExpenseLineUse.fromName(_expenseString(map['use'])),
      quantity: _expenseDouble(map['quantity']) ?? 1,
      unitsPerPackage: _expenseDouble(map['unitsPerPackage']) ?? 1,
      unit: _expenseString(map['unit'], fallback: 'each'),
      subtotal: _expenseDouble(map['subtotal']) ?? 0,
      businessPercent: _clampedPercent(_expenseDouble(map['businessPercent'])),
      odometerReading: _expenseInt(map['odometerReading']),
      fuelType: _nullableExpenseString(map['fuelType']),
      fillType: _nullableExpenseString(map['fillType']),
      unitPrice: _expenseDouble(map['unitPrice']),
      rawReceiptText: _expenseString(map['rawReceiptText']),
      catalogItemId: _nullableExpenseString(map['catalogItemId']),
      catalogItemName: _nullableExpenseString(map['catalogItemName']),
      catalogItemPath: _nullableExpenseString(map['catalogItemPath']),
      catalogMatchConfidence: _clampedPercent(
        _expenseDouble(map['catalogMatchConfidence']),
      ),
      catalogMatchedTerms:
          (map['catalogMatchedTerms'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      parserConfidence: _clampedPercent(
        _expenseDouble(map['parserConfidence']),
      ),
      parserReviewLabel: _nullableExpenseString(map['parserReviewLabel']),
      parserReviewReason: _nullableExpenseString(map['parserReviewReason']),
      parserNeedsReview: _expenseBool(map['parserNeedsReview']),
      ocrSourceLineId: _nullableExpenseString(map['ocrSourceLineId']),
      ocrSourceLineNumber: _expenseInt(map['ocrSourceLineNumber']),
      ocrSourceSectionNumber: _expenseInt(map['ocrSourceSectionNumber']),
      ocrSourceSectionLineNumber: _expenseInt(
        map['ocrSourceSectionLineNumber'],
      ),
      parserExpenseFamily: _nullableExpenseString(map['parserExpenseFamily']),
      parserHint: _nullableExpenseString(map['parserHint']),
    );
  }

  final String id;
  final String description;
  final String category;
  final ExpenseLineUse use;
  final double quantity;
  final double unitsPerPackage;
  final String unit;
  final double subtotal;
  final double? businessPercent;
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

  bool get hasCatalogMatch => (catalogItemId ?? '').trim().isNotEmpty;
  bool get hasParserReview =>
      parserConfidence != null || parserReviewReason != null;
  bool get hasOcrSourceLine =>
      (ocrSourceLineId ?? '').trim().isNotEmpty ||
      safeOcrSourceLineNumber != null ||
      safeOcrSourceSectionLineNumber != null;
  bool get hasParserClassification =>
      (parserExpenseFamily ?? '').trim().isNotEmpty ||
      (parserHint ?? '').trim().isNotEmpty;

  String get parserExpenseFamilyLabel {
    final family = (parserExpenseFamily ?? '').trim();
    if (family.isEmpty) return '';
    return _expenseTokenLabel(family);
  }

  String get parserHintLabel {
    final hint = (parserHint ?? '').trim();
    if (hint.isEmpty) return '';
    return _expenseTokenLabel(hint);
  }

  String get parserClassificationLabel {
    final family = parserExpenseFamilyLabel;
    final hint = parserHintLabel;
    if (family.isEmpty) return hint;
    if (hint.isEmpty) return family;
    return '$family | $hint';
  }

  String get ocrSourceLineLabel {
    final sectionLine = safeOcrSourceSectionLineNumber;
    final section = safeOcrSourceSectionNumber;
    if (sectionLine != null) {
      if (section != null && section > 1) {
        return 'OCR section $section line $sectionLine';
      }
      return 'OCR source line $sectionLine';
    }
    final lineNumber = safeOcrSourceLineNumber;
    if (lineNumber != null) return 'OCR line $lineNumber';
    final id = (ocrSourceLineId ?? '').trim();
    if (id.isNotEmpty) return _expensePrivateSafeLineReferenceLabel(id);
    return '';
  }

  String get receiptProofLineReferenceLabel {
    final sectionLine = safeOcrSourceSectionLineNumber;
    final section = safeOcrSourceSectionNumber;
    if (sectionLine != null) {
      if (section != null && section > 1) {
        return 'Section $section line $sectionLine';
      }
      return 'Source line $sectionLine';
    }
    final lineNumber = safeOcrSourceLineNumber;
    if (lineNumber != null) return 'Line $lineNumber';
    final sourceId = (ocrSourceLineId ?? '').trim();
    if (sourceId.isNotEmpty) {
      return _expensePrivateSafeLineReferenceLabel(sourceId);
    }
    return 'Receipt line';
  }

  int? get safeOcrSourceLineNumber {
    final lineNumber = ocrSourceLineNumber;
    if (lineNumber == null || lineNumber < 1) return null;
    return lineNumber.clamp(1, _maxExpenseReceiptLineNumber);
  }

  int? get safeOcrSourceSectionLineNumber {
    final sectionLine = ocrSourceSectionLineNumber;
    if (sectionLine == null || sectionLine < 1) return null;
    return sectionLine.clamp(1, _maxExpenseReceiptLineNumber);
  }

  int? get safeOcrSourceSectionNumber {
    if (safeOcrSourceSectionLineNumber == null) return null;
    return _expenseSafeReceiptSectionNumber(ocrSourceSectionNumber);
  }

  int? get receiptDisplayLineNumber {
    return safeOcrSourceSectionLineNumber ?? safeOcrSourceLineNumber;
  }

  String get receiptLineNumberLabel {
    final displayNumber = receiptDisplayLineNumber;
    if (displayNumber == null) return receiptProofLineReferenceLabel;
    final section = safeOcrSourceSectionNumber;
    if (section != null && section > 1) {
      return 'Section $section line $displayNumber';
    }
    return 'Line $displayNumber';
  }

  ExpenseReceiptLineReviewMode get receiptReviewMode {
    return isAllocationOnlyLine
        ? ExpenseReceiptLineReviewMode.priceOnly
        : ExpenseReceiptLineReviewMode.detailedLine;
  }

  String get receiptReviewModeCode => receiptReviewMode.name;

  String get receiptReviewModeLabel => receiptReviewMode.label;

  String get businessUseReviewLabel {
    return switch (use) {
      ExpenseLineUse.unclassified => 'Needs classification',
      ExpenseLineUse.business => 'Business',
      ExpenseLineUse.personal => 'Personal',
      ExpenseLineUse.split =>
        'Split ${((effectiveBusinessPercent) * 100).round()}% business',
    };
  }

  String get receiptLineReviewSummary {
    final mode = receiptReviewMode == ExpenseReceiptLineReviewMode.priceOnly
        ? 'price only'
        : 'detailed line';
    return '$receiptLineNumberLabel: $mode, $businessUseReviewLabel';
  }

  Map<String, Object?> get privacySafeLineReviewContract {
    return {
      'lineId': receiptProofRedactionAnchorCode,
      'lineNumberLabel': receiptLineNumberLabel,
      'reviewMode': receiptReviewModeCode,
      'businessUse': use.name,
      'businessUseLabel': businessUseReviewLabel,
      'businessPercent': effectiveBusinessPercent,
      'personalPercent': effectivePersonalPercent,
      'hasDetailText': !isAllocationOnlyLine,
      'hasAmount': subtotal != 0,
      'redactionAnchorCode': receiptProofRedactionAnchorCode,
      if (receiptDisplayLineNumber != null)
        'receiptDisplayLineNumber': receiptDisplayLineNumber,
      if (safeOcrSourceLineNumber != null)
        'ocrSourceLineNumber': safeOcrSourceLineNumber,
      if (safeOcrSourceSectionNumber != null)
        'ocrSourceSectionNumber': safeOcrSourceSectionNumber,
      if (safeOcrSourceSectionLineNumber != null)
        'ocrSourceSectionLineNumber': safeOcrSourceSectionLineNumber,
    };
  }

  String get receiptProofRedactionAnchorCode {
    final sourceSection = safeOcrSourceSectionNumber;
    final sourceSectionLine = safeOcrSourceSectionLineNumber;
    final lineNumber = safeOcrSourceLineNumber;
    final lineToken = sourceSectionLine != null && sourceSection != null
        ? 's${sourceSection.toString().padLeft(2, '0')}_l${sourceSectionLine.toString().padLeft(4, '0')}'
        : lineNumber != null
        ? 'l${lineNumber.toString().padLeft(4, '0')}'
        : _expensePrivateSafeLineToken(ocrSourceLineId, id);
    final family = _expenseSafeToken(
      (parserExpenseFamily ?? category).trim(),
      fallback: 'expense',
    );
    return 'receipt_line_${lineToken}_${family}_${use.name}';
  }

  String get clientProofDefaultVisibility {
    if (use == ExpenseLineUse.personal) return 'redact_by_default';
    if (parserNeedsReview ||
        category.trim().toLowerCase() == 'uncategorized' ||
        parserReviewLabelText == 'Poor') {
      return 'review_before_client_share';
    }
    return 'review_for_client_proof';
  }

  bool get redactsFromClientProofByDefault =>
      clientProofDefaultVisibility == 'redact_by_default';

  bool get needsClientProofReview =>
      clientProofDefaultVisibility != 'redact_by_default';

  String get clientProofReviewLabel {
    if (redactsFromClientProofByDefault) return 'Hidden from client proof';
    if (clientProofDefaultVisibility == 'review_before_client_share') {
      return 'Review before sharing';
    }
    return 'Review for client proof';
  }

  Map<String, Object?> get privacySafeProofReference {
    return {
      'lineId': receiptProofRedactionAnchorCode,
      'proofLineReferenceLabel': receiptProofLineReferenceLabel,
      'redactionAnchorCode': receiptProofRedactionAnchorCode,
      'clientProofDefaultVisibility': clientProofDefaultVisibility,
      'clientProofReviewLabel': clientProofReviewLabel,
      'use': use.name,
      'businessPercent': effectiveBusinessPercent,
      'personalPercent': effectivePersonalPercent,
      'categoryToken': _expenseSafeToken(category),
      'parserExpenseFamily': parserExpenseFamily,
      'hasAmount': subtotal != 0,
      'needsParserReview': parserNeedsReview,
      'hasOcrSourceLine': hasOcrSourceLine,
      if (safeOcrSourceLineNumber != null)
        'ocrSourceLineNumber': safeOcrSourceLineNumber,
      if (safeOcrSourceSectionNumber != null)
        'ocrSourceSectionNumber': safeOcrSourceSectionNumber,
      if (safeOcrSourceSectionLineNumber != null)
        'ocrSourceSectionLineNumber': safeOcrSourceSectionLineNumber,
    };
  }

  String get receiptEvidenceText {
    final raw = rawReceiptText.trim();
    if (raw.isNotEmpty) return raw;
    return description.trim();
  }

  String get parserReviewLabelText {
    final label = parserReviewLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    final confidence = parserConfidence;
    if (confidence == null) return parserNeedsReview ? 'Review' : 'Manual';
    if (confidence >= .84 && !parserNeedsReview) return 'Good';
    if (confidence >= .58) return 'Review';
    return 'Poor';
  }

  String get parserReviewActionText {
    if (parserNeedsReview) return 'Review before saving';
    final label = parserReviewLabelText.toLowerCase();
    if (label == 'good') return 'Looks matched';
    if (label == 'poor') return 'Needs correction';
    if (hasParserReview) return 'Check line';
    return 'Manual line';
  }

  String get displayDescription {
    final clean = description.trim();
    if (clean.isNotEmpty && clean.toLowerCase() != 'receipt item') {
      return clean;
    }
    return switch (use) {
      ExpenseLineUse.unclassified => 'Receipt items',
      ExpenseLineUse.business => 'Business receipt items',
      ExpenseLineUse.personal => 'Personal receipt items',
      ExpenseLineUse.split => 'Split receipt items',
    };
  }

  bool get isAllocationOnlyLine =>
      _hasAllocationOnlyDescription && !hasReceiptLineDetailEvidence;

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

  double get effectiveBusinessPercent {
    return switch (use) {
      ExpenseLineUse.unclassified => 0,
      ExpenseLineUse.business => 1,
      ExpenseLineUse.personal => 0,
      ExpenseLineUse.split => _clampedPercent(businessPercent) ?? .5,
    };
  }

  double get effectivePersonalPercent {
    if (use == ExpenseLineUse.unclassified) return 0;
    return 1 - effectiveBusinessPercent;
  }

  double get businessAmount {
    return switch (use) {
      ExpenseLineUse.unclassified => 0,
      ExpenseLineUse.business => subtotal,
      ExpenseLineUse.personal => 0,
      ExpenseLineUse.split => subtotal * effectiveBusinessPercent,
    };
  }

  double get personalAmount {
    return switch (use) {
      ExpenseLineUse.unclassified => 0,
      ExpenseLineUse.business => 0,
      ExpenseLineUse.personal => subtotal,
      ExpenseLineUse.split => subtotal * effectivePersonalPercent,
    };
  }

  String get quantityLabel {
    if (unitsPerPackage <= 1) return 'Qty ${_formatNumber(quantity)} $unit';
    return '${_formatNumber(quantity)} pkg x ${_formatNumber(unitsPerPackage)} $unit';
  }
}

String _expenseTokenLabel(String value) {
  final cleaned = value
      .trim()
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
  if (cleaned.isEmpty) return '';
  return cleaned
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => part.length == 1
            ? part.toUpperCase()
            : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String _expenseSafeToken(String value, {String fallback = 'unknown'}) {
  final token = value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  return token.isEmpty ? fallback : token;
}

String _expensePrivateSafeLineToken(
  String? ocrSourceLineId,
  String fallbackId,
) {
  final sourceId = (ocrSourceLineId ?? '').trim();
  if (_expenseLooksLikeSafeOcrLineId(sourceId)) {
    return _expenseSafeToken(sourceId);
  }
  return _expensePrivateSafeIdToken(sourceId.isEmpty ? fallbackId : sourceId);
}

String _expensePrivateSafeLineReferenceLabel(String value) {
  final sourceId = value.trim();
  if (_expenseLooksLikeSafeOcrLineId(sourceId)) return sourceId;
  return 'Receipt line';
}

bool _expenseLooksLikeSafeOcrLineId(String value) {
  return RegExp(r'^ocr_line_[0-9]{3,5}(_[a-z0-9_]+)?$').hasMatch(value.trim());
}

int _expenseSafeReceiptSectionNumber(int? value) {
  if (value == null || value < 1) return 1;
  return value.clamp(1, _maxExpenseReceiptSectionNumber);
}

String _expensePrivateSafeIdToken(String value) {
  final cleaned = value.trim();
  if (cleaned.isEmpty) return 'manual_unknown';
  var hash = 0x811c9dc5;
  for (final unit in cleaned.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return 'manual_${hash.toRadixString(16).padLeft(8, '0')}';
}
