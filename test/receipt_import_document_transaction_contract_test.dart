import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('document picker cancellation cannot reopen or stack the chooser', () {
    final source = File(
      'lib/shared/widgets/receipt_capture/receipt_import_source_sheet.dart',
    ).readAsStringSync();
    final pdf = File(
      'lib/shared/widgets/receipt_capture/receipt_pdf_import_actions.dart',
    ).readAsStringSync();
    final text = File(
      'lib/shared/widgets/receipt_capture/receipt_attachment_text_document_actions.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('returnToReceiptImportOptions')));
    expect(pdf, isNot(contains('returnToReceiptImportOptions')));
    expect(text, isNot(contains('returnToReceiptImportOptions')));
    expect(source, contains('final previousAttachmentCount ='));
    expect(
      source,
      contains('_documentAttachments.length > previousAttachmentCount'),
    );
    expect(source, contains('const ReceiptImportActionResult.stayOnChooser()'));
  });
}
