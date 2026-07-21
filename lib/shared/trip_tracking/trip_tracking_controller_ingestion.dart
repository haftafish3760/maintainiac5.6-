// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// Sends validated native samples through the shared engine while preserving
/// local ordering and review-only odometer behavior.
extension TripTrackingControllerIngestion on TripTrackingController {
  Future<TripSampleDecision?> ingest(
    TripLocationSample sample, {
    TripActivityObservation? activity,
    DateTime? referenceTime,
  }) {
    if (_isDisposed || _sessionOperationInProgress) {
      return Future<TripSampleDecision?>.value();
    }
    return _enqueueIngestion(
      () => _ingest(sample, activity: activity, referenceTime: referenceTime),
    );
  }

  Future<TripSampleDecision?> _ingest(
    TripLocationSample sample, {
    TripActivityObservation? activity,
    DateTime? referenceTime,
  }) async {
    if (_isDisposed) return null;
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;

    if (sample.recordedAt.toUtc().isBefore(session.startedAt.toUtc())) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }

    // A caller may supply the native receipt time for a platform event. Direct
    // ingestion still uses the controller clock as a mandatory future-date
    // guard, while the odometer projection keeps its historical sample time
    // when no distinct receipt time is available.
    final receivedAt = (referenceTime ?? _clockNow()).toUtc();
    final projectionReceivedAt = (referenceTime ?? sample.recordedAt).toUtc();
    if (sample.recordedAt.toUtc().isAfter(
      receivedAt.add(engine.policy.maximumFutureSampleSkew),
    )) {
      return engine.reject(TripSampleDisposition.rejectedFutureTimestamp);
    }

    if (!sample.hasValidCoordinate || !sample.hasValidAccuracy) {
      return engine.reject(TripSampleDisposition.rejectedInvalid);
    }
    if (!sample.hasValidReportedSpeed ||
        !sample.hasValidReportedSpeedAccuracy) {
      return engine.reject(TripSampleDisposition.rejectedInvalid);
    }

    final lastObservedAt = engine.snapshot.lastObservedAt?.toUtc();
    final lastObservedMonotonicElapsedNanos =
        engine.snapshot.lastObservedMonotonicElapsedNanos;
    final monotonicIsNewer =
        sample.monotonicElapsedNanos != null &&
        lastObservedMonotonicElapsedNanos != null &&
        sample.monotonicElapsedNanos! > lastObservedMonotonicElapsedNanos;
    final wallClockIsNewer =
        lastObservedAt == null ||
        sample.recordedAt.toUtc().isAfter(lastObservedAt);
    final monotonicClockReset = TripTrackingEngine.isMonotonicClockReset(
      candidate: sample.monotonicElapsedNanos,
      previous: lastObservedMonotonicElapsedNanos,
      candidateWallClock: sample.recordedAt,
      previousWallClock: lastObservedAt,
    );
    if (lastObservedAt != null && !wallClockIsNewer && !monotonicIsNewer) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }
    if (lastObservedMonotonicElapsedNanos != null &&
        sample.monotonicElapsedNanos != null &&
        !monotonicIsNewer &&
        !monotonicClockReset) {
      return engine.reject(TripSampleDisposition.rejectedOutOfOrder);
    }

    final safeActivity = _activitySafeForSample(sample, activity);
    if (sample.mockedLocation != true) {
      await _sessionStore.savePending(
        TripTrackingPendingSample(
          sessionId: session.id,
          sample: sample,
          activity: safeActivity,
        ),
      );
    }

    // The filter is mutable. Keep a recoverable in-memory checkpoint until
    // its matching session state is safely local. Otherwise a failed write
    // could make the next sample measure from GPS evidence that did not
    // survive the local-first durability boundary.
    final previousEngineSnapshot = engine.snapshot;
    final previousMotionState = engine.motionState;
    if (sample.mockedLocation != true) {
      engine.completeSignalGap(sample.recordedAt);
    }
    final decision = engine.ingest(sample, activity: safeActivity);
    final advisories = TripStopAdvisoryReviewer.afterMotionTransition(
      session,
      engineSnapshot: engine.snapshot,
      previousMotionState: previousMotionState,
      currentMotionState: engine.motionState,
      detectedAt: sample.recordedAt,
    );
    final persistsRecoveryState =
        decision.accepted ||
        decision.disposition == TripSampleDisposition.rejectedAccuracy ||
        decision.disposition == TripSampleDisposition.rejectedMockLocation ||
        decision.disposition == TripSampleDisposition.rejectedDrift ||
        decision.disposition == TripSampleDisposition.rejectedGap ||
        decision.disposition ==
            TripSampleDisposition.rejectedImplausibleSpeed ||
        decision.disposition == TripSampleDisposition.rejectedSpeedConflict ||
        decision.disposition == TripSampleDisposition.excludedWalking;
    if (persistsRecoveryState) {
      final naturalLifecycleState = _lifecycleAfterDecision(
        session.lifecycleState,
        decision,
      );
      if (naturalLifecycleState != session.lifecycleState) {
        TripTrackingSessionStateMachine.requireTransition(
          session.lifecycleState,
          naturalLifecycleState,
        );
      }
      _session = session.copyWith(
        updatedAt: sample.recordedAt,
        engineSnapshot: engine.snapshot,
        advisories: advisories,
        lifecycleState: naturalLifecycleState,
        healthState: _healthAfterDecision(session.healthState, decision),
      );
      try {
        await _sessionStore.save(_session!);
      } catch (_) {
        _session = session;
        _engine = TripTrackingEngine.fromSnapshot(
          previousEngineSnapshot,
          policy: engine.policy,
          profile: engine.profile,
        );
        rethrow;
      }
      final estimatedOdometer = projection.updateAcceptedMeters(
        decision.totalAcceptedMeters,
        gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      );
      final liveProjectionUpdated = _odometer.updateLiveTripProjection(
        tripId: session.id,
        estimatedOdometer: estimatedOdometer,
        observedAtUtc: sample.recordedAt,
        receivedAtUtc: projectionReceivedAt,
      );
      final liveProjectionFailed =
          decision.accepted &&
          (projection.lastUpdateExceededMax || !liveProjectionUpdated);
      if (liveProjectionFailed) {
        _platformStatus = 'odometer_projection_invalid';
        _platformError = projection.lastUpdateExceededMax
            ? 'GPS distance exceeded the supported live odometer range. Review the trip before continuing.'
            : 'GPS live odometer projection could not be updated safely. The confirmed odometer remains unchanged.';
        if (TripTrackingSessionStateMachine.canTransition(
          _session!.lifecycleState,
          TripTrackingSessionLifecycleState.failedRecoverable,
        )) {
          _session = _session!.copyWith(
            lifecycleState: TripTrackingSessionLifecycleState.failedRecoverable,
            healthState: TripTrackingHealthState.unavailable,
          );
          await _sessionStore.save(_session!);
        }
      }
      notifyListeners();
    }
    await _sessionStore.clearPending(session.id);
    return decision;
  }

  TripActivityObservation? _activitySafeForSample(
    TripLocationSample sample,
    TripActivityObservation? activity,
  ) {
    final evidence = activity;
    if (evidence == null) return null;
    if (evidence.confidence < 0 || evidence.confidence > 100) return null;
    if (evidence.recordedAt.isAfter(sample.recordedAt)) return null;
    final age = sample.recordedAt.difference(evidence.recordedAt);
    if (age > _policy.walkingConfirmationWindow) return null;
    return evidence;
  }

  /// Starts the platform collector only after an active trip exists. Native
  /// samples are queued one at a time so a fast EventChannel cannot reorder
  /// distance decisions or overwrite a newer recovery snapshot.
}
