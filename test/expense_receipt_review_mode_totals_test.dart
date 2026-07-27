import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review modes expose only the promised amount fields', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_totals.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('detailMode == _ReceiptDetailEntryMode.detailedItems'),
    );
    expect(
      source,
      contains('detailMode == _ReceiptDetailEntryMode.basicReceipt'),
    );
    expect(source, contains("priceOnly ? 'Price Paid'"));
    expect(source, contains("'Final Total After Tax'"));
    expect(source, contains("label: 'Receipt Subtotal'"));
    expect(source, contains("label: 'Sales Tax'"));
  });

  test('receipt form exposes all three detail levels and summary controls', () {
    final screen = File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsStringSync();
    final scaffold = File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsStringSync();
    final manualFlow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();
    final panel = File(
      'lib/screens/expenses/entry/expense_receipt_detail_level_panel.dart',
    ).readAsStringSync();
    final actions = File(
      'lib/screens/expenses/entry/expense_receipt_entry_line_mode_helpers.dart',
    ).readAsStringSync();
    final splitActions = File(
      'lib/screens/expenses/entry/expense_receipt_entry_split_percent_actions.dart',
    ).readAsStringSync();
    final lineActions = File(
      'lib/screens/expenses/entry/expense_receipt_line_actions.dart',
    ).readAsStringSync();
    final lineEditor = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor.dart',
    ).readAsStringSync();
    final noLineRecovery = File(
      'lib/screens/expenses/entry/expense_receipt_entry_no_line_recovery_panel.dart',
    ).readAsStringSync();
    final categoryScope = File(
      'lib/screens/expenses/entry/expense_receipt_category_scope_panel.dart',
    ).readAsStringSync();
    final parseApply = File(
      'lib/screens/expenses/entry/expense_receipt_entry_parse_apply_actions.dart',
    ).readAsStringSync();
    final recap = File(
      'lib/screens/expenses/entry/expense_receipt_recap.dart',
    ).readAsStringSync();
    final recapLines = File(
      'lib/screens/expenses/entry/expense_receipt_recap_line_controls.dart',
    ).readAsStringSync();

    expect(screen, contains("part 'expense_receipt_detail_level_panel.dart';"));
    expect(scaffold, contains('_buildManualDetailedReceiptFlow(context)'));
    expect(scaffold, contains('_ReceiptSummaryUsePanel('));
    expect(panel, contains("title: 'Receipt Detail'"));
    expect(panel, contains('Change this receipt only'));
    expect(panel, contains('Your default stays in Receipt Settings.'));
    expect(panel, contains("label: 'Business'"));
    expect(panel, contains("label: 'Personal'"));
    expect(panel, contains("label: 'Split'"));
    expect(actions, contains('_receiptReviewModeChangedByUser = true'));
    expect(actions, isNot(contains('Choose the expense category first.')));
    expect(actions, contains('category: _receiptCategory'));
    expect(
      scaffold,
      contains(
        '_detailEntryMode == _ReceiptDetailEntryMode.basicReceipt) ...[',
      ),
    );
    expect(lineActions, contains("'Add Category Lines'"));
    expect(lineActions, contains("'Add Another Category Line'"));
    expect(lineActions, contains('if (basicMode)'));
    expect(lineActions, contains("'Add Itemized Category Lines'"));
    expect(lineActions, contains('onTap: onSwitchToCategoryLines'));
    expect(scaffold, contains('onSwitchToCategoryLines: () =>'));
    expect(manualFlow, contains('_showManualReceiptCategoryScope(context)'));
    expect(categoryScope, contains("title: 'Receipt Category Setup'"));
    expect(categoryScope, contains("label: 'One Category'"));
    expect(categoryScope, contains("label: 'Category Per Line'"));
    expect(categoryScope, contains('Categories stay optional either way.'));
    expect(actions, contains('void _selectReceiptCategoryScope'));
    expect(actions, contains('_receiptCategoryAppliesToAll = appliesToAll'));
    expect(actions, contains('String get _newReceiptLineCategory'));
    expect(actions, contains(": 'Uncategorized';"));
    expect(
      actions,
      isNot(contains('Choose the category for this receipt line.')),
    );
    expect(scaffold, contains('category: _newReceiptLineCategory'));
    expect(
      actions,
      contains('final allocation = await _chooseSplitAllocation('),
    );
    expect(actions, contains('businessPercent: percent'));
    expect(actions, isNot(contains("label: 'Business %'")));
    expect(
      lineEditor,
      contains(
        'Category is optional. Leave it unresolved if you are not sure.',
      ),
    );
    expect(manualFlow, contains('_continueFromManualReceiptItems'));
    expect(parseApply, contains('if (!_receiptCategoryAppliesToAll)'));
    expect(scaffold, contains('detailMode: _detailEntryMode'));
    expect(recap, contains('showItemDetails'));
    expect(recapLines, contains("'Receipt line \$lineNumber'"));
    expect(recapLines, contains('showItemDetails'));
    expect(actions, contains('allowQuantity: false'));
    expect(
      splitActions,
      contains(
        'allowQuantity || method != ExpenseSplitAllocationMethod.quantity',
      ),
    );
    expect(actions, contains('replaceExisting: true'));
    expect(actions, contains('if (replaceExisting) _lines.clear();'));
    expect(
      actions,
      contains('if (replaceExisting) _lines.addAll(previousLines);'),
    );
    expect(actions, contains('_isReceiptTotalSummaryLine(_lines.single)'));
    expect(
      noLineRecovery,
      contains(
        '_selectReceiptDetailMode(_ReceiptDetailEntryMode.quickClassify)',
      ),
    );
    expect(noLineRecovery, contains("'Use Basic Receipt Lines'"));
  });
}
