import 'expense_ledger_models.dart';

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

  /// Miles between the first and last fuel/charge odometer observations in
  /// this period. It is intentionally null until there are two observations.
  final int? drivenMiles;
  final bool hasOdometerSequenceConflict;

  double? get fuelCostPerMile => drivenMiles == null || drivenMiles! <= 0
      ? null
      : receiptPeriodMetrics.fuelExpense / drivenMiles!;

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

String _liquidFuelMetricTypeFor(ExpenseReceiptLineRecord line) {
  final fuelType = _normalizeFuelToken(line.fuelType ?? '');
  if (fuelType.isNotEmpty) return fuelType;
  final unit = _normalizeFuelToken(line.unit);
  return unit.isEmpty ? 'unclassified liquid' : unit;
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
  List<_LiquidFuelFillEvent> events, {
  required bool hasOdometerSequenceConflict,
}) {
  if (hasOdometerSequenceConflict || events.length < 2) {
    return const _CompletedLiquidFillMetrics();
  }
  final sorted = [...events]..sort(_compareFuelEventTimeline);
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
    required this.occurredAt,
    required this.receiptId,
    required this.lineId,
  });

  final int odometer;
  final double gallons;
  final bool isFullFill;
  final DateTime occurredAt;
  final String receiptId;
  final String lineId;
}

class _OdometerEvent {
  const _OdometerEvent({
    required this.odometer,
    required this.occurredAt,
    required this.receiptId,
    required this.lineId,
  });

  final int odometer;
  final DateTime occurredAt;
  final String receiptId;
  final String lineId;
}

DateTime _occurredAt(ExpenseReceiptRecord receipt) {
  final minutes = receipt.receiptTimeMinutes;
  if (minutes == null || minutes < 0 || minutes >= 24 * 60) {
    return DateTime(
      receipt.receiptDate.year,
      receipt.receiptDate.month,
      receipt.receiptDate.day,
      23,
      59,
    );
  }
  return DateTime(
    receipt.receiptDate.year,
    receipt.receiptDate.month,
    receipt.receiptDate.day,
    minutes ~/ 60,
    minutes % 60,
  );
}

int _compareFuelEventTimeline(
  _LiquidFuelFillEvent left,
  _LiquidFuelFillEvent right,
) {
  final byDate = left.occurredAt.compareTo(right.occurredAt);
  if (byDate != 0) return byDate;
  final byOdometer = left.odometer.compareTo(right.odometer);
  if (byOdometer != 0) return byOdometer;
  final byReceipt = left.receiptId.compareTo(right.receiptId);
  if (byReceipt != 0) return byReceipt;
  return left.lineId.compareTo(right.lineId);
}

bool _hasOdometerSequenceConflict(List<_OdometerEvent> events) {
  if (events.length < 2) return false;
  final sorted = [...events]
    ..sort((left, right) {
      final byDate = left.occurredAt.compareTo(right.occurredAt);
      if (byDate != 0) return byDate;
      final byOdometer = left.odometer.compareTo(right.odometer);
      if (byOdometer != 0) return byOdometer;
      final byReceipt = left.receiptId.compareTo(right.receiptId);
      if (byReceipt != 0) return byReceipt;
      return left.lineId.compareTo(right.lineId);
    });
  var previousOdometer = sorted.first.odometer;
  for (final event in sorted.skip(1)) {
    if (event.odometer < previousOdometer) return true;
    previousOdometer = event.odometer;
  }
  return false;
}

List<_OdometerEvent> _fuelOdometerEventsFor(
  Iterable<ExpenseReceiptRecord> receipts,
) {
  final events = <_OdometerEvent>[];
  for (final receipt in receipts) {
    for (final line in receipt.lines) {
      if (!_isFuelLine(line)) continue;
      final odometer = line.odometerReading ?? receipt.odometerReading;
      if (odometer == null || odometer <= 0) continue;
      events.add(
        _OdometerEvent(
          odometer: odometer,
          occurredAt: _occurredAt(receipt),
          receiptId: receipt.id,
          lineId: line.id,
        ),
      );
    }
  }
  return events;
}

_OdometerEvent? _earliestOdometerEventOnOrAfter(
  Iterable<_OdometerEvent> events,
  DateTime boundary,
) {
  return _earliestOdometerEventWhere(
    events,
    (event) => !event.occurredAt.isBefore(boundary),
  );
}

_OdometerEvent? _latestOdometerEventBefore(
  Iterable<_OdometerEvent> events,
  DateTime boundary,
) {
  return _latestOdometerEventWhere(
    events,
    (event) => event.occurredAt.isBefore(boundary),
  );
}

_OdometerEvent? _latestOdometerEventWhere(
  Iterable<_OdometerEvent> events,
  bool Function(_OdometerEvent event) predicate,
) {
  _OdometerEvent? latest;
  for (final event in events) {
    if (!predicate(event)) continue;
    if (latest == null || _compareOdometerEventTimeline(latest, event) < 0) {
      latest = event;
    }
  }
  return latest;
}

_OdometerEvent? _earliestOdometerEventWhere(
  Iterable<_OdometerEvent> events,
  bool Function(_OdometerEvent event) predicate,
) {
  _OdometerEvent? earliest;
  for (final event in events) {
    if (!predicate(event)) continue;
    if (earliest == null ||
        _compareOdometerEventTimeline(earliest, event) > 0) {
      earliest = event;
    }
  }
  return earliest;
}

int _compareOdometerEventTimeline(_OdometerEvent left, _OdometerEvent right) {
  final byDate = left.occurredAt.compareTo(right.occurredAt);
  if (byDate != 0) return byDate;
  final byOdometer = left.odometer.compareTo(right.odometer);
  if (byOdometer != 0) return byOdometer;
  final byReceipt = left.receiptId.compareTo(right.receiptId);
  if (byReceipt != 0) return byReceipt;
  return left.lineId.compareTo(right.lineId);
}

String? _normalizedVehicleId(String? vehicleId) {
  final normalized = vehicleId?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

class _CompletedLiquidFillMetrics {
  const _CompletedLiquidFillMetrics({this.miles, this.gallons = 0});

  final int? miles;
  final double gallons;
}
