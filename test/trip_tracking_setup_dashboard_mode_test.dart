import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_screen.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_settings_store.dart';

void main() {
  testWidgets('contractor setup changes a solo driver dashboard', (
    tester,
  ) async {
    final harness = await _pumpFirstSetup(
      tester,
      initialMode: OperationalDashboardMode.gigDriver,
    );

    await _chooseManualContractor(tester);

    expect(
      harness.operational.context.dashboardMode,
      OperationalDashboardMode.soloContractor,
    );
    expect(harness.settings.settings.tripTrackingSetupCompleted, isTrue);
    expect(harness.settings.settings.gpsAssistedTrackingEnabled, isFalse);
  });

  testWidgets('contractor setup preserves an existing fleet dashboard', (
    tester,
  ) async {
    final harness = await _pumpFirstSetup(
      tester,
      initialMode: OperationalDashboardMode.fleetOwner,
    );

    await _chooseManualContractor(tester);

    expect(
      harness.operational.context.dashboardMode,
      OperationalDashboardMode.fleetOwner,
    );
  });
}

Future<void> _chooseManualContractor(WidgetTester tester) async {
  expect(find.text('What Type of Work Do You Do?'), findsOneWidget);
  await tester.tap(find.text('Contractor and service work'));
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Enter mileage myself'));
  await tester.pump();
  await tester.tap(find.text('Use Manual Mileage'));
  await tester.pumpAndSettle();
}

Future<_SetupHarness> _pumpFirstSetup(
  WidgetTester tester, {
  required OperationalDashboardMode initialMode,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final appState = AppStateController();
  final workday = ActiveWorkdayController.memory();
  final odometer = GlobalOdometerController(
    vehicleId: 'vehicle_1',
    initialReading: 12000,
  );
  final trip = TripTrackingController(
    sessionStore: TripTrackingSessionStore.memory(),
    odometer: odometer,
  );
  final settings = TripTrackingSettingsController.memory();
  final operational = OperationalContextController.memory(
    profile: UserProfileRecord.starterContractor(),
    activeVehicleId: 'vehicle_1',
    activeVehicleLabel: 'Work Truck',
  );
  await operational.setDashboardMode(initialMode);
  await workday.startDay(
    vehicleId: 'vehicle_1',
    vehicleLabel: 'Work Truck',
    workProfileId: 'business',
    startOdometer: 12000,
  );
  addTearDown(appState.dispose);
  addTearDown(workday.dispose);
  addTearDown(odometer.dispose);
  addTearDown(trip.dispose);
  addTearDown(settings.dispose);
  addTearDown(operational.dispose);

  await tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: ActiveWorkdayScope(
        controller: workday,
        child: GlobalOdometerScope(
          controller: odometer,
          child: TripTrackingSettingsScope(
            controller: settings,
            child: TripTrackingScope(
              controller: trip,
              child: OperationalContextScope(
                controller: operational,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '12000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                    promptForTripTrackingSetup: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return _SetupHarness(operational: operational, settings: settings);
}

class _SetupHarness {
  const _SetupHarness({required this.operational, required this.settings});

  final OperationalContextController operational;
  final TripTrackingSettingsController settings;
}
