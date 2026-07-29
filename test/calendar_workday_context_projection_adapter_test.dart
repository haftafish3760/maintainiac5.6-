import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_context_segment.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_store.dart';
import 'package:maintaniac/shared/calendar/calendar_projection_contract.dart';
import 'package:maintaniac/shared/calendar/calendar_workday_context_projection_adapter.dart';

void main() {
  test('user-confirmed vehicle/profile handoff projects to workday detail', () {
    final event = CalendarWorkdayContextProjectionAdapter.eventsForDay([
      _session(),
    ], DateTime(2026, 7, 22)).single;

    expect(event.source, CalendarProjectionSource.vehicleProfile);
    expect(event.state, CalendarProjectionState.confirmed);
    expect(event.timing.actualAt, DateTime(2026, 7, 22, 13));
    expect(event.deepLink.target, CalendarDeepLinkTarget.vehicleProfileDetail);
    expect(event.deepLink.sourceRecordId, 'workday-1');
    expect(event.deepLink.argumentId, 'segment-2');
    expect(event.conciseDetail, contains('Van 1 → Truck 2'));
  });

  test('initial workday context is not falsely presented as a handoff', () {
    final session = _session().copyWith(
      contextSegments: [_segment(id: 'segment-1', vehicleId: 'van-1')],
    );

    expect(
      CalendarWorkdayContextProjectionAdapter.eventsForDay([
        session,
      ], DateTime(2026, 7, 22)),
      isEmpty,
    );
  });
}

ActiveWorkdaySessionRecord _session() => ActiveWorkdaySessionRecord(
  id: 'workday-1',
  vehicleId: 'van-1',
  vehicleLabel: 'Van 1',
  workProfileId: 'delivery',
  startedAt: DateTime(2026, 7, 22, 8),
  startOdometer: 100,
  status: ActiveWorkdayStatus.active,
  events: const [],
  contextSegments: [
    _segment(id: 'segment-1', vehicleId: 'van-1'),
    _segment(
      id: 'segment-2',
      vehicleId: 'truck-2',
      label: 'Truck 2',
      profileId: 'service',
      startedAt: DateTime(2026, 7, 22, 13),
      startOdometer: 120,
    ),
  ],
);

ActiveWorkdayContextSegment _segment({
  required String id,
  required String vehicleId,
  String label = 'Van 1',
  String profileId = 'delivery',
  DateTime? startedAt,
  int startOdometer = 100,
}) => ActiveWorkdayContextSegment(
  id: id,
  vehicleId: vehicleId,
  vehicleLabel: label,
  workProfileId: profileId,
  startedAt: startedAt ?? DateTime(2026, 7, 22, 8),
  startOdometer: startOdometer,
);
