part of 'expense_ledger_models.dart';

enum ExpenseLineUse {
  business('Business'),
  personal('Personal'),
  split('Split');

  const ExpenseLineUse(this.label);

  final String label;

  static ExpenseLineUse fromName(String? name) {
    return ExpenseLineUse.values.firstWhere(
      (value) => value.name == name,
      orElse: () => ExpenseLineUse.business,
    );
  }
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

  bool get hasCatalogMatch => (catalogItemId ?? '').trim().isNotEmpty;
  bool get hasParserReview =>
      parserConfidence != null || parserReviewReason != null;

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
      ExpenseLineUse.business => 'Business receipt items',
      ExpenseLineUse.personal => 'Personal receipt items',
      ExpenseLineUse.split => 'Split receipt items',
    };
  }

  bool get isAllocationOnlyLine {
    final clean = description.trim().toLowerCase();
    return clean.isEmpty ||
        clean == 'receipt item' ||
        clean == 'business receipt items' ||
        clean == 'personal receipt items' ||
        clean == 'split receipt items';
  }

  double get effectiveBusinessPercent {
    return switch (use) {
      ExpenseLineUse.business => 1,
      ExpenseLineUse.personal => 0,
      ExpenseLineUse.split => businessPercent ?? .5,
    };
  }

  double get effectivePersonalPercent => 1 - effectiveBusinessPercent;

  double get businessAmount {
    return switch (use) {
      ExpenseLineUse.business => subtotal,
      ExpenseLineUse.personal => 0,
      ExpenseLineUse.split => subtotal * effectiveBusinessPercent,
    };
  }

  double get personalAmount {
    return switch (use) {
      ExpenseLineUse.business => 0,
      ExpenseLineUse.personal => subtotal,
      ExpenseLineUse.split => subtotal * effectivePersonalPercent,
    };
  }

  String get quantityLabel {
    if (unitsPerPackage <= 1) return 'Qty ${_formatNumber(quantity)} $unit';
    return '${_formatNumber(quantity)} pkg x ${_formatNumber(unitsPerPackage)} $unit';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'category': category,
      'use': use.name,
      'quantity': quantity,
      'unitsPerPackage': unitsPerPackage,
      'unit': unit,
      'subtotal': subtotal,
      'businessPercent': businessPercent,
      'odometerReading': odometerReading,
      'fuelType': fuelType,
      'fillType': fillType,
      'unitPrice': unitPrice,
      'rawReceiptText': rawReceiptText,
      'catalogItemId': catalogItemId,
      'catalogItemName': catalogItemName,
      'catalogItemPath': catalogItemPath,
      'catalogMatchConfidence': catalogMatchConfidence,
      'catalogMatchedTerms': catalogMatchedTerms,
      'parserConfidence': parserConfidence,
      'parserReviewLabel': parserReviewLabel,
      'parserReviewReason': parserReviewReason,
      'parserNeedsReview': parserNeedsReview,
    };
  }
}
