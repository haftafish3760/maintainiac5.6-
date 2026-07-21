part of 'trip_tracking_models.dart';

enum TripSampleDisposition {
  acceptedAnchor,
  acceptedDistance,
  rejectedInvalid,
  rejectedMockLocation,
  rejectedAccuracy,
  rejectedOutOfOrder,
  rejectedDrift,
  rejectedImplausibleSpeed,
  rejectedSpeedConflict,
  rejectedGap,
  rejectedFutureTimestamp,
  excludedWalking,
}

class TripLocationSample {
  const TripLocationSample({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    required this.horizontalAccuracyMeters,
    this.speedMetersPerSecond,
    this.speedAccuracyMetersPerSecond,
    this.bearingDegrees,
    this.monotonicElapsedNanos,
    this.mockedLocation,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double horizontalAccuracyMeters;
  final double? speedMetersPerSecond;
  final double? speedAccuracyMetersPerSecond;
  final double? bearingDegrees;
  final int? monotonicElapsedNanos;
  final bool? mockedLocation;

  bool get hasValidCoordinate =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get hasValidAccuracy =>
      horizontalAccuracyMeters.isFinite &&
      horizontalAccuracyMeters > 0 &&
      horizontalAccuracyMeters <= _maximumNativeHorizontalAccuracyMeters;

  bool get hasValidReportedSpeed =>
      speedMetersPerSecond == null ||
      (speedMetersPerSecond!.isFinite &&
          speedMetersPerSecond! >= 0 &&
          speedMetersPerSecond! <= _maximumNativeReportedSpeedMetersPerSecond);

  bool get hasValidReportedSpeedAccuracy =>
      speedAccuracyMetersPerSecond == null ||
      (speedAccuracyMetersPerSecond!.isFinite &&
          speedAccuracyMetersPerSecond! >= 0 &&
          speedAccuracyMetersPerSecond! <=
              _maximumNativeSpeedAccuracyMetersPerSecond);

  bool get hasValidReportedBearing =>
      bearingDegrees == null ||
      (bearingDegrees!.isFinite &&
          bearingDegrees! >= 0 &&
          bearingDegrees! < 360);

  bool get hasValidMonotonicElapsedNanos =>
      monotonicElapsedNanos == null ||
      (monotonicElapsedNanos! > 0 &&
          monotonicElapsedNanos! <= _maximumNativeMonotonicElapsedNanos);

  Map<String, Object?> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'recordedAt': recordedAt.toIso8601String(),
    'horizontalAccuracyMeters': horizontalAccuracyMeters,
    'speedMetersPerSecond': _tripSpeedFrom(speedMetersPerSecond),
    if (speedAccuracyMetersPerSecond != null)
      'speedAccuracyMetersPerSecond': _tripSpeedAccuracyFrom(
        speedAccuracyMetersPerSecond,
      ),
    'bearingDegrees': _tripBearingFrom(bearingDegrees),
    if (monotonicElapsedNanos != null)
      'monotonicElapsedNanos': monotonicElapsedNanos,
    if (mockedLocation != null) 'mockedLocation': mockedLocation,
  };

  /// Parses only a complete native or persisted fix. Returning `null` is
  /// intentional: missing coordinates or a timestamp must not become a
  /// plausible-looking point at (0, 0) or at the current time.
  static TripLocationSample? tryFromMap(Map<dynamic, dynamic> map) {
    final latitude = _tripNumberFrom(map['latitude']);
    final longitude = _tripNumberFrom(map['longitude']);
    final accuracy = _tripNumberFrom(map['horizontalAccuracyMeters']);
    final recordedAt = _tripTimestampFrom(map['recordedAt']);
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        recordedAt == null) {
      return null;
    }
    if (map.containsKey('mockedLocation') && map['mockedLocation'] is! bool) {
      return null;
    }
    final monotonicElapsedNanos = map.containsKey('monotonicElapsedNanos')
        ? _tripMonotonicElapsedNanosFrom(map['monotonicElapsedNanos'])
        : null;
    if (map.containsKey('monotonicElapsedNanos') &&
        monotonicElapsedNanos == null) {
      return null;
    }
    final speedAccuracy = map.containsKey('speedAccuracyMetersPerSecond')
        ? _tripSpeedAccuracyFrom(map['speedAccuracyMetersPerSecond'])
        : null;
    if (map['speedAccuracyMetersPerSecond'] != null && speedAccuracy == null) {
      return null;
    }
    final sample = TripLocationSample(
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
      horizontalAccuracyMeters: accuracy,
      speedMetersPerSecond: _tripSpeedFrom(map['speedMetersPerSecond']),
      speedAccuracyMetersPerSecond: speedAccuracy,
      bearingDegrees: _tripBearingFrom(map['bearingDegrees']),
      monotonicElapsedNanos: monotonicElapsedNanos,
      mockedLocation: map['mockedLocation'] is bool
          ? map['mockedLocation'] as bool
          : null,
    );
    return sample.hasValidCoordinate &&
            sample.hasValidAccuracy &&
            sample.hasValidReportedSpeedAccuracy &&
            sample.hasValidReportedBearing &&
            sample.hasValidMonotonicElapsedNanos
        ? sample
        : null;
  }
}

double? _tripSpeedFrom(Object? rawSpeed) {
  final speed = _tripNumberFrom(rawSpeed);
  return speed != null &&
          speed.isFinite &&
          speed >= 0 &&
          speed <= _maximumNativeReportedSpeedMetersPerSecond
      ? speed
      : null;
}

double? _tripSpeedAccuracyFrom(Object? rawSpeedAccuracy) {
  final accuracy = _tripNumberFrom(rawSpeedAccuracy);
  return accuracy != null &&
          accuracy >= 0 &&
          accuracy <= _maximumNativeSpeedAccuracyMetersPerSecond
      ? accuracy
      : null;
}

double? _tripBearingFrom(Object? rawBearing) {
  final bearing = _tripNumberFrom(rawBearing);
  return bearing != null && bearing.isFinite && bearing >= 0 && bearing < 360
      ? bearing
      : null;
}

const _maximumNativeHorizontalAccuracyMeters = 10000.0;
const _maximumNativeReportedSpeedMetersPerSecond = 70.0;
// A poor speed estimate should reduce trust, not turn an otherwise valid GPS
// fix into a fabricated platform failure. The engine applies a much tighter
// trust threshold before speed can influence distance or cadence.
const _maximumNativeSpeedAccuracyMetersPerSecond = 1000.0;
const _maximumNativeMonotonicElapsedNanos = 9223372036854775807;

double? _tripNumberFrom(Object? value) {
  if (value is! num || !value.isFinite) return null;
  return value.toDouble();
}

int? _tripMonotonicElapsedNanosFrom(Object? value) {
  if (value is! int ||
      value <= 0 ||
      value > _maximumNativeMonotonicElapsedNanos) {
    return null;
  }
  return value;
}

DateTime? _tripTimestampFrom(Object? rawTimestamp) {
  if (rawTimestamp is! num) {
    return DateTime.tryParse('${rawTimestamp ?? ''}');
  }
  // Android location and activity APIs provide epoch milliseconds as an
  // integer. Rounding a fractional external value changes event ordering at
  // the native boundary, which can turn malformed input into a plausible
  // duplicate or out-of-order fix. Reject it instead of inventing time.
  if (!rawTimestamp.isFinite || rawTimestamp != rawTimestamp.roundToDouble()) {
    return null;
  }
  try {
    return DateTime.fromMillisecondsSinceEpoch(
      rawTimestamp.round(),
      isUtc: true,
    );
  } on ArgumentError {
    return null;
  }
}

class TripActivityObservation {
  const TripActivityObservation({
    required this.activity,
    required this.confidence,
    required this.recordedAt,
  });

  final TripActivity activity;
  final int confidence;
  final DateTime recordedAt;

  bool get isHighConfidenceWalking =>
      activity == TripActivity.walking && confidence >= 70 && confidence <= 100;

  bool get canSupportStopReview =>
      isHighConfidenceWalking && recordedAt.isAfter(_minimumTrustedSensorTime);

  Map<String, Object?> toSafeSummary() => {
    'activity': activity.name,
    'confidenceBucket': _activityConfidenceBucket(confidence),
    'canSupportStopReview': canSupportStopReview,
    'advisoryOnly': true,
    'activityRecognitionRequiresOptIn': true,
    'activityCanCreateOfficialStop': false,
    'activityCanEndTripAutomatically': false,
    'requiresAcceptedVehicleMovement': true,
    'minimumTrustedSensorYear': _minimumTrustedSensorTime.year,
    'walkingEvidenceCanOnlySuggestReview': true,
    'odometerRemainsCanonical': true,
    'odometerIsGlobalTruth': true,
    'rawSensorPayloadIncluded': false,
    'preciseTimestampIncluded': false,
    'preciseLocationIncluded': false,
  };

  Map<String, Object?> toMap() => {
    'activity': activity.name,
    'confidence': confidence,
    'recordedAt': recordedAt.toIso8601String(),
  };

  /// Parses a complete activity observation without substituting the current
  /// time for a missing native timestamp.
  static TripActivityObservation? tryFromMap(Map<dynamic, dynamic> map) {
    final rawConfidence = _tripNumberFrom(map['confidence']);
    if (rawConfidence == null) return null;
    final recordedAt = _tripTimestampFrom(map['recordedAt']);
    if (rawConfidence < 0 ||
        rawConfidence > 100 ||
        rawConfidence != rawConfidence.roundToDouble() ||
        recordedAt == null) {
      return null;
    }
    final confidence = rawConfidence.toInt();
    final activity = TripActivity.values.firstWhere(
      (value) => value.name == map['activity'],
      orElse: () => TripActivity.unknown,
    );
    if (activity == TripActivity.unknown) return null;
    return TripActivityObservation(
      activity: activity,
      confidence: confidence,
      recordedAt: recordedAt,
    );
  }
}

final DateTime _minimumTrustedSensorTime = DateTime.utc(2020);

String _activityConfidenceBucket(int confidence) {
  if (confidence < 0 || confidence > 100) return 'unknown';
  if (confidence >= 85) return 'high';
  if (confidence >= 70) return 'walkingReview';
  if (confidence >= 40) return 'medium';
  return 'low';
}
