import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('receipt review modes expose only the promised amount fields', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_totals.dart',
    ).readAsStringSync();

    expect(
      source,
      contains('detailMode == _ReceiptDetailEntryMode.detailedItems'),
    );
    expect(
      source,
      contains('detailMode == _ReceiptDetailEntryMode.basicReceipt'),
    );
    expect(source, contains("priceOnly ? 'Price Paid'"));
    expect(source, contains("'Final Total After Tax'"));
    expect(source, contains("label: 'Receipt Subtotal'"));
    expect(source, contains("label: 'Sales Tax'"));
  });
}
