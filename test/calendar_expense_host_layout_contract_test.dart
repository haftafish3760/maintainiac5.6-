// Calendar regression: Expenses keeps the shared, responsive Calendar tiles.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Expense Calendar host reuses the shared expense tile layout', () {
    final host = File(
      'lib/screens/expenses/calendar/expense_month_calendar.dart',
    ).readAsStringSync();

    expect(host, contains('const ExpenseAppCalendar()'));
    expect(host, isNot(contains('class _ExpenseCalendarCell')));
    expect(host, isNot(contains('TableCalendar<void>')));
  });
}
