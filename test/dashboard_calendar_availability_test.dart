// Dashboard Calendar availability regression coverage.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dashboard Calendar is present before and during an active workday', () {
    final dashboard = File(
      'lib/screens/dashboard/dashboard.dart',
    ).readAsStringSync();
    final activeWorkday = File(
      'lib/screens/dashboard/active_workday_screen.dart',
    ).readAsStringSync();

    expect(dashboard, contains('DashboardCalendar()'));
    expect(
      activeWorkday,
      contains("import '../../shared/calendar/calendar.dart';"),
    );
    expect(activeWorkday, contains('const DashboardCalendar()'));
    expect(
      activeWorkday.indexOf('const DashboardCalendar()'),
      greaterThan(activeWorkday.indexOf('_SessionActivityList(')),
    );
  });
}
