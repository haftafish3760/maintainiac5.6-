import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shared Calendar panel preserves the fixed large-month tile layout', () {
    final source = File(
      'lib/shared/calendar/app_month_calendar.dart',
    ).readAsStringSync();

    expect(source, contains('calendarFormat: CalendarFormat.month'));
    expect(source, contains('formatButtonVisible: false'));
    expect(source, isNot(contains('CalendarFormat.week: \'Week\'')));
    expect(source, isNot(contains('onFormatChanged: (format)')));
    expect(source, contains('_focusedDay = focusedDay'));
    expect(source, contains('firstDay: DateTime.utc(1900)'));
    expect(source, contains('lastDay: DateTime.utc(2100, 12, 31)'));
  });
}
