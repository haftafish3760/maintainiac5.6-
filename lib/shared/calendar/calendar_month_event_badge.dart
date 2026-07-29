// Calendar month badge model. It converts read-only projection events into
// count and state indicators; it never persists or reclassifies a record.

import 'calendar_projection_contract.dart';

class CalendarMonthEventBadge {
  const CalendarMonthEventBadge({
    required this.entryCount,
    required this.hasScheduled,
    required this.hasCompleted,
  });

  factory CalendarMonthEventBadge.fromEvents(
    Iterable<CalendarProjectionEvent> events,
  ) {
    final values = events.toList(growable: false);
    return CalendarMonthEventBadge(
      entryCount: values.length,
      hasScheduled: values.any(
        (event) => event.timing.timeSource == CalendarTimeSource.scheduled,
      ),
      hasCompleted: values.any(
        (event) =>
            event.state == CalendarProjectionState.confirmed ||
            event.state == CalendarProjectionState.historical,
      ),
    );
  }

  final int entryCount;
  final bool hasScheduled;
  final bool hasCompleted;
}
