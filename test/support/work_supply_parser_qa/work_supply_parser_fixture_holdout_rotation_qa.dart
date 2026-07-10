import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFixtureHoldoutRotationSuite extends QaSuite {
  const WorkSupplyParserFixtureHoldoutRotationSuite()
    : super('inventory.fixture_holdout_rotation_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_holdout_fixture_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_fixture_corpus_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_baseline_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_validation_strategy_qa.dart',
  };

  static const _holdoutRules = {
    'holdout_set_not_used_for_rule_tuning',
    'hidden_fixture_set_has_owner',
    'fixture_has_review_date',
    'fixture_has_locale',
    'fixture_has_merchant',
    'fixture_has_trade',
    'fixture_has_synthetic_or_real_flag',
    'expected_answer_has_confidence',
    'bad_expected_data_can_poison_parser',
    'holdout_rotation_preserves_regression_history',
  };

  static const _datasetMetrics = {
    'top-1 accuracy',
    'top-3 accuracy',
    'false confident match rate',
    'unknown rate',
    'ambiguous rate',
    'noise false-positive rate',
    'performance budget',
    'privacy pass rate',
    'changed result count',
    'regression count',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _holdoutRules.length;
    _requireRules(failures, source, _holdoutRules);

    checked += _datasetMetrics.length;
    _requireTokens(
      failures,
      source,
      _datasetMetrics,
      idPrefix: 'missing_holdout_metric',
      message: 'Holdout fixture QA is missing a release metric.',
      fix:
          'Holdout validation must track accuracy, false-confidence, unknown/ambiguous rates, noise safety, performance, privacy, and changed-result regressions.',
      triage: QaFailureTriage.baseline,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'A hidden holdout set prevents overfitting and keeps release metrics honest across fixture rotations.',
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
          id: 'missing_holdout_rule:${_safeId(rule)}',
          message: 'Holdout fixture QA is missing a named governance rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add holdout governance so the parser cannot overfit to fixtures used during tuning.',
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
