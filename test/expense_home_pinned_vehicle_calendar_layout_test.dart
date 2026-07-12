import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense home pins vehicle and moves daily context to calendar', () {
    final shell = File(
      'lib/shared/widgets/app_screen_shell.dart',
    ).readAsStringSync();
    final home = File(
      'lib/screens/expenses/home/expenses_home_screen.dart',
    ).readAsStringSync();
    final day = File(
      'lib/screens/expenses/calendar/expense_day_screen.dart',
    ).readAsStringSync();
    final calendarHeader = File(
      'lib/screens/expenses/calendar/expense_calendar_context_header.dart',
    ).readAsStringSync();

    expect(shell, contains('this.pinnedHeader'));
    expect(shell, contains('Expanded(child: body)'));
    expect(
      home,
      contains(
        'pinnedHeader: const GlobalOdometerHeader(section: AppSection.expenses)',
      ),
    );
    expect(home, isNot(contains('_ExpenseDayNavigatorPanel(')));
    expect(day, contains('_ExpenseCalendarContextHeader(day: _day)'));
    expect(calendarHeader, contains("'Daily Expenses'"));
  });
}
