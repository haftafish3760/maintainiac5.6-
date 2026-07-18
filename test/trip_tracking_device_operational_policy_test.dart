import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test('shared device capabilities shape GPS sampling without maps', () {
    final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      DeviceCapabilityProfile(
        hardware: const DeviceHardwareSnapshot(platform: 'android'),
        runtime: DeviceRuntimeSnapshot(
          observedAt: DateTime.utc(2026, 7, 18),
          freeStorageMb: 32000,
          totalStorageMb: 64000,
        ),
        camera: const DeviceCameraCapabilities(),
        extended: const DeviceExtendedCapabilities(
          sensors: DeviceSensorCapabilities(
            types: {'accelerometer', 'gyroscope'},
          ),
          battery: DeviceBatteryCapabilities(levelPercent: 75),
          connectivity: DeviceConnectivityCapabilities(isConnected: true),
        ),
        baselineTier: DevicePerformanceTier.performance,
        tier: DevicePerformanceTier.performance,
        confidence: DeviceCapabilityConfidence.high,
        score: 80,
        limitingFactors: const [],
      ),
    );
    final summary = policy.toSafeSummary();

    expect(policy.activityRecognitionRecommended, isTrue);
    expect(policy.backgroundTrackingAllowed, isTrue);
    expect(policy.deferMapRouteHistory, isFalse);
    expect(summary['usesSharedDeviceCapabilityProfile'], isTrue);
    expect(summary['gpsTrackingCanRunWithoutMaps'], isTrue);
    expect(summary['mapsRequiredForTracking'], isFalse);
    expect(summary['deviceModelIncluded'], isFalse);
    expect(summary['rawSensorPayloadIncluded'], isFalse);
  });

  test('constrained devices defer map history and keep battery guard', () {
    final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      DeviceCapabilityProfile(
        hardware: const DeviceHardwareSnapshot(platform: 'android'),
        runtime: DeviceRuntimeSnapshot(
          observedAt: DateTime.utc(2026, 7, 18),
          freeStorageMb: 500,
          totalStorageMb: 64000,
          powerSaving: true,
        ),
        camera: const DeviceCameraCapabilities(),
        extended: const DeviceExtendedCapabilities(
          battery: DeviceBatteryCapabilities(levelPercent: 12),
        ),
        baselineTier: DevicePerformanceTier.entry,
        tier: DevicePerformanceTier.constrained,
        confidence: DeviceCapabilityConfidence.medium,
        score: 20,
        limitingFactors: const ['low_storage', 'critical_battery'],
      ),
    );
    final guidance = policy.guidanceFor(
      const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        activityRecognitionEnabled: true,
        backgroundTrackingEnabled: true,
        mapPreviewEnabled: true,
        mapRouteHistorySavingEnabled: true,
        mapRouteHistoryDailyBudgetMb: 1,
      ),
    );

    expect(policy.lowBatteryGuardRecommended, isTrue);
    expect(policy.backgroundTrackingAllowed, isFalse);
    expect(policy.activityRecognitionRecommended, isFalse);
    expect(policy.deferMapRouteHistory, isTrue);
    expect(guidance.recommendedSettings.backgroundTrackingEnabled, isFalse);
    expect(guidance.recommendedSettings.activityRecognitionEnabled, isFalse);
    expect(guidance.recommendedSettings.mapRouteHistorySavingEnabled, isFalse);
    expect(guidance.recommendedSettings.lowBatteryGpsProtectionEnabled, isTrue);
  });
}
