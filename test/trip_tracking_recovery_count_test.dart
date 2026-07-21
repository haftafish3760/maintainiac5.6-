import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'separate recovery runs increment count and revision monotonically',
    () async {
      final now = DateTime.utc(2026, 7, 21, 12);
      final store = TripTrackingSessionStore.memory();
      await store.save(
        TripTrackingSessionRecord(
          id: 'recovery_count_trip',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'work_profile_1',
          startedAt: now,
          updatedAt: now,
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 0,
            walkingReviewSuggested: false,
          ),
          revision: 1,
        ),
      );

      TripTrackingController controller() => TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        clockNow: () => now,
      );

      final first = controller();
      expect(await first.restore(), isTrue);
      expect(store.activeSession?.recoveryCount, 1);
      expect(store.activeSession?.revision, 2);

      final second = controller();
      expect(await second.restore(), isTrue);
      expect(store.activeSession?.recoveryCount, 2);
      expect(store.activeSession?.revision, 3);
      expect(store.activeSession?.effectiveProfileId, 'work_profile_1');
    },
  );
}
