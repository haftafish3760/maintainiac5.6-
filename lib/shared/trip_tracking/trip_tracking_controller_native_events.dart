// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

/// Serializes native location/activity events and enforces runtime battery
/// protection without taking ownership of confirmed TripLog or odometer data.
extension _TripTrackingControllerNativeEvents on TripTrackingController {
  String _safeNativeCommandFailure(Object error, {required String fallback}) {
    if (error is PlatformException) {
      return TripTrackingNativeErrorPolicy.safeMessage(error.code);
    }
    return fallback;
  }

  String _gpsBatteryMessageFor(TripGpsBatteryDecision decision) {
    if (decision.reasonCode == 'battery_critical_gps_blocked') {
      return 'Battery is critically low. GPS-assisted tracking is paused below 10% to preserve your device and local TripLog.';
    }
    final lowPowerMode = decision.reasonCode.startsWith('low_power_mode');
    final prompt =
        decision.status == TripGpsBatteryDecisionStatus.userPromptRequired;
    if (lowPowerMode) {
      return prompt
          ? 'Battery saver is active. Choose whether to continue GPS while the device is conserving power.'
          : 'GPS tracking is blocked while battery saver is active by your saved battery setting.';
    }
    return prompt
        ? 'Battery is at or below the GPS safety threshold. Choose whether to continue GPS at or below 15% battery.'
        : 'GPS tracking is blocked at or below 15% battery by your saved battery setting.';
  }

  StreamSubscription<TripTrackingPlatformEvent> _listenToPlatformEvents(
    TripTrackingNativeGateway platform,
  ) => platform.events.listen(
    _enqueuePlatformEvent,
    onError: (Object error) {
      if (!_nativeTracking && _pendingNativeStartRequest != null) {
        _pendingNativeStartStopped = true;
        _platformStatus = 'interrupted';
        _platformError =
            'GPS updates stopped while trip tracking was starting.';
        notifyListeners();
        return;
      }
      if (!_nativeTracking) return;
      unawaited(_handleNativeInterruption('GPS updates stopped unexpectedly.'));
    },
    onDone: () {
      if (!_nativeTracking && _pendingNativeStartRequest != null) {
        _pendingNativeStartStopped = true;
        _platformStatus = 'interrupted';
        _platformError = 'GPS updates ended while trip tracking was starting.';
        notifyListeners();
        return;
      }
      if (!_nativeTracking) return;
      _deferPlatformCleanup(
        () => _handleNativeInterruption('GPS updates ended unexpectedly.'),
      );
    },
  );

  Future<void> _handleNativeInterruption(String message) async {
    if (_isDisposed || _nativeInterruptionPending) return;
    _nativeInterruptionPending = true;
    try {
      _platformError = message;
      _platformStatus = 'error';
      if (_session?.lifecycleState ==
              TripTrackingSessionLifecycleState.active ||
          _session?.lifecycleState ==
              TripTrackingSessionLifecycleState.degraded) {
        await _tryTransitionSession(
          TripTrackingSessionLifecycleState.interrupted,
          health: TripTrackingHealthState.interrupted,
          source: 'native_interruption_event',
          reasonCode: 'native_stream_interruption',
        );
      }
      notifyListeners();
      await _stopNativeTracking(interrupted: true);
    } finally {
      _pendingNativeSystemPauseStatus = null;
      _nativeInterruptionPending = false;
    }
  }

  Future<void> _handleNativeSystemPause({
    required String message,
    required TripTrackingHealthState health,
    required String platformStatus,
    required String source,
    required String reasonCode,
  }) async {
    if (_isDisposed || _nativeInterruptionPending) return;
    _nativeInterruptionPending = true;
    try {
      _platformError = message;
      _platformStatus = platformStatus;
      notifyListeners();
      await _stopNativeTracking(
        interrupted: true,
        interruptionHealth: health,
        interruptionSource: source,
        interruptionReasonCode: reasonCode,
      );
      _platformStatus = platformStatus;
      notifyListeners();
    } finally {
      _pendingNativeSystemPauseStatus = null;
      _nativeInterruptionPending = false;
    }
  }

  void _enqueuePlatformEvent(TripTrackingPlatformEvent event) {
    _platformEventQueue = _platformEventQueue
        .then((_) async {
          if (_isDisposed) return;
          if (event.type == TripTrackingPlatformEventType.location &&
              event.location != null) {
            if (!_nativeTracking || _pendingNativeSystemPauseStatus != null) {
              return;
            }
            final receivedAt = _clockNow().toUtc();
            if (_awaitingInitialFix) {
              final engine = _engine;
              final currentSession = _session;
              if (engine == null || currentSession == null) return;
              final previousEngineSnapshot = engine.snapshot;
              final assessment = _initialFixClassifier.classify(
                sample: event.location,
                receivedAt: receivedAt,
                locationServicesAvailable:
                    _lastKnownCapabilities?.locationAvailable == true,
                preciseLocationAuthorized:
                    currentSession.permissionHistory.isNotEmpty &&
                    currentSession.permissionHistory.last.preciseLocation,
                sessionStartedAt: currentSession.startedAt,
                recentKnownLocation: engine.snapshot.lastAccepted,
              );
              engine.recordInitialFixAssessment(assessment);
              if (!assessment.mayUseProvisionally) {
                final nextSession = currentSession.copyWith(
                  updatedAt: _nonRegressingSessionTime(
                    currentSession,
                    receivedAt,
                  ),
                  revision: currentSession.revision + 1,
                  engineSnapshot: engine.snapshot,
                );
                try {
                  await _sessionStore.save(nextSession);
                  _session = nextSession;
                  _platformStatus = switch (assessment.quality) {
                    TripInitialFixQuality.staleCached => 'initial_fix_stale',
                    TripInitialFixQuality.approximateOnly =>
                      'initial_fix_approximate',
                    TripInitialFixQuality.unavailable =>
                      'initial_fix_unavailable',
                    _ => 'initial_fix_rejected',
                  };
                  _platformError = switch (assessment.quality) {
                    TripInitialFixQuality.approximateOnly =>
                      'Only approximate location is available. GPS assistance will remain low confidence until precise access is restored.',
                    TripInitialFixQuality.staleCached =>
                      'The device returned an old location. The trip remains local while GPS waits for a current fix.',
                    TripInitialFixQuality.unavailable =>
                      'GPS has not produced a usable starting location yet.',
                    _ => 'The starting GPS location was rejected safely.',
                  };
                } catch (_) {
                  _engine = TripTrackingEngine.fromSnapshot(
                    previousEngineSnapshot,
                    policy: engine.policy,
                    profile: engine.profile,
                  );
                  _platformStatus = 'storage_failed';
                  _platformError =
                      'Could not save initial GPS fix evidence locally.';
                  _deferPlatformCleanup(() async {
                    await _stopNativeTracking(
                      interrupted: true,
                      interruptionHealth: TripTrackingHealthState.unavailable,
                      interruptionSource: 'native_initial_fix_evidence',
                      interruptionReasonCode:
                          'initial_fix_evidence_storage_system_pause',
                    );
                    _platformStatus = 'storage_failed';
                    _platformError =
                        'Could not save initial GPS fix evidence locally.';
                    notifyListeners();
                  });
                }
                notifyListeners();
                return;
              }
              _awaitingInitialFix = false;
              _platformStatus = 'tracking';
              _platformError = null;
            }
            // A received provider event is a runtime heartbeat. Deliberately
            // use receive time, not the untrusted payload timestamp.
            final heartbeatAt = _nonRegressingNativeHeartbeatTime(receivedAt);
            _lastNativeHeartbeatUtc = heartbeatAt;
            _lastNativeLocationReceivedUtc = heartbeatAt;
            final activity = _latestActivity;
            final decision = await ingest(
              event.location!,
              activity:
                  activity != null &&
                      !event.location!.recordedAt.isBefore(
                        activity.recordedAt,
                      ) &&
                      event.location!.recordedAt.difference(
                            activity.recordedAt,
                          ) <=
                          const Duration(seconds: 90)
                  ? activity
                  : null,
              referenceTime: _clockNow().toUtc(),
            );
            await _maybeUpdateNativeSampling(event.location!, decision);
            await _maybePersistRoutePoint(event.location!, decision);
            if (decision?.accepted == true &&
                _platformStatus == 'gps_signal_stale') {
              _platformStatus = 'tracking';
              _platformError = null;
            }
            _scheduleRuntimeBatterySafetyCheck();
          } else if (event.activity != null) {
            // Native event streams are external input. Ignore motion evidence
            // unless this tracking session both asked for it and the platform
            // confirmed that the device can provide it.
            if (!_nativeTracking || !_activityRecognitionEnabled) return;
            // Retain activity for the next location callback only after its
            // engine snapshot is durable. Otherwise a failed local write
            // could later influence GPS assistance despite being absent from
            // crash recovery.
            if (await _persistNativeActivityEvidence(event.activity!)) {
              _latestActivity = event.activity;
            }
          } else if (event.type ==
                  TripTrackingPlatformEventType.authorization &&
              event.authorization != null) {
            final pendingStart = _pendingNativeStartRequest;
            if (!_nativeTracking && pendingStart == null) return;
            final authorization = event.authorization!;
            if (!await _persistPermissionEvidence(
              authorization,
              source: 'native_event',
            )) {
              if (_nativeTracking) {
                _deferPlatformCleanup(() async {
                  await _stopNativeTracking(
                    interrupted: true,
                    interruptionHealth: TripTrackingHealthState.unavailable,
                    interruptionSource: 'native_permission_evidence',
                    interruptionReasonCode:
                        'permission_evidence_storage_system_pause',
                  );
                  // Preserve the actionable storage failure after the native
                  // stop records its recoverable system-pause boundary.
                  _platformStatus = 'storage_failed';
                  _platformError =
                      'Could not save GPS permission state locally.';
                  notifyListeners();
                });
              }
              return;
            }
            final authorizationStillAllowsTracking =
                authorization.canTrack &&
                (!(_nativeTracking
                        ? _backgroundTrackingAllowed
                        : pendingStart!.allowBackground) ||
                    authorization.canTrackInBackground);
            if (authorizationStillAllowsTracking) {
              if (!authorization.preciseLocation) {
                _platformStatus = 'initial_fix_approximate';
                _platformError =
                    'Only approximate location is available. GPS assistance will remain low confidence until precise access is restored.';
                notifyListeners();
              } else if (_platformStatus == 'initial_fix_approximate') {
                _platformStatus = _awaitingInitialFix
                    ? 'awaiting_initial_fix'
                    : 'tracking';
                _platformError = null;
                notifyListeners();
              }
              return;
            }
            if (pendingStart != null && !_nativeTracking) {
              final backgroundOnlyLoss =
                  pendingStart.allowBackground &&
                  authorization.canTrack &&
                  !authorization.canTrackInBackground;
              _pendingNativeStartAuthorizationRevoked = true;
              _pendingNativeStartErrorCode = backgroundOnlyLoss
                  ? 'trip_tracking_background_location_denied'
                  : 'trip_tracking_location_denied';
              _platformError = TripTrackingNativeErrorPolicy.safeMessage(
                _pendingNativeStartErrorCode,
              );
              notifyListeners();
              return;
            }
            // This handler is already serialized by the platform event queue.
            // Schedule interruption cleanup after it returns so its final
            // queue drain cannot wait on the event currently being processed.
            final backgroundOnlyLoss =
                _backgroundTrackingAllowed &&
                authorization.canTrack &&
                !authorization.canTrackInBackground;
            final pendingStatus = backgroundOnlyLoss
                ? 'background_location_settings_required'
                : 'permission_required';
            _pendingNativeSystemPauseStatus = pendingStatus;
            _deferPlatformCleanup(
              () => _handleNativeSystemPause(
                message: backgroundOnlyLoss
                    ? TripTrackingNativeErrorPolicy.safeMessage(
                        'trip_tracking_background_location_denied',
                      )
                    : TripTrackingNativeErrorPolicy.safeMessage(
                        'trip_tracking_location_denied',
                      ),
                health: TripTrackingHealthState.permissionBlocked,
                platformStatus: pendingStatus,
                source: 'native_authorization_event',
                reasonCode: backgroundOnlyLoss
                    ? 'native_background_permission_revoked_system_pause'
                    : 'native_permission_revoked_system_pause',
              ),
            );
          } else if (event.type == TripTrackingPlatformEventType.status) {
            final status = event.status;
            if (status == 'tracking' && _awaitingInitialFix) {
              await _markExpiredInitialFixPreparation(
                _clockNow().toUtc(),
                deferStopOnStorageFailure: true,
              );
            }
            if (status == 'stopped' || status == 'paused') {
              final pendingSystemPauseStatus = _pendingNativeSystemPauseStatus;
              if (pendingSystemPauseStatus != null) {
                _platformStatus = pendingSystemPauseStatus;
                notifyListeners();
                return;
              }
              if (_pendingNativeStartRequest != null && !_nativeTracking) {
                _pendingNativeStartStopped = true;
                _platformStatus = 'interrupted';
                _platformError =
                    'GPS updates stopped while trip tracking was starting.';
                notifyListeners();
                return;
              }
              final expectedStop =
                  _nativeStopRequested ||
                  _nativeCriticalBatteryStopPending ||
                  status == 'paused';
              _platformStatus = expectedStop ? status : 'interrupted';
              if (!expectedStop) {
                _platformError =
                    'GPS updates stopped unexpectedly. Your local trip is preserved for review.';
              }
              _nativeTracking = false;
              _nativeSampling = null;
              _nativeSamplingPlan = null;
              _lastNativeHeartbeatUtc = null;
              _nativeTrackingStartedAtUtc = null;
              _lastNativeLocationReceivedUtc = null;
              _backgroundTrackingAllowed = false;
              _latestActivity = null;
              await _cancelPlatformSubscriptionAfterNativeStop();
              _platformSubscription = null;
              final activeOrDegraded =
                  _session?.lifecycleState ==
                      TripTrackingSessionLifecycleState.active ||
                  _session?.lifecycleState ==
                      TripTrackingSessionLifecycleState.degraded;
              if (activeOrDegraded) {
                final driverRequestedPause = status == 'paused';
                final engine = _engine;
                final engineBeforeGap = engine?.snapshot;
                engine?.beginSignalGap(
                  _clockNow(),
                  reason: driverRequestedPause
                      ? TripTrackingSignalGapReason.userPause
                      : TripTrackingSignalGapReason.systemPause,
                );
                final transitioned = expectedStop
                    ? await _tryTransitionSession(
                        TripTrackingSessionLifecycleState.paused,
                        pauseKind: driverRequestedPause
                            ? TripTrackingPauseKind.user
                            : TripTrackingPauseKind.system,
                        source: 'native_signal_event',
                        reasonCode: driverRequestedPause
                            ? 'native_notification_pause_requested'
                            : 'native_tracking_stopped',
                      )
                    : await _tryTransitionSession(
                        TripTrackingSessionLifecycleState.interrupted,
                        health: TripTrackingHealthState.interrupted,
                        source: 'native_signal_event',
                        reasonCode: 'native_location_stream_stopped',
                      );
                if (!transitioned &&
                    engine != null &&
                    engineBeforeGap != null) {
                  _engine = TripTrackingEngine.fromSnapshot(
                    engineBeforeGap,
                    policy: engine.policy,
                    profile: engine.profile,
                  );
                }
              }
            } else if (status == 'tracking' && _nativeTracking) {
              final now = _clockNow().toUtc();
              _lastNativeHeartbeatUtc = _nonRegressingNativeHeartbeatTime(now);
              if (_engine?.snapshot.initialFixAssessment?.quality !=
                  TripInitialFixQuality.unavailable) {
                await _markGpsSignalStaleIfNeeded(now);
              }
              if (_platformStatus != 'gps_signal_stale' &&
                  _platformStatus != 'initial_fix_unavailable' &&
                  _platformStatus != 'storage_failed') {
                _platformStatus = status;
              }
            } else if (status == 'idle' && !_nativeTracking) {
              _platformStatus = status;
            } else {
              return;
            }
            notifyListeners();
          } else if (event.type == TripTrackingPlatformEventType.error) {
            if (TripTrackingNativeErrorPolicy.isIgnorableMalformedPayload(
              event.errorCode,
            )) {
              return;
            }
            final message = TripTrackingNativeErrorPolicy.safeMessage(
              event.errorCode,
            );
            _platformError = message;
            if (event.errorCode == 'trip_tracking_battery_critical') {
              _nativeCriticalBatteryStopPending = true;
              _pendingNativeSystemPauseStatus = 'battery_critical_gps_blocked';
              _deferPlatformCleanup(
                () => _handleNativeCriticalBatteryStop(message),
              );
            } else if (event.errorCode ==
                'trip_tracking_activity_unavailable') {
              final pendingStart = _pendingNativeStartRequest;
              final activityAssistanceActive =
                  (_nativeTracking && !_nativeStopRequested) ||
                  (pendingStart?.activityRecognitionEnabled ?? false);
              if (!activityAssistanceActive) {
                notifyListeners();
                return;
              }
              // Walking assistance is optional. A permission revocation or
              // provider failure must retire only that sensor, never GPS,
              // TripLog, or the authoritative odometer workflow.
              _latestActivity = null;
              _activityRecognitionEnabled = false;
              if (pendingStart != null) {
                _pendingNativeStartActivityUnavailable = true;
              }
              final persisted = await _persistNativeCollectionPreferences(
                allowBackground:
                    pendingStart?.allowBackground ?? _backgroundTrackingAllowed,
                activityRecognitionEnabled: false,
              );
              if (!persisted) {
                if (pendingStart != null) {
                  _pendingNativeStartPreferenceSaveFailed = true;
                } else {
                  _platformError =
                      'Motion activity became unavailable, and GPS tracking stopped because that privacy change could not be saved locally.';
                  // This handler is executing inside the platform event queue.
                  // Stopping drains that queue, so schedule it after this event
                  // completes instead of awaiting a self-draining deadlock.
                  _deferPlatformCleanup(() async {
                    await _stopNativeTracking(
                      interrupted: true,
                      interruptionHealth: TripTrackingHealthState.unavailable,
                      interruptionSource: 'native_activity_evidence',
                      interruptionReasonCode:
                          'activity_preference_storage_system_pause',
                    );
                    _platformStatus = 'storage_failed';
                    notifyListeners();
                  });
                }
              }
              notifyListeners();
            } else if (event.errorCode ==
                    'trip_tracking_location_accuracy_reduced' &&
                (_nativeTracking || _pendingNativeStartRequest != null)) {
              // Approximate location remains advisory-only evidence. Preserve
              // the local trip and collector; validation will reject or
              // downgrade coarse samples instead of inventing precise miles.
              _platformStatus = 'initial_fix_approximate';
              _platformError =
                  'Only approximate location is available. GPS assistance will remain low confidence until precise access is restored.';
              notifyListeners();
            } else if (_pendingNativeStartRequest != null &&
                !_nativeTracking &&
                TripTrackingNativeErrorPolicy.requiresRecovery(
                  event.errorCode,
                )) {
              _pendingNativeStartErrorCode ??= event.errorCode;
              notifyListeners();
            } else if (_nativeTracking &&
                TripTrackingNativeErrorPolicy.isAuthorizationLoss(
                  event.errorCode,
                )) {
              final pendingStatus =
                  event.errorCode == 'trip_tracking_background_location_denied'
                  ? 'background_location_settings_required'
                  : 'permission_required';
              _pendingNativeSystemPauseStatus = pendingStatus;
              _deferPlatformCleanup(
                () => _handleNativeSystemPause(
                  message: message,
                  health: TripTrackingHealthState.permissionBlocked,
                  platformStatus: pendingStatus,
                  source: 'native_authorization_error',
                  reasonCode:
                      event.errorCode ==
                          'trip_tracking_background_location_denied'
                      ? 'native_background_permission_revoked_system_pause'
                      : event.errorCode ==
                            'trip_tracking_foreground_service_denied'
                      ? 'native_foreground_service_permission_failed_system_pause'
                      : 'native_permission_revoked_system_pause',
                ),
              );
            } else if (_nativeTracking &&
                TripTrackingNativeErrorPolicy.isLocationServicesLoss(
                  event.errorCode,
                )) {
              _pendingNativeSystemPauseStatus = 'location_services_required';
              _deferPlatformCleanup(
                () => _handleNativeSystemPause(
                  message: message,
                  health: TripTrackingHealthState.unavailable,
                  platformStatus: 'location_services_required',
                  source: 'native_location_services_event',
                  reasonCode: 'native_location_services_system_pause',
                ),
              );
            } else if (_nativeTracking &&
                TripTrackingNativeErrorPolicy.requiresRecovery(
                  event.errorCode,
                )) {
              _deferPlatformCleanup(() => _handleNativeInterruption(message));
            } else {
              notifyListeners();
            }
          }
        })
        .catchError((Object error, StackTrace _) {
          if (_isDisposed) return;
          const safeMessage = 'GPS event could not be processed safely.';
          _platformStatus = 'native_event_processing_failed';
          _platformError = safeMessage;
          if (_nativeTracking) {
            _deferPlatformCleanup(() async {
              await _stopNativeTracking(
                interrupted: true,
                interruptionHealth: TripTrackingHealthState.unavailable,
                interruptionSource: 'native_event_processing',
                interruptionReasonCode: 'native_event_processing_system_pause',
              );
              _platformStatus = 'native_event_processing_failed';
              _platformError = safeMessage;
              notifyListeners();
            });
          } else {
            notifyListeners();
          }
        });
  }

  Future<void> _maybePersistRoutePoint(
    TripLocationSample sample,
    TripSampleDecision? decision,
  ) async {
    if (decision?.accepted != true) return;
    final store = _routePointStore;
    final settingsProvider = _routeSettings;
    final dayKeyProvider = _localRouteDayKey;
    final session = _session;
    if (store == null ||
        settingsProvider == null ||
        dayKeyProvider == null ||
        session == null) {
      return;
    }
    final settings = settingsProvider();
    final lastSavedAt = _lastRoutePointPersistedAtUtc;
    final sampleAt = sample.recordedAt.toUtc();
    if (lastSavedAt != null &&
        sampleAt.difference(lastSavedAt) <
            Duration(seconds: settings.mapRouteHistorySampleIntervalSeconds)) {
      return;
    }
    try {
      final result = await store.persist(
        payload: {
          'schemaVersion': 1,
          'tripId': session.id,
          'source': 'gps',
          'sequence': store.nextSequenceForTrip(session.id),
          'recordedAt': sampleAt.toIso8601String(),
          'latitude': sample.latitude,
          'longitude': sample.longitude,
          'horizontalAccuracyMeters': sample.horizontalAccuracyMeters,
        },
        expectedTripId: session.id,
        localDayKey: dayKeyProvider(sampleAt),
        nowUtc: _clockNow().toUtc(),
        settings: settings,
      );
      _routeStorageStatus = result.reasonCode;
      if (result.saved) _lastRoutePointPersistedAtUtc = sampleAt;
    } catch (_) {
      _routeStorageStatus = 'route_storage_failed_gps_continues';
    }
  }

  Future<bool> _persistNativeActivityEvidence(
    TripActivityObservation activity,
  ) async {
    final session = _session;
    final engine = _engine;
    if (session == null || engine == null) return false;
    final activityAt = activity.recordedAt.toUtc();
    if (activityAt.isBefore(session.startedAt.toUtc()) ||
        activityAt.isAfter(
          _clockNow().toUtc().add(engine.policy.maximumFutureSampleSkew),
        )) {
      return false;
    }
    final previousSnapshot = engine.snapshot;
    if (!engine.recordActivityEvidence(activity, observedAt: activityAt)) {
      return false;
    }
    final updatedAt = activityAt.isAfter(session.updatedAt.toUtc())
        ? activityAt
        : session.updatedAt;
    final updatedSession = session.copyWith(
      updatedAt: updatedAt,
      revision: session.revision + 1,
      engineSnapshot: engine.snapshot,
    );
    try {
      await _sessionStore.save(updatedSession);
      _session = updatedSession;
      notifyListeners();
      return true;
    } catch (_) {
      _engine = TripTrackingEngine.fromSnapshot(
        previousSnapshot,
        policy: engine.policy,
        profile: engine.profile,
      );
      // GPS can continue with its last durable checkpoint, but hiding this
      // failure would make walking-stop assistance appear more reliable than
      // it is. Keep the global odometer and TripLog untouched.
      _platformStatus = 'storage_failed';
      _platformError =
          'Could not save GPS activity evidence locally; walking stop assistance is temporarily unavailable.';
      notifyListeners();
      return false;
    }
  }

  void _scheduleRuntimeBatterySafetyCheck() {
    final platform = _platform;
    final capabilities = _lastKnownCapabilities;
    if (!_nativeTracking ||
        platform == null ||
        capabilities?.batteryStateAvailable != true) {
      return;
    }
    final now = _clockNow().toUtc();
    final previous = _lastBatterySafetyCheckUtc;
    if (previous != null &&
        now.difference(previous) < const Duration(minutes: 5)) {
      return;
    }
    _lastBatterySafetyCheckUtc = now;
    // This is deliberately scheduled after the current platform event. A
    // native stop drains that event queue, so stopping inline here could wait
    // on the event currently being processed.
    unawaited(_enqueueNativeLifecycle(_enforceRuntimeBatterySafety));
  }

  Future<void> _enforceRuntimeBatterySafety() async {
    final platform = _platform;
    final capabilities = _lastKnownCapabilities;
    if (!_nativeTracking ||
        platform == null ||
        capabilities?.batteryStateAvailable != true) {
      return;
    }
    TripTrackingBatterySnapshot snapshot;
    try {
      snapshot = await platform.readBatterySnapshot();
    } catch (_) {
      // An unavailable battery bridge must not fabricate a low-battery stop.
      return;
    }
    final decision = _policy.gpsBatteryDecision(
      batteryPercent: snapshot.batteryPercent,
      isCharging: snapshot.isCharging,
      lowPowerModeEnabled:
          capabilities!.lowPowerModeAvailable && snapshot.lowPowerModeEnabled,
      lowBatteryProtectionEnabled: _lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: _lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: _lowBatteryWarningDismissed,
    );
    if (!await _persistBatteryStateSummary(
      TripTrackingBatteryStateSummary(
        observedAt: _clockNow(),
        batteryPercent: snapshot.batteryPercent,
        isCharging: snapshot.isCharging,
        lowPowerModeEnabled: snapshot.lowPowerModeEnabled,
        allowsGps: decision.allowsGps,
        reasonCode: decision.reasonCode,
      ),
    )) {
      await _stopNativeTracking(
        interrupted: true,
        interruptionHealth: TripTrackingHealthState.unavailable,
        interruptionSource: 'runtime_battery_safety',
        interruptionReasonCode: 'runtime_battery_evidence_storage_system_pause',
      );
      _platformStatus = 'storage_failed';
      notifyListeners();
      return;
    }
    if (decision.allowsGps) {
      if (decision.reasonCode == 'battery_low_warning') {
        _platformStatus = 'battery_low_warning';
        _platformError =
            'Battery is below 20%. GPS will ask before continuing at or below 15% unless the device is charging.';
        notifyListeners();
      }
      return;
    }
    _platformStatus = decision.reasonCode;
    _platformError = _gpsBatteryMessageFor(decision);
    await _stopNativeTracking(
      interrupted: true,
      interruptionHealth: TripTrackingHealthState.unavailable,
      interruptionSource: 'runtime_battery_safety',
      interruptionReasonCode:
          decision.reasonCode == 'battery_critical_gps_blocked'
          ? 'native_critical_battery_system_pause'
          : 'runtime_battery_policy_system_pause',
    );
    // Stopping the optional collector must not erase the actionable reason.
    // The local TripLog remains active and the user can make a new explicit
    // decision after charging or changing the GPS battery preference.
    _platformStatus = decision.reasonCode;
    notifyListeners();
  }

  /// A native collector can enforce the critical cutoff while Dart is asleep.
  /// Keep that distinct, actionable state instead of presenting a generic GPS
  /// failure; local work and odometer truth remain intact.
  Future<void> _handleNativeCriticalBatteryStop(String message) async {
    if (_isDisposed) return;
    try {
      await _stopNativeTracking(
        interrupted: true,
        interruptionHealth: TripTrackingHealthState.unavailable,
        interruptionSource: 'native_battery_safety',
        interruptionReasonCode: 'native_critical_battery_system_pause',
      );
      _platformStatus = 'battery_critical_gps_blocked';
      _platformError = message;
      notifyListeners();
    } finally {
      _pendingNativeSystemPauseStatus = null;
    }
  }

  Future<void> _cancelPlatformSubscriptionAfterNativeStop() async {
    final subscription = _platformSubscription;
    if (subscription == null) return;
    try {
      await subscription.cancel();
    } catch (error) {
      _platformError ??= 'Could not detach GPS event listener cleanly.';
    }
  }

  Future<void> _markGpsSignalStaleIfNeeded(DateTime nowUtc) async {
    final session = _session;
    final lastEvidence =
        _lastNativeLocationReceivedUtc ?? _nativeTrackingStartedAtUtc;
    if (session == null || lastEvidence == null) return;
    if (nowUtc.difference(lastEvidence) <= _policy.maximumGap) return;
    _platformStatus = 'gps_signal_stale';
    _platformError =
        'GPS has not produced a location fix recently. Your local trip is preserved while signal recovers.';
    if (session.lifecycleState == TripTrackingSessionLifecycleState.active) {
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.degraded,
        health: TripTrackingHealthState.reduced,
        source: 'native_signal_stale',
        reasonCode: 'native_gps_signal_gap',
      );
    }
  }

  Future<void> _maybeUpdateNativeSampling(
    TripLocationSample sample,
    TripSampleDecision? decision,
  ) async {
    final platform = _platform;
    final session = _session;
    final current = _nativeSampling;
    final candidate = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: _policy,
      profile: session?.profile ?? TripTrackingProfile.roadVehicle,
      sample: sample,
      decision: decision,
      current: current,
      adaptiveSamplingEnabled: _adaptiveSamplingEnabled,
      nativeTracking: _nativeTracking,
      platformAvailable: platform != null,
      sessionAvailable: session != null,
    );
    if (platform == null || session == null || candidate == null) {
      return;
    }
    final next = _nativeSamplingPlan?.constrainAdaptive(candidate) ?? candidate;
    if (TripTrackingNativeSamplingPolicy.isSameRecommendation(current, next)) {
      return;
    }
    bool updated;
    try {
      updated = await platform.update(
        TripTrackingNativeRequest(
          profile: session.profile,
          sampling: next,
          allowBackground: _backgroundTrackingAllowed,
          activityRecognitionEnabled: _activityRecognitionEnabled,
        ),
      );
    } catch (error) {
      final message = _safeNativeCommandFailure(
        error,
        fallback: 'Could not update GPS sampling.',
      );
      final errorCode = error is PlatformException ? error.code : null;
      if (TripTrackingNativeErrorPolicy.isAuthorizationLoss(errorCode)) {
        final pendingStatus =
            errorCode == 'trip_tracking_background_location_denied'
            ? 'background_location_settings_required'
            : 'permission_required';
        _platformError = message;
        _platformStatus = pendingStatus;
        _pendingNativeSystemPauseStatus = pendingStatus;
        notifyListeners();
        _deferPlatformCleanup(
          () => _handleNativeSystemPause(
            message: message,
            health: TripTrackingHealthState.permissionBlocked,
            platformStatus: pendingStatus,
            source: 'native_sampling_update',
            reasonCode: errorCode == 'trip_tracking_background_location_denied'
                ? 'native_sampling_update_background_permission_revoked'
                : errorCode == 'trip_tracking_foreground_service_denied'
                ? 'native_sampling_update_foreground_service_permission_failed'
                : 'native_sampling_update_permission_revoked',
          ),
        );
        return;
      }
      if (TripTrackingNativeErrorPolicy.isLocationServicesLoss(errorCode)) {
        _platformError = message;
        _platformStatus = 'location_services_required';
        _pendingNativeSystemPauseStatus = 'location_services_required';
        notifyListeners();
        _deferPlatformCleanup(
          () => _handleNativeSystemPause(
            message: message,
            health: TripTrackingHealthState.unavailable,
            platformStatus: 'location_services_required',
            source: 'native_sampling_update',
            reasonCode: 'native_sampling_update_location_services_lost',
          ),
        );
        return;
      }
      _platformError = message;
      notifyListeners();
      return;
    }
    if (updated) {
      _nativeSampling = next;
      await _persistNativeCollectionPreferences(
        allowBackground: _backgroundTrackingAllowed,
        activityRecognitionEnabled: _activityRecognitionEnabled,
        nativeSampling: next,
      );
    } else {
      _platformError =
          'The device could not apply the updated GPS sampling mode.';
      notifyListeners();
    }
  }
}
