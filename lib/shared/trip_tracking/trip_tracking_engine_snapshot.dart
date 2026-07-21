part of 'trip_tracking_models.dart';

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
