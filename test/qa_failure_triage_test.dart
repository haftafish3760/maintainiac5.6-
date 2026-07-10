import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';

void main() {
  test('qa failures expose triage category in json and summary', () {
    final report = QaReport(
      domain: 'triage_probe',
      strict: false,
      startedAt: DateTime(2026),
      duration: Duration.zero,
      results: const [
        QaSuiteResult(
          name: 'inventory.review_safety_contract',
          duration: Duration.zero,
          checked: 1,
          failures: [
            QaFailure(
              suite: 'inventory.review_safety_contract',
              id: 'review_status_allows_confirmed',
              message: 'Confirmed review status is unsafe.',
            ),
          ],
        ),
      ],
    );

    expect(report.failures.single.triageCategory, QaFailureTriage.reviewSafety);
    expect(report.failuresByTriageCategory, {QaFailureTriage.reviewSafety: 1});
    expect(report.toJson()['failuresByTriageCategory'], {
      QaFailureTriage.reviewSafety: 1,
    });
    expect(
      report.toSummary(),
      contains('QA_TRIAGE_GROUP category=review_safety count=1'),
    );
    expect(report.toSummary(), contains('triage=review_safety'));
  });

  test('explicit triage category metadata wins over classifier', () {
    const failure = QaFailure(
      suite: 'inventory.anything',
      id: 'weird_case',
      message: 'Useful but domain-specific failure.',
      metadata: {'triageCategory': 'custom_domain'},
    );

    expect(failure.triageCategory, 'custom_domain');
  });

  test('redactor preserves receipt review wording but scrubs receipt ids', () {
    const redactor = QaRedactor();

    expect(redactor('Inventory receipt review status'), contains('receipt'));
    expect(redactor('RECEIPT #ABC123'), '[REDACTED_RECEIPT_ID]');
    expect(redactor('receipt number 98765'), '[REDACTED_RECEIPT_ID]');
    expect(redactor('AUTH 991827'), '[REDACTED_RECEIPT_ID]');
  });
}
