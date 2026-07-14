part of 'expense_recap_models.dart';

class _ExpenseRecapFuelSummary {
  const _ExpenseRecapFuelSummary({
    required this.liquidFuelExpense,
    required this.electricFuelExpense,
    required this.liquidGallons,
    required this.electricKwh,
    required this.odometerMiles,
    required this.completedLiquidFillMiles,
    required this.completedLiquidFillGallons,
    required this.hasMixedLiquidFuelTypes,
  });

  factory _ExpenseRecapFuelSummary.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts,
  ) {
    final grouped = <String, List<ExpenseReceiptRecord>>{};
    for (final receipt in receipts) {
      if (!receipt.lines.any(_isFuelReceiptLine)) continue;
      final vehicleId = receipt.vehicleId?.trim() ?? '';
      grouped.putIfAbsent(vehicleId, () => []).add(receipt);
    }
    if (grouped.length <= 1) {
      final metrics = FuelEconomyMetrics.fromReceipts(receipts);
      return _ExpenseRecapFuelSummary._fromMetrics(metrics);
    }

    final metrics = grouped.values
        .map(FuelEconomyMetrics.fromReceipts)
        .toList(growable: false);
    return _ExpenseRecapFuelSummary(
      liquidFuelExpense: metrics.fold(
        0,
        (total, metric) => total + metric.liquidFuelExpense,
      ),
      electricFuelExpense: metrics.fold(
        0,
        (total, metric) => total + metric.electricFuelExpense,
      ),
      liquidGallons: metrics.fold(
        0,
        (total, metric) => total + metric.liquidGallons,
      ),
      electricKwh: metrics.fold(0, (total, metric) => total + metric.electricKwh),
      odometerMiles: null,
      completedLiquidFillMiles: null,
      completedLiquidFillGallons: 0,
      hasMixedLiquidFuelTypes: true,
    );
  }

  factory _ExpenseRecapFuelSummary._fromMetrics(FuelEconomyMetrics metrics) {
    return _ExpenseRecapFuelSummary(
      liquidFuelExpense: metrics.liquidFuelExpense,
      electricFuelExpense: metrics.electricFuelExpense,
      liquidGallons: metrics.liquidGallons,
      electricKwh: metrics.electricKwh,
      odometerMiles: metrics.odometerMiles,
      completedLiquidFillMiles: metrics.completedLiquidFillMiles,
      completedLiquidFillGallons: metrics.completedLiquidFillGallons,
      hasMixedLiquidFuelTypes: metrics.hasMixedLiquidFuelTypes,
    );
  }

  final double liquidFuelExpense;
  final double electricFuelExpense;
  final double liquidGallons;
  final double electricKwh;
  final int? odometerMiles;
  final int? completedLiquidFillMiles;
  final double completedLiquidFillGallons;
  final bool hasMixedLiquidFuelTypes;
}

bool _isFuelReceiptLine(ExpenseReceiptLineRecord line) {
  final category = line.category.trim().toLowerCase();
  return category == 'fuel' || category == 'charging fees';
}
