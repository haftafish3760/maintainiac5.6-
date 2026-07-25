// odometerIsGlobalTruth: true.
part of 'trip_tracking_controller.dart';

extension TripTrackingControllerRuntimeSettings on TripTrackingController {
  /// Applies user-controlled collection settings to an already-running
  /// collector. Enabling background or motion access remains deferred until a
  /// separately authorized start; withdrawing either permission applies now.
  Future<bool> applyActiveTrackingSettings(TripTrackingSettings settings) =>
      _enqueueNativeLifecycle(() => _applyActiveTrackingSettings(settings));

  Future<bool> _applyActiveTrackingSettings(
    TripTrackingSettings settings,
  ) async {
    if (_isDisposed || !settings.gpsAssistedTrackingEnabled) return true;
    final platform = _platform;
    final session = _session;
    if (!_nativeTracking || platform == null || session == null) return true;
    final capabilities = _lastKnownCapabilities;
    final plan = TripTrackingSamplingPresetPolicy.planFor(
      preset: settings.samplingPreset,
      customIntervalSeconds: settings.customIntervalSeconds,
      capabilities:
          capabilities ??
          const TripTrackingPlatformCapabilities(
            locationAvailable: true,
            backgroundTrackingAvailable: false,
            activityRecognitionAvailable: false,
          ),
      deviceIntervalFloorSeconds: _deviceLocationIntervalFloorSeconds,
    );
    final desiredSampling = plan.sampling;
    final desiredBackground =
        _backgroundTrackingAllowed && settings.backgroundTrackingEnabled;
    final desiredActivity =
        _activityRecognitionEnabled && settings.activityRecognitionEnabled;
    final nativeChangeRequired =
        !TripTrackingNativeSamplingPolicy.isSameRecommendation(
          _nativeSampling,
          desiredSampling,
        ) ||
        desiredBackground != _backgroundTrackingAllowed ||
        desiredActivity != _activityRecognitionEnabled;
    final preferenceChangeRequired =
        session.adaptiveSamplingEnabled != settings.adaptiveSamplingEnabled ||
        session.lowBatteryProtectionEnabled !=
            settings.lowBatteryGpsProtectionEnabled ||
        session.lowBatteryOverrideEnabled !=
            settings.lowBatteryGpsOverrideEnabled ||
        session.lowBatteryWarningDismissed !=
            settings.lowBatteryGpsWarningDismissed;
    if (!nativeChangeRequired && !preferenceChangeRequired) return true;

    if (nativeChangeRequired) {
      try {
        final updated = await platform.update(
          TripTrackingNativeRequest(
            profile: session.profile,
            sampling: desiredSampling,
            allowBackground: desiredBackground,
            activityRecognitionEnabled: desiredActivity,
          ),
        );
        if (!updated) {
          await _pauseForRuntimeSettingsFailure(
            message:
                'The device could not apply the updated GPS settings. Your trip is preserved for review.',
            health: TripTrackingHealthState.unavailable,
            reasonCode: 'native_runtime_settings_update_rejected',
          );
          return false;
        }
      } catch (error) {
        final errorCode = error is PlatformException ? error.code : null;
        final authorizationLost =
            TripTrackingNativeErrorPolicy.isAuthorizationLoss(errorCode);
        final locationServicesLost =
            TripTrackingNativeErrorPolicy.isLocationServicesLoss(errorCode);
        await _pauseForRuntimeSettingsFailure(
          message: authorizationLost || locationServicesLost
              ? TripTrackingNativeErrorPolicy.safeMessage(errorCode)
              : 'The device could not apply the updated GPS settings. Your trip is preserved for review.',
          health: authorizationLost
              ? TripTrackingHealthState.permissionBlocked
              : TripTrackingHealthState.unavailable,
          reasonCode: authorizationLost
              ? 'native_runtime_settings_permission_lost'
              : locationServicesLost
              ? 'native_runtime_settings_location_services_lost'
              : 'native_runtime_settings_update_failed',
          platformStatus: authorizationLost
              ? 'permission_required'
              : locationServicesLost
              ? 'location_services_required'
              : 'gps_settings_update_failed',
        );
        return false;
      }
    }

    final persisted = await _persistNativeCollectionPreferences(
      allowBackground: desiredBackground,
      activityRecognitionEnabled: desiredActivity,
      nativeSampling: desiredSampling,
      samplingCeiling: desiredSampling,
      adaptiveSamplingEnabled: settings.adaptiveSamplingEnabled,
      lowBatteryProtectionEnabled: settings.lowBatteryGpsProtectionEnabled,
      lowBatteryOverrideEnabled: settings.lowBatteryGpsOverrideEnabled,
      lowBatteryWarningDismissed: settings.lowBatteryGpsWarningDismissed,
      deviceLocationIntervalFloorSeconds:
          _deviceLocationIntervalFloorSeconds,
    );
    if (!persisted) {
      await _pauseForRuntimeSettingsFailure(
        message:
            'Updated GPS settings could not be saved locally. Your trip is preserved for review.',
        health: TripTrackingHealthState.unavailable,
        reasonCode: 'runtime_settings_storage_system_pause',
        platformStatus: 'storage_failed',
      );
      return false;
    }
    _nativeSampling = desiredSampling;
    _nativeSamplingPlan = plan;
    _backgroundTrackingAllowed = desiredBackground;
    _activityRecognitionEnabled = desiredActivity;
    _adaptiveSamplingEnabled = settings.adaptiveSamplingEnabled;
    _lowBatteryProtectionEnabled = settings.lowBatteryGpsProtectionEnabled;
    _lowBatteryOverrideEnabled = settings.lowBatteryGpsOverrideEnabled;
    _lowBatteryWarningDismissed = settings.lowBatteryGpsWarningDismissed;
    _platformStatus = 'tracking';
    _platformError = null;
    notifyListeners();
    await _enforceRuntimeBatterySafety();
    return true;
  }

  Future<void> _pauseForRuntimeSettingsFailure({
    required String message,
    required TripTrackingHealthState health,
    required String reasonCode,
    String platformStatus = 'gps_settings_update_failed',
  }) async {
    await _stopNativeTracking(
      interrupted: true,
      interruptionHealth: health,
      interruptionSource: 'runtime_settings',
      interruptionReasonCode: reasonCode,
    );
    _platformStatus = platformStatus;
    _platformError = message;
    notifyListeners();
  }
}
