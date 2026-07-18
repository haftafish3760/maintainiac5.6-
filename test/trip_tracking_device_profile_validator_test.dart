import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_operational_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_device_profile_validator.dart';

void main() {
  test(
    'malformed device profile degrades GPS assist instead of trusting sensors',
    () {
      final profile = _trustedProfile(
        freeStorageMb: 128000,
        totalStorageMb: 64000,
      );

      final validation = TripTrackingDeviceProfileValidation.evaluate(
        profile,
        currentAt: DateTime.utc(2026, 7, 18, 12, 1),
      );
      final policy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
        profile,
        currentAt: DateTime.utc(2026, 7, 18, 12, 1),
      );
      final summary = validation.toSafeSummary();

      expect(validation.trustedForGpsAssist, isFalse);
      expect(validation.reasonCode, 'invalid_storage_capacity');
      expect(summary['degradesToLocationOnly'], isTrue);
      expect(summary['preciseStorageIncluded'], isFalse);
      expect(policy.backgroundTrackingAllowed, isFalse);
      expect(policy.activityRecognitionRecommended, isFalse);
      expect(policy.platformCapabilities.activityRecognitionAvailable, isFalse);
      expect(policy.deferMapRouteHistory, isTrue);
    },
  );

  test('stale or unsafe capability data cannot enable motion stop assist', () {
    final stale = _trustedProfile(
      platform: 'ios',
      observedAt: DateTime.utc(2026, 7, 18, 8),
    );
    final unsafeSensor = _trustedProfile(
      sensors: {'accelerometer', 'gyroscope', 'token=sk.secret'},
    );

    final staleValidation = TripTrackingDeviceProfileValidation.evaluate(
      stale,
      currentAt: DateTime.utc(2026, 7, 18, 12),
    );
    final unsafeValidation = TripTrackingDeviceProfileValidation.evaluate(
      unsafeSensor,
      currentAt: DateTime.utc(2026, 7, 18, 12),
    );
    final unsafePolicy = TripTrackingDeviceOperationalPolicy.fromDeviceProfile(
      unsafeSensor,
      currentAt: DateTime.utc(2026, 7, 18, 12),
    );

    expect(staleValidation.reasonCode, 'stale_runtime_snapshot');
    expect(unsafeValidation.reasonCode, 'unsafe_sensor_type');
    expect(unsafePolicy.activityRecognitionRecommended, isFalse);
    expect(unsafePolicy.backgroundTrackingAllowed, isFalse);
    expect(unsafeValidation.toSafeSummary().toString(), isNot(contains('sk.')));
  });
}

DeviceCapabilityProfile _trustedProfile({
  String platform = 'android',
  DateTime? observedAt,
  int freeStorageMb = 64000,
  int totalStorageMb = 128000,
  Set<String> sensors = const {'accelerometer', 'gyroscope'},
}) {
  return DeviceCapabilityProfile(
    hardware: DeviceHardwareSnapshot(platform: platform),
    runtime: DeviceRuntimeSnapshot(
      observedAt: observedAt ?? DateTime.utc(2026, 7, 18, 12),
      freeStorageMb: freeStorageMb,
      totalStorageMb: totalStorageMb,
    ),
    camera: const DeviceCameraCapabilities(),
    extended: DeviceExtendedCapabilities(
      sensors: DeviceSensorCapabilities(
        sensorCount: sensors.length,
        types: sensors,
      ),
      battery: const DeviceBatteryCapabilities(levelPercent: 50),
      connectivity: const DeviceConnectivityCapabilities(isConnected: true),
    ),
    baselineTier: DevicePerformanceTier.performance,
    tier: DevicePerformanceTier.performance,
    confidence: DeviceCapabilityConfidence.high,
    score: 80,
    limitingFactors: const [],
  );
}
