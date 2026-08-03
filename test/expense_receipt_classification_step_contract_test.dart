import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classification is flat and category selection is receipt-wide', () {
    final flow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();
    final widgets = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/screens/expenses/entry/expense_receipt_category_scope_panel.dart',
    ).readAsStringSync();
    final attachmentPanel = File(
      'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
    ).readAsStringSync();

    final start = flow.indexOf('Widget _buildReceiptClassificationStep()');
    final end = flow.indexOf('Future<void> _openReceiptCategoryPicker()');
    final step = flow.substring(start, end);

    expect(
      step,
      contains("key: const ValueKey('receipt-classification-step')"),
    );
    expect(step, isNot(contains('_SplitSurface(')));
    expect(step, contains('_ReceiptCategoryEntryOptions('));
    expect(step, contains("'Choose a category for this receipt'"));
    expect(step, contains('Pick one category for the whole receipt'));
    expect(widgets, contains("label: 'Mixed items'"));
    expect(widgets, contains("label: 'Not sure yet'"));
    expect(widgets, contains('Icons.radio_button_checked'));
    expect(picker, contains("'Choose a category'"));
    expect(picker, contains('whole receipt'));
    expect(picker, contains("child: const Text('Done')"));
    expect(picker, isNot(contains('Category Per Line')));
    expect(flow, contains('PopScope<Object?>('));
    expect(flow, contains('canPop:'));
    expect(flow, contains('!_receiptClassificationConfirmed'));
    expect(flow, contains('_startsWithAppAssistedReceiptCapture'));
    expect(flow, contains('_manualReceiptStep == _ManualReceiptStep.details'));
    expect(
      flow,
      contains('WidgetsBinding.instance.addPostFrameCallback((_) {'),
    );
    expect(
      flow,
      contains(
        'unawaited(_manualReceiptAttachmentController.openImportOptions())',
      ),
    );
    expect(flow, isNot(contains("label: 'Add receipt photo'")));
    expect(attachmentPanel, contains('startsWithAssistedCapture'));
    expect(attachmentPanel, contains('closeParentWhenImportCanceled'));
    expect(flow, contains('if (_receiptClassificationConfirmed)'));
    expect(
      flow,
      contains(
        '_setReceiptEntryState(() => _receiptClassificationConfirmed = false)',
      ),
    );
    expect(flow, contains('_ReferenceReceiptSelectionContext('));
    expect(widgets, contains('class _ReferenceReceiptSelectionContext'));
    expect(widgets, contains("label: 'RECEIPT CATEGORY'"));
    expect(widgets, contains("label: 'RECEIPT CLASSIFICATION'"));
    expect(widgets, contains('fontSize: 14'));
    expect(widgets, contains('fontSize: 17'));
    expect(widgets, contains('Color(0xFF72B8FF)'));
    expect(widgets, contains('final String entryModeLabel'));
    expect(flow, contains("'App-assisted'"));
    expect(widgets, contains('color: const Color(0xFF9D4141)'));
    expect(widgets, contains('fillColor: Color(0xFF161012)'));
  });
}
