part of 'trip_tracking_engine.dart';

TripTrackingEngine restoreTripTrackingEngineSnapshot(
  TripTrackingEngineSnapshot snapshot, {
  required TripTrackingPolicy policy,
  required TripTrackingProfile profile,
}) {
  final engine = TripTrackingEngine(policy: policy, profile: profile);
  // This public recovery boundary normalizes direct in-memory snapshots using
  // the same versioned rules as persisted snapshots.
  final recoveredSnapshot = TripTrackingEngineSnapshot.fromMap(
    snapshot.toMap(),
  );
  engine._lastAccepted = recoveredSnapshot.lastAccepted;
  engine._lastObservedAt = recoveredSnapshot.lastObservedAt;
  engine._lastContinuousAt =
      recoveredSnapshot.lastContinuousAt ??
      recoveredSnapshot.lastAccepted?.recordedAt;
  engine._lastObservedMonotonicElapsedNanos =
      recoveredSnapshot.lastObservedMonotonicElapsedNanos ??
      recoveredSnapshot.lastAccepted?.monotonicElapsedNanos;
  engine._lastContinuousMonotonicElapsedNanos =
      recoveredSnapshot.lastContinuousMonotonicElapsedNanos ??
      recoveredSnapshot.lastAccepted?.monotonicElapsedNanos;
  engine._totalAcceptedMeters = recoveredSnapshot.totalAcceptedMeters;
  final strategy = TripTrackingProfileStrategy.forProfile(
    profile,
    policy: policy,
  );
  final recoveredWalkingEvidence = sanitizeRecoveredWalkingEvidence(
    recoveredSnapshot.walkingEvidence,
    lastObservedAt: engine._lastObservedAt,
    maximumEvidenceAge: _safePositiveDuration(
      policy.walkingConfirmationWindow,
      _defaultWalkingConfirmationWindow,
    ),
  );
  final recoveredStationaryStartedAt =
      TripTrackingEngineAnalysis._safeRecoveredStationaryStartedAt(
        recoveredSnapshot.stationaryStartedAt,
        vehicleMovementObserved: recoveredSnapshot.vehicleMovementObserved,
        lastObservedAt: engine._lastObservedAt,
      );
  if (strategy.usesWalkingStopEvidence) {
    engine._walkingEvidence.addAll(recoveredWalkingEvidence);
    final hasRecoveredWalkingEvidence = recoveredWalkingEvidence.isNotEmpty;
    final latestWalkingEvidenceAt = hasRecoveredWalkingEvidence
        ? recoveredWalkingEvidence.last.recordedAt
        : null;
    final hasRecoveredWalkingStopEvidence = strategy.hasWalkingStopEvidence(
      walkingEvidenceCount: recoveredWalkingEvidence.length,
      observedAt:
          engine._lastObservedAt ??
          latestWalkingEvidenceAt ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      latestWalkingEvidenceAt: latestWalkingEvidenceAt,
      walkingEvidenceSpan: hasRecoveredWalkingEvidence
          ? latestWalkingEvidenceAt!.difference(
              recoveredWalkingEvidence.first.recordedAt,
            )
          : Duration.zero,
    );
    final hasRecoveredWalkingStopReview =
        recoveredSnapshot.walkingReviewSuggested &&
        recoveredSnapshot.vehicleMovementObserved &&
        hasRecoveredWalkingStopEvidence;
    engine._walkingReviewSuggested = hasRecoveredWalkingStopReview;
    engine._motionState = switch (recoveredSnapshot.motionState) {
      TripMotionState.moving when recoveredSnapshot.vehicleMovementObserved =>
        TripMotionState.moving,
      TripMotionState.stopCandidate
          when recoveredSnapshot.vehicleMovementObserved &&
              (recoveredStationaryStartedAt != null ||
                  hasRecoveredWalkingStopEvidence) =>
        TripMotionState.stopCandidate,
      TripMotionState.stopped
          when recoveredSnapshot.vehicleMovementObserved &&
              hasRecoveredWalkingStopReview =>
        TripMotionState.stopped,
      _ => TripMotionState.unknown,
    };
  } else {
    engine._walkingReviewSuggested = false;
    engine._motionState =
        recoveredSnapshot.motionState == TripMotionState.stopCandidate ||
            recoveredSnapshot.motionState == TripMotionState.stopped
        ? TripMotionState.unknown
        : recoveredSnapshot.motionState;
  }
  engine._vehicleMovementObserved = recoveredSnapshot.vehicleMovementObserved;
  engine._stationaryStartedAt = recoveredStationaryStartedAt;
  engine._diagnostics = recoveredSnapshot.diagnostics;
  return engine;
}
