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

    expect(find.text('Start Your Delivery Day'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);

    await tester.tap(find.text('Work Truck'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delivery Van'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Delivery'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rideshare'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enter Odometer'));
    await tester.pumpAndSettle();

    expect(result?.vehicleId, van.id);
    expect(result?.workProfileId, rideshare.id);
  });

  testWidgets('does not invent choices when only one context exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => openGigStartDaySetupSheet(
                context,
                vehicles: [truck],
                workProfiles: [delivery],
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

    expect(find.text('Only work profile'), findsOneWidget);
    expect(find.text('Only available vehicle'), findsOneWidget);
  });
}
