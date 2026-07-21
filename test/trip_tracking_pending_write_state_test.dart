import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'memory checkpoint preserves recovery and profile fields without pending write',
    () async {
      final now = DateTime.utc(2026, 7, 21, 12);
      final store = TripTrackingSessionStore.memory();
      await store.save(
        TripTrackingSessionRecord(
          id: 'write_state_trip',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.contractorVehicle,
          profileId: 'job_profile_1',
          startedAt: now,
          updatedAt: now,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
          recoveryCount: 3,
          revision: 4,
        ),
      );

      expect(store.pendingWriteState, TripTrackingPendingWriteState.none);
      expect(store.activeSession?.effectiveProfileId, 'job_profile_1');
      expect(store.activeSession?.recoveryCount, 3);
      expect(store.activeSession?.revision, 4);

      await store.clear();
      expect(store.activeSession, isNull);
      expect(store.pendingWriteState, TripTrackingPendingWriteState.none);
    },
  );
}
