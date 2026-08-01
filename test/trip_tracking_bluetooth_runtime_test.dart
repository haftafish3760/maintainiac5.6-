// Bluetooth vehicle-link runtime regression tests.
//
// Owns deterministic coverage for lifecycle idempotency, bounded pending
// observations, explicit approval, expiry, and local association persistence.
// It does not emulate a platform radio or validate GPS field accuracy.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  test(
    'concurrent lifecycle starts create one observation subscription',
    () async {
      final fixture = _RuntimeFixture();
      addTearDown(fixture.dispose);

      final results = await Future.wait([
        fixture.runtime.start(),
        fixture.runtime.start(),
        fixture.runtime.start(),
      ]);

      expect(results, everyElement(isTrue));
      expect(fixture.probe.capabilityReads, 1);
      expect(fixture.probe.hasListener, isTrue);
      expect(fixture.runtime.observationAvailable, isTrue);
    },
  );

  test('explicit permission approval starts observation once', () async {
    var permissionRequests = 0;
    final fixture = _RuntimeFixture(
      requestObservationAccess: () async {
        permissionRequests += 1;
        return true;
      },
    );
    addTearDown(fixture.dispose);

    expect(await fixture.runtime.requestObservationAccess(), isTrue);
    expect(permissionRequests, 1);
    expect(fixture.probe.capabilityReads, 1);
    expect(fixture.runtime.observationAvailable, isTrue);
  });

  test(
    'concurrent access requests show one native permission prompt',
    () async {
      var permissionRequests = 0;
      final permissionResult = Completer<bool>();
      final fixture = _RuntimeFixture(
        requestObservationAccess: () {
          permissionRequests += 1;
          return permissionResult.future;
        },
      );
      addTearDown(fixture.dispose);

      final requests = [
        fixture.runtime.requestObservationAccess(),
        fixture.runtime.requestObservationAccess(),
        fixture.runtime.requestObservationAccess(),
      ];
      expect(permissionRequests, 1);

      permissionResult.complete(true);
      expect(await Future.wait(requests), everyElement(isTrue));
      expect(fixture.probe.capabilityReads, 1);
    },
  );

  test(
    'native access errors fail closed without escaping to the settings UI',
    () async {
      final fixture = _RuntimeFixture(
        requestObservationAccess: () async => throw StateError('unavailable'),
      );
      addTearDown(fixture.dispose);

      expect(await fixture.runtime.requestObservationAccess(), isFalse);
      expect(fixture.runtime.observationAvailable, isFalse);
      expect(fixture.probe.capabilityReads, 0);
    },
  );

  test('a denied access request can be retried later', () async {
    var attempts = 0;
    final fixture = _RuntimeFixture(
      requestObservationAccess: () async => ++attempts > 1,
    );
    addTearDown(fixture.dispose);

    expect(await fixture.runtime.requestObservationAccess(), isFalse);
    expect(await fixture.runtime.requestObservationAccess(), isTrue);
    expect(attempts, 2);
    expect(fixture.runtime.observationAvailable, isTrue);
  });

  test(
    'unlinked connection requires explicit fresh vehicle approval',
    () async {
      final now = DateTime.utc(2026, 7, 28, 10);
      final fixture = _RuntimeFixture(now: now);
      addTearDown(fixture.dispose);
      await fixture.runtime.start();

      fixture.probe.add(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'private-hash-never-rendered',
          connected: true,
          observedAtUtc: now,
        ),
      );
      await _drainUntil(() => fixture.runtime.hasPendingDevice);

      expect(
        fixture.links.linkForDevice('private-hash-never-rendered'),
        isNull,
      );
      expect(
        await fixture.runtime.approvePendingForVehicle(
          vehicleId: 'vehicle_1',
          vehicleLabel: 'Work Truck',
        ),
        isTrue,
      );
      final link = fixture.links.linkForDevice('private-hash-never-rendered');
      expect(link?.vehicleId, 'vehicle_1');
      expect(link?.displayName, 'Work Truck Bluetooth');
      expect(fixture.runtime.hasPendingDevice, isFalse);
    },
  );

  test(
    'latest observation is bounded and stale approval fails closed',
    () async {
      var now = DateTime.utc(2026, 7, 28, 11);
      final fixture = _RuntimeFixture(now: now, clockNow: () => now);
      addTearDown(fixture.dispose);
      await fixture.runtime.start();

      fixture.probe.add(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'device-1',
          connected: true,
          observedAtUtc: now,
        ),
      );
      fixture.probe.add(
        DeviceBluetoothConnectionObservation(
          opaqueDeviceId: 'device-2',
          connected: true,
          observedAtUtc: now,
        ),
      );
      await _drainUntil(() => fixture.runtime.hasPendingDevice);
      now = now.add(const Duration(minutes: 6));

      expect(fixture.runtime.hasPendingDevice, isFalse);
      expect(
        await fixture.runtime.approvePendingForVehicle(
          vehicleId: 'vehicle_1',
          vehicleLabel: 'Work Truck',
        ),
        isFalse,
      );
      expect(fixture.links.linkForDevice('device-1'), isNull);
      expect(fixture.links.linkForDevice('device-2'), isNull);
    },
  );
}

class _RuntimeFixture {
  _RuntimeFixture({
    DateTime? now,
    DateTime Function()? clockNow,
    Future<bool> Function()? requestObservationAccess,
  }) {
    final fixedNow = now ?? DateTime.utc(2026, 7, 28, 9);
    coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () =>
          const TripTrackingSettings(bluetoothVehicleRecognitionEnabled: true),
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_1',
      switchVehicle: (_) async => false,
    );
    runtime = TripTrackingBluetoothRuntimeController(
      probe: probe,
      coordinator: coordinator,
      linkStore: links,
      clockNow: clockNow ?? () => fixedNow,
      requestObservationAccess: requestObservationAccess,
    );
  }

  final probe = _FakeBluetoothProbe();
  final links = TripTrackingBluetoothVehicleLinkStore.memory();
  late final TripTrackingBluetoothCoordinator coordinator;
  late final TripTrackingBluetoothRuntimeController runtime;

  Future<void> dispose() async {
    runtime.dispose();
    await probe.dispose();
  }
}

class _FakeBluetoothProbe implements DeviceBluetoothConnectionProbe {
  final _events =
      StreamController<DeviceBluetoothConnectionObservation>.broadcast();
  int capabilityReads = 0;

  bool get hasListener => _events.hasListener;

  @override
  Stream<DeviceBluetoothConnectionObservation> get approvedConnectionChanges =>
      _events.stream;

  @override
  Future<DeviceBluetoothCapabilities> bluetoothCapabilities() async {
    capabilityReads += 1;
    await Future<void>.delayed(Duration.zero);
    return const DeviceBluetoothCapabilities(
      adapterAvailable: true,
      poweredOn: true,
      authorization: DeviceBluetoothAuthorizationState.authorized,
      supportsApprovedDeviceObservation: true,
    );
  }

  void add(DeviceBluetoothConnectionObservation observation) =>
      _events.add(observation);

  Future<void> dispose() => _events.close();
}

Future<void> _drainUntil(bool Function() condition) async {
  for (var attempt = 0; attempt < 20 && !condition(); attempt++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(condition(), isTrue);
}
