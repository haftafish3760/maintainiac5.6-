import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';

enum TripBatteryGpsContinuationStatus {
  continueGps,
  promptUser,
  pauseGpsKeepTripAlive,
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
  });

  final TripBatteryGpsContinuationStatus status;
  final String reasonCode;
  final bool shouldContinueGpsSampling;
  final bool shouldPromptUser;
  final bool shouldKeepTripSessionAlive;
  final bool shouldKeepTextTripLogWritable;
  final bool shouldWriteLocalCheckpoint;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'shouldContinueGpsSampling': shouldContinueGpsSampling,
    'shouldPromptUser': shouldPromptUser,
    'shouldKeepTripSessionAlive': shouldKeepTripSessionAlive,
    'shouldKeepTextTripLogWritable': shouldKeepTextTripLogWritable,
    'shouldWriteLocalCheckpoint': shouldWriteLocalCheckpoint,
    'gpsPauseCanEndTripAutomatically': false,
    'gpsPauseCanDeleteTripRecords': false,
    'gpsPauseCanConfirmMileage': false,
    'gpsPauseCanCreateOfficialStop': false,
    'textTripLogContinuesWithoutGps': shouldKeepTextTripLogWritable,
    'manualOdometerEntryStillAllowed': shouldKeepTextTripLogWritable,
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
}) {
  return TripBatteryGpsContinuationDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    shouldContinueGpsSampling: shouldContinueGpsSampling,
    shouldPromptUser: shouldPromptUser,
    shouldKeepTripSessionAlive: shouldKeepTripSessionAlive,
    shouldKeepTextTripLogWritable: shouldKeepTextTripLogWritable,
    shouldWriteLocalCheckpoint: shouldWriteLocalCheckpoint,
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
    _ => 'battery_unknown',
  };
}
