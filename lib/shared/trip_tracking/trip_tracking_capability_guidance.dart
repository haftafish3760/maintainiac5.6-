import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

enum TripTrackingCapabilityReadiness {
  unavailable,
  locationOnly,
  foregroundReady,
  backgroundReady,
  motionReady,
  fullSafetyAssist,
}

class TripTrackingCapabilityGuidance {
  const TripTrackingCapabilityGuidance({
    required this.readiness,
    required this.canStartForegroundGps,
    required this.canStartBackgroundGps,
    required this.canUseActivityRecognition,
    required this.canUseBatteryGuard,
    required this.canUseLowPowerGuard,
    required this.safeStatus,
    required this.dashboardBadge,
    required this.recommendedSettings,
  });

  final TripTrackingCapabilityReadiness readiness;
  final bool canStartForegroundGps;
  final bool canStartBackgroundGps;
  final bool canUseActivityRecognition;
  final bool canUseBatteryGuard;
  final bool canUseLowPowerGuard;
  final String safeStatus;
  final String dashboardBadge;
  final TripTrackingSettings recommendedSettings;

  bool get gpsUnavailable =>
      readiness == TripTrackingCapabilityReadiness.unavailable;

  bool get hasSafetySensors =>
      canUseBatteryGuard || canUseActivityRecognition || canUseLowPowerGuard;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'readiness': readiness.name,
    'canStartForegroundGps': canStartForegroundGps,
    'canStartBackgroundGps': canStartBackgroundGps,
    'canUseActivityRecognition': canUseActivityRecognition,
    'canUseBatteryGuard': canUseBatteryGuard,
    'canUseLowPowerGuard': canUseLowPowerGuard,
    'gpsUnavailable': gpsUnavailable,
    'hasSafetySensors': hasSafetySensors,
    'safeStatus': safeStatus,
    'dashboardBadge': dashboardBadge,
    'gpsAssistRequiresOptIn': true,
    'backgroundTrackingRequiresOptIn': true,
    'activityRecognitionRequiresOptIn': true,
    'batteryGuardRequiresOptIn': true,
    'deviceCapabilityCanReduceAccuracy': true,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'routeHistoryRequiresLocationCapability': true,
    'routeHistoryDisabledWhenGpsUnavailable': true,
    'odometerRemainsCanonical': true,
    'nativeCapabilitiesAreAdvisory': true,
    'sensorAvailabilityRequiresRuntimePermission': true,
    'capabilityReadDoesNotStartTracking': true,
    'capabilityReadDoesNotGrantAuthorization': true,
    'batteryBelowTwentyDefaultsToGpsPause': canUseBatteryGuard,
    'lowBatteryOverrideRequiresUserChoice': canUseBatteryGuard,
    'lowBatteryWarningCanBeRestoredInSettings': canUseBatteryGuard,
    'rawNativePayloadIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  static TripTrackingCapabilityGuidance fromCapabilities({
    required TripTrackingPlatformCapabilities capabilities,
    required TripTrackingSettings settings,
  }) {
    final gpsEnabled =
        settings.gpsAssistedTrackingEnabled && capabilities.locationAvailable;
    final activityEnabled =
        gpsEnabled &&
        settings.activityRecognitionEnabled &&
        capabilities.activityRecognitionAvailable;
    final backgroundEnabled =
        gpsEnabled &&
        settings.backgroundTrackingEnabled &&
        capabilities.backgroundTrackingAvailable;
    final lowBatteryProtection =
        settings.lowBatteryGpsProtectionEnabled &&
        capabilities.batteryStateAvailable;
    final recommended = settings.copyWith(
      gpsAssistedTrackingEnabled: gpsEnabled,
      backgroundTrackingEnabled: backgroundEnabled,
      activityRecognitionEnabled: activityEnabled,
      lowBatteryGpsProtectionEnabled: lowBatteryProtection,
      lowBatteryGpsOverrideEnabled:
          lowBatteryProtection && settings.lowBatteryGpsOverrideEnabled,
      lowBatteryGpsWarningDismissed:
          lowBatteryProtection && settings.lowBatteryGpsWarningDismissed,
      mapRouteHistorySavingEnabled:
          gpsEnabled && settings.mapRouteHistorySavingEnabled,
    );
    final readiness = _readinessFor(
      capabilities: capabilities,
      backgroundEnabled: backgroundEnabled,
      activityEnabled: activityEnabled,
      lowBatteryProtection: lowBatteryProtection,
    );
    return TripTrackingCapabilityGuidance(
      readiness: readiness,
      canStartForegroundGps: capabilities.locationAvailable,
      canStartBackgroundGps: backgroundEnabled,
      canUseActivityRecognition: capabilities.activityRecognitionAvailable,
      canUseBatteryGuard: capabilities.batteryStateAvailable,
      canUseLowPowerGuard: capabilities.lowPowerModeAvailable,
      safeStatus: _safeStatus(readiness),
      dashboardBadge: _dashboardBadge(readiness),
      recommendedSettings: recommended,
    );
  }
}

TripTrackingCapabilityReadiness _readinessFor({
  required TripTrackingPlatformCapabilities capabilities,
  required bool backgroundEnabled,
  required bool activityEnabled,
  required bool lowBatteryProtection,
}) {
  if (!capabilities.locationAvailable) {
    return TripTrackingCapabilityReadiness.unavailable;
  }
  if (activityEnabled &&
      lowBatteryProtection &&
      capabilities.lowPowerModeAvailable) {
    return TripTrackingCapabilityReadiness.fullSafetyAssist;
  }
  if (activityEnabled) return TripTrackingCapabilityReadiness.motionReady;
  if (backgroundEnabled) return TripTrackingCapabilityReadiness.backgroundReady;
  if (capabilities.locationAvailable) {
    return TripTrackingCapabilityReadiness.foregroundReady;
  }
  return TripTrackingCapabilityReadiness.locationOnly;
}

String _safeStatus(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable =>
      'GPS tracking is unavailable on this device.',
    TripTrackingCapabilityReadiness.locationOnly =>
      'Location-only GPS assist is available.',
    TripTrackingCapabilityReadiness.foregroundReady =>
      'Foreground GPS assist is available.',
    TripTrackingCapabilityReadiness.backgroundReady =>
      'Background GPS assist is available when the user opts in.',
    TripTrackingCapabilityReadiness.motionReady =>
      'Motion-assisted stop review is available when the user opts in.',
    TripTrackingCapabilityReadiness.fullSafetyAssist =>
      'Motion and battery safety assist are available when the user opts in.',
  };
}

String _dashboardBadge(TripTrackingCapabilityReadiness readiness) {
  return switch (readiness) {
    TripTrackingCapabilityReadiness.unavailable => 'GPS unavailable',
    TripTrackingCapabilityReadiness.locationOnly => 'Location only',
    TripTrackingCapabilityReadiness.foregroundReady => 'Foreground GPS',
    TripTrackingCapabilityReadiness.backgroundReady => 'Background capable',
    TripTrackingCapabilityReadiness.motionReady => 'Motion capable',
    TripTrackingCapabilityReadiness.fullSafetyAssist => 'Motion + battery',
  };
}
