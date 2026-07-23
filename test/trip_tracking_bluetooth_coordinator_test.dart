import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'connection coordinator switches once and absorbs duplicate callbacks',
    () async {
      final now = DateTime.utc(2026, 7, 23, 9);
      final links = TripTrackingBluetoothVehicleLinkStore.memory();
      await links.save(
        TripTrackingBluetoothVehicleLink(
          deviceId: 'head-unit-2',
          vehicleId: 'vehicle_2',
          createdAt: now,
        ),
      );
      var activeVehicleId = 'vehicle_1';
      var switchCalls = 0;
      final coordinator = TripTrackingBluetoothCoordinator(
        linkStore: links,
        settings: () => const TripTrackingSettings(
          bluetoothVehicleRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        ),
        hasActiveSession: () => false,
        hasUnfinishedStoredSession: () => false,
        currentVehicleId: () => activeVehicleId,
        switchVehicle: (vehicleId) async {
          switchCalls += 1;
          activeVehicleId = vehicleId;
          return true;
        },
      );
      final observation = DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'head-unit-2',
        connected: true,
        observedAtUtc: now,
      );

      final results = await Future.wait([
        coordinator.handleConnection(observation, nowUtc: now),
        coordinator.handleConnection(observation, nowUtc: now),
      ]);

      expect(
        results.first.disposition,
        BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
      );
      expect(
        results.last.disposition,
        BluetoothVehicleMatchDisposition.alreadyActiveVehicle,
      );
      expect(activeVehicleId, 'vehicle_2');
      expect(switchCalls, 1);
    },
  );

  test('connection coordinator fails safely and remains usable', () async {
    final now = DateTime.utc(2026, 7, 23, 10);
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    await links.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: 'head-unit-2',
        vehicleId: 'vehicle_2',
        createdAt: now,
      ),
    );
    var settingsFail = true;
    var activeVehicleId = 'vehicle_1';
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () {
        if (settingsFail) throw StateError('settings unavailable');
        return const TripTrackingSettings(
          bluetoothVehicleRecognitionEnabled: true,
          automaticVehicleSwitchEnabled: true,
        );
      },
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => activeVehicleId,
      switchVehicle: (vehicleId) async {
        activeVehicleId = vehicleId;
        return true;
      },
    );
    final observation = DeviceBluetoothConnectionObservation(
      opaqueDeviceId: 'head-unit-2',
      connected: true,
      observedAtUtc: now,
    );

    final failed = await coordinator.handleConnection(observation, nowUtc: now);
    settingsFail = false;
    final recovered = await coordinator.handleConnection(
      observation,
      nowUtc: now,
    );

    expect(failed.disposition, BluetoothVehicleMatchDisposition.noMatch);
    expect(failed.safeReason, 'bluetooth_vehicle_context_unavailable');
    expect(failed.vehicleId, isNull);
    expect(
      recovered.disposition,
      BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
    );
    expect(activeVehicleId, 'vehicle_2');
  });

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

  test(
    'Bluetooth link storage failure falls back to manual vehicle choice',
    () {
      final links = _RecoveringBluetoothLinkStore();
      final controller = TripTrackingController(
        sessionStore: TripTrackingSessionStore.memory(),
        odometer: GlobalOdometerController(
          vehicleId: 'vehicle_1',
          initialReading: 1000,
        ),
      );
      addTearDown(controller.dispose);
      const settings = TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      );

      final failed = controller.evaluateBluetoothVehicleIdentity(
        deviceId: 'head-unit-1',
        settings: settings,
        linkStore: links,
      );
      expect(failed.disposition, BluetoothVehicleMatchDisposition.noMatch);
      expect(failed.canSwitchVehicle, isFalse);
      expect(failed.safeReason, 'bluetooth_vehicle_link_storage_unavailable');
      expect(controller.platformStatus, 'bluetooth_link_storage_failed');

      links.fail = false;
      final recovered = controller.evaluateBluetoothVehicleIdentity(
        deviceId: 'head-unit-1',
        settings: settings,
        linkStore: links,
      );
      expect(recovered.disposition, BluetoothVehicleMatchDisposition.noMatch);
      expect(controller.platformStatus, isNull);
      expect(controller.platformError, isNull);
    },
  );

  test('Bluetooth switching pauses while trip storage state is unknown', () {
    final sessions = _RecoveringBluetoothSessionStore();
    final controller = TripTrackingController(
      sessionStore: sessions,
      odometer: GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      ),
    );
    addTearDown(controller.dispose);
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    const settings = TripTrackingSettings(
      bluetoothVehicleRecognitionEnabled: true,
      automaticVehicleSwitchEnabled: true,
    );

    final failed = controller.evaluateBluetoothVehicleIdentity(
      deviceId: 'head-unit-1',
      settings: settings,
      linkStore: links,
    );
    expect(
      failed.disposition,
      BluetoothVehicleMatchDisposition.blockedByUnfinishedSession,
    );
    expect(
      controller.platformStatus,
      'bluetooth_session_storage_state_unknown',
    );

    sessions.fail = false;
    final recovered = controller.evaluateBluetoothVehicleIdentity(
      deviceId: 'head-unit-1',
      settings: settings,
      linkStore: links,
    );
    expect(recovered.disposition, BluetoothVehicleMatchDisposition.noMatch);
    expect(controller.platformStatus, isNull);
    expect(controller.platformError, isNull);
  });
}

class _RecoveringBluetoothLinkStore
    extends TripTrackingBluetoothVehicleLinkStore {
  _RecoveringBluetoothLinkStore() : super.memory();

  var fail = true;

  @override
  TripTrackingBluetoothVehicleLink? linkForDevice(String deviceId) {
    if (fail) throw StateError('Bluetooth link storage unavailable');
    return super.linkForDevice(deviceId);
  }
}

class _RecoveringBluetoothSessionStore extends TripTrackingSessionStore {
  _RecoveringBluetoothSessionStore() : super.memory();

  var fail = true;

  @override
  TripTrackingSessionRecord? get activeSession {
    if (fail) throw StateError('trip storage unavailable');
    return super.activeSession;
  }
}
