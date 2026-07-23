// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// Starts and restores local GPS sessions without changing the independent
/// confirmed-odometer authority.
extension TripTrackingControllerSessionLifecycle on TripTrackingController {
  Future<bool> start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    String? profileId,
    DateTime? startedAt,
    TripTrackingSessionAncestry? ancestry,
  }) => _runExclusiveSessionOperation(
    false,
    () => _start(
      tripId: tripId,
      vehicleId: vehicleId,
      profile: profile,
      profileId: profileId,
      startedAt: startedAt,
      ancestry: ancestry,
    ),
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

  Future<bool> _start({
    required String tripId,
    required String vehicleId,
    required TripTrackingProfile profile,
    String? profileId,
    DateTime? startedAt,
    TripTrackingSessionAncestry? ancestry,
  }) async {
    if (_isDisposed) {
      return false;
    }
    final priorStorageError = _platformStatus == 'storage_failed'
        ? _platformError
        : null;
    final preservePriorStorageError =
        priorStorageError != null &&
        priorStorageError != 'Could not evaluate local trip recovery data.' &&
        priorStorageError != 'Could not save the trip locally.' &&
        priorStorageError !=
            'Could not read local split-trip ancestry evidence.';
    final effectiveProfileId = profileId?.trim().isNotEmpty == true
        ? profileId!.trim()
        : profile.name;
    if (!_isSafeTripTrackingIdentity(effectiveProfileId)) {
      _platformStatus = 'profile_identity_invalid';
      _platformError =
          'Select a valid work profile before starting trip tracking.';
      notifyListeners();
      return false;
    }
    if (ancestry != null &&
        (!ancestry.isValidFor(tripId) ||
            ancestry.kind == TripTrackingSessionAncestryKind.mergeResult)) {
      _platformStatus = 'session_ancestry_invalid';
      _platformError =
          'This split or merge reference is invalid. No tracking session was started.';
      notifyListeners();
      return false;
    }
    if (isTracking) {
      _platformStatus = 'trip_already_active';
      _platformError =
          'A trip is already active. Finish or cancel it before starting another.';
      notifyListeners();
      return false;
    }
    final platform = _platform;
    if (platform != null) {
      try {
        if (await platform.isTracking) {
          _platformStatus = 'native_service_running';
          _platformError =
              'A native GPS collector is already running. Recover or stop it before starting a new trip.';
          notifyListeners();
          return false;
        }
      } catch (error) {
        _platformStatus = 'native_service_state_unknown';
        _platformError =
            'Could not verify whether the GPS service is already running.';
        notifyListeners();
        return false;
      }
    }
    try {
      final recoveredSession = _sessionStore.activeSession;
      if (recoveredSession != null) {
        if (_isCompletionPendingSession(recoveredSession) ||
            _isRecoverableSession(recoveredSession)) {
          if (recoveredSession.profile != profile ||
              recoveredSession.effectiveProfileId != effectiveProfileId) {
            _platformStatus = 'profile_mismatch';
            _platformError =
                'The active trip is bound to ${recoveredSession.profile.name}. Switch profiles to resume, review, or complete it before starting another.';
            notifyListeners();
            return false;
          }
          if (_isCompletionPendingSession(recoveredSession)) {
            _platformStatus = 'completion_pending';
            _platformError = _completionOrRecoverableErrorMessage();
            notifyListeners();
            return false;
          }
          _session = recoveredSession;
          _platformStatus = 'trip_already_active';
          _platformError = recoveredSession.vehicleId == _odometer.vehicleId
              ? _completionOrRecoverableErrorMessage()
              : 'A trip is already stored locally for ${recoveredSession.vehicleId}. Switch vehicles to resume, review, or complete it before starting another.';
          notifyListeners();
          return false;
        }
        _platformStatus =
            recoveredSession.lifecycleState ==
                TripTrackingSessionLifecycleState.cancelled
            ? 'cancelled_review_pending'
            : 'stored_session_requires_review';
        _platformError =
            recoveredSession.lifecycleState ==
                TripTrackingSessionLifecycleState.cancelled
            ? 'A cancelled trip is still being preserved for review. Recover it before starting another trip.'
            : 'Stored trip evidence needs review before another trip can start.';
        notifyListeners();
        return false;
      }
    } catch (error) {
      // We cannot confidently determine whether a durable checkpoint is
      // recoverable. Preserve the current evidence and fail closed so we do not
      // risk silently discarding a prior trip.
      _platformStatus = 'storage_failed';
      _platformError = 'Could not evaluate local trip recovery data.';
      notifyListeners();
      return false;
    }
    if (!_isSafeTripTrackingIdentity(tripId) ||
        !_isSafeTripTrackingIdentity(vehicleId)) {
      _platformStatus = 'trip_identity_invalid';
      _platformError =
          'Trip and vehicle identifiers must be safe values without control characters or leading/trailing whitespace.';
      notifyListeners();
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
      if (_sessionStore.recoveryReviewForTrip(tripId) != null) {
        _platformStatus = 'trip_review_exists';
        _platformError =
            'A review already exists for this trip. Review it before starting a new trip.';
        notifyListeners();
        return false;
      }
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
    if (ancestry?.kind == TripTrackingSessionAncestryKind.splitChild) {
      TripTrackingReviewRecord? parent;
      var parentAlreadySplit = false;
      try {
        parent = _sessionStore.reviewForTrip(ancestry!.parentSessionId!);
        parentAlreadySplit = _sessionStore.pendingReviews.any(
          (review) =>
              review.ancestry?.kind ==
                  TripTrackingSessionAncestryKind.splitChild &&
              review.ancestry?.parentSessionId == ancestry.parentSessionId,
        );
      } catch (error) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not read local split-trip ancestry evidence.';
        notifyListeners();
        return false;
      }
      final odometerBoundaryMatches =
          parent?.vehicleId != vehicleId ||
          parent?.confirmedEndingOdometer == _odometer.confirmedReading;
      if (parent == null ||
          !parent.isOdometerConfirmed ||
          !odometerBoundaryMatches ||
          parentAlreadySplit ||
          started.toUtc().isBefore(parent.finishedAt.toUtc())) {
        _platformStatus = 'split_parent_unavailable';
        _platformError =
            'The preserved parent trip needs an unused confirmed odometer and time boundary.';
        notifyListeners();
        return false;
      }
    }
    final startingOdometer = _odometer.confirmedReading;
    if (!_odometer.beginLiveTripProjection(
      tripId: tripId,
      startingOdometer: startingOdometer,
      observedAtUtc: started,
    )) {
      _platformStatus = 'odometer_projection_unavailable';
      _platformError =
          'Could not start live trip projection. A trip may already be active on this odometer state.';
      notifyListeners();
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
      vehicleConfigurationRevision: _currentVehicleConfigurationRevision,
      gpsAssistanceCalibrationMultiplier: _activeTripCalibrationMultiplier,
      ancestry: ancestry,
      startingOdometer: startingOdometer,
      profile: profile,
      profileId: effectiveProfileId,
      startedAt: started,
      updatedAt: started,
      startedTimeZoneOffsetMinutes: started.timeZoneOffset.inMinutes,
      startedTimeZoneName: started.timeZoneName,
      engineSnapshot: _engine!.snapshot,
    );
    try {
      final created = await _sessionStore.createIfNoSessionEvidence(_session!);
      if (!created) {
        _odometer.clearLiveTripProjection(tripId: tripId);
        _session = null;
        _engine = null;
        _projection = null;
        _activeTripCalibrationMultiplier = 1;
        _platformStatus = 'trip_already_active';
        _platformError =
            'Another trip session was saved while this trip was starting. Recover or review it before trying again.';
        notifyListeners();
        return false;
      }
    } catch (error) {
      // An active trip is only recoverable after its initial local checkpoint
      // succeeds. Do not leave a phantom trip holding the live odometer when
      // storage is unavailable (for example, a full or closed local store).
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
    if (!preservePriorStorageError) {
      _platformStatus = null;
      _platformError = null;
    }
    notifyListeners();
    return true;
  }

  Future<bool> restore() => _runExclusiveSessionOperation(
    false,
    _restore,
    busyStatus: 'session_operation_in_progress',
    busyError:
        'A trip is already starting or ending. Please wait for it to finish.',
  );

  Future<bool> _restore() async {
    if (_isDisposed || isTracking) return false;
    TripTrackingSessionRecord? session;
    try {
      session = await _sessionStore.recoverActive(recordedAtUtc: _clockNow());
    } catch (error) {
      _platformStatus = 'storage_failed';
      _platformError = 'Could not read local trip recovery data.';
      notifyListeners();
      return false;
    }
    if (session == null) {
      try {
        final diagnostic = await _sessionStore
            .recordUnreadableRecoveryDiagnostic(recordedAtUtc: _clockNow());
        if (diagnostic != null) {
          _platformStatus = 'corrupt_session_recovery_required';
          _platformError =
              'A damaged trip checkpoint was preserved for recovery review. It was not deleted or used as mileage.';
          notifyListeners();
        }
      } catch (_) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not preserve damaged trip recovery evidence.';
        notifyListeners();
      }
      return false;
    }
    if (session.lifecycleState == TripTrackingSessionLifecycleState.cancelled) {
      return _recoverCancelledSession(session);
    }
    if (session.lifecycleState == TripTrackingSessionLifecycleState.stopping) {
      return _recoverStoppingSession(session);
    }
    if (!_isRecoverableSession(session)) {
      if (_isCompletionPendingSession(session)) {
        _session = null;
        _platformStatus = 'completion_pending';
        _platformError = _completionOrRecoverableErrorMessage();
        notifyListeners();
        return false;
      }
      try {
        final quarantined = await _sessionStore.quarantineActiveSession(
          sessionId: session.id,
          reasonCode: 'unsafe_session_recovery_boundary',
          quarantinedAtUtc: _clockNow(),
        );
        _platformStatus = quarantined
            ? 'session_quarantined'
            : 'session_quarantine_pending';
        _platformError = quarantined
            ? 'An unsafe trip checkpoint was isolated without deleting its evidence.'
            : 'An unsafe trip checkpoint still needs recovery review.';
      } catch (_) {
        _platformStatus = 'storage_failed';
        _platformError = 'Could not isolate invalid local trip data safely.';
      }
      notifyListeners();
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
    _activeTripCalibrationMultiplier =
        session.gpsAssistanceCalibrationMultiplier;
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
    final recoveredSession = session.copyWith(
      recoveryCount: session.recoveryCount + 1,
      revision: session.revision + 1,
    );
    try {
      await _sessionStore.save(recoveredSession);
      _session = recoveredSession;
    } catch (_) {
      _odometer.clearLiveTripProjection(tripId: recoveredSession.id);
      _session = null;
      _engine = null;
      _projection = null;
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save the trip recovery count locally.';
      notifyListeners();
      return false;
    }
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
      if (!_canAcceptTrustedGpsSample(session.lifecycleState)) {
        // Paused and otherwise non-collecting sessions must retain the exact
        // in-flight evidence without treating it as trusted distance. Replay
        // is deferred until an explicit lifecycle transition permits GPS
        // ingestion; clearing it here would silently lose crash evidence.
        _platformStatus = 'pending_replay_deferred';
        _platformError =
            'Pending GPS evidence is preserved until tracking can safely resume.';
        notifyListeners();
      } else {
        try {
          // Restore already owns the exclusive session boundary and has drained
          // the public ingestion queue, so replay the durable pending sample
          // directly without allowing a competing native callback.
          final replayDecision = await _ingest(
            pending.sample,
            activity: pending.activity,
          );
          if (replayDecision == null) {
            _platformStatus = 'pending_replay_failed';
            _platformError = 'Could not replay the last pending GPS sample.';
            notifyListeners();
            return true;
          }
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
        String? nativeRecoveryStatus;
        final recoveryGateway = platform is TripTrackingNativeRecoveryGateway
            ? platform as TripTrackingNativeRecoveryGateway
            : null;
        if (recoveryGateway != null) {
          try {
            nativeRecoveryStatus = await recoveryGateway
                .consumeRecoveryStatus();
          } catch (_) {
            // Recovery markers are supporting evidence only. The durable
            // session and live native probe remain authoritative.
          }
        }
        final providerRunning = await platform.isTracking;
        final recoveredContractState = session.effectiveContractState;
        final latestPermission = session.permissionHistory.isEmpty
            ? null
            : session.permissionHistory.last;
        final lastTransitionReason = session.transitionAudits.isEmpty
            ? ''
            : session.transitionAudits.last.reasonCode;
        final permissionResumeRequired =
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION ||
            (recoveredContractState ==
                    TripTrackingSessionLifecycleContractState
                        .PAUSED_BY_SYSTEM &&
                (lastTransitionReason.contains('permission_revoked') ||
                    lastTransitionReason.contains('permission_failed')));
        final locationServicesResumeRequired =
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState
                    .AWAITING_LOCATION_SERVICES ||
            (recoveredContractState ==
                    TripTrackingSessionLifecycleContractState
                        .PAUSED_BY_SYSTEM &&
                lastTransitionReason.contains('location_services'));
        final criticalBatteryResumeRequired =
            lastTransitionReason.contains('critical_battery') ||
            lastTransitionReason.contains('battery_critical');
        final backgroundPermissionResumeRequired =
            permissionResumeRequired &&
            session.backgroundTrackingAllowed &&
            ((latestPermission?.preciseLocation == true &&
                    latestPermission?.canTrackInBackground == false) ||
                lastTransitionReason.contains('background_permission'));
        final foregroundServicePermissionResumeRequired =
            permissionResumeRequired &&
            lastTransitionReason.contains('foreground_service_permission');
        final permissionRecoveryStatus = backgroundPermissionResumeRequired
            ? 'background_location_settings_required'
            : 'permission_required';
        final permissionRecoveryError = backgroundPermissionResumeRequired
            ? 'Background GPS permission must be restored in device settings before you resume this trip.'
            : foregroundServicePermissionResumeRequired
            ? TripTrackingNativeErrorPolicy.safeMessage(
                'trip_tracking_foreground_service_denied',
              )
            : 'GPS permission must be restored before you resume this trip.';
        final explicitResumeRequired =
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION ||
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState
                    .AWAITING_LOCATION_SERVICES ||
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState.PAUSED_BY_USER ||
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM ||
            recoveredContractState ==
                TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE;
        if (providerRunning && explicitResumeRequired) {
          try {
            await platform.stop();
            _platformStatus = switch (recoveredContractState) {
              TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION =>
                permissionRecoveryStatus,
              TripTrackingSessionLifecycleContractState
                  .AWAITING_LOCATION_SERVICES =>
                'location_services_required',
              TripTrackingSessionLifecycleContractState.PAUSED_BY_USER =>
                'recovery_paused_by_user',
              TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM =>
                permissionResumeRequired
                    ? permissionRecoveryStatus
                    : locationServicesResumeRequired
                    ? 'location_services_required'
                    : criticalBatteryResumeRequired
                    ? 'battery_critical_gps_blocked'
                    : 'recovery_paused_native_missing',
              TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE =>
                criticalBatteryResumeRequired
                    ? 'battery_critical_gps_blocked'
                    : 'recoverable',
              _ => 'recovery_paused_native_missing',
            };
            _platformError = switch (recoveredContractState) {
              TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION =>
                permissionRecoveryError,
              TripTrackingSessionLifecycleContractState
                  .AWAITING_LOCATION_SERVICES =>
                'Device location must be turned on before you resume this trip.',
              TripTrackingSessionLifecycleContractState.PAUSED_BY_USER => null,
              TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM =>
                permissionResumeRequired
                    ? permissionRecoveryError
                    : locationServicesResumeRequired
                    ? 'Device location must be turned on before you resume this trip.'
                    : criticalBatteryResumeRequired
                    ? TripTrackingNativeErrorPolicy.safeMessage(
                        'trip_tracking_battery_critical',
                      )
                    : 'GPS assistance remains paused until you explicitly resume this trip.',
              TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE =>
                criticalBatteryResumeRequired
                    ? TripTrackingNativeErrorPolicy.safeMessage(
                        'trip_tracking_battery_critical',
                      )
                    : 'GPS assistance could not continue and needs an explicit retry.',
              _ =>
                'GPS assistance remains paused until you explicitly resume this trip.',
            };
          } catch (_) {
            _platformStatus = 'recoverable';
            _platformError =
                'Could not stop GPS while restoring a session that requires explicit resume.';
          }
        } else if (providerRunning) {
          if (!session.backgroundTrackingAllowed) {
            // A collector that outlives this process cannot continue from
            // missing or foreground-only consent. Keep the local trip for an
            // explicit driver restart instead of silently tracking.
            try {
              await platform.stop();
              final engineBeforeGap = _engine?.snapshot;
              _engine?.beginSignalGap(
                _nonRegressingSessionTime(session, _clockNow()),
                reason: TripTrackingSignalGapReason.systemPause,
              );
              final transitioned = await _tryTransitionSession(
                TripTrackingSessionLifecycleState.paused,
                pauseKind: TripTrackingPauseKind.system,
                health: TripTrackingHealthState.interrupted,
                source: 'session_recovery',
                reasonCode: 'background_consent_missing_after_recovery',
              );
              if (!transitioned && engineBeforeGap != null) {
                _engine = TripTrackingEngine.fromSnapshot(
                  engineBeforeGap,
                  policy: _policy,
                  profile: session.profile,
                );
              } else {
                _platformStatus = 'background_consent_required';
                _platformError =
                    'GPS recovery was paused because background tracking was not previously authorized.';
              }
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
              await _stopNativeTracking(
                interrupted: true,
                interruptionHealth: TripTrackingHealthState.unavailable,
                interruptionSource: 'session_recovery',
                interruptionReasonCode:
                    'recovery_sampling_state_missing_system_pause',
              );
              _platformStatus = 'sampling_recovery_required';
            } else {
              bool reapplied;
              String? reapplyErrorCode;
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
              } catch (error) {
                reapplied = false;
                reapplyErrorCode = error is PlatformException
                    ? error.code
                    : null;
              }
              if (!reapplied) {
                final authorizationLost =
                    TripTrackingNativeErrorPolicy.isAuthorizationLoss(
                      reapplyErrorCode,
                    );
                final locationServicesLost =
                    TripTrackingNativeErrorPolicy.isLocationServicesLoss(
                      reapplyErrorCode,
                    );
                _platformError = authorizationLost || locationServicesLost
                    ? TripTrackingNativeErrorPolicy.safeMessage(
                        reapplyErrorCode,
                      )
                    : 'GPS recovery was paused because the device could not reapply its saved tracking settings.';
                await _stopNativeTracking(
                  interrupted: true,
                  interruptionHealth: authorizationLost
                      ? TripTrackingHealthState.permissionBlocked
                      : TripTrackingHealthState.unavailable,
                  interruptionSource: 'session_recovery',
                  interruptionReasonCode: authorizationLost
                      ? reapplyErrorCode ==
                                'trip_tracking_background_location_denied'
                            ? 'recovery_background_permission_revoked_system_pause'
                            : reapplyErrorCode ==
                                  'trip_tracking_foreground_service_denied'
                            ? 'recovery_foreground_service_permission_failed_system_pause'
                            : 'recovery_permission_revoked_system_pause'
                      : locationServicesLost
                      ? 'recovery_location_services_lost_system_pause'
                      : 'recovery_native_reconfiguration_system_pause',
                );
                _platformStatus = authorizationLost
                    ? reapplyErrorCode ==
                              'trip_tracking_background_location_denied'
                          ? 'background_location_settings_required'
                          : 'permission_required'
                    : locationServicesLost
                    ? 'location_services_required'
                    : 'native_reconfiguration_failed';
              } else {
                _platformSubscription = _listenToPlatformEvents(platform);
                try {
                  _lastKnownCapabilities = await platform.readCapabilities();
                  if (_lastKnownCapabilities?.locationAvailable == false) {
                    await _handleNativeSystemPause(
                      message:
                          'Device location must be turned on before GPS recovery can continue.',
                      health: TripTrackingHealthState.unavailable,
                      platformStatus: 'location_services_required',
                      source: 'session_recovery_capabilities',
                      reasonCode:
                          'recovery_location_services_unavailable_system_pause',
                    );
                  } else {
                    _lastBatterySafetyCheckUtc = _clockNow().toUtc();
                    await _enforceRuntimeBatterySafety();
                  }
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
        } else if (explicitResumeRequired) {
          _platformStatus = switch (recoveredContractState) {
            TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION =>
              permissionRecoveryStatus,
            TripTrackingSessionLifecycleContractState
                .AWAITING_LOCATION_SERVICES =>
              'location_services_required',
            TripTrackingSessionLifecycleContractState.PAUSED_BY_USER =>
              'recovery_paused_by_user',
            TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM =>
              permissionResumeRequired
                  ? permissionRecoveryStatus
                  : locationServicesResumeRequired
                  ? 'location_services_required'
                  : criticalBatteryResumeRequired
                  ? 'battery_critical_gps_blocked'
                  : 'recovery_paused_native_missing',
            TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE =>
              criticalBatteryResumeRequired
                  ? 'battery_critical_gps_blocked'
                  : 'recoverable',
            _ => 'recovery_paused_native_missing',
          };
          _platformError = switch (recoveredContractState) {
            TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION =>
              permissionRecoveryError,
            TripTrackingSessionLifecycleContractState
                .AWAITING_LOCATION_SERVICES =>
              'Device location must be turned on before you resume this trip.',
            TripTrackingSessionLifecycleContractState.PAUSED_BY_USER => null,
            TripTrackingSessionLifecycleContractState.PAUSED_BY_SYSTEM =>
              permissionResumeRequired
                  ? permissionRecoveryError
                  : locationServicesResumeRequired
                  ? 'Device location must be turned on before you resume this trip.'
                  : criticalBatteryResumeRequired
                  ? TripTrackingNativeErrorPolicy.safeMessage(
                      'trip_tracking_battery_critical',
                    )
                  : 'GPS assistance remains paused until you explicitly resume this trip.',
            TripTrackingSessionLifecycleContractState.FAILED_RECOVERABLE =>
              criticalBatteryResumeRequired
                  ? TripTrackingNativeErrorPolicy.safeMessage(
                      'trip_tracking_battery_critical',
                    )
                  : 'GPS assistance could not continue and needs an explicit retry.',
            _ =>
              'GPS assistance remains paused until you explicitly resume this trip.',
          };
        } else if (session.lifecycleState ==
                TripTrackingSessionLifecycleState.active ||
            session.lifecycleState ==
                TripTrackingSessionLifecycleState.degraded ||
            session.lifecycleState ==
                TripTrackingSessionLifecycleState.starting) {
          final driverRequestedPause = nativeRecoveryStatus == 'paused_by_user';
          final engineBeforeGap = _engine?.snapshot;
          _engine?.beginSignalGap(
            session.updatedAt,
            reason: driverRequestedPause
                ? TripTrackingSignalGapReason.userPause
                : TripTrackingSignalGapReason.systemPause,
          );
          final target =
              TripTrackingSessionStateMachine.canTransition(
                session.lifecycleState,
                TripTrackingSessionLifecycleState.paused,
              )
              ? TripTrackingSessionLifecycleState.paused
              : TripTrackingSessionLifecycleState.failedRecoverable;
          final transitioned = await _tryTransitionSession(
            target,
            pauseKind: target == TripTrackingSessionLifecycleState.paused
                ? driverRequestedPause
                      ? TripTrackingPauseKind.user
                      : TripTrackingPauseKind.system
                : null,
            health: driverRequestedPause
                ? null
                : TripTrackingHealthState.interrupted,
            source: 'session_recovery',
            reasonCode: driverRequestedPause
                ? 'native_notification_pause_recovered'
                : 'native_collector_missing_after_recovery',
          );
          if (!transitioned && engineBeforeGap != null) {
            _engine = TripTrackingEngine.fromSnapshot(
              engineBeforeGap,
              policy: _policy,
              profile: session.profile,
            );
          } else {
            _platformStatus = driverRequestedPause
                ? 'recovery_paused_by_user'
                : 'recovery_paused_native_missing';
            _platformError = driverRequestedPause
                ? null
                : 'The trip was recovered, but GPS collection is paused because the native service is no longer running.';
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

  Future<bool> _recoverCancelledSession(
    TripTrackingSessionRecord session,
  ) async {
    if (!session.hasValidTimeline ||
        !_isSafeTripTrackingIdentity(session.id) ||
        !_isSafeTripTrackingIdentity(session.vehicleId)) {
      _platformStatus = 'cancelled_session_invalid';
      _platformError =
          'Cancelled trip evidence needs manual recovery because its local record is incomplete.';
      notifyListeners();
      return false;
    }
    try {
      final existing = _sessionStore.recoveryReviewForTrip(session.id);
      if (existing != null && !_isAuthoritativeReview(existing, session)) {
        _platformStatus = 'cancelled_review_invalid';
        _platformError =
            'Cancelled trip evidence is preserved, but its saved review needs repair.';
        notifyListeners();
        return false;
      }
      if (existing == null) {
        final engine = TripTrackingEngine.fromSnapshot(
          session.engineSnapshot,
          policy: _policy,
          profile: session.profile,
        );
        final projection = TripLiveOdometerProjection(
          startingOdometer: session.startingOdometer,
          maxSupportedReading: _odometer.maxSupportedReading,
        );
        await _sessionStore.saveReview(
          _buildReviewRecord(
            session: session,
            engine: engine,
            projection: projection,
            finishedAt: session.updatedAt,
          ),
        );
      }
      await _sessionStore.clearPending(session.id);
      await _sessionStore.clear();
      _platformStatus = 'cancelled_review_recovered';
      _platformError = null;
    } catch (_) {
      _platformStatus = 'cancelled_review_recovery_failed';
      _platformError =
          'Cancelled trip evidence remains saved and will be recovered on the next retry.';
    }
    notifyListeners();
    return false;
  }

  Future<bool> _recoverStoppingSession(
    TripTrackingSessionRecord session,
  ) async {
    if (!session.hasValidTimeline ||
        !_isSafeTripTrackingIdentity(session.id) ||
        !_isSafeTripTrackingIdentity(session.vehicleId)) {
      _platformStatus = 'completion_session_invalid';
      _platformError =
          'Completed trip evidence needs manual recovery because its local record is incomplete.';
      notifyListeners();
      return false;
    }
    try {
      final existing = _sessionStore.recoveryReviewForTrip(session.id);
      if (existing != null && !_isAuthoritativeReview(existing, session)) {
        _platformStatus = 'completion_review_invalid';
        _platformError =
            'Completed trip evidence is preserved, but its saved review needs repair.';
        notifyListeners();
        return false;
      }
      if (existing == null) {
        final engine = TripTrackingEngine.fromSnapshot(
          session.engineSnapshot,
          policy: _policy,
          profile: session.profile,
        );
        final projection = TripLiveOdometerProjection(
          startingOdometer: session.startingOdometer,
          maxSupportedReading: _odometer.maxSupportedReading,
        );
        await _sessionStore.saveReview(
          _buildReviewRecord(
            session: session,
            engine: engine,
            projection: projection,
            finishedAt: session.updatedAt,
          ),
        );
      }
      await _sessionStore.clearPending(session.id);
      await _sessionStore.clear();
      _platformStatus = 'completion_review_recovered';
      _platformError = null;
    } catch (_) {
      _platformStatus = 'completion_review_recovery_failed';
      _platformError =
          'Completed trip evidence remains saved and will be recovered on the next retry.';
    }
    notifyListeners();
    return false;
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
        TripTrackingSessionLifecycleState.permissionRequired ||
        TripTrackingSessionLifecycleState.starting ||
        TripTrackingSessionLifecycleState.active ||
        TripTrackingSessionLifecycleState.paused ||
        TripTrackingSessionLifecycleState.degraded ||
        TripTrackingSessionLifecycleState.interrupted ||
        TripTrackingSessionLifecycleState.recovering ||
        TripTrackingSessionLifecycleState.stopping ||
        TripTrackingSessionLifecycleState.failedRecoverable => true,
        TripTrackingSessionLifecycleState.disabled ||
        TripTrackingSessionLifecycleState.awaitingReview ||
        TripTrackingSessionLifecycleState.completed ||
        TripTrackingSessionLifecycleState.cancelled ||
        TripTrackingSessionLifecycleState.failedTerminal => false,
      };

  bool _isAuthoritativeReview(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      review.hasValidTimeline &&
      review.id == session.id &&
      review.vehicleId == session.vehicleId &&
      review.profile == session.profile &&
      review.effectiveProfileId == session.effectiveProfileId &&
      review.vehicleConfigurationRevision ==
          session.vehicleConfigurationRevision &&
      review.startedTimeZoneOffsetMinutes ==
          session.startedTimeZoneOffsetMinutes &&
      review.startedTimeZoneName == session.startedTimeZoneName &&
      _reviewAdvisoriesMatchSession(review, session) &&
      _reviewTripEventsMatchSession(review, session) &&
      _reviewEngineSnapshotMatchesSession(review, session) &&
      _reviewRecoveryEvidenceMatchesSession(review, session) &&
      _reviewEstimatedOdometerMatchesSession(review, session) &&
      _reviewFinishedAtMatchesSession(review, session) &&
      review.startingOdometer == session.startingOdometer &&
      review.startedAt == session.startedAt &&
      review.estimatedEndingOdometer >= review.startingOdometer;

  bool _reviewEngineSnapshotMatchesSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      jsonEncode(review.engineSnapshot.toMap()) ==
      jsonEncode(session.engineSnapshot.toMap());

  bool _reviewEstimatedOdometerMatchesSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) {
    final projection = TripLiveOdometerProjection(
      startingOdometer: session.startingOdometer,
      maxSupportedReading: _odometer.maxSupportedReading,
    );
    final expected = projection.updateAcceptedMeters(
      session.engineSnapshot.totalAcceptedMeters,
      gpsAssistanceCalibrationMultiplier:
          session.gpsAssistanceCalibrationMultiplier,
    );
    return !projection.lastUpdateExceededMax &&
        review.estimatedEndingOdometer == expected;
  }

  bool _reviewFinishedAtMatchesSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) {
    if (session.lifecycleState == TripTrackingSessionLifecycleState.stopping ||
        session.lifecycleState == TripTrackingSessionLifecycleState.cancelled) {
      return review.finishedAt == session.updatedAt;
    }
    return !review.finishedAt.isBefore(session.updatedAt);
  }

  bool _reviewRecoveryEvidenceMatchesSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      review.gpsAssistanceCalibrationMultiplier ==
          session.gpsAssistanceCalibrationMultiplier &&
      review.recoveryCount == session.recoveryCount &&
      review.revision >= session.revision &&
      jsonEncode(review.ancestry?.toMap()) ==
          jsonEncode(session.ancestry?.toMap()) &&
      jsonEncode(
            review.transitionAudits.map((audit) => audit.toMap()).toList(),
          ) ==
          jsonEncode(
            session.transitionAudits.map((audit) => audit.toMap()).toList(),
          ) &&
      jsonEncode(review.batteryStateSummary?.toMap()) ==
          jsonEncode(session.batteryStateSummary?.toMap()) &&
      jsonEncode(
            review.permissionHistory
                .map((evidence) => evidence.toMap())
                .toList(),
          ) ==
          jsonEncode(
            session.permissionHistory
                .map((evidence) => evidence.toMap())
                .toList(),
          );

  bool _reviewAdvisoriesMatchSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      jsonEncode(
        review.advisories.map((advisory) => advisory.toMap()).toList(),
      ) ==
      jsonEncode(
        session.advisories.map((advisory) => advisory.toMap()).toList(),
      );

  bool _reviewTripEventsMatchSession(
    TripTrackingReviewRecord review,
    TripTrackingSessionRecord session,
  ) =>
      jsonEncode(review.tripEvents.map((event) => event.toMap()).toList()) ==
      jsonEncode(session.tripEvents.map((event) => event.toMap()).toList());

  bool _isCompletionPendingSession(TripTrackingSessionRecord session) =>
      session.lifecycleState ==
      TripTrackingSessionLifecycleState.awaitingReview;

  String _completionOrRecoverableErrorMessage() =>
      'A trip is already stored locally and requires completion actions. Review it, complete it, or cancel it before starting another.';
}
