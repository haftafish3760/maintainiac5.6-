import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_initial_fix_classifier.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

TripLocationSample sample(
  DateTime at, {
  double accuracy = 5,
  double lon = -80,
}) => TripLocationSample(
  latitude: 35,
  longitude: lon,
  recordedAt: at,
  horizontalAccuracyMeters: accuracy,
  speedMetersPerSecond: 0,
);

void main() {
  const classifier = TripInitialFixClassifier();
  final now = DateTime.utc(2026, 7, 21, 12);

  test('classifies all usable initial fix quality bands', () {
    expect(
      classifier
          .classify(
            sample: sample(now, accuracy: 5),
            receivedAt: now,
            locationServicesAvailable: true,
            preciseLocationAuthorized: true,
          )
          .quality,
      TripInitialFixQuality.freshPrecise,
    );
    expect(
      classifier
          .classify(
            sample: sample(now, accuracy: 20),
            receivedAt: now,
            locationServicesAvailable: true,
            preciseLocationAuthorized: true,
          )
          .quality,
      TripInitialFixQuality.freshModerate,
    );
    expect(
      classifier
          .classify(
            sample: sample(now, accuracy: 70),
            receivedAt: now,
            locationServicesAvailable: true,
            preciseLocationAuthorized: true,
          )
          .quality,
      TripInitialFixQuality.freshLowQuality,
    );
  });

  test('rejects stale cached, approximate, and implausible fixes', () {
    final stale = classifier.classify(
      sample: sample(now.subtract(const Duration(minutes: 5))),
      receivedAt: now,
      locationServicesAvailable: true,
      preciseLocationAuthorized: true,
    );
    final approximate = classifier.classify(
      sample: sample(now),
      receivedAt: now,
      locationServicesAvailable: true,
      preciseLocationAuthorized: false,
    );
    final implausible = classifier.classify(
      sample: sample(now.add(const Duration(seconds: 1)), lon: -70),
      receivedAt: now.add(const Duration(seconds: 1)),
      locationServicesAvailable: true,
      preciseLocationAuthorized: true,
      recentKnownLocation: sample(now),
    );

    expect(stale.quality, TripInitialFixQuality.staleCached);
    expect(stale.mayUseProvisionally, isFalse);
    expect(approximate.quality, TripInitialFixQuality.approximateOnly);
    expect(implausible.quality, TripInitialFixQuality.rejected);
    expect(implausible.canConfirmMileage, isFalse);
  });

  test('assessment survives coordinate-free persistence', () {
    final assessment = classifier.classify(
      sample: sample(now),
      receivedAt: now,
      locationServicesAvailable: true,
      preciseLocationAuthorized: true,
    );
    final restored = TripInitialFixAssessment.tryFromMap(assessment.toMap());

    expect(restored?.quality, TripInitialFixQuality.freshPrecise);
    expect(restored?.mayUseProvisionally, isTrue);
    expect(restored?.canConfirmMileage, isFalse);
    expect(assessment.toMap().containsKey('latitude'), isFalse);
    expect(assessment.toMap().containsKey('longitude'), isFalse);
  });

  test('snapshot preserves bounded initial-fix recovery history', () {
    final stale = classifier.classify(
      sample: sample(now.subtract(const Duration(minutes: 5))),
      receivedAt: now,
      locationServicesAvailable: true,
      preciseLocationAuthorized: true,
    );
    final fresh = classifier.classify(
      sample: sample(now.add(const Duration(seconds: 10))),
      receivedAt: now.add(const Duration(seconds: 10)),
      locationServicesAvailable: true,
      preciseLocationAuthorized: true,
    );
    final restored = TripTrackingEngineSnapshot.fromMap(
      TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
        initialFixAssessment: fresh,
        initialFixHistory: [stale, fresh],
      ).toMap(),
    );

    expect(restored.initialFixHistory.map((item) => item.quality), [
      TripInitialFixQuality.staleCached,
      TripInitialFixQuality.freshPrecise,
    ]);
    expect(
      restored.initialFixAssessment?.quality,
      TripInitialFixQuality.freshPrecise,
    );
    final recoveredEngine = TripTrackingEngine.fromSnapshot(
      restored,
      profile: TripTrackingProfile.roadVehicle,
    );
    expect(recoveredEngine.initialFixHistory.length, 2);
    expect(restored.toMap().toString(), isNot(contains('latitude')));
    expect(restored.toMap().toString(), isNot(contains('longitude')));
  });

  test(
    'snapshot isolates malformed fix history and migrates legacy evidence',
    () {
      final fresh = classifier.classify(
        sample: sample(now),
        receivedAt: now,
        locationServicesAvailable: true,
        preciseLocationAuthorized: true,
      );
      final legacyMap = TripTrackingEngineSnapshot(
        totalAcceptedMeters: 0,
        walkingReviewSuggested: false,
        initialFixAssessment: fresh,
      ).toMap()..remove('initialFixHistory');
      final legacy = TripTrackingEngineSnapshot.fromMap(legacyMap);
      expect(legacy.initialFixHistory.single.quality, fresh.quality);

      final malformedMap = Map<String, Object?>.from(legacyMap)
        ..['initialFixHistory'] = <Object?>[
          {'quality': 'not_real'},
          fresh.toMap(),
          'invalid',
        ];
      final sanitized = TripTrackingEngineSnapshot.fromMap(malformedMap);
      expect(sanitized.initialFixHistory.length, 1);
      expect(sanitized.initialFixAssessment?.quality, fresh.quality);
    },
  );
}
