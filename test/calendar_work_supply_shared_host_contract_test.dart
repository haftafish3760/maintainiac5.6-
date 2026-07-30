// Calendar regression: Work Supplies must use the shared month-tile system.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Work Supplies has no competing month-calendar renderer', () {
    final panel = File(
      'lib/screens/work_supplies/calendar/work_supply_calendar_panel.dart',
    ).readAsStringSync();

    expect(
      panel,
      contains('class WorkSupplyCalendarPanel extends StatelessWidget'),
    );
    expect(panel, contains('required this.calendarSource'));
    expect(panel, contains('AppMonthCalendar('));
    expect(panel, isNot(contains('TableCalendar<void>')));
    expect(panel, isNot(contains('class _CalendarPanelPainter')));
  });
}
