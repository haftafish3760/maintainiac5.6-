enum TripTrackingProfile {
  roadVehicle,
  rideshareVehicle,
  deliveryVehicle,
  contractorVehicle,
  lowSpeedEquipment,
}

enum TripSamplingMode { economy, balanced, precision }

enum TripActivity { unknown, still, walking, running, cycling, automotive }

/// Shared, advisory-only interpretation of vehicle movement. It never creates
/// or closes a TripLog entry by itself.
enum TripMotionState { unknown, moving, stopCandidate, stopped }

/// A GPS-assisted suggestion. It is intentionally separate from confirmed
/// TripLog history and exists only until the driver reviews it.
enum TripTrackingAdvisoryType { probableStop, resumedMovement }

enum TripTrackingConfidence { unknown, low, medium, high }

enum TripTrackingSessionLifecycleState {
  disabled,
  permissionRequired,
  ready,
  starting,
  active,
  paused,
  degraded,
  interrupted,
  recovering,
  awaitingReview,
  stopping,
  completed,
  failedRecoverable,
  failedTerminal,
}

enum TripTrackingHealthState {
  healthy,
  reduced,
  poor,
  interrupted,
  unavailable,
  permissionBlocked,
  platformRestricted,
}

enum TripTrackingAdvisoryDisposition {
  pending,
  confirmed,
  rejected,
  corrected,
  dismissed,
}

class TripTrackingAdvisoryEvent {
  const TripTrackingAdvisoryEvent({
    required this.id,
    required this.type,
    required this.sessionId,
    required this.vehicleId,
    required this.profile,
    required this.detectedAt,
    required this.evidenceStartedAt,
    required this.evidenceEndedAt,
    required this.confidence,
    required this.suggestedAction,
    this.disposition = TripTrackingAdvisoryDisposition.pending,
    this.tripLogReference,
  });

  final String id;
  final TripTrackingAdvisoryType type;
  final String sessionId;
  final String vehicleId;
  final TripTrackingProfile profile;
  final DateTime detectedAt;
  final DateTime evidenceStartedAt;
  final DateTime evidenceEndedAt;
  final TripTrackingConfidence confidence;
  final String suggestedAction;
  final TripTrackingAdvisoryDisposition disposition;
  final String? tripLogReference;

  TripTrackingAdvisoryEvent copyWith({
    DateTime? evidenceStartedAt,
    DateTime? evidenceEndedAt,
    TripTrackingConfidence? confidence,
    TripTrackingAdvisoryDisposition? disposition,
    String? tripLogReference,
  }) => TripTrackingAdvisoryEvent(
    id: id,
    type: type,
    sessionId: sessionId,
    vehicleId: vehicleId,
    profile: profile,
    detectedAt: detectedAt,
    evidenceStartedAt: evidenceStartedAt ?? this.evidenceStartedAt,
    evidenceEndedAt: evidenceEndedAt ?? this.evidenceEndedAt,
    confidence: confidence ?? this.confidence,
    suggestedAction: suggestedAction,
    disposition: disposition ?? this.disposition,
    tripLogReference: tripLogReference ?? this.tripLogReference,
  );

  Map<String, Object?> toMap() {
    final safeEvidenceEndedAt = evidenceEndedAt.isBefore(evidenceStartedAt)
        ? evidenceStartedAt
        : evidenceEndedAt;
    return {
      'id': _safeText(id, maxLength: 160),
      'type': type.name,
      'sessionId': _safeText(sessionId, maxLength: 160),
      'vehicleId': _safeText(vehicleId, maxLength: 160),
      'profile': profile.name,
      'detectedAt': detectedAt.toIso8601String(),
      'evidenceStartedAt': evidenceStartedAt.toIso8601String(),
      'evidenceEndedAt': safeEvidenceEndedAt.toIso8601String(),
      'confidence': confidence.name,
      'suggestedAction': _safeText(suggestedAction, maxLength: 120),
      'disposition': disposition.name,
      'tripLogReference': _optionalSafeText(tripLogReference, maxLength: 160),
    };
  }

  factory TripTrackingAdvisoryEvent.fromMap(Map<dynamic, dynamic> map) {
    final detectedAt =
        _safeAdvisoryTimestamp(map['detectedAt']) ??
        _safeAdvisoryFallbackTimestamp();
    final evidenceStartedAt = _safeAdvisoryEvidenceStartedAt(
      map['evidenceStartedAt'],
      detectedAt: detectedAt,
    );
    final evidenceEndedAt = _safeAdvisoryEvidenceEndedAt(
      map['evidenceEndedAt'],
      evidenceStartedAt: evidenceStartedAt,
      detectedAt: detectedAt,
    );
    return TripTrackingAdvisoryEvent(
      id: _safeText(map['id'], maxLength: 160),
      type: TripTrackingAdvisoryType.values.firstWhere(
        (value) => value.name == map['type'],
        orElse: () => TripTrackingAdvisoryType.probableStop,
      ),
      sessionId: _safeText(map['sessionId'], maxLength: 160),
      vehicleId: _safeText(map['vehicleId'], maxLength: 160),
      profile: TripTrackingProfile.values.firstWhere(
        (value) => value.name == map['profile'],
        orElse: () => TripTrackingProfile.roadVehicle,
      ),
      detectedAt: detectedAt,
      evidenceStartedAt: evidenceStartedAt,
      evidenceEndedAt: evidenceEndedAt,
      confidence: TripTrackingConfidence.values.firstWhere(
        (value) => value.name == map['confidence'],
        orElse: () => TripTrackingConfidence.unknown,
      ),
      suggestedAction: _safeText(
        map['suggestedAction'],
        maxLength: 120,
        fallback: 'review',
      ),
      disposition: TripTrackingAdvisoryDisposition.values.firstWhere(
        (value) => value.name == map['disposition'],
        orElse: () => TripTrackingAdvisoryDisposition.pending,
      ),
      tripLogReference: _optionalSafeText(
        map['tripLogReference'],
        maxLength: 160,
      ),
    );
  }
}

DateTime _safeAdvisoryFallbackTimestamp() =>
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

DateTime? _safeAdvisoryTimestamp(Object? value) {
  if (value == null) return null;
  if (value is num) return _tripTimestampFrom(value);
  return DateTime.tryParse('$value');
}

DateTime _safeAdvisoryEvidenceStartedAt(
  Object? value, {
  required DateTime detectedAt,
}) {
  final parsed = _safeAdvisoryTimestamp(value);
  if (parsed == null || parsed.isAfter(detectedAt)) return detectedAt;
  if (detectedAt.difference(parsed) > const Duration(hours: 24)) {
    return detectedAt;
  }
  return parsed;
}

DateTime _safeAdvisoryEvidenceEndedAt(
  Object? value, {
  required DateTime evidenceStartedAt,
  required DateTime detectedAt,
}) {
  final parsed = _safeAdvisoryTimestamp(value);
  if (parsed == null) return detectedAt;
  if (parsed.isBefore(evidenceStartedAt)) return evidenceStartedAt;
  if (parsed.difference(evidenceStartedAt) > const Duration(hours: 24)) {
    return detectedAt.isBefore(evidenceStartedAt)
        ? evidenceStartedAt
        : detectedAt;
  }
  return parsed;
}

String _safeText(
  Object? value, {
  required int maxLength,
  String fallback = '',
}) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  if (clean.isEmpty) return fallback;
  return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
}

String? _optionalSafeText(Object? value, {required int maxLength}) {
  if (value == null) return null;
  final clean = _safeText(value, maxLength: maxLength);
  return clean.isEmpty ? null : clean;
}

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
    if (rawConfidence < 0 || rawConfidence > 100 || recordedAt == null) {
      return null;
    }
    final confidence = rawConfidence.floor();
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

class TripTrackingEngineSnapshot {
  const TripTrackingEngineSnapshot({
    required this.totalAcceptedMeters,
    required this.walkingReviewSuggested,
    this.motionState = TripMotionState.unknown,
    this.vehicleMovementObserved = false,
    this.stationaryStartedAt,
    this.diagnostics = const TripTrackingDiagnostics(),
    this.schemaVersion = 1,
    this.algorithmVersion = 'gps-v1',
    this.lastAccepted,
    this.lastObservedAt,
    this.lastContinuousAt,
    this.lastObservedMonotonicElapsedNanos,
    this.lastContinuousMonotonicElapsedNanos,
    this.walkingEvidence = const [],
  });

  final TripLocationSample? lastAccepted;
  final DateTime? lastObservedAt;
  final DateTime? lastContinuousAt;
  final int? lastObservedMonotonicElapsedNanos;
  final int? lastContinuousMonotonicElapsedNanos;
  final double totalAcceptedMeters;
  final List<TripActivityObservation> walkingEvidence;
  final bool walkingReviewSuggested;
  final TripMotionState motionState;
  final bool vehicleMovementObserved;
  final DateTime? stationaryStartedAt;
  final TripTrackingDiagnostics diagnostics;
  final int schemaVersion;
  final String algorithmVersion;

  Map<String, Object?> toMap() {
    final evidence = _boundedWalkingEvidence(
      walkingEvidence,
    ).toList(growable: false);
    return {
      'lastAccepted': lastAccepted?.toMap(),
      'lastObservedAt': lastObservedAt?.toIso8601String(),
      'lastContinuousAt': lastContinuousAt?.toIso8601String(),
      'lastObservedMonotonicElapsedNanos': lastObservedMonotonicElapsedNanos,
      'lastContinuousMonotonicElapsedNanos':
          lastContinuousMonotonicElapsedNanos,
      'totalAcceptedMeters': _safeAcceptedMeters(totalAcceptedMeters),
      'walkingEvidence': evidence.map((item) => item.toMap()).toList(),
      'walkingReviewSuggested': _safeWalkingReviewSuggested(
        walkingReviewSuggested,
        vehicleMovementObserved: vehicleMovementObserved,
        walkingEvidence: evidence,
      ),
      'motionState': motionState.name,
      'vehicleMovementObserved': vehicleMovementObserved,
      'stationaryStartedAt': stationaryStartedAt?.toIso8601String(),
      'diagnostics': diagnostics.toMap(),
      'schemaVersion': schemaVersion,
      'algorithmVersion': algorithmVersion,
    };
  }

  factory TripTrackingEngineSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final rawEvidence = map['walkingEvidence'];
    final parsedWalkingEvidence = rawEvidence is Iterable
        ? rawEvidence
              .whereType<Map>()
              .map(TripActivityObservation.tryFromMap)
              .whereType<TripActivityObservation>()
              .toList(growable: false)
        : const <TripActivityObservation>[];
    final vehicleMovementObserved = map['vehicleMovementObserved'] == true;
    final lastAccepted = map['lastAccepted'] is Map
        ? TripLocationSample.tryFromMap(map['lastAccepted'] as Map)
        : null;
    final lastObservedAt = _safeLastObservedAt(
      map['lastObservedAt'],
      lastAccepted: lastAccepted,
    );
    final lastContinuousAt = _safeLastContinuousAt(
      map['lastContinuousAt'],
      lastAccepted: lastAccepted,
      lastObservedAt: lastObservedAt,
    );
    final lastObservedMonotonicElapsedNanos =
        _safePersistedMonotonicElapsedNanos(
          map['lastObservedMonotonicElapsedNanos'],
          floor: lastAccepted?.monotonicElapsedNanos,
        );
    final lastContinuousMonotonicElapsedNanos =
        _safePersistedMonotonicElapsedNanos(
          map['lastContinuousMonotonicElapsedNanos'],
          floor: lastAccepted?.monotonicElapsedNanos,
          ceiling: lastObservedMonotonicElapsedNanos,
        );
    final walkingEvidence = sanitizeRecoveredWalkingEvidence(
      parsedWalkingEvidence,
      lastObservedAt: lastObservedAt,
    );
    final stationaryStartedAt = _safeStationaryStartedAt(
      map['stationaryStartedAt'],
      vehicleMovementObserved: vehicleMovementObserved,
      lastObservedAt: lastObservedAt,
    );
    return TripTrackingEngineSnapshot(
      lastAccepted: lastAccepted,
      lastObservedAt: lastObservedAt,
      lastContinuousAt: lastContinuousAt,
      lastObservedMonotonicElapsedNanos: lastObservedMonotonicElapsedNanos,
      lastContinuousMonotonicElapsedNanos: lastContinuousMonotonicElapsedNanos,
      totalAcceptedMeters: _safeAcceptedMeters(map['totalAcceptedMeters']),
      walkingEvidence: walkingEvidence,
      walkingReviewSuggested: _safeWalkingReviewSuggested(
        map['walkingReviewSuggested'] == true,
        vehicleMovementObserved: vehicleMovementObserved,
        walkingEvidence: walkingEvidence,
      ),
      motionState: _safeRecoveredMotionState(
        map['motionState'],
        vehicleMovementObserved: vehicleMovementObserved,
        stationaryStartedAt: stationaryStartedAt,
        walkingEvidence: walkingEvidence,
      ),
      vehicleMovementObserved: vehicleMovementObserved,
      stationaryStartedAt: stationaryStartedAt,
      diagnostics: map['diagnostics'] is Map
          ? TripTrackingDiagnostics.fromMap(map['diagnostics'] as Map)
          : const TripTrackingDiagnostics(),
      schemaVersion: _safeSchemaVersion(map['schemaVersion']),
      algorithmVersion: _safeAlgorithmVersion(map['algorithmVersion']),
    );
  }
}

const _maxPersistedWalkingEvidence = 12;
const _maxPersistedObservationLead = Duration(minutes: 2);

Iterable<TripActivityObservation> _boundedWalkingEvidence(
  Iterable<TripActivityObservation> evidence,
) {
  final items = evidence.toList(growable: false);
  return items.takeLast(_maxPersistedWalkingEvidence);
}

/// Removes recovery evidence that cannot safely corroborate a user-reviewable
/// stop. This is shared by map decoding and direct in-memory recovery.
List<TripActivityObservation> sanitizeRecoveredWalkingEvidence(
  Iterable<TripActivityObservation> evidence, {
  required DateTime? lastObservedAt,
}) {
  // Persisted activity evidence is advisory-only, but it still must not be
  // allowed to manufacture a stop after recovery. Remove
  // non-walking/low-confidence records, and when a location timeline is
  // available reject events that claim to occur materially after the last
  // accepted observation. Legacy pending-review records may legitimately
  // carry only advisory motion evidence, so a missing anchor cannot erase a
  // user-visible review cue by itself.
  final latestAllowed = lastObservedAt?.add(_maxPersistedObservationLead);
  final ordered =
      evidence
          .where(
            (item) =>
                item.canSupportStopReview &&
                (latestAllowed == null ||
                    !item.recordedAt.isAfter(latestAllowed)),
          )
          .toList(growable: false)
        ..sort((left, right) => left.recordedAt.compareTo(right.recordedAt));
  final seenTimestamps = <int>{};
  return _boundedWalkingEvidence(
    ordered.where(
      (item) => seenTimestamps.add(item.recordedAt.microsecondsSinceEpoch),
    ),
  ).toList(growable: false);
}

bool _safeWalkingReviewSuggested(
  bool requested, {
  required bool vehicleMovementObserved,
  required Iterable<TripActivityObservation> walkingEvidence,
}) =>
    requested &&
    vehicleMovementObserved &&
    walkingEvidence.any((item) => item.isHighConfidenceWalking);

TripMotionState _safeRecoveredMotionState(
  Object? rawValue, {
  required bool vehicleMovementObserved,
  required DateTime? stationaryStartedAt,
  required Iterable<TripActivityObservation> walkingEvidence,
}) {
  final parsed = TripMotionState.values.firstWhere(
    (value) => value.name == rawValue,
    orElse: () => TripMotionState.unknown,
  );
  if (parsed == TripMotionState.unknown) return TripMotionState.unknown;
  if (!vehicleMovementObserved) return TripMotionState.unknown;
  if (parsed == TripMotionState.moving) return TripMotionState.moving;
  if (parsed == TripMotionState.stopCandidate) {
    return stationaryStartedAt != null ||
            walkingEvidence.any((item) => item.isHighConfidenceWalking)
        ? TripMotionState.stopCandidate
        : TripMotionState.unknown;
  }
  if (parsed == TripMotionState.stopped) {
    return walkingEvidence.any((item) => item.isHighConfidenceWalking)
        ? TripMotionState.stopped
        : TripMotionState.unknown;
  }
  return TripMotionState.unknown;
}

extension _TakeLastExtension<T> on List<T> {
  Iterable<T> takeLast(int maxLength) {
    if (length <= maxLength) return this;
    return skip(length - maxLength);
  }
}

/// Coordinate-free counters retained with a session for health assessment and
/// field diagnostics. Raw locations are deliberately not copied into it.
class TripTrackingDiagnostics {
  const TripTrackingDiagnostics({
    this.receivedSamples = 0,
    this.acceptedSamples = 0,
    this.dispositionCounts = const {},
  });

  final int receivedSamples;
  final int acceptedSamples;
  final Map<TripSampleDisposition, int> dispositionCounts;

  int get rejectedSamples {
    final received = _safeNonNegativeInt(receivedSamples);
    final accepted = _safeAcceptedDiagnosticsCount(acceptedSamples, received);
    return received - accepted;
  }

  TripTrackingDiagnostics record(TripSampleDisposition disposition) {
    final counts = Map<TripSampleDisposition, int>.from(dispositionCounts);
    counts.update(disposition, (count) => count + 1, ifAbsent: () => 1);
    final accepted =
        disposition == TripSampleDisposition.acceptedAnchor ||
        disposition == TripSampleDisposition.acceptedDistance;
    return TripTrackingDiagnostics(
      receivedSamples: receivedSamples + 1,
      acceptedSamples: accepted ? acceptedSamples + 1 : acceptedSamples,
      dispositionCounts: Map.unmodifiable(counts),
    );
  }

  Map<String, Object?> toMap() {
    final received = _safeNonNegativeInt(receivedSamples);
    return {
      'receivedSamples': received,
      'acceptedSamples': _safeAcceptedDiagnosticsCount(
        acceptedSamples,
        received,
      ),
      'dispositionCounts': _safeSerializedDispositionCounts(
        dispositionCounts,
        received,
      ),
    };
  }

  factory TripTrackingDiagnostics.fromMap(Map<dynamic, dynamic> map) {
    final rawCounts = map['dispositionCounts'];
    final rawDispositionCounts = <TripSampleDisposition, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final key = entry.key;
        if (key is! String) continue;
        final disposition = TripSampleDisposition.values.where(
          (value) => value.name == key,
        );
        if (disposition.isEmpty) continue;
        final count = _safeNonNegativeInt(entry.value);
        if (count > 0) rawDispositionCounts[disposition.single] = count;
      }
    }
    final received = _safeNonNegativeInt(map['receivedSamples']);
    final accepted = _safeNonNegativeInt(map['acceptedSamples']);
    final safeCounts = _safeDispositionCounts(rawDispositionCounts, received);
    return TripTrackingDiagnostics(
      receivedSamples: received,
      acceptedSamples: _safeRestoredAcceptedDiagnosticsCount(
        accepted,
        received,
        safeCounts,
      ),
      dispositionCounts: Map.unmodifiable(safeCounts),
    );
  }
}

Map<String, Object?> _safeSerializedDispositionCounts(
  Map<TripSampleDisposition, int> counts,
  int receivedSamples,
) => {
  for (final entry in _safeDispositionCounts(counts, receivedSamples).entries)
    entry.key.name: entry.value,
};

Map<TripSampleDisposition, int> _safeDispositionCounts(
  Map<TripSampleDisposition, int> counts,
  int receivedSamples,
) {
  final received = _safeNonNegativeInt(receivedSamples);
  if (received == 0) return const {};
  var total = 0;
  final safe = <TripSampleDisposition, int>{};
  for (final entry in counts.entries) {
    final count = _safeNonNegativeInt(entry.value);
    if (count == 0 || total + count > received) continue;
    total += count;
    safe[entry.key] = count;
  }
  return Map.unmodifiable(safe);
}

int _safeAcceptedDiagnosticsCount(int acceptedSamples, int receivedSamples) {
  final received = _safeNonNegativeInt(receivedSamples);
  final accepted = _safeNonNegativeInt(acceptedSamples);
  return accepted > received ? 0 : accepted;
}

int _safeRestoredAcceptedDiagnosticsCount(
  int acceptedSamples,
  int receivedSamples,
  Map<TripSampleDisposition, int> counts,
) {
  final safeAccepted = _safeAcceptedDiagnosticsCount(
    acceptedSamples,
    receivedSamples,
  );
  final countedAccepted =
      (counts[TripSampleDisposition.acceptedAnchor] ?? 0) +
      (counts[TripSampleDisposition.acceptedDistance] ?? 0);
  if (countedAccepted > safeAccepted) return 0;
  return safeAccepted;
}

int _safeNonNegativeInt(Object? value) {
  if (value is! num || !value.isFinite) return 0;
  final parsed = value.toInt();
  return parsed < 0 ? 0 : parsed;
}

double _safeAcceptedMeters(Object? value) {
  if (value is! num) return 0;
  final meters = value.toDouble();
  return meters.isFinite && meters >= 0 ? meters : 0;
}

int _safeSchemaVersion(Object? value) {
  if (value is! num || !value.isFinite) return 1;
  final version = value.toInt();
  return version < 1 ? 1 : version;
}

String _safeAlgorithmVersion(Object? value) {
  final version = value is String ? value.trim() : '';
  if (version.isEmpty) return 'gps-v1';
  final safe = version
      .replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
  if (safe.isEmpty) return 'gps-v1';
  return safe.length > 48 ? safe.substring(0, 48) : safe;
}

DateTime? _safeLastObservedAt(
  Object? value, {
  required TripLocationSample? lastAccepted,
}) {
  if (lastAccepted == null) return null;
  final parsed = _tripTimestampFrom(value);
  if (parsed == null) return lastAccepted.recordedAt;
  if (parsed.isBefore(lastAccepted.recordedAt)) {
    return lastAccepted.recordedAt;
  }
  if (parsed.difference(lastAccepted.recordedAt) >
      _maxPersistedObservationLead) {
    return lastAccepted.recordedAt;
  }
  return parsed;
}

DateTime? _safeLastContinuousAt(
  Object? value, {
  required TripLocationSample? lastAccepted,
  required DateTime? lastObservedAt,
}) {
  if (lastAccepted == null || lastObservedAt == null) return null;
  final parsed = _tripTimestampFrom(value) ?? lastAccepted.recordedAt;
  if (parsed.isBefore(lastAccepted.recordedAt)) return lastAccepted.recordedAt;
  if (parsed.isAfter(lastObservedAt)) return lastObservedAt;
  return parsed;
}

int? _safePersistedMonotonicElapsedNanos(
  Object? value, {
  int? floor,
  int? ceiling,
}) {
  final parsed = _tripMonotonicElapsedNanosFrom(value);
  if (parsed == null) return floor;
  if (floor != null && parsed < floor) return floor;
  if (ceiling != null && parsed > ceiling) return ceiling;
  return parsed;
}

DateTime? _safeStationaryStartedAt(
  Object? value, {
  required bool vehicleMovementObserved,
  required DateTime? lastObservedAt,
}) {
  if (!vehicleMovementObserved || lastObservedAt == null) return null;
  final parsed = _tripTimestampFrom(value);
  if (parsed == null || parsed.isAfter(lastObservedAt)) return null;
  if (lastObservedAt.difference(parsed) > const Duration(hours: 8)) {
    return null;
  }
  return parsed;
}

class TripSamplingRecommendation {
  const TripSamplingRecommendation({
    required this.mode,
    required this.interval,
    required this.minimumDisplacementMeters,
  });

  final TripSamplingMode mode;
  final Duration interval;
  final double minimumDisplacementMeters;
}

class TripSampleDecision {
  const TripSampleDecision({
    required this.disposition,
    required this.totalAcceptedMeters,
    this.addedMeters = 0,
    this.walkingReviewSuggested = false,
    this.motionState = TripMotionState.unknown,
  });

  final TripSampleDisposition disposition;
  final double totalAcceptedMeters;
  final double addedMeters;
  final bool walkingReviewSuggested;
  final TripMotionState motionState;

  bool get accepted =>
      disposition == TripSampleDisposition.acceptedAnchor ||
      disposition == TripSampleDisposition.acceptedDistance;
}
