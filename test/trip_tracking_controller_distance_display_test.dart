import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  test(
    'display miles convert GPS meters without changing odometer truth',
    () async {
      final odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 12000,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: odometer,
      );
      addTearDown(controller.dispose);
      addTearDown(odometer.dispose);
      final startedAt = DateTime.utc(2026, 7, 22, 12);

      expect(
        await controller.start(
          tripId: 'distance_display',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          profileId: 'profile_1',
          startedAt: startedAt,
        ),
        isTrue,
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -80,
          recordedAt: startedAt,
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 20,
        ),
      );
      await controller.ingest(
        TripLocationSample(
          latitude: 35,
          longitude: -79.9823,
          recordedAt: startedAt.add(const Duration(seconds: 90)),
          horizontalAccuracyMeters: 5,
          speedMetersPerSecond: 20,
        ),
      );

      expect(controller.acceptedMeters, greaterThan(1500));
      expect(
        controller.acceptedMiles,
        closeTo(controller.acceptedMeters / 1609.344, 1e-9),
      );
      expect(odometer.confirmedReading, 12000);
      expect(odometer.hasLiveTripProjection, isTrue);
      expect(odometer.reading, greaterThanOrEqualTo(odometer.confirmedReading));
    },
  );
}
