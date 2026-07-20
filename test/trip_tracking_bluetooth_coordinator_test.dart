import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  final now = DateTime.utc(2026, 7, 20, 12);

  test('approved Bluetooth link may request only its bound vehicle', () async {
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    await links.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: 'opaque_local_device',
        vehicleId: 'vehicle_2',
        createdAt: now,
      ),
    );
    String? switchedTo;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () => const TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      ),
      hasActiveOrRecoverableSession: () => false,
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
  });

  test('active recoverable trip blocks Bluetooth vehicle switching', () async {
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    await links.save(
      TripTrackingBluetoothVehicleLink(
        deviceId: 'opaque_local_device',
        vehicleId: 'vehicle_2',
        createdAt: now,
      ),
    );
    var switchCalls = 0;
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () => const TripTrackingSettings(
        bluetoothVehicleRecognitionEnabled: true,
        automaticVehicleSwitchEnabled: true,
      ),
      hasActiveOrRecoverableSession: () => true,
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
      BluetoothVehicleMatchDisposition.blockedByActiveTrip,
    );
    expect(switchCalls, 0);
  });
}
