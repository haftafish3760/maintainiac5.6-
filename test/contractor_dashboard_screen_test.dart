import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard.dart';
import 'package:maintaniac/shared/state/app_state.dart';
import 'package:maintaniac/shared/state/global_odometer.dart';

void main() {
  late AppStateController appState;
  late GlobalOdometerController odometer;

  setUp(() {
    appState = AppStateController();
    odometer = GlobalOdometerController();
  });

  tearDown(() {
    appState.dispose();
    odometer.dispose();
  });

  testWidgets('dashboard opens contractor command center', (tester) async {
    await _pumpDashboard(tester, appState, odometer);

    expect(find.text('Contractor Dashboard'), findsOneWidget);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Contractor Command Center'), findsOneWidget);
    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('Solo'), findsOneWidget);
    expect(find.text('Operations Pulse'), findsOneWidget);
    expect(find.text('Today Status'), findsOneWidget);
    expect(find.text('Cloud Backup'), findsOneWidget);
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
    await _pumpDashboard(tester, appState, odometer);

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
}

Future<void> _pumpDashboard(
  WidgetTester tester,
  AppStateController appState,
  GlobalOdometerController odometer,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(900, 1500);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    AppStateScope(
      controller: appState,
      child: GlobalOdometerScope(
        controller: odometer,
        child: const MaterialApp(home: DashboardScreen()),
      ),
    ),
  );
}
