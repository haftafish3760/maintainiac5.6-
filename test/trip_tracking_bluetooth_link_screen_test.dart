// User-facing Bluetooth vehicle-link approval regression test.
//
// Owns the settings-screen proof that a fresh approved observation can be
// linked and forgotten with confirmation while its opaque identifier remains
// hidden. It does not emulate native Bluetooth or test GPS accuracy.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/settings/trip_tracking_settings_screen.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/profiles/user_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('user explicitly links and forgets a recent device', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final now = DateTime.utc(2026, 7, 28, 12);
    final probe = _FakeBluetoothProbe();
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () =>
          const TripTrackingSettings(bluetoothVehicleRecognitionEnabled: true),
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_work_truck_1',
      switchVehicle: (_) async => false,
    );
    final runtime = TripTrackingBluetoothRuntimeController(
      probe: probe,
      coordinator: coordinator,
      linkStore: links,
      clockNow: () => now,
    );
    final settings = TripTrackingSettingsController.memory();
    final appState = AppStateController();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_work_truck_1',
    );
    final profiles = UserProfileController.memory();
    addTearDown(runtime.dispose);
    addTearDown(probe.dispose);
    addTearDown(settings.dispose);
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);
    addTearDown(profiles.dispose);
    await runtime.start();
    probe.add(
      DeviceBluetoothConnectionObservation(
        opaqueDeviceId: 'opaque-private-device-hash',
        connected: true,
        observedAtUtc: now,
      ),
    );
    for (
      var attempt = 0;
      attempt < 20 && !runtime.hasPendingDevice;
      attempt++
    ) {
      await tester.pump();
    }
    expect(runtime.hasPendingDevice, isTrue);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: appState,
          child: GlobalOdometerScope(
            controller: odometer,
            child: UserProfileScope(
              controller: profiles,
              child: TripTrackingSettingsScope(
                controller: settings,
                child: TripTrackingBluetoothRuntimeScope(
                  controller: runtime,
                  child: const TripTrackingSettingsScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final approve = find.byKey(const Key('approveRecentBluetoothVehicle'));
    await tester.ensureVisible(approve);
    expect(approve, findsOneWidget);
    expect(find.textContaining('opaque-private-device-hash'), findsNothing);

    await tester.tap(approve);
    await tester.pumpAndSettle();

    expect(
      links.linkForDevice('opaque-private-device-hash')?.vehicleId,
      'vehicle_work_truck_1',
    );
    expect(find.text('Approved device 1'), findsOneWidget);
    expect(find.textContaining('opaque-private-device-hash'), findsNothing);

    await tester.tap(find.text('Forget'));
    await tester.pumpAndSettle();
    expect(find.text('Forget Bluetooth vehicle link?'), findsOneWidget);
    await tester.tap(find.text('Forget link'));
    await tester.pumpAndSettle();

    expect(links.linkForDevice('opaque-private-device-hash'), isNull);
    expect(find.text('Approved device 1'), findsNothing);
  });

  testWidgets('user can explicitly request Bluetooth vehicle access', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    var permissionRequests = 0;
    final probe = _FakeBluetoothProbe();
    final links = TripTrackingBluetoothVehicleLinkStore.memory();
    final coordinator = TripTrackingBluetoothCoordinator(
      linkStore: links,
      settings: () => const TripTrackingSettings(),
      hasActiveSession: () => false,
      hasUnfinishedStoredSession: () => false,
      currentVehicleId: () => 'vehicle_work_truck_1',
      switchVehicle: (_) async => false,
    );
    final runtime = TripTrackingBluetoothRuntimeController(
      probe: probe,
      coordinator: coordinator,
      linkStore: links,
      requestObservationAccess: () async {
        permissionRequests += 1;
        return true;
      },
    );
    final settings = TripTrackingSettingsController.memory();
    final appState = AppStateController();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_work_truck_1',
    );
    final profiles = UserProfileController.memory();
    addTearDown(runtime.dispose);
    addTearDown(probe.dispose);
    addTearDown(settings.dispose);
    addTearDown(appState.dispose);
    addTearDown(odometer.dispose);
    addTearDown(profiles.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppStateScope(
          controller: appState,
          child: GlobalOdometerScope(
            controller: odometer,
            child: UserProfileScope(
              controller: profiles,
              child: TripTrackingSettingsScope(
                controller: settings,
                child: TripTrackingBluetoothRuntimeScope(
                  controller: runtime,
                  child: const TripTrackingSettingsScreen(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final enable = find.byKey(const Key('enableBluetoothVehicleAccess'));
    await tester.ensureVisible(enable);
    expect(enable, findsOneWidget);

    await tester.tap(enable);
    await tester.pumpAndSettle();

    expect(permissionRequests, 1);
    expect(runtime.observationAvailable, isTrue);
    expect(find.text('Ready for an approved vehicle link'), findsOneWidget);
  });
}

class _FakeBluetoothProbe implements DeviceBluetoothConnectionProbe {
  final _events =
      StreamController<DeviceBluetoothConnectionObservation>.broadcast();

  @override
  Stream<DeviceBluetoothConnectionObservation> get approvedConnectionChanges =>
      _events.stream;

  @override
  Future<DeviceBluetoothCapabilities> bluetoothCapabilities() async =>
      const DeviceBluetoothCapabilities(
        adapterAvailable: true,
        poweredOn: true,
        authorization: DeviceBluetoothAuthorizationState.authorized,
        supportsApprovedDeviceObservation: true,
      );

  void add(DeviceBluetoothConnectionObservation observation) =>
      _events.add(observation);

  Future<void> dispose() => _events.close();
}
