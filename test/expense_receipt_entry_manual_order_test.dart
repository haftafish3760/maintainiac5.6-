import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'manual receipt keeps merchant details before optional receipt proof',
    () {
      final source = File(
        'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
      ).readAsStringSync();

      final dateTime = source.indexOf('SharedReceiptDateTimePanel(');
      final store = source.indexOf('SharedReceiptStorePanel(');
      final attachment = source.indexOf('key: _receiptReadHandoffKey');
      final odometer = source.indexOf('_ExpenseOdometerPanel(');
      final detail = source.indexOf('_ReceiptDetailLevelPanel(');

      expect(dateTime, greaterThanOrEqualTo(0));
      expect(odometer, lessThan(dateTime));
      expect(store, greaterThan(dateTime));
      expect(attachment, greaterThan(store));
      expect(detail, greaterThan(odometer));
      expect(detail, lessThan(dateTime));
      expect(source, isNot(contains('_ReceiptCategoryScopePanel(')));
    },
  );
}
