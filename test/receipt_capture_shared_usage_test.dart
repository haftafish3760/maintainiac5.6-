import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maintenance setup uses the shared receipt capture system', () async {
    final source =
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_screen.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_core_helpers.dart',
        ).readAsString() +
        await File(
          'lib/screens/expenses/entry/expense_receipt_entry_attachment_panel.dart',
        ).readAsString();

    expect(
      source,
      contains("shared/widgets/receipt_capture/receipt_capture.dart"),
    );
    expect(source, contains('SharedReceiptAttachmentPanel'));
    expect(source, contains('ReceiptCaptureArea.maintenanceRepair'));
    expect(source, isNot(contains('receipt_capture_section.dart')));
  });
}
