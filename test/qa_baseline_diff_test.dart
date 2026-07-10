import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/qa_harness/qa_baseline_diff.dart';
import 'support/qa_harness/qa_harness.dart';

void main() {
  test('baseline diff warns when requested baseline is missing', () async {
    final report = _report(const [
      QaSuiteResult(
        name: 'inventory.security_privacy',
        duration: Duration.zero,
        checked: 1,
      ),
    ]);

    final diffed = await appendQaBaselineDiff(
      report: report,
      context: _context(),
      baselinePath: 'test/fixtures/work_supply_parser/baselines/missing.json',
    );

    final baselineFailures = diffed.failures
        .where((failure) => failure.suite == 'qa.baseline_diff')
        .toList(growable: false);

    expect(baselineFailures, hasLength(1));
    expect(baselineFailures.single.id, 'baseline_missing');
    expect(baselineFailures.single.severity, QaSeverity.warning);
  });

  test(
    'baseline diff reports coverage drops and severity regressions',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'parser_baseline_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });
      final baselineFile = File('${directory.path}/baseline.json');
      baselineFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'results': [
            {
              'name': 'inventory.fixture_governance',
              'checked': 10,
              'actualFailureCount': 0,
              'severityCounts': {
                'info': 0,
                'warning': 0,
                'error': 0,
                'critical': 0,
              },
            },
            {
              'name': 'inventory.noise_lines',
              'checked': 5,
              'actualFailureCount': 0,
              'severityCounts': {
                'info': 0,
                'warning': 0,
                'error': 0,
                'critical': 0,
              },
            },
          ],
        }),
      );
      final current = _report(const [
        QaSuiteResult(
          name: 'inventory.fixture_governance',
          duration: Duration.zero,
          checked: 8,
          failures: [
            QaFailure(
              suite: 'inventory.fixture_governance',
              id: 'fixture_regression',
              message: 'fixture regression',
              severity: QaSeverity.error,
            ),
          ],
        ),
        // New suites must stay visible so baseline comparisons cannot hide
        // added parser QA coverage from review.
        QaSuiteResult(
          name: 'inventory.new_suite',
          duration: Duration.zero,
          checked: 3,
        ),
      ]);

      final diffed = await appendQaBaselineDiff(
        report: current,
        context: _context(),
        baselinePath: baselineFile.path,
      );
      final ids = diffed.failures
          .where((failure) => failure.suite == 'qa.baseline_diff')
          .map((failure) => failure.id)
          .toSet();

      expect(ids, contains('checked_decreased:inventory.fixture_governance'));
      expect(ids, contains('failures_increased:inventory.fixture_governance'));
      expect(
        ids,
        contains('severity_increased:inventory.fixture_governance:error'),
      );
      expect(ids, contains('suite_removed:inventory.noise_lines'));
      expect(ids, contains('suite_added:inventory.new_suite'));
    },
  );

  test('baseline diff reports runtime metric regressions', () async {
    final directory = await Directory.systemTemp.createTemp(
      'parser_runtime_baseline_',
    );
    addTearDown(() {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    });
    final baselineFile = File('${directory.path}/baseline.json');
    baselineFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'results': [
          {
            'name': 'inventory.runtime_measurement',
            'checked': 4,
            'actualFailureCount': 0,
            'severityCounts': {
              'info': 0,
              'warning': 0,
              'error': 0,
              'critical': 0,
            },
            'metrics': {'coldStartMs': 1000, 'warmCacheMs': 50},
          },
        ],
      }),
    );
    final current = _report(const [
      QaSuiteResult(
        name: 'inventory.runtime_measurement',
        duration: Duration.zero,
        checked: 4,
        metrics: {'coldStartMs': 5000, 'warmCacheMs': 300},
      ),
    ]);

    final diffed = await appendQaBaselineDiff(
      report: current,
      context: _context(),
      baselinePath: baselineFile.path,
    );
    final failures = diffed.failures
        .where((failure) => failure.suite == 'qa.baseline_diff')
        .toList(growable: false);
    final ids = failures.map((failure) => failure.id).toSet();

    expect(
      ids,
      contains('metric_regressed:inventory.runtime_measurement:coldStartMs'),
    );
    expect(
      ids,
      contains('metric_regressed:inventory.runtime_measurement:warmCacheMs'),
    );
    expect(
      failures.every((failure) => failure.severity == QaSeverity.warning),
      isTrue,
    );
  });

  test(
    'baseline diff reports new failure ids even when count is unchanged',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'parser_failure_id_baseline_',
      );
      addTearDown(() {
        if (directory.existsSync()) {
          directory.deleteSync(recursive: true);
        }
      });
      final baselineFile = File('${directory.path}/baseline.json');
      baselineFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert({
          'results': [
            {
              'name': 'inventory.golden_fixtures',
              'checked': 12,
              'actualFailureCount': 1,
              'severityCounts': {
                'info': 0,
                'warning': 0,
                'error': 1,
                'critical': 0,
              },
              'failures': [
                {'id': 'old_parser_failure', 'severity': 'error'},
              ],
            },
          ],
        }),
      );
      final current = _report(const [
        QaSuiteResult(
          name: 'inventory.golden_fixtures',
          duration: Duration.zero,
          checked: 12,
          failures: [
            QaFailure(
              suite: 'inventory.golden_fixtures',
              id: 'new_parser_failure',
              message: 'same count, different parser failure',
              severity: QaSeverity.error,
            ),
          ],
        ),
      ]);

      final diffed = await appendQaBaselineDiff(
        report: current,
        context: _context(),
        baselinePath: baselineFile.path,
      );
      final ids = diffed.failures
          .where((failure) => failure.suite == 'qa.baseline_diff')
          .map((failure) => failure.id)
          .toSet();

      expect(
        ids,
        contains(
          'failure_id_added:inventory.golden_fixtures:new_parser_failure',
        ),
      );
      expect(
        ids,
        isNot(contains('failures_increased:inventory.golden_fixtures')),
      );
    },
  );
}

QaContext _context() {
  return const QaContext(strict: false, redactor: QaRedactor());
}

QaReport _report(List<QaSuiteResult> results) {
  return QaReport(
    domain: 'work_supply_inventory_parser',
    strict: false,
    results: results,
    startedAt: DateTime(2026),
    duration: Duration.zero,
  );
}
