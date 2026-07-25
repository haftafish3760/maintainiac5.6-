part of 'trip_tracking_platform.dart';

class TripTrackingNativeRequest {
  const TripTrackingNativeRequest({
    required this.profile,
    required this.sampling,
    this.allowBackground = false,
    this.activityRecognitionEnabled = false,
  });

  final TripTrackingProfile profile;
  final TripSamplingRecommendation sampling;

  /// Consent bound to this collector start, not a UI preference alone.
  final bool allowBackground;
  final bool activityRecognitionEnabled;

  Map<String, Object> toMap() => {
    'profile': profile.name,
    'intervalMillis': _safeSamplingIntervalMillis(sampling.interval),
    'minimumDisplacementMeters': _safeMinimumDisplacementMeters(
      sampling.minimumDisplacementMeters,
    ),
    'allowBackground': allowBackground,
    'activityRecognitionEnabled': activityRecognitionEnabled,
  };
}

int _safeSamplingIntervalMillis(Duration interval) {
  final millis = interval.inMilliseconds;
  // Both native collectors cap at sixty seconds. Bound here too so the
  // saved setting, Dart request, Android, and iOS all mean the same thing.
  return millis.clamp(1000, 60000).toInt();
}

double _safeMinimumDisplacementMeters(double meters) {
  if (!meters.isFinite || meters <= 0) return 1;
  // Android and iOS both enforce this same ceiling. Bound it before crossing
  // the native channel so saved diagnostics describe the request the device
  // actually receives instead of a silently rewritten value.
  return meters > 100 ? 100 : meters;
}

class TripTrackingPlatformCapabilities {
  const TripTrackingPlatformCapabilities({
    required this.locationAvailable,
    required this.backgroundTrackingAvailable,
    required this.activityRecognitionAvailable,
    this.batteryStateAvailable = false,
    this.lowPowerModeAvailable = false,
  });

  final bool locationAvailable;
  final bool backgroundTrackingAvailable;
  final bool activityRecognitionAvailable;
  final bool batteryStateAvailable;
  final bool lowPowerModeAvailable;

  TripTrackingDeviceCapabilityTier get deviceTier {
    if (!locationAvailable) return TripTrackingDeviceCapabilityTier.unavailable;
    if (activityRecognitionAvailable && batteryStateAvailable) {
      return TripTrackingDeviceCapabilityTier.motionAndBatteryAssist;
    }
    if (activityRecognitionAvailable) {
      return TripTrackingDeviceCapabilityTier.motionAssist;
    }
    return TripTrackingDeviceCapabilityTier.locationOnly;
  }

  /// Safe for diagnostics: no device model, identity, or raw sensor payloads.
  Map<String, Object> toSafeLogMap() => {
    'schemaVersion': 1,
    'externalNativeInput': true,
    'payloadPassedSchemaValidation': true,
    'locationAvailable': locationAvailable,
    'backgroundTrackingAvailable': backgroundTrackingAvailable,
    'activityRecognitionAvailable': activityRecognitionAvailable,
    'batteryStateAvailable': batteryStateAvailable,
    'lowPowerModeAvailable': lowPowerModeAvailable,
    'deviceTier': deviceTier.name,
    'capabilityCanAuthorizeUserDataAccess': false,
    'capabilityCanConfirmMileage': false,
    'deviceModelIncluded': false,
    'rawSensorPayloadIncluded': false,
    'preciseLocationIncluded': false,
    'tokensIncluded': false,
  };

  factory TripTrackingPlatformCapabilities.fromMap(Map<dynamic, dynamic> map) {
    if (!_schemaVersionAllowed(map['schemaVersion'])) {
      return const TripTrackingPlatformCapabilities(
        locationAvailable: false,
        backgroundTrackingAvailable: false,
        activityRecognitionAvailable: false,
      );
    }
    final locationAvailable = map['locationAvailable'] == true;
    final batteryStateAvailable =
        locationAvailable && map['batteryStateAvailable'] == true;
    return TripTrackingPlatformCapabilities(
      locationAvailable: locationAvailable,
      backgroundTrackingAvailable:
          locationAvailable && map['backgroundTrackingAvailable'] == true,
      activityRecognitionAvailable:
          locationAvailable && map['activityRecognitionAvailable'] == true,
      batteryStateAvailable: batteryStateAvailable,
      lowPowerModeAvailable:
          batteryStateAvailable && map['lowPowerModeAvailable'] == true,
    );
  }
}

enum TripTrackingDeviceCapabilityTier {
  unavailable,
  locationOnly,
  motionAssist,
  motionAndBatteryAssist,
}

class TripTrackingBatterySnapshot {
  const TripTrackingBatterySnapshot({
    required this.batteryPercent,
    required this.isCharging,
    required this.lowPowerModeEnabled,
  });

  final int? batteryPercent;
  final bool isCharging;
  final bool lowPowerModeEnabled;

  /// Buckets battery state without creating a precise telemetry trail.
  Map<String, Object?> toSafeLogMap() => {
    'schemaVersion': 1,
    'externalNativeInput': true,
    'payloadPassedSchemaValidation': true,
    'batteryPercentBucket': _batteryBucket(batteryPercent),
    'isCharging': isCharging,
    'lowPowerModeEnabled': lowPowerModeEnabled,
    'batteryCanStopTripAutomatically': false,
    'batteryCanDeleteLocalData': false,
    'preciseBatteryIncluded': false,
    'rawBatteryPayloadIncluded': false,
  };

  factory TripTrackingBatterySnapshot.fromMap(Map<dynamic, dynamic> map) {
    if (!_schemaVersionAllowed(map['schemaVersion'])) {
      return const TripTrackingBatterySnapshot(
        batteryPercent: null,
        isCharging: false,
        lowPowerModeEnabled: false,
      );
    }
    final rawPercent = map['batteryPercent'];
    final percent = rawPercent is num && rawPercent.isFinite
        ? rawPercent.floor()
        : null;
    return TripTrackingBatterySnapshot(
      batteryPercent: percent != null && percent >= 0 && percent <= 100
          ? percent
          : null,
      isCharging: map['isCharging'] == true,
      lowPowerModeEnabled: map['lowPowerModeEnabled'] == true,
    );
  }
}
