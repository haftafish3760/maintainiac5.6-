import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';

void main() {
  test('untrusted legacy activity timestamps cannot create stop evidence', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.deliveryVehicle,
    );
    final start = DateTime.utc(2026, 7, 18, 12);

    engine.ingest(_sample(start, -80, 0, speed: 9));
    engine.ingest(_sample(start, -79.999, 20, speed: 9));
    final decision = engine.ingest(
      _sample(start, -79.9989, 45),
      activity: TripActivityObservation(
        activity: TripActivity.walking,
        confidence: 95,
        recordedAt: DateTime.utc(1970),
      ),
    );

    expect(decision.disposition, isNot(TripSampleDisposition.excludedWalking));
    expect(engine.needsWalkingReview, isFalse);
    expect(engine.motionState, TripMotionState.moving);
  });

  test('trusted activity summaries never expose raw sensor details', () {
    final summary = TripActivityObservation(
      activity: TripActivity.walking,
      confidence: 92,
      recordedAt: DateTime.utc(2026, 7, 18, 12),
    ).toSafeSummary();

    expect(summary['canSupportStopReview'], isTrue);
    expect(summary['activityRecognitionRequiresOptIn'], isTrue);
    expect(summary['activityCanCreateOfficialStop'], isFalse);
    expect(summary['activityCanEndTripAutomatically'], isFalse);
    expect(summary['requiresAcceptedVehicleMovement'], isTrue);
    expect(summary['preciseLocationIncluded'], isFalse);
    expect(summary['preciseTimestampIncluded'], isFalse);
    expect(summary.toString(), isNot(contains('2026-07-18')));
  });
}

TripLocationSample _sample(
  DateTime start,
  double longitude,
  int seconds, {
  double? speed,
}) => TripLocationSample(
  latitude: 35,
  longitude: longitude,
  recordedAt: start.add(Duration(seconds: seconds)),
  horizontalAccuracyMeters: 5,
  speedMetersPerSecond: speed,
);
