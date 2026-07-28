import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/app/maintaniac_app.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('Maintaniac app starts on the dashboard', (tester) async {
    final workProfiles = ExpenseWorkProfileController.memory();
    final bluetooth = _DashboardBluetoothRuntime();
    addTearDown(workProfiles.dispose);
    addTearDown(bluetooth.dispose);
    await tester.pumpWidget(
      AppStateScope(
        controller: AppStateController(),
        child: GlobalOdometerScope(
          controller: GlobalOdometerController(),
          child: ExpenseWorkProfileScope(
            controller: workProfiles,
            child: MaintaniacApp(bluetoothTripRuntime: bluetooth.runtime),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE VEHICLE'), findsAtLeastNWidgets(1));
    expect(find.text('READY WHEN YOU ARE'), findsOneWidget);
    expect(find.text('Payments this week'), findsOneWidget);
    expect(find.text('Start day'), findsOneWidget);
    expect(find.text('Fuel'), findsAtLeastNWidgets(1));
  });
}

class _DashboardBluetoothRuntime {
  _DashboardBluetoothRuntime()
    : _probe = _NoopBluetoothProbe(),
      _links = TripTrackingBluetoothVehicleLinkStore.memory() {
    runtime = TripTrackingBluetoothRuntimeController(
      probe: _probe,
      linkStore: _links,
      coordinator: TripTrackingBluetoothCoordinator(
        linkStore: _links,
        settings: () => const TripTrackingSettings(),
        hasActiveSession: () => false,
        hasUnfinishedStoredSession: () => false,
        currentVehicleId: () => '',
        switchVehicle: (_) async => false,
      ),
    );
  }

  final _NoopBluetoothProbe _probe;
  final TripTrackingBluetoothVehicleLinkStore _links;
  late final TripTrackingBluetoothRuntimeController runtime;

  Future<void> dispose() async {
    runtime.dispose();
    await _probe.dispose();
  }
}

class _NoopBluetoothProbe implements DeviceBluetoothConnectionProbe {
  final _events = StreamController<DeviceBluetoothConnectionObservation>();

  @override
  Stream<DeviceBluetoothConnectionObservation> get approvedConnectionChanges =>
      _events.stream;

  @override
  Future<DeviceBluetoothCapabilities> bluetoothCapabilities() async =>
      const DeviceBluetoothCapabilities();

  Future<void> dispose() => _events.close();
}
