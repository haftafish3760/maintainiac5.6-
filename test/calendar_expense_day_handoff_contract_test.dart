// Calendar regression: the gig-worker Expense home uses the shared day flow.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Expense home routes its day action through shared Calendar presentation',
    () {
      final homeTotals = File(
        'lib/screens/expenses/home/expenses_home_totals.dart',
      ).readAsStringSync();

      expect(homeTotals, contains('CalendarDayFlowScreen('));
      expect(homeTotals, contains('source: CalendarFlowSource.expenses'));
      expect(homeTotals, isNot(contains('ExpenseDayScreen(')));
    },
  );
}
