import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_maintenance_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/state/app_state.dart';

void main() {
  test(
    'maintenance projection preserves service date and source-detail identity',
    () {
      final event = MaintenanceServiceEvent(
        eventId: 'service-1',
        vehicleId: 'truck-1',
        vehicleName: 'Work Truck',
        itemName: 'Oil change',
        serviceDate: DateTime(2026, 7, 22),
        odometer: 120000,
        totalCost: 79.95,
        receiptProofCount: 1,
        createdAt: DateTime(2026, 7, 28, 10),
      );

      final events = CalendarMaintenanceProjectionAdapter.eventsForDay([
        event,
      ], DateTime(2026, 7, 22));

      expect(events, hasLength(1));
      expect(events.single.timing.eventDate, DateTime(2026, 7, 22));
      expect(events.single.timing.timeSource, CalendarTimeSource.unknown);
      expect(
        events.single.deepLink.target,
        CalendarDeepLinkTarget.maintenanceDetail,
      );
      expect(events.single.deepLink.sourceRecordId, 'service-1');
      expect(events.single.evidence.summary, '1 receipt proof(s) attached.');
    },
  );
}
