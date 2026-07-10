class MaintainiacPricedLine {
  const MaintainiacPricedLine({
    required this.id,
    required this.sourceId,
    required this.unitCostCents,
    required this.quantity,
    this.taxCents = 0,
    this.discountCents = 0,
    this.markupBasisPoints = 0,
    this.sourceMutationAllowed = false,
  });

  final String id;
  final String sourceId;
  final int unitCostCents;
  final int quantity;
  final int taxCents;
  final int discountCents;
  final int markupBasisPoints;
  final bool sourceMutationAllowed;

  int get subtotalCents => unitCostCents * quantity;

  int get markupCents {
    return ((subtotalCents * markupBasisPoints) / 10000).round();
  }

  int get totalCents => subtotalCents + taxCents + markupCents - discountCents;

  List<int> allocateTaxPerUnit() {
    if (quantity <= 0) {
      throw ArgumentError.value(quantity, 'quantity', 'must be positive');
    }
    final base = taxCents ~/ quantity;
    final remainder = taxCents.remainder(quantity);
    return [
      for (var index = 0; index < quantity; index++)
        base + (index < remainder ? 1 : 0),
    ];
  }

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('priced line missing id');
    if (sourceId.trim().isEmpty) failures.add('$id missing source id');
    if (unitCostCents < 0) failures.add('$id unit cost must not be negative');
    if (quantity <= 0) failures.add('$id quantity must be positive');
    if (taxCents < 0) failures.add('$id tax must not be negative');
    if (discountCents < 0) failures.add('$id discount must not be negative');
    if (markupBasisPoints < 0) failures.add('$id markup must not be negative');
    if (discountCents > subtotalCents + taxCents + markupCents) {
      failures.add('$id discount cannot exceed line total');
    }
    if (sourceMutationAllowed) {
      failures.add('$id estimate/invoice pricing must not mutate source data');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sourceId': sourceId,
      'unitCostCents': unitCostCents,
      'quantity': quantity,
      'subtotalCents': subtotalCents,
      'taxCents': taxCents,
      'discountCents': discountCents,
      'markupBasisPoints': markupBasisPoints,
      'markupCents': markupCents,
      'totalCents': totalCents,
      'sourceMutationAllowed': sourceMutationAllowed,
    };
  }
}

class MaintainiacPricingContract {
  const MaintainiacPricingContract(this.lines);

  final List<MaintainiacPricedLine> lines;

  int get subtotalCents {
    return lines.fold(0, (sum, line) => sum + line.subtotalCents);
  }

  int get taxCents {
    return lines.fold(0, (sum, line) => sum + line.taxCents);
  }

  int get markupCents {
    return lines.fold(0, (sum, line) => sum + line.markupCents);
  }

  int get discountCents {
    return lines.fold(0, (sum, line) => sum + line.discountCents);
  }

  int get totalCents {
    return lines.fold(0, (sum, line) => sum + line.totalCents);
  }

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (lines.isEmpty) failures.add('pricing contract has no lines');
    for (final line in lines) {
      if (!ids.add(line.id)) {
        failures.add('duplicate priced line id ${line.id}');
      }
      failures.addAll(line.validate());
      if (line.quantity > 0) {
        final allocated = line.allocateTaxPerUnit();
        final allocatedTotal = allocated.fold(0, (sum, cents) => sum + cents);
        if (allocatedTotal != line.taxCents) {
          failures.add('${line.id} allocated tax does not equal tax total');
        }
      }
    }
    if (subtotalCents + taxCents + markupCents - discountCents != totalCents) {
      failures.add('pricing totals do not balance');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'lineCount': lines.length,
      'subtotalCents': subtotalCents,
      'taxCents': taxCents,
      'markupCents': markupCents,
      'discountCents': discountCents,
      'totalCents': totalCents,
      'lines': [for (final line in lines) line.toJson()],
    };
  }
}
