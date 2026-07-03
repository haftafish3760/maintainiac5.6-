import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('PDF import copy keeps proof-only and app-fill choices clear', () {
    final actions = File(
      'lib/shared/widgets/receipt_capture/receipt_pdf_import_actions.dart',
    ).readAsStringSync();
    final sheets = File(
      'lib/shared/widgets/receipt_capture/receipt_pdf_import_sheets.dart',
    ).readAsStringSync();
    final source = '$actions\n$sheets';

    expect(source, contains('Save Read-Only Proof'));
    expect(source, contains('without reading, editing, or changing it'));
    expect(source, contains('Try App-Assisted Fill'));
    expect(source, contains('You still review everything before saving'));
    expect(source, contains('Saving proof only is safest'));
    expect(source, contains('will never edit the PDF proof'));
    expect(source, contains('inspection.canUseAssistedRead'));
    expect(source, contains('will stay proof-only'));
    expect(actions, contains('readableAttachments'));
    expect(actions, contains('proofOnlyAttachments'));
    expect(actions, contains('ReceiptAttachmentReadState.notRead'));
    expect(actions, contains('final attachmentPath = attachment.path.trim();'));
    expect(actions, contains('current.fileHash.trim() == hash'));
    expect(actions, contains('final currentPath = current.path.trim();'));
    expect(actions, contains('currentPath == attachmentPath'));
    expect(actions, isNot(contains('assistedReadBlockers')));
  });
}
