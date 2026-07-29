import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('manual receipt keeps context before proof and line items', () {
    final source = File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsStringSync();

    final dateTime = source.indexOf('SharedReceiptDateTimePanel(');
    final store = source.indexOf('SharedReceiptStorePanel(');
    final attachment = source.indexOf('key: _receiptReadHandoffKey');
    final odometer = source.indexOf('_ExpenseOdometerPanel(');
    final lineItems = source.indexOf('_ReceiptLineActionsPanel(');

    expect(dateTime, greaterThanOrEqualTo(0));
    expect(odometer, lessThan(dateTime));
    expect(store, greaterThan(dateTime));
    expect(attachment, greaterThan(store));
    expect(lineItems, greaterThan(attachment));
    expect(source, isNot(contains('_ReceiptDetailLevelPanel(')));
    expect(source, isNot(contains('_ReceiptCategoryScopePanel(')));
  });
}
