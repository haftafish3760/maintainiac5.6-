import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';

void main() {
  final start = DateTime.utc(2026, 7, 12, 12);

  TripLocationSample sample(
    double longitude,
    int seconds, {
    double accuracy = 5,
    double? speedMetersPerSecond,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speedMetersPerSecond,
  );

  TripActivityObservation walking(int seconds, {int confidence = 90}) =>
      TripActivityObservation(
        activity: TripActivity.walking,
        confidence: confidence,
        recordedAt: start.add(Duration(seconds: seconds)),
      );

  test('uses two-second precision only after vehicle speed reaches 15 mph', () {
    final engine = TripTrackingEngine();

    expect(
      engine
          .samplingRecommendation(
            speedMetersPerSecond: 7,
            vehicleMovementConfirmed: true,
          )
          .mode,
      TripSamplingMode.precision,
    );
    expect(
      engine
          .samplingRecommendation(
            speedMetersPerSecond: 7,
            vehicleMovementConfirmed: true,
          )
          .interval,
      const Duration(seconds: 2),
    );
  });

  test('an active trip starts balanced instead of waiting thirty seconds', () {
    final engine = TripTrackingEngine();

    expect(
      engine.samplingRecommendation(activeTrip: true).mode,
      TripSamplingMode.balanced,
    );
  });

  test('keeps low-speed lawn equipment in balanced tracking, not economy', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.lowSpeedEquipment,
    );

    final recommendation = engine.samplingRecommendation(
      speedMetersPerSecond: 3.6,
      vehicleMovementConfirmed: true,
    );

    expect(recommendation.mode, TripSamplingMode.balanced);
    expect(recommendation.interval, const Duration(seconds: 5));
  });

  test('precision sampling has hysteresis around the 15 mph threshold', () {
    final engine = TripTrackingEngine();

    final settled = engine.samplingRecommendation(
      speedMetersPerSecond: 6.0,
      vehicleMovementConfirmed: true,
      currentMode: TripSamplingMode.precision,
    );
    final downgrade = engine.samplingRecommendation(
      speedMetersPerSecond: 5.5,
      vehicleMovementConfirmed: true,
      currentMode: TripSamplingMode.precision,
    );

    expect(settled.mode, TripSamplingMode.precision);
    expect(downgrade.mode, TripSamplingMode.balanced);
  });

  test('unusable reported speed cannot promote precision GPS sampling', () {
    final engine = TripTrackingEngine(profile: TripTrackingProfile.roadVehicle);

    for (final speed in [double.nan, double.infinity, -1.0]) {
      final recommendation = engine.samplingRecommendation(
        speedMetersPerSecond: speed,
        vehicleMovementConfirmed: true,
        currentMode: TripSamplingMode.precision,
        activeTrip: true,
      );

      expect(recommendation.mode, TripSamplingMode.balanced);
    }
  });

  test('malformed persisted engine version fields recover safely', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 0,
      'walkingReviewSuggested': false,
      'schemaVersion': '2',
      'algorithmVersion': ' gps/v1 with spaces and ${'x' * 80} ',
    });
    final nonFinite = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 0,
      'walkingReviewSuggested': false,
      'schemaVersion': double.nan,
      'algorithmVersion': '\n\t',
    });

    expect(snapshot.schemaVersion, 1);
    expect(snapshot.algorithmVersion, isNot(contains('/')));
    expect(snapshot.algorithmVersion, hasLength(48));
    expect(nonFinite.schemaVersion, 1);
    expect(nonFinite.algorithmVersion, 'gps-v1');
  });

  test('malformed sampling thresholds do not force high-rate GPS', () {
    const policy = TripTrackingPolicy(
      precisionSpeedMetersPerSecond: 0,
      precisionExitSpeedMetersPerSecond: -1,
      lowSpeedMovementMetersPerSecond: double.infinity,
    );

    final parked = policy.samplingFor(
      speedMetersPerSecond: 0,
      vehicleMovementConfirmed: false,
      currentMode: TripSamplingMode.precision,
    );
    final moving = policy.samplingFor(
      speedMetersPerSecond: 7,
      vehicleMovementConfirmed: true,
    );

    expect(parked.mode, TripSamplingMode.economy);
    expect(moving.mode, TripSamplingMode.precision);
  });

  test('zero precision thresholds cannot force parked precision GPS', () {
    const policy = TripTrackingPolicy(
      precisionSpeedMetersPerSecond: 0,
      precisionExitSpeedMetersPerSecond: 0,
      lowSpeedMovementMetersPerSecond: 0,
    );

    final parked = policy.samplingFor(
      speedMetersPerSecond: 0,
      vehicleMovementConfirmed: true,
      currentMode: TripSamplingMode.precision,
    );

    expect(parked.mode, TripSamplingMode.balanced);
    expect(parked.interval, const Duration(seconds: 5));
  });

  test('malformed distance thresholds cannot turn GPS jitter into miles', () {
    final engine = TripTrackingEngine(
      policy: const TripTrackingPolicy(
        maximumHorizontalAccuracyMeters: double.nan,
        minimumMovementMeters: -1,
        accuracyEnvelopeMultiplier: -4,
        maximumGap: Duration.zero,
        maximumPlausibleSpeedMetersPerSecond: double.infinity,
        maximumReportedSpeedDisagreementMetersPerSecond: double.nan,
      ),
    );

    expect(engine.ingest(sample(-80, 0)).accepted, isTrue);
    final jitter = engine.ingest(sample(-80.00003, 5));

    expect(jitter.disposition, TripSampleDisposition.rejectedDrift);
    expect(engine.totalAcceptedMeters, 0);
  });

  test('malformed walking thresholds cannot invent an instant stop', () {
    final engine = TripTrackingEngine(
      policy: const TripTrackingPolicy(
        walkingConfirmationCount: 0,
        walkingConfirmationWindow: Duration.zero,
        walkingStopConfirmationDuration: Duration(days: -1),
      ),
    );

    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.999, 30, speedMetersPerSecond: 10));
    final decision = engine.ingest(sample(-79.9988, 45), activity: walking(45));

    expect(decision.disposition, TripSampleDisposition.excludedWalking);
    expect(engine.needsWalkingReview, isFalse);
    expect(engine.motionState, TripMotionState.stopCandidate);
  });

  test('malformed low battery GPS cutoffs fall back to twenty percent', () {
    for (final cutoff in const [-1, 0, 101]) {
      final decision = TripTrackingPolicy(lowBatteryGpsCutoffPercent: cutoff)
          .gpsBatteryDecision(
            batteryPercent: 19,
            isCharging: false,
            lowBatteryProtectionEnabled: true,
            lowBatteryOverrideEnabled: false,
            lowBatteryWarningDismissed: false,
          );

      expect(
        decision.status,
        TripGpsBatteryDecisionStatus.userPromptRequired,
        reason: 'cutoff $cutoff must not disable the default battery guard',
      );
      expect(decision.reasonCode, 'low_battery_requires_user_choice');
      expect(decision.toSafeSummary()['safetyCutoffPercent'], 20);
    }
  });

  test(
    'low battery GPS decision summary is actionable without raw battery data',
    () {
      final prompt = const TripTrackingPolicy().gpsBatteryDecision(
        batteryPercent: 19,
        isCharging: false,
        lowBatteryProtectionEnabled: true,
        lowBatteryOverrideEnabled: false,
        lowBatteryWarningDismissed: false,
      );
      final blocked = const TripTrackingPolicy().gpsBatteryDecision(
        batteryPercent: 18,
        isCharging: false,
        lowPowerModeEnabled: true,
        lowBatteryProtectionEnabled: true,
        lowBatteryOverrideEnabled: false,
        lowBatteryWarningDismissed: true,
      );

      expect(prompt.requiresUserChoice, isTrue);
      expect(prompt.toSafeSummary(), {
        'status': 'userPromptRequired',
        'reasonCode': 'low_battery_requires_user_choice',
        'batteryBucket': 'below_20',
        'safetyCutoffPercent': 20,
        'promptTitle': 'Battery below 20%',
        'promptBody':
            'GPS-assisted tracking is paused by default below the safety threshold. Continue only if you want GPS to keep running.',
        'allowsGps': false,
        'requiresUserChoice': true,
        'userCanOverride': true,
        'continueGpsActionLabel': 'Continue with GPS',
        'cancelGpsActionLabel': 'Cancel GPS',
        'doNotShowAgainAvailable': true,
        'settingsReversalAvailable': true,
        'defaultGpsPausesBelowCutoff': true,
        'userOverrideRequiresExplicitChoice': true,
        'batteryGuardCanBeChangedInSettings': true,
        'gpsTrackingCanRetryWhenCharging': true,
        'mapsRequiredForGps': false,
        'tripDataDeletionAllowed': false,
        'odometerRemainsCanonical': true,
        'preciseBatteryIncluded': false,
        'rawBatteryPayloadIncluded': false,
      });
      expect(blocked.isSavedBlock, isTrue);
      expect(blocked.toSafeSummary()['requiresUserChoice'], isFalse);
      expect(blocked.toSafeSummary()['doNotShowAgainAvailable'], isFalse);
      expect(blocked.toSafeSummary()['settingsReversalAvailable'], isTrue);
      expect(blocked.toSafeSummary().keys, isNot(contains('batteryPercent')));
    },
  );

  test('does not count stationary GPS jitter as miles', () {
    final engine = TripTrackingEngine();

    expect(engine.ingest(sample(-80, 0)).accepted, isTrue);
    final jitter = engine.ingest(sample(-80.00003, 5));

    expect(jitter.disposition, TripSampleDisposition.rejectedDrift);
    expect(engine.totalAcceptedMeters, 0);
  });

  test(
    'rejects non-finite GPS values before they can poison trip distance',
    () {
      final engine = TripTrackingEngine();

      expect(
        engine
            .ingest(
              TripLocationSample(
                latitude: double.nan,
                longitude: -80,
                recordedAt: start,
                horizontalAccuracyMeters: 5,
              ),
            )
            .disposition,
        TripSampleDisposition.rejectedInvalid,
      );
      expect(
        engine
            .ingest(
              TripLocationSample(
                latitude: 35,
                longitude: -80,
                recordedAt: start,
                horizontalAccuracyMeters: double.infinity,
              ),
            )
            .disposition,
        TripSampleDisposition.rejectedInvalid,
      );
      expect(engine.totalAcceptedMeters, 0);
    },
  );

  test('rejects out-of-range coordinates and non-positive accuracy', () {
    final engine = TripTrackingEngine();
    final invalidSamples = [
      TripLocationSample(
        latitude: 90.0001,
        longitude: -80,
        recordedAt: start,
        horizontalAccuracyMeters: 5,
      ),
      TripLocationSample(
        latitude: 35,
        longitude: -180.0001,
        recordedAt: start.add(const Duration(seconds: 5)),
        horizontalAccuracyMeters: 5,
      ),
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: start.add(const Duration(seconds: 10)),
        horizontalAccuracyMeters: 0,
      ),
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: start.add(const Duration(seconds: 15)),
        horizontalAccuracyMeters: -1,
      ),
    ];

    for (final invalidSample in invalidSamples) {
      expect(
        engine.ingest(invalidSample).disposition,
        TripSampleDisposition.rejectedInvalid,
      );
    }
    expect(engine.totalAcceptedMeters, 0);
  });

  test('mocked GPS locations cannot enter trip mileage', () {
    final engine = TripTrackingEngine();
    final decision = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: start,
        horizontalAccuracyMeters: 5,
        mockedLocation: true,
      ),
    );

    expect(decision.disposition, TripSampleDisposition.rejectedMockLocation);
    expect(engine.totalAcceptedMeters, 0);
  });

  test('future-dated walking evidence cannot suppress vehicle mileage', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0));

    final decision = engine.ingest(
      sample(-79.9998, 10),
      activity: TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 90,
        recordedAt: start.add(const Duration(seconds: 20)),
      ),
    );

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(decision.addedMeters, greaterThan(0));
    expect(engine.needsWalkingReview, isFalse);
  });

  test('stale walking evidence cannot suppress later vehicle mileage', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0));

    final decision = engine.ingest(sample(-79.9998, 60), activity: walking(1));

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(decision.addedMeters, greaterThan(0));
    expect(engine.needsWalkingReview, isFalse);
  });

  test(
    'accumulates credible low-speed movement after it clears accuracy noise',
    () {
      final engine = TripTrackingEngine(
        profile: TripTrackingProfile.lowSpeedEquipment,
      );

      engine.ingest(sample(-80, 0));
      expect(engine.ingest(sample(-79.9998, 5)).accepted, isTrue);
      expect(engine.totalAcceptedMeters, greaterThan(5));
    },
  );

  test('rejects poor accuracy without moving the accepted anchor', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    expect(
      engine.ingest(sample(-79.999, 5, accuracy: 66)).disposition,
      TripSampleDisposition.rejectedAccuracy,
    );
    expect(engine.ingest(sample(-79.9998, 20)).accepted, isTrue);
  });

  test('poor-accuracy samples still prevent an older fix being accepted', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    expect(
      engine.ingest(sample(-79.999, 20, accuracy: 66)).disposition,
      TripSampleDisposition.rejectedAccuracy,
    );
    expect(
      engine.ingest(sample(-79.9998, 10)).disposition,
      TripSampleDisposition.rejectedOutOfOrder,
    );
  });

  test('does not bridge a long location outage into false trip distance', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    final gap = engine.ingest(sample(-79.99, 121));

    expect(gap.disposition, TripSampleDisposition.rejectedGap);
    expect(engine.totalAcceptedMeters, 0);
  });

  test('rejects impossible location jumps', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    expect(
      engine.ingest(sample(-79.99, 2)).disposition,
      TripSampleDisposition.rejectedImplausibleSpeed,
    );
  });

  test('rejects a severe conflict between reported and implied speed', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0));
    final conflict = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.992,
        recordedAt: start.add(const Duration(seconds: 20)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 0,
      ),
    );

    expect(conflict.disposition, TripSampleDisposition.rejectedSpeedConflict);
    expect(engine.totalAcceptedMeters, 0);
  });

  test('rejected jumps cannot accumulate walking stop evidence', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.9998, 20));

    for (final seconds in const [22, 24, 26]) {
      final decision = engine.ingest(
        sample(-79.99 + (seconds * .01), seconds),
        activity: walking(seconds),
      );
      expect(
        decision.disposition,
        TripSampleDisposition.rejectedImplausibleSpeed,
      );
      expect(decision.walkingReviewSuggested, isFalse);
    }

    expect(engine.needsWalkingReview, isFalse);
  });

  test(
    'an impossible jump is re-anchored and cannot create a delayed bridge',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0));
      expect(
        engine.ingest(sample(-79.99, 2)).disposition,
        TripSampleDisposition.rejectedImplausibleSpeed,
      );
      expect(
        engine.ingest(sample(-79.9898, 30)).disposition,
        TripSampleDisposition.acceptedDistance,
      );
      expect(engine.totalAcceptedMeters, lessThan(30));
    },
  );

  test('rejects out-of-order samples without changing total distance', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.9998, 20));
    final total = engine.totalAcceptedMeters;

    expect(
      engine.ingest(sample(-79.9996, 10)).disposition,
      TripSampleDisposition.rejectedOutOfOrder,
    );
    expect(engine.totalAcceptedMeters, total);
  });

  test(
    'requires repeated high-confidence walking before suggesting review',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0));
      expect(
        engine
            .ingest(sample(-79.9998, 20), activity: walking(20))
            .walkingReviewSuggested,
        isFalse,
      );
      expect(
        engine
            .ingest(sample(-79.9996, 35), activity: walking(35))
            .walkingReviewSuggested,
        isFalse,
      );
      expect(
        engine
            .ingest(sample(-79.9994, 50), activity: walking(50))
            .walkingReviewSuggested,
        isTrue,
      );
    },
  );

  test(
    'does not let a low-confidence walking signal suppress a mower route',
    () {
      final engine = TripTrackingEngine(
        profile: TripTrackingProfile.lowSpeedEquipment,
      );

      engine.ingest(sample(-80, 0));
      final decision = engine.ingest(
        sample(-79.9998, 20),
        activity: walking(20, confidence: 40),
      );

      expect(decision.disposition, TripSampleDisposition.acceptedDistance);
      expect(decision.walkingReviewSuggested, isFalse);
    },
  );

  test(
    'strong walking after confirmation is excluded and surfaced for review',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0));
      engine.ingest(sample(-79.9998, 20), activity: walking(20));
      engine.ingest(sample(-79.9996, 35), activity: walking(35));
      engine.ingest(sample(-79.9994, 50), activity: walking(50));

      expect(
        engine.ingest(sample(-79.9992, 65), activity: walking(65)).disposition,
        TripSampleDisposition.excludedWalking,
      );
    },
  );

  test(
    'the first high-confidence walking point cannot inflate vehicle miles',
    () {
      final engine = TripTrackingEngine();
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );
      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      final distanceBeforeWalking = engine.totalAcceptedMeters;

      final decision = engine.ingest(
        sample(-79.9995, 30),
        activity: walking(30),
      );

      expect(decision.disposition, TripSampleDisposition.excludedWalking);
      expect(engine.totalAcceptedMeters, distanceBeforeWalking);
    },
  );

  test(
    'vehicle-speed evidence overrides a walking sensor misclassification',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0, speedMetersPerSecond: 8));
      final decision = engine.ingest(
        sample(-79.999, 20, speedMetersPerSecond: 8),
        activity: walking(20),
      );

      expect(decision.disposition, TripSampleDisposition.acceptedDistance);
      expect(decision.accepted, isTrue);
      expect(decision.walkingReviewSuggested, isFalse);
      expect(engine.motionState, TripMotionState.moving);
    },
  );

  test('walking before vehicle movement cannot count toward a later stop', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0), activity: walking(0));
    engine.ingest(sample(-79.995, 60));
    final decision = engine.ingest(sample(-79.995, 75), activity: walking(75));

    expect(decision.walkingReviewSuggested, isFalse);
    expect(engine.motionState, TripMotionState.stopCandidate);
  });

  test('automotive recognition clears an unconfirmed walking streak', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.9998, 20), activity: walking(20));
    engine.ingest(
      sample(-79.9996, 35),
      activity: TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start.add(const Duration(seconds: 35)),
      ),
    );
    final decision = engine.ingest(sample(-79.9994, 50), activity: walking(50));

    expect(decision.walkingReviewSuggested, isFalse);
  });

  test(
    'driving, walking at a real stop, then driving emits advisory motion',
    () {
      final engine = TripTrackingEngine();
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );

      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      expect(engine.motionState, TripMotionState.moving);

      engine.ingest(sample(-79.9997, 30), activity: walking(30));
      expect(engine.motionState, TripMotionState.stopCandidate);
      engine.ingest(sample(-79.9997, 45), activity: walking(45));
      engine.ingest(sample(-79.9997, 60), activity: walking(60));
      expect(engine.motionState, TripMotionState.stopped);
      expect(engine.needsWalkingReview, isTrue);

      engine.ingest(
        sample(-79.9994, 75),
        activity: TripActivityObservation(
          activity: TripActivity.automotive,
          confidence: 90,
          recordedAt: start.add(const Duration(seconds: 75)),
        ),
      );
      expect(engine.motionState, TripMotionState.moving);
    },
  );

  test('a traffic light without walking evidence is not an actual stop', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    for (final seconds in [30, 45, 60, 75]) {
      engine.ingest(sample(-79.9997, seconds));
    }

    expect(engine.motionState, TripMotionState.moving);
    expect(engine.needsWalkingReview, isFalse);
  });

  test('sustained vehicle-only waiting becomes review-safe stop candidate', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    for (final seconds in [30, 60, 90]) {
      engine.ingest(sample(-79.9997, seconds));
    }
    expect(engine.motionState, isNot(TripMotionState.stopCandidate));

    engine.ingest(sample(-79.9997, 135));
    expect(engine.motionState, TripMotionState.stopCandidate);
    expect(engine.needsWalkingReview, isFalse);

    engine.ingest(
      sample(-79.997, 160),
      activity: TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start.add(const Duration(seconds: 160)),
      ),
    );
    expect(engine.motionState, TripMotionState.moving);
  });

  test('road-style work profiles use conservative walking stop rules', () {
    for (final profile in const [
      TripTrackingProfile.roadVehicle,
      TripTrackingProfile.deliveryVehicle,
      TripTrackingProfile.contractorVehicle,
    ]) {
      final engine = TripTrackingEngine(profile: profile);
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );
      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      engine.ingest(sample(-79.9997, 30), activity: walking(30));
      engine.ingest(sample(-79.9997, 45), activity: walking(45));
      engine.ingest(sample(-79.9997, 60), activity: walking(60));

      expect(engine.motionState, TripMotionState.stopped, reason: profile.name);
      expect(engine.needsWalkingReview, isTrue, reason: profile.name);
    }
  });

  test('one reused walking classification cannot become a sustained stop', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);
    final oneWalkingClassification = walking(30);

    engine.ingest(sample(-79.9997, 30), activity: oneWalkingClassification);
    engine.ingest(sample(-79.9997, 45), activity: oneWalkingClassification);
    expect(engine.needsWalkingReview, isFalse);

    engine.ingest(sample(-79.9997, 60), activity: oneWalkingClassification);
    expect(engine.motionState, TripMotionState.stopCandidate);
    expect(engine.needsWalkingReview, isFalse);
  });

  test('fresh time-spaced walking classifications can suggest stop review', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    expect(engine.needsWalkingReview, isFalse);

    engine.ingest(sample(-79.9997, 60), activity: walking(60));
    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.needsWalkingReview, isTrue);
  });

  test(
    'walking evidence does not turn a low-speed equipment route into a stop',
    () {
      final engine = TripTrackingEngine(
        profile: TripTrackingProfile.lowSpeedEquipment,
      );
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );
      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      for (final seconds in [30, 45, 60]) {
        engine.ingest(sample(-79.9997, seconds), activity: walking(seconds));
      }

      expect(engine.needsWalkingReview, isFalse);
      expect(engine.motionState, TripMotionState.moving);
    },
  );

  test(
    'a reviewed walking cue clears without changing accepted trip distance',
    () {
      final engine = TripTrackingEngine();
      engine.ingest(sample(-80, 0));
      for (var index = 1; index <= 5; index++) {
        final seconds = index * 15;
        engine.ingest(
          sample(-80 + (index * .00012), seconds),
          activity: walking(seconds),
        );
      }
      final acceptedBeforeReview = engine.totalAcceptedMeters;
      expect(engine.needsWalkingReview, isTrue);

      engine.acknowledgeWalkingReview();

      expect(engine.needsWalkingReview, isFalse);
      expect(engine.motionState, TripMotionState.unknown);
      expect(engine.totalAcceptedMeters, acceptedBeforeReview);
    },
  );

  test('restart snapshot preserves distance but never bridges an outage', () {
    final original = TripTrackingEngine();
    original.ingest(sample(-80, 0));
    original.ingest(sample(-79.9998, 20));
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot.fromMap(original.snapshot.toMap()),
    );

    final totalBeforeGap = restored.totalAcceptedMeters;
    final decision = restored.ingest(sample(-79.99, 141));

    expect(decision.disposition, TripSampleDisposition.rejectedGap);
    expect(restored.totalAcceptedMeters, totalBeforeGap);
  });

  test(
    'coordinate-free diagnostics survive a snapshot and classify failures',
    () {
      final engine = TripTrackingEngine();
      engine.ingest(sample(-80, 0));
      engine.ingest(sample(-79.999, 5, accuracy: 120));
      engine.ingest(sample(-79.9998, 4));

      final restored = TripTrackingEngine.fromSnapshot(
        TripTrackingEngineSnapshot.fromMap(engine.snapshot.toMap()),
      );
      final diagnostics = restored.snapshot.diagnostics;

      expect(diagnostics.receivedSamples, 3);
      expect(diagnostics.acceptedSamples, 1);
      expect(diagnostics.rejectedSamples, 2);
      expect(
        diagnostics.dispositionCounts[TripSampleDisposition.rejectedAccuracy],
        1,
      );
      expect(
        diagnostics.dispositionCounts[TripSampleDisposition.rejectedOutOfOrder],
        1,
      );
    },
  );

  test('malformed persisted diagnostics cannot poison recovery', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 0,
      'diagnostics': {
        'receivedSamples': double.nan,
        'acceptedSamples': double.infinity,
        'dispositionCounts': {
          'rejectedAccuracy': double.nan,
          'acceptedDistance': -4,
          'unknownFutureDisposition': 99,
          7: 3,
        },
      },
    });

    final diagnostics = snapshot.diagnostics;

    expect(diagnostics.receivedSamples, 0);
    expect(diagnostics.acceptedSamples, 0);
    expect(diagnostics.rejectedSamples, 0);
    expect(diagnostics.dispositionCounts, isEmpty);
  });

  test('malformed accepted distance and diagnostic math recover safely', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 'one mile',
      'walkingReviewSuggested': false,
      'diagnostics': {'receivedSamples': 2, 'acceptedSamples': 5},
    });
    const inMemoryDiagnostics = TripTrackingDiagnostics(
      receivedSamples: 2,
      acceptedSamples: 5,
    );

    expect(snapshot.totalAcceptedMeters, isZero);
    expect(snapshot.diagnostics.receivedSamples, 2);
    expect(snapshot.diagnostics.acceptedSamples, isZero);
    expect(snapshot.diagnostics.rejectedSamples, 2);
    expect(inMemoryDiagnostics.rejectedSamples, 2);
  });

  test('restored diagnostics reject accepted count contradictions', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 0,
      'walkingReviewSuggested': false,
      'diagnostics': {
        'receivedSamples': 3,
        'acceptedSamples': 1,
        'dispositionCounts': {
          'acceptedAnchor': 1,
          'acceptedDistance': 1,
          'rejectedAccuracy': 1,
        },
      },
    });

    expect(snapshot.diagnostics.receivedSamples, 3);
    expect(snapshot.diagnostics.acceptedSamples, isZero);
    expect(snapshot.diagnostics.rejectedSamples, 3);
    expect(
      snapshot.diagnostics.dispositionCounts[TripSampleDisposition
          .acceptedAnchor],
      1,
    );
    expect(
      snapshot.diagnostics.dispositionCounts[TripSampleDisposition
          .acceptedDistance],
      1,
    );
  });

  test(
    'malformed recovery data never fabricates a GPS anchor or walk event',
    () {
      final snapshot = TripTrackingEngineSnapshot.fromMap({
        'totalAcceptedMeters': 17,
        'lastAccepted': {'latitude': 35.2, 'horizontalAccuracyMeters': 4},
        'walkingEvidence': [
          {'activity': 'walking', 'confidence': 95},
        ],
      });

      expect(snapshot.lastAccepted, isNull);
      expect(snapshot.walkingEvidence, isEmpty);
      expect(snapshot.totalAcceptedMeters, 17);
    },
  );

  test('restored observation timestamp cannot poison future samples', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot.fromMap({
        'lastAccepted': sample(-80, 0).toMap(),
        'lastObservedAt': start.add(const Duration(days: 30)).toIso8601String(),
        'totalAcceptedMeters': 0,
      }),
    );

    final decision = restored.ingest(sample(-79.9998, 20));

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(restored.totalAcceptedMeters, greaterThan(0));
  });

  test('last observed restore is discarded without a valid anchor', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'lastObservedAt': start.add(const Duration(days: 30)).toIso8601String(),
      'totalAcceptedMeters': 0,
    });
    final restored = TripTrackingEngine.fromSnapshot(snapshot);

    final decision = restored.ingest(sample(-80, 0));

    expect(snapshot.lastObservedAt, isNull);
    expect(decision.disposition, TripSampleDisposition.acceptedAnchor);
  });

  test('persisted walking evidence keeps only a bounded recent window', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 17,
      'walkingReviewSuggested': true,
      'walkingEvidence': [
        for (var i = 0; i < 20; i++)
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': DateTime.utc(2026, 7, 12, 12, i).toIso8601String(),
          },
      ],
    });
    final map = snapshot.toMap();
    final persistedEvidence = map['walkingEvidence'] as List<Object?>;

    expect(snapshot.walkingEvidence, hasLength(12));
    expect(snapshot.walkingEvidence.first.recordedAt.minute, 8);
    expect(persistedEvidence, hasLength(12));
  });

  test('non-finite in-memory snapshot distance cannot poison recovery', () {
    final restored = TripTrackingEngine.fromSnapshot(
      const TripTrackingEngineSnapshot(
        totalAcceptedMeters: double.nan,
        walkingReviewSuggested: false,
      ),
    );

    expect(restored.totalAcceptedMeters, isZero);
    expect(restored.ingest(sample(-80, 0)).accepted, isTrue);
    expect(restored.totalAcceptedMeters, isZero);
  });

  test('low-speed equipment restore ignores road walking-stop state', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot.fromMap({
        'totalAcceptedMeters': 17,
        'walkingReviewSuggested': true,
        'motionState': 'stopped',
        'walkingEvidence': [
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
          },
        ],
      }),
      profile: TripTrackingProfile.lowSpeedEquipment,
    );

    expect(restored.needsWalkingReview, isFalse);
    expect(restored.motionState, TripMotionState.unknown);
    expect(restored.snapshot.walkingEvidence, isEmpty);
  });
}
