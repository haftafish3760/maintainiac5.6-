part of 'trip_tracking_controller.dart';

/// Starts native location collection after policy, capability, and local
/// recovery safeguards have approved the request.
extension TripTrackingControllerNativeCollection on TripTrackingController {
  Future<bool> openBackgroundLocationSettings() async {
    final platform = _platform;
    if (_isDisposed ||
        platform == null ||
        platform is! TripTrackingNativeSettingsGateway) {
      return false;
    }
    try {
      return await (platform as TripTrackingNativeSettingsGateway)
          .openBackgroundLocationSettings();
    } catch (_) {
      return false;
    }
  }

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
      source: 'native_start',
      reasonCode: 'native_start_request',
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
        source: 'native_start',
        reasonCode: 'native_capabilities_read_failed',
      );
      notifyListeners();
      return false;
    }
    if (!capabilities.locationAvailable) {
      _platformError = 'Device location is unavailable.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.permissionRequired,
        contractState: TripTrackingSessionLifecycleContractState
            .AWAITING_LOCATION_SERVICES,
        health: TripTrackingHealthState.unavailable,
        source: 'native_start',
        reasonCode: 'native_location_unavailable',
      );
      notifyListeners();
      return false;
    }
    if (allowBackground && !capabilities.backgroundTrackingAvailable) {
      _platformError = 'Background GPS tracking is unavailable on this device.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
        source: 'native_start',
        reasonCode: 'native_background_unavailable',
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
    if (!await _persistBatteryStateSummary(
      TripTrackingBatteryStateSummary(
        observedAt: _clockNow(),
        batteryPercent: batterySnapshot.batteryPercent,
        isCharging: batterySnapshot.isCharging,
        lowPowerModeEnabled: batterySnapshot.lowPowerModeEnabled,
        allowsGps: batteryDecision.allowsGps,
        reasonCode: batteryDecision.reasonCode,
      ),
    )) {
      return false;
    }
    if (!batteryDecision.allowsGps) {
      _platformStatus = batteryDecision.reasonCode;
      _platformError = _gpsBatteryMessageFor(batteryDecision);
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.failedRecoverable,
        health: TripTrackingHealthState.unavailable,
        source: 'native_start',
        reasonCode: 'battery_protection_triggered',
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
        source: 'native_start',
        reasonCode: 'native_permission_request_failed',
      );
      notifyListeners();
      return false;
    }
    if (!await _persistPermissionEvidence(
      authorization,
      source: 'native_start',
    )) {
      return false;
    }
    if (!authorization.canTrack ||
        (allowBackground && !authorization.canTrackInBackground)) {
      final backgroundSettingsRequired =
          allowBackground &&
          authorization.canTrack &&
          !authorization.canTrackInBackground;
      if (backgroundSettingsRequired) {
        _platformStatus = 'background_location_settings_required';
      }
      _platformError = allowBackground
          ? 'Background location permission is required for this tracking mode.'
          : 'Location permission is required to start trip tracking.';
      await _tryTransitionSession(
        TripTrackingSessionLifecycleState.permissionRequired,
        health: TripTrackingHealthState.permissionBlocked,
        source: 'native_start',
        reasonCode: 'native_permission_denied',
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
        source: 'native_start',
        reasonCode: 'native_preferences_persist_failed',
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
    _pendingNativeStartErrorCode = null;
    _platformSubscription = _listenToPlatformEvents(platform);
    bool started;
    try {
      started = await platform.start(request);
    } catch (error) {
      final errorCode = error is PlatformException ? error.code : null;
      // Current native adapters continue with approximate-only evidence, but
      // older adapters can still reject startup with this legacy code. Since
      // no collector started, preserve an actionable permission recovery
      // state rather than treating it like an active-session precision event.
      final legacyPrecisionStartFailure =
          errorCode == 'trip_tracking_location_accuracy_reduced';
      final authorizationFailure =
          legacyPrecisionStartFailure ||
          TripTrackingNativeErrorPolicy.isAuthorizationLoss(errorCode);
      final locationServicesFailure =
          TripTrackingNativeErrorPolicy.isLocationServicesLoss(errorCode);
      _clearPendingNativeStart();
      await _platformSubscription?.cancel();
      _platformSubscription = null;
      _platformError = _safeNativeCommandFailure(
        error,
        fallback: 'The device could not start GPS trip tracking.',
      );
      _platformStatus = errorCode == 'trip_tracking_background_location_denied'
          ? 'background_location_settings_required'
          : authorizationFailure
          ? 'permission_required'
          : locationServicesFailure
          ? 'location_services_required'
          : _platformStatus;
      await _tryTransitionSession(
        authorizationFailure || locationServicesFailure
            ? TripTrackingSessionLifecycleState.permissionRequired
            : TripTrackingSessionLifecycleState.failedRecoverable,
        contractState: authorizationFailure
            ? TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION
            : locationServicesFailure
            ? TripTrackingSessionLifecycleContractState
                  .AWAITING_LOCATION_SERVICES
            : null,
        health: authorizationFailure
            ? TripTrackingHealthState.permissionBlocked
            : TripTrackingHealthState.unavailable,
        source: 'native_start',
        reasonCode: authorizationFailure
            ? errorCode == 'trip_tracking_background_location_denied'
                  ? 'native_platform_start_background_permission_failed'
                  : errorCode == 'trip_tracking_foreground_service_denied'
                  ? 'native_platform_start_foreground_service_permission_failed'
                  : 'native_platform_start_authorization_failed'
            : locationServicesFailure
            ? 'native_platform_start_location_services_failed'
            : 'native_platform_start_failed',
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
    final nativeErrorDuringStart = _pendingNativeStartErrorCode;
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
        source: 'native_start',
        reasonCode: 'native_battery_critical_stop',
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
        source: 'native_start',
        reasonCode: 'native_not_started',
      );
      notifyListeners();
      return false;
    }
    if (preferenceSaveFailedDuringStart ||
        nativeStoppedDuringStart ||
        authorizationRevokedDuringStart ||
        nativeErrorDuringStart != null) {
      final authorizationFailedDuringStart =
          authorizationRevokedDuringStart ||
          TripTrackingNativeErrorPolicy.isAuthorizationLoss(
            nativeErrorDuringStart,
          );
      final locationServicesFailedDuringStart =
          TripTrackingNativeErrorPolicy.isLocationServicesLoss(
            nativeErrorDuringStart,
          );
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
          : authorizationFailedDuringStart
          ? TripTrackingNativeErrorPolicy.safeMessage(nativeErrorDuringStart)
          : nativeErrorDuringStart != null
          ? TripTrackingNativeErrorPolicy.safeMessage(nativeErrorDuringStart)
          : 'GPS updates stopped while trip tracking was starting.';
      _platformStatus = authorizationFailedDuringStart
          ? nativeErrorDuringStart == 'trip_tracking_background_location_denied'
                ? 'background_location_settings_required'
                : 'permission_required'
          : locationServicesFailedDuringStart
          ? 'location_services_required'
          : _platformStatus;
      final startFailureReason = authorizationFailedDuringStart
          ? nativeErrorDuringStart == 'trip_tracking_background_location_denied'
                ? 'native_background_permission_revoked_during_start'
                : nativeErrorDuringStart ==
                      'trip_tracking_foreground_service_denied'
                ? 'native_foreground_service_permission_failed_during_start'
                : 'native_permission_revoked_during_start'
          : locationServicesFailedDuringStart
          ? 'native_location_services_lost_during_start'
          : nativeErrorDuringStart != null
          ? 'native_platform_error_during_start'
          : preferenceSaveFailedDuringStart
          ? 'native_collection_preference_failed'
          : 'native_tracking_stopped_during_start';
      await _tryTransitionSession(
        authorizationFailedDuringStart
            ? TripTrackingSessionLifecycleState.permissionRequired
            : locationServicesFailedDuringStart
            ? TripTrackingSessionLifecycleState.permissionRequired
            : TripTrackingSessionLifecycleState.failedRecoverable,
        contractState: authorizationFailedDuringStart
            ? TripTrackingSessionLifecycleContractState.AWAITING_PERMISSION
            : locationServicesFailedDuringStart
            ? TripTrackingSessionLifecycleContractState
                  .AWAITING_LOCATION_SERVICES
            : null,
        health: authorizationFailedDuringStart
            ? TripTrackingHealthState.permissionBlocked
            : TripTrackingHealthState.unavailable,
        source: 'native_start',
        reasonCode: startFailureReason,
      );
      notifyListeners();
      return false;
    }
    _nativeTracking = true;
    _awaitingInitialFix = true;
    _engine?.recordInitialFixAssessment(null);
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
      source: 'native_start',
      reasonCode: 'native_tracking_started',
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
