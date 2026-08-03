import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt preview uses flat, editable receipt lines', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_recap_line_controls.dart',
    ).readAsStringSync();

    expect(source, contains('_ReceiptLineUseSegment('));
    expect(source, contains('_ReceiptPaperLineFacts(line: line)'));
    expect(source, contains("label: 'Price'"));
    expect(source, contains("label: 'Unit'"));
    expect(source, contains("label: 'Qty'"));
    expect(source, contains("label: 'Edit'"));
    expect(source, isNot(contains('_ReceiptParserBadge(line: line)')));
    expect(source, isNot(contains('line.allocationDetail')));
  });
}
