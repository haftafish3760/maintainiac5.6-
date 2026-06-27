part of 'expense_receipt_entry_screen.dart';

const Object _noBusinessPercentChange = Object();

enum _ExpenseLineUse {
  business('Business'),
  personal('Personal'),
  split('Split');

  const _ExpenseLineUse(this.label);

  final String label;
}

extension on _ExpenseLineUse {
  ExpenseLineUse get ledgerUse {
    return switch (this) {
      _ExpenseLineUse.business => ExpenseLineUse.business,
      _ExpenseLineUse.personal => ExpenseLineUse.personal,
      _ExpenseLineUse.split => ExpenseLineUse.split,
    };
  }
}

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
      },
      quantity: line.quantity,
      unitsPerPackage: line.unitsPerPackage,
      stockUnit: line.unit,
      subtotal: line.subtotal,
      businessPercent: line.businessPercent,
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
    double? parserConfidence,
    String? parserReviewLabel,
    String? parserReviewReason,
    bool? parserNeedsReview,
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
    );
  }

  _ExpenseReceiptLine confirmParserReview() {
    return _ExpenseReceiptLine(
      id: id,
      description: description,
      category: category,
      use: use,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit,
      subtotal: subtotal,
      businessPercent: businessPercent,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      catalogItemId: catalogItemId,
      catalogItemName: catalogItemName,
      catalogItemPath: catalogItemPath,
      catalogMatchConfidence: catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms,
      parserConfidence: parserConfidence ?? catalogMatchConfidence ?? .9,
      parserReviewLabel: 'Good',
      parserReviewReason: 'User confirmed this parsed receipt line.',
      parserNeedsReview: false,
    );
  }

  _ExpenseReceiptLine markExpenseOnly() {
    final nextCategory = category == 'Materials' ? 'Supplies' : category;
    return _ExpenseReceiptLine(
      id: id,
      description: description,
      category: nextCategory,
      use: use == _ExpenseLineUse.personal ? use : _ExpenseLineUse.business,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      stockUnit: stockUnit,
      subtotal: subtotal,
      businessPercent: null,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      parserConfidence: parserConfidence,
      parserReviewLabel: 'Good',
      parserReviewReason: 'Marked as expense-only from receipt review.',
      parserNeedsReview: false,
    );
  }

  String get quantityText => quantity == quantity.roundToDouble()
      ? quantity.toInt().toString()
      : '$quantity';
  String get unitsPerPackageText =>
      unitsPerPackage == unitsPerPackage.roundToDouble()
      ? unitsPerPackage.toInt().toString()
      : '$unitsPerPackage';
  String get subtotalText => subtotal == 0 ? '' : subtotal.toStringAsFixed(2);
  String get businessPercentText {
    if (use != _ExpenseLineUse.split) return '50';
    final percent = (businessPercent ?? .5) * 100;
    return percent == percent.roundToDouble()
        ? percent.toInt().toString()
        : percent.toStringAsFixed(2);
  }

  double get totalUnits => quantity * unitsPerPackage;

  String get displayDescription {
    final clean = description.trim();
    if (clean.isNotEmpty && clean.toLowerCase() != 'receipt item') {
      return clean;
    }
    return switch (use) {
      _ExpenseLineUse.business => 'Business receipt items',
      _ExpenseLineUse.personal => 'Personal receipt items',
      _ExpenseLineUse.split => 'Split receipt items',
    };
  }

  double get effectiveBusinessPercent {
    return switch (use) {
      _ExpenseLineUse.business => 1,
      _ExpenseLineUse.personal => 0,
      _ExpenseLineUse.split => businessPercent ?? .5,
    };
  }

  double get effectivePersonalPercent => 1 - effectiveBusinessPercent;

  String get allocationSummary {
    if (use != _ExpenseLineUse.split) return use.label;
    return 'Split ${_percent(effectiveBusinessPercent)} business';
  }

  String get allocationDetail {
    return switch (use) {
      _ExpenseLineUse.business => 'Business ${_money(subtotal)}',
      _ExpenseLineUse.personal => 'Personal ${_money(subtotal)}',
      _ExpenseLineUse.split =>
        'Business ${_money(businessAmount)} | Personal ${_money(personalAmount)}',
    };
  }

  bool get hasParserReview {
    return parserConfidence != null ||
        (parserReviewLabel ?? '').trim().isNotEmpty ||
        (parserReviewReason ?? '').trim().isNotEmpty ||
        parserNeedsReview;
  }

  bool get cameFromAppAssistedReceiptRead {
    return rawReceiptText.trim().isNotEmpty || hasParserReview;
  }

  String get parserReviewSummary {
    final label = (parserReviewLabel ?? '').trim().isEmpty
        ? (parserNeedsReview ? 'Review' : 'App Fill')
        : parserReviewLabel!.trim();
    final confidence = parserConfidence;
    if (confidence == null) return label;
    return '$label ${(confidence * 100).round()}%';
  }

  String get receiptEvidenceText {
    final raw = rawReceiptText.trim();
    if (raw.isNotEmpty) return raw;
    return description.trim();
  }

  bool get hasReceiptEvidence {
    final evidence = receiptEvidenceText;
    return evidence.isNotEmpty && evidence != description.trim();
  }

  String get parserReviewActionText {
    if (parserNeedsReview) return 'Review before saving';
    final label = (parserReviewLabel ?? '').trim().toLowerCase();
    if (label == 'good') return 'Looks matched';
    if (label == 'poor') return 'Needs correction';
    if (hasParserReview) return 'Check line';
    return 'Manual line';
  }

  Color get parserBadgeColor {
    final label = (parserReviewLabel ?? '').trim().toLowerCase();
    if (parserNeedsReview || label == 'review') return const Color(0xFF8A5D00);
    if (label == 'poor') return const Color(0xFFA33A2C);
    return const Color(0xFF1E7A3D);
  }

  String get packageSummary {
    if (category == 'Fuel') {
      final unitLabel = stockUnit == 'kWh' ? 'kWh' : 'gal';
      final odometer = odometerReading == null ? '' : ' | odo $odometerReading';
      final fill = fillType == null ? '' : ' | $fillType';
      return '${fuelType ?? 'Fuel'} | ${_formatNumber(quantity)} $unitLabel$fill$odometer';
    }
    if (!expenseCategoryUsesQuantityFields(category)) {
      return 'Receipt amount only';
    }
    if (unitsPerPackage <= 1) {
      return 'Qty ${_formatNumber(quantity)} $stockUnit';
    }
    final eachCost = totalUnits <= 0 ? 0.0 : subtotal / totalUnits;
    return '${_formatNumber(quantity)} pkg x ${_formatNumber(unitsPerPackage)} $stockUnit | ${_money(eachCost)} each';
  }

  double get businessAmount {
    return switch (use) {
      _ExpenseLineUse.business => subtotal,
      _ExpenseLineUse.personal => 0,
      _ExpenseLineUse.split => subtotal * effectiveBusinessPercent,
    };
  }

  double get personalAmount {
    return switch (use) {
      _ExpenseLineUse.business => 0,
      _ExpenseLineUse.personal => subtotal,
      _ExpenseLineUse.split => subtotal * effectivePersonalPercent,
    };
  }

  ExpenseReceiptLineRecord toLedgerLine({String? id}) {
    return ExpenseReceiptLineRecord(
      id: id ?? this.id ?? 'EXPL-${DateTime.now().microsecondsSinceEpoch}',
      description: description,
      category: category,
      use: use.ledgerUse,
      quantity: quantity,
      unitsPerPackage: unitsPerPackage,
      unit: stockUnit,
      subtotal: subtotal,
      businessPercent: businessPercent,
      odometerReading: odometerReading,
      fuelType: fuelType,
      fillType: fillType,
      unitPrice: unitPrice,
      rawReceiptText: rawReceiptText,
      catalogItemId: catalogItemId,
      catalogItemName: catalogItemName,
      catalogItemPath: catalogItemPath,
      catalogMatchConfidence: catalogMatchConfidence,
      catalogMatchedTerms: catalogMatchedTerms,
      parserConfidence: parserConfidence,
      parserReviewLabel: parserReviewLabel,
      parserReviewReason: parserReviewReason,
      parserNeedsReview: parserNeedsReview,
    );
  }
}

String _formatNumber(double value) =>
    value == value.roundToDouble() ? value.toInt().toString() : '$value';

String _money(double value) => '\$${value.toStringAsFixed(2)}';
String _percent(double value) => '${(value * 100).toStringAsFixed(2)}%';

double? _parseMoneyInput(String value) {
  final cleaned = value.replaceAll(RegExp(r'[^0-9.\-]'), '');
  if (cleaned.isEmpty || cleaned == '-' || cleaned == '.') return null;
  return double.tryParse(cleaned);
}

String _moneyInputText(double? value) {
  if (value == null) return '';
  return value.toStringAsFixed(2);
}

final _expenseCategoryNames = [
  'Uncategorized',
  ...{
    for (final category in [
      ...defaultExpenseCategories,
      ...otherExpenseCategories,
    ])
      category.category,
  },
];

const _stockUnits = [
  'each',
  'bottle',
  'package',
  'pack',
  'box',
  'case',
  'roll',
  'tube',
  'bag',
  'gallon',
  'quart',
  'ounce',
  'pound',
  'foot',
  'linear foot',
  'sheet',
  'set',
];
