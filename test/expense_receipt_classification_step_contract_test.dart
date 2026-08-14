import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('classification can stay undecided and uses the Expense FAB blue', () {
    final screen = File(
      'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
    ).readAsStringSync();
    final flow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();
    final widgets = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/screens/expenses/entry/expense_receipt_category_scope_panel.dart',
    ).readAsStringSync();
    final pickerWidgets = File(
      'lib/screens/expenses/entry/expense_receipt_category_picker_widgets.dart',
    ).readAsStringSync();
    final attachmentPanel = File(
      'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
    ).readAsStringSync();

    final start = flow.indexOf('Widget _buildReceiptClassificationStep()');
    final end = flow.indexOf('Future<void> _openReceiptCategoryPicker()');
    final step = flow.substring(start, end);
    final categoryPickerOpen = flow.substring(
      end,
      flow.indexOf('void _confirmReceiptClassification()'),
    );

    expect(
      step,
      contains("key: const ValueKey('receipt-classification-step')"),
    );
    expect(step, isNot(contains('_SplitSurface(')));
    expect(step, contains('_ReceiptCategoryEntryOptions('));
    expect(step, contains("'Choose a category for this receipt'"));
    expect(
      step,
      isNot(contains('Optional. Pick one category for the whole receipt')),
    );
    expect(
      widgets,
      contains("onTap: () => onChanged(_ExpenseLineUse.unclassified)"),
    );
    expect(widgets, contains("label: 'Not sure yet'"));
    expect(
      widgets,
      contains('const _receiptReferenceBlue = Color(0xFF2E78B7)'),
    );
    expect(flow, contains('viewport.maxWidth >= 600'));
    expect(flow, contains('padding: const EdgeInsets.fromLTRB(8, 8, 8, 18)'));
    expect(flow, isNot(contains('const BoxConstraints(maxWidth: 840)')));
    expect(widgets, contains('constraints.maxWidth >= 600'));
    expect(widgets, contains('Expanded(child: options[0])'));
    expect(widgets, contains('Expanded(child: options[3])'));
    expect(widgets, contains('crossAxisAlignment: CrossAxisAlignment.stretch'));
    expect(
      widgets,
      contains('const _receiptReferencePage = Color(0xFF2A3337)'),
    );
    expect(widgets, contains('const _receiptSetupPanel = Color(0xFF1A2226)'));
    expect(
      widgets,
      contains('const _receiptSetupPanelBorder = Color(0xFF445159)'),
    );
    expect(
      widgets,
      contains('const _receiptSetupChoiceSurface = Color(0xFF101719)'),
    );
    expect(step, contains('_ReceiptSetupSection('));
    expect(step, contains("'How should this receipt count?'"));
    expect(widgets, contains('color: _receiptSetupChoiceSurface'));
    expect(widgets, isNot(contains('Color(0xFF102231)')));
    expect(flow, contains('selected: _receiptUseSelectionMade'));
    expect(flow, contains('? _receiptUse'));
    expect(screen, contains('var _receiptUseSelectionMade = false'));
    expect(widgets, contains("label: 'Mixed items'"));
    final categoryOptions = widgets.substring(
      widgets.indexOf('class _ReceiptCategoryEntryOptions'),
      widgets.indexOf('class _ReferenceReceiptClassificationButton'),
    );
    expect(categoryOptions, contains('Icons.category_outlined'));
    expect(categoryOptions, contains('Icons.help_outline_rounded'));
    expect(categoryOptions, isNot(contains('Icons.radio_button_checked')));
    final categoryTile = pickerWidgets.substring(
      pickerWidgets.indexOf('class _CategoryBrowserTile'),
      pickerWidgets.indexOf('class _CategoryChoiceChip'),
    );
    expect(categoryTile, contains('height: 54'));
    expect(categoryTile, contains('padding: const EdgeInsets.only(bottom: 8)'));
    expect(categoryTile, contains('_receiptReferenceBlue'));
    expect(categoryTile, isNot(contains('Icons.check_rounded')));
    expect(picker, contains("'Select a category'"));
    expect(picker, contains("hintText: 'Search categories'"));
    expect(picker, contains('final visibleHomeCategories = homeCategories'));
    expect(picker, contains('visibleOtherCategories'));
    expect(picker, contains('_ReceiptSetupSection('));
    expect(pickerWidgets, contains("? 'No Category' : category"));
    expect(picker, contains('choose No Category to decide later'));
    expect(
      picker,
      contains(
        'Select one category for this receipt, or choose No Category to decide later. You can review or change it before saving.',
      ),
    );
    expect(categoryPickerOpen, contains('Navigator.of(context).push<void>('));
    expect(categoryPickerOpen, contains('appNativeRoute<void>('));
    expect(categoryPickerOpen, isNot(contains('showModalBottomSheet<void>(')));
    expect(picker, contains('return Scaffold('));
    expect(picker, contains('const _ReceiptCategoryPickerHeader()'));
    expect(picker, contains('Icons.arrow_back_rounded'));
    expect(picker, contains('iconSize: 30'));
    expect(picker, isNot(contains('DraggableScrollableSheet(')));
    expect(picker, contains("child: const Text('Cancel')"));
    expect(picker, isNot(contains('Optional. This choice will apply')));
    expect(picker, contains("child: const Text('Done')"));
    expect(picker, isNot(contains('Category Per Line')));
    expect(flow, contains('PopScope<Object?>('));
    expect(flow, contains('canPop:'));
    expect(flow, isNot(contains('_startsWithAppAssistedReceiptCapture')));
    expect(flow, contains('expenseReceiptBackActionFor('));
    expect(flow, contains('ExpenseReceiptBackAction.popRoute'));
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
    final confirmation = flow.substring(
      flow.indexOf('void _confirmReceiptClassification()'),
      flow.indexOf('void _setReceiptCategoryEntryChoice('),
    );
    expect(confirmation, contains('expenseReceiptEntryDestinationFor(choice)'));
    expect(
      confirmation,
      contains('ExpenseReceiptEntryDestination.manualDetails'),
    );
    expect(
      confirmation,
      contains('_manualReceiptStep = _ManualReceiptStep.details'),
    );
    expect(
      confirmation,
      contains(
        'if (destination == ExpenseReceiptEntryDestination.manualDetails) {',
      ),
    );
    expect(
      confirmation,
      isNot(contains('_receiptUse == _ExpenseLineUse.unclassified')),
    );
    expect(flow, isNot(contains("label: 'Add receipt photo'")));
    expect(attachmentPanel, contains('startsWithAssistedCapture'));
    expect(attachmentPanel, contains('closeParentWhenImportCanceled'));
    expect(flow, contains('expenseReceiptBackActionFor('));
    expect(flow, contains('ExpenseReceiptBackAction.showStart'));
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
