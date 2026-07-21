part of 'trip_tracking_controller.dart';

/// Starts native location collection after policy, capability, and local
/// recovery safeguards have approved the request.
extension TripTrackingControllerNativeCollection on TripTrackingController {
  Future<bool> startNativeTracking({
    required bool allowBackground,
    double? observedSpeedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingRecommendation? samplingOverride,
    TripTrackingSamplingPreset? samplingPreset,
    int customIntervalSeconds = 15,
    bool activityRecognitionEnabled = false,
    bool adaptiveSamplingEnabled = true,
    bool lowBatteryProtectionEnabled = true,
    bool lowBatteryOverrideEnabled = false,
    bool lowBatteryWarningDismissed = false,
  }) => _enqueueNativeLifecycle(
    () => _startNativeTracking(
      allowBackground: allowBackground,
      observedSpeedMetersPerSecond: observedSpeedMetersPerSecond,
      vehicleMovementConfirmed: vehicleMovementConfirmed,
      samplingOverride: samplingOverride,
      samplingPreset: samplingPreset,
      customIntervalSeconds: customIntervalSeconds,
      activityRecognitionEnabled: activityRecognitionEnabled,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    ),
  );

  Future<bool> _startNativeTracking({
    required bool allowBackground,
    double? observedSpeedMetersPerSecond,
    bool vehicleMovementConfirmed = false,
    TripSamplingRecommendation? samplingOverride,
    TripTrackingSamplingPreset? samplingPreset,
    int customIntervalSeconds = 15,
    bool activityRecognitionEnabled = false,
    bool adaptiveSamplingEnabled = true,
    bool lowBatteryProtectionEnabled = true,
    bool lowBatteryOverrideEnabled = false,
    bool lowBatteryWarningDismissed = false,
  }) async {
    final platform = _platform;
    var session = _session;
    if (_isDisposed || platform == null || session == null || _nativeTracking) {
      return false;
    }
    if (!await _tryTransitionSession(
      TripTrackingSessionLifecycleState.starting,
      health: TripTrackingHealthState.healthy,
    )) {
      return false;
    }
    session = _session;
    if (session == null) return false;
    TripTrackingPlatformCapabilities capabilities;
    _lastKnownCapabilities = null;
    try {
      capabilities = await platform.readCapabilities();
      _lastKnownCapabilities = capabilities;
    } catch (error) {
      _platformError = 'Could not read GPS capabilities.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (!capabilities.locationAvailable) {
      _platformError = 'Device location is unavailable.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (allowBackground && !capabilities.backgroundTrackingAvailable) {
      _platformError = 'Background GPS tracking is unavailable on this device.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    final requestedActivityRecognition =
        activityRecognitionEnabled && capabilities.activityRecognitionAvailable;
    var batterySnapshot = const TripTrackingBatterySnapshot(
      batteryPercent: null,
      isCharging: false,
      lowPowerModeEnabled: false,
    );
    try {
      if (capabilities.batteryStateAvailable) {
        batterySnapshot = await platform.readBatterySnapshot();
      }
    } catch (_) {
      // Battery state is advisory for safety. If the platform cannot provide a
      // trustworthy reading, continue as "unknown" instead of fabricating data.
    }
    final batteryDecision = _policy.gpsBatteryDecision(
      batteryPercent: batterySnapshot.batteryPercent,
      isCharging: batterySnapshot.isCharging,
      lowPowerModeEnabled:
          capabilities.lowPowerModeAvailable &&
          batterySnapshot.lowPowerModeEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    );
    if (!batteryDecision.allowsGps) {
      _platformStatus = batteryDecision.reasonCode;
      _platformError = _gpsBatteryMessageFor(batteryDecision);
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    TripTrackingAuthorization authorization;
    try {
      authorization = await platform.requestAuthorization(
        allowBackground: allowBackground,
        activityRecognitionEnabled: requestedActivityRecognition,
      );
    } catch (error) {
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'Could not request GPS permission.',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.permissionBlocked,
      );
      notifyListeners();
      return false;
    }
    if (!authorization.canTrackPrecisely ||
        (allowBackground && !authorization.canTrackInBackground)) {
      _platformError = allowBackground
          ? 'Background location permission is required for this tracking mode.'
          : 'Precise location permission is required to start trip tracking.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.permissionRequired,
        health: TripTrackingHealthState.permissionBlocked,
      );
      notifyListeners();
      return false;
    }
    final samplingPlan = samplingOverride == null && samplingPreset != null
        ? TripTrackingSamplingPresetPolicy.planFor(
            preset: samplingPreset,
            customIntervalSeconds: customIntervalSeconds,
            capabilities: capabilities,
          )
        : null;
    final request = TripTrackingNativeRequest(
      profile: session.profile,
      sampling:
          samplingOverride ??
          samplingPlan?.sampling ??
          _policy.samplingFor(
            speedMetersPerSecond: observedSpeedMetersPerSecond,
            vehicleMovementConfirmed: vehicleMovementConfirmed,
            profile: session.profile,
            activeTrip: true,
          ),
      activityRecognitionEnabled: requestedActivityRecognition,
      allowBackground: allowBackground,
    );
    if (!await _persistNativeCollectionPreferences(
      allowBackground: allowBackground,
      activityRecognitionEnabled: requestedActivityRecognition,
      nativeSampling: request.sampling,
      samplingCeiling: samplingPlan?.sampling,
      clearSamplingCeiling: samplingPlan == null,
      adaptiveSamplingEnabled: adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: lowBatteryProtectionEnabled,
      lowBatteryOverrideEnabled: lowBatteryOverrideEnabled,
      lowBatteryWarningDismissed: lowBatteryWarningDismissed,
    )) {
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      return false;
    }
    session = _session;
    if (session == null) return false;
    _latestActivity = null;
    _nativeCriticalBatteryStopPending = false;
    _pendingNativeStartRequest = request;
    _pendingNativeStartActivityUnavailable = false;
    _pendingNativeStartPreferenceSaveFailed = false;
    _pendingNativeStartStopped = false;
    _pendingNativeStartAuthorizationRevoked = false;
    _platformSubscription = _listenToPlatformEvents(platform);
    bool started;
    try {
      started = await platform.start(request);
    } catch (error) {
      _clearPendingNativeStart();
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'The device could not start GPS trip tracking.',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    final activityUnavailableDuringStart =
        _pendingNativeStartActivityUnavailable;
    final preferenceSaveFailedDuringStart =
        _pendingNativeStartPreferenceSaveFailed;
    final nativeStoppedDuringStart = _pendingNativeStartStopped;
    final authorizationRevokedDuringStart =
        _pendingNativeStartAuthorizationRevoked;
    _clearPendingNativeStart();
    if (_nativeCriticalBatteryStopPending) {
      await _cancelPlatformSubscriptionAfterNativeStop();
      _platformSubscription = null;
      _platformStatus = 'battery_critical_gps_blocked';
      _platformError = TripTrackingNativeErrorPolicy.safeMessage(
        'trip_tracking_battery_critical',
      );
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (!started) {
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = 'The device did not start GPS trip tracking.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    if (preferenceSaveFailedDuringStart ||
        nativeStoppedDuringStart ||
        authorizationRevokedDuringStart) {
      try {
        await platform.stop();
      } catch (_) {
        // The durable local failure is authoritative; best-effort native
        // cleanup must not replace that actionable error.
      }
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = preferenceSaveFailedDuringStart
          ? 'Motion activity became unavailable, and GPS tracking could not save that privacy change locally.'
          : authorizationRevokedDuringStart
          ? 'Precise location permission was removed while trip tracking was starting.'
          : 'GPS updates stopped while trip tracking was starting.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: authorizationRevokedDuringStart
            ? TripTrackingHealthState.permissionBlocked
            : TripTrackingHealthState.unavailable,
      );
      notifyListeners();
      return false;
    }
    _nativeTracking = true;
    _nativeSampling = request.sampling;
    _nativeSamplingPlan = samplingPlan;
    _lastNativeHeartbeatUtc = _clockNow().toUtc();
    _nativeTrackingStartedAtUtc = _lastNativeHeartbeatUtc;
    _lastNativeLocationReceivedUtc = null;
    _backgroundTrackingAllowed = allowBackground;
    _activityRecognitionEnabled =
        requestedActivityRecognition && !activityUnavailableDuringStart;
    _adaptiveSamplingEnabled = adaptiveSamplingEnabled;
    _lowBatteryProtectionEnabled = lowBatteryProtectionEnabled;
    _lowBatteryOverrideEnabled = lowBatteryOverrideEnabled;
    _lowBatteryWarningDismissed = lowBatteryWarningDismissed;
    _lastBatterySafetyCheckUtc = _clockNow().toUtc();
    _platformError = null;
    _platformStatus = 'tracking';
    if (!await _tryTransitionSession(
      TripTrackingSessionLifecycleState.active,
      health: TripTrackingHealthState.healthy,
    )) {
      try {
        await platform.stop();
      } catch (_) {
        // The local persistence failure is already surfaced. The platform
        // service also has its own cleanup path if this best-effort stop fails.
      }
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _nativeTracking = false;
      _nativeSampling = null;
      _nativeSamplingPlan = null;
      _lastNativeHeartbeatUtc = null;
      _nativeTrackingStartedAtUtc = null;
      _lastNativeLocationReceivedUtc = null;
      _backgroundTrackingAllowed = false;
      return false;
    }
    notifyListeners();
    return true;
  }
}
