import 'trip_tracking_models.dart';
import 'trip_tracking_policy.dart';

class TripTrackingNativeSamplingPolicy {
  const TripTrackingNativeSamplingPolicy._();

  static TripSamplingRecommendation? nextRecommendation({
    required TripTrackingPolicy policy,
    required TripTrackingProfile profile,
    required TripLocationSample sample,
    required TripSampleDecision? decision,
    required TripSamplingRecommendation? current,
    required bool adaptiveSamplingEnabled,
    required bool nativeTracking,
    required bool platformAvailable,
    required bool sessionAvailable,
  }) {
    if (!adaptiveSamplingEnabled ||
        !platformAvailable ||
        !sessionAvailable ||
        !nativeTracking ||
        decision == null ||
        (!decision.accepted &&
            !canDeescalatePrecision(
              policy: policy,
              sample: sample,
              current: current,
            ))) {
      return null;
    }
    final next = policy.samplingFor(
      speedMetersPerSecond: sample.speedMetersPerSecond,
      vehicleMovementConfirmed:
          decision.disposition == TripSampleDisposition.acceptedDistance,
      profile: profile,
      currentMode: current?.mode,
      activeTrip: true,
    );
    return isSameRecommendation(current, next) ? null : next;
  }

  static bool canDeescalatePrecision({
    required TripTrackingPolicy policy,
    required TripLocationSample sample,
    required TripSamplingRecommendation? current,
  }) {
    final speed = sample.speedMetersPerSecond;
    return current?.mode == TripSamplingMode.precision &&
        speed != null &&
        speed.isFinite &&
        speed >= 0 &&
        speed < policy.precisionExitSpeedMetersPerSecond;
  }

  static bool isSameRecommendation(
    TripSamplingRecommendation? current,
    TripSamplingRecommendation next,
  ) =>
      current != null &&
      current.mode == next.mode &&
      current.interval == next.interval &&
      current.minimumDisplacementMeters == next.minimumDisplacementMeters;
}
