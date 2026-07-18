import '../device_capabilities/device_capabilities.dart';

class TripTrackingDeviceProfileValidation {
  const TripTrackingDeviceProfileValidation({
    required this.trustedForGpsAssist,
    required this.reasonCode,
  });

  final bool trustedForGpsAssist;
  final String reasonCode;

  bool get shouldDegradeToLocationOnly => !trustedForGpsAssist;

  Map<String, Object?> toSafeSummary() => {
    'schemaVersion': 1,
    'trustedForGpsAssist': trustedForGpsAssist,
    'reasonCode': reasonCode,
    'degradesToLocationOnly': shouldDegradeToLocationOnly,
    'rawCapabilityPayloadIncluded': false,
    'deviceModelIncluded': false,
    'preciseStorageIncluded': false,
    'preciseBatteryIncluded': false,
    'tokensIncluded': false,
  };

  static TripTrackingDeviceProfileValidation evaluate(
    DeviceCapabilityProfile profile, {
    DateTime? currentAt,
  }) {
    final reason = _firstProfileRisk(profile, currentAt: currentAt);
    return TripTrackingDeviceProfileValidation(
      trustedForGpsAssist: reason == null,
      reasonCode: reason ?? 'profile_trusted_for_gps_assist',
    );
  }
}

String? _firstProfileRisk(
  DeviceCapabilityProfile profile, {
  DateTime? currentAt,
}) {
  final platform = profile.hardware.platform.trim().toLowerCase();
  if (!_allowedPlatformNames.contains(platform)) {
    return 'unknown_platform';
  }
  if (profile.score < 0 || profile.score > 100) {
    return 'invalid_capability_score';
  }
  final runtimeRisk = _runtimeRisk(profile.runtime, currentAt: currentAt);
  if (runtimeRisk != null) return runtimeRisk;
  final batteryRisk = _batteryRisk(profile.extended.battery);
  if (batteryRisk != null) return batteryRisk;
  final sensorRisk = _sensorRisk(profile.extended.sensors);
  if (sensorRisk != null) return sensorRisk;
  final limitingFactorRisk = _limitingFactorRisk(profile.limitingFactors);
  if (limitingFactorRisk != null) return limitingFactorRisk;
  return null;
}

String? _runtimeRisk(DeviceRuntimeSnapshot runtime, {DateTime? currentAt}) {
  if (_negative(runtime.availableRamMb) ||
      _negative(runtime.freeStorageMb) ||
      _negative(runtime.totalStorageMb)) {
    return 'invalid_runtime_capacity';
  }
  final free = runtime.freeStorageMb;
  final total = runtime.totalStorageMb;
  if (free != null && total != null && (total <= 0 || free > total)) {
    return 'invalid_storage_capacity';
  }
  final now = currentAt;
  if (now != null) {
    final observed = runtime.observedAt.toUtc();
    final reference = now.toUtc();
    if (observed.isAfter(reference.add(const Duration(minutes: 5)))) {
      return 'future_runtime_snapshot';
    }
    if (observed.isBefore(reference.subtract(const Duration(minutes: 30)))) {
      return 'stale_runtime_snapshot';
    }
  }
  return null;
}

String? _batteryRisk(DeviceBatteryCapabilities battery) {
  final level = battery.levelPercent;
  if (level != null && (level < 0 || level > 100)) {
    return 'invalid_battery_level';
  }
  final temp = battery.temperatureCelsius;
  if (temp != null && (temp < -30 || temp > 90)) {
    return 'invalid_battery_temperature';
  }
  if (_negative(battery.remainingChargeMah) ||
      _negative(battery.estimatedFullCapacityMah)) {
    return 'invalid_battery_capacity';
  }
  return null;
}

String? _sensorRisk(DeviceSensorCapabilities sensors) {
  if (sensors.sensorCount < 0 || sensors.sensorCount > 256) {
    return 'invalid_sensor_count';
  }
  for (final type in sensors.types) {
    if (!_safeCapabilityName.hasMatch(type)) {
      return 'unsafe_sensor_type';
    }
  }
  return null;
}

String? _limitingFactorRisk(List<String> factors) {
  if (factors.length > 32) return 'too_many_limiting_factors';
  for (final factor in factors) {
    if (!_safeCapabilityName.hasMatch(factor)) {
      return 'unsafe_limiting_factor';
    }
  }
  return null;
}

bool _negative(num? value) => value != null && value < 0;

const _allowedPlatformNames = {
  'android',
  'ios',
  'macos',
  'windows',
  'linux',
  'web',
};

final _safeCapabilityName = RegExp(r'^[a-z0-9_]{1,48}$');
