import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('assisted receipts use the same clean customer receipt review', () {
    final scaffold = File(
      'lib/screens/expenses/entry/expense_receipt_entry_scaffold.dart',
    ).readAsStringSync();
    final recap = File(
      'lib/screens/expenses/entry/expense_receipt_recap_paper.dart',
    ).readAsStringSync();

    expect(scaffold, isNot(contains('_ReceiptAppAssistedReviewIntroPanel(')));
    expect(scaffold, isNot(contains('_ReceiptClassificationReviewPanel(')));
    expect(scaffold, isNot(contains('_ReceiptLineEvidenceReviewPanel(')));
    expect(recap, contains('RECEIPT DETAILS'));
    expect(recap, contains("label: 'Subtotal'"));
    expect(recap, contains("label: 'Tax'"));
    expect(recap, contains("label: 'Receipt Total'"));
    expect(recap, contains('const Divider'));
    expect(recap, isNot(contains('_ReceiptMixedAllocationReview(')));
    expect(recap, isNot(contains('ALLOCATION REVIEW')));
  });

  test('save screen does not expose parser diagnostics or percentages', () {
    final savePanel = File(
      'lib/screens/expenses/entry/expense_receipt_totals.dart',
    ).readAsStringSync();

    expect(savePanel, isNot(contains('app-filled line still needs review')));
    expect(savePanel, isNot(contains('Detected sales tax')));
    expect(savePanel, isNot(contains('_percent(')));
  });
}
