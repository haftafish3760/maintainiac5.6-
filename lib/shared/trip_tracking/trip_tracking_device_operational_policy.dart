import '../device_capabilities/device_capabilities.dart';
import 'trip_tracking_capability_guidance.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

class TripTrackingDeviceOperationalPolicy {
  const TripTrackingDeviceOperationalPolicy({
    required this.platformCapabilities,
    required this.recommendedSampleIntervalSeconds,
    required this.lowBatteryGuardRecommended,
    required this.activityRecognitionRecommended,
    required this.backgroundTrackingAllowed,
    required this.deferMapRouteHistory,
  });

  final TripTrackingPlatformCapabilities platformCapabilities;
  final int recommendedSampleIntervalSeconds;
  final bool lowBatteryGuardRecommended;
  final bool activityRecognitionRecommended;
  final bool backgroundTrackingAllowed;
  final bool deferMapRouteHistory;

  TripTrackingCapabilityGuidance guidanceFor(TripTrackingSettings settings) {
    return TripTrackingCapabilityGuidance.fromCapabilities(
      capabilities: platformCapabilities,
      settings: settings.copyWith(
        lowBatteryGpsProtectionEnabled: lowBatteryGuardRecommended,
        activityRecognitionEnabled:
            settings.activityRecognitionEnabled &&
            activityRecognitionRecommended,
        backgroundTrackingEnabled:
            settings.backgroundTrackingEnabled && backgroundTrackingAllowed,
        mapRouteHistorySavingEnabled:
            settings.mapRouteHistorySavingEnabled && !deferMapRouteHistory,
        mapRouteHistorySampleIntervalSeconds: recommendedSampleIntervalSeconds,
      ),
    );
  }

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'usesSharedDeviceCapabilityProfile': true,
    'deviceTier': platformCapabilities.deviceTier.name,
    'recommendedSampleIntervalSeconds': _safeSampleIntervalSeconds(
      recommendedSampleIntervalSeconds,
    ),
    'lowBatteryGuardRecommended': lowBatteryGuardRecommended,
    'activityRecognitionRecommended': activityRecognitionRecommended,
    'backgroundTrackingAllowed': backgroundTrackingAllowed,
    'deferMapRouteHistory': deferMapRouteHistory,
    'gpsTrackingCanRunWithoutMaps': true,
    'mapsRequiredForTracking': false,
    'gpsTextTripLogCanContinueWithLowStorage': true,
    'mapRouteHistoryIsOptional': true,
    'mapRouteHistoryDeferBelowDeviceBudget': true,
    'deviceCapabilityTrustedAfterValidationOnly': true,
    'remoteCapabilityCanEnableSensorsWithoutOptIn': false,
    'firebaseDeviceProfileCanOverrideUserConsent': false,
    'mapboxCanOverrideDevicePolicy': false,
    'malformedCapabilityPayloadFailsSafe': true,
    'lowBatteryDefaultGpsPausePercent': 20,
    'lowBatteryPauseCanBeOverriddenByUser': true,
    'activityRecognitionRequiresOptIn': true,
    'backgroundTrackingRequiresPlatformPermission': true,
    'deviceModelIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  factory TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
    DeviceCapabilityProfile profile,
  ) {
    final operational = profile.operationalPolicy;
    final sensors = profile.extended.sensors;
    final battery = profile.extended.battery;
    final constrained = operational.deferNonEssentialHeavyWork;
    return TripTrackingDeviceOperationalPolicy(
      platformCapabilities: TripTrackingPlatformCapabilities(
        locationAvailable: true,
        backgroundTrackingAvailable: !constrained,
        activityRecognitionAvailable: sensors.hasMotion,
        batteryStateAvailable: battery.levelPercent != null,
        lowPowerModeAvailable: profile.runtime.powerSaving || battery.isLow,
      ),
      recommendedSampleIntervalSeconds: operational.tripLocationIntervalSeconds
          .clamp(5, 60),
      lowBatteryGuardRecommended: true,
      activityRecognitionRecommended: sensors.hasMotion && !constrained,
      backgroundTrackingAllowed: !constrained,
      deferMapRouteHistory:
          constrained || !operational.allowLargeNetworkTransfer,
    );
  }
}

int _safeSampleIntervalSeconds(int value) => value.clamp(5, 60).toInt();
