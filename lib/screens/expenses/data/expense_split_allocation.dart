part of 'expense_ledger_models.dart';

/// User-entered evidence for a split line. The remainder is always derived,
/// so business and personal portions cannot silently exceed the printed line.
enum ExpenseSplitAllocationMethod {
  percentage,
  amount,
  quantity;

  static ExpenseSplitAllocationMethod fromName(String? value) {
    return ExpenseSplitAllocationMethod.values.firstWhere(
      (method) => method.name == value?.trim().toLowerCase(),
      orElse: () => ExpenseSplitAllocationMethod.percentage,
    );
  }
}

class ExpenseSplitAllocation {
  const ExpenseSplitAllocation({
    required this.method,
    required this.businessValue,
  });

  factory ExpenseSplitAllocation.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) {
      return const ExpenseSplitAllocation(
        method: ExpenseSplitAllocationMethod.percentage,
        businessValue: double.nan,
      );
    }
    return ExpenseSplitAllocation(
      method: ExpenseSplitAllocationMethod.fromName(
        _expenseString(map['method']),
      ),
      businessValue: _expenseDouble(map['businessValue']) ?? double.nan,
    );
  }

  final ExpenseSplitAllocationMethod method;

  /// Percentage uses 0..1. Amount uses the printed-line currency amount.
  /// Quantity uses the printed line quantity, never package count.
  final double businessValue;

  Map<String, Object?> toMap() => {
    'method': method.name,
    'businessValue': businessValue.isFinite ? businessValue : null,
  };

  double? businessPercentFor(ExpenseReceiptLineRecord line) {
    if (!businessValue.isFinite) return null;
    return switch (method) {
      ExpenseSplitAllocationMethod.percentage => _clampedPercent(businessValue),
      ExpenseSplitAllocationMethod.amount => _percentForAmount(
        subtotal: line.subtotal,
        businessAmount: businessValue,
      ),
      ExpenseSplitAllocationMethod.quantity => _percentForQuantity(
        quantity: line.quantity,
        businessQuantity: businessValue,
      ),
    };
  }

  bool isValidFor(ExpenseReceiptLineRecord line) {
    if (!businessValue.isFinite) return false;
    return switch (method) {
      ExpenseSplitAllocationMethod.percentage =>
        businessValue >= 0 && businessValue <= 1,
      ExpenseSplitAllocationMethod.amount => _isValidAmountFor(
        subtotal: line.subtotal,
        businessAmount: businessValue,
      ),
      ExpenseSplitAllocationMethod.quantity => _isValidQuantityFor(
        quantity: line.quantity,
        businessQuantity: businessValue,
      ),
    };
  }

  bool _isValidAmountFor({
    required double subtotal,
    required double businessAmount,
  }) {
    if (!subtotal.isFinite || subtotal == 0) return false;
    final percent = businessAmount / subtotal;
    return percent.isFinite && percent >= 0 && percent <= 1;
  }

  bool _isValidQuantityFor({
    required double quantity,
    required double businessQuantity,
  }) {
    return quantity.isFinite &&
        quantity > 0 &&
        businessQuantity.isFinite &&
        businessQuantity >= 0 &&
        businessQuantity <= quantity;
  }

  double? _percentForAmount({
    required double subtotal,
    required double businessAmount,
  }) {
    if (!subtotal.isFinite || !businessAmount.isFinite || subtotal == 0) {
      return null;
    }
    final percent = businessAmount / subtotal;
    return _clampedPercent(percent);
  }

  double? _percentForQuantity({
    required double quantity,
    required double businessQuantity,
  }) {
    if (!quantity.isFinite || !businessQuantity.isFinite || quantity <= 0) {
      return null;
    }
    return _clampedPercent(businessQuantity / quantity);
  }
}
