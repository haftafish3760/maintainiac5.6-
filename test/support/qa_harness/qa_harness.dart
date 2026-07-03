import 'dart:convert';
import 'dart:io';

export 'maintainiac_qa_assertions.dart';
export 'maintainiac_audit_trail.dart';
export 'maintainiac_qa_artifact_policy.dart';
export 'maintainiac_qa_checkpoint_policy.dart';
export 'maintainiac_qa_backbone.dart';
export 'maintainiac_qa_builders.dart';
export 'maintainiac_qa_case_registry.dart';
export 'maintainiac_device_capability.dart';
export 'maintainiac_export_privacy.dart';
export 'maintainiac_expense_parser_consumer_contract.dart';
export 'maintainiac_failure_taxonomy.dart';
export 'maintainiac_fixture_governance_gate.dart';
export 'maintainiac_correction_learning_contract.dart';
export 'maintainiac_financial_formula_registry.dart';
export 'maintainiac_qa_environment.dart';
export 'maintainiac_qa_execution_manifest.dart';
export 'maintainiac_qa_fingerprint.dart';
export 'maintainiac_qa_fixtures.dart';
export 'maintainiac_qa_quality_gates.dart';
export 'maintainiac_qa_readiness.dart';
export 'maintainiac_qa_run_ledger.dart';
export 'maintainiac_qa_scenario_runners.dart';
export 'maintainiac_qa_telemetry_privacy_gate.dart';
export 'maintainiac_release_evidence_bundle.dart';
export 'maintainiac_release_gate_plan.dart';
export 'maintainiac_restart_lifecycle_gate.dart';
export 'maintainiac_regression_registry.dart';
export 'maintainiac_schedule_contract.dart';
export 'maintainiac_financial_ledger.dart';
export 'maintainiac_inventory_parser_consumer_contract.dart';
export 'maintainiac_job_contract.dart';
export 'maintainiac_local_first_contract.dart';
export 'maintainiac_module_boundary_gate.dart';
export 'maintainiac_module_suite_contract.dart';
export 'maintainiac_mutation_guard.dart';
export 'maintainiac_parser_candidate_contract.dart';
export 'maintainiac_parser_consumer_gate.dart';
export 'maintainiac_parser_fixture_manifest.dart';
export 'maintainiac_parser_regression_binding.dart';
export 'maintainiac_parser_release_command_plan.dart';
export 'maintainiac_payment_contract.dart';
export 'maintainiac_pricing_contract.dart';
export 'maintainiac_source_boundary.dart';
export 'maintainiac_source_truth_gate.dart';
export 'maintainiac_surgical_rerun_router.dart';
export 'maintainiac_surgical_selector_coverage.dart';
export 'maintainiac_surgical_test_selector.dart';
export 'maintainiac_sync_conflict_contract.dart';
export 'maintainiac_sync_lifecycle.dart';
export 'maintainiac_scope_policy.dart';

enum QaSeverity { info, warning, error, critical }

class QaFailure {
  const QaFailure({
    required this.suite,
    required this.id,
    required this.message,
    this.severity = QaSeverity.error,
    this.expected = '',
    this.actual = '',
    this.suggestedFix = '',
    this.metadata = const {},
  });

  final String suite;
  final String id;
  final String message;
  final QaSeverity severity;
  final String expected;
  final String actual;
  final String suggestedFix;
  final Map<String, Object?> metadata;

  String get triageCategory {
    final explicit = metadata['triageCategory']?.toString().trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    return QaFailureTriage.classify(suite: suite, id: id, message: message);
  }

  Map<String, Object?> toJson({QaRedactor redactor = const QaRedactor()}) {
    return {
      'suite': redactor(suite),
      'id': redactor(id),
      'severity': severity.name,
      'triageCategory': redactor(triageCategory),
      'message': redactor(message),
      if (expected.isNotEmpty) 'expected': redactor(expected),
      if (actual.isNotEmpty) 'actual': redactor(actual),
      if (suggestedFix.isNotEmpty) 'suggestedFix': redactor(suggestedFix),
      if (metadata.isNotEmpty) 'metadata': redactor.value(metadata),
    };
  }
}

class QaSuiteResult {
  const QaSuiteResult({
    required this.name,
    required this.duration,
    required this.checked,
    this.failures = const [],
    this.metrics = const {},
    this.totalFailureCount,
  });

  final String name;
  final Duration duration;
  final int checked;
  final List<QaFailure> failures;
  final Map<String, Object?> metrics;
  final int? totalFailureCount;

  int get actualFailureCount => totalFailureCount ?? failures.length;

  bool get hasBlockingFailures {
    return failures.any(
      (failure) =>
          failure.severity == QaSeverity.error ||
          failure.severity == QaSeverity.critical,
    );
  }

  Map<String, int> get severityCounts {
    final counts = {for (final severity in QaSeverity.values) severity.name: 0};
    for (final failure in failures) {
      counts.update(failure.severity.name, (count) => count + 1);
    }
    return counts;
  }

  Map<String, Object?> toJson({QaRedactor redactor = const QaRedactor()}) {
    return {
      'name': redactor(name),
      'durationMs': duration.inMilliseconds,
      'checked': checked,
      'failureCount': failures.length,
      'actualFailureCount': actualFailureCount,
      'severityCounts': severityCounts,
      'metrics': redactor.value(metrics),
      'failures': [
        for (final failure in failures) failure.toJson(redactor: redactor),
      ],
    };
  }
}

class QaReport {
  const QaReport({
    required this.domain,
    required this.strict,
    required this.results,
    required this.startedAt,
    required this.duration,
    this.runConfig = const QaRunConfig(),
  });

  final String domain;
  final bool strict;
  final List<QaSuiteResult> results;
  final DateTime startedAt;
  final Duration duration;
  final QaRunConfig runConfig;

  int get checked => results.fold(0, (sum, result) => sum + result.checked);

  int get actualFailureCount {
    return results.fold(0, (sum, result) => sum + result.actualFailureCount);
  }

  List<QaFailure> get failures {
    return [for (final result in results) ...result.failures];
  }

  bool get hasBlockingFailures {
    return results.any((result) => result.hasBlockingFailures);
  }

  Map<String, int> get failuresBySuite {
    final grouped = <String, int>{};
    for (final failure in failures) {
      grouped.update(failure.suite, (count) => count + 1, ifAbsent: () => 1);
    }
    return grouped;
  }

  Map<String, int> get severityCounts {
    final counts = {for (final severity in QaSeverity.values) severity.name: 0};
    for (final result in results) {
      for (final entry in result.severityCounts.entries) {
        counts.update(entry.key, (count) => count + entry.value);
      }
    }
    return counts;
  }

  Map<String, int> get failuresByTriageCategory {
    final grouped = <String, int>{};
    for (final failure in failures) {
      grouped.update(
        failure.triageCategory,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }
    return grouped;
  }

  List<Map<String, Object?>> get slowestSuites {
    final sorted = [...results]
      ..sort(
        (a, b) =>
            b.duration.inMilliseconds.compareTo(a.duration.inMilliseconds),
      );
    return [
      for (final result in sorted.take(8))
        {
          'name': result.name,
          'durationMs': result.duration.inMilliseconds,
          'checked': result.checked,
          'checksPerSecond': result.duration.inMilliseconds == 0
              ? result.checked
              : (result.checked * 1000 / result.duration.inMilliseconds)
                    .toStringAsFixed(2),
        },
    ];
  }

  Map<String, Object?> get packHealth {
    final suite = _suiteNamed(results, 'inventory.pack_health_score');
    if (suite == null) {
      return {
        'suite': 'inventory.pack_health_score',
        'presentContracts': const <String>[],
        'missingRequiredContracts': const <String>[],
        'missingRecommendedContracts': const <String>[],
        'healthScore': 0.0,
        'coverageScore': 0.0,
        'readinessLabel': 'not run',
        'failureCount': 0,
        'checked': 0,
        'durationMs': 0,
      };
    }
    final present = _stringList(suite.metrics['presentContracts']);
    final missingRequired = _stringList(
      suite.metrics['missingRequiredContracts'],
    );
    final missingRecommended = _stringList(
      suite.metrics['missingRecommendedContracts'],
    );
    final total =
        present.length + missingRequired.length + missingRecommended.length;
    final healthScore = total == 0 ? 0.0 : present.length / total;
    final readinessLabel = missingRequired.isNotEmpty
        ? 'blocked'
        : missingRecommended.isNotEmpty
        ? 'needs governance'
        : 'ready';
    return {
      'suite': suite.name,
      'presentContracts': present,
      'missingRequiredContracts': missingRequired,
      'missingRecommendedContracts': missingRecommended,
      'healthScore': double.parse(healthScore.toStringAsFixed(4)),
      'coverageScore': double.parse(healthScore.toStringAsFixed(4)),
      'readinessLabel': readinessLabel,
      'failureCount': suite.actualFailureCount,
      'checked': suite.checked,
      'durationMs': suite.duration.inMilliseconds,
    };
  }

  Map<String, Object?> get adminHealth {
    final blockingFailures =
        severityCounts['error']! + severityCounts['critical']!;
    return {
      'domain': domain,
      'profile': runConfig.profile,
      'preset': runConfig.preset,
      'strict': strict,
      'status': blockingFailures > 0
          ? 'blocked'
          : actualFailureCount > 0
          ? 'needs review'
          : 'passing',
      'checked': checked,
      'actualFailureCount': actualFailureCount,
      'blockingFailureCount': blockingFailures,
      'severityCounts': severityCounts,
      'failuresByTriageCategory': failuresByTriageCategory,
      'slowestSuites': slowestSuites,
      'packHealth': packHealth,
      'durationMs': duration.inMilliseconds,
      'startedAt': startedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toJson({QaRedactor redactor = const QaRedactor()}) {
    return {
      'domain': redactor(domain),
      'strict': strict,
      'startedAt': startedAt.toIso8601String(),
      if (runConfig.isNotEmpty) 'runConfig': redactor.value(runConfig.toJson()),
      'durationMs': duration.inMilliseconds,
      'checked': checked,
      'failureCount': failures.length,
      'actualFailureCount': actualFailureCount,
      'severityCounts': severityCounts,
      'failuresBySuite': redactor.value(failuresBySuite),
      'failuresByTriageCategory': redactor.value(failuresByTriageCategory),
      'slowestSuites': redactor.value(slowestSuites),
      'packHealth': redactor.value(packHealth),
      'adminHealth': redactor.value(adminHealth),
      'results': [
        for (final result in results) result.toJson(redactor: redactor),
      ],
    };
  }

  String toSummary({QaRedactor redactor = const QaRedactor()}) {
    final buffer = StringBuffer()
      ..writeln(
        'QA_REPORT domain=${redactor(domain)} strict=$strict checked=$checked '
        'failures=${failures.length} actualFailures=$actualFailureCount '
        'severity=$severityCounts '
        'durationMs=${duration.inMilliseconds}',
      );
    if (runConfig.isNotEmpty) {
      buffer.writeln('QA_RUN_CONFIG ${redactor.value(runConfig.toJson())}');
    }
    for (final result in results) {
      buffer.writeln(
        'QA_SUITE name=${redactor(result.name)} checked=${result.checked} '
        'failures=${result.failures.length} '
        'actualFailures=${result.actualFailureCount} '
        'durationMs=${result.duration.inMilliseconds}',
      );
    }
    for (final suite in slowestSuites.take(5)) {
      buffer.writeln(
        'QA_SLOW_SUITE name=${redactor(suite['name'].toString())} '
        'durationMs=${suite['durationMs']} checked=${suite['checked']} '
        'checksPerSecond=${suite['checksPerSecond']}',
      );
    }
    final health = packHealth;
    buffer.writeln(
      'QA_PACK_HEALTH readinessLabel=${redactor(health['readinessLabel'].toString())} '
      'healthScore=${health['healthScore']} '
      'present=${(health['presentContracts'] as List).length} '
      'missingRequired=${(health['missingRequiredContracts'] as List).length} '
      'missingRecommended=${(health['missingRecommendedContracts'] as List).length}',
    );
    final admin = redactor.value(adminHealth) as Map;
    buffer.writeln(
      'QA_ADMIN_HEALTH status=${admin['status']} '
      'profile=${admin['profile']} preset=${admin['preset']} '
      'checked=${admin['checked']} actualFailures=${admin['actualFailureCount']} '
      'blockingFailures=${admin['blockingFailureCount']} '
      'durationMs=${admin['durationMs']}',
    );
    for (final entry in failuresBySuite.entries) {
      buffer.writeln(
        'QA_FAILURE_GROUP suite=${redactor(entry.key)} count=${entry.value}',
      );
    }
    for (final entry in failuresByTriageCategory.entries) {
      buffer.writeln(
        'QA_TRIAGE_GROUP category=${redactor(entry.key)} count=${entry.value}',
      );
    }
    for (final failure in failures.take(40)) {
      buffer.writeln(
        'QA_FAILURE suite=${redactor(failure.suite)} '
        'id=${redactor(failure.id)} severity=${failure.severity.name} '
        'triage=${redactor(failure.triageCategory)} '
        'message=${redactor(failure.message)} '
        'expected=${redactor(failure.expected)} '
        'actual=${redactor(failure.actual)} '
        'fix=${redactor(failure.suggestedFix)}',
      );
    }
    return buffer.toString();
  }
}

List<String> _stringList(Object? raw) {
  if (raw is! List) return const [];
  return [for (final value in raw) value.toString()];
}

QaSuiteResult? _suiteNamed(List<QaSuiteResult> results, String name) {
  for (final result in results) {
    if (result.name == name) return result;
  }
  return null;
}

class QaRunConfig {
  const QaRunConfig({
    this.profile = '',
    this.preset = '',
    this.baselinePath = '',
    this.maxGeneratedCases = 0,
    this.maxFailuresPerSuite = 0,
    this.catalogSchemaSampleLimit = 0,
    this.aliasSampleLimit = 0,
    this.mutationMode = '',
    this.mutationScenarios = '',
    this.mutationDryRun = true,
    this.shardId = '',
    this.timeoutBudgetMs = 0,
    this.resumeFrom = '',
    this.suiteFilter = const {},
  });

  final String profile;
  final String preset;
  final String baselinePath;
  final int maxGeneratedCases;
  final int maxFailuresPerSuite;
  final int catalogSchemaSampleLimit;
  final int aliasSampleLimit;
  final String mutationMode;
  final String mutationScenarios;
  final bool mutationDryRun;
  final String shardId;
  final int timeoutBudgetMs;
  final String resumeFrom;
  final Set<String> suiteFilter;

  bool get isNotEmpty {
    return profile.isNotEmpty ||
        preset.isNotEmpty ||
        baselinePath.isNotEmpty ||
        maxGeneratedCases > 0 ||
        maxFailuresPerSuite > 0 ||
        catalogSchemaSampleLimit > 0 ||
        aliasSampleLimit > 0 ||
        mutationMode.isNotEmpty ||
        mutationScenarios.isNotEmpty ||
        mutationDryRun == false ||
        shardId.isNotEmpty ||
        timeoutBudgetMs > 0 ||
        resumeFrom.isNotEmpty ||
        suiteFilter.isNotEmpty;
  }

  Map<String, Object?> toJson() {
    return {
      if (profile.isNotEmpty) 'profile': profile,
      if (preset.isNotEmpty) 'preset': preset,
      if (baselinePath.isNotEmpty) 'baselinePath': baselinePath,
      if (maxGeneratedCases > 0) 'maxGeneratedCases': maxGeneratedCases,
      if (maxFailuresPerSuite > 0) 'maxFailuresPerSuite': maxFailuresPerSuite,
      if (catalogSchemaSampleLimit > 0)
        'catalogSchemaSampleLimit': catalogSchemaSampleLimit,
      if (aliasSampleLimit > 0) 'aliasSampleLimit': aliasSampleLimit,
      if (mutationMode.isNotEmpty) 'mutationMode': mutationMode,
      if (mutationScenarios.isNotEmpty) 'mutationScenarios': mutationScenarios,
      if (mutationDryRun == false) 'mutationDryRun': mutationDryRun,
      if (shardId.isNotEmpty) 'shardId': shardId,
      if (timeoutBudgetMs > 0) 'timeoutBudgetMs': timeoutBudgetMs,
      if (resumeFrom.isNotEmpty) 'resumeFrom': resumeFrom,
      if (suiteFilter.isNotEmpty) 'suiteFilter': suiteFilter.toList()..sort(),
    };
  }
}

class QaContext {
  const QaContext({
    required this.strict,
    required this.redactor,
    this.profile = 'smoke',
    this.maxGeneratedCases = 500,
    this.maxFailuresPerSuite = 250,
    this.catalogSchemaSampleLimit = 6000,
    this.aliasSampleLimit = 2500,
    this.suiteFilter = const {},
    this.thresholds = const QaThresholds(),
  });

  final bool strict;
  final QaRedactor redactor;
  final String profile;
  final int maxGeneratedCases;
  final int maxFailuresPerSuite;
  final int catalogSchemaSampleLimit;
  final int aliasSampleLimit;
  final Set<String> suiteFilter;
  final QaThresholds thresholds;

  bool get isFullProfile => profile == 'full' || profile == 'release';

  bool get isReleaseProfile => profile == 'release';
}

class QaThresholds {
  const QaThresholds({
    this.maxActualFailures = -1,
    this.maxCriticalFailures = -1,
    this.maxErrorFailures = -1,
    this.maxWarningFailures = -1,
    this.maxDurationMs = -1,
    this.maxSuiteDurationMs = const {},
    this.maxSuiteActualFailures = const {},
    this.minSuiteChecksPerSecond = const {},
  });

  final int maxActualFailures;
  final int maxCriticalFailures;
  final int maxErrorFailures;
  final int maxWarningFailures;
  final int maxDurationMs;
  final Map<String, int> maxSuiteDurationMs;
  final Map<String, int> maxSuiteActualFailures;
  final Map<String, double> minSuiteChecksPerSecond;

  static QaThresholds forProfile(String profile) {
    switch (profile) {
      case 'release':
        return const QaThresholds(
          maxActualFailures: 0,
          maxCriticalFailures: 0,
          maxErrorFailures: 0,
          maxWarningFailures: 0,
          maxDurationMs: 600000,
          minSuiteChecksPerSecond: {
            'inventory.dangerous_words': 1,
            'inventory.golden_fixtures': 1,
            'inventory.generated_cases': 1,
            'inventory.metamorphic_variants': 1,
            'inventory.property_cases': 1,
            'inventory.trade_context': 1,
          },
        );
      case 'full':
        return const QaThresholds(
          maxCriticalFailures: 0,
          maxErrorFailures: 0,
          maxWarningFailures: 250,
          maxDurationMs: 600000,
          minSuiteChecksPerSecond: {
            'inventory.dangerous_words': 1,
            'inventory.golden_fixtures': 1,
            'inventory.generated_cases': 1,
            'inventory.metamorphic_variants': 1,
            'inventory.property_cases': 1,
            'inventory.trade_context': 1,
          },
        );
      case 'smoke':
      default:
        return const QaThresholds(
          maxCriticalFailures: 0,
          maxDurationMs: 120000,
          maxSuiteDurationMs: {'inventory.catalog_schema': 90000},
        );
    }
  }
}

abstract class QaSuite {
  const QaSuite(this.name);

  final String name;

  Future<QaSuiteResult> run(QaContext context);
}

class QaFailureTriage {
  const QaFailureTriage._();

  static const schema = 'schema';
  static const alias = 'alias';
  static const merchantRule = 'merchant_rule';
  static const conflict = 'conflict';
  static const normalization = 'normalization';
  static const category = 'category';
  static const unit = 'unit';
  static const quantity = 'quantity';
  static const confidence = 'confidence';
  static const context = 'context';
  static const parserEngine = 'parser_engine';
  static const privacy = 'privacy';
  static const security = 'security';
  static const performance = 'performance';
  static const governance = 'governance';
  static const reviewSafety = 'review_safety';
  static const fixture = 'fixture';
  static const economics = 'economics';
  static const locale = 'locale';
  static const baseline = 'baseline';
  static const unknown = 'unknown';

  static String classify({
    required String suite,
    required String id,
    String message = '',
  }) {
    final haystack = '$suite $id $message'.toLowerCase();
    if (haystack.contains('review_safety') ||
        haystack.contains('review_status') ||
        haystack.contains('auto_save') ||
        haystack.contains('auto_accept') ||
        haystack.contains('confirmed')) {
      return reviewSafety;
    }
    if (haystack.contains('security') ||
        haystack.contains('forbidden_') ||
        haystack.contains('hostile') ||
        haystack.contains('network') ||
        haystack.contains('firebase') ||
        haystack.contains('injection')) {
      return security;
    }
    if (haystack.contains('privacy') ||
        haystack.contains('redactor') ||
        haystack.contains('private') ||
        haystack.contains('leaked')) {
      return privacy;
    }
    if (haystack.contains('baseline')) return baseline;
    if (haystack.contains('threshold') ||
        haystack.contains('duration') ||
        haystack.contains('checks_per_second') ||
        haystack.contains('performance')) {
      return performance;
    }
    if (haystack.contains('fixture') ||
        haystack.contains('golden') ||
        haystack.contains('case_type') ||
        haystack.contains('risk_tag')) {
      return fixture;
    }
    if (haystack.contains('governance') ||
        haystack.contains('version') ||
        haystack.contains('source_confidence') ||
        haystack.contains('generated')) {
      return governance;
    }
    if (haystack.contains('alias')) return alias;
    if (haystack.contains('merchant')) return merchantRule;
    if (haystack.contains('conflict') ||
        haystack.contains('duplicate') ||
        haystack.contains('negative_match') ||
        haystack.contains('dangerous') ||
        haystack.contains('generic')) {
      return conflict;
    }
    if (haystack.contains('normaliz') ||
        haystack.contains('metamorphic') ||
        haystack.contains('variant') ||
        haystack.contains('raw_line_changed')) {
      return normalization;
    }
    if (haystack.contains('category') ||
        haystack.contains('trade') ||
        haystack.contains('system') ||
        haystack.contains('item_type') ||
        haystack.contains('scope') ||
        haystack.contains('impact')) {
      return category;
    }
    if (haystack.contains('unit')) return unit;
    if (haystack.contains('quantity') ||
        haystack.contains('pack') ||
        haystack.contains('stock')) {
      return quantity;
    }
    if (haystack.contains('price') ||
        haystack.contains('tax') ||
        haystack.contains('total') ||
        haystack.contains('cost') ||
        haystack.contains('economics') ||
        haystack.contains('math')) {
      return economics;
    }
    if (haystack.contains('confidence')) return confidence;
    if (haystack.contains('context') ||
        haystack.contains('scope') ||
        haystack.contains('unscoped')) {
      return context;
    }
    if (haystack.contains('locale') ||
        haystack.contains('spanish') ||
        haystack.contains('language')) {
      return locale;
    }
    if (haystack.contains('schema') ||
        haystack.contains('missing_id') ||
        haystack.contains('missing_name') ||
        haystack.contains('invalid_')) {
      return schema;
    }
    if (haystack.contains('parser') ||
        haystack.contains('match') ||
        haystack.contains('candidate')) {
      return parserEngine;
    }
    return unknown;
  }
}

class QaHarness {
  const QaHarness({required this.domain, required this.suites});

  final String domain;
  final List<QaSuite> suites;

  Future<QaReport> run(QaContext context) async {
    final startedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final results = <QaSuiteResult>[];
    for (final suite in suites) {
      if (context.suiteFilter.isNotEmpty &&
          !context.suiteFilter.contains(suite.name)) {
        continue;
      }
      results.add(await suite.run(context));
    }
    stopwatch.stop();
    return QaReport(
      domain: domain,
      strict: context.strict,
      results: results,
      startedAt: startedAt,
      duration: stopwatch.elapsed,
    );
  }
}

class QaRedactor {
  const QaRedactor();

  String call(String value) {
    return value
        .replaceAll(
          RegExp(r'\b[\w.+%-]+@[\w.-]+\.[A-Za-z]{2,}\b'),
          '[REDACTED_EMAIL]',
        )
        .replaceAll(
          RegExp(
            r'\b(?:visa|mastercard|amex|discover|card|payment|ending|last4|last four)'
            r'\s*(?:ending|last4|last four|#|:)?\s*\d{4}\b',
            caseSensitive: false,
          ),
          '[REDACTED_CARD_LAST4]',
        )
        .replaceAll(RegExp(r'\b\d{12,19}\b'), '[REDACTED_CARD_LIKE_NUMBER]')
        .replaceAll(
          RegExp(
            r'\b(?:auth|approval|transaction|trans)\s*#?\s*\w+'
            r'|\breceipt\s*(?:#|no\.?|number|id)\s*\w+',
            caseSensitive: false,
          ),
          '[REDACTED_RECEIPT_ID]',
        )
        .replaceAll(
          RegExp(
            r'\b(customer|client|homeowner)\s+[A-Z][a-z]+(?:\s+[A-Z][a-z]+){0,2}\b',
            caseSensitive: false,
          ),
          '[REDACTED_PERSON_NAME]',
        )
        .replaceAll(
          RegExp(
            r'\b\d{1,6}\s+[A-Za-z0-9 .#-]{2,40}\s+'
            r'(?:st|street|rd|road|ave|avenue|blvd|lane|ln|dr|drive|ct|court)\b',
            caseSensitive: false,
          ),
          '[REDACTED_ADDRESS]',
        )
        .replaceAll(RegExp(r'\b\d{3}[-.]\d{3}[-.]\d{4}\b'), '[REDACTED_PHONE]')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Object? value(Object? raw) {
    if (raw is String) return call(raw);
    if (raw is num || raw is bool || raw == null) return raw;
    if (raw is Set) {
      return [for (final entry in raw) value(entry)];
    }
    if (raw is Iterable) {
      return [for (final entry in raw) value(entry)];
    }
    if (raw is Map) {
      final redacted = <String, Object?>{};
      for (final entry in raw.entries) {
        final mapEntry = _redactedMapEntry(entry);
        redacted[mapEntry.key] = mapEntry.value;
      }
      return redacted;
    }
    return call(raw.toString());
  }

  MapEntry<String, Object?> _redactedMapEntry(
    MapEntry<Object?, Object?> entry,
  ) {
    final key = entry.key.toString();
    if (_isPrivateFieldKey(key)) {
      return MapEntry(
        '[REDACTED_PRIVATE_FIELD]',
        _privateFieldValue(entry.value),
      );
    }
    return MapEntry(call(key), value(entry.value));
  }

  Object _privateFieldValue(Object? raw) {
    if (raw == null) return '[REDACTED_PRIVATE_VALUE]';
    if (raw is Iterable) return '[REDACTED_PRIVATE_LIST]';
    if (raw is Map) return '[REDACTED_PRIVATE_MAP]';
    return '[REDACTED_PRIVATE_VALUE]';
  }

  bool _isPrivateFieldKey(String key) {
    final normalized = key.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    return normalized.contains('rawreceipt') ||
        normalized.contains('receiptimage') ||
        normalized.contains('customername') ||
        normalized == 'customer' ||
        normalized.contains('cardlast4') ||
        normalized.contains('payment') ||
        normalized.contains('email') ||
        normalized.contains('phone') ||
        normalized.contains('address') ||
        normalized.contains('deviceserial') ||
        normalized.contains('fulldeviceserial');
  }
}

Future<QaReportArtifact> writeQaReport({
  required QaReport report,
  String outputDirectory = 'build/parser_qa_reports',
}) async {
  final directory = Directory(outputDirectory);
  if (!directory.existsSync()) {
    directory.createSync(recursive: true);
  }
  final stamp = report.startedAt
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('.', '');
  final file = File('${directory.path}/${report.domain}_$stamp.json');
  final latestJson = File('${directory.path}/latest_${report.domain}.json');
  final latestSummary = File('${directory.path}/latest_${report.domain}.txt');
  final packHealthFile = File(
    '${directory.path}/${report.domain}_pack_health_$stamp.json',
  );
  final latestPackHealth = File(
    '${directory.path}/latest_${report.domain}_pack_health.json',
  );
  final packHealthJson = const JsonEncoder.withIndent(
    '  ',
  ).convert(report.packHealth);
  final reportJson = const QaRedactor().value(report.toJson());
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(reportJson),
  );
  await latestJson.writeAsString(
    const JsonEncoder.withIndent('  ').convert(reportJson),
  );
  await latestSummary.writeAsString(report.toSummary());
  await packHealthFile.writeAsString(packHealthJson);
  await latestPackHealth.writeAsString(packHealthJson);
  return QaReportArtifact(
    timestampedJsonPath: file.path,
    latestJsonPath: latestJson.path,
    latestSummaryPath: latestSummary.path,
    timestampedPackHealthJsonPath: packHealthFile.path,
    latestPackHealthJsonPath: latestPackHealth.path,
  );
}

class QaReportArtifact {
  const QaReportArtifact({
    required this.timestampedJsonPath,
    required this.latestJsonPath,
    required this.latestSummaryPath,
    required this.timestampedPackHealthJsonPath,
    required this.latestPackHealthJsonPath,
  });

  final String timestampedJsonPath;
  final String latestJsonPath;
  final String latestSummaryPath;
  final String timestampedPackHealthJsonPath;
  final String latestPackHealthJsonPath;
}

class QaStopwatch {
  QaStopwatch.start() : _stopwatch = (Stopwatch()..start());

  final Stopwatch _stopwatch;

  QaSuiteResult finish({
    required String suite,
    required int checked,
    required List<QaFailure> failures,
    Map<String, Object?> metrics = const {},
    int? maxFailures,
  }) {
    _stopwatch.stop();
    final cappedFailures = maxFailures == null || failures.length <= maxFailures
        ? failures
        : failures.take(maxFailures).toList(growable: false);
    return QaSuiteResult(
      name: suite,
      duration: _stopwatch.elapsed,
      checked: checked,
      failures: cappedFailures,
      metrics: {
        ...metrics,
        if (cappedFailures.length != failures.length)
          'totalFailuresBeforeCap': failures.length,
      },
      totalFailureCount: failures.length,
    );
  }
}
