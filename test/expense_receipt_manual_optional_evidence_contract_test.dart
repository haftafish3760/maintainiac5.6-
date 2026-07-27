import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt details keep evidence optional and ordered', () {
    final flow = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_flow.dart',
    ).readAsStringSync();
    final save = File(
      'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
    ).readAsStringSync();
    final store = File(
      'lib/shared/widgets/receipt_form/receipt_store_panel.dart',
    ).readAsStringSync();
    final capture = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_panel_controller.dart',
    ).readAsStringSync();
    final captureSettings = File(
      'lib/shared/widgets/receipt_capture/receipt_capture_settings_sheet.dart',
    ).readAsStringSync();
    final dateTimeSource = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_date_time.dart',
    ).readAsStringSync();
    final storeSheet = File(
      'lib/shared/widgets/receipt_form/receipt_store_panel_sheet.dart',
    ).readAsStringSync();
    final manualWidgetsSource = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
    ).readAsStringSync();
    final reviewTopBar = File(
      'lib/shared/widgets/receipt_capture/receipt_photo_review_top_bar.dart',
    ).readAsStringSync();

    final contextActions = flow.indexOf('_buildManualReceiptContextActions(');
    final dateTime = flow.indexOf('_ManualReceiptDateTimeStrip(');
    final storeAction = flow.indexOf("label: 'Store information'");
    final attachment = flow.indexOf("label: 'Add receipt'");

    expect(contextActions, greaterThanOrEqualTo(0));
    expect(dateTime, greaterThan(contextActions));
    expect(storeAction, greaterThan(dateTime));
    expect(attachment, greaterThan(storeAction));
    expect(flow, contains('_ManualReceiptStoreBinding('));
    expect(flow, isNot(contains('Add any details you have.')));
    expect(flow, contains('onSettingsPressed:'));
    expect(
      flow,
      contains('headerLabel: _manualReceiptStep.vehicleHeaderLabel'),
    );
    expect(
      flow,
      contains('screenContext: _manualReceiptStep.settingsScreenContext'),
    );
    expect(flow, contains("'RECEIPT DETAILS'"));
    expect(flow, contains("'RECEIPT ITEMS'"));
    expect(flow, contains("'RECEIPT REVIEW'"));
    expect(flow, isNot(contains('Receipt proof')));
    expect(flow, isNot(contains("_receiptAttachments.isEmpty) {")));
    expect(save, contains('!_usesRebuiltManualDetailedReceiptFlow'));
    expect(store, contains('this.storeRequired = false'));
    expect(capture, contains('openSettings'));
    expect(capture, contains('ReceiptSettingsScreenContext'));
    expect(captureSettings, contains('screenContext?.title'));
    expect(captureSettings, contains('screenContext?.subtitle'));
    expect(captureSettings, contains('screenContext!.description'));
    expect(captureSettings, contains('screenContext?.workflowNote'));
    expect(flow, contains('_buildManualReceiptContextActions('));
    expect(dateTimeSource, contains("label: 'Date · Required'"));
    expect(dateTimeSource, contains("label: 'Time · Optional'"));
    expect(dateTimeSource, contains('return Column('));
    expect(storeSheet, contains('MediaQuery.paddingOf(context).bottom'));
    expect(storeSheet, contains('backgroundColor: const Color(0xFFC62828)'));
    expect(storeSheet, contains("const Text('Cancel')"));
    expect(storeSheet, contains("const Text('Save Store Details')"));
    expect(
      manualWidgetsSource,
      contains('backgroundColor: const Color(0xFF28A745)'),
    );
    expect(reviewTopBar, contains("foregroundColor: const Color(0xFFFF8A80)"));
    expect(
      File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_details_widgets.dart',
      ).readAsStringSync(),
      contains('Enter your current odometer to add it to the receipt.'),
    );
    expect(
      File(
        'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
      ).readAsStringSync(),
      contains('BorderRadius.circular(6)'),
    );
    final manualWidgets = File(
      'lib/screens/expenses/entry/expense_receipt_entry_manual_widgets.dart',
    ).readAsStringSync();
    expect(
      manualWidgets,
      isNot(contains('line.displayDescription,\n                    maxLines')),
    );
  });
}
