import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Jobs use one shared durable owner across app surfaces', () {
    final main = File('lib/main.dart').readAsStringSync();
    final jobsScreen = File(
      'lib/screens/work_supplies/jobs/work_supply_jobs_screen.dart',
    ).readAsStringSync();
    final jobsActions = File(
      'lib/screens/work_supplies/jobs/work_supply_jobs_actions.dart',
    ).readAsStringSync();
    final jobsDaySections = File(
      'lib/screens/work_supplies/jobs/work_supply_jobs_day_sections.dart',
    ).readAsStringSync();
    final receiptScreen = File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsStringSync();
    final receiptJobPanel = File(
      'lib/screens/expenses/entry/expense_receipt_entry_job_context_panel.dart',
    ).readAsStringSync();

    expect(main, contains('MaintainiacJobController.create()'));
    expect(main, contains('MaintainiacJobScope('));
    expect(jobsScreen, contains('MaintainiacJobScope.of('));
    expect(jobsScreen, contains(').activeJobs.map(_workSupplyJobFromRecord)'));
    expect(
      jobsActions,
      contains('MaintainiacJobScope.of(currentContext).save'),
    );
    expect(jobsDaySections, isNot(contains('_demoJobs')));
    expect(
      receiptScreen,
      contains("part 'expense_receipt_entry_job_context_panel.dart';"),
    );
    expect(receiptJobPanel, contains('MaintainiacJobScope.maybeOf(context)'));
    expect(receiptJobPanel, contains("title: const Text('No job')"));
    expect(receiptJobPanel, contains("title: const Text('Create a job')"));
    expect(receiptJobPanel, contains('_scheduleDraftSave()'));
    expect(
      receiptJobPanel,
      isNot(contains('ExpenseJobController')),
      reason: 'Do not recreate the old Expense-only Jobs owner.',
    );
  });
}
