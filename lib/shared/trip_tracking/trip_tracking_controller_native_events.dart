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
        ? 'Battery is below the GPS safety threshold. Choose whether to continue GPS below 20% battery.'
        : 'GPS tracking is blocked below 20% battery by your saved battery setting.';
  }

  StreamSubscription<TripTrackingPlatformEvent> _listenToPlatformEvents(
    TripTrackingNativeGateway platform,
  ) => platform.events.listen(
    _enqueuePlatformEvent,
    onError: (Object error) {
      if (!_nativeTracking) return;
      unawaited(_handleNativeInterruption('GPS updates stopped unexpectedly.'));
    },
    onDone: () {
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
        );
      }
      notifyListeners();
      await _stopNativeTracking(interrupted: true);
    } finally {
      _nativeInterruptionPending = false;
    }
  }

  void _enqueuePlatformEvent(TripTrackingPlatformEvent event) {
    _platformEventQueue = _platformEventQueue
        .then((_) async {
          if (_isDisposed) return;
          if (event.type == TripTrackingPlatformEventType.location &&
              event.location != null) {
            if (!_nativeTracking) return;
            // A received provider event is a runtime heartbeat. Deliberately
            // use receive time, not the untrusted payload timestamp.
            _lastNativeHeartbeatUtc = _clockNow().toUtc();
            _lastNativeLocationReceivedUtc = _lastNativeHeartbeatUtc;
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
            _latestActivity = event.activity;
          } else if (event.type ==
                  TripTrackingPlatformEventType.authorization &&
              event.authorization != null) {
            final pendingStart = _pendingNativeStartRequest;
            if (!_nativeTracking && pendingStart == null) return;
            final authorization = event.authorization!;
            final authorizationStillAllowsTracking =
                authorization.canTrackPrecisely &&
                (!(_nativeTracking
                        ? _backgroundTrackingAllowed
                        : pendingStart!.allowBackground) ||
                    authorization.canTrackInBackground);
            if (authorizationStillAllowsTracking) return;
            if (pendingStart != null && !_nativeTracking) {
              _pendingNativeStartAuthorizationRevoked = true;
              _platformError = pendingStart.allowBackground
                  ? 'Background location permission was removed while trip tracking was starting.'
                  : 'Precise location permission was removed while trip tracking was starting.';
              notifyListeners();
              return;
            }
            // This handler is already serialized by the platform event queue.
            // Schedule interruption cleanup after it returns so its final
            // queue drain cannot wait on the event currently being processed.
            _deferPlatformCleanup(
              () => _handleNativeInterruption(
                _backgroundTrackingAllowed
                    ? 'Background location permission was removed while tracking.'
                    : 'Precise location permission was removed while tracking.',
              ),
            );
          } else if (event.type == TripTrackingPlatformEventType.status) {
            final status = event.status;
            if (status == 'stopped' || status == 'paused') {
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
              if (!expectedStop &&
                  (_session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.active ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.degraded)) {
                await _tryTransitionSession(
                  TripTrackingSessionLifecycleState.interrupted,
                  health: TripTrackingHealthState.interrupted,
                );
              } else if (expectedStop &&
                  (_session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.active ||
                      _session?.lifecycleState ==
                          TripTrackingSessionLifecycleState.degraded)) {
                await _tryTransitionSession(
                  TripTrackingSessionLifecycleState.paused,
                );
              }
            } else if (status == 'tracking' && _nativeTracking) {
              final now = _clockNow().toUtc();
              _lastNativeHeartbeatUtc = now;
              await _markGpsSignalStaleIfNeeded(now);
              if (_platformStatus != 'gps_signal_stale') {
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
              unawaited(_handleNativeCriticalBatteryStop(message));
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
                  _deferPlatformCleanup(_stopNativeTracking);
                }
              }
              notifyListeners();
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
          _platformError = 'GPS event could not be processed safely.';
          notifyListeners();
        });
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
    if (decision.allowsGps) return;
    _platformStatus = decision.reasonCode;
    _platformError = _gpsBatteryMessageFor(decision);
    await _stopNativeTracking();
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
    await _stopNativeTracking();
    _platformStatus = 'battery_critical_gps_blocked';
    _platformError = message;
    notifyListeners();
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
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'Could not update GPS sampling.',
      );
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
