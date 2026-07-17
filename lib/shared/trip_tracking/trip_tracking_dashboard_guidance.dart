import 'trip_tracking_models.dart';
import 'trip_tracking_profile_strategy.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingDashboardGuidance {
  const TripTrackingDashboardGuidance({
    required this.enabled,
    required this.profileLabel,
    required this.modeToken,
    required this.primaryStatus,
    required this.safetyStatus,
    required this.syncStatus,
    required this.stopDetectionStatus,
    required this.odometerStatus,
    required this.recommendsActivityRecognition,
    required this.activityRecognitionActive,
    required this.backgroundTrackingActive,
    required this.lowBatteryProtectionActive,
    required this.odometerAnomalyAlertsActive,
  });

  final bool enabled;
  final String profileLabel;
  final String modeToken;
  final String primaryStatus;
  final String safetyStatus;
  final String syncStatus;
  final String stopDetectionStatus;
  final String odometerStatus;
  final bool recommendsActivityRecognition;
  final bool activityRecognitionActive;
  final bool backgroundTrackingActive;
  final bool lowBatteryProtectionActive;
  final bool odometerAnomalyAlertsActive;

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
    return badges;
  }

  static TripTrackingDashboardGuidance fromSettings(
    TripTrackingSettings settings,
  ) {
    final strategy = TripTrackingProfileStrategy.forProfile(
      settings.defaultProfile,
    );
    final enabled = settings.gpsAssistedTrackingEnabled;
    final activityActive =
        enabled &&
        settings.activityRecognitionEnabled &&
        strategy.recommendedActivityRecognition;
    final backgroundActive = enabled && settings.backgroundTrackingEnabled;
    final odometerAlerts = enabled && settings.odometerAnomalyAlertsEnabled;
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
      syncStatus: _syncLabel(settings.backupNetworkPolicy),
      stopDetectionStatus: strategy.stopDetectionSummary,
      odometerStatus: odometerAlerts
          ? 'Odometer anomaly review is on. GPS remains advisory and will not replace confirmed odometer readings.'
          : 'Odometer remains the mileage truth. Optional anomaly alerts can warn about unusual mileage swings.',
      recommendsActivityRecognition: strategy.recommendedActivityRecognition,
      activityRecognitionActive: activityActive,
      backgroundTrackingActive: backgroundActive,
      lowBatteryProtectionActive: settings.lowBatteryGpsProtectionEnabled,
      odometerAnomalyAlertsActive: odometerAlerts,
    );
  }
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

String _syncLabel(TripTrackingBackupNetworkPolicy policy) {
  return switch (policy) {
    TripTrackingBackupNetworkPolicy.wifiOnly => 'Sync: Wi-Fi only',
    TripTrackingBackupNetworkPolicy.wifiAndMobileData =>
      'Sync: Wi-Fi or mobile data',
    TripTrackingBackupNetworkPolicy.mobileDataOnly => 'Sync: mobile data only',
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
