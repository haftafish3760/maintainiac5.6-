import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('expense forms return the saved record to their caller', () {
    final saveActions = File(
      'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    ).readAsStringSync();

    expect(saveActions, contains('Navigator.of(context).pop(saved);'));
    expect(saveActions, isNot(contains('Navigator.of(context).pop();')));
  });

  test('dashboard workday events are created only after expense save', () {
    for (final path in [
      'lib/screens/dashboard/active_workday_expense_actions.dart',
      'lib/screens/dashboard/contractor/contractor_dashboard_actions.dart',
      'lib/screens/dashboard/dashboard_shortcuts.dart',
    ]) {
      final source = File(path).readAsStringSync();
      final navigationIndex = source.indexOf('push<ExpenseReceiptRecord>');
      final savedGuardIndex = source.indexOf('saved == null');
      final eventIndex = path.contains('contractor_dashboard_actions')
          ? source.indexOf('_recordContractorDayEvent(')
          : source.indexOf('addEvent(');

      expect(navigationIndex, greaterThanOrEqualTo(0), reason: path);
      expect(savedGuardIndex, greaterThan(navigationIndex), reason: path);
      expect(eventIndex, greaterThan(savedGuardIndex), reason: path);
      expect(source, isNot(contains('entry started')), reason: path);
    }
  });

  test('workday handoff uses the final saved expense odometer', () {
    for (final path in [
      'lib/screens/dashboard/active_workday_expense_actions.dart',
      'lib/screens/dashboard/contractor/contractor_dashboard_actions.dart',
      'lib/screens/dashboard/dashboard_shortcuts.dart',
    ]) {
      final source = File(path).readAsStringSync();
      expect(source, contains('saved.odometerReading ??'), reason: path);
    }
  });
}
