import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'phase 7 handoff keeps user-reviewed values ahead of parser rewrites',
    () async {
      final parseApply = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_parse_apply_actions.dart',
      ).readAsString();
      final lifecycle = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_lifecycle_helpers.dart',
      ).readAsString();
      final stateActions = await File(
        'lib/screens/expenses/entry/expense_receipt_entry_state_actions.dart',
      ).readAsString();
      final mergeHelper = await File(
        'lib/screens/expenses/data/expense_receipt_user_review_merge.dart',
      ).readAsString();

      expect(parseApply, contains('_mergeParsedReceiptLines(parsed)'));
      expect(parseApply, contains('mergeParsedReceiptLinesWithReviewedLines('));
      expect(parseApply, contains('_shouldApplyParsedMerchantValue'));
      expect(parseApply, contains('_shouldApplyParsedDateValue'));
      expect(parseApply, contains('_shouldApplyParsedTimeValue'));
      expect(parseApply, contains('_shouldApplyParsedSubtotalValue'));
      expect(parseApply, contains('_shouldApplyParsedTaxValue'));
      expect(parseApply, contains('_shouldApplyParsedTotalValue'));
      expect(parseApply, contains('_applyingParsedFieldValues = true;'));
      expect(parseApply, contains('_applyingParsedFieldValues = false;'));
      expect(parseApply, contains('_ExpenseReceiptLine.fromLedgerLine(line)'));
      expect(
        lifecycle,
        contains('_storeController.addListener(_trackMerchantUserEdit);'),
      );
      expect(
        lifecycle,
        contains(
          '_receiptSubtotalController.addListener(_trackSubtotalUserEdit);',
        ),
      );
      expect(
        lifecycle,
        contains('_salesTaxController.addListener(_trackTaxUserEdit);'),
      );
      expect(
        lifecycle,
        contains('_receiptTotalController.addListener(_trackTotalUserEdit);'),
      );
      expect(stateActions, contains('_receiptDateLockedByUser = true;'));
      expect(stateActions, contains('_receiptTimeLockedByUser = true;'));
      expect(mergeHelper, contains('isUserReviewedAppAssistedReceiptLine'));
      expect(mergeHelper, contains("reason.startsWith('user reviewed')"));
      expect(mergeHelper, contains("reason.startsWith('user confirmed')"));
      expect(
        mergeHelper,
        contains("return 'section:\$section:\$sectionLine';"),
      );
      expect(mergeHelper, contains("return 'line:\$lineNumber';"));
      expect(mergeHelper, contains("return 'source:\$sourceId';"));
    },
  );
}
