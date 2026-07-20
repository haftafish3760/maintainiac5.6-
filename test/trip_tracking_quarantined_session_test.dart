import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_quarantined_session.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  final started = DateTime.utc(2026, 7, 20, 12);

  TripTrackingSessionRecord session() => TripTrackingSessionRecord(
    id: 'trip_quarantine',
    vehicleId: 'vehicle_1',
    profileId: 'profile_1',
    startingOdometer: 1000,
    profile: TripTrackingProfile.roadVehicle,
    startedAt: started,
    updatedAt: started.add(const Duration(minutes: 2)),
    lifecycleState: TripTrackingSessionLifecycleState.failedUnrecoverable,
    engineSnapshot: const TripTrackingEngineSnapshot(
      totalAcceptedMeters: 1609.344,
      walkingReviewSuggested: false,
      vehicleMovementObserved: true,
    ),
  );

  test(
    'quarantine preserves full evidence before releasing active ownership',
    () async {
      final store = TripTrackingSessionStore.memory();
      await store.save(session());

      expect(
        await store.quarantineActiveSession(
          sessionId: 'trip_quarantine',
          reasonCode: 'unsafe_session_recovery_boundary',
          quarantinedAtUtc: started.add(const Duration(minutes: 3)),
        ),
        isTrue,
      );

      expect(store.activeSession, isNull);
      expect(store.quarantinedSessions, hasLength(1));
      final quarantined = store.quarantinedSessions.single;
      expect(quarantined.sessionId, 'trip_quarantine');
      expect(quarantined.sessionPayload['vehicleId'], 'vehicle_1');
      expect(
        (quarantined.sessionPayload['engineSnapshot']
            as Map)['totalAcceptedMeters'],
        1609.344,
      );
      expect(quarantined.toMap()['evidencePreserved'], isTrue);
      expect(quarantined.toMap()['automaticDeletionAllowed'], isFalse);

      await store.clear();
      expect(store.quarantinedSessions, hasLength(1));
      expect(
        await store.quarantineActiveSession(
          sessionId: 'trip_quarantine',
          reasonCode: 'unsafe_session_recovery_boundary',
        ),
        isFalse,
      );
    },
  );

  test('malformed quarantine envelopes are isolated', () {
    final valid = TripTrackingQuarantinedSession(
      sessionId: 'trip_quarantine',
      revision: session().revision,
      sessionPayload: session().toMap(),
      reasonCode: 'unsafe_session_recovery_boundary',
      quarantinedAtUtc: started,
    ).toMap();

    expect(TripTrackingQuarantinedSession.tryFromMap(valid), isNotNull);
    expect(
      TripTrackingQuarantinedSession.tryFromMap({
        ...valid,
        'automaticDeletionAllowed': true,
      }),
      isNull,
    );
    expect(
      TripTrackingQuarantinedSession.tryFromMap({
        ...valid,
        'session': {1: 'non_string_key'},
      }),
      isNull,
    );
  });
}
