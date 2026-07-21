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
    this.signalGaps = const [],
    this.initialFixAssessment,
    this.initialFixHistory = const [],
  });

  final TripLocationSample? lastAccepted;
  final DateTime? lastObservedAt;
  final DateTime? lastContinuousAt;
  final int? lastObservedMonotonicElapsedNanos;
  final int? lastContinuousMonotonicElapsedNanos;
  final double totalAcceptedMeters;
  final List<TripActivityObservation> walkingEvidence;
  final List<TripTrackingSignalGap> signalGaps;
  final TripInitialFixAssessment? initialFixAssessment;
  final List<TripInitialFixAssessment> initialFixHistory;
  final bool walkingReviewSuggested;
  final TripMotionState motionState;
  final bool vehicleMovementObserved;
  final DateTime? stationaryStartedAt;
  final TripTrackingDiagnostics diagnostics;
  final int schemaVersion;
  final String algorithmVersion;

  /// Derived from the single persisted engine snapshot so recovery does not
  /// create a second source of truth for temporary-stop evidence.
  TripStopCandidate? get currentStopCandidate {
    if (motionState != TripMotionState.stopCandidate &&
        motionState != TripMotionState.stopped) {
      return null;
    }
    final hasWalkingEvidence = walkingEvidence.isNotEmpty;
    final candidateStartedAt =
        stationaryStartedAt ??
        (hasWalkingEvidence ? walkingEvidence.first.recordedAt : null);
    final candidateDetectedAt =
        lastObservedAt ??
        (hasWalkingEvidence ? walkingEvidence.last.recordedAt : null);
    if (candidateStartedAt == null ||
        candidateDetectedAt == null ||
        candidateDetectedAt.isBefore(candidateStartedAt)) {
      return null;
    }
    return TripStopCandidate(
      startedAt: candidateStartedAt,
      detectedAt: candidateDetectedAt,
      confidence:
          motionState == TripMotionState.stopped && walkingReviewSuggested
          ? TripTrackingConfidence.high
          : hasWalkingEvidence
          ? TripTrackingConfidence.medium
          : TripTrackingConfidence.low,
      evidence: hasWalkingEvidence
          ? TripStopCandidateEvidence.walkingAssisted
          : TripStopCandidateEvidence.stationaryGps,
    );
  }

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
      'signalGaps': signalGaps.map((item) => item.toMap()).toList(),
      'initialFixAssessment': initialFixAssessment?.toMap(),
      'initialFixHistory': initialFixHistory
          .skip(initialFixHistory.length > 8 ? initialFixHistory.length - 8 : 0)
          .map((item) => item.toMap())
          .toList(growable: false),
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
    final legacyInitialFix = map['initialFixAssessment'] is Map
        ? TripInitialFixAssessment.tryFromMap(
            map['initialFixAssessment'] as Map,
          )
        : null;
    final parsedInitialFixHistory = map['initialFixHistory'] is Iterable
        ? (map['initialFixHistory'] as Iterable)
              .whereType<Map>()
              .map(TripInitialFixAssessment.tryFromMap)
              .whereType<TripInitialFixAssessment>()
              .toList(growable: false)
        : const <TripInitialFixAssessment>[];
    final initialFixHistory = parsedInitialFixHistory.isNotEmpty
        ? parsedInitialFixHistory
              .skip(
                parsedInitialFixHistory.length > 8
                    ? parsedInitialFixHistory.length - 8
                    : 0,
              )
              .toList(growable: false)
        : legacyInitialFix == null
        ? const <TripInitialFixAssessment>[]
        : <TripInitialFixAssessment>[legacyInitialFix];
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
      signalGaps: _safeSignalGaps(map['signalGaps']),
      initialFixAssessment: initialFixHistory.isEmpty
          ? legacyInitialFix
          : initialFixHistory.last,
      initialFixHistory: initialFixHistory,
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

List<TripTrackingSignalGap> _safeSignalGaps(Object? value) {
  if (value is! Iterable) return const [];
  final recovered = <TripTrackingSignalGap>[];
  for (final raw in value.whereType<Map>()) {
    final gap = TripTrackingSignalGap.tryFromMap(raw);
    if (gap == null) continue;
    if (recovered.isNotEmpty) {
      final previous = recovered.last;
      if (previous.isOpen || gap.startedAt.isBefore(previous.startedAt)) {
        continue;
      }
    }
    recovered.add(gap);
  }
  return List.unmodifiable(recovered);
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
  Duration? maximumEvidenceAge,
}) {
  // Persisted activity evidence is advisory-only, but it still must not be
  // allowed to manufacture a stop after recovery. Remove
  // non-walking/low-confidence records, and when a location timeline is
  // available reject events that claim to occur materially after the last
  // accepted observation. Legacy pending-review records may legitimately
  // carry only advisory motion evidence, so a missing anchor cannot erase a
  // user-visible review cue by itself.
  final latestAllowed = lastObservedAt?.add(_maxPersistedObservationLead);
  final earliestAllowed =
      lastObservedAt != null &&
          maximumEvidenceAge != null &&
          !maximumEvidenceAge.isNegative &&
          maximumEvidenceAge > Duration.zero
      ? lastObservedAt.subtract(maximumEvidenceAge)
      : null;
  final ordered =
      evidence
          .where(
            (item) =>
                item.canSupportStopReview &&
                (earliestAllowed == null ||
                    !item.recordedAt.isBefore(earliestAllowed)) &&
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
