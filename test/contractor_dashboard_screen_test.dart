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
    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    expect(find.text('Contractor Dashboard'), findsOneWidget);

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();

    expect(find.text('Contractor Command Center'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -260));
    await tester.pumpAndSettle();
    expect(find.text('Needs Attention'), findsOneWidget);
  });

  testWidgets('contractor dashboard exposes active day tools', (tester) async {
    await tester.pumpWidget(
      AppStateScope(
        controller: appState,
        child: GlobalOdometerScope(
          controller: odometer,
          child: const MaterialApp(home: DashboardScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Contractor Dashboard'));
    await tester.pumpAndSettle();
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
