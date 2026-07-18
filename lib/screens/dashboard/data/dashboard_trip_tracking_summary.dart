import '../../../shared/storage/app_storage_guard.dart';
import '../../../shared/maps/mapbox_trip_assist_policy.dart';
import '../../../shared/trip_tracking/trip_tracking_capability_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_controller.dart';
import '../../../shared/trip_tracking/trip_tracking_dashboard_guidance.dart';
import '../../../shared/trip_tracking/trip_tracking_map_storage_policy.dart';
import '../../../shared/trip_tracking/trip_stop_classification.dart';
import '../../../shared/trip_tracking/trip_tracking_models.dart';
import '../../../shared/trip_tracking/trip_tracking_odometer_reconciliation.dart';
import '../../../shared/trip_tracking/trip_tracking_odometer_usage_anomaly.dart';
import '../../../shared/trip_tracking/trip_tracking_profile_strategy.dart';
import '../../../shared/trip_tracking/trip_tracking_recovery_policy.dart';
import '../../../shared/trip_tracking/trip_tracking_settings_store.dart';
import '../../../shared/trip_tracking/trip_tracking_signal_quality.dart';
import '../../../shared/trip_tracking/trip_tracking_storage_policy.dart';
import '../../../shared/trip_tracking/trip_tracking_sync_policy.dart';
import 'active_workday_store.dart';

part 'dashboard_trip_tracking_summary_sanitizers.dart';
part 'dashboard_trip_tracking_summary_mapbox.dart';
part 'dashboard_trip_tracking_summary_runtime_helpers.dart';

class DashboardTripTrackingSummary {
  const DashboardTripTrackingSummary({
    required this.dashboardMode,
    required this.workStyle,
    required this.stopDetectionMode,
    required this.stopReviewReasonCode,
    required this.stopSignal,
    required this.stopActionToken,
    required this.stopClassificationReason,
    required this.recommendedActivityRecognition,
    required this.requiresStrongerStopDebounce,
    required this.recoveryState,
    required this.recoveryReason,
    required this.recoveryUserActionRequired,
    required this.mileageMode,
    required this.syncMode,
    required this.gpsAssistState,
    required this.gpsSignalQuality,
    required this.gpsSignalReason,
    required this.gpsSignalReviewRequired,
    required this.mapboxAssistState,
    required this.mapboxAssistReason,
    required this.mapboxAssistReviewRequired,
    required this.mapboxTrustedMileageSource,
    required this.mapboxRouteDistanceMiles,
    required this.mapboxRouteDeltaMiles,
    required this.mapPreviewEnabled,
    required this.mapRouteHistorySavingEnabled,
    required this.mapRouteHistoryDailyBudgetMb,
    required this.mapRouteHistorySampleIntervalSeconds,
    required this.mapRouteHistoryState,
    required this.mapRouteHistoryEstimatedSamplesPerDay,
    required this.mapRouteHistoryEstimatedDailyMb,
    required this.storageState,
    required this.deviceCapabilityState,
    required this.sensorAssistState,
    required this.odometerCalibrationState,
    required this.odometerCalibrationSamples,
    required this.odometerCalibrationMultiplier,
    required this.odometerUsageState,
    required this.odometerUsageReviewedDays,
    required this.odometerUsageCurrentMiles,
    required this.odometerUsageAverageDailyMiles,
    required this.odometerUsageReviewThresholdMiles,
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
  final String stopSignal;
  final String stopActionToken;
  final String stopClassificationReason;
  final bool recommendedActivityRecognition;
  final bool requiresStrongerStopDebounce;
  final String recoveryState;
  final String recoveryReason;
  final bool recoveryUserActionRequired;
  final String mileageMode;
  final String syncMode;
  final String gpsAssistState;
  final String gpsSignalQuality;
  final String gpsSignalReason;
  final bool gpsSignalReviewRequired;
  final String mapboxAssistState;
  final String mapboxAssistReason;
  final bool mapboxAssistReviewRequired;
  final String mapboxTrustedMileageSource;
  final double? mapboxRouteDistanceMiles;
  final double? mapboxRouteDeltaMiles;
  final bool mapPreviewEnabled;
  final bool mapRouteHistorySavingEnabled;
  final double mapRouteHistoryDailyBudgetMb;
  final int mapRouteHistorySampleIntervalSeconds;
  final String mapRouteHistoryState;
  final int mapRouteHistoryEstimatedSamplesPerDay;
  final double mapRouteHistoryEstimatedDailyMb;
  final String storageState;
  final String deviceCapabilityState;
  final String sensorAssistState;
  final String odometerCalibrationState;
  final int? odometerCalibrationSamples;
  final double? odometerCalibrationMultiplier;
  final String odometerUsageState;
  final int? odometerUsageReviewedDays;
  final double? odometerUsageCurrentMiles;
  final double? odometerUsageAverageDailyMiles;
  final double? odometerUsageReviewThresholdMiles;
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
    double? odometerCalibrationMultiplier,
    String odometerUsageState = 'disabled',
    int? odometerUsageReviewedDays,
    double? odometerUsageCurrentMiles,
    double? odometerUsageAverageDailyMiles,
    double? odometerUsageReviewThresholdMiles,
    String recoveryState = 'none',
    String recoveryReason = 'trip_recovery_none',
    bool recoveryUserActionRequired = false,
    String stopSignal = 'no_stop',
    String stopActionToken = 'keep_tracking',
    String stopClassificationReason = 'no_stop_review_needed',
    String gpsSignalQuality = 'no_samples',
    String gpsSignalReason = 'gps_signal_waiting_for_samples',
    bool gpsSignalReviewRequired = false,
    MapboxTripAssistDecision? mapboxRouteAssist,
    String mapboxAssistState = 'disabled',
    String mapboxAssistReason = 'mapbox_assist_disabled',
    bool mapboxAssistReviewRequired = false,
    String mapboxTrustedMileageSource = 'none',
    double? mapboxRouteDistanceMiles,
    double? mapboxRouteDeltaMiles,
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
    final mapboxSummary = _dashboardMapboxAssistFor(
      decision: mapboxRouteAssist,
      fallbackState: mapboxAssistState,
      fallbackReason: mapboxAssistReason,
      fallbackReviewRequired: mapboxAssistReviewRequired,
      fallbackTrustedMileageSource: mapboxTrustedMileageSource,
      fallbackRouteDistanceMiles: mapboxRouteDistanceMiles,
      fallbackRouteDeltaMiles: mapboxRouteDeltaMiles,
    );
    final mapStorageEstimate = TripTrackingMapStoragePolicy.estimate(
      settings: settings,
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
      stopSignal: _safeStopSignal(stopSignal),
      stopActionToken: _safeStopActionToken(stopActionToken),
      stopClassificationReason: _safeStopClassificationReason(
        stopClassificationReason,
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
      gpsSignalQuality: _safeGpsSignalQuality(gpsSignalQuality),
      gpsSignalReason: _safeGpsSignalReason(gpsSignalReason),
      gpsSignalReviewRequired: gpsSignalReviewRequired,
      mapboxAssistState: mapboxSummary.state,
      mapboxAssistReason: mapboxSummary.reason,
      mapboxAssistReviewRequired: mapboxSummary.reviewRequired,
      mapboxTrustedMileageSource: mapboxSummary.trustedMileageSource,
      mapboxRouteDistanceMiles: mapboxSummary.routeDistanceMiles,
      mapboxRouteDeltaMiles: mapboxSummary.routeDeltaMiles,
      mapPreviewEnabled: settings.mapPreviewEnabled,
      mapRouteHistorySavingEnabled: settings.mapRouteHistorySavingEnabled,
      mapRouteHistoryDailyBudgetMb: _safeMapRouteHistoryBudget(
        settings.mapRouteHistoryDailyBudgetMb,
      ),
      mapRouteHistorySampleIntervalSeconds: _safeMapRouteHistoryInterval(
        settings.mapRouteHistorySampleIntervalSeconds,
      ),
      mapRouteHistoryState: _mapRouteHistoryState(mapStorageEstimate),
      mapRouteHistoryEstimatedSamplesPerDay:
          mapStorageEstimate.estimatedSamplesPerDay,
      mapRouteHistoryEstimatedDailyMb: mapStorageEstimate.estimatedDailyMb,
      storageState: _safeStorageState(storageState),
      deviceCapabilityState: _safeDeviceCapabilityState(deviceCapabilityState),
      sensorAssistState: _safeSensorAssistState(sensorAssistState),
      odometerCalibrationState: _safeOdometerCalibrationState(
        odometerCalibrationState,
      ),
      odometerCalibrationSamples: _safeCalibrationSamples(
        odometerCalibrationSamples,
      ),
      odometerCalibrationMultiplier: _safeCalibrationMultiplier(
        odometerCalibrationMultiplier,
      ),
      odometerUsageState: _safeOdometerUsageState(odometerUsageState),
      odometerUsageReviewedDays: _safeCalibrationSamples(
        odometerUsageReviewedDays,
      ),
      odometerUsageCurrentMiles: _safeUsageMiles(odometerUsageCurrentMiles),
      odometerUsageAverageDailyMiles: _safeUsageMiles(
        odometerUsageAverageDailyMiles,
      ),
      odometerUsageReviewThresholdMiles: _safeUsageMiles(
        odometerUsageReviewThresholdMiles,
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
      reviewRequired:
          reviewRequired ||
          gpsSignalReviewRequired ||
          mapboxSummary.reviewRequired,
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
    final signalQuality = tripTracking == null
        ? null
        : TripTrackingSignalQualitySummary.evaluate(tripTracking.diagnostics);
    final stopClassification = _stopClassificationFor(
      settings: settings,
      tripTracking: tripTracking,
    );
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
          signalQuality?.requiresUserReview == true ||
          usageSignal?.shouldPromptUser == true,
      storageState: _storageStateFor(storageCheck),
      deviceCapabilityState: _deviceCapabilityStateFor(capabilityGuidance),
      sensorAssistState: _sensorAssistStateFor(capabilityGuidance),
      odometerCalibrationState: _calibrationStateFor(calibrationSignal),
      odometerCalibrationSamples: calibrationSignal?.eligibleSampleCount,
      odometerCalibrationMultiplier:
          calibrationSignal?.gpsAssistanceCalibrationMultiplier,
      odometerUsageState: _usageStateFor(usageSignal),
      odometerUsageReviewedDays: usageSignal?.reviewedDayCount,
      odometerUsageCurrentMiles: usageSignal?.currentOdometerMiles,
      odometerUsageAverageDailyMiles: usageSignal?.averageDailyMiles,
      odometerUsageReviewThresholdMiles: usageSignal?.reviewThresholdMiles,
      recoveryState: _recoveryStateFor(recoveryDecision),
      recoveryReason: _recoveryReasonFor(recoveryDecision),
      recoveryUserActionRequired: recoveryDecision?.requiresUserAction == true,
      stopSignal: _dashboardStopSignalFor(stopClassification),
      stopActionToken: stopClassification?.actionToken ?? 'keep_tracking',
      stopClassificationReason:
          stopClassification?.reasonCode ?? 'no_stop_review_needed',
      gpsSignalQuality: _dashboardGpsSignalQualityFor(signalQuality),
      gpsSignalReason:
          signalQuality?.reasonCode ?? 'gps_signal_waiting_for_samples',
      gpsSignalReviewRequired: signalQuality?.requiresUserReview == true,
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

TripStopClassification? _stopClassificationFor({
  required TripTrackingSettings settings,
  required TripTrackingController? tripTracking,
}) {
  if (tripTracking == null || !tripTracking.isTracking) return null;
  final counts = tripTracking.diagnostics.dispositionCounts;
  return TripStopClassifier.classify(
    profile: settings.defaultProfile,
    motionState: tripTracking.motionState,
    needsWalkingReview: tripTracking.needsWalkingReview,
    excludedWalkingCount: counts[TripSampleDisposition.excludedWalking] ?? 0,
    rejectedDriftCount: counts[TripSampleDisposition.rejectedDrift] ?? 0,
    rejectedUnsafeCount:
        (counts[TripSampleDisposition.rejectedInvalid] ?? 0) +
        (counts[TripSampleDisposition.rejectedMockLocation] ?? 0) +
        (counts[TripSampleDisposition.rejectedAccuracy] ?? 0) +
        (counts[TripSampleDisposition.rejectedOutOfOrder] ?? 0),
    acceptedDistanceCount: counts[TripSampleDisposition.acceptedDistance] ?? 0,
  );
}

String _dashboardStopSignalFor(TripStopClassification? classification) {
  return switch (classification?.signal) {
    TripStopSignal.stopCandidate => 'stop_candidate',
    TripStopSignal.reviewOnlyStop => 'review_only_stop',
    TripStopSignal.likelyTrafficControl => 'likely_traffic_control',
    TripStopSignal.equipmentIgnored => 'equipment_ignored',
    TripStopSignal.unsafeEvidence => 'unsafe_evidence',
    _ => 'no_stop',
  };
}

String _dashboardGpsSignalQualityFor(
  TripTrackingSignalQualitySummary? summary,
) {
  return switch (summary?.quality) {
    TripTrackingSignalQuality.healthy => 'healthy',
    TripTrackingSignalQuality.reduced => 'reduced',
    TripTrackingSignalQuality.poor => 'poor',
    TripTrackingSignalQuality.interrupted => 'interrupted',
    TripTrackingSignalQuality.unsafe => 'unsafe',
    _ => 'no_samples',
  };
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
