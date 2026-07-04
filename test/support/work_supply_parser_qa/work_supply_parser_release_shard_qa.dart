import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseShardSuite extends QaSuite {
  const WorkSupplyParserReleaseShardSuite()
    : super('inventory.release_shard_manifest');

  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _harnessPath = 'test/support/qa_harness/qa_harness.dart';
  static const _thresholdPath =
      'test/support/qa_harness/qa_threshold_gate.dart';
  static const _runnerPath = 'tool/work_supply_parser_qa_shard_runner.dart';
  static const _runnerTestPath =
      'test/work_supply_parser_qa_shard_runner_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _contracts = [
    _ShardContract(
      name: 'entrypoint_shard_knobs',
      path: _entryPath,
      tokens: [
        'PARSER_QA_SHARD_ID',
        'PARSER_QA_TIMEOUT_BUDGET_MS',
        'PARSER_QA_RESUME_FROM',
      ],
    ),
    _ShardContract(
      name: 'report_config_shard_metadata',
      path: _harnessPath,
      tokens: [
        'shardId',
        'timeoutBudgetMs',
        'resumeFrom',
        "'shardId': shardId",
        "'timeoutBudgetMs': timeoutBudgetMs",
        "'resumeFrom': resumeFrom",
      ],
    ),
    _ShardContract(
      name: 'slow_suite_profiler',
      path: _harnessPath,
      tokens: [
        'slowestSuites',
        'durationMs',
        'checksPerSecond',
        'QA_SLOW_SUITE',
      ],
    ),
    _ShardContract(
      name: 'threshold_runtime_budget',
      path: _thresholdPath,
      tokens: [
        'maxDurationMs',
        'max_suite_duration_ms',
        'min_suite_checks_per_second',
      ],
    ),
    _ShardContract(
      name: 'artifact_resume_evidence',
      path: _entryPath,
      tokens: ['QA_ARTIFACT', 'latestJson', 'latestSummary'],
    ),
    _ShardContract(
      name: 'shard_runner_script',
      path: _runnerPath,
      tokens: [
        'work_supply_parser_qa_shard_runner',
        'QA_SHARD_SUMMARY',
        'transcriptPath',
        'summary.json',
        'completedShardCount',
        "'state'",
        '--execute',
        'release-contracts-001',
      ],
    ),
    _ShardContract(
      name: 'shard_runner_regression_tests',
      path: _runnerTestPath,
      tokens: [
        'No QA shards matched --only-shard=not-a-real-shard',
        'release-contracts-001',
        'safety-governance-001',
        'semantic-fixtures-001',
        'catalog-contracts-001',
        'QA_SHARD_SUMMARY',
      ],
    ),
    _ShardContract(
      name: 'release_shard_docs',
      path: _planPath,
      tokens: [
        'PARSER_QA_SHARD_ID',
        'PARSER_QA_TIMEOUT_BUDGET_MS',
        'PARSER_QA_RESUME_FROM',
        'resume evidence',
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
          if (!_containsContractToken(source, token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_shard_contract:${contract.name}',
          message: 'Release shard/profiler contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep full/release shards resumable, timeout-budgeted, artifact-backed, and performance-profiled before release gating parser packs.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
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
        'releaseShardMetadataRequired': true,
        'recordsShardId': true,
        'recordsSuiteFilter': true,
        'recordsGeneratedCaseLimit': true,
        'recordsTimeoutBudget': true,
        'recordsResumeEvidence': true,
        'profilerFields': const [
          'slowestSuites',
          'durationMs',
          'checksPerSecond',
        ],
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
        id: 'missing_release_shard_file:$path',
        message: 'Release shard contract scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if release shard files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _ShardContract {
  const _ShardContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
