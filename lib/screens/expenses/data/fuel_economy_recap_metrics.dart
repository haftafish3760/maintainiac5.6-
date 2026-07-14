part of 'fuel_economy_metrics.dart';

class FuelRecapPeriod {
  FuelRecapPeriod({required this.start, required this.endExclusive})
    : assert(!endExclusive.isBefore(start));

  final DateTime start;
  final DateTime endExclusive;

  bool contains(DateTime value) =>
      !value.isBefore(start) && value.isBefore(endExclusive);
}

class FuelRecapMetrics {
  const FuelRecapMetrics({
    required this.period,
    required this.vehicleId,
    required this.receiptPeriodMetrics,
    required this.drivenMiles,
    required this.hasOdometerSequenceConflict,
  });

  factory FuelRecapMetrics.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts, {
    required FuelRecapPeriod period,
    required String vehicleId,
  }) {
    final normalizedVehicleId = _normalizedVehicleId(vehicleId);
    if (normalizedVehicleId == null) {
      throw ArgumentError.value(vehicleId, 'vehicleId', 'must not be blank');
    }
    final vehicleReceipts = receipts
        .where(
          (receipt) =>
              _normalizedVehicleId(receipt.vehicleId) == normalizedVehicleId,
        )
        .toList(growable: false);
    final periodReceipts = vehicleReceipts
        .where((receipt) => period.contains(_occurredAt(receipt)))
        .toList(growable: false);
    final receiptPeriodMetrics = FuelEconomyMetrics.fromReceipts(
      periodReceipts,
      vehicleId: normalizedVehicleId,
    );
    final events = _fuelOdometerEventsFor(vehicleReceipts);
    final hasConflict = _hasOdometerSequenceConflict(events);
    final startEvent = _earliestOdometerEventOnOrAfter(events, period.start);
    final endEvent = _latestOdometerEventBefore(events, period.endExclusive);
    final drivenMiles = hasConflict || startEvent == null || endEvent == null
        ? null
        : endEvent.odometer - startEvent.odometer;

    return FuelRecapMetrics(
      period: period,
      vehicleId: normalizedVehicleId,
      receiptPeriodMetrics: receiptPeriodMetrics,
      drivenMiles: drivenMiles == null || drivenMiles <= 0 ? null : drivenMiles,
      hasOdometerSequenceConflict: hasConflict,
    );
  }

  final FuelRecapPeriod period;
  final String vehicleId;
  final FuelEconomyMetrics receiptPeriodMetrics;
  final int? drivenMiles;
  final bool hasOdometerSequenceConflict;

  double? get fuelCostPerMile => drivenMiles == null || drivenMiles! <= 0
      ? null
      : (receiptPeriodMetrics.liquidFuelExpense +
                receiptPeriodMetrics.electricFuelExpense +
                receiptPeriodMetrics.hydrogenFuelExpense) /
            drivenMiles!;
  double? get liquidFuelCostPerMile => drivenMiles == null || drivenMiles! <= 0
      ? null
      : receiptPeriodMetrics.liquidFuelExpense / drivenMiles!;
  double? get electricFuelCostPerMile =>
      drivenMiles == null || drivenMiles! <= 0
      ? null
      : receiptPeriodMetrics.electricFuelExpense / drivenMiles!;
}

class FuelFleetRecapMetrics {
  const FuelFleetRecapMetrics({
    required this.metricsByVehicleId,
    required this.unassignedFuelReceiptCount,
  });

  factory FuelFleetRecapMetrics.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts, {
    required FuelRecapPeriod period,
  }) {
    final receiptList = receipts.toList(growable: false);
    final vehicleIds = receiptList
        .where((receipt) => receipt.lines.any(_isFuelLine))
        .map((receipt) => _normalizedVehicleId(receipt.vehicleId))
        .whereType<String>()
        .toSet();
    final unassignedFuelReceiptCount = receiptList.where((receipt) {
      return receipt.lines.any(_isFuelLine) &&
          _normalizedVehicleId(receipt.vehicleId) == null;
    }).length;

    return FuelFleetRecapMetrics(
      metricsByVehicleId: {
        for (final vehicleId in vehicleIds)
          vehicleId: FuelRecapMetrics.fromReceipts(
            receiptList,
            period: period,
            vehicleId: vehicleId,
          ),
      },
      unassignedFuelReceiptCount: unassignedFuelReceiptCount,
    );
  }

  final Map<String, FuelRecapMetrics> metricsByVehicleId;
  final int unassignedFuelReceiptCount;
}

class FuelEconomyFleetMetrics {
  const FuelEconomyFleetMetrics({
    required this.metricsByVehicleId,
    required this.unassignedFuelReceiptCount,
  });

  factory FuelEconomyFleetMetrics.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts,
  ) {
    final receiptsByVehicleId = <String, List<ExpenseReceiptRecord>>{};
    var unassignedFuelReceiptCount = 0;
    for (final receipt in receipts) {
      if (!receipt.lines.any(_isFuelLine)) continue;
      final vehicleId = _normalizedVehicleId(receipt.vehicleId);
      if (vehicleId == null) {
        unassignedFuelReceiptCount += 1;
        continue;
      }
      receiptsByVehicleId.putIfAbsent(vehicleId, () => []).add(receipt);
    }
    return FuelEconomyFleetMetrics(
      metricsByVehicleId: {
        for (final entry in receiptsByVehicleId.entries)
          entry.key: FuelEconomyMetrics.fromReceipts(
            entry.value,
            vehicleId: entry.key,
          ),
      },
      unassignedFuelReceiptCount: unassignedFuelReceiptCount,
    );
  }

  final Map<String, FuelEconomyMetrics> metricsByVehicleId;
  final int unassignedFuelReceiptCount;
}
