import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_screen.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_controller.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_models.dart';
import 'package:maintaniac/shared/trip_tracking/trip_tracking_session_store.dart';

void main() {
  late AppStateController appState;
  late GlobalOdometerController odometer;
  late ExpenseWorkProfileController workProfiles;

  setUp(() {
    appState = AppStateController();
    odometer = GlobalOdometerController();
    workProfiles = ExpenseWorkProfileController.memory();
  });

  tearDown(() {
    appState.dispose();
    odometer.dispose();
  });

  testWidgets('dashboard opens contractor command center', (tester) async {
    await _pumpDashboard(tester, appState, odometer, workProfiles);

    expect(find.text('Contractor Dashboard'), findsOneWidget);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Contractor Command Center'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Contractor'), findsOneWidget);
    expect(find.text('Operations Pulse'), findsOneWidget);
    expect(find.text('Vehicles Active'), findsOneWidget);
    expect(find.text('Employees Active'), findsOneWidget);
    expect(find.text('Needs Attention'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Money In'),
      360,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Money In'), findsOneWidget);
    expect(find.text('Money Out'), findsOneWidget);
  });

  testWidgets('contractor dashboard exposes active day tools', (tester) async {
    await _pumpDashboard(tester, appState, odometer, workProfiles);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Start Day'),
      220,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Start Day'));
    await tester.pumpAndSettle();

    expect(find.text('Active Contractor Day'), findsOneWidget);
    expect(find.text('Add Stop'), findsOneWidget);
    expect(find.text('Job Note'), findsOneWidget);
    expect(find.text('Use Materials'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Create Invoice'), findsOneWidget);
    expect(find.text('Record Payment'), findsOneWidget);
    expect(find.text('Proof Photo'), findsOneWidget);
  });

  testWidgets('active workday miles redraw from live GPS odometer projection', (
    tester,
  ) async {
    odometer.dispose();
    odometer = GlobalOdometerController(initialReading: 1000);
    final activeWorkday = ActiveWorkdayController.memory();
    await activeWorkday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'business',
      startOdometer: 1000,
      startedAt: DateTime(2026, 7, 16, 8),
    );

    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: ActiveWorkdayScope(
          controller: activeWorkday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: const MaterialApp(
              home: ActiveWorkdayScreen(
                activeVehicle: VehicleProfilePreview(
                  id: 'vehicle_1',
                  nickname: 'Work Truck',
                  year: '2026',
                  make: 'Ford',
                  model: 'Transit',
                  odometer: '0001000',
                  status: 'ACTIVE',
                ),
                workProfileName: 'Business',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Miles Today'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);

    expect(
      odometer.beginLiveTripProjection(
        tripId: 'gps-trip-active-day',
        startingOdometer: 1000,
      ),
      isTrue,
    );
    expect(
      odometer.updateLiveTripProjection(
        tripId: 'gps-trip-active-day',
        estimatedOdometer: 1005,
      ),
      isTrue,
    );
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
  });

  testWidgets(
    'active workday stop dialog redraws live GPS odometer projection',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      odometer.dispose();
      odometer = GlobalOdometerController(initialReading: 1000);
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 7, 16, 8),
      );

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: const MaterialApp(
                home: ActiveWorkdayScreen(
                  activeVehicle: VehicleProfilePreview(
                    id: 'vehicle_1',
                    nickname: 'Work Truck',
                    year: '2026',
                    make: 'Ford',
                    model: 'Transit',
                    odometer: '0001000',
                    status: 'ACTIVE',
                  ),
                  workProfileName: 'Business',
                ),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('Add Stop'));
      await tester.pump();
      await tester.tap(
        find
            .ancestor(of: find.text('Add Stop'), matching: find.byType(InkWell))
            .first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Odometer: 0001000'), findsOneWidget);
      expect(
        odometer.beginLiveTripProjection(
          tripId: 'gps-trip-stop-dialog',
          startingOdometer: 1000,
        ),
        isTrue,
      );
      expect(
        odometer.updateLiveTripProjection(
          tripId: 'gps-trip-stop-dialog',
          estimatedOdometer: 1004,
        ),
        isTrue,
      );
      await tester.pump();

      expect(find.text('Odometer: 0001004'), findsOneWidget);
      expect(find.text('Odometer: 0001000'), findsNothing);
    },
  );

  testWidgets(
    'active workday trip review confirms the exact sheet odometer value',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(900, 1500);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      odometer.dispose();
      odometer = GlobalOdometerController(
        vehicleId: 'vehicle_1',
        initialReading: 1000,
      );
      final activeWorkday = ActiveWorkdayController.memory();
      await activeWorkday.startDay(
        vehicleId: odometer.vehicleId,
        vehicleLabel: 'Work Truck',
        workProfileId: 'business',
        startOdometer: 1000,
        startedAt: DateTime(2026, 7, 16, 8),
      );
      final tripStore = TripTrackingSessionStore.memory();
      final tripController = TripTrackingController(
        sessionStore: tripStore,
        odometer: odometer,
      );
      await tripStore.saveReview(
        TripTrackingReviewRecord(
          id: 'dashboard_review_exact_saved_reading',
          vehicleId: 'vehicle_1',
          startingOdometer: 1000,
          estimatedEndingOdometer: 1001,
          profile: TripTrackingProfile.roadVehicle,
          startedAt: DateTime.utc(2026, 7, 16, 12),
          finishedAt: DateTime.utc(2026, 7, 16, 12, 10),
          engineSnapshot: const TripTrackingEngineSnapshot(
            totalAcceptedMeters: 1609.344,
            walkingReviewSuggested: false,
          ),
        ),
      );

      await tester.pumpWidget(
        AppStateScope(
          controller: appState,
          child: ActiveWorkdayScope(
            controller: activeWorkday,
            child: GlobalOdometerScope(
              controller: odometer,
              child: TripTrackingScope(
                controller: tripController,
                child: const MaterialApp(
                  home: ActiveWorkdayScreen(
                    activeVehicle: VehicleProfilePreview(
                      id: 'vehicle_1',
                      nickname: 'Work Truck',
                      year: '2026',
                      make: 'Ford',
                      model: 'Transit',
                      odometer: '0001000',
                      status: 'ACTIVE',
                    ),
                    workProfileName: 'Business',
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.ensureVisible(find.text('REVIEW LATEST GPS TRIP'));
      await tester.pump();
      await tester.tap(
        find
            .ancestor(
              of: find.text('REVIEW LATEST GPS TRIP'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '1001');
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm Odometer'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Business'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Save Miles'));
      await tester.pumpAndSettle();

      final stored = tripStore.reviewForTrip(
        'dashboard_review_exact_saved_reading',
      );
      expect(stored?.confirmedEndingOdometer, 1001);
      expect(stored?.isOdometerConfirmed, isTrue);
      expect(odometer.confirmedReading, 1001);
      expect(
        find.text('GPS trip reviewed and odometer confirmed.'),
        findsOneWidget,
      );
    },
  );
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  AppStateController appState,
  GlobalOdometerController odometer,
  ExpenseWorkProfileController workProfiles,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1500);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
}
