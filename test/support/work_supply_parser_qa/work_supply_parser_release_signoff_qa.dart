import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseSignoffSuite extends QaSuite {
  const WorkSupplyParserReleaseSignoffSuite()
    : super('inventory.release_signoff_manifest');

  static const _signoffPath = 'tool/work_supply_parser_qa_release_signoff.dart';
  static const _runnerPath = 'tool/work_supply_parser_qa_shard_runner.dart';
  static const _testPath =
      'test/work_supply_parser_qa_release_signoff_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _contracts = [
    _SignoffContract(
      name: 'signoff_script',
      path: _signoffPath,
      tokens: [
        'QA_RELEASE_SIGNOFF',
        'missing_expected_shard',
        'stale_shard',
        'dry_run_not_release_signoff',
        'profile_mismatch',
        'missing_transcript',
        'missing_completed_shard_count',
        'incomplete_shard_count',
        'summary_not_complete',
        'shard_not_complete',
      ],
    ),
    _SignoffContract(
      name: 'runner_summary_source',
      path: _runnerPath,
      tokens: [
        'QA_SHARD_SUMMARY',
        'summary.json',
        'shardCount',
        'failedShardCount',
        'transcriptPath',
      ],
    ),
    _SignoffContract(
      name: 'signoff_regression_tests',
      path: _testPath,
      tokens: [
        'dry_run_not_release_signoff',
        'profile_mismatch',
        'stale_shard',
        'missing_expected_shard',
        'shard_failed',
        'missing_transcript',
        'missing_completed_shard_count',
        'summary_not_complete',
        'incomplete_shard_count',
        'shard_not_complete',
      ],
    ),
    _SignoffContract(
      name: 'signoff_docs',
      path: _planPath,
      tokens: [
        'QA_RELEASE_SIGNOFF',
        'release sign-off',
        'missing, stale, failed, running, incomplete',
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
          id: 'missing_release_signoff_contract:${contract.name}',
          message: 'Release sign-off contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep release sign-off able to reject missing, stale, failed, wrong-profile, and dry-run shard evidence before parser pack release.',
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
        'requiresAllExpectedShards': true,
        'rejectsDryRunByDefault': true,
        'rejectsWrongProfile': true,
        'requiresTranscriptEvidence': true,
        'rejectsIncompleteShardEvidence': true,
        'rejectsRunningShardEvidence': true,
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
        id: 'missing_release_signoff_file:$path',
        message: 'Release sign-off scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if release sign-off files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _SignoffContract {
  const _SignoffContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
