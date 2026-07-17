import '../../../shared/storage/app_storage_guard.dart';
import '../../../shared/trip_tracking/trip_tracking_capability_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../../shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../../shared/trip_tracking/trip_tracking_sync_policy.dart';
import 'active_workday_store.dart';

class DashboardTripTrackingSummary {
  const DashboardTripTrackingSummary({
    required this.dashboardMode,
    required this.mileageMode,
    required this.syncMode,
    required this.gpsAssistState,
    required this.storageState,
    required this.deviceCapabilityState,
    required this.sensorAssistState,
    required this.odometerCalibrationState,
    required this.odometerCalibrationSamples,
    required this.freeSyncsRemaining,
    required this.syncsUsedInWindow,
    required this.batteryGpsLimited,
    required this.reviewRequired,
  });

  final String dashboardMode;
  final String mileageMode;
  final String syncMode;
  final String gpsAssistState;
  final String storageState;
  final String deviceCapabilityState;
  final String sensorAssistState;
  final String odometerCalibrationState;
  final int? odometerCalibrationSamples;
  final int? freeSyncsRemaining;
  final int? syncsUsedInWindow;
  final bool batteryGpsLimited;
  final bool reviewRequired;

  bool get hasVerifiedSyncCounters =>
      freeSyncsRemaining != null && syncsUsedInWindow != null;

  static DashboardTripTrackingSummary fromSettings({
    required TripTrackingSettings settings,
    bool nativeTracking = false,
    bool recoverableTrip = false,
    bool lowBatteryLimited = false,
    bool reviewRequired = false,
    String storageState = 'unknown',
    String deviceCapabilityState = 'unknown',
    String sensorAssistState = 'unknown',
    String odometerCalibrationState = 'disabled',
    int? odometerCalibrationSamples,
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    int? syncsUsedInWindow,
  }) {
    final guidance = TripTrackingDashboardGuidance.fromSettingsWithSyncContext(
      settings,
      wifiAvailable: wifiAvailable,
      mobileDataAvailable: mobileDataAvailable,
      syncsUsedInWindow: syncsUsedInWindow,
    );
    final syncDecision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: settings.backupNetworkPolicy,
      wifiAvailable: wifiAvailable,
      mobileDataAvailable: mobileDataAvailable,
      syncsUsedInWindow: syncsUsedInWindow,
    );
    final safeSyncsUsed = syncsUsedInWindow == null || syncsUsedInWindow < 0
        ? null
        : syncsUsedInWindow;
    return DashboardTripTrackingSummary(
      dashboardMode: guidance.modeToken,
      mileageMode: settings.gpsAssistedTrackingEnabled
          ? 'gps_assisted'
          : 'manual',
      syncMode: _syncMode(settings.backupNetworkPolicy),
      gpsAssistState: _gpsAssistState(
        enabled: settings.gpsAssistedTrackingEnabled,
        nativeTracking: nativeTracking,
        recoverableTrip: recoverableTrip,
        lowBatteryLimited: lowBatteryLimited,
      ),
      storageState: _safeStorageState(storageState),
      deviceCapabilityState: _safeDeviceCapabilityState(deviceCapabilityState),
      sensorAssistState: _safeSensorAssistState(sensorAssistState),
      odometerCalibrationState: _safeOdometerCalibrationState(
        odometerCalibrationState,
      ),
      odometerCalibrationSamples: _safeCalibrationSamples(
        odometerCalibrationSamples,
      ),
      freeSyncsRemaining: safeSyncsUsed == null
          ? null
          : syncDecision.freeSyncsRemaining,
      syncsUsedInWindow: safeSyncsUsed,
      batteryGpsLimited: lowBatteryLimited,
      reviewRequired: reviewRequired,
    );
  }

  static DashboardTripTrackingSummary fromRuntime({
    required TripTrackingSettings settings,
    TripTrackingController? tripTracking,
    ActiveWorkdaySessionRecord? activeWorkday,
    AppStorageCheck? storageCheck,
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    int? syncsUsedInWindow,
    String? platformStatus,
  }) {
    final status = platformStatus ?? tripTracking?.platformStatus;
    final activeTrip = tripTracking?.isTracking == true;
    final nativeTracking = tripTracking?.nativeTracking == true;
    final capabilityGuidance = tripTracking?.lastKnownCapabilities == null
        ? null
        : TripTrackingCapabilityGuidance.fromCapabilities(
            capabilities: tripTracking!.lastKnownCapabilities!,
            settings: settings,
          );
    final calibrationSignal =
        settings.gpsAssistedTrackingEnabled &&
            settings.odometerAnomalyAlertsEnabled
        ? tripTracking?.odometerCalibrationSignal()
        : null;
    return fromSettings(
      settings: settings,
      nativeTracking: nativeTracking,
      recoverableTrip: activeTrip && !nativeTracking,
      lowBatteryLimited: _isBatteryLimitedStatus(status),
      reviewRequired:
          tripTracking?.latestUnconfirmedReview != null ||
          tripTracking?.needsWalkingReview == true ||
          activeWorkday?.isPaused == true,
      storageState: _storageStateFor(storageCheck),
      deviceCapabilityState: _deviceCapabilityStateFor(capabilityGuidance),
      sensorAssistState: _sensorAssistStateFor(capabilityGuidance),
      odometerCalibrationState: _calibrationStateFor(calibrationSignal),
      odometerCalibrationSamples: calibrationSignal?.eligibleSampleCount,
      wifiAvailable: wifiAvailable,
      mobileDataAvailable: mobileDataAvailable,
      syncsUsedInWindow: syncsUsedInWindow,
    );
  }
}

String _syncMode(TripTrackingBackupNetworkPolicy policy) {
  return switch (policy) {
    TripTrackingBackupNetworkPolicy.wifiOnly => 'wifi_only',
    TripTrackingBackupNetworkPolicy.wifiAndMobileData => 'wifi_and_mobile',
    TripTrackingBackupNetworkPolicy.mobileDataOnly => 'mobile_only',
  };
}

String _gpsAssistState({
  required bool enabled,
  required bool nativeTracking,
  required bool recoverableTrip,
  required bool lowBatteryLimited,
}) {
  if (!enabled) return 'off';
  if (lowBatteryLimited) return 'battery_limited';
  if (nativeTracking) return 'on';
  if (recoverableTrip) return 'gps_assisted';
  return 'gps_assisted';
}

String _safeStorageState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'text_record_safe' => 'text_record_safe',
    'low_storage' => 'low_storage',
    'blocked' => 'blocked',
    _ => 'unknown',
  };
}

String _safeDeviceCapabilityState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'unavailable' => 'unavailable',
    'location_only' => 'location_only',
    'foreground_ready' => 'foreground_ready',
    'background_ready' => 'background_ready',
    'motion_ready' => 'motion_ready',
    'full_safety_assist' => 'full_safety_assist',
    _ => 'unknown',
  };
}

String _safeSensorAssistState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'no_assist' => 'no_assist',
    'battery_available' => 'battery_available',
    'motion_available' => 'motion_available',
    'motion_battery_available' => 'motion_battery_available',
    _ => 'unknown',
  };
}

String _safeOdometerCalibrationState(String value) {
  return switch (value.trim()) {
    'unknown' => 'unknown',
    'disabled' => 'disabled',
    'insufficient_history' => 'insufficient_history',
    'stable' => 'stable',
    'review_recommended' => 'review_recommended',
    'invalid' => 'invalid',
    _ => 'unknown',
  };
}

int? _safeCalibrationSamples(int? value) {
  if (value == null || value < 0) return null;
  return value > 999 ? 999 : value;
}

String _deviceCapabilityStateFor(
  TripTrackingCapabilityGuidance? capabilityGuidance,
) {
  if (capabilityGuidance == null) return 'unknown';
  return switch (capabilityGuidance.readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'unavailable',
    TripTrackingCapabilityReadiness.locationOnly => 'location_only',
    TripTrackingCapabilityReadiness.foregroundReady => 'foreground_ready',
    TripTrackingCapabilityReadiness.backgroundReady => 'background_ready',
    TripTrackingCapabilityReadiness.motionReady => 'motion_ready',
    TripTrackingCapabilityReadiness.fullSafetyAssist => 'full_safety_assist',
  };
}

String _sensorAssistStateFor(
  TripTrackingCapabilityGuidance? capabilityGuidance,
) {
  if (capabilityGuidance == null) return 'unknown';
  final motion = capabilityGuidance.canUseActivityRecognition;
  final battery =
      capabilityGuidance.canUseBatteryGuard ||
      capabilityGuidance.canUseLowPowerGuard;
  if (motion && battery) return 'motion_battery_available';
  if (motion) return 'motion_available';
  if (battery) return 'battery_available';
  return 'no_assist';
}

String _calibrationStateFor(TripOdometerCalibrationSignal? signal) {
  if (signal == null) return 'disabled';
  if (signal.reasonCode == 'invalid_calibration_threshold') return 'invalid';
  return switch (signal.status) {
    TripOdometerCalibrationStatus.insufficientHistory => 'insufficient_history',
    TripOdometerCalibrationStatus.stable => 'stable',
    TripOdometerCalibrationStatus.reviewRecommended => 'review_recommended',
  };
}

String _storageStateFor(AppStorageCheck? storageCheck) {
  if (storageCheck == null || !storageCheck.canVerify) return 'unknown';
  if (!storageCheck.hasEnoughSpace) return 'blocked';
  if (storageCheck.shouldWarnLowStorage) return 'low_storage';
  return 'text_record_safe';
}

bool _isBatteryLimitedStatus(String? status) {
  return switch (status) {
    'low_battery_requires_user_choice' ||
    'low_power_mode_requires_user_choice' ||
    'low_battery_gps_blocked_by_saved_choice' ||
    'low_power_mode_gps_blocked_by_saved_choice' => true,
    _ => false,
  };
}
