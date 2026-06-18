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
    expect(find.text('Needs Attention'), findsOneWidget);
    expect(find.text('Start Contractor Day'), findsOneWidget);

    await tester.dragUntilVisible(
      find.text('Today Jobs'),
      find.byType(ListView).last,
      const Offset(0, -220),
    );
    expect(find.text('Today Jobs'), findsOneWidget);
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

    expect(find.text('Active Job'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Use Materials'),
      find.byType(ListView).last,
      const Offset(0, -220),
    );
    expect(find.text('Use Materials'), findsOneWidget);
    expect(find.text('Add Expense'), findsOneWidget);
    expect(find.text('Invoice'), findsOneWidget);
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Proof Photo'), findsOneWidget);
  });
}
