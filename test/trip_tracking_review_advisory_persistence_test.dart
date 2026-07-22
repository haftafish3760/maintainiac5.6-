import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 20, 8);
  final finishedAt = DateTime.utc(2026, 7, 20, 9);

  TripTrackingAdvisoryEvent advisory({
    String sessionId = 'trip_stops',
    String vehicleId = 'vehicle_1',
    TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
  }) => TripTrackingAdvisoryEvent(
    id: 'stop_1',
    type: TripTrackingAdvisoryType.probableStop,
    sessionId: sessionId,
    vehicleId: vehicleId,
    profile: profile,
    detectedAt: startedAt.add(const Duration(minutes: 30)),
    evidenceStartedAt: startedAt.add(const Duration(minutes: 25)),
    evidenceEndedAt: startedAt.add(const Duration(minutes: 30)),
    confidence: TripTrackingConfidence.high,
    suggestedAction: 'review_stop',
    disposition: TripTrackingAdvisoryDisposition.confirmed,
  );

  TripTrackingReviewRecord review({
    List<TripTrackingAdvisoryEvent>? advisories,
  }) => TripTrackingReviewRecord(
    id: 'trip_stops',
    vehicleId: 'vehicle_1',
    profileId: 'profile_1',
    startingOdometer: 1000,
    estimatedEndingOdometer: 1010,
    profile: TripTrackingProfile.deliveryVehicle,
    startedAt: startedAt,
    finishedAt: finishedAt,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 10 * 1609.344,
      walkingReviewSuggested: false,
    ),
    advisories: advisories ?? [advisory()],
  );

  test('completed review preserves confirmed stop ancestry', () async {
    final restored = TripTrackingReviewRecord.fromMap(review().toMap());
    final store = TripTrackingSessionStore.memory();
    await store.saveReview(restored);

    expect(restored.advisories, hasLength(1));
    expect(
      restored.advisories.single.disposition,
      TripTrackingAdvisoryDisposition.confirmed,
    );
    expect(store.pendingReviews.single.advisories.single.id, 'stop_1');
  });

  test('review rejects advisory evidence belonging to another trip', () async {
    final store = TripTrackingSessionStore.memory();

    await expectLater(
      store.saveReview(
        review(advisories: [advisory(sessionId: 'different_trip')]),
      ),
      throwsArgumentError,
    );
  });

  test(
    'review rejects advisory evidence with another vehicle or profile',
    () async {
      final store = TripTrackingSessionStore.memory();

      await expectLater(
        store.saveReview(
          review(advisories: [advisory(vehicleId: 'vehicle_2')]),
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.saveReview(
          review(
            advisories: [advisory(profile: TripTrackingProfile.roadVehicle)],
          ),
        ),
        throwsArgumentError,
      );
    },
  );
}
