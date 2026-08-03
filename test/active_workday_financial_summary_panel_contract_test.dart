// Active Day payment-summary wording and destination regression contract.
// Owns the user-visible meaning of the payment metric. Does not test invoice
// math or expense storage. Consumed by dashboard UI regression QA.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Active Day labels payment totals and opens payment review', () {
    final source = File(
      'lib/screens/dashboard/active_workday_financial_summary_panel.dart',
    ).readAsStringSync();

    expect(source, contains("'Payments'"));
    expect(source, isNot(contains("'Received'")));
    expect(source, contains('GigPaymentsReviewScreen('));
  });
}
