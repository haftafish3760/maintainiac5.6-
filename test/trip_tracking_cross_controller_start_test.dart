import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test('two controller instances cannot create competing sessions', () async {
    final store = TripTrackingSessionStore.memory();
    final firstOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final secondOdometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final first = TripTrackingController(
      sessionStore: store,
      odometer: firstOdometer,
    );
    final second = TripTrackingController(
      sessionStore: store,
      odometer: secondOdometer,
    );
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    final at = DateTime.utc(2026, 7, 21, 16);

    final results = await Future.wait([
      first.start(
        tripId: 'competing_trip_1',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      ),
      second.start(
        tripId: 'competing_trip_2',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.roadVehicle,
        startedAt: at,
      ),
    ]);

    expect(results.where((result) => result), hasLength(1));
    expect(store.activeSession, isNotNull);
    expect(
      [
        firstOdometer,
        secondOdometer,
      ].where((odometer) => odometer.hasLiveTripProjection),
      hasLength(1),
    );
    final loser = results.first ? second : first;
    expect(loser.platformStatus, 'trip_already_active');
  });
}
