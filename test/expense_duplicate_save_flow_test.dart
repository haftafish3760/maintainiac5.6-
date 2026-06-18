import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'duplicate save flow returns from View Existing to current decision',
    () {
      final source = File(
        'lib/screens/expenses/entry/expense_receipt_save_actions.dart',
      ).readAsStringSync();

      expect(source, contains('while (duplicateCheck.hasCandidates)'));
      expect(source, contains('choice.shouldViewExistingFirst'));
      expect(source, contains('_showExistingDuplicateReceipt'));
      expect(source, contains('continue;'));
      expect(source, contains('choice.shouldKeepEditingCurrent'));
      expect(source, contains('duplicateOverride: true'));
      expect(source, contains('duplicateOverrideReason'));
    },
  );
}
