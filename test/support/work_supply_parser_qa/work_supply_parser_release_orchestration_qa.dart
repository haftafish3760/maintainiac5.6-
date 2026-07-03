import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOrchestrationSuite extends QaSuite {
  const WorkSupplyParserReleaseOrchestrationSuite()
    : super('inventory.release_orchestration_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _presetPath = 'test/support/qa_harness/qa_suite_presets.dart';
  static const _thresholdPath =
      'test/support/qa_harness/qa_threshold_gate.dart';
  static const _shardPath =
      'test/support/work_supply_parser_qa/work_supply_parser_release_shard_qa.dart';
  static const _runnerPath = 'tool/work_supply_parser_qa_shard_runner.dart';

  static const _contracts = [
    _OrchestrationContract(
      name: 'bounded_full_generated_cases',
      path: _entryPath,
      tokens: ['PARSER_QA_MAX_GENERATED_CASES', 'defaultValue: 100'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'suite_filter_sharding',
      path: _entryPath,
      tokens: ['PARSER_QA_SUITES', 'suiteFilter'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'profile_threshold_gate',
      path: _thresholdPath,
      tokens: ['maxDurationMs', 'checksPerSecond'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'named_preset_shards',
      path: _presetPath,
      tokens: ["case 'quick'", "case 'fixtures'", "case 'catalog'"],
      category: QaFailureTriage.governance,
    ),
    _OrchestrationContract(
      name: 'full_profile_timeout_guard_docs',
      path: _planPath,
      tokens: ['full-profile timeout guard', 'external command cap'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'release_shard_strategy_docs',
      path: _planPath,
      tokens: ['release shard strategy', 'run one shard at a time'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'artifact_checkpoint_docs',
      path: _planPath,
      tokens: ['latest_work_supply_inventory_parser.json', 'resume evidence'],
      category: QaFailureTriage.governance,
    ),
    _OrchestrationContract(
      name: 'release_shard_manifest_suite',
      path: _shardPath,
      tokens: [
        'inventory.release_shard_manifest',
        'PARSER_QA_SHARD_ID',
        'PARSER_QA_TIMEOUT_BUDGET_MS',
        'PARSER_QA_RESUME_FROM',
      ],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'release_shard_runner_script',
      path: _runnerPath,
      tokens: ['QA_SHARD_SUMMARY', 'summary.json', 'transcriptPath'],
      category: QaFailureTriage.performance,
    ),
    _OrchestrationContract(
      name: 'mac_mini_handoff_docs',
      path: _planPath,
      tokens: ['Mac Mini', 'Windows smoke'],
      category: QaFailureTriage.performance,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in {
      _planPath,
      _entryPath,
      _presetPath,
      _thresholdPath,
      _shardPath,
      _runnerPath,
    }) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_release_orchestration_file:$path',
            message: 'Release orchestration scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the release orchestration suite if harness files move.',
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
          id: 'missing_release_orchestration_contract:${contract.name}',
          message: 'Full/release run orchestration contract is missing.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Document or wire shardable, timeout-safe full/release parser QA before broad catalog release gates.',
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
        'orchestrationProfiles': const ['full', 'release'],
      },
    );
  }
}

class _OrchestrationContract {
  const _OrchestrationContract({
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
