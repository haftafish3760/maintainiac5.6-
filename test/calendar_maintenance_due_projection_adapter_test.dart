import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_maintenance_due_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test(
    'calendar projects confirmed date interval without inventing mileage date',
    () {
      final record = MaintenanceRecord(
        recordId: 'oil-1',
        vehicleId: 'truck-1',
        itemName: 'Oil change',
        vehicleName: 'Work truck',
        intervalMiles: 5000,
        milesSinceService: 0,
        intervalMonths: 3,
        monthsSinceService: 0,
        importance: 1,
        setupComplete: true,
        lastServiceDate: DateTime(2026, 1, 31),
        updatedAt: DateTime(2026, 2, 1),
        revision: 2,
      );

      final events = CalendarMaintenanceDueProjectionAdapter.eventsForDay(
        [record],
        DateTime(2026, 4, 30),
        now: DateTime(2026, 3, 1),
      ).toList();

      expect(events, hasLength(1));
      expect(events.single.timing.timeSource, CalendarTimeSource.scheduled);
      expect(events.single.state, CalendarProjectionState.proposed);
      expect(events.single.deepLink.sourceRecordId, 'oil-1');
    },
  );

  test('disabled maintenance thresholds do not create a calendar reminder', () {
    final record = MaintenanceRecord(
      recordId: 'oil-disabled',
      vehicleId: 'truck-1',
      itemName: 'Oil change',
      vehicleName: 'Work truck',
      intervalMiles: 5000,
      milesSinceService: 0,
      intervalMonths: 3,
      monthsSinceService: 0,
      importance: 1,
      setupComplete: true,
      thresholdsEnabled: false,
      lastServiceDate: DateTime(2026, 1, 31),
    );

    final events = CalendarMaintenanceDueProjectionAdapter.eventsForDay([
      record,
    ], DateTime(2026, 4, 30)).toList();

    expect(events, isEmpty);
  });
}
