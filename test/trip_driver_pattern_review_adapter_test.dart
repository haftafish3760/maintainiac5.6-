import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_driver_pattern_assistant.dart';
import 'package:maintaniac/shared/trip_tracking/trip_driver_pattern_review_adapter.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('adapter learns only confirmed odometer and user stop history', () {
    final now = DateTime.utc(2026, 7, 22, 12);
    final observations = TripDriverPatternReviewAdapter.fromReviews([
      _review(now: now, confirmed: true, vehicleId: 'vehicle_1'),
      _review(now: now, confirmed: false, vehicleId: 'vehicle_1'),
      _review(now: now, confirmed: true, vehicleId: 'vehicle_2'),
    ]);

    final decision = TripDriverPatternAssistant.evaluate(
      observations: observations,
      vehicleId: 'vehicle_1',
      profileId: TripTrackingProfile.deliveryVehicle.name,
      nowUtc: now.add(const Duration(hours: 2)),
      minimumReviewedTrips: 3,
    );

    expect(decision.reviewedTripCount, 1);
    expect(decision.ignoredObservationCount, 2);
    expect(observations.first.confirmedOdometerDistanceMiles, 12);
    expect(observations.first.confirmedStopCount, 1);
    expect(
      observations.first.longestConfirmedStop,
      const Duration(minutes: 20),
    );
  });

  test('adapter stays bounded before evaluation', () {
    final now = DateTime.utc(2026, 7, 22, 12);
    final shuffledOldestFirst = List.generate(
      300,
      (index) => _review(
        now: now.subtract(Duration(days: 299 - index)),
        confirmed: true,
        vehicleId: 'vehicle_1',
        id: 'trip_$index',
      ),
    );
    final observations = TripDriverPatternReviewAdapter.fromReviews(
      shuffledOldestFirst,
    );
    expect(observations, hasLength(256));
    expect(observations.first.endedAtUtc, now);
    expect(
      observations.last.endedAtUtc,
      now.subtract(const Duration(days: 255)),
    );
  });

  test('invalid review limit stays bounded to one newest review', () {
    final now = DateTime.utc(2026, 7, 22, 12);
    final observations = TripDriverPatternReviewAdapter.fromReviews([
      _review(
        now: now.subtract(const Duration(days: 1)),
        confirmed: true,
        vehicleId: 'vehicle_1',
        id: 'older',
      ),
      _review(now: now, confirmed: true, vehicleId: 'vehicle_1', id: 'newest'),
    ], maximumReviews: 0);

    expect(observations, hasLength(1));
    expect(observations.single.sessionId, 'newest');
  });
}

TripTrackingReviewRecord _review({
  required DateTime now,
  required bool confirmed,
  required String vehicleId,
  String id = 'trip',
}) {
  final started = now.subtract(const Duration(hours: 1));
  final stopAt = started.add(const Duration(minutes: 20));
  return TripTrackingReviewRecord(
    id: id,
    vehicleId: vehicleId,
    startingOdometer: 1000,
    estimatedEndingOdometer: 1012,
    confirmedEndingOdometer: confirmed ? 1012 : null,
    odometerConfirmedAt: confirmed ? now : null,
    profile: TripTrackingProfile.deliveryVehicle,
    profileId: TripTrackingProfile.deliveryVehicle.name,
    startedAt: started,
    finishedAt: now,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 0,
      walkingReviewSuggested: false,
    ),
    tripEvents: [
      TripManualEvent(
        id: 'user:stop',
        type: TripManualEventType.stop,
        occurredAt: stopAt,
        userConfirmed: true,
      ),
    ],
    advisories: [
      TripTrackingAdvisoryEvent(
        id: 'stop',
        type: TripTrackingAdvisoryType.probableStop,
        sessionId: id,
        vehicleId: vehicleId,
        profile: TripTrackingProfile.deliveryVehicle,
        detectedAt: stopAt,
        evidenceStartedAt: stopAt,
        evidenceEndedAt: stopAt,
        confidence: TripTrackingConfidence.high,
        suggestedAction: 'review',
        disposition: TripTrackingAdvisoryDisposition.confirmed,
      ),
      TripTrackingAdvisoryEvent(
        id: 'resume',
        type: TripTrackingAdvisoryType.resumedMovement,
        sessionId: id,
        vehicleId: vehicleId,
        profile: TripTrackingProfile.deliveryVehicle,
        detectedAt: stopAt.add(const Duration(minutes: 20)),
        evidenceStartedAt: stopAt.add(const Duration(minutes: 20)),
        evidenceEndedAt: stopAt.add(const Duration(minutes: 20)),
        confidence: TripTrackingConfidence.high,
        suggestedAction: 'continue',
      ),
    ],
  );
}
