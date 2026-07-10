import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDifferentialRegressionSuite extends QaSuite {
  const WorkSupplyParserDifferentialRegressionSuite()
    : super('inventory.differential_regression_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_impact_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_baseline_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_determinism_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_signoff_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_artifact_contract_qa.dart',
    'test/work_supply_parser_differential_regression_behavior_test.dart',
  };

  static const _diffAxes = {
    'old parser',
    'new parser',
    'old catalog',
    'new catalog',
    'old pack version',
    'new pack version',
    'changed item',
    'changed alias',
    'changed merchant rule',
    'changed confidence',
    'changed category',
    'changed review status',
  };

  static const _diffRules = {
    'differential_run_reports_every_changed_result',
    'differential_run_requires_reason_for_changed_result',
    'differential_run_blocks_false_confident_regression',
    'differential_run_blocks_source_mutation_regression',
    'differential_run_blocks_privacy_regression',
    'differential_run_blocks_performance_budget_regression',
    'differential_run_allows_expected_improvement_with_note',
    'differential_run_groups_changes_by_trade',
    'differential_run_groups_changes_by_merchant',
    'differential_run_groups_changes_by_locale',
    'differential_run_outputs_surgical_rerun_targets',
    'differential_run_is_local_only',
  };

  static const _diffReportFields = {
    'fixture id',
    'old candidate id',
    'new candidate id',
    'old confidence',
    'new confidence',
    'old review status',
    'new review status',
    'old category',
    'new category',
    'change reason',
    'approved change',
    'blocking regression',
  };

  static const _releaseGateTokens = {
    'release gate',
    'signoff',
    'baseline',
    'holdout',
    'mutation',
    'performance',
    'privacy',
    'security',
    'local-only',
    'no live Firebase',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _diffAxes.length;
    _requireTokens(
      failures,
      source,
      _diffAxes,
      idPrefix: 'missing_diff_axis',
      message: 'Differential regression QA is missing comparison axes.',
      fix:
          'Differential QA must compare old/new parser, catalog, pack version, aliases, merchant rules, confidence, category, and review status.',
      triage: QaFailureTriage.baseline,
    );

    checked += _diffRules.length;
    _requireRules(failures, source, _diffRules);

    checked += _diffReportFields.length;
    _requireTokens(
      failures,
      source,
      _diffReportFields,
      idPrefix: 'missing_diff_report_field',
      message: 'Differential regression QA is missing report fields.',
      fix:
          'Differential reports must show old/new candidate, confidence, review status, category, reason, approval, and blocking status.',
      triage: QaFailureTriage.governance,
    );

    checked += _releaseGateTokens.length;
    _requireTokens(
      failures,
      source,
      _releaseGateTokens,
      idPrefix: 'missing_diff_release_gate',
      message: 'Differential regression QA is missing release-gate concepts.',
      fix:
          'Differential QA must feed release gates with baseline, holdout, mutation, performance, privacy, security, and local-only evidence.',
      triage: QaFailureTriage.governance,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Every parser/catalog change must compare old vs new behavior and explain, approve, or block each changed result.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_differential_rule:${_safeId(rule)}',
          message: 'Differential regression QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit old-vs-new comparison rules before parser/catalog changes can be accepted.',
          triage: QaFailureTriage.baseline,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
