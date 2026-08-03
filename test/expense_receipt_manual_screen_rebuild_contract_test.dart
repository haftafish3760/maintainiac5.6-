import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manual receipt uses the compact add receipt surface instead of legacy panels',
    () {
      final screen = File(
        'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
      ).readAsStringSync();
      final scaffold = File(
        'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
      ).readAsStringSync();
      final flow = File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
      ).readAsStringSync();
      final widgets = File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
      ).readAsStringSync();
      final itemEditor = File(
        'lib/screens/expenses/entry/expense_receipt_line_editor.dart',
      ).readAsStringSync();
      final dateTime = File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_date_time.dart',
      ).readAsStringSync();
      final controller = File(
        'lib/shared/widgets/receipt_capture/receipt_attachment_panel_controller.dart',
      ).readAsStringSync();
      final parseApply = File(
        'lib/screens/expenses/entry/expense_receipt_entry_parse_apply_actions.dart',
      ).readAsStringSync();

      expect(screen, contains("part 'expense_receipt_entry_manual_flow.dart'"));
      expect(scaffold, contains('_usesRebuiltManualDetailedReceiptFlow'));
      expect(scaffold, contains('_buildLegacyReceiptEntryScaffold'));
      expect(widgets, contains("'Add Receipt'"));
      expect(flow, contains('_ReferenceReceiptAppBar('));
      expect(flow, contains('_ReferenceReceiptContextRow('));
      expect(
        flow,
        isNot(contains('class _ManualReceiptClassificationSummary')),
      );
      expect(flow, isNot(contains('Change in preview')));
      expect(flow, isNot(contains('You can change it before saving.')));
      expect(flow, contains("'Continue to receipt preview'"));
      expect(flow, contains('class _ManualReceiptPreviewScreen'));
      expect(flow, contains("'Store information'"));
      expect(flow, contains("'Please classify this receipt'"));
      expect(flow, contains('if (!_receiptClassificationConfirmed)'));
      expect(flow, contains("label: 'Continue'"));
      expect(widgets, contains("label: 'Not sure yet'"));
      expect(flow, contains('allowLineClassification:'));
      expect(flow, contains('_ExpenseLineUse.split ||'));
      expect(flow, contains('_ExpenseLineUse.unclassified'));
      expect(flow, contains('_ReferenceReceiptTotalField('));
      expect(flow, contains('_ReferenceReceiptClassificationRow('));
      expect(flow, contains('_ReferenceReceiptCategoryTile('));
      expect(
        flow,
        isNot(
          contains('_detailEntryMode == _ReceiptDetailEntryMode.detailedItems'),
        ),
      );
      expect(flow, isNot(contains('_ReceiptDetailLevelPanel(')));
      expect(flow, contains('_ReceiptWholeCategoryPicker('));
      expect(flow, contains('_ReceiptCategoryEntryOptions('));
      expect(flow, contains('_setManualReceiptCategory'));
      expect(flow, contains("? 'Add items' : 'Edit items'"));
      expect(flow, contains('Add receipt photo'));
      expect(flow, contains('Save receipt'));
      expect(screen, contains('ReceiptAttachmentPanelController'));
      expect(flow, isNot(contains('SharedReceiptDateTimePanel(')));
      expect(flow, isNot(contains('SharedReceiptStorePanel(')));
      expect(flow, isNot(contains('_ReceiptRecapPanel(')));
      expect(flow, isNot(contains('_ReceiptLineActionsPanel(')));
      expect(flow, isNot(contains('_ReceiptTotalsPanel(')));
      expect(flow, isNot(contains('_ReceiptSavePanel(')));
      expect(widgets, contains('class _ReferenceReceiptAppBar'));
      expect(widgets, contains('class _ReferenceReceiptTotalField'));
      expect(widgets, contains('height: 108'));
      expect(widgets, contains('height: 82'));
      expect(widgets, contains("'Choose a category'"));
      expect(widgets, contains('class _ReferenceReceiptClassificationRow'));
      expect(dateTime, contains('class _ManualReceiptDateTimeStrip'));
      expect(dateTime, isNot(contains('flex: 3')));
      expect(dateTime, isNot(contains('flex: 2')));
      expect(dateTime, isNot(contains('TextOverflow.ellipsis')));
      expect(itemEditor, contains('Printed line total'));
      expect(itemEditor, contains('_unitPriceLabel'));
      expect(itemEditor, contains("label: 'Unit of measure'"));
      expect(itemEditor, contains('if (widget.allowLineClassification)'));
      expect(controller, contains('openImportOptions'));
      expect(parseApply, contains('_openAppAssistedReceiptPreviewIfReady'));
      expect(parseApply, contains('unawaited(_openManualReceiptPreview())'));
    },
  );
}
