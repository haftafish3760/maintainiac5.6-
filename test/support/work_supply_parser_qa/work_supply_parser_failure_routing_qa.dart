import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFailureRoutingSuite extends QaSuite {
  const WorkSupplyParserFailureRoutingSuite()
    : super('inventory.failure_routing_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _triagePath =
      'test/support/qa_harness/qa_harness.dart';
  static const _failureDigestPath =
      'tool/work_supply_parser_qa_failure_digest.dart';
  static const _reportDigestPath =
      'tool/work_supply_parser_qa_report_digest.dart';
  static const _runIntelligencePath =
      'tool/work_supply_parser_qa_run_intelligence_report.dart';

  static const _triageCategories = {
    'schema',
    'alias',
    'merchant_rule',
    'conflict',
    'normalization',
    'category',
    'unit',
    'quantity',
    'confidence',
    'context',
    'parser_engine',
    'privacy',
    'security',
    'performance',
    'governance',
    'review_safety',
    'fixture',
    'economics',
    'locale',
    'baseline',
    'unknown',
  };

  static const _routingExpectations = {
    'schema': 'inventory.catalog_schema',
    'alias': 'inventory.alias_conflicts',
    'merchant_rule': 'inventory.merchant_rules',
    'conflict': 'inventory.conflict_graph',
    'normalization': 'inventory.metamorphic_variants',
    'category': 'inventory.workflow_routing',
    'unit': 'inventory.math_reconciliation',
    'quantity': 'inventory.economics_contract',
    'confidence': 'inventory.confidence_calibration',
    'context': 'inventory.trade_context',
    'parser_engine': 'inventory.generated_cases',
    'privacy': 'inventory.security_privacy',
    'security': 'inventory.boundary_guard',
    'performance': 'inventory.runtime_profile_contract',
    'governance': 'inventory.requirement_coverage',
    'review_safety': 'inventory.review_safety_contract',
    'fixture': 'inventory.fixture_coverage_matrix',
    'economics': 'inventory.economics_contract',
    'locale': 'inventory.locale_contract',
    'baseline': 'inventory.baseline_contract',
    'unknown': 'inventory.failure_taxonomy_contract',
  };

  static const _digestTokens = {
    'failedCells',
    'failurePreview',
    'transcriptPath',
    'QA_FAILURE_DIGEST',
  };

  static const _reportTokens = {
    'failuresByTriageCategory',
    'QA_TRIAGE_GROUP',
    'QA_FAILURE_GROUP',
    'suggestedFix',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final triageSource = _read(_triagePath);
    final digestSource = _read(_failureDigestPath);
    final reportSource =
        '${_read(_reportDigestPath)}\n${_read(_runIntelligencePath)}\n$triageSource';
    var checked = 0;

    checked += _triageCategories.length;
    for (final category in _triageCategories) {
      if (triageSource.contains(category)) continue;
      failures.add(
        _failure(
          id: 'missing_triage_category:$category',
          message: 'Failure triage category is not defined in the QA harness.',
          expected: category,
          actual: 'not found',
          fix:
              'Define every failure category so parser QA reports have stable routing.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _routingExpectations.length;
    for (final entry in _routingExpectations.entries) {
      if (progress.contains(entry.key) && progress.contains(entry.value)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_failure_route:${entry.key}',
          message: 'Progress memory is missing a failure-category rerun route.',
          expected: '${entry.key} -> ${entry.value}',
          actual: 'not found in $_progressPath',
          fix:
              'Map each failure category to the smallest inventory QA suite that should be rerun first.',
          category: QaFailureTriage.performance,
        ),
      );
    }

    checked += _digestTokens.length;
    for (final token in _digestTokens) {
      if (digestSource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_failure_digest_token:${_safeId(token)}',
          message: 'Failure digest tool is missing compact failure routing evidence.',
          expected: token,
          actual: 'not found in $_failureDigestPath',
          fix:
              'Failure digests should identify failed cells, transcripts, and compact previews without reopening every log.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _reportTokens.length;
    for (final token in _reportTokens) {
      if (reportSource.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_report_routing_token:${_safeId(token)}',
          message: 'QA reports are missing failure grouping/routing evidence.',
          expected: token,
          actual: 'not found in report sources',
          fix:
              'Reports must group failures by suite and triage category with suggested fixes.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'triageCategoryCount': _triageCategories.length,
        'routingExpectationCount': _routingExpectations.length,
        'contract':
            'Every parser QA failure category must route to a focused inventory suite or digest, not a broad rerun by default.',
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
