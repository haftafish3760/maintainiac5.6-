import 'expense_ledger_models.dart';

part 'fuel_economy_recap_metrics.dart';
part 'fuel_economy_helpers.dart';

class FuelEconomyMetrics {
  const FuelEconomyMetrics({
    required this.fuelExpense,
    required this.liquidFuelExpense,
    required this.electricFuelExpense,
    required this.hydrogenFuelExpense,
    required this.liquidGallons,
    required this.electricKwh,
    required this.hydrogenKg,
    required this.liquidFuelTypes,
    required this.odometerMiles,
    required this.completedLiquidFillMiles,
    required this.completedLiquidFillGallons,
    required this.hasOdometerSequenceConflict,
  });

  factory FuelEconomyMetrics.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts, {
    String? vehicleId,
  }) {
    final receiptList = receipts.toList(growable: false);
    final requestedVehicleId = _normalizedVehicleId(vehicleId);
    final sourceVehicleIds = receiptList
        .where((receipt) => receipt.lines.any(_isFuelLine))
        .map((receipt) => _normalizedVehicleId(receipt.vehicleId))
        .whereType<String>()
        .toSet();
    if (requestedVehicleId == null && sourceVehicleIds.length > 1) {
      throw ArgumentError(
        'Fuel economy cannot combine multiple vehicles. Use '
        'FuelEconomyFleetMetrics.fromReceipts instead.',
      );
    }
    final selectedReceipts = requestedVehicleId == null
        ? receiptList
        : receiptList
              .where(
                (receipt) =>
                    _normalizedVehicleId(receipt.vehicleId) ==
                    requestedVehicleId,
              )
              .toList(growable: false);
    final odometers = <int>[];
    final odometerEvents = <_OdometerEvent>[];
    var fuelExpense = 0.0;
    var liquidFuelExpense = 0.0;
    var electricFuelExpense = 0.0;
    var hydrogenFuelExpense = 0.0;
    var liquidGallons = 0.0;
    var electricKwh = 0.0;
    var hydrogenKg = 0.0;
    final liquidFuelTypes = <String>{};
    final liquidFillEvents = <_LiquidFuelFillEvent>[];
    var hasExplicitLiquidFillType = false;

    for (final receipt in selectedReceipts) {
      for (final line in receipt.lines) {
        if (!_isFuelLine(line)) continue;
        final lineTotal = receipt.totalForLine(line);
        fuelExpense += lineTotal;
        final odometer = line.odometerReading ?? receipt.odometerReading;
        if (odometer != null && odometer > 0) {
          odometers.add(odometer);
          odometerEvents.add(
            _OdometerEvent(
              odometer: odometer,
              occurredAt: _occurredAt(receipt),
              receiptId: receipt.id,
              lineId: line.id,
            ),
          );
        }

        if (_isChargingFeeLine(line)) {
          electricFuelExpense += lineTotal;
        } else if (_isElectricFuelLine(line)) {
          electricFuelExpense += lineTotal;
          electricKwh += line.quantity;
        } else if (_isHydrogenFuelLine(line)) {
          hydrogenFuelExpense += lineTotal;
          hydrogenKg += line.quantity;
        } else if (!_isDieselExhaustFluidLine(line)) {
          liquidFuelExpense += lineTotal;
          liquidFuelTypes.add(_liquidFuelMetricTypeFor(line));
          final gallons = _liquidGallonsFor(line);
          liquidGallons += gallons;
          if (odometer != null && odometer > 0) {
            if ((line.fillType ?? '').trim().isNotEmpty) {
              hasExplicitLiquidFillType = true;
            }
            liquidFillEvents.add(
              _LiquidFuelFillEvent(
                odometer: odometer,
                gallons: gallons,
                isFullFill: _isFullLiquidFill(line),
                occurredAt: _occurredAt(receipt),
                receiptId: receipt.id,
                lineId: line.id,
              ),
            );
          }
        }
      }
    }

    odometers.sort();
    final hasOdometerSequenceConflict = _hasOdometerSequenceConflict(
      odometerEvents,
    );
    final hasMixedLiquidFuelTypes = liquidFuelTypes.length > 1;
    final completedFill = !hasMixedLiquidFuelTypes && hasExplicitLiquidFillType
        ? _completedLiquidFillMetrics(
            liquidFillEvents,
            hasOdometerSequenceConflict: hasOdometerSequenceConflict,
          )
        : const _CompletedLiquidFillMetrics();
    return FuelEconomyMetrics(
      fuelExpense: fuelExpense,
      liquidFuelExpense: liquidFuelExpense,
      electricFuelExpense: electricFuelExpense,
      hydrogenFuelExpense: hydrogenFuelExpense,
      liquidGallons: liquidGallons,
      electricKwh: electricKwh,
      hydrogenKg: hydrogenKg,
      liquidFuelTypes: liquidFuelTypes,
      odometerMiles: hasOdometerSequenceConflict || odometers.length < 2
          ? null
          : odometers.last - odometers.first,
      completedLiquidFillMiles: completedFill.miles,
      completedLiquidFillGallons: completedFill.gallons,
      hasOdometerSequenceConflict: hasOdometerSequenceConflict,
    );
  }

  final double fuelExpense;
  final double liquidFuelExpense;
  final double electricFuelExpense;
  final double hydrogenFuelExpense;
  final double liquidGallons;
  final double electricKwh;
  final double hydrogenKg;
  final Set<String> liquidFuelTypes;
  final int? odometerMiles;
  final int? completedLiquidFillMiles;
  final double completedLiquidFillGallons;
  final bool hasOdometerSequenceConflict;

  bool get hasMixedLiquidFuelTypes => liquidFuelTypes.length > 1;

  double? get averageMpg {
    if (hasMixedLiquidFuelTypes) return null;
    final miles = completedLiquidFillMiles ?? odometerMiles;
    final gallons = completedLiquidFillMiles == null
        ? liquidGallons
        : completedLiquidFillGallons;
    if (miles == null || miles <= 0 || gallons <= 0) return null;
    return miles / gallons;
  }

  double? get milesPerKwh {
    final miles = odometerMiles;
    if (miles == null || miles <= 0 || electricKwh <= 0) return null;
    return miles / electricKwh;
  }

  double? get milesPerHydrogenKg {
    final miles = odometerMiles;
    if (miles == null || miles <= 0 || hydrogenKg <= 0) return null;
    return miles / hydrogenKg;
  }

  double? get averageLiquidFuelPrice =>
      hasMixedLiquidFuelTypes || liquidGallons <= 0
      ? null
      : liquidFuelExpense / liquidGallons;

  double? get averageElectricKwhPrice =>
      electricKwh <= 0 ? null : electricFuelExpense / electricKwh;

  double? get averageHydrogenKgPrice =>
      hydrogenKg <= 0 ? null : hydrogenFuelExpense / hydrogenKg;

  double? get fuelCostPerMile =>
      _perMile(liquidFuelExpense + electricFuelExpense + hydrogenFuelExpense);
  double? get liquidFuelCostPerMile => _perMile(liquidFuelExpense);
  double? get electricFuelCostPerMile => _perMile(electricFuelExpense);
  double? get hydrogenFuelCostPerMile => _perMile(hydrogenFuelExpense);

  double? _perMile(double amount) {
    final miles = odometerMiles;
    if (miles == null || miles <= 0) return null;
    return amount / miles;
  }
}
