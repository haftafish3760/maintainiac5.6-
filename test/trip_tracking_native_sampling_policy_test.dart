import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_native_sampling_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  final start = DateTime.utc(2026, 7, 14, 12);

  TripLocationSample sample({required int seconds, required double speed}) =>
      TripLocationSample(
        latitude: 35,
        longitude: -80 + (seconds * .0001),
        horizontalAccuracyMeters: 8,
        recordedAt: start.add(Duration(seconds: seconds)),
        speedMetersPerSecond: speed,
      );

  TripSampleDecision decision(TripSampleDisposition disposition) =>
      TripSampleDecision(
        disposition: disposition,
        totalAcceptedMeters: 0,
        motionState: TripMotionState.moving,
      );

  test('sampling stays unchanged when the recommendation is identical', () {
    const current = TripSamplingRecommendation(
      mode: TripSamplingMode.balanced,
      interval: Duration(seconds: 5),
      minimumDisplacementMeters: 5,
    );

    expect(
      TripTrackingNativeSamplingPolicy.nextRecommendation(
        policy: const TripTrackingPolicy(),
        profile: TripTrackingProfile.roadVehicle,
        sample: sample(seconds: 20, speed: 1),
        decision: decision(TripSampleDisposition.acceptedAnchor),
        current: current,
        adaptiveSamplingEnabled: true,
        nativeTracking: true,
        platformAvailable: true,
        sessionAvailable: true,
      ),
      isNull,
    );
  });

  test('accepted high-speed distance escalates to precision sampling', () {
    final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: const TripTrackingPolicy(),
      profile: TripTrackingProfile.roadVehicle,
      sample: sample(seconds: 20, speed: 8),
      decision: decision(TripSampleDisposition.acceptedDistance),
      current: const TripSamplingRecommendation(
        mode: TripSamplingMode.balanced,
        interval: Duration(seconds: 5),
        minimumDisplacementMeters: 5,
      ),
      adaptiveSamplingEnabled: true,
      nativeTracking: true,
      platformAvailable: true,
      sessionAvailable: true,
    );

    expect(next?.mode, TripSamplingMode.precision);
    expect(next?.interval, const Duration(seconds: 2));
  });

  test(
    'stationary drift can deescalate from precision without adding miles',
    () {
      final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
        policy: const TripTrackingPolicy(),
        profile: TripTrackingProfile.roadVehicle,
        sample: sample(seconds: 22, speed: 0),
        decision: decision(TripSampleDisposition.rejectedDrift),
        current: const TripSamplingRecommendation(
          mode: TripSamplingMode.precision,
          interval: Duration(seconds: 2),
          minimumDisplacementMeters: 3,
        ),
        adaptiveSamplingEnabled: true,
        nativeTracking: true,
        platformAvailable: true,
        sessionAvailable: true,
      );

      expect(next?.mode, TripSamplingMode.balanced);
      expect(next?.interval, const Duration(seconds: 5));
    },
  );

  test(
    'malformed or unavailable state cannot trigger native sampling update',
    () {
      for (final flags in [
        (adaptive: false, tracking: true, platform: true, session: true),
        (adaptive: true, tracking: false, platform: true, session: true),
        (adaptive: true, tracking: true, platform: false, session: true),
        (adaptive: true, tracking: true, platform: true, session: false),
      ]) {
        expect(
          TripTrackingNativeSamplingPolicy.nextRecommendation(
            policy: const TripTrackingPolicy(),
            profile: TripTrackingProfile.roadVehicle,
            sample: sample(seconds: 20, speed: 8),
            decision: decision(TripSampleDisposition.acceptedDistance),
            current: null,
            adaptiveSamplingEnabled: flags.adaptive,
            nativeTracking: flags.tracking,
            platformAvailable: flags.platform,
            sessionAvailable: flags.session,
          ),
          isNull,
        );
      }
    },
  );
}
