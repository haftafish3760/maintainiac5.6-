/// Durable vehicle and work-profile boundaries within one active workday.
///
/// Owns one user-confirmed context interval and its per-vehicle odometer
/// boundary. Does not own workday persistence, GPS sessions, or financial
/// records. Consumed by ActiveWorkdaySessionRecord during safe context
/// handoffs. A segment never rewrites a previously closed context.
class ActiveWorkdayContextSegment {
  const ActiveWorkdayContextSegment({
    required this.id,
    required this.vehicleId,
    required this.vehicleLabel,
    required this.workProfileId,
    required this.startedAt,
    required this.startOdometer,
    this.endedAt,
    this.endOdometer,
  });

  final String id;
  final String vehicleId;
  final String vehicleLabel;
  final String workProfileId;
  final DateTime startedAt;
  final int startOdometer;
  final DateTime? endedAt;
  final int? endOdometer;

  bool get isOpen => endedAt == null && endOdometer == null;

  bool get isClosed => !isOpen;

  int milesAt(int currentOdometer) {
    final ending = endOdometer ?? currentOdometer;
    final delta = ending - startOdometer;
    return delta < 0 ? 0 : delta;
  }

  bool matchesContext({
    required String vehicleId,
    required String workProfileId,
  }) =>
      this.vehicleId == vehicleId.trim() &&
      this.workProfileId == workProfileId.trim();

  ActiveWorkdayContextSegment close({
    required DateTime endedAt,
    required int endOdometer,
  }) {
    if (!isOpen) {
      throw StateError(
        'A closed workday context segment cannot be closed again.',
      );
    }
    if (endedAt.isBefore(startedAt)) {
      throw ArgumentError.value(
        endedAt,
        'endedAt',
        'A context segment cannot end before it starts.',
      );
    }
    if (endOdometer < startOdometer) {
      throw ArgumentError.value(
        endOdometer,
        'endOdometer',
        'A context segment cannot end below its starting odometer.',
      );
    }
    return ActiveWorkdayContextSegment(
      id: id,
      vehicleId: vehicleId,
      vehicleLabel: vehicleLabel,
      workProfileId: workProfileId,
      startedAt: startedAt,
      startOdometer: startOdometer,
      endedAt: endedAt,
      endOdometer: endOdometer,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'vehicleId': vehicleId,
    'vehicleLabel': vehicleLabel,
    'workProfileId': workProfileId,
    'startedAt': startedAt.toUtc().toIso8601String(),
    'startOdometer': startOdometer,
    'endedAt': endedAt?.toUtc().toIso8601String(),
    'endOdometer': endOdometer,
  };

  static ActiveWorkdayContextSegment? tryFromMap(Map<dynamic, dynamic> map) {
    final id = map['id'];
    final vehicleId = map['vehicleId'];
    final vehicleLabel = map['vehicleLabel'];
    final workProfileId = map['workProfileId'];
    final startedAt = DateTime.tryParse('${map['startedAt'] ?? ''}');
    final startOdometer = _nonNegativeInt(map['startOdometer']);
    final rawEndedAt = map['endedAt'];
    final rawEndOdometer = map['endOdometer'];
    final endedAt = rawEndedAt == null
        ? null
        : DateTime.tryParse('$rawEndedAt');
    final endOdometer = rawEndOdometer == null
        ? null
        : _nonNegativeInt(rawEndOdometer);
    final hasValidIdentity =
        _safeToken(id, maximumLength: 160) &&
        _safeToken(vehicleId, maximumLength: 160) &&
        _safeLabel(vehicleLabel) &&
        _safeToken(workProfileId, maximumLength: 160);
    final hasValidOpening = startedAt != null && startOdometer != null;
    final hasMatchedClosure =
        (endedAt == null && endOdometer == null) ||
        (endedAt != null &&
            endOdometer != null &&
            !endedAt.isBefore(startedAt ?? endedAt) &&
            endOdometer >= (startOdometer ?? endOdometer));
    if (!hasValidIdentity || !hasValidOpening || !hasMatchedClosure) {
      return null;
    }
    return ActiveWorkdayContextSegment(
      id: id as String,
      vehicleId: vehicleId as String,
      vehicleLabel: vehicleLabel as String,
      workProfileId: workProfileId as String,
      startedAt: startedAt,
      startOdometer: startOdometer,
      endedAt: endedAt,
      endOdometer: endOdometer,
    );
  }
}

int? _nonNegativeInt(Object? value) {
  if (value is int && value >= 0) return value;
  if (value is num && value.isFinite && value == value.round() && value >= 0) {
    return value.toInt();
  }
  return null;
}

bool _safeToken(Object? value, {required int maximumLength}) {
  if (value is! String || value.isEmpty || value.length > maximumLength) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value);
}

bool _safeLabel(Object? value) {
  if (value is! String || value.trim().isEmpty || value.length > 120) {
    return false;
  }
  return !RegExp(r'[\x00-\x1F\x7F]').hasMatch(value);
}
