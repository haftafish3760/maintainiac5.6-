import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt uses a new three-step screen instead of legacy panels', () {
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

    expect(screen, contains("part 'expense_receipt_entry_manual_flow.dart'"));
    expect(scaffold, contains('_usesRebuiltManualDetailedReceiptFlow'));
    expect(scaffold, contains('_buildLegacyReceiptEntryScaffold'));
    expect(widgets, contains("'Manual Receipt'"));
    expect(flow, contains('_ManualReceiptStep.details'));
    expect(flow, contains('_ManualReceiptStep.items'));
    expect(flow, contains('_ManualReceiptStep.review'));
    expect(
      flow,
      isNot(
        contains('_detailEntryMode == _ReceiptDetailEntryMode.detailedItems'),
      ),
    );
    expect(flow, isNot(contains('_ReceiptDetailLevelPanel(')));
    expect(flow, contains('Continue to items'));
    expect(flow, contains("label: const Text('Add item')"));
    expect(flow, contains('Review receipt'));
    expect(flow, contains('Save receipt'));
    expect(screen, contains('ReceiptAttachmentPanelController'));
    expect(flow, isNot(contains('SharedReceiptDateTimePanel(')));
    expect(flow, isNot(contains('SharedReceiptStorePanel(')));
    expect(flow, isNot(contains('_ReceiptRecapPanel(')));
    expect(flow, isNot(contains('_ReceiptLineActionsPanel(')));
    expect(flow, isNot(contains('_ReceiptTotalsPanel(')));
    expect(flow, isNot(contains('_ReceiptSavePanel(')));
    expect(widgets, contains('class _ManualReceiptItemCard'));
    expect(widgets, contains("const labels = ['Details', 'Items', 'Review']"));
    expect(dateTime, contains('class _ManualReceiptDateTimeStrip'));
    expect(dateTime, isNot(contains('TextOverflow.ellipsis')));
    expect(itemEditor, contains('Printed line total'));
    expect(itemEditor, contains('Price each'));
    expect(controller, contains('openImportOptions'));
  });
}
