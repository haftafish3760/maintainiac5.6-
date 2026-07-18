import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_sync_policy.dart';

class TripTrackingDashboardGuidance {
  const TripTrackingDashboardGuidance({
    required this.enabled,
    required this.profileLabel,
    required this.modeToken,
    required this.primaryStatus,
    required this.safetyStatus,
    required this.syncStatus,
    required this.syncReason,
    required this.mapStatus,
    required this.stopDetectionStatus,
    required this.odometerStatus,
    required this.recommendsActivityRecognition,
    required this.activityRecognitionActive,
    required this.backgroundTrackingActive,
    required this.lowBatteryProtectionActive,
    required this.odometerAnomalyAlertsActive,
    required this.gpsOdometerCalibrationAssistActive,
  });

  final bool enabled;
  final String profileLabel;
  final String modeToken;
  final String primaryStatus;
  final String safetyStatus;
  final String syncStatus;
  final String syncReason;
  final String mapStatus;
  final String stopDetectionStatus;
  final String odometerStatus;
  final bool recommendsActivityRecognition;
  final bool activityRecognitionActive;
  final bool backgroundTrackingActive;
  final bool lowBatteryProtectionActive;
  final bool odometerAnomalyAlertsActive;
  final bool gpsOdometerCalibrationAssistActive;

  bool get shouldShowActivityRecognitionRecommendation =>
      enabled && recommendsActivityRecognition && !activityRecognitionActive;

  bool get shouldShowBatterySafety =>
      enabled && lowBatteryProtectionActive && !backgroundTrackingActive;

  bool get shouldShowOdometerReview => enabled && !odometerAnomalyAlertsActive;

  List<String> get dashboardBadges {
    final badges = <String>[profileLabel, syncStatus];
    if (activityRecognitionActive) badges.add('Motion assist on');
    if (backgroundTrackingActive) badges.add('Background GPS on');
    if (lowBatteryProtectionActive) badges.add('Battery guard on');
    if (odometerAnomalyAlertsActive) badges.add('Odometer alerts on');
    if (gpsOdometerCalibrationAssistActive) {
      badges.add('Odometer calibration assist on');
    }
    if (mapStatus == 'Map preview on') badges.add('Map preview on');
    if (mapStatus == 'Map route history on') badges.add('Map route history on');
    return badges;
  }

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'enabled': enabled,
    'profileLabel': profileLabel,
    'modeToken': modeToken,
    'primaryStatus': primaryStatus,
    'safetyStatus': safetyStatus,
    'syncStatus': syncStatus,
    'syncReason': syncReason,
    'mapStatus': mapStatus,
    'stopDetectionStatus': stopDetectionStatus,
    'odometerStatus': odometerStatus,
    'dashboardBadges': List.unmodifiable(dashboardBadges),
    'shouldShowActivityRecognitionRecommendation':
        shouldShowActivityRecognitionRecommendation,
    'shouldShowBatterySafety': shouldShowBatterySafety,
    'shouldShowOdometerReview': shouldShowOdometerReview,
    'advisoryOnly': true,
    'odometerRemainsCanonical': true,
    'mapsRequiredForTracking': false,
    'locationSharingRequiresActiveOptIn': true,
    'employeeTrackingRequiresMutualConsent': true,
    'employerGodModeAllowed': false,
    'tokensIncluded': false,
    'preciseLocationIncluded': false,
    'rawLocationIncluded': false,
    'rawSensorPayloadIncluded': false,
    'rawModuleDataIncluded': false,
  };

  static TripTrackingDashboardGuidance fromSettings(
    TripTrackingSettings settings,
  ) => fromSettingsWithSyncContext(settings);

  static TripTrackingDashboardGuidance fromSettingsWithSyncContext(
    TripTrackingSettings settings, {
    bool? wifiAvailable,
    bool? mobileDataAvailable,
    int? syncsUsedInWindow,
  }) {
    final strategy = TripTrackingProfileStrategy.forProfile(
      settings.defaultProfile,
    );
    final syncDecision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: settings.backupNetworkPolicy,
      wifiAvailable: wifiAvailable,
      mobileDataAvailable: mobileDataAvailable,
      syncsUsedInWindow: syncsUsedInWindow,
    );
    final enabled = settings.gpsAssistedTrackingEnabled;
    final activityActive =
        enabled &&
        settings.activityRecognitionEnabled &&
        strategy.recommendedActivityRecognition;
    final backgroundActive = enabled && settings.backgroundTrackingEnabled;
    final odometerAlerts = enabled && settings.odometerAnomalyAlertsEnabled;
    final calibrationAssist =
        odometerAlerts && settings.gpsOdometerCalibrationAssistEnabled;
    final profileLabel = _profileLabel(settings.defaultProfile);
    return TripTrackingDashboardGuidance(
      enabled: enabled,
      profileLabel: profileLabel,
      modeToken: strategy.dashboardModeToken,
      primaryStatus: enabled
          ? 'GPS assist is ready for ${profileLabel.toLowerCase()} work.'
          : 'GPS assist is off until you enable it in this dashboard.',
      safetyStatus: _safetyStatus(
        enabled: enabled,
        lowBatteryProtection: settings.lowBatteryGpsProtectionEnabled,
        backgroundTracking: backgroundActive,
      ),
      syncStatus: syncDecision.dashboardLabel,
      syncReason: syncDecision.userFacingReason,
      mapStatus: _mapStatus(settings),
      stopDetectionStatus: strategy.stopDetectionSummary,
      odometerStatus: _odometerStatus(
        odometerAlerts: odometerAlerts,
        calibrationAssist: calibrationAssist,
      ),
      recommendsActivityRecognition: strategy.recommendedActivityRecognition,
      activityRecognitionActive: activityActive,
      backgroundTrackingActive: backgroundActive,
      lowBatteryProtectionActive: settings.lowBatteryGpsProtectionEnabled,
      odometerAnomalyAlertsActive: odometerAlerts,
      gpsOdometerCalibrationAssistActive: calibrationAssist,
    );
  }
}

String _odometerStatus({
  required bool odometerAlerts,
  required bool calibrationAssist,
}) {
  if (calibrationAssist) {
    return 'Odometer calibration assist is on. It can tune future GPS estimates after reviewed patterns, but cannot replace confirmed odometer readings.';
  }
  if (odometerAlerts) {
    return 'Odometer anomaly review is on. GPS remains advisory and will not replace confirmed odometer readings.';
  }
  return 'Odometer remains the mileage truth. Optional anomaly alerts can warn about unusual mileage swings.';
}

String _mapStatus(TripTrackingSettings settings) {
  if (!settings.gpsAssistedTrackingEnabled) {
    return 'Maps are separate from GPS assist.';
  }
  if (!settings.mapPreviewEnabled) {
    return 'GPS assist is running without maps.';
  }
  if (!settings.mapRouteHistorySavingEnabled) return 'Map preview on';
  return 'Map route history on';
}

String _profileLabel(TripTrackingProfile profile) {
  return switch (profile) {
    TripTrackingProfile.rideshareVehicle => 'Rideshare',
    TripTrackingProfile.deliveryVehicle => 'Delivery',
    TripTrackingProfile.contractorVehicle => 'Contractor',
    TripTrackingProfile.lowSpeedEquipment => 'Equipment',
    TripTrackingProfile.roadVehicle => 'Road vehicle',
  };
}

String _safetyStatus({
  required bool enabled,
  required bool lowBatteryProtection,
  required bool backgroundTracking,
}) {
  if (!enabled) return 'Battery guard is staged but GPS is off.';
  if (!lowBatteryProtection) return 'Battery guard is off by user choice.';
  if (backgroundTracking) {
    return 'Battery guard stays on while background tracking is allowed.';
  }
  return 'Battery guard will ask before GPS starts below the safety threshold.';
}
