part of 'trip_tracking_controller.dart';

/// User-directed stop and trip review actions. These create review records;
/// confirmed mileage remains owned by the global odometer workflow.
extension TripTrackingControllerReviewActions on TripTrackingController {
  Future<void> acknowledgeLatestStopReview() =>
      reviewLatestStopAdvisory(TripTrackingAdvisoryDisposition.confirmed);

  Future<void> reviewLatestStopAdvisory(
    TripTrackingAdvisoryDisposition disposition,
  ) async {
    if (!TripStopAdvisoryReviewer.isFinalReviewDisposition(disposition)) {
      return;
    }
    final session = _session;
    final engine = _engine;
    if (session == null || engine == null) return;

    final reviewingWalkingStop = engine.needsWalkingReview;
    final latestPendingStopIndex =
        TripStopAdvisoryReviewer.latestPendingStopReviewIndex(
          session,
          preferHighConfidence: reviewingWalkingStop,
        );
    if (!reviewingWalkingStop && latestPendingStopIndex < 0) return;
    if (reviewingWalkingStop) engine.acknowledgeWalkingReview();
    final reviewedAdvisories = [...session.advisories];
    if (latestPendingStopIndex >= 0) {
      reviewedAdvisories[latestPendingStopIndex] =
          reviewedAdvisories[latestPendingStopIndex].copyWith(
            disposition: disposition,
          );
    }
    _session = session.copyWith(
      updatedAt: _clockNow(),
      engineSnapshot: engine.snapshot,
      advisories: reviewedAdvisories,
    );
    await _sessionStore.save(_session!);
    notifyListeners();
  }

  /// Backward-compatible walking stop review hook used by existing UI/tests.
  Future<void> acknowledgeWalkingReview() => acknowledgeLatestStopReview();

  /// Drops a just-created trip only when it has not accepted any distance.
  /// This is used after permission or hardware startup fails so the global
  /// odometer is not left locked by a trip that never actually began.
  Future<bool> discardEmptyTrip() =>
      _runExclusiveSessionOperation(false, _discardEmptyTrip);

  Future<bool> _discardEmptyTrip() async {
    final session = _session;
    if (session == null || acceptedMeters > 0 || _nativeTracking) return false;
    try {
      await _sessionStore.clear();
    } catch (error) {
      // Preserve the checkpoint and odometer projection if its durable delete
      // cannot be confirmed. A later retry is safer than inventing a clean
      // state while stale trip data may still exist on disk.
      _platformStatus = 'discard_failed';
      _platformError = 'Could not discard the empty trip locally.';
      notifyListeners();
      return false;
    }
    try {
      await _sessionStore.clearPending(session.id);
    } catch (error) {
      _platformStatus = 'pending_cleanup_failed';
      _platformError = 'Could not clear transient GPS recovery data.';
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    notifyListeners();
    return true;
  }

  /// Durably stores a review record before dropping crash-recovery state.
  /// The confirmed odometer stays untouched until a later review action makes
  /// one auditable permanent odometer event.
  Future<TripTrackingReviewRecord?> finishForReview({DateTime? finishedAt}) =>
      _runExclusiveSessionOperation(
        null,
        () => _finishForReview(finishedAt: finishedAt),
      );

  Future<TripTrackingReviewRecord?> _finishForReview({
    DateTime? finishedAt,
  }) async {
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;
    final completedAt = finishedAt ?? _clockNow();
    if (completedAt.isBefore(session.startedAt)) {
      _platformStatus = 'review_timeline_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is before the start time.';
      notifyListeners();
      return null;
    }
    if (completedAt.toUtc().isAfter(
      _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'review_finish_time_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is too far in the future.';
      notifyListeners();
      return null;
    }
    if (session.lifecycleState == TripTrackingSessionLifecycleState.active ||
        session.lifecycleState == TripTrackingSessionLifecycleState.paused ||
        session.lifecycleState == TripTrackingSessionLifecycleState.degraded) {
      await _tryTransitionSession(TripTrackingSessionLifecycleState.stopping);
    }
    await stopNativeTracking();
    final review = TripTrackingReviewRecord(
      id: session.id,
      vehicleId: session.vehicleId,
      startingOdometer: session.startingOdometer,
      estimatedEndingOdometer: projection.updateAcceptedMeters(
        engine.totalAcceptedMeters,
        gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      ),
      profile: session.profile,
      startedAt: session.startedAt,
      finishedAt: completedAt,
      engineSnapshot: engine.snapshot,
    );
    try {
      await _sessionStore.saveReview(review);
    } catch (error) {
      // Keep the active checkpoint and live projection intact. The driver can
      // retry finishing after local storage recovers; clearing here would turn
      // a transient disk failure into lost mileage.
      _platformStatus = 'review_save_failed';
      _platformError =
          'Could not save the completed trip locally. It remains recoverable.';
      notifyListeners();
      return null;
    }
    try {
      await _sessionStore.clear();
    } catch (error) {
      // The review is already durable. Clear the in-memory trip regardless so
      // it cannot be finished twice; restore will treat the review as
      // authoritative and retry cleanup on a future launch.
      _platformStatus = 'review_cleanup_failed';
      _platformError =
          'Trip review was saved, but stale recovery cleanup is pending.';
    }
    try {
      // A review contains only the completed-trip summary. Its transient
      // pending sample can contain a raw location, so it must not linger once
      // the review itself is durable.
      await _sessionStore.clearPending(session.id);
    } catch (error) {
      if (_platformStatus == null) {
        _platformStatus = 'pending_cleanup_failed';
        _platformError = 'Could not clear transient GPS recovery data.';
      }
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    notifyListeners();
    return review;
  }
}
