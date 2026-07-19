import 'trip_tracking_models.dart';
import 'trip_tracking_platform.dart';
import 'trip_tracking_settings_store.dart';

/// Converts an explicit, user-selected GPS sampling preference into a bounded
/// native request. Capability detection describes what evidence can assist a
/// trip; it must not silently rewrite the user's chosen GPS cadence.
class TripTrackingSamplingPresetPolicy {
  const TripTrackingSamplingPresetPolicy._();

  static TripTrackingSamplingPlan planFor({
    required TripTrackingSamplingPreset preset,
    required int customIntervalSeconds,
    required TripTrackingPlatformCapabilities capabilities,
  }) {
    return TripTrackingSamplingPlan(
      sampling: recommendationFor(
        preset: preset,
        customIntervalSeconds: customIntervalSeconds,
      ),
      deviceTier: capabilities.deviceTier,
      walkingEvidenceAvailable: capabilities.activityRecognitionAvailable,
      batteryProtectionEvidenceAvailable: capabilities.batteryStateAvailable,
    );
  }

  static TripSamplingRecommendation recommendationFor({
    required TripTrackingSamplingPreset preset,
    required int customIntervalSeconds,
  }) => switch (preset) {
    TripTrackingSamplingPreset.highAccuracy => const TripSamplingRecommendation(
      mode: TripSamplingMode.precision,
      interval: Duration(seconds: 3),
      minimumDisplacementMeters: 3,
    ),
    TripTrackingSamplingPreset.enhancedAccuracy =>
      const TripSamplingRecommendation(
        mode: TripSamplingMode.balanced,
        interval: Duration(seconds: 8),
        minimumDisplacementMeters: 5,
      ),
    TripTrackingSamplingPreset.balanced => const TripSamplingRecommendation(
      mode: TripSamplingMode.balanced,
      interval: Duration(seconds: 15),
      minimumDisplacementMeters: 8,
    ),
    TripTrackingSamplingPreset.batterySaver => const TripSamplingRecommendation(
      mode: TripSamplingMode.economy,
      interval: Duration(seconds: 30),
      minimumDisplacementMeters: 20,
    ),
    TripTrackingSamplingPreset.extremeOptimized =>
      const TripSamplingRecommendation(
        mode: TripSamplingMode.economy,
        interval: Duration(seconds: 60),
        minimumDisplacementMeters: 30,
      ),
    TripTrackingSamplingPreset.custom => TripSamplingRecommendation(
      mode: TripSamplingMode.balanced,
      interval: Duration(
        seconds: _boundedCustomInterval(customIntervalSeconds),
      ),
      minimumDisplacementMeters: 8,
    ),
  };

  static int _boundedCustomInterval(int seconds) => seconds.clamp(3, 60);
}

/// Capability facts are retained as coarse feature availability only. This
/// object intentionally contains neither raw location, device identity, nor
/// anything that could authorize tracking or alter confirmed odometer truth.
class TripTrackingSamplingPlan {
  const TripTrackingSamplingPlan({
    required this.sampling,
    required this.deviceTier,
    required this.walkingEvidenceAvailable,
    required this.batteryProtectionEvidenceAvailable,
  });

  final TripSamplingRecommendation sampling;
  final TripTrackingDeviceCapabilityTier deviceTier;
  final bool walkingEvidenceAvailable;
  final bool batteryProtectionEvidenceAvailable;

  /// Adaptive GPS may reduce collection when conditions are quiet, but it must
  /// never become more aggressive than the cadence the driver selected.
  TripSamplingRecommendation constrainAdaptive(
    TripSamplingRecommendation candidate,
  ) {
    final interval = candidate.interval < sampling.interval
        ? sampling.interval
        : candidate.interval;
    final displacement =
        candidate.minimumDisplacementMeters < sampling.minimumDisplacementMeters
        ? sampling.minimumDisplacementMeters
        : candidate.minimumDisplacementMeters;
    final mode = _samplingAggressiveness(candidate.mode) >
            _samplingAggressiveness(sampling.mode)
        ? sampling.mode
        : candidate.mode;
    if (interval == candidate.interval &&
        displacement == candidate.minimumDisplacementMeters &&
        mode == candidate.mode) {
      return candidate;
    }
    return TripSamplingRecommendation(
      mode: mode,
      interval: interval,
      minimumDisplacementMeters: displacement,
    );
  }

  Map<String, Object> toSafeLogMap() => {
    'schemaVersion': 1,
    'samplingMode': sampling.mode.name,
    'samplingIntervalSeconds': sampling.interval.inSeconds,
    'minimumDisplacementMeters': sampling.minimumDisplacementMeters,
    'deviceTier': deviceTier.name,
    'walkingEvidenceAvailable': walkingEvidenceAvailable,
    'batteryProtectionEvidenceAvailable': batteryProtectionEvidenceAvailable,
    'rawLocationIncluded': false,
    'deviceIdentityIncluded': false,
    'canAuthorizeTracking': false,
    'canConfirmOdometerMileage': false,
  };
}

int _samplingAggressiveness(TripSamplingMode mode) => switch (mode) {
  TripSamplingMode.precision => 3,
  TripSamplingMode.balanced => 2,
  TripSamplingMode.economy => 1,
};
