import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'release signoff accepts complete dry-run only when explicitly allowed',
    () async {
      final workspace = await Directory.systemTemp.createTemp(
        'parser_signoff_pass_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final summary = _writeSummary(workspace, profile: 'smoke', dryRun: true);

      final result = await _runSignoff([
        '--summary',
        summary.path,
        '--expected-profile',
        'smoke',
        '--allow-dry-run',
        '--max-age-hours',
        '168',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(
        result.stdout.toString(),
        contains('QA_RELEASE_SIGNOFF status=pass'),
      );
    },
  );

  test('release signoff rejects unsafe or incomplete shard evidence', () async {
    final cases = <_SignoffCase>[
      _SignoffCase(
        name: 'dry-run evidence without explicit approval',
        expectedFailure: 'dry_run_not_release_signoff',
        mutateSummary: (summary) {},
      ),
      _SignoffCase(
        name: 'wrong profile',
        expectedFailure: 'profile_mismatch',
        allowDryRun: true,
        expectedProfile: 'release',
        mutateSummary: (summary) {},
      ),
      _SignoffCase(
        name: 'stale shard',
        expectedFailure: 'stale_shard:release-contracts-001',
        allowDryRun: true,
        mutateSummary: (summary) {
          final firstResult = (summary['results'] as List).first as Map;
          firstResult['startedAt'] = DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 30))
              .toIso8601String();
        },
      ),
      _SignoffCase(
        name: 'missing expected shard',
        expectedFailure: 'missing_expected_shard:catalog-contracts-001',
        allowDryRun: true,
        mutateSummary: (summary) {
          final results = summary['results'] as List;
          results.removeWhere(
            (result) =>
                result is Map && result['shardId'] == 'catalog-contracts-001',
          );
        },
      ),
      _SignoffCase(
        name: 'failed shard',
        expectedFailure: 'shard_failed:semantic-fixtures-001',
        allowDryRun: true,
        mutateSummary: (summary) {
          final result =
              ((summary['results'] as List).firstWhere(
                    (result) =>
                        result is Map &&
                        result['shardId'] == 'semantic-fixtures-001',
                  )
                  as Map);
          result['exitCode'] = 1;
          summary['failedShardCount'] = 1;
        },
      ),
      _SignoffCase(
        name: 'summary still running',
        expectedFailure: 'summary_not_complete:running',
        allowDryRun: true,
        mutateSummary: (summary) {
          summary['state'] = 'running';
        },
      ),
      _SignoffCase(
        name: 'incomplete shard count',
        expectedFailure: 'incomplete_shard_count:3/4',
        allowDryRun: true,
        mutateSummary: (summary) {
          summary['completedShardCount'] = 3;
        },
      ),
      _SignoffCase(
        name: 'running shard',
        expectedFailure: 'shard_not_complete:catalog-contracts-001:running',
        allowDryRun: true,
        mutateSummary: (summary) {
          final result =
              ((summary['results'] as List).firstWhere(
                    (result) =>
                        result is Map &&
                        result['shardId'] == 'catalog-contracts-001',
                  )
                  as Map);
          result['state'] = 'running';
        },
      ),
      _SignoffCase(
        name: 'missing transcript',
        expectedFailure: 'missing_transcript:safety-governance-001',
        allowDryRun: true,
        mutateSummary: (summary) {
          final result =
              ((summary['results'] as List).firstWhere(
                    (result) =>
                        result is Map &&
                        result['shardId'] == 'safety-governance-001',
                  )
                  as Map);
          result['transcriptPath'] = 'missing/transcript.txt';
        },
      ),
    ];

    for (final signoffCase in cases) {
      final workspace = await Directory.systemTemp.createTemp(
        'parser_signoff_fail_',
      );
      addTearDown(() => workspace.delete(recursive: true));
      final summary = _summaryMap(workspace, profile: 'smoke', dryRun: true);
      signoffCase.mutateSummary(summary);
      final summaryFile = File(
        '${workspace.path}/summary.json',
      )..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));

      final result = await _runSignoff([
        '--summary',
        summaryFile.path,
        '--expected-profile',
        signoffCase.expectedProfile,
        if (signoffCase.allowDryRun) '--allow-dry-run',
        '--max-age-hours',
        '168',
      ]);

      expect(
        result.exitCode,
        isNot(0),
        reason: '${signoffCase.name} unexpectedly passed.',
      );
      expect(
        result.stdout.toString(),
        contains(signoffCase.expectedFailure),
        reason: signoffCase.name,
      );
    }
  });
}

Future<ProcessResult> _runSignoff(List<String> args) {
  return Process.run('dart', [
    'run',
    'tool/work_supply_parser_qa_release_signoff.dart',
    ...args,
  ], runInShell: Platform.isWindows);
}

File _writeSummary(
  Directory workspace, {
  required String profile,
  required bool dryRun,
}) {
  return File('${workspace.path}/summary.json')..writeAsStringSync(
    const JsonEncoder.withIndent(
      '  ',
    ).convert(_summaryMap(workspace, profile: profile, dryRun: dryRun)),
  );
}

Map<String, Object?> _summaryMap(
  Directory workspace, {
  required String profile,
  required bool dryRun,
}) {
  final now = DateTime.now().toUtc().toIso8601String();
  final shards = [
    'release-contracts-001',
    'safety-governance-001',
    'semantic-fixtures-001',
    'catalog-contracts-001',
  ];
  return {
    'runId': 'test-run',
    'profile': profile,
    'strict': profile == 'release',
    'dryRun': dryRun,
    'timeoutBudgetMs': 600000,
    'maxGeneratedCases': 500,
    'resumeFrom':
        'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
    'shardCount': shards.length,
    'completedShardCount': shards.length,
    'failedShardCount': 0,
    'state': 'complete',
    'results': [
      for (final shard in shards)
        _shardResult(workspace: workspace, shardId: shard, startedAt: now),
    ],
  };
}

Map<String, Object?> _shardResult({
  required Directory workspace,
  required String shardId,
  required String startedAt,
}) {
  final transcript = File('${workspace.path}/${shardId}_transcript.txt')
    ..writeAsStringSync('transcript for $shardId');
  return {
    'shardId': shardId,
    'description': 'test shard $shardId',
    'suiteFilter': ['qa.threshold_gate'],
    'generatedCaseLimit': 500,
    'timeoutBudgetMs': 600000,
    'resumeFrom':
        'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
    'startedAt': startedAt,
    'durationMs': 1,
    'exitCode': 0,
    'state': 'complete',
    'dryRun': true,
    'transcriptPath': transcript.path,
  };
}

class _SignoffCase {
  const _SignoffCase({
    required this.name,
    required this.expectedFailure,
    required this.mutateSummary,
    this.expectedProfile = 'smoke',
    this.allowDryRun = false,
  });

  final String name;
  final String expectedFailure;
  final String expectedProfile;
  final bool allowDryRun;
  final void Function(Map<String, Object?> summary) mutateSummary;
}
