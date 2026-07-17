import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  testWidgets('dashboard active vehicle block follows live odometer updates', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1500);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final appState = AppStateController();
    final workProfiles = ExpenseWorkProfileController.memory();
    final odometer = GlobalOdometerController(initialReading: 1000);
    addTearDown(appState.dispose);
    addTearDown(workProfiles.dispose);
    addTearDown(odometer.dispose);

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ExpenseWorkProfileScope(
          controller: workProfiles,
          child: GlobalOdometerScope(
            controller: odometer,
            child: const MaterialApp(home: DashboardScreen()),
          ),
        ),
      ),
    );

    expect(find.text('Odometer 0001000'), findsOneWidget);

    expect(
      odometer.beginLiveTripProjection(
        tripId: 'dashboard-live-trip',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'dashboard-live-trip',
        estimatedOdometer: 1006,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('Live odometer 0001006'), findsOneWidget);
    expect(find.text('Odometer 0001000'), findsNothing);
    expect(odometer.confirmedReading, 1000);
  });
}
