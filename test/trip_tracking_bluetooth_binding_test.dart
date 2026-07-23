import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_binding.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'binding forwards approved connections without duplicate switches',
    () async {
      final now = DateTime.now().toUtc();
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
      final probe = _FakeBluetoothProbe(authorized: true);
      final decisions = <BluetoothVehicleMatchDecision>[];
      final binding = TripTrackingBluetoothBinding(
        probe: probe,
        coordinator: coordinator,
        onDecision: decisions.add,
      );
      addTearDown(binding.dispose);
      addTearDown(probe.dispose);

      expect(await binding.start(), isTrue);
      expect(await binding.start(), isTrue);
      expect(probe.hasListener, isTrue);
      probe.add(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'head-unit-2',
          connected: true,
          observedAtUtc: DateTime.now().toUtc(),
        ),
      );
      probe.add(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'head-unit-2',
          connected: true,
          observedAtUtc: DateTime.now().toUtc(),
        ),
      );
      await _drainUntil(() => decisions.length == 2);

      expect(switchCalls, 1);
      expect(activeVehicleId, 'vehicle_2');
      expect(decisions.map((item) => item.disposition), [
        BluetoothVehicleMatchDisposition.automaticSwitchAllowed,
        BluetoothVehicleMatchDisposition.alreadyActiveVehicle,
      ]);
    },
  );

  test(
    'binding does not subscribe without approved capability access',
    () async {
      final probe = _FakeBluetoothProbe(authorized: false);
      final coordinator = TripTrackingBluetoothCoordinator(
        linkStore: TripTrackingBluetoothVehicleLinkStore.memory(),
        settings: () => const TripTrackingSettings(),
        hasActiveSession: () => false,
        hasUnfinishedStoredSession: () => false,
        currentVehicleId: () => 'vehicle_1',
        switchVehicle: (_) async => true,
      );
      final binding = TripTrackingBluetoothBinding(
        probe: probe,
        coordinator: coordinator,
      );
      addTearDown(binding.dispose);
      addTearDown(probe.dispose);

      expect(await binding.start(), isFalse);
      expect(binding.isListening, isFalse);
      expect(probe.hasListener, isFalse);
    },
  );

  test('disposed binding ignores later observations', () async {
    final probe = _FakeBluetoothProbe(authorized: true);
    var decisions = 0;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: TripTrackingBluetoothVehicleLinkStore.memory(),
      settings: () => const TripTrackingSettings(),
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_1',
      switchVehicle: (_) async => true,
    );
    final binding = TripTrackingBluetoothBinding(
      probe: probe,
      coordinator: coordinator,
      onDecision: (_) => decisions += 1,
    );
    addTearDown(probe.dispose);

    expect(await binding.start(), isTrue);
    await binding.dispose();
    probe.add(
      DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'head-unit-2',
        connected: true,
        observedAtUtc: DateTime.now().toUtc(),
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(binding.isListening, isFalse);
    expect(decisions, 0);
  });
}

class _FakeBluetoothProbe implements DeviceBluetoothConnectionProbe {
  _FakeBluetoothProbe({required this.authorized});

  final bool authorized;
  final _events =
      StreamController<DeviceBluetoothConnectionObservation>.broadcast();

  bool get hasListener => _events.hasListener;

  @override
  Stream<DeviceBluetoothConnectionObservation> get approvedConnectionChanges =>
      _events.stream;

  @override
  Future<DeviceBluetoothCapabilities> bluetoothCapabilities() async =>
      DeviceBluetoothCapabilities(
        adapterAvailable: true,
        poweredOn: true,
        authorization: authorized
            ? DeviceBluetoothAuthorizationState.authorized
            : DeviceBluetoothAuthorizationState.denied,
        supportsApprovedDeviceObservation: true,
      );

  void add(DeviceBluetoothConnectionObservation observation) =>
      _events.add(observation);

  Future<void> dispose() => _events.close();
}

Future<void> _drainUntil(bool Function() condition) async {
  for (var index = 0; index < 20 && !condition(); index += 1) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}
