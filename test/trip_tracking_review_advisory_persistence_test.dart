import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 20, 8);
  final finishedAt = DateTime.utc(2026, 7, 20, 9);

  TripTrackingAdvisoryEvent advisory({String sessionId = 'trip_stops'}) =>
      TripTrackingAdvisoryEvent(
        id: 'stop_1',
        type: TripTrackingAdvisoryType.probableStop,
        sessionId: sessionId,
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
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

    expect(restored.schemaVersion, 5);
    expect(restored.advisories, hasLength(1));
    expect(
      restored.advisories.single.disposition,
      TripTrackingAdvisoryDisposition.confirmed,
    );
    expect(store.pendingReviews.single.advisories.single.id, 'stop_1');
  });

  test('review rejects advisory evidence belonging to another session', () {
    final store = TripTrackingSessionStore.memory();

    expect(
      () => store.saveReview(
        review(advisories: [advisory(sessionId: 'different_trip')]),
      ),
      throwsArgumentError,
    );
  });

  test(
    'legacy review migration preserves the trip without inventing stops',
    () {
      final map = review().toMap()
        ..['schemaVersion'] = 3
        ..remove('advisories');
      final restored = TripTrackingReviewRecord.fromMap(map);

      expect(restored.schemaVersion, 5);
      expect(restored.advisories, isEmpty);
      expect(restored.hasValidTimeline, isTrue);
    },
  );
}
