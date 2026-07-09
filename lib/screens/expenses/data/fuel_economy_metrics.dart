import 'expense_ledger_models.dart';

class FuelEconomyMetrics {
  const FuelEconomyMetrics({
    required this.fuelExpense,
    required this.liquidFuelExpense,
    required this.electricFuelExpense,
    required this.hydrogenFuelExpense,
    required this.liquidGallons,
    required this.electricKwh,
    required this.hydrogenKg,
    required this.odometerMiles,
    required this.completedLiquidFillMiles,
    required this.completedLiquidFillGallons,
  });

  factory FuelEconomyMetrics.fromReceipts(
    Iterable<ExpenseReceiptRecord> receipts,
  ) {
    final odometers = <int>[];
    var fuelExpense = 0.0;
    var liquidFuelExpense = 0.0;
    var electricFuelExpense = 0.0;
    var hydrogenFuelExpense = 0.0;
    var liquidGallons = 0.0;
    var electricKwh = 0.0;
    var hydrogenKg = 0.0;
    final liquidFillEvents = <_LiquidFuelFillEvent>[];
    var hasExplicitLiquidFillType = false;

    for (final receipt in receipts) {
      for (final line in receipt.lines) {
        if (!_isFuelLine(line)) continue;
        final lineTotal = receipt.totalForLine(line);
        fuelExpense += lineTotal;
        final odometer = line.odometerReading ?? receipt.odometerReading;
        if (odometer != null && odometer > 0) odometers.add(odometer);

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
              ),
            );
          }
        }
      }
    }

    odometers.sort();
    final completedFill = hasExplicitLiquidFillType
        ? _completedLiquidFillMetrics(liquidFillEvents)
        : const _CompletedLiquidFillMetrics();
    return FuelEconomyMetrics(
      fuelExpense: fuelExpense,
      liquidFuelExpense: liquidFuelExpense,
      electricFuelExpense: electricFuelExpense,
      hydrogenFuelExpense: hydrogenFuelExpense,
      liquidGallons: liquidGallons,
      electricKwh: electricKwh,
      hydrogenKg: hydrogenKg,
      odometerMiles: odometers.length < 2
          ? null
          : odometers.last - odometers.first,
      completedLiquidFillMiles: completedFill.miles,
      completedLiquidFillGallons: completedFill.gallons,
    );
  }

  final double fuelExpense;
  final double liquidFuelExpense;
  final double electricFuelExpense;
  final double hydrogenFuelExpense;
  final double liquidGallons;
  final double electricKwh;
  final double hydrogenKg;
  final int? odometerMiles;
  final int? completedLiquidFillMiles;
  final double completedLiquidFillGallons;

  double? get averageMpg {
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
      liquidGallons <= 0 ? null : liquidFuelExpense / liquidGallons;

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

bool _isFuelLine(ExpenseReceiptLineRecord line) {
  final category = _normalizeFuelToken(line.category);
  return category == 'fuel' || category == 'charging fees';
}

bool _isElectricFuelLine(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  final fuelType = _normalizeFuelToken(line.fuelType ?? '');
  return unit == 'kwh' || fuelType == 'electric';
}

bool _isChargingFeeLine(ExpenseReceiptLineRecord line) {
  return _normalizeFuelToken(line.category) == 'charging fees';
}

bool _isHydrogenFuelLine(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  final fuelType = _normalizeFuelToken(line.fuelType ?? '');
  return unit == 'kg' || fuelType == 'hydrogen';
}

bool _isDieselExhaustFluidLine(ExpenseReceiptLineRecord line) {
  final tokens = [
    _normalizeFuelToken(line.fuelType ?? ''),
    _normalizeFuelToken(line.description),
    _normalizeFuelToken(line.category),
  ].where((token) => token.isNotEmpty);
  return tokens.any(
    (token) =>
        token == 'def' ||
        token.contains(' diesel exhaust fluid ') ||
        token.startsWith('diesel exhaust fluid') ||
        token.endsWith('diesel exhaust fluid') ||
        token.contains(' adblue ') ||
        token.startsWith('adblue') ||
        token.endsWith('adblue') ||
        token.contains(' blue def ') ||
        token.startsWith('blue def') ||
        token.endsWith('blue def'),
  );
}

bool _isFullLiquidFill(ExpenseReceiptLineRecord line) {
  final fillType = _normalizeFuelToken(line.fillType ?? '');
  if (fillType.isEmpty) return true;
  return fillType.contains('full');
}

double _liquidGallonsFor(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  if (unit == 'liter' ||
      unit == 'litre' ||
      unit == 'liters' ||
      unit == 'litres') {
    return line.quantity * 0.2641720524;
  }
  if (unit == 'gge' ||
      unit == 'dge' ||
      unit == 'gasoline gallon equivalent' ||
      unit == 'diesel gallon equivalent') {
    return line.quantity;
  }
  return line.quantity;
}

_CompletedLiquidFillMetrics _completedLiquidFillMetrics(
  List<_LiquidFuelFillEvent> events,
) {
  if (events.length < 2) return const _CompletedLiquidFillMetrics();
  final sorted = [...events]..sort((a, b) => a.odometer.compareTo(b.odometer));
  _LiquidFuelFillEvent? lastFullFill;
  var pendingGallons = 0.0;
  var completedMiles = 0;
  var completedGallons = 0.0;

  for (final event in sorted) {
    if (lastFullFill == null) {
      if (event.isFullFill) lastFullFill = event;
      continue;
    }
    pendingGallons += event.gallons;
    if (!event.isFullFill) continue;
    final miles = event.odometer - lastFullFill.odometer;
    if (miles > 0 && pendingGallons > 0) {
      completedMiles += miles;
      completedGallons += pendingGallons;
    }
    lastFullFill = event;
    pendingGallons = 0;
  }

  return _CompletedLiquidFillMetrics(
    miles: completedMiles <= 0 ? null : completedMiles,
    gallons: completedGallons,
  );
}

String _normalizeFuelToken(String value) {
  return value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
}

class _LiquidFuelFillEvent {
  const _LiquidFuelFillEvent({
    required this.odometer,
    required this.gallons,
    required this.isFullFill,
  });

  final int odometer;
  final double gallons;
  final bool isFullFill;
}

class _CompletedLiquidFillMetrics {
  const _CompletedLiquidFillMetrics({this.miles, this.gallons = 0});

  final int? miles;
  final double gallons;
}
