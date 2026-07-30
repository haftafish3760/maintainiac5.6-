// Calendar ownership: verifies Jobs has a source-specific calendar surface.

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';
import 'package:maintaniac/shared/calendar/calendar_day_flow_support.dart';

void main() {
  test(
    'Jobs calendar labels itself and limits source-specific add choices',
    () {
      expect(calendarScreenTitle(CalendarFlowSource.jobs), 'Jobs Calendar');
      expect(calendarAppSectionFor(CalendarFlowSource.jobs).name, 'materials');
      expect(
      calendarTypesForSource(CalendarDayMode.future, CalendarFlowSource.jobs),
        [
          CalendarEntryType.job,
          CalendarEntryType.reminderSchedule,
          CalendarEntryType.note,
        ],
      );
    },
  );
}
