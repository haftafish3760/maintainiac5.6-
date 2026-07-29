import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_context_segment.dart';
import 'package:maintaniac/shared/calendar/calendar_active_workday_projection_adapter.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';

void main() {
  test('reloaded UTC activity stays on its local Calendar day', () {
    final occurredAt = DateTime.utc(2026, 7, 23, 3, 30);
    final localDay = occurredAt.toLocal();
    final session = _session(
      startedAt: occurredAt,
      events: [_event(occurredAt: occurredAt)],
    );

    final events = CalendarActiveWorkdayProjectionAdapter.eventsForDay([
      session,
    ], DateTime(localDay.year, localDay.month, localDay.day)).toList();

    expect(events, hasLength(2));
    expect(events.first.timing.actualAt, localDay);
    expect(events.last.timing.actualAt, localDay);
  });

  test(
    'paused workday remains review-required while dated events remain actual',
    () {
      final day = DateTime(2026, 7, 29);
      final session = ActiveWorkdaySessionRecord(
        id: 'day-1',
        vehicleId: 'truck-1',
        vehicleLabel: 'Work truck',
        workProfileId: 'contractor',
        startedAt: DateTime(2026, 7, 29, 8),
        startOdometer: 100,
        status: ActiveWorkdayStatus.paused,
        events: [
          ActiveWorkdayEvent(
            id: 'stop-1',
            type: ActiveWorkdayEventType.stop,
            occurredAt: DateTime(2026, 7, 29, 9),
            odometerReading: 110,
            label: 'Jones Tree Work',
          ),
        ],
      );
      final events = CalendarActiveWorkdayProjectionAdapter.eventsForDay([
        session,
      ], day).toList();

      expect(events, hasLength(2));
      expect(events.first.state, CalendarProjectionState.needsReview);
      expect(events.last.source, CalendarProjectionSource.stop);
      expect(events.last.timing.timeSource, CalendarTimeSource.actual);
    },
  );

  test(
    'handoff events retain their source context without duplicate handoff',
    () {
      final session = ActiveWorkdaySessionRecord(
        id: 'handoff-day',
        vehicleId: 'van-1',
        vehicleLabel: 'Van 1',
        workProfileId: 'delivery',
        startedAt: DateTime(2026, 7, 29, 8),
        startOdometer: 100,
        status: ActiveWorkdayStatus.active,
        contextSegments: [
          _context(
            id: 'context-1',
            vehicleId: 'van-1',
            vehicleLabel: 'Van 1',
            workProfileId: 'delivery',
            startedAt: DateTime(2026, 7, 29, 8),
            endedAt: DateTime(2026, 7, 29, 12),
            endOdometer: 120,
          ),
          _context(
            id: 'context-2',
            vehicleId: 'truck-2',
            vehicleLabel: 'Truck 2',
            workProfileId: 'service',
            startedAt: DateTime(2026, 7, 29, 12),
          ),
        ],
        events: [
          ActiveWorkdayEvent(
            id: 'handoff',
            type: ActiveWorkdayEventType.contextChanged,
            occurredAt: DateTime(2026, 7, 29, 12),
            odometerReading: 120,
            label: 'Context changed',
            contextSegmentId: 'context-2',
          ),
          ActiveWorkdayEvent(
            id: 'truck-stop',
            type: ActiveWorkdayEventType.stop,
            occurredAt: DateTime(2026, 7, 29, 13),
            odometerReading: 125,
            label: 'Service stop',
            contextSegmentId: 'context-2',
          ),
        ],
      );

      final events = CalendarActiveWorkdayProjectionAdapter.eventsForDay([
        session,
      ], DateTime(2026, 7, 29)).toList();

      expect(events, hasLength(2));
      expect(events.last.source, CalendarProjectionSource.stop);
      expect(events.last.vehicleIds, ['truck-2']);
      expect(events.last.workProfileId, 'service');
    },
  );
}

ActiveWorkdayContextSegment _context({
  required String id,
  required String vehicleId,
  required String vehicleLabel,
  required String workProfileId,
  required DateTime startedAt,
  DateTime? endedAt,
  int? endOdometer,
}) => ActiveWorkdayContextSegment(
  id: id,
  vehicleId: vehicleId,
  vehicleLabel: vehicleLabel,
  workProfileId: workProfileId,
  startedAt: startedAt,
  startOdometer: 100,
  endedAt: endedAt,
  endOdometer: endOdometer,
);

ActiveWorkdaySessionRecord _session({
  required DateTime startedAt,
  required List<ActiveWorkdayEvent> events,
}) => ActiveWorkdaySessionRecord(
  id: 'reloaded-day-1',
  vehicleId: 'truck-1',
  vehicleLabel: 'Work truck',
  workProfileId: 'contractor',
  startedAt: startedAt,
  startOdometer: 100,
  status: ActiveWorkdayStatus.active,
  events: events,
);

ActiveWorkdayEvent _event({required DateTime occurredAt}) => ActiveWorkdayEvent(
  id: 'reloaded-event-1',
  type: ActiveWorkdayEventType.stop,
  occurredAt: occurredAt,
  odometerReading: 110,
  label: 'Reloaded stop',
);
