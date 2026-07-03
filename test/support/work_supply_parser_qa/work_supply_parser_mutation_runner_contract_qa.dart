import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMutationRunnerContractSuite extends QaSuite {
  const WorkSupplyParserMutationRunnerContractSuite()
    : super('inventory.mutation_runner_contract');

  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _harnessPath = 'test/support/qa_harness/qa_harness.dart';
  static const _executionPath =
      'test/support/work_supply_parser_qa/work_supply_parser_execution_command_qa.dart';
  static const _scenarioPath =
      'test/support/work_supply_parser_qa/work_supply_parser_mutation_scenario_qa.dart';
  static const _planSuitePath =
      'test/support/work_supply_parser_qa/work_supply_parser_mutation_plan_qa.dart';
  static const _faultProbePath =
      'test/support/work_supply_parser_qa/work_supply_parser_mutation_fault_probe_qa.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _contracts = [
    _RunnerContract(
      name: 'entrypoint_env_knobs',
      path: _entryPath,
      tokens: [
        'PARSER_QA_MUTATION_MODE',
        'PARSER_QA_MUTATION_SCENARIOS',
        'PARSER_QA_MUTATION_DRY_RUN',
        'defaultValue: true',
      ],
    ),
    _RunnerContract(
      name: 'report_config_preserves_knobs',
      path: _harnessPath,
      tokens: [
        'mutationMode',
        'mutationScenarios',
        'mutationDryRun',
        "'mutationMode': mutationMode",
        "'mutationScenarios': mutationScenarios",
        "'mutationDryRun': mutationDryRun",
      ],
    ),
    _RunnerContract(
      name: 'execution_command_docs',
      path: _executionPath,
      tokens: [
        'mutation_dry_run',
        'mutation_scenario_filter',
        'PARSER_QA_MUTATION_MODE=dry-run',
        'PARSER_QA_MUTATION_DRY_RUN=true',
      ],
    ),
    _RunnerContract(
      name: 'scenario_matrix_source',
      path: _scenarioPath,
      tokens: [
        '_requiredMutationTypes',
        '_MutationScenario',
        'caughtBySuite',
        'protectedFailure',
        'parserCalls',
      ],
    ),
    _RunnerContract(
      name: 'dry_run_plan_source',
      path: _planSuitePath,
      tokens: [
        'inventory.mutation_dry_run_plan',
        'localOnlyMutationArtifacts',
        'firebaseWritesAllowed',
        'mutation_requires_explicit_scenario_selection',
        'build/parser_qa_reports/mutations',
      ],
    ),
    _RunnerContract(
      name: 'fault_probe_source',
      path: _faultProbePath,
      tokens: [
        'inventory.mutation_fault_probe',
        'toInjectedFailure',
        'blockingProbeCount',
        'catalogMutationAllowed',
        'firebaseWritesAllowed',
      ],
    ),
    _RunnerContract(
      name: 'local_safety_docs',
      path: _planPath,
      tokens: [
        'Mutation runner contract',
        'PARSER_QA_MUTATION_MODE',
        'PARSER_QA_MUTATION_SCENARIOS',
        'PARSER_QA_MUTATION_DRY_RUN',
        'dry-run by default',
        'no Firebase writes',
        'local-only mutation artifacts',
        'inventory.mutation_dry_run_plan',
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
          id: 'missing_mutation_runner_contract:${contract.name}',
          message: 'Mutation runner contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep mutation execution local, dry-run safe, scenario-filterable, and report-visible before adding real fault injection.',
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
        id: 'missing_mutation_runner_file:$path',
        message: 'Mutation runner contract scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if mutation runner files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _RunnerContract {
  const _RunnerContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
