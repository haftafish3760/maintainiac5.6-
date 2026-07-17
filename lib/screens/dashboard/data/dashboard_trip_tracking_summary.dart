import '../../../shared/storage/app_storage_guard.dart';
import '../../../shared/trip_tracking/trip_tracking_capability_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../../shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import '../../../shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart';
import '../../../shared/trip_tracking/trip_tracking_profile_strategy.dart';
import '../../../shared/trip_tracking/trip_tracking_recovery_policy.dart';
import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../../shared/trip_tracking/trip_tracking_storage_policy.dart';
import '../../../shared/trip_tracking/trip_tracking_sync_policy.dart';
import 'active_workday_store.dart';

part 'dashboard_trip_tracking_summary_sanitizers.dart';

class DashboardTripTrackingSummary {
  const DashboardTripTrackingSummary({
    required this.dashboardMode,
    required this.workStyle,
    required this.stopDetectionMode,
    required this.stopReviewReasonCode,
    required this.recommendedActivityRecognition,
    required this.requiresStrongerStopDebounce,
    required this.recoveryState,
    required this.recoveryReason,
    required this.recoveryUserActionRequired,
    required this.mileageMode,
    required this.syncMode,
    required this.gpsAssistState,
    required this.storageState,
    required this.deviceCapabilityState,
    required this.sensorAssistState,
    required this.odometerCalibrationState,
    required this.odometerCalibrationSamples,
    required this.odometerUsageState,
    required this.odometerUsageReviewedDays,
    required this.dashboardWidgetTokens,
    required this.quickActionTokens,
    required this.freeSyncsRemaining,
    required this.syncsUsedInWindow,
    required this.batteryGpsLimited,
    required this.reviewRequired,
  });

  final String dashboardMode;
  final String workStyle;
  final String stopDetectionMode;
  final String stopReviewReasonCode;
  final bool recommendedActivityRecognition;
  final bool requiresStrongerStopDebounce;
  final String recoveryState;
  final String recoveryReason;
  final bool recoveryUserActionRequired;
  final String mileageMode;
  final String syncMode;
  final String gpsAssistState;
  final String storageState;
  final String deviceCapabilityState;
  final String sensorAssistState;
  final String odometerCalibrationState;
  final int? odometerCalibrationSamples;
  final String odometerUsageState;
  final int? odometerUsageReviewedDays;
  final List<String> dashboardWidgetTokens;
  final List<String> quickActionTokens;
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
    String odometerUsageState = 'disabled',
    int? odometerUsageReviewedDays,
    String recoveryState = 'none',
    String recoveryReason = 'trip_recovery_none',
    bool recoveryUserActionRequired = false,
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
    final strategy = TripTrackingProfileStrategy.forProfile(
      settings.defaultProfile,
    );
    return DashboardTripTrackingSummary(
      dashboardMode: guidance.modeToken,
      workStyle: _safeWorkStyle(strategy.workStyleToken),
      stopDetectionMode: _safeStopDetectionMode(
        strategy.stopDetectionModeToken,
      ),
      stopReviewReasonCode: _safeStopReviewReasonCode(
        strategy.stopReviewReasonCode,
      ),
      recommendedActivityRecognition: strategy.recommendedActivityRecognition,
      requiresStrongerStopDebounce: strategy.requiresStrongerStopDebounce,
      recoveryState: _safeRecoveryState(recoveryState),
      recoveryReason: _safeRecoveryReason(recoveryReason),
      recoveryUserActionRequired: recoveryUserActionRequired,
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
      odometerUsageState: _safeOdometerUsageState(odometerUsageState),
      odometerUsageReviewedDays: _safeCalibrationSamples(
        odometerUsageReviewedDays,
      ),
      dashboardWidgetTokens: _safeDashboardWidgetTokens(
        strategy.dashboardWidgetTokens,
      ),
      quickActionTokens: _safeQuickActionTokens(strategy.quickActionTokens),
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
    final recoveryDecision = tripTracking?.recoveryDecision;
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
    final usageSignal =
        settings.gpsAssistedTrackingEnabled &&
            settings.odometerAnomalyAlertsEnabled &&
            activeWorkday != null
        ? tripTracking?.odometerUsageAnomalySignalForCurrentDay(
            startingOdometer: activeWorkday.startOdometer,
          )
        : null;
    return fromSettings(
      settings: settings,
      nativeTracking: nativeTracking,
      recoverableTrip: activeTrip && !nativeTracking,
      lowBatteryLimited: _isBatteryLimitedStatus(status),
      reviewRequired:
          tripTracking?.latestUnconfirmedReview != null ||
          tripTracking?.needsWalkingReview == true ||
          activeWorkday?.isPaused == true ||
          usageSignal?.shouldPromptUser == true,
      storageState: _storageStateFor(storageCheck),
      deviceCapabilityState: _deviceCapabilityStateFor(capabilityGuidance),
      sensorAssistState: _sensorAssistStateFor(capabilityGuidance),
      odometerCalibrationState: _calibrationStateFor(calibrationSignal),
      odometerCalibrationSamples: calibrationSignal?.eligibleSampleCount,
      odometerUsageState: _usageStateFor(usageSignal),
      odometerUsageReviewedDays: usageSignal?.reviewedDayCount,
      recoveryState: _recoveryStateFor(recoveryDecision),
      recoveryReason: _recoveryReasonFor(recoveryDecision),
      recoveryUserActionRequired: recoveryDecision?.requiresUserAction == true,
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

String _usageStateFor(TripOdometerUsageAnomalySignal? signal) {
  if (signal == null) return 'disabled';
  return switch (signal.status) {
    TripOdometerUsageAnomalyStatus.invalid => 'invalid',
    TripOdometerUsageAnomalyStatus.insufficientHistory =>
      'insufficient_history',
    TripOdometerUsageAnomalyStatus.normal => 'normal',
    TripOdometerUsageAnomalyStatus.reviewRecommended => 'review_recommended',
  };
}

String _storageStateFor(AppStorageCheck? storageCheck) {
  if (storageCheck == null || !storageCheck.canVerify) return 'unknown';
  return TripTrackingStoragePolicy.evaluate(storageCheck).storageState;
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

String _recoveryStateFor(TripTrackingRecoveryDecision? decision) {
  return switch (decision?.status) {
    TripTrackingRecoveryStatus.ready => 'ready',
    TripTrackingRecoveryStatus.pendingReplayReady => 'pending_replay',
    TripTrackingRecoveryStatus.completedReviewPresent => 'completed_review',
    TripTrackingRecoveryStatus.invalidSession => 'invalid_session',
    TripTrackingRecoveryStatus.invalidReviewPresent => 'invalid_review',
    TripTrackingRecoveryStatus.vehicleMismatch => 'vehicle_mismatch',
    TripTrackingRecoveryStatus.odometerMismatch => 'odometer_mismatch',
    TripTrackingRecoveryStatus.odometerProjectionInvalid =>
      'projection_invalid',
    TripTrackingRecoveryStatus.noRecoverableTrip || null => 'none',
  };
}

String _recoveryReasonFor(TripTrackingRecoveryDecision? decision) {
  return _safeRecoveryReason(decision?.safeReason ?? 'trip_recovery_none');
}
