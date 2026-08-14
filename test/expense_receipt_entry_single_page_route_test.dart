import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every receipt entry starts with the shared single-page form', () {
    final flow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();

    // Every user-visible new-receipt route constructs this screen. Keeping
    // the entry decision here prevents one surface from reopening the former
    // Details → Items → Review wizard while another uses the approved form.
    const entryRouteFiles = [
      'lib/app/incoming_receipt_destination_screen.dart',
      'lib/screens/dashboard/active_workday_expense_actions.dart',
      'lib/screens/dashboard/contractor/contractor_dashboard_actions.dart',
      'lib/screens/dashboard/gig_dashboard_record_review_screens.dart',
      'lib/screens/expenses/calendar/expense_calendar_actions.dart',
      'lib/screens/expenses/calendar/expense_day_screen.dart',
      'lib/screens/expenses/entry/expense_receipt_duplicate_dialog.dart',
      'lib/screens/expenses/home/expenses_home_navigation_actions.dart',
      'lib/shared/calendar/calendar_owner_entry_router.dart',
    ];

    expect(
      flow,
      contains(
        'bool get _usesRebuiltManualDetailedReceiptFlow =>\n'
        '      !_isEditingReceipt || (!_isMaterialsFlow && !_isMaintenanceRepairFlow);',
      ),
    );
    final homeNavigation = File(
      'lib/screens/expenses/home/expenses_home_navigation_actions.dart',
    ).readAsStringSync();
    expect(homeNavigation, contains("initialCategory: 'Materials'"));
    expect(
      homeNavigation,
      contains('_openMaterialReceipt(context, initialDate: initialDate)'),
    );
    for (final path in entryRouteFiles) {
      expect(
        File(path).readAsStringSync(),
        contains('ExpenseReceiptEntryScreen('),
      );
    }
  });
}
