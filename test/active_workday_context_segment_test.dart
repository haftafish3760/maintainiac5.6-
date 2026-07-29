// Active Workday context-segment regression coverage.
//
// Owns per-context vehicle/profile and odometer-boundary rules. Does not own
// dashboard controls, storage, GPS collection, or financial records. Consumed
// by the Active Workday handoff implementation before the UI enables switching.
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/dashboard/data/active_workday_context_segment.dart';

void main() {
  final startedAt = DateTime(2026, 7, 28, 8);

  ActiveWorkdayContextSegment segment() => ActiveWorkdayContextSegment(
    id: 'segment-1',
    vehicleId: 'truck-1',
    vehicleLabel: 'Work Truck',
    workProfileId: 'delivery',
    startedAt: startedAt,
    startOdometer: 1000,
  );

  test('open segment retains context identity and bounded mileage', () {
    final value = segment();

    expect(value.isOpen, isTrue);
    expect(
      value.matchesContext(vehicleId: 'truck-1', workProfileId: 'delivery'),
      isTrue,
    );
    expect(value.milesAt(1025), 25);
    expect(value.milesAt(999), 0);
  });

  test('closing segment preserves its immutable opening context', () {
    final closed = segment().close(
      endedAt: DateTime(2026, 7, 28, 9),
      endOdometer: 1012,
    );

    expect(closed.isClosed, isTrue);
    expect(closed.vehicleId, 'truck-1');
    expect(closed.workProfileId, 'delivery');
    expect(closed.milesAt(99999), 12);
    expect(closed.toMap()['endOdometer'], 1012);
  });

  test('segment rejects double closure, reversed time, and lower mileage', () {
    final value = segment();
    expect(
      () => value.close(endedAt: startedAt, endOdometer: 999),
      throwsArgumentError,
    );
    expect(
      () =>
          value.close(endedAt: DateTime(2026, 7, 28, 7, 59), endOdometer: 1000),
      throwsArgumentError,
    );
    final closed = value.close(
      endedAt: DateTime(2026, 7, 28, 9),
      endOdometer: 1000,
    );
    expect(
      () => closed.close(endedAt: DateTime(2026, 7, 28, 10), endOdometer: 1001),
      throwsStateError,
    );
  });

  test('corrupt persisted segment data fails closed', () {
    expect(
      ActiveWorkdayContextSegment.tryFromMap({
        'id': 'segment-1',
        'vehicleId': 'truck\n1',
        'vehicleLabel': 'Work Truck',
        'workProfileId': 'delivery',
        'startedAt': startedAt.toIso8601String(),
        'startOdometer': 1000,
      }),
      isNull,
    );
    expect(
      ActiveWorkdayContextSegment.tryFromMap({
        'id': 'segment-1',
        'vehicleId': 'truck-1',
        'vehicleLabel': 'Work Truck',
        'workProfileId': 'delivery',
        'startedAt': startedAt.toIso8601String(),
        'startOdometer': 1000,
        'endedAt': DateTime(2026, 7, 28, 9).toIso8601String(),
      }),
      isNull,
    );
  });
}
