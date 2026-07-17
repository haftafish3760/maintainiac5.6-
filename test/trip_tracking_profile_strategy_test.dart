import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_engine.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_policy.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_profile_strategy.dart';

void main() {
  final start = DateTime.utc(2026, 7, 17, 8);

  TripLocationSample sample(double longitude, int seconds) =>
      TripLocationSample(
        latitude: 35,
        longitude: longitude,
        recordedAt: start.add(Duration(seconds: seconds)),
        horizontalAccuracyMeters: 5,
        speedMetersPerSecond: 0,
      );

  TripActivityObservation walking(int seconds) => TripActivityObservation(
    activity: TripActivity.walking,
    confidence: 95,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  TripActivityObservation automotive(int seconds) => TripActivityObservation(
    activity: TripActivity.automotive,
    confidence: 95,
    recordedAt: start.add(Duration(seconds: seconds)),
  );

  test('rideshare profile requires stronger walking evidence than delivery', () {
    final rideshare = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.rideshareVehicle,
    );
    final delivery = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.deliveryVehicle,
    );

    expect(rideshare.walkingConfirmationCount, greaterThan(delivery.walkingConfirmationCount));
    expect(
      rideshare.walkingStopConfirmationDuration,
      greaterThan(delivery.walkingStopConfirmationDuration),
    );
    expect(rideshare.stopReviewReasonCode, contains('rideshare'));
    expect(rideshare.dashboardModeToken, 'gig_driver');
    expect(rideshare.recommendedActivityRecognition, isTrue);
    expect(rideshare.stopDetectionSummary, contains('stays in the vehicle'));
  });

  test('delivery walking stop evidence can identify a real stop quickly', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.deliveryVehicle,
    );

    engine.ingest(sample(-80, 0), activity: automotive(0));
    engine.ingest(sample(-79.9997, 15), activity: automotive(15));
    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    engine.ingest(sample(-79.9997, 60), activity: walking(60));

    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.needsWalkingReview, isTrue);
  });

  test('rideshare does not treat a short passenger stop as a completed stop', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    engine.ingest(sample(-80, 0), activity: automotive(0));
    engine.ingest(sample(-79.9997, 15), activity: automotive(15));
    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    engine.ingest(sample(-79.9997, 60), activity: walking(60));

    expect(engine.motionState, TripMotionState.stopCandidate);
    expect(engine.needsWalkingReview, isFalse);
  });

  test('rideshare eventually accepts sustained walking stop evidence', () {
    final engine = TripTrackingEngine(
      profile: TripTrackingProfile.rideshareVehicle,
    );

    engine.ingest(sample(-80, 0), activity: automotive(0));
    engine.ingest(sample(-79.9997, 15), activity: automotive(15));
    engine.ingest(sample(-79.9997, 30), activity: walking(30));
    engine.ingest(sample(-79.9997, 45), activity: walking(45));
    engine.ingest(sample(-79.9997, 60), activity: walking(60));
    engine.ingest(sample(-79.9997, 75), activity: walking(75));

    expect(engine.motionState, TripMotionState.stopped);
    expect(engine.needsWalkingReview, isTrue);
  });

  test('profile dashboard hints distinguish gig contractor and equipment modes', () {
    final delivery = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.deliveryVehicle,
    );
    final contractor = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.contractorVehicle,
    );
    final equipment = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.lowSpeedEquipment,
    );

    expect(delivery.dashboardModeToken, 'gig_driver');
    expect(contractor.dashboardModeToken, 'contractor');
    expect(equipment.dashboardModeToken, 'default');
    expect(equipment.recommendedActivityRecognition, isFalse);
    expect(equipment.usesWalkingStopEvidence, isFalse);
  });

  test('profile strategy clamps malformed walking thresholds safely', () {
    final strategy = TripTrackingProfileStrategy.forProfile(
      TripTrackingProfile.contractorVehicle,
      policy: const TripTrackingPolicy(
        walkingConfirmationCount: 0,
        walkingStopConfirmationDuration: Duration(days: -1),
      ),
    );

    expect(strategy.walkingConfirmationCount, 3);
    expect(strategy.walkingStopConfirmationDuration, const Duration(seconds: 20));
  });
}
