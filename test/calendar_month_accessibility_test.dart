import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/app_month_calendar.dart';

void main() {
  test('month-cell accessibility label explains counts and state', () {
    final label = calendarDayAccessibilityLabel(
      day: DateTime(2026, 7, 29),
      entryCount: 3,
      hasScheduled: true,
      hasCompleted: true,
      isOutsideMonth: false,
    );

    expect(
      label,
      '7/29/2026. 3 calendar entries. scheduled work. '
      'confirmed or historical records',
    );
  });

  test('outside month date does not claim current-month entry counts', () {
    final label = calendarDayAccessibilityLabel(
      day: DateTime(2026, 8, 1),
      entryCount: 0,
      hasScheduled: false,
      hasCompleted: false,
      isOutsideMonth: true,
    );

    expect(label, contains('outside the selected month'));
    expect(label, isNot(contains('no calendar entries')));
  });
}
