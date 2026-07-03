import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBaselineContractSuite extends QaSuite {
  const WorkSupplyParserBaselineContractSuite()
    : super('inventory.baseline_contract');

  static const _baselinePath = 'test/support/qa_harness/qa_baseline_diff.dart';
  static const _baselineTestPath = 'test/qa_baseline_diff_test.dart';
  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _contracts = [
    _BaselineContract(
      name: 'baseline_env_wired',
      path: _entryPath,
      tokens: ['PARSER_QA_BASELINE', 'appendQaBaselineDiff'],
      category: QaFailureTriage.governance,
    ),
    _BaselineContract(
      name: 'missing_baseline_guard',
      path: _baselinePath,
      tokens: ['baseline_missing', 'Requested baseline report does not exist'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'suite_removed_guard',
      path: _baselinePath,
      tokens: ['suite_removed:', 'A suite from the baseline is missing'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'coverage_drop_guard',
      path: _baselinePath,
      tokens: ['checked_decreased:', 'checked fewer cases than the baseline'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'failure_increase_guard',
      path: _baselinePath,
      tokens: [
        'failures_increased:',
        'actual failures increased over baseline',
      ],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'failure_id_added_guard',
      path: _baselinePath,
      tokens: [
        'failure_id_added:',
        'new failure id that was not present in the baseline',
      ],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'severity_increase_guard',
      path: _baselinePath,
      tokens: ['severity_increased:', 'severity count increased over baseline'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'runtime_metric_regression_guard',
      path: _baselinePath,
      tokens: ['metric_regressed:', 'coldStartMs', 'warmCacheMs'],
      category: QaFailureTriage.performance,
    ),
    _BaselineContract(
      name: 'suite_added_visibility',
      path: _baselinePath,
      tokens: ['suite_added:', 'A new suite is not present in the baseline'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'baseline_missing_test',
      path: _baselineTestPath,
      tokens: ['baseline diff warns when requested baseline is missing'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'baseline_regression_test',
      path: _baselineTestPath,
      tokens: ['coverage drops and severity regressions'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'failure_id_added_test',
      path: _baselineTestPath,
      tokens: ['new failure ids even when count is unchanged'],
      category: QaFailureTriage.baseline,
    ),
    _BaselineContract(
      name: 'runtime_metric_regression_test',
      path: _baselineTestPath,
      tokens: ['runtime metric regressions', 'coldStartMs', 'warmCacheMs'],
      category: QaFailureTriage.performance,
    ),
    _BaselineContract(
      name: 'baseline_docs',
      path: _planPath,
      tokens: [
        'PARSER_QA_BASELINE',
        'coverage drops',
        'severity counts regress',
      ],
      category: QaFailureTriage.governance,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in {
      _baselinePath,
      _baselineTestPath,
      _entryPath,
      _planPath,
    }) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_baseline_contract_file:$path',
            message: 'Baseline contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update baseline contract suite if baseline harness files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sources[path] = file.readAsStringSync();
    }

    final present = <String>[];
    for (final contract in _contracts) {
      final source = sources[contract.path] ?? '';
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_baseline_contract:${contract.name}',
          message: 'Baseline regression contract is missing.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep baseline comparison coverage explicit before approving parser changes.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: sources.length + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'baselineSuite': 'qa.baseline_diff',
      },
    );
  }
}

class _BaselineContract {
  const _BaselineContract({
    required this.name,
    required this.path,
    required this.tokens,
    required this.category,
  });

  final String name;
  final String path;
  final List<String> tokens;
  final String category;

  bool isPresentIn(String source) {
    return tokens.every(source.contains);
  }
}
