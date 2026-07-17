import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final start = DateTime.utc(2026, 7, 12, 12);

  TripLocationSample sample(
    double longitude,
    int seconds, {
    double accuracy = 5,
  }) => TripLocationSample(
    latitude: 35,
    longitude: longitude,
    recordedAt: start.add(Duration(seconds: seconds)),
    horizontalAccuracyMeters: accuracy,
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

  test('road-style work profiles use conservative walking stop rules', () {
    for (final profile in const [
      TripTrackingProfile.roadVehicle,
      TripTrackingProfile.rideshareVehicle,
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

  test('one walking classification needs sustained stationary evidence', () {
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
}
