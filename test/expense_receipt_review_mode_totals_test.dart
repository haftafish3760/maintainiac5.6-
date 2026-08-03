import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unified receipt form always exposes full receipt totals', () {
    final totals = File(
      'lib/screens/expenses/entry/expense_receipt_totals.dart',
    ).readAsStringSync();

    expect(totals, contains("label: 'Receipt Subtotal'"));
    expect(totals, contains("label: 'Sales Tax'"));
    expect(totals, contains("label: 'Final Total After Tax'"));
    expect(totals, isNot(contains("priceOnly ? 'Price Paid'")));
  });

  test('receipt entry has no user-selectable receipt types', () {
    final screen = File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsStringSync();
    final scaffold = File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsStringSync();
    final settings = File(
      'lib/screens/expenses/settings/expense_settings_screen.dart',
    ).readAsStringSync();
    final attachmentPanel = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel.dart',
    ).readAsStringSync();
    final captureSettings = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsStringSync();
    final actions = File(
      'lib/screens/expenses/entry/expense_receipt_entry_line_mode_helpers.dart',
    ).readAsStringSync();
    final lineEditor = File(
      'lib/screens/expenses/entry/expense_receipt_line_editor.dart',
    ).readAsStringSync();
    final recap = File(
      'lib/screens/expenses/entry/expense_receipt_recap.dart',
    ).readAsStringSync();

    expect(screen, isNot(contains("expense_receipt_detail_level_panel.dart")));
    expect(scaffold, isNot(contains('_ReceiptDetailLevelPanel(')));
    expect(scaffold, isNot(contains('_ReceiptSummaryUsePanel(')));
    expect(settings, isNot(contains('_ReceiptReviewStyleSettingsPanel(')));
    expect(
      attachmentPanel,
      isNot(contains('receipt_expense_review_default_picker.dart')),
    );
    expect(
      captureSettings,
      isNot(contains('_ExpenseReceiptReviewDefaultPicker(')),
    );
    expect(actions, contains('initial: _ExpenseReceiptLine.blank'));
    expect(actions, isNot(contains('_showQuickClassifyLineSheet')));
    expect(
      lineEditor,
      isNot(contains('_ReceiptItemCategoryContext(rule: _categoryRule)')),
    );
    expect(lineEditor, contains("label: 'Item description'"));
    expect(lineEditor, contains('TextInputAction.next'));
    expect(lineEditor, contains('ExpenseSplitAllocationMethod.amount'));
    expect(recap, contains('showItemDetails'));
  });
}
