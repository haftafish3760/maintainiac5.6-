import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shard runner dry-run writes summary and transcript metadata', () async {
    final runId = 'runner-test-${DateTime.now().microsecondsSinceEpoch}';
    final result = await _runShardRunner([
      '--dry-run',
      '--profile',
      'smoke',
      '--run-id',
      runId,
      '--only-shard',
      'release-contracts-001',
      '--max-generated-cases',
      '25',
      '--timeout-budget-ms',
      '120000',
      '--resume-from',
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
    ]);

    expect(result.exitCode, 0, reason: result.stderr.toString());
    expect(result.stdout.toString(), contains('QA_SHARD_SUMMARY'));

    final summaryPath =
        'build/parser_qa_reports/release_shards/$runId/summary.json';
    final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
    expect(summary['profile'], 'smoke');
    expect(summary['dryRun'], true);
    expect(summary['unsafe'], false);
    expect(summary['liveServicesAllowed'], false);
    expect(summary['writesProductionCatalog'], false);
    expect(summary['firebaseWritesAllowed'], false);
    expect(summary['ocrCameraExpensesTouched'], false);
    expect(summary['shardCount'], 1);
    expect(summary['completedShardCount'], 1);
    expect(summary['failedShardCount'], 0);
    expect(summary['state'], 'complete');
    final shard = (summary['results'] as List).single as Map;
    expect(shard['shardId'], 'release-contracts-001');
    expect(shard['state'], 'complete');
    expect(shard['strict'], false);
    expect(shard['unsafe'], false);
    expect(shard['liveServicesAllowed'], false);
    expect(shard['writesProductionCatalog'], false);
    expect(shard['firebaseWritesAllowed'], false);
    expect(shard['ocrCameraExpensesTouched'], false);
    expect(shard['generatedCaseLimit'], 25);
    expect(shard['timeoutBudgetMs'], 120000);
    expect(
      shard['resumeFrom'],
      contains('latest_work_supply_inventory_parser'),
    );
    expect(shard['suiteFilter'], contains('inventory.release_shard_manifest'));
    final transcript = File(shard['transcriptPath'].toString());
    expect(transcript.existsSync(), true);
    final transcriptText = transcript.readAsStringSync();
    expect(transcriptText, contains('DRY RUN'));
    expect(
      transcriptText,
      contains('--dart-define=PARSER_QA_SHARD_ID=release-contracts-001'),
    );
    expect(
      transcriptText,
      contains('--dart-define=PARSER_QA_MAX_GENERATED_CASES=25'),
    );
  });

  test(
    'shard runner dry-run includes all expected shards by default',
    () async {
      final runId = 'runner-all-test-${DateTime.now().microsecondsSinceEpoch}';
      final result = await _runShardRunner([
        '--dry-run',
        '--profile',
        'smoke',
        '--run-id',
        runId,
        '--max-generated-cases',
        '10',
      ]);

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final summaryPath =
          'build/parser_qa_reports/release_shards/$runId/summary.json';
      final summary = jsonDecode(File(summaryPath).readAsStringSync()) as Map;
      final shardIds = [
        for (final result in summary['results'] as List)
          (result as Map)['shardId'].toString(),
      ];
      expect(
        shardIds,
        containsAll([
          'release-contracts-001',
          'safety-governance-001',
          'semantic-fixtures-001',
          'catalog-contracts-001',
        ]),
      );
      expect(summary['shardCount'], 4);
      expect(summary['completedShardCount'], 4);
      expect(summary['state'], 'complete');
    },
  );

  test('shard runner rejects unknown shard id', () async {
    final result = await _runShardRunner([
      '--dry-run',
      '--only-shard',
      'not-a-real-shard',
    ]);

    expect(result.exitCode, 64);
    expect(
      result.stderr.toString(),
      contains('No QA shards matched --only-shard=not-a-real-shard'),
    );
  });
}

Future<ProcessResult> _runShardRunner(List<String> args) {
  return Process.run('dart', [
    'run',
    'tool/work_supply_parser_qa_shard_runner.dart',
    ...args,
  ], runInShell: Platform.isWindows);
}
