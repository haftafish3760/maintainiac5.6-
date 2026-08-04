import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/app/maintaniac_app.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/device_capabilities/device_bluetooth_capabilities.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_coordinator.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_bluetooth_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_automatic_evidence_runtime.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_platform.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
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
            child: MaintaniacApp(
              bluetoothTripRuntime: bluetooth.runtime,
              automaticEvidenceRuntime: bluetooth.automaticEvidenceRuntime,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ACTIVE VEHICLE'), findsAtLeastNWidgets(1));
    expect(find.text('Payments this week'), findsOneWidget);
    expect(find.text('Start day'), findsOneWidget);
    expect(find.text('Fuel'), findsAtLeastNWidgets(1));

    // Dispose app-owned runtime listeners before the test-owned gateway closes.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
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
    _automaticOdometer = GlobalOdometerController();
    _automaticEvidenceGateway = _NoopAutomaticEvidenceGateway();
    _automaticTripTracking = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: _automaticOdometer,
    );
    automaticEvidenceRuntime = TripAutomaticEvidenceRuntimeController(
      gateway: _automaticEvidenceGateway,
      tripTracking: _automaticTripTracking,
      settings: () => const TripTrackingSettings(),
    );
  }

  final _NoopBluetoothProbe _probe;
  final TripTrackingBluetoothVehicleLinkStore _links;
  late final TripTrackingBluetoothRuntimeController runtime;
  late final _NoopAutomaticEvidenceGateway _automaticEvidenceGateway;
  late final GlobalOdometerController _automaticOdometer;
  late final TripTrackingController _automaticTripTracking;
  late final TripAutomaticEvidenceRuntimeController automaticEvidenceRuntime;

  void dispose() {
    _automaticTripTracking.dispose();
    _automaticOdometer.dispose();
    unawaited(_automaticEvidenceGateway.dispose());
    unawaited(_probe.dispose());
  }
}

class _NoopAutomaticEvidenceGateway
    implements TripAutomaticEvidenceNativeGateway {
  final _events = StreamController<TripTrackingPlatformEvent>();

  @override
  Stream<TripTrackingPlatformEvent> get events => _events.stream;

  @override
  Future<bool> startAutomaticEvidenceObservation({
    required bool activityRecognitionEnabled,
  }) async => false;

  @override
  Future<void> stopAutomaticEvidenceObservation() async {}

  @override
  Future<bool> get isAutomaticEvidenceObservationRunning async => false;

  Future<void> dispose() => _events.close();
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
