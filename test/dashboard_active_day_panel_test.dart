import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/dashboard_active_day_panel.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';

void main() {
  testWidgets('dashboard active day panel shows workday stop entries', (
    tester,
  ) async {
    final session = ActiveWorkdaySessionRecord(
      id: 'workday_test',
      vehicleId: 'truck_1',
      vehicleLabel: 'Work Truck 1',
      workProfileId: 'contractor',
      startedAt: DateTime(2026, 7, 23, 8),
      startOdometer: 3284,
      status: ActiveWorkdayStatus.active,
      events: [
        ActiveWorkdayEvent(
          id: 'event_started',
          type: ActiveWorkdayEventType.started,
          occurredAt: DateTime(2026, 7, 23, 8),
          odometerReading: 3284,
          label: 'Workday started',
        ),
        ActiveWorkdayEvent(
          id: 'event_fuel',
          type: ActiveWorkdayEventType.fuel,
          occurredAt: DateTime(2026, 7, 23, 9, 15),
          odometerReading: 3291,
          label: 'Fuel stop',
          note: 'Fuel entry started',
        ),
        ActiveWorkdayEvent(
          id: 'event_stop',
          type: ActiveWorkdayEventType.stop,
          occurredAt: DateTime(2026, 7, 23, 10),
          odometerReading: 3302,
          label: 'Stop logged',
          note: 'Supply house',
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(home: DashboardActiveDayPanel(session: session)),
    );

    expect(find.text('Today: Work Truck 1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('Fuel stop at 3291 mi'), findsOneWidget);
    expect(find.textContaining('Stop logged at 3302 mi'), findsOneWidget);
    expect(find.textContaining('Workday started'), findsNothing);
  });
}
