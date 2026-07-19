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
    if (!_canCreateAdvisoryForSession(session)) return session.advisories;
    final safeDetectedAt = _safeDetectedAt(session, detectedAt);
    if (previousMotionState == TripMotionState.stopCandidate &&
        currentMotionState == TripMotionState.stopped) {
      return upgradedStopCandidateAdvisories(
        session,
        detectedAt: safeDetectedAt,
      );
    }
    if (currentMotionState == TripMotionState.stopped &&
        engineSnapshot.walkingEvidence.any(
          (item) => item.recordedAt == safeDetectedAt,
        )) {
      return extendConfirmedWalkingStopAdvisory(
        session,
        detectedAt: safeDetectedAt,
      );
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
    if (_hasSameTransition(session, type: type, detectedAt: safeDetectedAt)) {
      return session.advisories;
    }
    final evidenceStartedAt = _evidenceStartedAt(
      type: type,
      engineSnapshot: engineSnapshot,
      session: session,
      detectedAt: safeDetectedAt,
    );
    return [
      ...session.advisories,
      TripTrackingAdvisoryEvent(
        id: '${session.id}:${type.name}:${safeDetectedAt.microsecondsSinceEpoch}',
        type: type,
        sessionId: session.id,
        vehicleId: session.vehicleId,
        profile: session.profile,
        detectedAt: safeDetectedAt,
        evidenceStartedAt: evidenceStartedAt,
        evidenceEndedAt: safeDetectedAt,
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
    if (!_canCreateAdvisoryForSession(session)) return session.advisories;
    final latestPendingStopIndex = session.advisories.lastIndexWhere(
      (event) =>
          event.type == TripTrackingAdvisoryType.probableStop &&
          event.disposition == TripTrackingAdvisoryDisposition.pending,
    );
    if (latestPendingStopIndex < 0) return session.advisories;
    final advisories = [...session.advisories];
    final safeDetectedAt = _safeDetectedAt(session, detectedAt);
    advisories[latestPendingStopIndex] = advisories[latestPendingStopIndex]
        .copyWith(
          evidenceEndedAt: safeDetectedAt,
          confidence: TripTrackingConfidence.high,
        );
    return advisories;
  }

  static List<TripTrackingAdvisoryEvent> extendConfirmedWalkingStopAdvisory(
    TripTrackingSessionRecord session, {
    required DateTime detectedAt,
  }) {
    final latestPendingStopIndex = latestPendingStopReviewIndex(
      session,
      preferHighConfidence: true,
    );
    if (latestPendingStopIndex < 0) return session.advisories;
    final advisories = [...session.advisories];
    final current = advisories[latestPendingStopIndex];
    if (!detectedAt.isAfter(current.evidenceEndedAt)) return advisories;
    advisories[latestPendingStopIndex] = current.copyWith(
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
    required TripTrackingSessionRecord session,
    required DateTime detectedAt,
  }) {
    if (type != TripTrackingAdvisoryType.probableStop) return detectedAt;
    final stationaryStartedAt = engineSnapshot.stationaryStartedAt;
    final walkingStartedAt = engineSnapshot.walkingEvidence.isEmpty
        ? null
        : engineSnapshot.walkingEvidence.first.recordedAt;
    final candidates = [
      if (stationaryStartedAt != null &&
          !stationaryStartedAt.isAfter(detectedAt))
        stationaryStartedAt,
      if (walkingStartedAt != null && !walkingStartedAt.isAfter(detectedAt))
        walkingStartedAt,
    ];
    if (candidates.isEmpty) return detectedAt;
    var earliest = candidates.first;
    for (final candidate in candidates.skip(1)) {
      if (candidate.isBefore(earliest)) earliest = candidate;
    }
    return _safeEvidenceStartedAt(session, earliest, detectedAt: detectedAt);
  }

  static bool _hasSameTransition(
    TripTrackingSessionRecord session, {
    required TripTrackingAdvisoryType type,
    required DateTime detectedAt,
  }) {
    return session.advisories.any(
      (event) =>
          event.type == type &&
          event.detectedAt == detectedAt &&
          event.sessionId == session.id &&
          event.vehicleId == session.vehicleId,
    );
  }

  static DateTime _safeDetectedAt(
    TripTrackingSessionRecord session,
    DateTime detectedAt,
  ) {
    final tripStart = session.startedAt.toUtc();
    final clean = detectedAt.toUtc();
    if (clean.isBefore(tripStart)) return session.startedAt;
    final latestSupported = tripStart.add(const Duration(days: 30));
    if (clean.isAfter(latestSupported)) return latestSupported;
    return detectedAt;
  }

  static DateTime _safeEvidenceStartedAt(
    TripTrackingSessionRecord session,
    DateTime evidenceStartedAt, {
    required DateTime detectedAt,
  }) {
    final tripStart = session.startedAt.toUtc();
    final clean = evidenceStartedAt.toUtc();
    if (clean.isBefore(tripStart)) return session.startedAt;
    if (clean.isAfter(detectedAt.toUtc())) return detectedAt;
    return evidenceStartedAt;
  }

  static bool _canCreateAdvisoryForSession(TripTrackingSessionRecord session) {
    return _safeAdvisoryToken(session.id) &&
        _safeAdvisoryToken(session.vehicleId) &&
        session.schemaVersion >= 1 &&
        !session.updatedAt.isBefore(session.startedAt);
  }

  static bool _safeAdvisoryToken(String value) {
    final clean = value.trim();
    if (clean.isEmpty || clean != value || clean.length > 96) return false;
    if (clean.startsWith('pk.') || clean.startsWith('sk.')) return false;
    if (clean.toLowerCase().contains('token')) return false;
    return RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clean);
  }
}
