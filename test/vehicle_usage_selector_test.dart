// Vehicle-use selection UI regression coverage.
//
// Owns the neutral new-profile choice contract. It does not own vehicle
// persistence or Start Day behavior. Consumed by the dashboard vehicle form.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_flow.dart';
import 'package:maintaniac/screens/dashboard/vehicle_profile_widgets.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  testWidgets('new vehicle usage begins neutral and requires a driver choice', (
    tester,
  ) async {
    VehicleUsage? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VehicleUsageSelector(
            value: null,
            onChanged: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('What do you use this vehicle for?'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNothing);

    await tester.tap(find.text('Business only'));

    expect(selected, VehicleUsage.businessOnly);
  });

  testWidgets('saved vehicle usage remains visibly selected', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VehicleUsageSelector(
            value: VehicleUsage.businessPersonal,
            onChanged: _ignoreVehicleUsage,
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    expect(find.text('Business + personal'), findsOneWidget);
  });

  testWidgets('new vehicle profile cannot save until vehicle use is chosen', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AddVehicleProfileScreen()));
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();

    FilledButton saveButton() => tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Save Profile'),
    );

    expect(saveButton().onPressed, isNull);

    await tester.ensureVisible(find.text('Personal only'));
    await tester.pump();
    await tester.tap(find.text('Personal only'));
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, -1200));
    await tester.pump();

    expect(saveButton().onPressed, isNotNull);
  });
}

void _ignoreVehicleUsage(VehicleUsage _) {}
