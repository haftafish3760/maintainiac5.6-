// Widget regression coverage for active-workday context handoff confirmation.
//
// Owns user-visible selection and same-vehicle odometer-boundary behavior.
// It does not persist the draft or exercise the durable handoff coordinator.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/active_workday_context_handoff_sheet.dart';
import 'package:maintaniac/screens/expenses/data/expense_work_profile_store.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  testWidgets('same-vehicle profile handoff keeps one odometer boundary', (
    tester,
  ) async {
    ActiveWorkdayContextHandoffDraft? result;
    final vehicle = _vehicle('vehicle-1', 'Work Truck');
    final profile = _profile('profile-1', 'Delivery');

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await openActiveWorkdayContextHandoffSheet(
                context,
                currentVehicle: vehicle,
                currentWorkProfile: profile,
                currentOdometer: 12000,
                vehicles: [vehicle],
                workProfiles: [profile],
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    expect(find.text('Change workday context'), findsOneWidget);
    expect(find.text('Same vehicle boundary'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, '12012');
    await tester.tap(find.text('Review change'));
    await tester.pumpAndSettle();

    expect(result?.endingOdometer, 12012);
    expect(result?.startingOdometer, 12012);
    expect(result?.vehicle.id, 'vehicle-1');
    expect(result?.workProfile.id, 'profile-1');
  });
}

VehicleProfile _vehicle(String id, String nickname) => VehicleProfile(
  id: id,
  nickname: nickname,
  year: '2024',
  make: 'Maintainiac',
  model: 'Test',
);

ExpenseWorkProfile _profile(String id, String name) => ExpenseWorkProfile(
  id: id,
  name: name,
  createdAt: DateTime.utc(2026, 7, 29),
  updatedAt: DateTime.utc(2026, 7, 29),
);
