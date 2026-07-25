import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_start_detector.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final now = DateTime.utc(2026, 7, 20, 12);

  Future<TripTrackingBluetoothVehicleLinkStore> links() async {
    final store = TripTrackingBluetoothVehicleLinkStore.memory();
    await store.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: 'opaque_local_device',
        vehicleId: 'vehicle_2',
        createdAt: now,
      ),
    );
    return store;
  }

  TripTrackingSettings enabledSettings() => const TripTrackingSettings(
    bluetoothVehicleRecognitionEnabled: true,
    automaticVehicleSwitchEnabled: true,
  );

  test(
    'approved recent connection may request only its linked vehicle',
    () async {
      String? switchedTo;
      final coordinator = TripTrackingBluetoothCoordinator(
        linkStore: await links(),
        settings: enabledSettings,
        hasActiveSession: () => false,
        hasUnfinishedStoredSession: () => false,
        currentVehicleId: () => 'vehicle_1',
        switchVehicle: (vehicleId) async {
          switchedTo = vehicleId;
          return true;
        },
      );

      final decision = await coordinator.handleConnection(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'opaque_local_device',
          connected: true,
          observedAtUtc: now,
        ),
        nowUtc: now,
      );

      expect(decision.canSwitchVehicle, isTrue);
      expect(switchedTo, 'vehicle_2');
      expect(decision.toSafeSummary()['deviceIdIncluded'], isFalse);
    },
  );

  test('unfinished recovery evidence blocks vehicle switching', () async {
    var switchCalls = 0;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: await links(),
      settings: enabledSettings,
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => true,
      currentVehicleId: () => 'vehicle_1',
      switchVehicle: (_) async {
        switchCalls += 1;
        return true;
      },
    );

    final decision = await coordinator.handleConnection(
      DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'opaque_local_device',
        connected: true,
        observedAtUtc: now,
      ),
      nowUtc: now,
    );

    expect(
      decision.disposition,
      BluetoothVehicleMatchDisposition.blockedByUnfinishedSession,
    );
    expect(switchCalls, 0);
  });

  test(
    'connection handling is serialized and failed switches fail safe',
    () async {
      final firstSwitch = Completer<bool>();
      var switchCalls = 0;
      final coordinator = TripTrackingBluetoothCoordinator(
        linkStore: await links(),
        settings: enabledSettings,
        hasActiveSession: () => false,
        hasUnfinishedStoredSession: () => false,
        currentVehicleId: () => 'vehicle_1',
        switchVehicle: (_) {
          switchCalls += 1;
          return switchCalls == 1 ? firstSwitch.future : Future.value(false);
        },
      );
      final observation = DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'opaque_local_device',
        connected: true,
        observedAtUtc: now,
      );

      final first = coordinator.handleConnection(observation, nowUtc: now);
      final second = coordinator.handleConnection(observation, nowUtc: now);
      await Future<void>.delayed(Duration.zero);
      expect(switchCalls, 1);
      firstSwitch.complete(true);
      expect((await first).canSwitchVehicle, isTrue);
      expect(
        (await second).disposition,
        BluetoothVehicleMatchDisposition.requiresUserConfirmation,
      );
      expect(switchCalls, 2);
    },
  );

  test('paid linked vehicle connection may start automatic GPS tracking', () async {
    var active = false;
    String? startedVehicle;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: await links(),
      settings: () => const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      hasActiveSession: () => active,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_1',
      switchVehicle: (_) async => true,
      automaticStartAccess: () => TripAutomaticStartAccessLevel.paid,
      startAutomaticTracking: (vehicleId, _) async {
        startedVehicle = vehicleId;
        active = true;
        return true;
      },
    );

    await coordinator.handleConnection(
      DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'opaque_local_device',
        connected: true,
        observedAtUtc: now,
      ),
      nowUtc: now,
    );

    expect(startedVehicle, 'vehicle_2');
    expect(active, isTrue);
  });

  test('free linked vehicle connection cannot start automatic tracking', () async {
    var startCalls = 0;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: await links(),
      settings: () => const TripTrackingSettings(
        gpsAssistedTrackingEnabled: true,
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
        automaticStartAssistanceEnabled: true,
      ),
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_1',
      switchVehicle: (_) async => true,
      automaticStartAccess: () => TripAutomaticStartAccessLevel.free,
      startAutomaticTracking: (_, _) async {
        startCalls += 1;
        return true;
      },
    );

    await coordinator.handleConnection(
      DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'opaque_local_device',
        connected: true,
        observedAtUtc: now,
      ),
      nowUtc: now,
    );

    expect(startCalls, 0);
  });
}
