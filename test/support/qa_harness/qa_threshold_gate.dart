import 'qa_harness.dart';

Future<QaReport> runQaHarnessWithThresholdGate({
  required QaHarness harness,
  required QaContext context,
  QaRunConfig runConfig = const QaRunConfig(),
}) async {
  final startedAt = DateTime.now();
  final stopwatch = Stopwatch()..start();
  final results = <QaSuiteResult>[];
  for (final suite in harness.suites) {
    if (context.suiteFilter.isNotEmpty &&
        !context.suiteFilter.contains(suite.name)) {
      continue;
    }
    results.add(await suite.run(context));
  }
  if (context.suiteFilter.isEmpty ||
      context.suiteFilter.contains(QaThresholdGateSuite.suiteName)) {
    results.add(
      QaThresholdGateSuite(
        priorResults: List.unmodifiable(results),
      ).runSync(context),
    );
  }
  stopwatch.stop();
  return QaReport(
    domain: harness.domain,
    strict: context.strict,
    results: results,
    startedAt: startedAt,
    duration: stopwatch.elapsed,
    runConfig: runConfig,
  );
}

class QaThresholdGateSuite extends QaSuite {
  const QaThresholdGateSuite({required this.priorResults}) : super(suiteName);

  static const suiteName = 'qa.threshold_gate';
  static const _semanticParserSuites = {
    'inventory.dangerous_words',
    'inventory.golden_fixtures',
    'inventory.generated_cases',
    'inventory.metamorphic_variants',
    'inventory.property_cases',
    'inventory.trade_context',
    'inventory.merchant_rules',
    'inventory.noise_lines',
  };

  final List<QaSuiteResult> priorResults;

  QaSuiteResult runSync(QaContext context) {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final thresholds = context.thresholds;
    final actualFailures = priorResults.fold<int>(
      0,
      (sum, result) => sum + result.actualFailureCount,
    );
    final severities = <QaSeverity, int>{
      for (final severity in QaSeverity.values) severity: 0,
    };
    for (final result in priorResults) {
      for (final failure in result.failures) {
        severities.update(failure.severity, (count) => count + 1);
      }
    }
    final elapsedMs = priorResults.fold<int>(
      0,
      (sum, result) => sum + result.duration.inMilliseconds,
    );

    _checkBudget(
      failures,
      context,
      id: 'max_actual_failures',
      actual: actualFailures,
      max: thresholds.maxActualFailures,
      severity: context.isReleaseProfile
          ? QaSeverity.critical
          : QaSeverity.info,
      message: 'Actual failure count is above the profile budget.',
    );
    _checkBudget(
      failures,
      context,
      id: 'max_critical_failures',
      actual: severities[QaSeverity.critical] ?? 0,
      max: thresholds.maxCriticalFailures,
      severity: QaSeverity.critical,
      message: 'Critical failure count is above the profile budget.',
    );
    _checkBudget(
      failures,
      context,
      id: 'max_error_failures',
      actual: severities[QaSeverity.error] ?? 0,
      max: thresholds.maxErrorFailures,
      severity: context.isReleaseProfile
          ? QaSeverity.critical
          : QaSeverity.info,
      message: 'Error failure count is above the profile budget.',
    );
    _checkBudget(
      failures,
      context,
      id: 'max_warning_failures',
      actual: severities[QaSeverity.warning] ?? 0,
      max: thresholds.maxWarningFailures,
      severity: context.isReleaseProfile ? QaSeverity.error : QaSeverity.info,
      message: 'Warning failure count is above the profile budget.',
    );
    _checkBudget(
      failures,
      context,
      id: 'max_duration_ms',
      actual: elapsedMs,
      max: thresholds.maxDurationMs,
      severity: QaSeverity.error,
      message: 'Harness runtime is above the profile budget.',
    );
    for (final result in priorResults) {
      if (context.isFullProfile &&
          _semanticParserSuites.contains(result.name) &&
          _intMetric(result.metrics['parserCalls']) <= 0) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_parser_call_evidence:${result.name}',
            message:
                'Full/release semantic parser suite did not prove parser execution.',
            severity: context.isReleaseProfile
                ? QaSeverity.critical
                : QaSeverity.error,
            expected: 'parserCalls > 0',
            actual: '${result.metrics['parserCalls'] ?? 'missing'}',
            suggestedFix:
                'Record real parser call counts in semantic suites; do not let contract-only evidence stand in for runtime parser behavior.',
            metadata: const {'triageCategory': QaFailureTriage.parserEngine},
          ),
        );
      }
      _checkBudget(
        failures,
        context,
        id: 'max_suite_duration_ms:${result.name}',
        actual: result.duration.inMilliseconds,
        max: thresholds.maxSuiteDurationMs[result.name] ?? -1,
        severity: QaSeverity.warning,
        message: 'Suite runtime is above its profile budget.',
      );
      _checkBudget(
        failures,
        context,
        id: 'max_suite_actual_failures:${result.name}',
        actual: result.actualFailureCount,
        max: thresholds.maxSuiteActualFailures[result.name] ?? -1,
        severity: context.isReleaseProfile ? QaSeverity.error : QaSeverity.info,
        message: 'Suite actual failure count is above its profile budget.',
      );
      _checkMinimumDoubleBudget(
        failures,
        context,
        id: 'min_suite_checks_per_second:${result.name}',
        actual: _checksPerSecond(result),
        min: thresholds.minSuiteChecksPerSecond[result.name] ?? -1,
        severity: context.isReleaseProfile
            ? QaSeverity.error
            : QaSeverity.warning,
        message: 'Suite throughput is below its profile budget.',
      );
    }

    return timer.finish(
      suite: name,
      checked: 5 + (priorResults.length * 3),
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'profile': context.profile,
        'actualFailures': actualFailures,
        'criticalFailures': severities[QaSeverity.critical] ?? 0,
        'errorFailures': severities[QaSeverity.error] ?? 0,
        'warningFailures': severities[QaSeverity.warning] ?? 0,
        'priorSuiteDurationMs': elapsedMs,
        'semanticParserSuitesChecked': [
          for (final result in priorResults)
            if (_semanticParserSuites.contains(result.name)) result.name,
        ],
        'semanticParserCalls': priorResults.fold<int>(
          0,
          (sum, result) => sum + _intMetric(result.metrics['parserCalls']),
        ),
      },
    );
  }

  @override
  Future<QaSuiteResult> run(QaContext context) async => runSync(context);

  double _checksPerSecond(QaSuiteResult result) {
    final durationMs = result.duration.inMilliseconds;
    if (durationMs <= 0) return result.checked.toDouble();
    return result.checked * 1000 / durationMs;
  }

  void _checkMinimumDoubleBudget(
    List<QaFailure> failures,
    QaContext context, {
    required String id,
    required double actual,
    required double min,
    required QaSeverity severity,
    required String message,
  }) {
    if (min < 0 || actual >= min) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: message,
        severity: severity,
        expected: '>= ${min.toStringAsFixed(2)}',
        actual: actual.toStringAsFixed(2),
        suggestedFix:
            'Profile the parser path, reduce candidate scans, or move this suite to a slower release-only profile with owner approval.',
      ),
    );
  }

  void _checkBudget(
    List<QaFailure> failures,
    QaContext context, {
    required String id,
    required int actual,
    required int max,
    required QaSeverity severity,
    required String message,
  }) {
    if (max < 0 || actual <= max) return;
    failures.add(
      QaFailure(
        suite: name,
        id: id,
        message: message,
        severity: severity,
        expected: '<= $max',
        actual: '$actual',
        suggestedFix:
            'Reduce parser QA failures or adjust the ${context.profile} threshold only with release-owner approval.',
      ),
    );
  }
}

int _intMetric(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
