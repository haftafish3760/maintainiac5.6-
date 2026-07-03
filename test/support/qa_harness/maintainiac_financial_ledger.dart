class MaintainiacLedgerLine {
  const MaintainiacLedgerLine({
    required this.id,
    required this.category,
    required this.amountCents,
    this.taxCents = 0,
    this.discountCents = 0,
    this.refundCents = 0,
    this.business = true,
    this.sourceId = '',
  });

  final String id;
  final String category;
  final int amountCents;
  final int taxCents;
  final int discountCents;
  final int refundCents;
  final bool business;
  final String sourceId;

  int get netCents => amountCents + taxCents - discountCents - refundCents;

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'category': category,
      'amountCents': amountCents,
      'taxCents': taxCents,
      'discountCents': discountCents,
      'refundCents': refundCents,
      'netCents': netCents,
      'business': business,
      if (sourceId.isNotEmpty) 'sourceId': sourceId,
    };
  }
}

class MaintainiacLedgerSummary {
  const MaintainiacLedgerSummary({
    required this.totalCents,
    required this.businessCents,
    required this.personalCents,
    required this.taxCents,
    required this.discountCents,
    required this.refundCents,
    required this.byCategory,
  });

  final int totalCents;
  final int businessCents;
  final int personalCents;
  final int taxCents;
  final int discountCents;
  final int refundCents;
  final Map<String, int> byCategory;

  Map<String, Object?> toJson() {
    return {
      'totalCents': totalCents,
      'businessCents': businessCents,
      'personalCents': personalCents,
      'taxCents': taxCents,
      'discountCents': discountCents,
      'refundCents': refundCents,
      'byCategory': byCategory,
    };
  }
}

class MaintainiacFinancialLedgerProbe {
  const MaintainiacFinancialLedgerProbe();

  MaintainiacLedgerSummary summarize(Iterable<MaintainiacLedgerLine> lines) {
    var total = 0;
    var business = 0;
    var personal = 0;
    var tax = 0;
    var discount = 0;
    var refund = 0;
    final byCategory = <String, int>{};
    for (final line in lines) {
      _validateLine(line);
      total += line.netCents;
      tax += line.taxCents;
      discount += line.discountCents;
      refund += line.refundCents;
      if (line.business) {
        business += line.netCents;
      } else {
        personal += line.netCents;
      }
      byCategory.update(
        line.category,
        (value) => value + line.netCents,
        ifAbsent: () => line.netCents,
      );
    }
    return MaintainiacLedgerSummary(
      totalCents: total,
      businessCents: business,
      personalCents: personal,
      taxCents: tax,
      discountCents: discount,
      refundCents: refund,
      byCategory: Map.unmodifiable(byCategory),
    );
  }

  MaintainiacLedgerLine inventoryConsumption({
    required String id,
    required int unitCostCents,
    required int quantity,
    required String sourceId,
    String category = 'materials',
  }) {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }
    return MaintainiacLedgerLine(
      id: id,
      category: category,
      amountCents: unitCostCents * quantity,
      sourceId: sourceId,
    );
  }

  void assertBalanced(MaintainiacLedgerSummary summary) {
    final categoryTotal = summary.byCategory.values.fold<int>(
      0,
      (sum, value) => sum + value,
    );
    if (categoryTotal != summary.totalCents) {
      throw StateError(
        'Category total $categoryTotal does not equal ${summary.totalCents}.',
      );
    }
    if (summary.businessCents + summary.personalCents != summary.totalCents) {
      throw StateError('Business/personal totals do not balance.');
    }
  }

  void _validateLine(MaintainiacLedgerLine line) {
    if (line.id.trim().isEmpty) {
      throw ArgumentError.value(line.id, 'id', 'must not be blank');
    }
    if (line.category.trim().isEmpty) {
      throw ArgumentError.value(line.category, 'category', 'must not be blank');
    }
    if (line.amountCents < 0 || line.taxCents < 0) {
      throw ArgumentError('Amount and tax cents must not be negative.');
    }
    if (line.discountCents < 0 || line.refundCents < 0) {
      throw ArgumentError('Discount and refund cents must not be negative.');
    }
  }
}
