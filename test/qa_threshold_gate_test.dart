import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_harness.dart';
import 'support/qa_harness/qa_threshold_gate.dart';

void main() {
  test('threshold gate reports slow parser suite throughput', () {
    final result =
        QaThresholdGateSuite(
          priorResults: const [
            QaSuiteResult(
              name: 'inventory.trade_context',
              duration: Duration(seconds: 10),
              checked: 1,
            ),
          ],
        ).runSync(
          const QaContext(
            strict: false,
            redactor: QaRedactor(),
            profile: 'full',
            thresholds: QaThresholds(
              minSuiteChecksPerSecond: {'inventory.trade_context': 1},
            ),
          ),
        );

    expect(
      result.failures.map((failure) => failure.id),
      contains('min_suite_checks_per_second:inventory.trade_context'),
    );
    expect(result.failures.single.severity, QaSeverity.warning);
    expect(result.checked, 8);
  });

  test(
    'QA summaries keep suite names readable while redacting receipt IDs',
    () {
      final report = QaReport(
        domain: 'work_supply_inventory_parser',
        strict: false,
        results: const [
          QaSuiteResult(
            name: 'inventory.noise_lines',
            duration: Duration.zero,
            checked: 1,
          ),
          QaSuiteResult(
            name: 'inventory.math_reconciliation',
            duration: Duration.zero,
            checked: 1,
          ),
          QaSuiteResult(
            name: 'inventory.security_privacy',
            duration: Duration.zero,
            checked: 1,
            failures: [
              QaFailure(
                suite: 'inventory.security_privacy',
                id: 'privacy_probe',
                message: 'must redact receipt id',
                actual: 'RECEIPT #ABC123',
              ),
            ],
          ),
        ],
        startedAt: DateTime(2026),
        duration: Duration.zero,
      );

      final summary = report.toSummary();

      expect(summary, contains('inventory.noise_lines'));
      expect(summary, contains('inventory.math_reconciliation'));
      expect(summary, contains('[REDACTED_RECEIPT_ID]'));
      expect(summary, isNot(contains('ABC123')));
    },
  );
}
