import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'coordinator never silently replaces an active Bluetooth vehicle',
    () async {
      final links = TripTrackingBluetoothVehicleLinkStore.memory();
      final now = DateTime.utc(2026, 7, 21, 12);
      await links.save(
        TripTrackingBluetoothVehicleLink(
          deviceId: 'head-unit-1',
          vehicleId: 'vehicle_1',
          createdAt: now,
        ),
      );
      await links.save(
        TripTrackingBluetoothVehicleLink(
          deviceId: 'head-unit-2',
          vehicleId: 'vehicle_2',
          createdAt: now,
        ),
      );
      const settings = TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      );
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
        clockNow: () => now,
      );

      expect(
        controller
            .evaluateBluetoothVehicleIdentity(
              deviceId: 'head-unit-1',
              settings: settings,
              linkStore: links,
            )
            .disposition,
        BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
      );

      expect(
        await controller.start(
          tripId: 'bluetooth_vehicle_lock',
          vehicleId: 'vehicle_1',
          profile: TripTrackingProfile.roadVehicle,
          startedAt: now,
        ),
        isTrue,
      );
      final sameVehicle = controller.evaluateBluetoothVehicleIdentity(
        deviceId: 'head-unit-1',
        settings: settings,
        linkStore: links,
      );
      final differentVehicle = controller.evaluateBluetoothVehicleIdentity(
        deviceId: 'head-unit-2',
        settings: settings,
        linkStore: links,
      );

      expect(
        sameVehicle.disposition,
        BluetoothVehicleMatchDisposition.alreadyActiveVehicle,
      );
      expect(sameVehicle.canSwitchVehicle, isFalse);
      expect(
        differentVehicle.disposition,
        BluetoothVehicleMatchDisposition.blockedByActiveTrip,
      );
      expect(differentVehicle.canSwitchVehicle, isFalse);
      expect(differentVehicle.requiresUserConfirmation, isFalse);
      expect(differentVehicle.toSafeSummary()['deviceIdIncluded'], isFalse);
    },
  );

  test('durable unfinished session blocks Bluetooth auto switch', () async {
    final now = DateTime.utc(2026, 7, 21, 13);
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    await links.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: 'head-unit-2',
        vehicleId: 'vehicle_2',
        createdAt: now,
      ),
    );
    final sessions = TripTrackingSessionStore.memory();
    await sessions.save(
      TripTrackingSessionRecord(
        id: 'unfinished_trip',
        vehicleId: 'vehicle_1',
        startingOdometer: 1000,
        profile: TripTrackingProfile.roadVehicle,
        startedAt: now.subtract(const Duration(hours: 1)),
        updatedAt: now,
        lifecycleState: TripTrackingSessionLifecycleState.awaitingReview,
        engineSnapshot: const TripTrackingEngineSnapshot(
          totalAcceptedMeters: 1000,
          walkingReviewSuggested: false,
        ),
      ),
    );
    final controller = TripTrackingController(
      sessionStore: sessions,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );

    final decision = controller.evaluateBluetoothVehicleIdentity(
      deviceId: 'head-unit-2',
      settings: const TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      ),
      linkStore: links,
    );
    expect(
      decision.disposition,
      BluetoothVehicleMatchDisposition.blockedByUnfinishedSession,
    );
    expect(decision.canSwitchVehicle, isFalse);
  });
}
