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
    double? speedAccuracyMetersPerSecond,
    int? monotonicElapsedNanos,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
    speedMetersPerSecond: speedMetersPerSecond,
    speedAccuracyMetersPerSecond: speedAccuracyMetersPerSecond,
    monotonicElapsedNanos: monotonicElapsedNanos,
  );

  TripActivityObservation walking(int seconds, {int confidence = 90}) =>
      TripActivityObservation(
        activity: TripActivity.walking,
        confidence: confidence,
        recordedAt: start.add(Duration(seconds: seconds)),
      );

  test('malformed Android monotonic timestamps fail closed', () {
    final base = sample(-80, 0).toMap();

    expect(
      TripLocationSample.tryFromMap({...base, 'monotonicElapsedNanos': -1}),
      isNull,
    );
    expect(
      TripLocationSample.tryFromMap({...base, 'monotonicElapsedNanos': 1.5}),
      isNull,
    );
    expect(
      TripLocationSample.tryFromMap({
        ...base,
        'monotonicElapsedNanos': 1000000000,
      })?.monotonicElapsedNanos,
      1000000000,
    );
  });

  test('fractional native timestamps fail closed instead of being rounded', () {
    final base = sample(-80, 0).toMap();

    expect(
      TripLocationSample.tryFromMap({...base, 'recordedAt': 1783857600000.5}),
      isNull,
    );
    expect(
      TripActivityObservation.tryFromMap({
        'activity': 'walking',
        'confidence': 90,
        'recordedAt': 1783857600000.5,
      }),
      isNull,
    );
    expect(
      TripActivityObservation.tryFromMap({
        'activity': 'walking',
        'confidence': 90.5,
        'recordedAt': 1783857600000,
      }),
      isNull,
    );
  });

  test('malformed native speed accuracy fails closed', () {
    final base = sample(-80, 0).toMap();

    expect(
      TripLocationSample.tryFromMap({
        ...base,
        'speedAccuracyMetersPerSecond': -1,
      }),
      isNull,
    );
    expect(
      TripLocationSample.tryFromMap({
        ...base,
        'speedAccuracyMetersPerSecond': 1001,
      }),
      isNull,
    );
    expect(
      TripLocationSample.tryFromMap({
        ...base,
        'speedAccuracyMetersPerSecond': 2.5,
      })?.speedAccuracyMetersPerSecond,
      2.5,
    );
  });

  test('direct invalid speed accuracy cannot reach distance calculations', () {
    final engine = TripTrackingEngine();

    final decision = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -80,
        recordedAt: start,
        horizontalAccuracyMeters: 5,
        speedAccuracyMetersPerSecond: -1,
      ),
    );

    expect(decision.disposition, TripSampleDisposition.rejectedInvalid);
    expect(engine.totalAcceptedMeters, 0);
  });

  test('recovery clamps contradictory Android monotonic checkpoints', () {
    final anchor = sample(-80, 0, monotonicElapsedNanos: 1000000000);
    final recovered = TripTrackingEngineSnapshot.fromMap({
      'lastAccepted': anchor.toMap(),
      'lastObservedAt': anchor.recordedAt.toIso8601String(),
      'lastContinuousAt': anchor.recordedAt.toIso8601String(),
      'lastObservedMonotonicElapsedNanos': 999999999,
      'lastContinuousMonotonicElapsedNanos': 9999999999,
      'totalAcceptedMeters': 0,
      'walkingReviewSuggested': false,
      'vehicleMovementObserved': false,
      'diagnostics': const TripTrackingDiagnostics().toMap(),
      'schemaVersion': 1,
      'algorithmVersion': 'gps-v1',
    });

    expect(recovered.lastObservedMonotonicElapsedNanos, 1000000000);
    expect(recovered.lastContinuousMonotonicElapsedNanos, 1000000000);
  });

  test('uses two-second precision only after vehicle speed reaches 15 mph', () {
    final engine = TripTrackingEngine();

    expect(engine.odometerIsGlobalTruth, isTrue);
    expect(engine.calibrationRequiresTrustedGpsWindow, isTrue);
    expect(engine.poorGpsDaysExcludedFromCalibration, isTrue);
    expect(engine.engineCanCreateCalibration, isFalse);
    expect(engine.engineCanApplyCalibration, isFalse);
    expect(engine.engineCanConfirmOdometer, isFalse);
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

  test('malformed low battery GPS cutoffs fall back to fifteen percent', () {
    for (final cutoff in const [-1, 0, 101]) {
      final decision = TripTrackingPolicy(lowBatteryGpsCutoffPercent: cutoff)
          .gpsBatteryDecision(
            batteryPercent: 15,
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
      expect(decision.toSafeSummary()['safetyCutoffPercent'], 15);
    }
  });

  test(
    'low battery GPS decision summary is actionable without raw battery data',
    () {
      final prompt = const TripTrackingPolicy().gpsBatteryDecision(
        batteryPercent: 15,
        isCharging: false,
        lowBatteryProtectionEnabled: true,
        lowBatteryOverrideEnabled: false,
        lowBatteryWarningDismissed: false,
      );
      final blocked = const TripTrackingPolicy().gpsBatteryDecision(
        batteryPercent: 15,
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
        'safetyCutoffPercent': 15,
        'hardGpsShutdownPercent': 10,
        'promptTitle': 'Battery at or below 15%',
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
        'batteryDataTrustedAfterValidationOnly': true,
        'batteryDataCanDeleteTripRecords': false,
        'lowBatteryCanStopTextTripLog': false,
        'firebaseBatteryStateCanOverrideGpsDecision': false,
        'mapboxCanOverrideBatteryDecision': false,
        'malformedBatteryPayloadFailsSafe': true,
        'mapsRequiredForGps': false,
        'tripDataDeletionAllowed': false,
        'odometerRemainsCanonical': true,
        'odometerIsGlobalTruth': true,
        'preciseBatteryIncluded': false,
        'rawBatteryPayloadIncluded': false,
        'tokensIncluded': false,
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

  test('rejects malformed reported speeds before they can affect mileage', () {
    for (final speed in const [-0.1, double.nan, double.infinity, 70.1]) {
      final engine = TripTrackingEngine();
      engine.ingest(sample(-80, 0));

      final decision = engine.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -79.999,
          recordedAt: start.add(const Duration(seconds: 20)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: speed,
        ),
      );

      expect(decision.disposition, TripSampleDisposition.rejectedInvalid);
      expect(engine.totalAcceptedMeters, 0);
    }
  });

  test('allows maximum bounded reported speed through validation only', () {
    final engine = TripTrackingEngine(
      policy: const TripTrackingPolicy(
        maximumPlausibleSpeedMetersPerSecond: 100,
        maximumReportedSpeedDisagreementMetersPerSecond: 100,
      ),
    );
    engine.ingest(sample(-80, 0));

    final decision = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.99,
        recordedAt: start.add(const Duration(seconds: 20)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 70,
      ),
    );

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
  });

  test('unreliable reported speed cannot veto a credible GPS segment', () {
    final engine = TripTrackingEngine(
      policy: const TripTrackingPolicy(
        maximumReportedSpeedDisagreementMetersPerSecond: 5,
        maximumTrustedReportedSpeedAccuracyMetersPerSecond: 2,
      ),
    );
    engine.ingest(sample(-80, 0));

    final decision = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.9998,
        recordedAt: start.add(const Duration(seconds: 20)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 40,
        speedAccuracyMetersPerSecond: 20,
      ),
    );

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(engine.totalAcceptedMeters, greaterThan(10));
  });

  test('rejects impossible reported acceleration without adding mileage', () {
    final engine = TripTrackingEngine(
      policy: const TripTrackingPolicy(
        maximumPlausibleSpeedMetersPerSecond: 100,
        maximumReportedSpeedDisagreementMetersPerSecond: 100,
        maximumReportedAccelerationMetersPerSecondSquared: 5,
      ),
    );
    engine.ingest(sample(-80, 0, speedMetersPerSecond: 0));

    final decision = engine.ingest(
      TripLocationSample(
        latitude: 35,
        longitude: -79.9998,
        recordedAt: start.add(const Duration(seconds: 2)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 20,
      ),
    );

    expect(decision.disposition, TripSampleDisposition.rejectedSpeedConflict);
    expect(decision.addedMeters, 0);
    expect(engine.totalAcceptedMeters, 0);
  });

  test(
    'unreliable prior speed cannot create a false acceleration rejection',
    () {
      final engine = TripTrackingEngine(
        policy: const TripTrackingPolicy(
          maximumPlausibleSpeedMetersPerSecond: 100,
          maximumReportedSpeedDisagreementMetersPerSecond: 100,
          maximumReportedAccelerationMetersPerSecondSquared: 5,
          maximumTrustedReportedSpeedAccuracyMetersPerSecond: 2,
        ),
      );
      engine.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: start,
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 0,
          speedAccuracyMetersPerSecond: 20,
        ),
      );

      final decision = engine.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -79.9998,
          recordedAt: start.add(const Duration(seconds: 2)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 20,
          speedAccuracyMetersPerSecond: 1,
        ),
      );

      expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    },
  );

  test(
    'malformed acceleration policy falls back without rejecting a credible drive',
    () {
      final engine = TripTrackingEngine(
        policy: const TripTrackingPolicy(
          maximumPlausibleSpeedMetersPerSecond: 100,
          maximumReportedSpeedDisagreementMetersPerSecond: 100,
          maximumReportedAccelerationMetersPerSecondSquared: double.nan,
        ),
      );
      engine.ingest(sample(-80, 0, speedMetersPerSecond: 0));

      final decision = engine.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -79.9998,
          recordedAt: start.add(const Duration(seconds: 2)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 20,
        ),
      );

      expect(decision.disposition, TripSampleDisposition.acceptedDistance);
      expect(decision.addedMeters, greaterThan(10));
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

  test(
    'uses Android monotonic time to reject a wall-clock rollback outage',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0, monotonicElapsedNanos: 10000000000));
      final gap = engine.ingest(
        sample(-79.99, -60, monotonicElapsedNanos: 131000000000),
      );

      expect(gap.disposition, TripSampleDisposition.rejectedGap);
      expect(engine.totalAcceptedMeters, 0);
    },
  );

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

  test(
    'rejects stationary provider jitter without adding odometer mileage',
    () {
      final engine = TripTrackingEngine();
      engine.ingest(sample(-80, 0, speedMetersPerSecond: 0));

      final jitter = engine.ingest(
        sample(-79.999, 20, speedMetersPerSecond: 0.2),
      );

      expect(jitter.disposition, TripSampleDisposition.rejectedSpeedConflict);
      expect(jitter.addedMeters, 0);
      expect(engine.totalAcceptedMeters, 0);

      final resumed = engine.ingest(
        sample(-79.998, 40, speedMetersPerSecond: 4.6),
      );
      expect(resumed.disposition, TripSampleDisposition.acceptedDistance);
      expect(resumed.addedMeters, greaterThan(75));
    },
  );

  test('unreliable stationary speed cannot create a vehicle-only stop cue', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
      policy: const TripTrackingPolicy(
        maximumTrustedReportedSpeedAccuracyMetersPerSecond: 2,
      ),
    );
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    for (final seconds in const [30, 60, 90, 120]) {
      final decision = engine.ingest(
        sample(
          -79.9997,
          seconds,
          speedMetersPerSecond: 0.2,
          speedAccuracyMetersPerSecond: 20,
        ),
      );
      expect(decision.disposition, TripSampleDisposition.rejectedDrift);
      expect(engine.motionState, TripMotionState.moving);
    }
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

  test('unsafe walking jump bursts cannot create a later stop review', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0));
    engine.ingest(sample(-79.9998, 20));

    for (final seconds in const [22, 24, 26, 28]) {
      final rejected = engine.ingest(
        sample(-79.5 + (seconds * .01), seconds, speedMetersPerSecond: 0),
        activity: walking(seconds),
      );
      expect(
        rejected.disposition,
        TripSampleDisposition.rejectedImplausibleSpeed,
      );
      expect(rejected.walkingReviewSuggested, isFalse);
      expect(rejected.motionState, isNot(TripMotionState.stopped));
    }

    final resumed = engine.ingest(sample(-79.9996, 60));

    expect(resumed.walkingReviewSuggested, isFalse);
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

  test('Android monotonic time survives a backward wall-clock adjustment', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 10, monotonicElapsedNanos: 10000000000));
    final decision = engine.ingest(
      sample(-79.9998, -50, monotonicElapsedNanos: 30000000000),
    );

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(engine.totalAcceptedMeters, greaterThan(0));
  });

  test('Android monotonic time rebases after a device clock epoch reset', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0, monotonicElapsedNanos: 120000000000));
    final decision = engine.ingest(
      sample(-79.9998, 20, monotonicElapsedNanos: 1000000000),
    );

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(engine.snapshot.lastObservedMonotonicElapsedNanos, 1000000000);
    expect(engine.totalAcceptedMeters, greaterThan(0));
  });

  test('a monotonic clock reset still preserves a material recovery gap', () {
    final engine = TripTrackingEngine();

    engine.ingest(sample(-80, 0, monotonicElapsedNanos: 120000000000));
    final gap = engine.ingest(
      sample(-79.99, 121, monotonicElapsedNanos: 1000000000),
    );

    expect(gap.disposition, TripSampleDisposition.rejectedGap);
    expect(engine.totalAcceptedMeters, 0);
    expect(
      engine
          .ingest(sample(-79.9898, 141, monotonicElapsedNanos: 21000000000))
          .disposition,
      TripSampleDisposition.acceptedDistance,
    );
  });

  test(
    'Android monotonic time disambiguates duplicate wall-clock timestamps',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0, monotonicElapsedNanos: 10000000000));
      expect(
        engine
            .ingest(sample(-79.9998, 0, monotonicElapsedNanos: 30000000000))
            .disposition,
        TripSampleDisposition.acceptedDistance,
      );
      expect(engine.totalAcceptedMeters, greaterThan(0));
    },
  );

  test('persisted Android monotonic time remains an ordering boundary', () {
    final engine = TripTrackingEngine();
    engine.ingest(sample(-80, 0, monotonicElapsedNanos: 20000000000));
    final restored = TripTrackingEngine.fromSnapshot(engine.snapshot);

    expect(
      restored
          .ingest(sample(-79.9998, -40, monotonicElapsedNanos: 40000000000))
          .disposition,
      TripSampleDisposition.acceptedDistance,
    );
    expect(
      restored
          .ingest(sample(-79.9996, 20, monotonicElapsedNanos: 30000000000))
          .disposition,
      TripSampleDisposition.rejectedOutOfOrder,
    );
  });

  test(
    'rejects duplicate samples without changing distance or stop evidence',
    () {
      final engine = TripTrackingEngine();

      engine.ingest(sample(-80, 0));
      engine.ingest(sample(-79.9998, 20));
      final total = engine.totalAcceptedMeters;
      final duplicate = engine.ingest(
        sample(-79.9998, 20),
        activity: walking(20),
      );

      expect(duplicate.disposition, TripSampleDisposition.rejectedOutOfOrder);
      expect(duplicate.addedMeters, 0);
      expect(duplicate.walkingReviewSuggested, isFalse);
      expect(engine.totalAcceptedMeters, total);
      expect(engine.needsWalkingReview, isFalse);
    },
  );

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
    'a return to the vehicle after walking cannot create false road miles',
    () {
      final engine = TripTrackingEngine();
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );
      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      final distanceBeforeWalk = engine.totalAcceptedMeters;

      expect(
        engine.ingest(sample(-79.9987, 60), activity: walking(60)).disposition,
        TripSampleDisposition.excludedWalking,
      );
      final returnDecision = engine.ingest(sample(-79.9997, 75));

      expect(returnDecision.disposition, TripSampleDisposition.rejectedDrift);
      expect(engine.totalAcceptedMeters, distanceBeforeWalk);
      expect(
        engine
            .ingest(
              sample(-79.9994, 90),
              activity: TripActivityObservation(
                activity: TripActivity.automotive,
                confidence: 90,
                recordedAt: start.add(const Duration(seconds: 90)),
              ),
            )
            .disposition,
        TripSampleDisposition.acceptedDistance,
      );
    },
  );

  test('a restored engine keeps its vehicle anchor after an excluded walk', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);
    final distanceBeforeWalk = engine.totalAcceptedMeters;

    expect(
      engine.ingest(sample(-79.9987, 60), activity: walking(60)).disposition,
      TripSampleDisposition.excludedWalking,
    );

    final restored = TripTrackingEngine.fromSnapshot(engine.snapshot);
    final returnDecision = restored.ingest(sample(-79.9997, 75));

    expect(returnDecision.disposition, TripSampleDisposition.rejectedDrift);
    expect(restored.totalAcceptedMeters, distanceBeforeWalk);
  });

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

  test('buffered walking evidence survives sparse location callbacks', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    for (final seconds in [30, 45, 60]) {
      expect(
        engine.recordActivityEvidence(
          walking(seconds),
          observedAt: start.add(Duration(seconds: seconds)),
        ),
        isTrue,
      );
    }
    final decision = engine.ingest(sample(-79.9997, 60));

    expect(decision.walkingReviewSuggested, isTrue);
    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.totalAcceptedMeters, greaterThan(0));
  });

  test(
    'buffered walking evidence survives local recovery before the next fix',
    () {
      final engine = TripTrackingEngine();
      final automotive = TripActivityObservation(
        activity: TripActivity.automotive,
        confidence: 90,
        recordedAt: start,
      );
      engine.ingest(sample(-80, 0), activity: automotive);
      engine.ingest(sample(-79.9997, 15), activity: automotive);
      for (final seconds in [30, 45, 60]) {
        engine.recordActivityEvidence(
          walking(seconds),
          observedAt: start.add(Duration(seconds: seconds)),
        );
      }

      final restored = TripTrackingEngine.fromSnapshot(engine.snapshot);
      final decision = restored.ingest(sample(-79.9997, 60));

      expect(decision.walkingReviewSuggested, isTrue);
      expect(restored.motionState, TripMotionState.stopped);
      expect(restored.totalAcceptedMeters, engine.totalAcceptedMeters);
    },
  );

  test('stale or future buffered walking evidence cannot create a stop', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);

    expect(
      engine.recordActivityEvidence(
        walking(30),
        observedAt: start.add(const Duration(seconds: 120)),
      ),
      isFalse,
    );
    expect(
      engine.recordActivityEvidence(
        walking(180),
        observedAt: start.add(const Duration(seconds: 30)),
      ),
      isFalse,
    );
    final decision = engine.ingest(sample(-79.9997, 60));

    expect(decision.walkingReviewSuggested, isFalse);
    expect(engine.motionState, isNot(TripMotionState.stopped));
  });

  test('a delayed walking batch cannot stop the vehicle later', () {
    final engine = TripTrackingEngine();
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    engine.ingest(sample(-80, 0), activity: automotive);
    engine.ingest(sample(-79.9997, 15), activity: automotive);
    for (final seconds in [30, 45, 60]) {
      engine.recordActivityEvidence(
        walking(seconds),
        observedAt: start.add(Duration(seconds: seconds)),
      );
    }

    engine.ingest(sample(-79.9997, 180));

    expect(engine.motionState, isNot(TripMotionState.stopped));
  });

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

  test(
    'a long vehicle-only wait remains protected without clean drive proof',
    () {
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
      expect(engine.motionState, isNot(TripMotionState.stopCandidate));
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
    },
  );

  test('vehicle-only fallback rejects interrupted GPS evidence', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    for (final entry in const [
      (0, -80.0),
      (15, -79.9995),
      (30, -79.9990),
      (45, -79.9985),
      (60, -79.9980),
    ]) {
      engine.ingest(
        sample(entry.$2, entry.$1, speedMetersPerSecond: 3),
        activity: entry.$1 == 0 ? automotive : null,
      );
    }

    for (final seconds in [90, 180, 270, 360, 450, 540, 570]) {
      engine.ingest(sample(-79.9980, seconds, speedMetersPerSecond: .2));
    }

    expect(engine.motionState, TripMotionState.unknown);
    expect(engine.needsWalkingReview, isFalse);
  });

  test('a GPS outage cannot bridge an old vehicle-only wait into a stop', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );
    final automotive = TripActivityObservation(
      activity: TripActivity.automotive,
      confidence: 90,
      recordedAt: start,
    );
    for (final entry in const [
      (0, -80.0),
      (15, -79.9995),
      (30, -79.9990),
      (45, -79.9985),
      (60, -79.9980),
    ]) {
      engine.ingest(
        sample(entry.$2, entry.$1, speedMetersPerSecond: 3),
        activity: entry.$1 == 0 ? automotive : null,
      );
    }
    engine.ingest(sample(-79.9980, 90, speedMetersPerSecond: .2));
    final outage = engine.ingest(
      sample(-79.9980, 300, speedMetersPerSecond: .2),
    );
    engine.ingest(sample(-79.9980, 390, speedMetersPerSecond: .2));

    expect(outage.disposition, TripSampleDisposition.rejectedGap);
    expect(
      engine.snapshot.stationaryStartedAt,
      start.add(const Duration(seconds: 390)),
    );
    expect(engine.motionState, isNot(TripMotionState.stopCandidate));
  });

  test(
    'stationary GPS conflicts cannot invent a vehicle-only stop candidate',
    () {
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
      final drivenMeters = engine.totalAcceptedMeters;

      for (final entry in const [
        (30, -79.9987),
        (60, -79.9977),
        (90, -79.9967),
      ]) {
        final decision = engine.ingest(
          sample(entry.$2, entry.$1, speedMetersPerSecond: 0.2),
        );
        expect(
          decision.disposition,
          TripSampleDisposition.rejectedSpeedConflict,
        );
        expect(engine.motionState, isNot(TripMotionState.stopCandidate));
      }

      final stopped = engine.ingest(
        sample(-79.9957, 135, speedMetersPerSecond: 0.2),
      );
      expect(stopped.disposition, TripSampleDisposition.rejectedSpeedConflict);
      expect(engine.motionState, isNot(TripMotionState.stopCandidate));
      expect(engine.totalAcceptedMeters, drivenMeters);
      expect(engine.needsWalkingReview, isFalse);
    },
  );

  test(
    'vehicle-only wait remains protected after safe engine snapshot restore',
    () {
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

      final restored = TripTrackingEngine.fromSnapshot(
        TripTrackingEngineSnapshot.fromMap(engine.snapshot.toMap()),
        profile: TripTrackingProfile.rideshareVehicle,
      );
      restored.ingest(sample(-79.9997, 135));

      expect(restored.motionState, isNot(TripMotionState.stopCandidate));
      expect(restored.needsWalkingReview, isFalse);
    },
  );

  test('malformed stationary restore cannot invent vehicle-only stop', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot.fromMap({
        'lastAccepted': sample(-80, 0).toMap(),
        'lastObservedAt': start
            .add(const Duration(seconds: 20))
            .toIso8601String(),
        'totalAcceptedMeters': 0,
        'walkingReviewSuggested': false,
        'motionState': 'moving',
        'vehicleMovementObserved': true,
        'stationaryStartedAt': start
            .add(const Duration(days: -2))
            .toIso8601String(),
      }),
      profile: TripTrackingProfile.rideshareVehicle,
    );

    restored.ingest(sample(-80, 90));
    expect(restored.motionState, isNot(TripMotionState.stopCandidate));
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
    final recoveryAnchor = TripLocationSample(
      latitude: 35,
      longitude: -80,
      recordedAt: start.add(const Duration(minutes: 18)),
      horizontalAccuracyMeters: 5,
    );
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 17,
      'walkingReviewSuggested': true,
      'vehicleMovementObserved': true,
      'lastAccepted': recoveryAnchor.toMap(),
      'lastObservedAt': start
          .add(const Duration(minutes: 19))
          .toIso8601String(),
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

  test(
    'recovery sanitizes unordered, duplicate, and future walking evidence',
    () {
      final snapshot = TripTrackingEngineSnapshot.fromMap({
        'lastAccepted': sample(-80, 0).toMap(),
        'lastObservedAt': start
            .add(const Duration(seconds: 30))
            .toIso8601String(),
        'vehicleMovementObserved': true,
        'walkingReviewSuggested': true,
        'motionState': 'stopped',
        'walkingEvidence': [
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': start
                .add(const Duration(seconds: 20))
                .toIso8601String(),
          },
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': start
                .add(const Duration(seconds: 10))
                .toIso8601String(),
          },
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': start
                .add(const Duration(seconds: 20))
                .toIso8601String(),
          },
          {
            'activity': 'walking',
            'confidence': 95,
            'recordedAt': start
                .add(const Duration(minutes: 5))
                .toIso8601String(),
          },
        ],
      });

      expect(snapshot.walkingEvidence.map((item) => item.recordedAt), [
        start.add(const Duration(seconds: 10)),
        start.add(const Duration(seconds: 20)),
      ]);
      expect(snapshot.walkingReviewSuggested, isTrue);
      expect(snapshot.motionState, TripMotionState.stopped);
    },
  );

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

  test('direct recovery input cannot restore a future walking stop', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot(
        lastAccepted: sample(-80, 0),
        lastObservedAt: start.add(const Duration(seconds: 30)),
        totalAcceptedMeters: 17,
        vehicleMovementObserved: true,
        walkingReviewSuggested: true,
        motionState: TripMotionState.stopped,
        walkingEvidence: [
          TripActivityObservation(
            activity: TripActivity.walking,
            confidence: 95,
            recordedAt: start.add(const Duration(minutes: 5)),
          ),
        ],
      ),
    );

    expect(restored.snapshot.walkingEvidence, isEmpty);
    expect(restored.needsWalkingReview, isFalse);
    expect(restored.motionState, TripMotionState.unknown);
  });

  test('direct recovery cannot restore an expired walking stop', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot(
        lastAccepted: sample(-79.9997, 180),
        lastObservedAt: start.add(const Duration(seconds: 180)),
        totalAcceptedMeters: 17,
        vehicleMovementObserved: true,
        walkingReviewSuggested: true,
        motionState: TripMotionState.stopped,
        walkingEvidence: [walking(30), walking(45), walking(60)],
      ),
    );

    expect(restored.snapshot.walkingEvidence, isEmpty);
    expect(restored.needsWalkingReview, isFalse);
    expect(restored.motionState, TripMotionState.unknown);
  });

  test('direct recovery input cannot restore a future stationary start', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot(
        lastAccepted: sample(-80, 0),
        lastObservedAt: start.add(const Duration(seconds: 30)),
        totalAcceptedMeters: 17,
        vehicleMovementObserved: true,
        walkingReviewSuggested: false,
        motionState: TripMotionState.stopCandidate,
        stationaryStartedAt: start.add(const Duration(minutes: 5)),
      ),
    );

    expect(restored.snapshot.stationaryStartedAt, isNull);
    expect(restored.motionState, TripMotionState.unknown);
  });

  test('direct recovery input cannot poison the observed timestamp', () {
    final restored = TripTrackingEngine.fromSnapshot(
      TripTrackingEngineSnapshot(
        lastAccepted: sample(-80, 0),
        lastObservedAt: start.add(const Duration(days: 30)),
        totalAcceptedMeters: 17,
        walkingReviewSuggested: false,
        vehicleMovementObserved: true,
      ),
    );

    final decision = restored.ingest(sample(-79.9998, 20));

    expect(decision.disposition, TripSampleDisposition.acceptedDistance);
    expect(restored.totalAcceptedMeters, greaterThan(17));
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

  test('malformed recovery motion cannot invent a stopped trip', () {
    final snapshot = TripTrackingEngineSnapshot.fromMap({
      'totalAcceptedMeters': 0,
      'vehicleMovementObserved': false,
      'motionState': 'stopped',
      'walkingReviewSuggested': true,
      'walkingEvidence': [
        {
          'activity': 'walking',
          'confidence': 95,
          'recordedAt': DateTime.utc(2026, 7, 12, 12).toIso8601String(),
        },
      ],
    });
    final restored = TripTrackingEngine.fromSnapshot(snapshot);

    expect(snapshot.motionState, TripMotionState.unknown);
    expect(snapshot.walkingReviewSuggested, isFalse);
    expect(restored.motionState, TripMotionState.unknown);
    expect(restored.needsWalkingReview, isFalse);
  });

  test(
    'vehicle-only stop candidate restore needs a bounded stationary start',
    () {
      final withoutStationaryStart = TripTrackingEngineSnapshot.fromMap({
        'lastAccepted': sample(-80, 0).toMap(),
        'lastObservedAt': start
            .add(const Duration(minutes: 2))
            .toIso8601String(),
        'totalAcceptedMeters': 12,
        'vehicleMovementObserved': true,
        'motionState': 'stopCandidate',
      });
      final withStationaryStart = TripTrackingEngineSnapshot.fromMap({
        'lastAccepted': sample(-80, 0).toMap(),
        'lastObservedAt': start
            .add(const Duration(minutes: 2))
            .toIso8601String(),
        'totalAcceptedMeters': 12,
        'vehicleMovementObserved': true,
        'stationaryStartedAt': start
            .add(const Duration(minutes: 2))
            .toIso8601String(),
        'motionState': 'stopCandidate',
      });

      expect(withoutStationaryStart.motionState, TripMotionState.unknown);
      expect(withStationaryStart.motionState, TripMotionState.stopCandidate);
    },
  );
}
