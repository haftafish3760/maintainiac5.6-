// Calendar month badge model. It converts read-only projection events into
// count and state indicators; it never persists or reclassifies a record.

import 'calendar_projection_contract.dart';

class CalendarMonthEventBadge {
  const CalendarMonthEventBadge({
    required this.entryCount,
    required this.plannedEntryCount,
    required this.confirmedEntryCount,
    required this.reviewRequiredEntryCount,
    required this.hasScheduled,
    required this.hasCompleted,
  });

  factory CalendarMonthEventBadge.fromEvents(
    Iterable<CalendarProjectionEvent> events,
  ) {
    final values = events.toList(growable: false);
    final plannedEntryCount = values
        .where(
          (event) =>
              event.timing.timeSource == CalendarTimeSource.scheduled ||
              event.state == CalendarProjectionState.proposed,
        )
        .length;
    final confirmedEntryCount = values
        .where(
          (event) =>
              event.state == CalendarProjectionState.confirmed ||
              event.state == CalendarProjectionState.historical,
        )
        .length;
    final reviewRequiredEntryCount = values
        .where(
          (event) => switch (event.state) {
            CalendarProjectionState.proposed ||
            CalendarProjectionState.needsReview ||
            CalendarProjectionState.incomplete ||
            CalendarProjectionState.blocked => true,
            _ => false,
          },
        )
        .length;
    return CalendarMonthEventBadge(
      entryCount: values.length,
      plannedEntryCount: plannedEntryCount,
      confirmedEntryCount: confirmedEntryCount,
      reviewRequiredEntryCount: reviewRequiredEntryCount,
      hasScheduled: plannedEntryCount > 0,
      hasCompleted: confirmedEntryCount > 0,
    );
  }

  final int entryCount;
  final int plannedEntryCount;
  final int confirmedEntryCount;
  final int reviewRequiredEntryCount;
  final bool hasScheduled;
  final bool hasCompleted;
}
