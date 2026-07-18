import 'trip_tracking_models.dart';
import 'trip_tracking_session_store.dart';

class TripStopAdvisoryReviewer {
  const TripStopAdvisoryReviewer._();

  static bool isFinalReviewDisposition(
    TripTrackingAdvisoryDisposition disposition,
  ) =>
      disposition == TripTrackingAdvisoryDisposition.confirmed ||
      disposition == TripTrackingAdvisoryDisposition.rejected ||
      disposition == TripTrackingAdvisoryDisposition.corrected ||
      disposition == TripTrackingAdvisoryDisposition.dismissed;

  static int latestPendingStopReviewIndex(
    TripTrackingSessionRecord session, {
    required bool preferHighConfidence,
  }) {
    bool matches(TripTrackingAdvisoryEvent event) =>
        event.type == TripTrackingAdvisoryType.probableStop &&
        event.disposition == TripTrackingAdvisoryDisposition.pending;
    if (preferHighConfidence) {
      final highConfidenceIndex = session.advisories.lastIndexWhere(
        (event) =>
            matches(event) && event.confidence == TripTrackingConfidence.high,
      );
      if (highConfidenceIndex >= 0) return highConfidenceIndex;
    }
    return session.advisories.lastIndexWhere(matches);
  }

  static List<TripTrackingAdvisoryEvent> afterMotionTransition(
    TripTrackingSessionRecord session, {
    required TripTrackingEngineSnapshot engineSnapshot,
    required TripMotionState previousMotionState,
    required TripMotionState currentMotionState,
    required DateTime detectedAt,
  }) {
    if (previousMotionState == TripMotionState.stopCandidate &&
        currentMotionState == TripMotionState.stopped) {
      return upgradedStopCandidateAdvisories(session, detectedAt: detectedAt);
    }
    final type = _transitionType(
      previousMotionState: previousMotionState,
      currentMotionState: currentMotionState,
    );
    if (type == null) return session.advisories;
    if (type == TripTrackingAdvisoryType.resumedMovement &&
        !hasActiveStopReview(session)) {
      return session.advisories;
    }
    final evidenceStartedAt = _evidenceStartedAt(
      type: type,
      engineSnapshot: engineSnapshot,
      detectedAt: detectedAt,
    );
    return [
      ...session.advisories,
      TripTrackingAdvisoryEvent(
        id: '${session.id}:${type.name}:${detectedAt.microsecondsSinceEpoch}',
        type: type,
        sessionId: session.id,
        vehicleId: session.vehicleId,
        profile: session.profile,
        detectedAt: detectedAt,
        evidenceStartedAt: evidenceStartedAt,
        evidenceEndedAt: detectedAt,
        confidence: currentMotionState == TripMotionState.stopped
            ? TripTrackingConfidence.high
            : TripTrackingConfidence.medium,
        suggestedAction: type == TripTrackingAdvisoryType.probableStop
            ? 'reviewStop'
            : 'reviewResumedMovement',
      ),
    ];
  }

  static bool hasActiveStopReview(TripTrackingSessionRecord session) {
    final latestStopIndex = session.advisories.lastIndexWhere(
      (event) => event.type == TripTrackingAdvisoryType.probableStop,
    );
    if (latestStopIndex < 0) return false;
    return switch (session.advisories[latestStopIndex].disposition) {
      TripTrackingAdvisoryDisposition.rejected ||
      TripTrackingAdvisoryDisposition.dismissed => false,
      _ => true,
    };
  }

  static List<TripTrackingAdvisoryEvent> upgradedStopCandidateAdvisories(
    TripTrackingSessionRecord session, {
    required DateTime detectedAt,
  }) {
    final latestPendingStopIndex = session.advisories.lastIndexWhere(
      (event) =>
          event.type == TripTrackingAdvisoryType.probableStop &&
          (event.disposition == TripTrackingAdvisoryDisposition.pending ||
              event.disposition == TripTrackingAdvisoryDisposition.confirmed),
    );
    if (latestPendingStopIndex < 0) return session.advisories;
    final advisories = [...session.advisories];
    advisories[latestPendingStopIndex] = advisories[latestPendingStopIndex]
        .copyWith(
          evidenceEndedAt: detectedAt,
          confidence: TripTrackingConfidence.high,
        );
    return advisories;
  }

  static TripTrackingAdvisoryType? _transitionType({
    required TripMotionState previousMotionState,
    required TripMotionState currentMotionState,
  }) {
    if (!_isStopLikeMotion(previousMotionState) &&
        _isStopLikeMotion(currentMotionState)) {
      return TripTrackingAdvisoryType.probableStop;
    }
    if (_isStopLikeMotion(previousMotionState) &&
        currentMotionState == TripMotionState.moving) {
      return TripTrackingAdvisoryType.resumedMovement;
    }
    return null;
  }

  static bool _isStopLikeMotion(TripMotionState state) =>
      state == TripMotionState.stopCandidate ||
      state == TripMotionState.stopped;

  static DateTime _evidenceStartedAt({
    required TripTrackingAdvisoryType type,
    required TripTrackingEngineSnapshot engineSnapshot,
    required DateTime detectedAt,
  }) {
    if (type != TripTrackingAdvisoryType.probableStop) return detectedAt;
    if (engineSnapshot.walkingEvidence.isNotEmpty) {
      return engineSnapshot.walkingEvidence.first.recordedAt;
    }
    final stationaryStartedAt = engineSnapshot.stationaryStartedAt;
    if (stationaryStartedAt == null ||
        stationaryStartedAt.isAfter(detectedAt)) {
      return detectedAt;
    }
    return stationaryStartedAt;
  }
}
