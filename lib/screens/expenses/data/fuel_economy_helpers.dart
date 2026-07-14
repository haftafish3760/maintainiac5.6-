part of 'fuel_economy_metrics.dart';

bool _isFuelLine(ExpenseReceiptLineRecord line) {
  final category = _normalizeFuelToken(line.category);
  return category == 'fuel' || category == 'charging fees';
}

bool _isElectricFuelLine(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  final fuelType = _normalizeFuelToken(line.fuelType ?? '');
  return unit == 'kwh' || fuelType == 'electric';
}

bool _isChargingFeeLine(ExpenseReceiptLineRecord line) =>
    _normalizeFuelToken(line.category) == 'charging fees';

double _electricKwhFor(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  return const {'kwh', 'kilowatt hour', 'kilowatt hours'}.contains(unit)
      ? line.quantity
      : 0;
}

bool _isHydrogenFuelLine(ExpenseReceiptLineRecord line) {
  final fuelType = _normalizeFuelToken(line.fuelType ?? '');
  return fuelType == 'hydrogen';
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
        token == 'bluedef' ||
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

Set<String> _liquidFuelCompatibilityGroups(Iterable<String> fuelTypes) =>
    fuelTypes.map(_liquidFuelCompatibilityGroupFor).toSet();

String _liquidFuelCompatibilityGroupFor(String fuelType) {
  switch (_normalizeFuelToken(fuelType)) {
    case 'gasoline':
    case 'e10':
    case 'e15':
      return 'road gasoline up to e15';
    default:
      return _normalizeFuelToken(fuelType);
  }
}

bool _isFullLiquidFill(ExpenseReceiptLineRecord line) {
  final fillType = _normalizeFuelToken(line.fillType ?? '');
  return fillType.isEmpty || fillType.contains('full');
}

double _liquidGallonsFor(ExpenseReceiptLineRecord line) {
  final unit = _normalizeFuelToken(line.unit);
  if (unit == 'liter' ||
      unit == 'litre' ||
      unit == 'liters' ||
      unit == 'litres') {
    return line.quantity * 0.2641720524;
  }
  return const {'gallon', 'gallons', 'gal', 'gge', 'dge'}.contains(unit)
      ? line.quantity
      : 0;
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

String _normalizeFuelToken(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ');

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
  return byReceipt != 0 ? byReceipt : left.lineId.compareTo(right.lineId);
}

bool _hasOdometerSequenceConflict(List<_OdometerEvent> events) {
  if (events.length < 2) return false;
  final sorted = [...events]..sort(_compareOdometerEventTimeline);
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
) => _earliestOdometerEventWhere(
  events,
  (event) => !event.occurredAt.isBefore(boundary),
);
_OdometerEvent? _latestOdometerEventBefore(
  Iterable<_OdometerEvent> events,
  DateTime boundary,
) => _latestOdometerEventWhere(
  events,
  (event) => event.occurredAt.isBefore(boundary),
);

_OdometerEvent? _latestOdometerEventWhere(
  Iterable<_OdometerEvent> events,
  bool Function(_OdometerEvent event) predicate,
) {
  _OdometerEvent? latest;
  for (final event in events) {
    if (predicate(event) &&
        (latest == null || _compareOdometerEventTimeline(latest, event) < 0)) {
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
    if (predicate(event) &&
        (earliest == null ||
            _compareOdometerEventTimeline(earliest, event) > 0)) {
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
  return byReceipt != 0 ? byReceipt : left.lineId.compareTo(right.lineId);
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
