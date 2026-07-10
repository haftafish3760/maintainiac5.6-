import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRegressionLockSuite extends QaSuite {
  const WorkSupplyParserRegressionLockSuite()
    : super('inventory.regression_lock_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_baseline_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_holdout_fixture_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_fixture_expectation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_fixture_corpus_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_generated_fixture_cell_qa.dart',
    'test/work_supply_parser_regression_lock_behavior_test.dart',
  };

  static const _regressionBuckets = {
    'known good receipt line',
    'known bad receipt line',
    'known bug stays fixed',
    'merchant regression',
    'locale regression',
    'trade regression',
    'pack tier regression',
    'dangerous word regression',
    'financial total regression',
    'source immutability regression',
    'duplicate receipt regression',
    'search/index regression',
  };

  static const _lockedExpectationFields = {
    'fixture id',
    'raw line',
    'merchant',
    'locale',
    'trade',
    'pack tier',
    'expected item id',
    'expected category',
    'expected review status',
    'expected confidence band',
    'expected ranked candidates',
    'expected warnings',
    'expected failure category',
  };

  static const _regressionRules = {
    'regression_case_has_stable_fixture_id',
    'regression_case_has_expected_top_candidate',
    'regression_case_has_expected_review_status',
    'regression_case_has_confidence_band_not_exact_float',
    'regression_case_has_ranked_candidate_expectation',
    'regression_case_records_why_it_exists',
    'regression_case_links_to_fixed_bug_or_requirement',
    'regression_case_fails_on_false_confident_match',
    'regression_case_fails_on_source_mutation',
    'regression_case_fails_on_missing_warning',
    'regression_case_can_be_run_surgically',
    'regression_case_is_not_deleted_without_replacement',
  };

  static const _mustLockMerchants = {
    'Home Depot',
    'Lowe',
    'Ace',
    'Ferguson',
    'Grainger',
    'Menards',
    'Walmart',
    'True Value',
    'unknown merchant',
  };

  static const _mustLockLocales = {
    'en-US',
    'es-US',
    'English',
    'Spanish',
    'metric',
    'imperial',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _regressionBuckets.length;
    _requireTokens(
      failures,
      source,
      _regressionBuckets,
      idPrefix: 'missing_regression_bucket',
      message: 'Regression QA is missing a required regression bucket.',
      fix:
          'Add locked regression coverage for known good/bad lines, bugs, merchants, locales, trades, tiers, dangerous words, totals, immutability, duplicates, and search.',
      triage: QaFailureTriage.baseline,
    );

    checked += _lockedExpectationFields.length;
    _requireTokens(
      failures,
      source,
      _lockedExpectationFields,
      idPrefix: 'missing_locked_expectation_field',
      message: 'Regression QA is missing a locked expectation field.',
      fix:
          'Regression fixtures must record raw input, context, expected item/category/review/confidence/ranking/warnings/failure category.',
      triage: QaFailureTriage.fixture,
    );

    checked += _regressionRules.length;
    _requireRules(failures, source, _regressionRules);

    checked += _mustLockMerchants.length;
    _requireTokens(
      failures,
      source,
      _mustLockMerchants,
      idPrefix: 'missing_merchant_regression_lock',
      message: 'Regression QA is missing a merchant-specific lock.',
      fix:
          'Major merchant receipt styles must have locked regression cases before parser/pack releases.',
      triage: QaFailureTriage.merchantRule,
    );

    checked += _mustLockLocales.length;
    _requireTokens(
      failures,
      source,
      _mustLockLocales,
      idPrefix: 'missing_locale_regression_lock',
      message: 'Regression QA is missing a locale/unit lock.',
      fix:
          'English, Spanish, metric, and imperial parser behavior needs locked regression fixtures.',
      triage: QaFailureTriage.locale,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Known parser behavior is locked by stable fixtures with expected candidates, review status, warnings, categories, and context.',
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
          id: 'missing_regression_rule:${_safeId(rule)}',
          message: 'Regression QA is missing a named lock rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit regression lock rules before relying on parser changes not to re-break known cases.',
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
