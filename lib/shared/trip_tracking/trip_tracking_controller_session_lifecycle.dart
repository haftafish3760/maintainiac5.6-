part of 'trip_tracking_controller.dart';

/// Starts and restores local GPS sessions without changing the independent
/// confirmed-odometer authority.
extension TripTrackingControllerSessionLifecycle on TripTrackingController {
  Future<bool> start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    DateTime? startedAt,
  }) => _runExclusiveSessionOperation(
    false,
    () => _start(
      tripId: tripId,
      vehicleId: vehicleId,
      profile: profile,
      startedAt: startedAt,
    ),
  );

  Future<bool> _start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    DateTime? startedAt,
  }) async {
    if (_isDisposed ||
        isTracking ||
        !_isSafeTripTrackingIdentity(tripId) ||
        !_isSafeTripTrackingIdentity(vehicleId)) {
      return false;
    }
    if (vehicleId != _odometer.vehicleId) {
      // The live odometer is vehicle-scoped. Never create a session whose
      // later GPS miles could be projected onto a different active vehicle.
      _platformStatus = 'vehicle_mismatch';
      _platformError =
          'Select the vehicle used for this GPS trip before starting tracking.';
      notifyListeners();
      return false;
    }
    try {
      // Reviews are stored by trip id. Reusing an id would otherwise replace
      // an existing locally durable audit record when the new trip finishes.
      if (_sessionStore.recoveryReviewForTrip(tripId) != null) return false;
    } catch (error) {
      // Do not start GPS or alter the live odometer when we cannot establish
      // that the immutable local review history is available.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip locally.';
      notifyListeners();
      return false;
    }
    final now = _clockNow();
    final started = startedAt ?? now;
    if (started.toUtc().isAfter(
      now.toUtc().add(_policy.maximumFutureSampleSkew),
    )) {
      _platformStatus = 'trip_start_time_invalid';
      _platformError =
          'GPS trip tracking could not start because the start time is in the future.';
      notifyListeners();
      return false;
    }
    final startingOdometer = _odometer.confirmedReading;
    if (!_odometer.beginLiveTripProjection(
      tripId: tripId,
      startingOdometer: startingOdometer,
      observedAtUtc: started,
    )) {
      return false;
    }
    _engine = TripTrackingEngine(policy: _policy, profile: profile);
    _projection = TripLiveOdometerProjection(
      startingOdometer: startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    _activeTripCalibrationMultiplier = gpsAssistanceCalibrationMultiplier;
    _session = TripTrackingSessionRecord(
      id: tripId,
      vehicleId: vehicleId,
      startingOdometer: startingOdometer,
      profile: profile,
      startedAt: started,
      updatedAt: started,
      engineSnapshot: _engine!.snapshot,
    );
    try {
      await _sessionStore.save(_session!);
    } catch (error) {
      // An active trip is only recoverable after its initial local checkpoint
      // succeeds. Do not leave a phantom trip holding the live odometer when
      // storage is unavailable (for example, a full or closed local store).
      try {
        await _sessionStore.clear();
      } catch (_) {
        // The original storage failure is the useful error to surface. A
        // later restore still validates any residual record defensively.
      }
      _odometer.clearLiveTripProjection(tripId: tripId);
      _session = null;
      _engine = null;
      _projection = null;
      _activeTripCalibrationMultiplier = 1;
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip locally.';
      notifyListeners();
      return false;
    }
    _platformStatus = null;
    _platformError = null;
    notifyListeners();
    return true;
  }

  Future<bool> restore() => _runExclusiveSessionOperation(false, _restore);

  Future<bool> _restore() async {
    if (_isDisposed || isTracking) return false;
    TripTrackingSessionRecord? session;
    try {
      session = _sessionStore.activeSession;
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip recovery data.';
      notifyListeners();
      return false;
    }
    if (session == null) return false;
    if (!_isRecoverableSession(session)) {
      try {
        await _sessionStore.clear();
      } catch (error) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not remove invalid local trip data.';
        notifyListeners();
      }
      return false;
    }
    // A review record was durably written before the process died. Do not
    // resume tracking or risk adding distance to a trip the user ended.
    TripTrackingReviewRecord? review;
    try {
      review = _sessionStore.recoveryReviewForTrip(session.id);
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip review data.';
      notifyListeners();
      return false;
    }
    if (review != null) {
      if (!_isAuthoritativeReview(review, session)) {
        // A malformed review must not make us discard the only recoverable
        // active-trip checkpoint. Fail closed until the local record can be
        // repaired instead of risking mileage loss or duplicate tracking.
        _platformStatus = 'review_invalid';
        _platformError =
            'A saved trip review is incomplete. GPS recovery is paused to protect your mileage.';
        notifyListeners();
        return false;
      }
      try {
        await _sessionStore.clear();
        await _sessionStore.clearPending(session.id);
      } catch (error) {
        // The durable review remains authoritative even if a stale recovery
        // checkpoint cannot be removed right now. Never resume it as a trip.
        _platformStatus = 'review_cleanup_failed';
        _platformError =
            'Could not clear stale trip recovery data or transient GPS sample.';
        notifyListeners();
      }
      return false;
    }
    if (session.vehicleId != _odometer.vehicleId) {
      // Never project a recovered trip onto whichever vehicle happens to be
      // active after a restart. Keep the durable session intact until the
      // driver selects its original vehicle and can review it safely.
      _platformStatus = 'vehicle_mismatch';
      _platformError =
          'This GPS trip belongs to another vehicle. Switch vehicles before recovering it.';
      notifyListeners();
      return false;
    }
    final projection = TripLiveOdometerProjection(
      startingOdometer: session.startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    _activeTripCalibrationMultiplier = gpsAssistanceCalibrationMultiplier;
    final estimatedOdometer = projection.updateAcceptedMeters(
      session.engineSnapshot.totalAcceptedMeters,
      gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
    );
    if (!_odometer.beginLiveTripProjection(
      tripId: session.id,
      startingOdometer: session.startingOdometer,
      observedAtUtc: session.startedAt,
    )) {
      return false;
    }
    if (projection.lastUpdateExceededMax ||
        !_odometer.updateLiveTripProjection(
          tripId: session.id,
          estimatedOdometer: estimatedOdometer,
          observedAtUtc: session.updatedAt,
          receivedAtUtc: session.updatedAt,
        )) {
      _odometer.clearLiveTripProjection(tripId: session.id);
      _platformStatus = 'odometer_projection_invalid';
      _platformError =
          'Saved GPS trip distance is outside the supported odometer range.';
      notifyListeners();
      return false;
    }
    _session = session;
    _engine = TripTrackingEngine.fromSnapshot(
      session.engineSnapshot,
      policy: _policy,
      profile: session.profile,
    );
    _projection = projection;
    TripTrackingPendingSample? pending;
    try {
      pending = _sessionStore.pendingSampleFor(session.id);
    } catch (error) {
      // The active checkpoint is already recoverable. Keep it and its live
      // odometer projection rather than crashing or discarding mileage just
      // because the optional final in-flight sample cannot be read.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read pending GPS recovery data.';
      notifyListeners();
      return true;
    }
    final pendingRecovery = TripTrackingRecoveryPolicy.evaluate(
      session: session,
      currentVehicleId: _odometer.vehicleId,
      currentConfirmedOdometer: session.startingOdometer,
      pendingSample: pending,
    );
    if (pendingRecovery.status ==
            TripTrackingRecoveryStatus.pendingReplayReady &&
        pending != null) {
      try {
        await ingest(pending.sample, activity: pending.activity);
        await _sessionStore.clearPending(session.id);
      } catch (error) {
        // The active checkpoint and live odometer projection are already
        // restored. If replaying the optional in-flight sample cannot be
        // persisted, keep the trip recoverable and let the next sample move it
        // forward instead of failing the whole restore.
        _platformStatus = 'pending_replay_failed';
        _platformError = 'Could not replay the last pending GPS sample.';
        notifyListeners();
        return true;
      }
    } else if (pending != null && pending.sessionId == session.id) {
      try {
        await _sessionStore.clearPending(session.id);
      } catch (_) {
        _platformStatus = 'pending_cleanup_failed';
        _platformError = 'Could not clear stale GPS recovery data.';
        notifyListeners();
        return true;
      }
    }
    final platform = _platform;
    if (platform != null) {
      try {
        if (await platform.isTracking) {
          if (!session.backgroundTrackingAllowed) {
            // A collector that outlives this process cannot continue from
            // missing or foreground-only consent. Keep the local trip for an
            // explicit driver restart instead of silently tracking.
            try {
              await platform.stop();
              _platformStatus = 'background_consent_required';
              _platformError =
                  'GPS recovery was paused because background tracking was not previously authorized.';
            } catch (_) {
              _platformStatus = 'recoverable';
              _platformError =
                  'Could not stop GPS recovery without confirmed background permission.';
            }
          } else {
            _nativeTracking = true;
            _backgroundTrackingAllowed = true;
            _activityRecognitionEnabled = session.activityRecognitionEnabled;
            _nativeSampling = session.nativeSampling;
            _nativeSamplingPlan = session.samplingCeiling == null
                ? null
                : TripTrackingSamplingPlan(
                    sampling: session.samplingCeiling!,
                    deviceTier: TripTrackingDeviceCapabilityTier.locationOnly,
                    walkingEvidenceAvailable: false,
                    batteryProtectionEvidenceAvailable: false,
                  );
            _adaptiveSamplingEnabled = session.adaptiveSamplingEnabled;
            _lowBatteryProtectionEnabled = session.lowBatteryProtectionEnabled;
            _lowBatteryOverrideEnabled = session.lowBatteryOverrideEnabled;
            _lowBatteryWarningDismissed = session.lowBatteryWarningDismissed;
            _lastNativeHeartbeatUtc = _clockNow().toUtc();
            _nativeTrackingStartedAtUtc = _lastNativeHeartbeatUtc;
            _lastNativeLocationReceivedUtc = null;
            _platformStatus = 'tracking';
            final sampling = _nativeSampling;
            if (sampling == null) {
              _platformError =
                  'GPS recovery was paused because its saved sampling state is unavailable.';
              await _stopNativeTracking();
              _platformStatus = 'sampling_recovery_required';
            } else {
              bool reapplied;
              try {
                reapplied = await platform.update(
                  TripTrackingNativeRequest(
                    profile: session.profile,
                    sampling: sampling,
                    allowBackground: true,
                    activityRecognitionEnabled:
                        session.activityRecognitionEnabled,
                  ),
                );
              } catch (_) {
                reapplied = false;
              }
              if (!reapplied) {
                _platformError =
                    'GPS recovery was paused because the device could not reapply its saved tracking settings.';
                await _stopNativeTracking();
                _platformStatus = 'native_reconfiguration_failed';
              } else {
                _platformSubscription = _listenToPlatformEvents(platform);
                try {
                  _lastKnownCapabilities = await platform.readCapabilities();
                  _lastBatterySafetyCheckUtc = _clockNow().toUtc();
                  await _enforceRuntimeBatterySafety();
                } catch (_) {
                  // The surviving native collector remains authoritative for
                  // immediate OS-level safety. Do not fabricate a battery
                  // state or abandon recoverable local TripLog state when the
                  // optional runtime capability probe is temporarily
                  // unavailable.
                }
              }
            }
          }
        }
      } catch (error) {
        _platformError = 'Could not restore the GPS connection.';
        _platformStatus = 'recoverable';
      }
    }
    notifyListeners();
    return true;
  }

  bool _isRecoverableSession(TripTrackingSessionRecord session) =>
      session.hasValidTimeline &&
      _isSafeTripTrackingIdentity(session.id) &&
      _isSafeTripTrackingIdentity(session.vehicleId) &&
      session.startingOdometer >= 0 &&
      !session.updatedAt.isBefore(session.startedAt) &&
      _isRecoverableLifecycleState(session.lifecycleState);

  bool _isRecoverableLifecycleState(TripTrackingSessionLifecycleState state) =>
      switch (state) {
        TripTrackingSessionLifecycleState.ready ||
        TripTrackingSessionLifecycleState.starting ||
        TripTrackingSessionLifecycleState.active ||
        TripTrackingSessionLifecycleState.paused ||
        TripTrackingSessionLifecycleState.degraded ||
        TripTrackingSessionLifecycleState.interrupted ||
        TripTrackingSessionLifecycleState.recovering ||
        TripTrackingSessionLifecycleState.stopping ||
        TripTrackingSessionLifecycleState.failedRecoverable => true,
        TripTrackingSessionLifecycleState.disabled ||
        TripTrackingSessionLifecycleState.permissionRequired ||
        TripTrackingSessionLifecycleState.awaitingReview ||
        TripTrackingSessionLifecycleState.completed ||
        TripTrackingSessionLifecycleState.failedTerminal => false,
      };

  bool _isAuthoritativeReview(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      review.hasValidTimeline &&
      review.id == session.id &&
      review.vehicleId == session.vehicleId &&
      review.startingOdometer == session.startingOdometer &&
      review.startedAt == session.startedAt &&
      review.estimatedEndingOdometer >= review.startingOdometer;
}
