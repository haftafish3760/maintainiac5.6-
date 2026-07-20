import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_initial_fix_classifier.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);

  TripLocationSample sample({
    double latitude = 35,
    double longitude = -80,
    double accuracy = 5,
    DateTime? recordedAt,
    bool? mocked,
  }) => TripLocationSample(
    latitude: latitude,
    longitude: longitude,
    recordedAt: recordedAt ?? started.add(const Duration(seconds: 5)),
    horizontalAccuracyMeters: accuracy,
    mockedLocation: mocked,
  );

  TripInitialFixDecision classify(
    TripLocationSample? value, {
    bool precise = true,
    TripLocationSample? recent,
    TripMotionState motion = TripMotionState.unknown,
  }) => TripInitialFixClassifier.evaluate(
    sample: value,
    sessionStartedAt: started,
    receivedAt: started.add(const Duration(seconds: 10)),
    preciseLocationAuthorized: precise,
    recentKnownLocation: recent,
    motionState: motion,
  );

  test('fresh fixes are classified by bounded accuracy', () {
    expect(
      classify(sample()).classification,
      TripInitialFixClassification.freshPrecise,
    );
    expect(
      classify(sample(accuracy: 30)).classification,
      TripInitialFixClassification.freshModerate,
    );
    expect(
      classify(sample(accuracy: 60)).classification,
      TripInitialFixClassification.freshLowQuality,
    );
  });

  test(
    'cached, approximate, unavailable, and rejected fixes stay distinct',
    () {
      expect(
        classify(
          sample(recordedAt: started.subtract(const Duration(seconds: 1))),
        ).classification,
        TripInitialFixClassification.staleCached,
      );
      expect(
        classify(sample(), precise: false).classification,
        TripInitialFixClassification.approximateOnly,
      );
      expect(
        classify(null).classification,
        TripInitialFixClassification.unavailable,
      );
      expect(
        classify(sample(mocked: true)).classification,
        TripInitialFixClassification.rejected,
      );
      expect(
        classify(sample(accuracy: 80)).classification,
        TripInitialFixClassification.rejected,
      );
    },
  );

  test(
    'stationary teleport relationship is rejected but movement is provisional',
    () {
      final recent = sample(recordedAt: started);
      final distant = sample(latitude: 36, longitude: -81);

      expect(
        classify(distant, recent: recent).reasonCode,
        'initial_fix_rejected_relationship',
      );
      expect(
        classify(
          distant,
          recent: recent,
          motion: TripMotionState.moving,
        ).canAnchorSession,
        isTrue,
      );
    },
  );

  test('safe summary exposes confidence without coordinates or authority', () {
    final summary = classify(sample(accuracy: 30)).toSafeSummary();

    expect(summary['confidence'], TripTrackingConfidence.medium.name);
    expect(summary['odometerIsGlobalTruth'], isTrue);
    expect(summary['gpsCanMoveTripStartTime'], isFalse);
    expect(summary['coordinatesIncluded'], isFalse);
    expect(summary.toString(), isNot(contains('35')));
    expect(summary.toString(), isNot(contains('-80')));
  });
}
