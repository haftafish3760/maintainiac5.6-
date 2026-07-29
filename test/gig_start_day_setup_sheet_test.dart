// Guided Gig/Delivery Start Day regression coverage.
//
// Owns the context-selection and delayed-keypad contract. It does not own
// durable vehicle/profile storage or active-workday creation.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/gig_start_day_setup_sheet.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  final createdAt = DateTime.utc(2026, 7, 28);
  final truck = VehicleProfile(id: 'truck', nickname: 'Work Truck');
  final van = VehicleProfile(id: 'van', nickname: 'Delivery Van');
  final delivery = ExpenseWorkProfile(
    id: 'delivery',
    name: 'Delivery',
    createdAt: createdAt,
    updatedAt: createdAt,
  );
  final rideshare = ExpenseWorkProfile(
    id: 'rideshare',
    name: 'Rideshare',
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  test('skips the context prompt only when both choices are singular', () {
    expect(
      shouldSkipGigStartDayContextSelection(
        vehicleCount: 1,
        workProfileCount: 1,
      ),
      isTrue,
    );
    expect(
      shouldSkipGigStartDayContextSelection(
        vehicleCount: 2,
        workProfileCount: 1,
      ),
      isFalse,
    );
    expect(
      shouldSkipGigStartDayContextSelection(
        vehicleCount: 1,
        workProfileCount: 2,
      ),
      isFalse,
    );
  });

  testWidgets('guides vehicle and work-profile choices before odometer entry', (
    tester,
  ) async {
    GigStartDayContextChoice? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                result = await openGigStartDaySetupSheet(
                  context,
                  vehicles: [truck, van],
                  workProfiles: [delivery, rideshare],
                  initialVehicleId: truck.id,
                  initialWorkProfileId: delivery.id,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    expect(find.text('Start workday'), findsOneWidget);
    expect(
      find.text('Step 1 of 2: confirm who and what vehicle this workday uses.'),
      findsOneWidget,
    );
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Work Truck'));
    await tester.pumpAndSettle();
    expect(find.text('Choose vehicle'), findsOneWidget);
    expect(
      tester.widget<BottomSheet>(find.byType(BottomSheet).last).backgroundColor,
      const Color(0xFFF3F6F7),
    );
    await tester.tap(find.text('Delivery Van'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rideshare'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue to odometer'));
    await tester.pumpAndSettle();

    expect(result?.vehicleId, van.id);
    expect(result?.workProfileId, rideshare.id);
  });

  testWidgets('keeps short context choices side by side on iPhone SE width', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => openGigStartDaySetupSheet(
                context,
                vehicles: [truck, van],
                workProfiles: [delivery, rideshare],
                initialVehicleId: truck.id,
                initialWorkProfileId: delivery.id,
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final profileValue = find.text('Delivery');
    final vehicleValue = find.text('Work Truck');
    expect(profileValue, findsOneWidget);
    expect(vehicleValue, findsOneWidget);
    final profileRect = tester.getRect(profileValue);
    final vehicleRect = tester.getRect(vehicleValue);
    expect(profileRect.left, lessThan(vehicleRect.left));
    expect(profileRect.top, vehicleRect.top);
    expect(tester.takeException(), isNull);
  });
}
