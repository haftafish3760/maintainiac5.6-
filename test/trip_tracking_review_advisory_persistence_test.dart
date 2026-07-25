import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final startedAt = DateTime.utc(2026, 7, 20, 8);
  final finishedAt = DateTime.utc(2026, 7, 20, 9);

  TripTrackingAdvisoryEvent advisory({
    String id = 'stop_1',
    int minute = 30,
    String sessionId = 'trip_stops',
    String vehicleId = 'vehicle_1',
    TripTrackingProfile profile = TripTrackingProfile.deliveryVehicle,
  }) => TripTrackingAdvisoryEvent(
    id: id,
    type: TripTrackingAdvisoryType.probableStop,
    sessionId: sessionId,
    vehicleId: vehicleId,
    profile: profile,
    detectedAt: startedAt.add(Duration(minutes: minute)),
    evidenceStartedAt: startedAt.add(Duration(minutes: minute - 1)),
    evidenceEndedAt: startedAt.add(Duration(minutes: minute)),
    confidence: TripTrackingConfidence.high,
    suggestedAction: 'review_stop',
    disposition: TripTrackingAdvisoryDisposition.confirmed,
  );

  TripTrackingReviewRecord review({
    List<TripTrackingAdvisoryEvent>? advisories,
    List<TripTrackingSessionTransitionAudit>? transitionAudits,
    List<TripTrackingPermissionEvidence>? permissionHistory,
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
    transitionAudits: transitionAudits ?? const [],
    permissionHistory: permissionHistory ?? const [],
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

  test('completed review preserves all valid audit evidence', () {
    final transitionAudits = List.generate(
      36,
      (index) => TripTrackingSessionTransitionAudit(
        id: 'audit_$index',
        sessionId: 'trip_stops',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.deliveryVehicle,
        profileId: 'profile_1',
        fromState: TripTrackingSessionLifecycleState.ready,
        toState: TripTrackingSessionLifecycleState.starting,
        eventTimestamp: startedAt.add(Duration(seconds: index)),
        sequenceNumber: index + 1,
        reasonCode: 'gps_session_transition_allowed',
        initiatingSource: 'controller',
        revision: index + 1,
        permissionState: 'permission_granted',
        confidenceState: 'healthy',
        trackingQualityMode: 'high_quality',
      ),
    );
    final permissionHistory = List.generate(
      30,
      (index) => TripTrackingPermissionEvidence(
        observedAt: startedAt.add(Duration(minutes: index)),
        state: index.isEven ? 'always' : 'denied',
        preciseLocation: index.isEven,
        canTrackInBackground: index.isEven,
        source: 'native_event',
      ),
    );
    final restored = TripTrackingReviewRecord.fromMap(
      review(
        advisories: List.generate(
          40,
          (index) => advisory(id: 'stop_$index', minute: index + 1),
        ),
        transitionAudits: transitionAudits,
        permissionHistory: permissionHistory,
      ).toMap(),
    );

    expect(restored.advisories, hasLength(40));
    expect(restored.transitionAudits, hasLength(36));
    expect(restored.permissionHistory, hasLength(30));
    expect(restored.advisories.first.id, 'stop_0');
    expect(restored.transitionAudits.first.id, 'audit_0');
    expect(
      restored.permissionHistory.first.observedAt,
      permissionHistory.first.observedAt,
    );
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
