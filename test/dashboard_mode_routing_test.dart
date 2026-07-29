import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/context/operational_context_models.dart';
import 'package:maintaniac/shared/context/operational_context_store.dart';
import 'package:maintaniac/shared/profiles/user_profile_models.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';
import 'package:maintaniac/shared/widgets/app_back_button.dart';

void main() {
  testWidgets(
    'contractor work type keeps driver dashboard with contractor access',
    (tester) async {
      final harness = await _pumpDashboard(
        tester,
        OperationalDashboardMode.soloContractor,
      );
      addTearDown(harness.dispose);

      expect(find.text('Delivery dashboard'), findsOneWidget);
      expect(find.text('Contractor'), findsOneWidget);
    },
  );

  testWidgets('gig work type keeps the independent driving dashboard', (
    tester,
  ) async {
    final harness = await _pumpDashboard(
      tester,
      OperationalDashboardMode.gigDriver,
    );
    addTearDown(harness.dispose);

    expect(find.text('Delivery dashboard'), findsOneWidget);
    expect(find.text('Contractor'), findsOneWidget);
  });

  testWidgets(
    'driver dashboard supports enlarged Android text in contractor mode',
    (tester) async {
      final harness = await _pumpDashboard(
        tester,
        OperationalDashboardMode.soloContractor,
        textScaler: const TextScaler.linear(2),
      );
      addTearDown(harness.dispose);

      expect(find.text('Delivery dashboard'), findsOneWidget);
      expect(find.text('Contractor'), findsOneWidget);
      expect(find.text('Mock banner placement'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'returning from a secondary screen preserves the active workday Dashboard',
    (tester) async {
      final harness = await _pumpDashboard(
        tester,
        OperationalDashboardMode.gigDriver,
        activeWorkday: true,
      );
      addTearDown(harness.dispose);

      expect(find.text('Shift Timer'), findsOneWidget);
      Navigator.of(tester.element(find.byType(DashboardScreen))).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('Secondary screen')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Secondary screen'), findsOneWidget);

      Navigator.of(tester.element(find.text('Secondary screen'))).pop();
      await tester.pumpAndSettle();

      expect(find.text('Shift Timer'), findsOneWidget);
      expect(find.text('Delivery dashboard'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('pre-workday command center fits an iPhone SE viewport', (
    tester,
  ) async {
    final harness = await _pumpDashboard(
      tester,
      OperationalDashboardMode.gigDriver,
      logicalSize: const Size(375, 667),
    );
    addTearDown(harness.dispose);

    expect(find.text('Delivery dashboard'), findsOneWidget);
    expect(find.text('Start day'), findsOneWidget);
    expect(find.text('Payments this week'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-workday Start Day remains a prominent rectangular command', (
    tester,
  ) async {
    final harness = await _pumpDashboard(
      tester,
      OperationalDashboardMode.gigDriver,
      logicalSize: const Size(375, 667),
    );
    addTearDown(harness.dispose);

    final command = find.ancestor(
      of: find.text('Start day'),
      matching: find.byType(FilledButton),
    );
    expect(command, findsOneWidget);
    final size = tester.getSize(command);
    expect(size.height, 54);
    expect(size.width, greaterThan(300));
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pre-workday telemetry opens its matching review surface', (
    tester,
  ) async {
    final harness = await _pumpDashboard(
      tester,
      OperationalDashboardMode.gigDriver,
    );
    addTearDown(harness.dispose);

    await tester.tap(find.text('Payments this week'));
    await tester.pumpAndSettle();
    expect(find.text('Payments Review'), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses this week'));
    await tester.pumpAndSettle();
    expect(find.text('Expense Review'), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fuel recorded'));
    await tester.pumpAndSettle();
    expect(find.text('Fuel Review'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('active workday command center fits an iPhone SE viewport', (
    tester,
  ) async {
    final harness = await _pumpDashboard(
      tester,
      OperationalDashboardMode.gigDriver,
      activeWorkday: true,
      logicalSize: const Size(375, 667),
    );
    addTearDown(harness.dispose);

    expect(find.text('Shift Timer'), findsOneWidget);
    expect(find.text('Miles Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<_DashboardHarness> _pumpDashboard(
  WidgetTester tester,
  OperationalDashboardMode mode, {
  TextScaler textScaler = TextScaler.noScaling,
  bool activeWorkday = false,
  Size logicalSize = const Size(900, 1800),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final appState = AppStateController();
  final odometer = GlobalOdometerController(initialReading: 12000);
  final workProfiles = ExpenseWorkProfileController.memory();
  final workday = ActiveWorkdayController.memory();
  final operational = OperationalContextController.memory(
    profile: UserProfileRecord.starterContractor(),
  );
  await operational.setDashboardMode(mode);
  if (activeWorkday) {
    await workday.startDay(
      vehicleId: odometer.vehicleId,
      vehicleLabel: 'Work Truck',
      workProfileId: 'default',
      startOdometer: odometer.confirmedReading,
    );
  }

  await tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: ExpenseWorkProfileScope(
        controller: workProfiles,
        child: ActiveWorkdayScope(
          controller: workday,
          child: GlobalOdometerScope(
            controller: odometer,
            child: OperationalContextScope(
              controller: operational,
              child: MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: textScaler),
                  child: child!,
                ),
                home: const DashboardScreen(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return _DashboardHarness(
    appState: appState,
    odometer: odometer,
    workProfiles: workProfiles,
    operational: operational,
    workday: workday,
  );
}

class _DashboardHarness {
  const _DashboardHarness({
    required this.appState,
    required this.odometer,
    required this.workProfiles,
    required this.operational,
    required this.workday,
  });

  final AppStateController appState;
  final GlobalOdometerController odometer;
  final ExpenseWorkProfileController workProfiles;
  final OperationalContextController operational;
  final ActiveWorkdayController workday;

  void dispose() {
    appState.dispose();
    odometer.dispose();
    workProfiles.dispose();
    operational.dispose();
    workday.dispose();
  }
}
