enum TripTrackingProfile { roadVehicle, lowSpeedEquipment }

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
    TripTrackingAdvisoryDisposition? disposition,
    String? tripLogReference,
  }) => TripTrackingAdvisoryEvent(
    id: id,
    type: type,
    sessionId: sessionId,
    vehicleId: vehicleId,
    profile: profile,
    detectedAt: detectedAt,
    evidenceStartedAt: evidenceStartedAt,
    evidenceEndedAt: evidenceEndedAt,
    confidence: confidence,
    suggestedAction: suggestedAction,
    disposition: disposition ?? this.disposition,
    tripLogReference: tripLogReference ?? this.tripLogReference,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'sessionId': sessionId,
    'vehicleId': vehicleId,
    'profile': profile.name,
    'detectedAt': detectedAt.toIso8601String(),
    'evidenceStartedAt': evidenceStartedAt.toIso8601String(),
    'evidenceEndedAt': evidenceEndedAt.toIso8601String(),
    'confidence': confidence.name,
    'suggestedAction': suggestedAction,
    'disposition': disposition.name,
    'tripLogReference': tripLogReference,
  };

  factory TripTrackingAdvisoryEvent.fromMap(Map<dynamic, dynamic> map) =>
      TripTrackingAdvisoryEvent(
        id: '${map['id'] ?? ''}',
        type: TripTrackingAdvisoryType.values.firstWhere(
          (value) => value.name == map['type'],
          orElse: () => TripTrackingAdvisoryType.probableStop,
        ),
        sessionId: '${map['sessionId'] ?? ''}',
        vehicleId: '${map['vehicleId'] ?? ''}',
        profile: TripTrackingProfile.values.firstWhere(
          (value) => value.name == map['profile'],
          orElse: () => TripTrackingProfile.roadVehicle,
        ),
        detectedAt:
            DateTime.tryParse('${map['detectedAt'] ?? ''}') ?? DateTime.now(),
        evidenceStartedAt:
            DateTime.tryParse('${map['evidenceStartedAt'] ?? ''}') ??
            DateTime.tryParse('${map['detectedAt'] ?? ''}') ??
            DateTime.now(),
        evidenceEndedAt:
            DateTime.tryParse('${map['evidenceEndedAt'] ?? ''}') ??
            DateTime.tryParse('${map['detectedAt'] ?? ''}') ??
            DateTime.now(),
        confidence: TripTrackingConfidence.values.firstWhere(
          (value) => value.name == map['confidence'],
          orElse: () => TripTrackingConfidence.unknown,
        ),
        suggestedAction: '${map['suggestedAction'] ?? 'review'}',
        disposition: TripTrackingAdvisoryDisposition.values.firstWhere(
          (value) => value.name == map['disposition'],
          orElse: () => TripTrackingAdvisoryDisposition.pending,
        ),
        tripLogReference: map['tripLogReference'] as String?,
      );
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
    this.mockedLocation,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double horizontalAccuracyMeters;
  final double? speedMetersPerSecond;
  final bool? mockedLocation;

  bool get hasValidCoordinate =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  bool get hasValidAccuracy =>
      horizontalAccuracyMeters.isFinite && horizontalAccuracyMeters > 0;

  Map<String, Object?> toMap() => {
    'latitude': latitude,
    'longitude': longitude,
    'recordedAt': recordedAt.toIso8601String(),
    'horizontalAccuracyMeters': horizontalAccuracyMeters,
    'speedMetersPerSecond': speedMetersPerSecond,
    if (mockedLocation != null) 'mockedLocation': mockedLocation,
  };

  /// Parses only a complete native or persisted fix. Returning `null` is
  /// intentional: missing coordinates or a timestamp must not become a
  /// plausible-looking point at (0, 0) or at the current time.
  static TripLocationSample? tryFromMap(Map<dynamic, dynamic> map) {
    final latitude = (map['latitude'] as num?)?.toDouble();
    final longitude = (map['longitude'] as num?)?.toDouble();
    final accuracy = (map['horizontalAccuracyMeters'] as num?)?.toDouble();
    final recordedAt = _tripTimestampFrom(map['recordedAt']);
    if (latitude == null ||
        longitude == null ||
        accuracy == null ||
        recordedAt == null) {
      return null;
    }
    final sample = TripLocationSample(
      latitude: latitude,
      longitude: longitude,
      recordedAt: recordedAt,
      horizontalAccuracyMeters: accuracy,
      speedMetersPerSecond: _tripSpeedFrom(map['speedMetersPerSecond']),
      mockedLocation: map['mockedLocation'] is bool
          ? map['mockedLocation'] as bool
          : null,
    );
    return sample.hasValidCoordinate && sample.hasValidAccuracy ? sample : null;
  }
}

double? _tripSpeedFrom(Object? rawSpeed) {
  final speed = (rawSpeed as num?)?.toDouble();
  return speed != null && speed.isFinite && speed >= 0 ? speed : null;
}

DateTime? _tripTimestampFrom(Object? rawTimestamp) {
  if (rawTimestamp is! num) {
    return DateTime.tryParse('${rawTimestamp ?? ''}');
  }
  if (!rawTimestamp.isFinite) return null;
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
      activity == TripActivity.walking && confidence >= 70;

  Map<String, Object?> toMap() => {
    'activity': activity.name,
    'confidence': confidence,
    'recordedAt': recordedAt.toIso8601String(),
  };

  /// Parses a complete activity observation without substituting the current
  /// time for a missing native timestamp.
  static TripActivityObservation? tryFromMap(Map<dynamic, dynamic> map) {
    final rawConfidence = map['confidence'] as num?;
    if (rawConfidence == null || !rawConfidence.isFinite) return null;
    final confidence = rawConfidence.round();
    final recordedAt = DateTime.tryParse('${map['recordedAt'] ?? ''}');
    if (confidence < 0 || confidence > 100 || recordedAt == null) {
      return null;
    }
    return TripActivityObservation(
      activity: TripActivity.values.firstWhere(
        (value) => value.name == map['activity'],
        orElse: () => TripActivity.unknown,
      ),
      confidence: confidence,
      recordedAt: recordedAt,
    );
  }
}

class TripTrackingEngineSnapshot {
  const TripTrackingEngineSnapshot({
    required this.totalAcceptedMeters,
    required this.walkingReviewSuggested,
    this.motionState = TripMotionState.unknown,
    this.vehicleMovementObserved = false,
    this.diagnostics = const TripTrackingDiagnostics(),
    this.schemaVersion = 1,
    this.algorithmVersion = 'gps-v1',
    this.lastAccepted,
    this.lastObservedAt,
    this.walkingEvidence = const [],
  });

  final TripLocationSample? lastAccepted;
  final DateTime? lastObservedAt;
  final double totalAcceptedMeters;
  final List<TripActivityObservation> walkingEvidence;
  final bool walkingReviewSuggested;
  final TripMotionState motionState;
  final bool vehicleMovementObserved;
  final TripTrackingDiagnostics diagnostics;
  final int schemaVersion;
  final String algorithmVersion;

  Map<String, Object?> toMap() => {
    'lastAccepted': lastAccepted?.toMap(),
    'lastObservedAt': lastObservedAt?.toIso8601String(),
    'totalAcceptedMeters': totalAcceptedMeters,
    'walkingEvidence': walkingEvidence.map((item) => item.toMap()).toList(),
    'walkingReviewSuggested': walkingReviewSuggested,
    'motionState': motionState.name,
    'vehicleMovementObserved': vehicleMovementObserved,
    'diagnostics': diagnostics.toMap(),
    'schemaVersion': schemaVersion,
    'algorithmVersion': algorithmVersion,
  };

  factory TripTrackingEngineSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final rawEvidence = map['walkingEvidence'];
    return TripTrackingEngineSnapshot(
      lastAccepted: map['lastAccepted'] is Map
          ? TripLocationSample.tryFromMap(map['lastAccepted'] as Map)
          : null,
      lastObservedAt: DateTime.tryParse('${map['lastObservedAt'] ?? ''}'),
      totalAcceptedMeters: _safeAcceptedMeters(map['totalAcceptedMeters']),
      walkingEvidence: rawEvidence is Iterable
          ? rawEvidence
                .whereType<Map>()
                .map(TripActivityObservation.tryFromMap)
                .whereType<TripActivityObservation>()
                .toList(growable: false)
          : const [],
      walkingReviewSuggested: map['walkingReviewSuggested'] == true,
      motionState: TripMotionState.values.firstWhere(
        (value) => value.name == map['motionState'],
        orElse: () => TripMotionState.unknown,
      ),
      vehicleMovementObserved: map['vehicleMovementObserved'] == true,
      diagnostics: map['diagnostics'] is Map
          ? TripTrackingDiagnostics.fromMap(map['diagnostics'] as Map)
          : const TripTrackingDiagnostics(),
      schemaVersion: _safeSchemaVersion(map['schemaVersion']),
      algorithmVersion: _safeAlgorithmVersion(map['algorithmVersion']),
    );
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

  int get rejectedSamples => receivedSamples - acceptedSamples;

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

  Map<String, Object?> toMap() => {
    'receivedSamples': receivedSamples,
    'acceptedSamples': acceptedSamples,
    'dispositionCounts': {
      for (final entry in dispositionCounts.entries)
        entry.key.name: entry.value,
    },
  };

  factory TripTrackingDiagnostics.fromMap(Map<dynamic, dynamic> map) {
    final rawCounts = map['dispositionCounts'];
    final counts = <TripSampleDisposition, int>{};
    if (rawCounts is Map) {
      for (final entry in rawCounts.entries) {
        final disposition = TripSampleDisposition.values.firstWhere(
          (value) => value.name == entry.key,
          orElse: () => TripSampleDisposition.rejectedInvalid,
        );
        final count = (entry.value as num?)?.toInt() ?? 0;
        if (count > 0) counts[disposition] = count;
      }
    }
    final received = (map['receivedSamples'] as num?)?.toInt() ?? 0;
    final accepted = (map['acceptedSamples'] as num?)?.toInt() ?? 0;
    return TripTrackingDiagnostics(
      receivedSamples: received < 0 ? 0 : received,
      acceptedSamples: accepted < 0 || accepted > received ? 0 : accepted,
      dispositionCounts: Map.unmodifiable(counts),
    );
  }
}

double _safeAcceptedMeters(Object? value) {
  final meters = (value as num?)?.toDouble() ?? 0;
  return meters.isFinite && meters >= 0 ? meters : 0;
}

int _safeSchemaVersion(Object? value) {
  final version = (value as num?)?.toInt() ?? 1;
  return version < 1 ? 1 : version;
}

String _safeAlgorithmVersion(Object? value) {
  final version = value is String ? value.trim() : '';
  return version.isEmpty ? 'gps-v1' : version;
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
