// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// Stops, pauses, and checks native collection while retaining local TripLog
/// and confirmed-odometer authority.
extension TripTrackingControllerNativeLifecycle on TripTrackingController {
  Future<void> stopNativeTracking() =>
      _enqueueNativeLifecycle(_stopNativeTracking);

  /// Applies the app-wide GPS assistance opt-in to a running collector.
  ///
  /// Withdrawing consent pauses native assistance immediately while preserving
  /// the local trip and confirmed odometer. Granting consent never starts or
  /// resumes collection without the driver's separate start/resume action.
  Future<void> applyGpsAssistanceConsent({required bool enabled}) {
    if (enabled) return Future<void>.value();
    return _enqueueNativeLifecycle(() async {
      final state = _session?.lifecycleState;
      final mustStop =
          _nativeTracking ||
          state == TripTrackingSessionLifecycleState.starting ||
          state == TripTrackingSessionLifecycleState.active ||
          state == TripTrackingSessionLifecycleState.degraded ||
          state == TripTrackingSessionLifecycleState.recovering;
      if (!mustStop) return;
      await _stopNativeTracking();
      _platformStatus = 'gps_assistance_disabled';
      _platformError = null;
      notifyListeners();
    });
  }

  /// Withdraw optional motion-sensor assistance from an active collector.
  ///
  /// This is deliberately one-way for a running session: enabling a sensor
  /// later would require a fresh permission/capability decision, so it applies
  /// only when the next GPS session is started. Disabling must take effect now.
  Future<void> disableActivityRecognition() =>
      _enqueueNativeLifecycle(_disableActivityRecognition);

  Future<void> _disableActivityRecognition() async {
    if (!_activityRecognitionEnabled) return;
    _activityRecognitionEnabled = false;
    _latestActivity = null;
    if (!await _persistNativeCollectionPreferences(
      allowBackground: _backgroundTrackingAllowed,
      activityRecognitionEnabled: false,
    )) {
      _platformError =
          'Motion activity was disabled, but GPS tracking stopped because the privacy change could not be saved locally.';
      await _stopNativeTracking(
        interrupted: true,
        interruptionHealth: TripTrackingHealthState.unavailable,
        interruptionSource: 'motion_assistance_withdrawal',
        interruptionReasonCode: 'motion_withdrawal_storage_system_pause',
      );
      _platformStatus = 'storage_failed';
      notifyListeners();
      return;
    }
    final platform = _platform;
    final session = _session;
    final sampling = _nativeSampling;
    if (!_nativeTracking || platform == null || session == null) {
      notifyListeners();
      return;
    }
    if (sampling == null) {
      // Legacy recoveries can lack a persisted sampling request. Continuing
      // would leave us unable to prove that the native motion sensor was
      // withdrawn, so stop the collector rather than retaining optional
      // sensor access after the driver opted out.
      _platformError =
          'Motion activity was disabled, but GPS tracking stopped because the recovered sampling state was unavailable.';
      await _stopNativeTracking(
        interrupted: true,
        interruptionHealth: TripTrackingHealthState.unavailable,
        interruptionSource: 'motion_assistance_withdrawal',
        interruptionReasonCode: 'motion_withdrawal_recovery_state_system_pause',
      );
      return;
    }
    String? updateErrorCode;
    try {
      final updated = await platform.update(
        TripTrackingNativeRequest(
          profile: session.profile,
          sampling: sampling,
          allowBackground: _backgroundTrackingAllowed,
          activityRecognitionEnabled: false,
        ),
      );
      if (updated) {
        notifyListeners();
        return;
      }
    } catch (error) {
      updateErrorCode = error is PlatformException ? error.code : null;
      // A failed native update leaves the optional sensor state uncertain.
    }
    final authorizationLost = TripTrackingNativeErrorPolicy.isAuthorizationLoss(
      updateErrorCode,
    );
    final locationServicesLost =
        TripTrackingNativeErrorPolicy.isLocationServicesLoss(updateErrorCode);
    _platformError = authorizationLost || locationServicesLost
        ? TripTrackingNativeErrorPolicy.safeMessage(updateErrorCode)
        : 'Motion activity was disabled, but GPS tracking stopped because the device could not apply that privacy change.';
    await _stopNativeTracking(
      interrupted: true,
      interruptionHealth: authorizationLost
          ? TripTrackingHealthState.permissionBlocked
          : TripTrackingHealthState.unavailable,
      interruptionSource: 'motion_assistance_withdrawal',
      interruptionReasonCode: authorizationLost
          ? updateErrorCode == 'trip_tracking_background_location_denied'
                ? 'motion_withdrawal_background_permission_revoked_system_pause'
                : updateErrorCode == 'trip_tracking_foreground_service_denied'
                ? 'motion_withdrawal_foreground_service_permission_failed_system_pause'
                : 'motion_withdrawal_permission_revoked_system_pause'
          : locationServicesLost
          ? 'motion_withdrawal_location_services_system_pause'
          : 'motion_withdrawal_native_system_pause',
    );
    if (authorizationLost) {
      _platformStatus =
          updateErrorCode == 'trip_tracking_background_location_denied'
          ? 'background_location_settings_required'
          : 'permission_required';
    } else if (locationServicesLost) {
      _platformStatus = 'location_services_required';
    }
    notifyListeners();
  }

  /// Foreground-only tracking must never continue after the app leaves the
  /// foreground. Background collection remains an explicit user setting and
  /// is separately permission-gated by [startNativeTracking]. Serializing this
  /// with native start/stop prevents a lifecycle transition from racing a
  /// just-started collector.
  Future<void> handleAppLifecycleState(
    AppLifecycleState state, {
    required bool backgroundTrackingAllowed,
  }) => _enqueueNativeLifecycle(() async {
    // The UI-provided preference is not authority by itself: it can be stale
    // across a settings change or process restoration. Continuing collection
    // in the background requires both that current preference and the
    // consent durably bound to this native collector at startup.
    final mayContinueInBackground =
        backgroundTrackingAllowed && _backgroundTrackingAllowed;
    if (state == AppLifecycleState.resumed && mayContinueInBackground) {
      await _enforceRuntimeBatterySafety();
      if (!_nativeTracking) return;
      await _checkNativeHeartbeat();
      return;
    }
    if (mayContinueInBackground ||
        (state != AppLifecycleState.paused &&
            state != AppLifecycleState.hidden &&
            state != AppLifecycleState.detached)) {
      return;
    }
    await _stopNativeTracking(interrupted: true);
  });

  /// Reconciles the expected native collector after an app resume. This never
  /// creates distance, stops, or odometer changes; it only preserves the
  /// local session lifecycle for user-directed recovery.
  Future<TripTrackingHeartbeatWatchdogDecision?> checkNativeHeartbeat({
    DateTime? nowUtc,
  }) => _enqueueNativeLifecycle(() => _checkNativeHeartbeat(nowUtc: nowUtc));

  Future<TripTrackingHeartbeatWatchdogDecision?> _checkNativeHeartbeat({
    DateTime? nowUtc,
  }) async {
    final session = _session;
    if (_isDisposed || session == null) return null;
    final now = (nowUtc ?? _clockNow()).toUtc();
    await _markExpiredInitialFixPreparation(now);
    final platform = _platform;
    var providerRunning = false;
    var providerProbeSucceeded = false;
    if (_nativeTracking && platform != null) {
      try {
        providerRunning = await platform.isTracking;
        providerProbeSucceeded = true;
      } catch (_) {
        // The heartbeat policy below will preserve the local trip and surface
        // a recoverable state instead of trusting an unavailable bridge.
      }
    }
    if (providerProbeSucceeded && !providerRunning) {
      const decision = TripTrackingHeartbeatWatchdogDecision(
        status: TripTrackingHeartbeatWatchdogStatus.interruptedNeedsRecovery,
        action: TripTrackingHeartbeatWatchdogAction.markInterrupted,
        reasonCode: 'heartbeat_interrupted_recovery_required',
        targetLifecycle: TripTrackingSessionLifecycleState.interrupted,
        canBridgeDistanceGap: false,
        shouldRetryNativeTracking: true,
        requiresUserReview: true,
      );
      await _handleNativeInterruption(
        'GPS tracking is no longer running. Your local trip is preserved for review.',
      );
      return decision;
    }
    if (providerRunning) {
      _lastNativeHeartbeatUtc = _nonRegressingNativeHeartbeatTime(now);
    }
    final decision = TripTrackingHeartbeatWatchdogPolicy.evaluate(
      currentLifecycle: session.lifecycleState,
      lastHeartbeatUtc: _lastNativeHeartbeatUtc,
      nowUtc: now,
      nativeTrackingExpected: _nativeTracking,
    );
    switch (decision.action) {
      case TripTrackingHeartbeatWatchdogAction.continueTracking:
        if (providerRunning && _nativeTracking) {
          _platformStatus =
              _awaitingInitialFix &&
                  _engine?.snapshot.initialFixAssessment?.quality ==
                      TripInitialFixQuality.unavailable
              ? 'initial_fix_unavailable'
              : 'tracking';
          _platformError = null;
          notifyListeners();
        }
        break;
      case TripTrackingHeartbeatWatchdogAction.markDegraded:
        _platformStatus = 'native_heartbeat_stale';
        _platformError =
            'GPS tracking has not reported recently. Your local trip is preserved while it recovers.';
        await _tryTransitionSession(
          TripTrackingSessionLifecycleState.degraded,
          health: TripTrackingHealthState.reduced,
          source: 'heartbeat_watchdog',
          reasonCode: 'heartbeat_stale',
        );
        notifyListeners();
        break;
      case TripTrackingHeartbeatWatchdogAction.markInterrupted:
        await _handleNativeInterruption(
          'GPS tracking stopped responding. Your local trip is preserved for review.',
        );
        break;
      case TripTrackingHeartbeatWatchdogAction.preservePaused ||
          TripTrackingHeartbeatWatchdogAction.protectTerminal ||
          TripTrackingHeartbeatWatchdogAction.ignoreInvalidClock:
        break;
    }
    return decision;
  }

  Future<void> _markExpiredInitialFixPreparation(
    DateTime nowUtc, {
    bool deferStopOnStorageFailure = false,
  }) async {
    final startedAt = _nativeTrackingStartedAtUtc;
    final engine = _engine;
    final session = _session;
    if (!_awaitingInitialFix ||
        startedAt == null ||
        engine == null ||
        session == null ||
        nowUtc.isBefore(startedAt) ||
        nowUtc.difference(startedAt) < _initialFixPreparationWindow ||
        engine.snapshot.initialFixAssessment?.quality ==
            TripInitialFixQuality.unavailable) {
      return;
    }
    final previousSnapshot = engine.snapshot;
    engine.recordInitialFixAssessment(
      TripInitialFixAssessment(
        quality: TripInitialFixQuality.unavailable,
        assessedAt: nowUtc,
        confidence: TripTrackingConfidence.low,
        mayUseProvisionally: false,
      ),
    );
    final nextSession = session.copyWith(
      updatedAt: _nonRegressingSessionTime(session, nowUtc),
      revision: session.revision + 1,
      engineSnapshot: engine.snapshot,
    );
    try {
      await _sessionStore.save(nextSession);
      _session = nextSession;
      _platformStatus = 'initial_fix_unavailable';
      _platformError =
          'A reliable starting GPS location is not available yet. Your original trip start time is preserved.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.degraded,
        contractState:
            TripTrackingSessionLifecycleContractState.SIGNAL_DEGRADED,
        health: TripTrackingHealthState.reduced,
        source: 'initial_fix_watchdog',
        reasonCode: 'initial_fix_preparation_window_expired',
      );
    } catch (_) {
      _engine = TripTrackingEngine.fromSnapshot(
        previousSnapshot,
        policy: engine.policy,
        profile: engine.profile,
      );
      _platformStatus = 'storage_failed';
      _platformError = 'Could not save degraded initial GPS fix evidence.';
      if (deferStopOnStorageFailure) {
        _deferPlatformCleanup(() async {
          await _stopNativeTracking(interrupted: true);
          _platformStatus = 'storage_failed';
          _platformError = 'Could not save degraded initial GPS fix evidence.';
          notifyListeners();
        });
      } else {
        await _stopNativeTracking(interrupted: true);
        _platformStatus = 'storage_failed';
        _platformError = 'Could not save degraded initial GPS fix evidence.';
        notifyListeners();
      }
    }
  }

  DateTime _nonRegressingNativeHeartbeatTime(DateTime candidateUtc) {
    final candidate = candidateUtc.toUtc();
    final current = _lastNativeHeartbeatUtc;
    return current != null && candidate.isBefore(current) ? current : candidate;
  }

  Future<void> _stopNativeTracking({
    bool interrupted = false,
    TripTrackingHealthState? interruptionHealth,
    String? interruptionSource,
    String? interruptionReasonCode,
  }) async {
    final platform = _platform;
    final wasNativeTracking = _nativeTracking;
    final engine = _engine;
    final engineBeforeGap = engine?.snapshot;
    if (wasNativeTracking) _nativeStopRequested = true;
    if (platform != null && wasNativeTracking) {
      try {
        await platform.stop();
      } catch (error) {
        _platformError = 'The device could not cleanly stop GPS tracking.';
      }
    }
    try {
      await _platformSubscription?.cancel();
    } catch (error) {
      _platformError ??= 'Could not detach GPS event listener cleanly.';
    } finally {
      _platformSubscription = null;
    }
    // Drain events emitted just before the native stop/cancel boundary so a
    // final credible sample cannot be dropped before review is recorded.
    await _platformEventQueue;
    _nativeTracking = false;
    _awaitingInitialFix = false;
    _nativeSampling = null;
    _nativeSamplingPlan = null;
    _lastNativeHeartbeatUtc = null;
    _nativeTrackingStartedAtUtc = null;
    _lastNativeLocationReceivedUtc = null;
    _lastBatterySafetyCheckUtc = null;
    _nativeStopRequested = false;
    _backgroundTrackingAllowed = false;
    _latestActivity = null;
    _platformStatus = interrupted ? 'interrupted' : 'stopped';
    final lifecycleState = _session?.lifecycleState;
    final interruptedStateCanBecomePause =
        (lifecycleState == TripTrackingSessionLifecycleState.interrupted ||
            lifecycleState == TripTrackingSessionLifecycleState.recovering) &&
        (!interrupted || interruptionReasonCode != null);
    if (lifecycleState == TripTrackingSessionLifecycleState.active ||
        lifecycleState == TripTrackingSessionLifecycleState.degraded ||
        interruptedStateCanBecomePause ||
        (interrupted &&
            (lifecycleState == TripTrackingSessionLifecycleState.ready ||
                lifecycleState ==
                    TripTrackingSessionLifecycleState.starting))) {
      if (wasNativeTracking &&
          engine != null &&
          (lifecycleState == TripTrackingSessionLifecycleState.active ||
              lifecycleState == TripTrackingSessionLifecycleState.degraded)) {
        engine.beginSignalGap(
          _clockNow(),
          reason: interrupted
              ? TripTrackingSignalGapReason.systemPause
              : TripTrackingSignalGapReason.userPause,
        );
      }
      final transitioned = await _tryTransitionSession(
        TripTrackingSessionLifecycleState.paused,
        pauseKind: interrupted
            ? TripTrackingPauseKind.system
            : TripTrackingPauseKind.user,
        health: interrupted ? interruptionHealth : null,
        source: interruptionSource ?? 'native_stop_tracking',
        reasonCode:
            interruptionReasonCode ??
            (interrupted
                ? 'native_tracking_interrupted_stop'
                : 'native_tracking_stopped'),
      );
      if (!transitioned && engineBeforeGap != null) {
        _engine = TripTrackingEngine.fromSnapshot(
          engineBeforeGap,
          policy: engine!.policy,
          profile: engine.profile,
        );
      }
    }
    notifyListeners();
  }

  void _clearPendingNativeStart() {
    _pendingNativeStartRequest = null;
    _pendingNativeStartActivityUnavailable = false;
    _pendingNativeStartPreferenceSaveFailed = false;
    _pendingNativeStartStopped = false;
    _pendingNativeStartAuthorizationRevoked = false;
    _pendingNativeStartErrorCode = null;
  }

  /// Platform callbacks are serialized by [_platformEventQueue]. Stopping the
  /// collector drains that queue, so cleanup must begin only after the current
  /// callback has completed instead of waiting on its own in-flight future.
  void _deferPlatformCleanup(Future<void> Function() operation) {
    unawaited(Future<void>.delayed(Duration.zero, operation));
  }
}
