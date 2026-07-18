import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';

enum TripBatteryGpsContinuationStatus {
  continueGps,
  promptUser,
  pauseGpsKeepTripAlive,
  pauseForBackgroundPermission,
  blockedInvalidTrip,
}

class TripBatteryGpsContinuationDecision {
  const TripBatteryGpsContinuationDecision({
    required this.status,
    required this.reasonCode,
    required this.shouldContinueGpsSampling,
    required this.shouldPromptUser,
    required this.shouldKeepTripSessionAlive,
    required this.shouldKeepTextTripLogWritable,
    required this.shouldWriteLocalCheckpoint,
    required this.requiresForegroundService,
    required this.requiresBackgroundPermission,
    required this.canRetryWhenForeground,
  });

  final TripBatteryGpsContinuationStatus status;
  final String reasonCode;
  final bool shouldContinueGpsSampling;
  final bool shouldPromptUser;
  final bool shouldKeepTripSessionAlive;
  final bool shouldKeepTextTripLogWritable;
  final bool shouldWriteLocalCheckpoint;
  final bool requiresForegroundService;
  final bool requiresBackgroundPermission;
  final bool canRetryWhenForeground;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'shouldContinueGpsSampling': shouldContinueGpsSampling,
    'shouldPromptUser': shouldPromptUser,
    'shouldKeepTripSessionAlive': shouldKeepTripSessionAlive,
    'shouldKeepTextTripLogWritable': shouldKeepTextTripLogWritable,
    'shouldWriteLocalCheckpoint': shouldWriteLocalCheckpoint,
    'requiresForegroundService': requiresForegroundService,
    'requiresBackgroundPermission': requiresBackgroundPermission,
    'canRetryWhenForeground': canRetryWhenForeground,
    'gpsPauseCanEndTripAutomatically': false,
    'gpsPauseCanDeleteTripRecords': false,
    'gpsPauseCanConfirmMileage': false,
    'gpsPauseCanCreateOfficialStop': false,
    'textTripLogContinuesWithoutGps': shouldKeepTextTripLogWritable,
    'manualOdometerEntryStillAllowed': shouldKeepTextTripLogWritable,
    'lowBatteryPauseIsGpsOnly': true,
    'lowBatteryPauseRequiresLocalCheckpoint': true,
    'backgroundGpsCanResumeAfterUserOverride': true,
    'backgroundGpsRequiresPlatformGrant': true,
    'foregroundLocationDoesNotGrantBackgroundGps': true,
    'backgroundPermissionCanBeAssumed': false,
    'backgroundPermissionCanBeProvidedByFirestore': false,
    'backgroundPermissionCanBeProvidedByMapbox': false,
    'batteryChoiceCanBeChangedInSettings': true,
    'firebaseCanOverrideBatteryChoice': false,
    'cloudFunctionCanOverrideBatteryChoice': false,
    'mapboxCanOverrideBatteryChoice': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'preciseBatteryIncluded': false,
    'rawBatteryPayloadIncluded': false,
    'tokensIncluded': false,
  };
}

class TripBatteryGpsContinuationPolicy {
  const TripBatteryGpsContinuationPolicy._();

  static TripBatteryGpsContinuationDecision evaluate({
    required TripTrackingSessionLifecycleState lifecycle,
    required bool localSessionAvailable,
    required TripGpsBatteryDecision batteryDecision,
    bool appInBackground = false,
    bool foregroundServiceAvailable = true,
    bool backgroundTrackingPermissionGranted = true,
  }) {
    if (!_activeOrRecoverableLifecycle(lifecycle) || !localSessionAvailable) {
      return _decision(
        status: TripBatteryGpsContinuationStatus.blockedInvalidTrip,
        reasonCode: 'invalid_trip_for_battery_gps_continuation',
        shouldContinueGpsSampling: false,
        shouldPromptUser: false,
        shouldKeepTripSessionAlive: false,
        shouldKeepTextTripLogWritable: false,
        shouldWriteLocalCheckpoint: false,
        requiresForegroundService: false,
        requiresBackgroundPermission: false,
        canRetryWhenForeground: false,
      );
    }
    if (appInBackground &&
        (!foregroundServiceAvailable || !backgroundTrackingPermissionGranted)) {
      return _decision(
        status: TripBatteryGpsContinuationStatus.pauseForBackgroundPermission,
        reasonCode: !foregroundServiceAvailable
            ? 'foreground_service_required_for_background_gps'
            : 'background_permission_required_for_background_gps',
        shouldContinueGpsSampling: false,
        shouldPromptUser: false,
        shouldKeepTripSessionAlive: true,
        shouldKeepTextTripLogWritable: true,
        shouldWriteLocalCheckpoint: true,
        requiresForegroundService: !foregroundServiceAvailable,
        requiresBackgroundPermission: !backgroundTrackingPermissionGranted,
        canRetryWhenForeground: true,
      );
    }
    if (batteryDecision.requiresUserChoice) {
      return _decision(
        status: TripBatteryGpsContinuationStatus.promptUser,
        reasonCode: batteryDecision.reasonCode,
        shouldContinueGpsSampling: false,
        shouldPromptUser: true,
        shouldKeepTripSessionAlive: true,
        shouldKeepTextTripLogWritable: true,
        shouldWriteLocalCheckpoint: true,
        requiresForegroundService: appInBackground,
        requiresBackgroundPermission: false,
        canRetryWhenForeground: false,
      );
    }
    if (batteryDecision.isSavedBlock) {
      return _decision(
        status: TripBatteryGpsContinuationStatus.pauseGpsKeepTripAlive,
        reasonCode: batteryDecision.reasonCode,
        shouldContinueGpsSampling: false,
        shouldPromptUser: false,
        shouldKeepTripSessionAlive: true,
        shouldKeepTextTripLogWritable: true,
        shouldWriteLocalCheckpoint: true,
        requiresForegroundService: appInBackground,
        requiresBackgroundPermission: false,
        canRetryWhenForeground: false,
      );
    }
    return _decision(
      status: TripBatteryGpsContinuationStatus.continueGps,
      reasonCode: batteryDecision.reasonCode,
      shouldContinueGpsSampling: batteryDecision.allowsGps,
      shouldPromptUser: false,
      shouldKeepTripSessionAlive: true,
      shouldKeepTextTripLogWritable: true,
      shouldWriteLocalCheckpoint: true,
      requiresForegroundService: appInBackground,
      requiresBackgroundPermission: false,
      canRetryWhenForeground: false,
    );
  }
}

TripBatteryGpsContinuationDecision _decision({
  required TripBatteryGpsContinuationStatus status,
  required String reasonCode,
  required bool shouldContinueGpsSampling,
  required bool shouldPromptUser,
  required bool shouldKeepTripSessionAlive,
  required bool shouldKeepTextTripLogWritable,
  required bool shouldWriteLocalCheckpoint,
  required bool requiresForegroundService,
  required bool requiresBackgroundPermission,
  required bool canRetryWhenForeground,
}) {
  return TripBatteryGpsContinuationDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    shouldContinueGpsSampling: shouldContinueGpsSampling,
    shouldPromptUser: shouldPromptUser,
    shouldKeepTripSessionAlive: shouldKeepTripSessionAlive,
    shouldKeepTextTripLogWritable: shouldKeepTextTripLogWritable,
    shouldWriteLocalCheckpoint: shouldWriteLocalCheckpoint,
    requiresForegroundService: requiresForegroundService,
    requiresBackgroundPermission: requiresBackgroundPermission,
    canRetryWhenForeground: canRetryWhenForeground,
  );
}

bool _activeOrRecoverableLifecycle(
  TripTrackingSessionLifecycleState lifecycle,
) {
  return switch (lifecycle) {
    TripTrackingSessionLifecycleState.starting ||
    TripTrackingSessionLifecycleState.active ||
    TripTrackingSessionLifecycleState.degraded ||
    TripTrackingSessionLifecycleState.interrupted ||
    TripTrackingSessionLifecycleState.recovering ||
    TripTrackingSessionLifecycleState.stopping ||
    TripTrackingSessionLifecycleState.failedRecoverable => true,
    _ => false,
  };
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'battery_protection_disabled' => 'battery_protection_disabled',
    'device_charging' => 'device_charging',
    'user_override_low_battery' => 'user_override_low_battery',
    'user_override_low_power_mode' => 'user_override_low_power_mode',
    'low_battery_requires_user_choice' => 'low_battery_requires_user_choice',
    'low_battery_gps_blocked_by_saved_choice' =>
      'low_battery_gps_blocked_by_saved_choice',
    'low_power_mode_requires_user_choice' =>
      'low_power_mode_requires_user_choice',
    'low_power_mode_gps_blocked_by_saved_choice' =>
      'low_power_mode_gps_blocked_by_saved_choice',
    'battery_above_cutoff' => 'battery_above_cutoff',
    'battery_unknown' => 'battery_unknown',
    'invalid_trip_for_battery_gps_continuation' =>
      'invalid_trip_for_battery_gps_continuation',
    'foreground_service_required_for_background_gps' =>
      'foreground_service_required_for_background_gps',
    'background_permission_required_for_background_gps' =>
      'background_permission_required_for_background_gps',
    _ => 'battery_unknown',
  };
}
