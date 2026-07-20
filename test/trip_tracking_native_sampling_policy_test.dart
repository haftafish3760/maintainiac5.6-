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
    final summary = TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
      recommendation: next,
      adaptiveSamplingEnabled: true,
      nativeTracking: true,
      platformAvailable: true,
      sessionAvailable: true,
    );
    final validation = TripTrackingNativeSamplingSummaryValidation.fromSummary(
      summary,
    );
    expect(summary['canUpdateNativeCadence'], isTrue);
    expect(summary['validatedSampleRequired'], isTrue);
    expect(summary['mapboxCanChangeNativeCadence'], isFalse);
    expect(summary['nativeSamplingCanConfirmOdometer'], isFalse);
    expect(summary['nativeSamplingCanSetGlobalTruth'], isFalse);
    expect(summary['nativeSamplingCanChangeOfficialMileage'], isFalse);
    expect(validation.isRenderable, isTrue);
    expect(validation.canUpdateNativeCadence, isTrue);
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
      expect(
        TripTrackingNativeSamplingSummaryValidation.fromSummary(
          TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
            recommendation: next,
            adaptiveSamplingEnabled: true,
            nativeTracking: true,
            platformAvailable: true,
            sessionAvailable: true,
          ),
        ).isRenderable,
        isTrue,
      );
    },
  );

  test('malformed precision exit settings cannot pin high-rate GPS', () {
    final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: const TripTrackingPolicy(
        precisionExitSpeedMetersPerSecond: double.nan,
      ),
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
  });

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
        final summary =
            TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
              recommendation: null,
              adaptiveSamplingEnabled: flags.adaptive,
              nativeTracking: flags.tracking,
              platformAvailable: flags.platform,
              sessionAvailable: flags.session,
            );
        expect(
          TripTrackingNativeSamplingSummaryValidation.fromSummary(
            summary,
          ).canUpdateNativeCadence,
          isFalse,
        );
      }
    },
  );

  test('unsafe rejected GPS samples cannot change native sampling cadence', () {
    const current = TripSamplingRecommendation(
      mode: TripSamplingMode.precision,
      interval: Duration(seconds: 2),
      minimumDisplacementMeters: 3,
    );

    for (final disposition in [
      TripSampleDisposition.rejectedInvalid,
      TripSampleDisposition.rejectedMockLocation,
      TripSampleDisposition.rejectedAccuracy,
      TripSampleDisposition.rejectedOutOfOrder,
      TripSampleDisposition.rejectedImplausibleSpeed,
      TripSampleDisposition.rejectedGap,
      TripSampleDisposition.rejectedFutureTimestamp,
    ]) {
      final rejected = decision(disposition);
      expect(
        TripTrackingNativeSamplingPolicy.isSafeDecisionForNativeSampling(
          rejected,
        ),
        isFalse,
        reason: disposition.name,
      );
      expect(
        TripTrackingNativeSamplingPolicy.nextRecommendation(
          policy: const TripTrackingPolicy(),
          profile: TripTrackingProfile.roadVehicle,
          sample: sample(seconds: 30, speed: 0),
          decision: rejected,
          current: current,
          adaptiveSamplingEnabled: true,
          nativeTracking: true,
          platformAvailable: true,
          sessionAvailable: true,
        ),
        isNull,
        reason: disposition.name,
      );
    }
  });

  test('stationary speed conflicts can only downgrade precision sampling', () {
    const current = TripSamplingRecommendation(
      mode: TripSamplingMode.precision,
      interval: Duration(seconds: 2),
      minimumDisplacementMeters: 3,
    );
    final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: const TripTrackingPolicy(),
      profile: TripTrackingProfile.rideshareVehicle,
      sample: sample(seconds: 30, speed: 0.2),
      decision: decision(TripSampleDisposition.rejectedSpeedConflict),
      current: current,
      adaptiveSamplingEnabled: true,
      nativeTracking: true,
      platformAvailable: true,
      sessionAvailable: true,
    );

    expect(next?.mode, TripSamplingMode.balanced);
    expect(
      TripTrackingNativeSamplingPolicy.nextRecommendation(
        policy: const TripTrackingPolicy(),
        profile: TripTrackingProfile.rideshareVehicle,
        sample: sample(seconds: 30, speed: 8),
        decision: decision(TripSampleDisposition.rejectedSpeedConflict),
        current: current,
        adaptiveSamplingEnabled: true,
        nativeTracking: true,
        platformAvailable: true,
        sessionAvailable: true,
      ),
      isNull,
    );
  });

  test(
    'malformed samples cannot change native sampling even with safe decision',
    () {
      const current = TripSamplingRecommendation(
        mode: TripSamplingMode.balanced,
        interval: Duration(seconds: 5),
        minimumDisplacementMeters: 5,
      );
      final malformedSamples = [
        TripLocationSample(
          latitude: 95,
          longitude: -80,
          horizontalAccuracyMeters: 8,
          recordedAt: start.add(const Duration(seconds: 20)),
          speedMetersPerSecond: 8,
        ),
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          horizontalAccuracyMeters: 500,
          recordedAt: start.add(const Duration(seconds: 20)),
          speedMetersPerSecond: 8,
        ),
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          horizontalAccuracyMeters: 8,
          recordedAt: DateTime.utc(1970),
          speedMetersPerSecond: 8,
        ),
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          horizontalAccuracyMeters: 8,
          recordedAt: start.add(const Duration(seconds: 20)),
          speedMetersPerSecond: double.infinity,
        ),
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          horizontalAccuracyMeters: 8,
          recordedAt: start.add(const Duration(seconds: 20)),
          speedMetersPerSecond: 8,
          mockedLocation: true,
        ),
      ];

      for (final malformed in malformedSamples) {
        expect(
          TripTrackingNativeSamplingPolicy.isSafeSampleForNativeSampling(
            malformed,
          ),
          isFalse,
        );
        expect(
          TripTrackingNativeSamplingPolicy.nextRecommendation(
            policy: const TripTrackingPolicy(),
            profile: TripTrackingProfile.roadVehicle,
            sample: malformed,
            decision: decision(TripSampleDisposition.acceptedDistance),
            current: current,
            adaptiveSamplingEnabled: true,
            nativeTracking: true,
            platformAvailable: true,
            sessionAvailable: true,
          ),
          isNull,
        );
      }
    },
  );

  test('walking exclusion can deescalate precision without adding mileage', () {
    final next = TripTrackingNativeSamplingPolicy.nextRecommendation(
      policy: const TripTrackingPolicy(),
      profile: TripTrackingProfile.deliveryVehicle,
      sample: sample(seconds: 40, speed: 0.4),
      decision: decision(TripSampleDisposition.excludedWalking),
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
    expect(
      TripTrackingNativeSamplingPolicy.isSafeDecisionForNativeSampling(
        decision(TripSampleDisposition.excludedWalking),
      ),
      isTrue,
    );
  });

  test('safe native sampling summaries reject forged authority', () {
    final summary = TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
      recommendation: const TripSamplingRecommendation(
        mode: TripSamplingMode.precision,
        interval: Duration(seconds: 2),
        minimumDisplacementMeters: 3,
      ),
      adaptiveSamplingEnabled: true,
      nativeTracking: true,
      platformAvailable: true,
      sessionAvailable: true,
    );

    expect(
      TripTrackingNativeSamplingSummaryValidation.fromSummary({
        ...summary,
        'mapboxCanChangeNativeCadence': true,
      }).reasons,
      contains('external_or_unsafe_sample_can_change_cadence'),
    );
    expect(
      TripTrackingNativeSamplingSummaryValidation.fromSummary({
        ...summary,
        'nativeSamplingCanConfirmOdometer': true,
        'nativeSamplingCanSetGlobalTruth': true,
        'nativeSamplingCanChangeOfficialMileage': true,
      }).reasons,
      contains('native_sampling_claims_trip_truth'),
    );
    expect(
      TripTrackingNativeSamplingSummaryValidation.fromSummary({
        ...summary,
        'debug': '35.123456,-80.123456 token=sk.secret',
      }).reasons,
      contains('summary_contains_sensitive_sampling_material'),
    );
  });

  test('summary cannot claim cadence update without local prerequisites', () {
    final validation = TripTrackingNativeSamplingSummaryValidation.fromSummary({
      ...TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
        recommendation: null,
        adaptiveSamplingEnabled: false,
        nativeTracking: false,
        platformAvailable: false,
        sessionAvailable: false,
      ),
      'canUpdateNativeCadence': true,
    });

    expect(validation.isRenderable, isFalse);
    expect(validation.reasons, contains('unsafe_native_cadence_update_claim'));
  });

  test('summary rejects contradictory recommendation shape', () {
    final empty = TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
      recommendation: null,
      adaptiveSamplingEnabled: true,
      nativeTracking: true,
      platformAvailable: true,
      sessionAvailable: true,
    );
    final populated =
        TripTrackingNativeSamplingPolicy.safeRecommendationSummary(
          recommendation: const TripSamplingRecommendation(
            mode: TripSamplingMode.balanced,
            interval: Duration(seconds: 5),
            minimumDisplacementMeters: 5,
          ),
          adaptiveSamplingEnabled: true,
          nativeTracking: true,
          platformAvailable: true,
          sessionAvailable: true,
        );

    final forgedEmpty =
        TripTrackingNativeSamplingSummaryValidation.fromSummary({
          ...empty,
          'mode': TripSamplingMode.precision.name,
          'intervalSeconds': 1,
          'minimumDisplacementMeters': 1,
        });
    final forgedPopulated =
        TripTrackingNativeSamplingSummaryValidation.fromSummary({
          ...populated,
          'mode': null,
        });

    expect(forgedEmpty.isRenderable, isFalse);
    expect(forgedPopulated.isRenderable, isFalse);
    expect(
      forgedEmpty.reasons,
      contains('native_sampling_recommendation_shape_mismatch'),
    );
    expect(
      forgedPopulated.reasons,
      contains('native_sampling_recommendation_shape_mismatch'),
    );
  });
}
