import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/contractor/contractor_dashboard_screen.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  testWidgets('contractor stop survives into the active GPS trip review', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final appState = AppStateController();
    final workProfiles = ExpenseWorkProfileController.memory();
    final workday = ActiveWorkdayController.memory();
    final odometer = GlobalOdometerController(
      vehicleId: 'vehicle_1',
      initialReading: 1000,
    );
    final trip = TripTrackingController(
      sessionStore: TripTrackingSessionStore.memory(),
      odometer: odometer,
    );
    addTearDown(appState.dispose);
    addTearDown(workProfiles.dispose);
    addTearDown(workday.dispose);
    addTearDown(odometer.dispose);
    addTearDown(trip.dispose);

    final startedAt = DateTime.now().toUtc().subtract(
      const Duration(minutes: 5),
    );
    await workday.startDay(
      vehicleId: 'vehicle_1',
      vehicleLabel: 'Work Truck',
      workProfileId: 'contractor',
      startOdometer: 1000,
      startedAt: startedAt,
    );
    expect(
      await trip.start(
        tripId: 'contractor-stop-handoff',
        vehicleId: 'vehicle_1',
        profile: TripTrackingProfile.contractorVehicle,
        profileId: 'contractor',
        startedAt: startedAt,
      ),
      isTrue,
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ExpenseWorkProfileScope(
          controller: workProfiles,
          child: ActiveWorkdayScope(
            controller: workday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingScope(
                controller: trip,
                child: const MaterialApp(home: ContractorDashboardScreen()),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Add Stop'),
      250,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Add Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Add Stop Details'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Customer delivery');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 100));

    expect(workday.activeSession?.events, hasLength(2));
    final workdayEvent = workday.activeSession!.events.last;
    expect(workdayEvent.type, ActiveWorkdayEventType.stop);
    expect(workdayEvent.note, 'Customer delivery');
    expect(
      trip.activeSession?.tripEvents,
      hasLength(1),
      reason:
          'status=${trip.platformStatus}; error=${trip.platformError}; '
          'lifecycle=${trip.activeSession?.lifecycleState}',
    );
    final review = await trip.finishForReview();
    expect(review, isNotNull);
    expect(
      review!.tripEvents,
      hasLength(1),
      reason:
          'status=${trip.platformStatus}; error=${trip.platformError}; '
          'lifecycle=${trip.activeSession?.lifecycleState}',
    );
    expect(review.tripEvents.single.type, TripManualEventType.stop);
    expect(review.tripEvents.single.note, 'Customer delivery');
    expect(odometer.confirmedReading, 1000);
  });
}
