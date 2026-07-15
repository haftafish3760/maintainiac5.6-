import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'receipt odometer history is reviewed before the local receipt commits',
    () async {
      final saveSource = await File(
        'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
      ).readAsString();
      final lifecycleSource = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_odometer_lifecycle.dart',
      ).readAsString();

      expect(
        saveSource.indexOf('_prepareReceiptOdometerCommit(receipt)'),
        lessThan(saveSource.indexOf('_saveReceiptToLedger(ledger, receipt)')),
      );
      expect(
        saveSource.indexOf('odometerCommit.commit()'),
        greaterThan(
          saveSource.indexOf('_saveReceiptToLedger(ledger, receipt)'),
        ),
      );
      expect(lifecycleSource, contains('commit: false'));
      expect(lifecycleSource, contains("sourceType: 'expense_receipt'"));
    },
  );
}
