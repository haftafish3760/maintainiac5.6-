// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// User-directed stop and trip review actions. These create review records;
/// confirmed mileage remains owned by the global odometer workflow.
extension TripTrackingControllerReviewActions on TripTrackingController {
  Future<bool> saveCompletionDraft({
    required String tripId,
    int? endingOdometerDraft,
    bool clearEndingOdometerDraft = false,
    List<TripManualMileageAdjustment>? manualAdjustments,
    List<TripManualEvent>? tripEvents,
    TripOdometerUsageDayClassification? usageDayClassification,
  }) => _runExclusiveSessionOperation(
    false,
    () => _saveCompletionDraft(
      tripId: tripId,
      endingOdometerDraft: endingOdometerDraft,
      clearEndingOdometerDraft: clearEndingOdometerDraft,
      manualAdjustments: manualAdjustments,
      tripEvents: tripEvents,
      usageDayClassification: usageDayClassification,
    ),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip record is already being updated. Please wait for it to finish.',
  );

  Future<bool> _saveCompletionDraft({
    required String tripId,
    int? endingOdometerDraft,
    required bool clearEndingOdometerDraft,
    List<TripManualMileageAdjustment>? manualAdjustments,
    List<TripManualEvent>? tripEvents,
    TripOdometerUsageDayClassification? usageDayClassification,
  }) async {
    final review = _sessionStore.reviewForTrip(tripId);
    if (review == null || review.isOdometerConfirmed) return false;
    if (endingOdometerDraft != null && endingOdometerDraft < 0) return false;
    final adjustments = manualAdjustments ?? review.manualAdjustments;
    if (adjustments.any((item) => !item.isValid)) return false;
    final reviewRecordedAt = _clockNow().toUtc();
    final events = (tripEvents ?? review.tripEvents)
        .map(
          (event) => event.bindToReview(
            sessionId: review.id,
            vehicleId: review.vehicleId,
            profileId: review.effectiveProfileId,
            recordedAt: reviewRecordedAt,
          ),
        )
        .toList(growable: false);
    if (events.any(
      (item) =>
          !item.isValid ||
          item.occurredAt.isBefore(review.startedAt) ||
          item.occurredAt.isAfter(review.finishedAt),
    )) {
      return false;
    }
    final next = review.copyWith(
      endingOdometerDraft: endingOdometerDraft,
      clearEndingOdometerDraft: clearEndingOdometerDraft,
      manualAdjustments: adjustments,
      tripEvents: events,
      usageDayClassification: usageDayClassification,
    );
    try {
      await _sessionStore.saveReview(next);
      notifyListeners();
      return true;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip completion draft locally.';
      notifyListeners();
      return false;
    }
  }

  Future<void> acknowledgeLatestStopReview() =>
      reviewLatestStopAdvisory(TripTrackingAdvisoryDisposition.confirmed);

  Future<void> reviewLatestStopAdvisory(
    TripTrackingAdvisoryDisposition disposition,
  ) => _runExclusiveSessionOperation<void>(
    null,
    () => _reviewLatestStopAdvisory(disposition),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip record is already being updated. Please wait for it to finish.',
  );

  Future<void> _reviewLatestStopAdvisory(
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
    final previousEngineSnapshot = engine.snapshot;
    if (reviewingWalkingStop) engine.acknowledgeWalkingReview();
    final reviewedAdvisories = [...session.advisories];
    if (latestPendingStopIndex >= 0) {
      reviewedAdvisories[latestPendingStopIndex] =
          reviewedAdvisories[latestPendingStopIndex].copyWith(
            disposition: disposition,
          );
    }
    final reviewedSession = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session),
      revision: session.revision + 1,
      engineSnapshot: engine.snapshot,
      advisories: reviewedAdvisories,
    );
    try {
      await _sessionStore.save(reviewedSession);
      _session = reviewedSession;
      notifyListeners();
    } catch (_) {
      _session = session;
      _engine = TripTrackingEngine.fromSnapshot(
        previousEngineSnapshot,
        policy: engine.policy,
        profile: engine.profile,
      );
      _platformStatus = 'storage_failed';
      _platformError =
          'Could not save the GPS stop review locally. It remains available for retry.';
      notifyListeners();
    }
  }

  /// Backward-compatible walking stop review hook used by existing UI/tests.
  Future<void> acknowledgeWalkingReview() => acknowledgeLatestStopReview();

  /// Records an explicit driver event while a trip is active. GPS and remote
  /// systems cannot create these events, and [commandId] makes UI or voice
  /// retries idempotent across controller rebuilds.
  Future<bool> recordUserTripEvent({
    required String commandId,
    required TripManualEventType type,
    required String initiatingSource,
    DateTime? occurredAt,
    String? note,
  }) => _runExclusiveSessionOperation(
    false,
    () => _recordUserTripEvent(
      commandId: commandId,
      type: type,
      initiatingSource: initiatingSource,
      occurredAt: occurredAt,
      note: note,
    ),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip record is already being updated. Please wait for it to finish.',
  );

  Future<bool> _recordUserTripEvent({
    required String commandId,
    required TripManualEventType type,
    required String initiatingSource,
    DateTime? occurredAt,
    String? note,
  }) async {
    final session = _session;
    if (session == null ||
        !_canRecordUserTripEvent(session.lifecycleState) ||
        !_isSafeUserEventCommandId(commandId) ||
        !TripManualEvent.allowsInitiatingSource(initiatingSource)) {
      return false;
    }
    final eventId = 'user:$commandId';
    for (final existing in session.tripEvents) {
      if (existing.id != eventId) continue;
      return existing.type == type &&
          existing.initiatingSource == initiatingSource;
    }
    if (session.tripEvents.length >= TripManualEvent.maximumPerTrip) {
      _platformStatus = 'trip_event_limit_reached';
      _platformError =
          'This trip has reached the safe event limit. Existing events remain preserved.';
      notifyListeners();
      return false;
    }
    final recordedAt = _clockNow().toUtc();
    final eventTime = (occurredAt ?? recordedAt).toUtc();
    if (eventTime.isBefore(session.startedAt.toUtc()) ||
        eventTime.isAfter(recordedAt.add(_policy.maximumFutureSampleSkew))) {
      return false;
    }
    final event = TripManualEvent(
      id: eventId,
      type: type,
      occurredAt: eventTime,
      userConfirmed: true,
      note: note,
      sessionId: session.id,
      vehicleId: session.vehicleId,
      profileId: session.effectiveProfileId,
      recordedAt: recordedAt.isBefore(eventTime) ? eventTime : recordedAt,
      initiatingSource: initiatingSource,
    );
    final next = session.copyWith(
      updatedAt: recordedAt.isBefore(eventTime) ? eventTime : recordedAt,
      revision: session.revision + 1,
      tripEvents: [...session.tripEvents, event],
    );
    try {
      await _sessionStore.save(next);
      _session = next;
    } catch (_) {
      _platformStatus = 'trip_event_save_failed';
      _platformError =
          'Could not save this trip event locally. Retry before leaving the screen.';
      notifyListeners();
      return false;
    }
    _platformStatus = null;
    _platformError = null;
    notifyListeners();
    return true;
  }

  bool _canRecordUserTripEvent(TripTrackingSessionLifecycleState state) =>
      switch (state) {
        TripTrackingSessionLifecycleState.ready ||
        TripTrackingSessionLifecycleState.starting ||
        TripTrackingSessionLifecycleState.active ||
        TripTrackingSessionLifecycleState.paused ||
        TripTrackingSessionLifecycleState.degraded ||
        TripTrackingSessionLifecycleState.interrupted ||
        TripTrackingSessionLifecycleState.recovering ||
        TripTrackingSessionLifecycleState.failedRecoverable => true,
        _ => false,
      };

  Future<bool> retryTripLogProposal(
    String tripId,
  ) => _runExclusiveSessionOperation(
    false,
    () => _retryTripLogProposal(tripId),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip record is already being updated. Please wait for it to finish.',
  );

  Future<bool> _retryTripLogProposal(String tripId) async {
    final review = _sessionStore.reviewForTrip(tripId);
    if (review == null || _tripLogProposalSink == null) return false;
    if (review.tripLogProposalState ==
        TripTrackingTripLogProposalState.submitted) {
      return true;
    }
    return _submitTripLogProposal(review);
  }

  Future<bool> _submitTripLogProposal(TripTrackingReviewRecord review) async {
    final sink = _tripLogProposalSink;
    if (sink == null) return true;
    final attemptedAt = _clockNow().toUtc();
    final attemptCount = review.tripLogProposalAttemptCount + 1;
    try {
      await sink.propose(TripTrackingTripLogProposal.fromReview(review));
      await _sessionStore.saveReview(
        review.copyWith(
          tripLogProposalState: TripTrackingTripLogProposalState.submitted,
          tripLogProposalAttemptCount: attemptCount,
          tripLogProposalLastAttemptAt: attemptedAt,
        ),
      );
      _tripLogProposalError = null;
      return true;
    } catch (_) {
      try {
        await _sessionStore.saveReview(
          review.copyWith(
            tripLogProposalState: TripTrackingTripLogProposalState.pending,
            tripLogProposalAttemptCount: attemptCount,
            tripLogProposalLastAttemptAt: attemptedAt,
          ),
        );
      } catch (_) {
        // The original review remains the durable retry source.
      }
      _tripLogProposalError =
          'TripLog proposal is preserved locally and can be retried.';
      return false;
    }
  }

  /// Cancels an active trip with an intentional user action. Cancellation
  /// preserves runtime evidence by creating an unconfirmed review record and
  /// clearing live tracking state without changing odometer truth.
  Future<TripTrackingReviewRecord?> cancelActiveTrip({
    DateTime? canceledAt,
    bool userConfirmed = false,
  }) => _runExclusiveSessionOperation(
    null,
    () =>
        _cancelActiveTrip(canceledAt: canceledAt, userConfirmed: userConfirmed),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

  Future<TripTrackingReviewRecord?> _cancelActiveTrip({
    DateTime? canceledAt,
    bool userConfirmed = false,
  }) async {
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;
    final snapshot = session.engineSnapshot;
    var hasMeaningfulEvidence =
        acceptedMeters > 0 ||
        snapshot.lastAccepted != null ||
        snapshot.lastObservedAt != null ||
        snapshot.vehicleMovementObserved ||
        snapshot.walkingEvidence.isNotEmpty ||
        snapshot.signalGaps.isNotEmpty ||
        snapshot.initialFixAssessment != null ||
        session.advisories.isNotEmpty;
    try {
      hasMeaningfulEvidence =
          hasMeaningfulEvidence ||
          _sessionStore.pendingSampleFor(session.id) != null;
    } catch (_) {
      _platformStatus = 'storage_failed';
      _platformError =
          'Could not verify pending GPS evidence before cancellation.';
      notifyListeners();
      return null;
    }
    if (hasMeaningfulEvidence && !userConfirmed) {
      _platformStatus = 'trip_cancel_confirmation_required';
      _platformError =
          'Trip cancellation requires confirmation because this trip has recorded tracking evidence.';
      notifyListeners();
      return null;
    }
    final observedCompletedAt = canceledAt ?? _clockNow();
    if (canceledAt != null && observedCompletedAt.isBefore(session.startedAt)) {
      _platformStatus = 'trip_cancel_timeline_invalid';
      _platformError =
          'Trip cancellation could not be saved because the cancel time is before the start time.';
      notifyListeners();
      return null;
    }
    if (canceledAt != null &&
        observedCompletedAt.toUtc().isBefore(session.updatedAt.toUtc())) {
      _platformStatus = 'trip_cancel_before_latest_evidence';
      _platformError =
          'Trip cancellation time cannot be before the latest saved trip evidence.';
      notifyListeners();
      return null;
    }
    final completedAt = canceledAt == null
        ? _nonRegressingSessionTime(session, observedCompletedAt)
        : observedCompletedAt.toUtc();
    if (completedAt.toUtc().isAfter(
          _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
        ) &&
        completedAt.toUtc().isAfter(session.updatedAt.toUtc())) {
      _platformStatus = 'trip_cancel_future_invalid';
      _platformError =
          'Trip cancellation could not be saved because the cancel time is too far in the future.';
      notifyListeners();
      return null;
    }
    if (session.lifecycleState != TripTrackingSessionLifecycleState.cancelled) {
      final transitioned = await _tryTransitionSession(
        TripTrackingSessionLifecycleState.cancelled,
        reasonCode: 'trip_cancelled',
        source: 'user_cancel',
        eventTimestamp: completedAt,
      );
      if (!transitioned) return null;
    }
    await stopNativeTracking();
    final cancelledSession = _session;
    if (cancelledSession == null) return null;
    final review = _buildReviewRecord(
      session: cancelledSession,
      engine: engine,
      projection: projection,
      finishedAt: completedAt,
      finishedTimeZoneContextAt: observedCompletedAt,
    );
    try {
      await _sessionStore.saveReview(review);
    } catch (_) {
      _platformStatus = 'cancel_review_save_failed';
      _platformError = 'Could not save the cancelled trip locally.';
      notifyListeners();
      return null;
    }
    try {
      await _sessionStore.clear();
    } catch (_) {
      _platformStatus = 'cancel_cleanup_failed';
      _platformError =
          'Could not remove active trip after cancellation. Review remains recoverable.';
    }
    try {
      await _sessionStore.clearPending(session.id);
    } catch (_) {
      if (_platformStatus == null ||
          (_platformStatus == 'stopped' && _platformError == null)) {
        _platformStatus = 'pending_cleanup_failed';
        _platformError = 'Could not clear transient GPS recovery data.';
      }
    }
    _odometer.clearLiveTripProjection(tripId: session.id);
    _session = null;
    _engine = null;
    _projection = null;
    _activeTripCalibrationMultiplier = 1;
    if (_platformStatus == 'stopped' && _platformError == null) {
      _platformStatus = null;
    }
    notifyListeners();
    return review;
  }

  TripTrackingReviewRecord _buildReviewRecord({
    required TripTrackingSessionRecord session,
    required TripTrackingEngine engine,
    required TripLiveOdometerProjection projection,
    required DateTime finishedAt,
    DateTime? finishedTimeZoneContextAt,
  }) {
    final finishedContext = finishedTimeZoneContextAt ?? finishedAt;
    final estimatedEndingOdometer = projection.updateAcceptedMeters(
      engine.totalAcceptedMeters,
      gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
    );
    return TripTrackingReviewRecord(
      id: session.id,
      vehicleId: session.vehicleId,
      vehicleConfigurationRevision: session.vehicleConfigurationRevision,
      gpsAssistanceCalibrationMultiplier:
          session.gpsAssistanceCalibrationMultiplier,
      ancestry: session.ancestry,
      startingOdometer: session.startingOdometer,
      estimatedEndingOdometer:
          estimatedEndingOdometer < session.startingOdometer
          ? session.startingOdometer
          : estimatedEndingOdometer,
      profile: session.profile,
      profileId: session.effectiveProfileId,
      startedAt: session.startedAt,
      finishedAt: finishedAt,
      startedTimeZoneOffsetMinutes: session.startedTimeZoneOffsetMinutes,
      startedTimeZoneName: session.startedTimeZoneName,
      finishedTimeZoneOffsetMinutes: finishedContext.timeZoneOffset.inMinutes,
      finishedTimeZoneName: finishedContext.timeZoneName,
      engineSnapshot: engine.snapshot,
      advisories: session.advisories,
      tripEvents: session.tripEvents,
      transitionAudits: session.transitionAudits,
      batteryStateSummary: session.batteryStateSummary,
      permissionHistory: session.permissionHistory,
      recoveryCount: session.recoveryCount,
      revision: session.revision,
    );
  }

  /// Drops a just-created trip only when it has not accepted any distance.
  /// This is used after permission or hardware startup fails so the global
  /// odometer is not left locked by a trip that never actually began.
  Future<bool> discardEmptyTrip() => _runExclusiveSessionOperation(
    false,
    _discardEmptyTrip,
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

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
  Future<TripTrackingReviewRecord?> finishForReview({
    DateTime? finishedAt,
  }) => _runExclusiveSessionOperation(
    null,
    () => _finishForReview(finishedAt: finishedAt),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

  Future<TripTrackingReviewRecord?> _finishForReview({
    DateTime? finishedAt,
  }) async {
    final session = _session;
    final engine = _engine;
    final projection = _projection;
    if (session == null || engine == null || projection == null) return null;
    final observedCompletedAt = finishedAt ?? _clockNow();
    if (finishedAt != null && observedCompletedAt.isBefore(session.startedAt)) {
      _platformStatus = 'review_timeline_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is before the start time.';
      notifyListeners();
      return null;
    }
    if (finishedAt != null &&
        observedCompletedAt.toUtc().isBefore(session.updatedAt.toUtc())) {
      _platformStatus = 'review_finish_before_latest_evidence';
      _platformError =
          'Trip finish time cannot be before the latest saved trip evidence.';
      notifyListeners();
      return null;
    }
    final completedAt = finishedAt == null
        ? _nonRegressingSessionTime(session, observedCompletedAt)
        : observedCompletedAt.toUtc();
    if (completedAt.toUtc().isAfter(
          _clockNow().toUtc().add(_policy.maximumFutureSampleSkew),
        ) &&
        completedAt.toUtc().isAfter(session.updatedAt.toUtc())) {
      _platformStatus = 'review_finish_time_invalid';
      _platformError =
          'Trip review could not be saved because the finish time is too far in the future.';
      notifyListeners();
      return null;
    }
    if (TripTrackingSessionStateMachine.canTransition(
      session.lifecycleState,
      TripTrackingSessionLifecycleState.stopping,
    )) {
      final transitioned = await _tryTransitionSession(
        TripTrackingSessionLifecycleState.stopping,
        source: 'user_finish_for_review',
        reasonCode: 'trip_review_requested',
        eventTimestamp: completedAt,
      );
      if (!transitioned) {
        if (_platformStatus == 'storage_failed') {
          _platformStatus = 'review_save_failed';
          _platformError =
              'Could not save the completed trip locally. It remains recoverable.';
          notifyListeners();
        }
        return null;
      }
    }
    await stopNativeTracking();
    final completedSession = _session;
    if (completedSession == null) return null;
    final review = _buildReviewRecord(
      session: completedSession,
      engine: engine,
      projection: projection,
      finishedAt: completedAt,
      finishedTimeZoneContextAt: observedCompletedAt,
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
    await _submitTripLogProposal(review);
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
      if (_platformStatus == null ||
          (_platformStatus == 'stopped' && _platformError == null)) {
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
