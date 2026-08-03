import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new expense receipt entry explains the first three actions', () async {
    final scaffold = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsString();
    final guide = await File(
      'lib/screens/expenses/entry/expense_receipt_entry_start_guide.dart',
    ).readAsString();

    expect(scaffold, contains('const _ReceiptEntryStartGuide()'));
    expect(guide, contains('Set the vehicle and date'));
    expect(guide, contains('Add a receipt photo or enter it by hand'));
    expect(
      guide,
      contains(
        'Check the filled details, choose Business, Personal, or Split, then save',
      ),
    );
    expect(guide, contains('You stay in control'));
  });
}
