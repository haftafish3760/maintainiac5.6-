import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/screens/expenses/profiles/expense_work_profile_screen.dart';

void main() {
  testWidgets('Android back safely dismisses an empty work-profile editor', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1080, 2340);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final profiles = ExpenseWorkProfileController.memory();
    addTearDown(profiles.dispose);

    await tester.pumpWidget(
      ExpenseWorkProfileScope(
        controller: profiles,
        child: const MaterialApp(home: ExpenseWorkProfileScreen()),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Add work profile'));
    await tester.pumpAndSettle();
    expect(find.text('New work profile'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('New work profile'), findsNothing);
    expect(find.text('Work profiles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
