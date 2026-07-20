import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('two coordinators cannot claim duplicate active sessions', () async {
    final store = TripTrackingSessionStore.memory();
    final first = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      activeProfileId: () => 'profile_1',
    );
    final second = TripTrackingController(
      sessionStore: store,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
      activeProfileId: () => 'profile_1',
    );

    final starts = await Future.wait([
      first.start(
        tripId: 'trip_first',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
      ),
      second.start(
        tripId: 'trip_second',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
      ),
    ]);

    expect(starts.where((started) => started), hasLength(1));
    expect(store.activeSession, isNotNull);
    expect(store.transitionEventsFor(store.activeSession!.id), hasLength(1));
    final loser = starts.first ? second : first;
    expect(loser.platformStatus, 'active_session_exists');
  });

  test(
    'recovery refuses to bind an unfinished trip to another profile',
    () async {
      final store = TripTrackingSessionStore.memory();
      final owner = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        activeProfileId: () => 'profile_owner',
      );
      expect(
        await owner.start(
          tripId: 'trip_profile_bound',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
        ),
        isTrue,
      );

      final otherProfile = TripTrackingController(
        sessionStore: store,
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        activeProfileId: () => 'profile_other',
      );

      expect(await otherProfile.restore(), isFalse);
      expect(otherProfile.platformStatus, 'profile_mismatch');
      expect(store.activeSession?.id, 'trip_profile_bound');
    },
  );
}
