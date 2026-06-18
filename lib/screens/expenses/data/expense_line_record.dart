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
    this.parserConfidence,
    this.parserReviewLabel,
    this.parserReviewReason,
    this.parserNeedsReview = false,
  });

  factory ExpenseReceiptLineRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseReceiptLineRecord(
      id: map['id'] as String? ?? '',
      description: map['description'] as String? ?? '',
      category: map['category'] as String? ?? 'Uncategorized',
      use: ExpenseLineUse.fromName(map['use'] as String?),
      quantity: (map['quantity'] as num?)?.toDouble() ?? 1,
      unitsPerPackage: (map['unitsPerPackage'] as num?)?.toDouble() ?? 1,
      unit: map['unit'] as String? ?? 'each',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0,
      businessPercent: _clampedPercent(
        (map['businessPercent'] as num?)?.toDouble(),
      ),
      odometerReading: (map['odometerReading'] as num?)?.toInt(),
      fuelType: map['fuelType'] as String?,
      fillType: map['fillType'] as String?,
      unitPrice: (map['unitPrice'] as num?)?.toDouble(),
      parserConfidence: _clampedPercent(
        (map['parserConfidence'] as num?)?.toDouble(),
      ),
      parserReviewLabel: map['parserReviewLabel'] as String?,
      parserReviewReason: map['parserReviewReason'] as String?,
      parserNeedsReview: map['parserNeedsReview'] as bool? ?? false,
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
  final double? parserConfidence;
  final String? parserReviewLabel;
  final String? parserReviewReason;
  final bool parserNeedsReview;

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
      'parserConfidence': parserConfidence,
      'parserReviewLabel': parserReviewLabel,
      'parserReviewReason': parserReviewReason,
      'parserNeedsReview': parserNeedsReview,
    };
  }
}
