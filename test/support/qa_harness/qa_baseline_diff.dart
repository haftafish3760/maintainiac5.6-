import 'dart:convert';
import 'dart:io';

import 'qa_harness.dart';

Future<QaReport> appendQaBaselineDiff({
  required QaReport report,
  required QaContext context,
  required String baselinePath,
}) async {
  if (baselinePath.trim().isEmpty) return report;
  final suite = await QaBaselineDiffSuite(
    currentReport: report,
    baselinePath: baselinePath,
  ).run(context);
  return QaReport(
    domain: report.domain,
    strict: report.strict,
    results: [...report.results, suite],
    startedAt: report.startedAt,
    duration: report.duration,
    runConfig: report.runConfig,
  );
}

class QaBaselineDiffSuite extends QaSuite {
  const QaBaselineDiffSuite({
    required this.currentReport,
    required this.baselinePath,
  }) : super('qa.baseline_diff');

  static const _metricBudgets = {
    _MetricBudget(
      suite: 'inventory.runtime_measurement',
      metric: 'coldStartMs',
      relativeIncreaseAllowed: .25,
      absoluteIncreaseAllowed: 2000,
    ),
    _MetricBudget(
      suite: 'inventory.runtime_measurement',
      metric: 'warmCacheMs',
      relativeIncreaseAllowed: .50,
      absoluteIncreaseAllowed: 100,
    ),
  };

  final QaReport currentReport;
  final String baselinePath;

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final file = File(baselinePath);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'baseline_missing',
          message: 'Requested baseline report does not exist.',
          severity: context.strict ? QaSeverity.error : QaSeverity.warning,
          expected: baselinePath,
          actual: 'missing',
          suggestedFix:
              'Create or copy a known-good redacted QA report before enabling baseline comparison.',
        ),
      );
      return timer.finish(suite: name, checked: 1, failures: failures);
    }

    final baseline = _BaselineReport.fromJson(
      (jsonDecode(file.readAsStringSync()) as Map).cast<String, Object?>(),
    );
    final currentSuites = {
      for (final result in currentReport.results) result.name: result,
    };
    var checked = 1;

    for (final baselineSuite in baseline.suites.values) {
      checked++;
      final current = currentSuites[baselineSuite.name];
      if (current == null) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'suite_removed:${baselineSuite.name}',
            message: 'A suite from the baseline is missing in this run.',
            severity: QaSeverity.error,
            expected: baselineSuite.name,
            actual: 'missing',
            suggestedFix:
                'Restore the suite or intentionally update the baseline after review.',
          ),
        );
        continue;
      }
      if (current.checked < baselineSuite.checked) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'checked_decreased:${baselineSuite.name}',
            message: 'Suite checked fewer cases than the baseline.',
            severity: QaSeverity.warning,
            expected: '>= ${baselineSuite.checked}',
            actual: '${current.checked}',
            suggestedFix:
                'Confirm the harness did not accidentally drop fixture or generated coverage.',
          ),
        );
      }
      if (current.actualFailureCount > baselineSuite.actualFailureCount) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'failures_increased:${baselineSuite.name}',
            message: 'Suite actual failures increased over baseline.',
            severity: QaSeverity.error,
            expected: '<= ${baselineSuite.actualFailureCount}',
            actual: '${current.actualFailureCount}',
            suggestedFix:
                'Inspect parser/catalog changes before accepting a worse baseline.',
          ),
        );
      }
      for (final failure in current.failures) {
        if (baselineSuite.failureIds.contains(failure.id)) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'failure_id_added:${baselineSuite.name}:${failure.id}',
            message:
                'Suite has a new failure id that was not present in the baseline.',
            severity:
                failure.severity == QaSeverity.critical ||
                    failure.severity == QaSeverity.error
                ? QaSeverity.error
                : QaSeverity.warning,
            expected: 'no new failure ids versus reviewed baseline',
            actual: failure.id,
            suggestedFix:
                'Review the changed parser failure signature before accepting a new baseline.',
          ),
        );
      }
      for (final severity in ['critical', 'error']) {
        final currentCount = current.severityCounts[severity] ?? 0;
        final baselineCount = baselineSuite.severityCounts[severity] ?? 0;
        if (currentCount <= baselineCount) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'severity_increased:${baselineSuite.name}:$severity',
            message: 'Suite severity count increased over baseline.',
            severity: severity == 'critical'
                ? QaSeverity.critical
                : QaSeverity.error,
            expected: '$severity <= $baselineCount',
            actual: '$currentCount',
            suggestedFix:
                'Investigate severity regression before accepting a new baseline.',
          ),
        );
      }
      for (final budget in _metricBudgets) {
        if (budget.suite != baselineSuite.name) continue;
        final baselineMetric = baselineSuite.numericMetric(budget.metric);
        final currentMetric = _numericMetric(current.metrics[budget.metric]);
        if (baselineMetric == null || currentMetric == null) continue;
        final allowed = budget.allowedValueFrom(baselineMetric);
        if (currentMetric <= allowed) continue;
        failures.add(
          QaFailure(
            suite: name,
            id: 'metric_regressed:${baselineSuite.name}:${budget.metric}',
            message: 'Suite runtime metric regressed over baseline.',
            severity: context.strict ? QaSeverity.error : QaSeverity.warning,
            expected:
                '${budget.metric} <= ${allowed.toStringAsFixed(0)} from baseline ${baselineMetric.toStringAsFixed(0)}',
            actual: currentMetric.toStringAsFixed(0),
            suggestedFix:
                'Profile cold-start indexing, warm-cache lookup, or intentionally update the reviewed performance baseline.',
          ),
        );
      }
    }

    for (final current in currentSuites.values) {
      checked++;
      if (baseline.suites.containsKey(current.name)) continue;
      failures.add(
        QaFailure(
          suite: name,
          id: 'suite_added:${current.name}',
          message: 'A new suite is not present in the baseline.',
          severity: QaSeverity.info,
          expected: 'baseline reviewed for this suite',
          actual: current.name,
          suggestedFix:
              'Review the new suite output and update the baseline when accepted.',
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'baselinePath': baselinePath,
        'baselineSuites': baseline.suites.length,
        'currentSuites': currentSuites.length,
      },
    );
  }
}

class _MetricBudget {
  const _MetricBudget({
    required this.suite,
    required this.metric,
    required this.relativeIncreaseAllowed,
    required this.absoluteIncreaseAllowed,
  });

  final String suite;
  final String metric;
  final double relativeIncreaseAllowed;
  final double absoluteIncreaseAllowed;

  double allowedValueFrom(double baseline) {
    final relative = baseline * (1 + relativeIncreaseAllowed);
    final absolute = baseline + absoluteIncreaseAllowed;
    return relative > absolute ? relative : absolute;
  }
}

class _BaselineReport {
  const _BaselineReport({required this.suites});

  final Map<String, _BaselineSuite> suites;

  static _BaselineReport fromJson(Map<String, Object?> json) {
    final results = json['results'];
    if (results is! List) return const _BaselineReport(suites: {});
    final suites = <String, _BaselineSuite>{};
    for (final entry in results) {
      if (entry is! Map) continue;
      final suite = _BaselineSuite.fromJson(entry.cast<String, Object?>());
      if (suite.name.isNotEmpty) suites[suite.name] = suite;
    }
    return _BaselineReport(suites: suites);
  }
}

class _BaselineSuite {
  const _BaselineSuite({
    required this.name,
    required this.checked,
    required this.actualFailureCount,
    required this.severityCounts,
    required this.metrics,
    required this.failureIds,
  });

  final String name;
  final int checked;
  final int actualFailureCount;
  final Map<String, int> severityCounts;
  final Map<String, Object?> metrics;
  final Set<String> failureIds;

  double? numericMetric(String metric) => _numericMetric(metrics[metric]);

  static _BaselineSuite fromJson(Map<String, Object?> json) {
    final severityCounts = <String, int>{};
    final rawSeverityCounts = json['severityCounts'];
    if (rawSeverityCounts is Map) {
      for (final entry in rawSeverityCounts.entries) {
        severityCounts[entry.key.toString()] =
            (entry.value as num?)?.toInt() ?? 0;
      }
    }
    final failureIds = <String>{};
    final rawFailures = json['failures'];
    if (rawFailures is List) {
      for (final failure in rawFailures) {
        if (failure is! Map) continue;
        final id = failure['id']?.toString().trim();
        if (id == null || id.isEmpty) continue;
        failureIds.add(id);
      }
    }
    return _BaselineSuite(
      name: json['name'] as String? ?? '',
      checked: (json['checked'] as num?)?.toInt() ?? 0,
      actualFailureCount:
          (json['actualFailureCount'] as num?)?.toInt() ??
          (json['failureCount'] as num?)?.toInt() ??
          0,
      severityCounts: severityCounts,
      metrics: (json['metrics'] as Map?)?.cast<String, Object?>() ?? const {},
      failureIds: failureIds,
    );
  }
}

double? _numericMetric(Object? raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw);
  return null;
}
