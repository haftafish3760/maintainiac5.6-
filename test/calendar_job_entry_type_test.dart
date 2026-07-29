import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/shared/calendar/calendar_flow_models.dart';

void main() {
  test('Dashboard Quick Add preserves the established job-free tile set', () {
    final types = calendarTypesForSource(
      CalendarDayMode.future,
      CalendarFlowSource.dashboard,
    );

    expect(types, isNot(contains(CalendarEntryType.job)));
    expect(calendarEntryMeta(CalendarEntryType.job).label, 'Job / Appointment');
  });

  test('projected jobs retain the job entry identity', () {
    expect(CalendarEntryType.job, isNot(CalendarEntryType.invoiceEstimate));
  });
}
