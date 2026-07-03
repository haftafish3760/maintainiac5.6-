import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserValidationStrategySuite extends QaSuite {
  const WorkSupplyParserValidationStrategySuite()
    : super('inventory.validation_strategy_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _baselinePath = 'test/support/qa_harness/qa_baseline_diff.dart';
  static const _baselineTestPath = 'test/qa_baseline_diff_test.dart';
  static const _impactPath =
      'test/support/work_supply_parser_qa/work_supply_parser_impact_qa.dart';
  static const _metamorphicPath =
      'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart';
  static const _propertyPath =
      'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart';
  static const _determinismPath =
      'test/support/work_supply_parser_qa/work_supply_parser_determinism_qa.dart';
  static const _holdoutPath =
      'test/support/work_supply_parser_qa/work_supply_parser_holdout_fixture_qa.dart';

  static const _contracts = [
    _ValidationContract(
      name: 'holdout_strategy_docs',
      path: _planPath,
      tokens: [
        'Independent validation set',
        'holdout fixture set',
        'prevents overfitting',
      ],
    ),
    _ValidationContract(
      name: 'holdout_fixture_contract',
      path: _holdoutPath,
      tokens: [
        'inventory.holdout_fixture_contract',
        'holdoutOnly',
        'releaseOnlySemanticUse',
        'holdout_raw_line_also_in_golden',
      ],
    ),
    _ValidationContract(
      name: 'differential_baseline_docs',
      path: _planPath,
      tokens: ['Differential baseline tests', 'old/new ranked candidates'],
    ),
    _ValidationContract(
      name: 'baseline_regression_guards',
      path: _baselinePath,
      tokens: [
        'checked_decreased:',
        'failures_increased:',
        'failure_id_added:',
        'severity_increased:',
        'suite_added:',
      ],
    ),
    _ValidationContract(
      name: 'baseline_regression_unit_tests',
      path: _baselineTestPath,
      tokens: [
        'coverage drops and severity regressions',
        'New suites',
        'new failure ids even when count is unchanged',
      ],
    ),
    _ValidationContract(
      name: 'changed_item_selective_impact',
      path: _impactPath,
      tokens: [
        'protectedItems',
        'protectedFamilies',
        'fixturesByFamily',
        'oldNewRankedCandidateComparisons',
        'impact_ranked_candidate_changed',
      ],
    ),
    _ValidationContract(
      name: 'metamorphic_variants',
      path: _metamorphicPath,
      tokens: ['uppercase', 'extra_spacing', 'sku_prefix', 'spaced_fraction'],
    ),
    _ValidationContract(
      name: 'property_generation',
      path: _propertyPath,
      tokens: ['generationSeed', 'dangerous', 'merchant', 'locale'],
    ),
    _ValidationContract(
      name: 'deterministic_repeatability',
      path: _determinismPath,
      tokens: [
        'repeatCount',
        'nondeterministic_result',
        'Repeat parser assertions run in full/release profiles.',
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final present = <String>[];
    var checked = 0;

    for (final contract in _contracts) {
      checked += contract.tokens.length;
      final source = _read(contract.path, failures);
      final missing = [
        for (final token in contract.tokens)
          if (!source.contains(token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_validation_strategy:${contract.name}',
          message: 'Parser validation strategy contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Preserve holdout, differential, mutation, baseline, and impact validation before scaling parser data.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'contractCount': _contracts.length,
        'parserCalls': 0,
      },
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_validation_strategy_file:$path',
        message: 'Validation strategy scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if validation strategy files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _ValidationContract {
  const _ValidationContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
