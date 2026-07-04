import 'dart:convert';
import 'dart:io';

const _entrypoint = 'test/work_supply_parser_qa_harness_test.dart';
const _reportRoot = 'build/parser_qa_reports/release_shards';
const _usage =
    'dart run tool/work_supply_parser_qa_shard_runner.dart --dry-run '
    '[--execute] [--profile release] [--only-shard release-contracts-001]';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }
  final options = _RunnerOptions.parse(args);
  final runId = options.runId.isEmpty
      ? DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '')
      : options.runId;
  final runDir = Directory('$_reportRoot/$runId')..createSync(recursive: true);
  final shards = options.onlyShard.isEmpty
      ? _defaultShards
      : _defaultShards.where((shard) => shard.id == options.onlyShard).toList();

  if (shards.isEmpty) {
    stderr.writeln('No QA shards matched --only-shard=${options.onlyShard}');
    exitCode = 64;
    return;
  }

  final results = <Map<String, Object?>>[];
  for (final shard in shards) {
    final command = _flutterCommand(
      options: options,
      shard: shard,
      runDir: runDir.path,
    );
    final startedAt = DateTime.now().toUtc();
    final transcriptPath = '${runDir.path}/${shard.id}_transcript.txt';

    if (options.dryRun) {
      final transcript = StringBuffer()
        ..writeln('DRY RUN')
        ..writeln('startedAt=${startedAt.toIso8601String()}')
        ..writeln('workingDirectory=${Directory.current.path}')
        ..writeln('command=${command.join(' ')}');
      File(transcriptPath).writeAsStringSync(transcript.toString());
      results.add(
        _resultJson(
          shard: shard,
          options: options,
          startedAt: startedAt,
          durationMs: 0,
          exitCode: 0,
          transcriptPath: transcriptPath,
          dryRun: true,
        ),
      );
      continue;
    }

    final process = await Process.run(
      command.first,
      command.skip(1).toList(),
      workingDirectory: Directory.current.path,
      runInShell: Platform.isWindows,
    );
    final transcript = StringBuffer()
      ..writeln('startedAt=${startedAt.toIso8601String()}')
      ..writeln('workingDirectory=${Directory.current.path}')
      ..writeln('command=${command.join(' ')}')
      ..writeln('exitCode=${process.exitCode}')
      ..writeln('--- stdout ---')
      ..writeln(process.stdout)
      ..writeln('--- stderr ---')
      ..writeln(process.stderr);
    File(transcriptPath).writeAsStringSync(transcript.toString());
    final durationMs = DateTime.now()
        .toUtc()
        .difference(startedAt)
        .inMilliseconds;
    results.add(
      _resultJson(
        shard: shard,
        options: options,
        startedAt: startedAt,
        durationMs: durationMs,
        exitCode: process.exitCode,
        transcriptPath: transcriptPath,
        dryRun: false,
      ),
    );
    if (process.exitCode != 0 && options.stopOnFailure) break;
  }

  final summary = {
    'runId': runId,
    'profile': options.profile,
    'strict': options.strict,
    'dryRun': options.dryRun,
    'timeoutBudgetMs': options.timeoutBudgetMs,
    'maxGeneratedCases': options.maxGeneratedCases,
    'resumeFrom': options.resumeFrom,
    'shardCount': results.length,
    'failedShardCount': results
        .where((result) => (result['exitCode'] as int? ?? 1) != 0)
        .length,
    'results': results,
  };
  final summaryPath = '${runDir.path}/summary.json';
  File(
    summaryPath,
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  File('$_reportRoot/latest_summary.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));

  stdout.writeln('QA_SHARD_SUMMARY $summaryPath');
  if (summary['failedShardCount'] != 0) exitCode = 1;
}

List<String> _flutterCommand({
  required _RunnerOptions options,
  required _QaShard shard,
  required String runDir,
}) {
  return [
    'flutter',
    'test',
    _entrypoint,
    '--dart-define=PARSER_QA_PROFILE=${options.profile}',
    '--dart-define=PARSER_QA_SUITES=${shard.suites.join(',')}',
    '--dart-define=PARSER_QA_MAX_GENERATED_CASES=${options.maxGeneratedCases}',
    '--dart-define=PARSER_QA_MAX_FAILURES_PER_SUITE=${options.maxFailuresPerSuite}',
    '--dart-define=PARSER_QA_SHARD_ID=${shard.id}',
    '--dart-define=PARSER_QA_TIMEOUT_BUDGET_MS=${options.timeoutBudgetMs}',
    '--dart-define=PARSER_QA_RESUME_FROM=${options.resumeFrom}',
    if (options.strict) '--dart-define=PARSER_QA_STRICT=true',
    '--reporter',
    'compact',
  ];
}

Map<String, Object?> _resultJson({
  required _QaShard shard,
  required _RunnerOptions options,
  required DateTime startedAt,
  required int durationMs,
  required int exitCode,
  required String transcriptPath,
  required bool dryRun,
}) {
  return {
    'shardId': shard.id,
    'description': shard.description,
    'suiteFilter': shard.suites,
    'generatedCaseLimit': options.maxGeneratedCases,
    'timeoutBudgetMs': options.timeoutBudgetMs,
    'resumeFrom': options.resumeFrom,
    'startedAt': startedAt.toIso8601String(),
    'durationMs': durationMs,
    'exitCode': exitCode,
    'dryRun': dryRun,
    'transcriptPath': transcriptPath,
  };
}

class _RunnerOptions {
  const _RunnerOptions({
    required this.profile,
    required this.strict,
    required this.dryRun,
    required this.stopOnFailure,
    required this.maxGeneratedCases,
    required this.maxFailuresPerSuite,
    required this.timeoutBudgetMs,
    required this.resumeFrom,
    required this.onlyShard,
    required this.runId,
  });

  final String profile;
  final bool strict;
  final bool dryRun;
  final bool stopOnFailure;
  final int maxGeneratedCases;
  final int maxFailuresPerSuite;
  final int timeoutBudgetMs;
  final String resumeFrom;
  final String onlyShard;
  final String runId;

  static _RunnerOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final withoutPrefix = arg.substring(2);
      final equalsIndex = withoutPrefix.indexOf('=');
      if (equalsIndex >= 0) {
        values[withoutPrefix.substring(0, equalsIndex)] = withoutPrefix
            .substring(equalsIndex + 1);
        continue;
      }
      final nextIsValue =
          index + 1 < args.length && !args[index + 1].startsWith('--');
      if (nextIsValue) {
        values[withoutPrefix] = args[++index];
      } else {
        flags.add(withoutPrefix);
      }
    }
    return _RunnerOptions(
      profile: values['profile'] ?? 'release',
      strict: flags.contains('strict'),
      dryRun: !flags.contains('execute'),
      stopOnFailure: !flags.contains('continue-on-failure'),
      maxGeneratedCases:
          int.tryParse(values['max-generated-cases'] ?? '') ?? 500,
      maxFailuresPerSuite:
          int.tryParse(values['max-failures-per-suite'] ?? '') ?? 80,
      timeoutBudgetMs:
          int.tryParse(values['timeout-budget-ms'] ?? '') ?? 600000,
      resumeFrom:
          values['resume-from'] ??
          'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
      onlyShard: values['only-shard'] ?? '',
      runId: values['run-id'] ?? '',
    );
  }
}

class _QaShard {
  const _QaShard({
    required this.id,
    required this.description,
    required this.suites,
  });

  final String id;
  final String description;
  final List<String> suites;
}

const _defaultShards = [
  _QaShard(
    id: 'release-contracts-001',
    description:
        'Release governance, shard metadata, and requirement coverage.',
    suites: [
      'inventory.release_shard_manifest',
      'inventory.release_orchestration_contract',
      'inventory.release_manifest',
      'inventory.requirement_coverage',
      'qa.threshold_gate',
    ],
  ),
  _QaShard(
    id: 'safety-governance-001',
    description:
        'Privacy, no-live-service, review safety, and platform guards.',
    suites: [
      'inventory.security_privacy',
      'inventory.boundary_guard',
      'inventory.no_live_services_contract',
      'inventory.review_safety_contract',
      'inventory.fake_user_chaos_contract',
      'inventory.fake_user_review_workflow',
      'inventory.result_contract',
      'inventory.legal_safety_contract',
      'qa.threshold_gate',
    ],
  ),
  _QaShard(
    id: 'semantic-fixtures-001',
    description:
        'Golden, holdout, generated, and ambiguity-heavy parser cases.',
    suites: [
      'inventory.golden_fixtures',
      'inventory.generated_cases',
      'inventory.holdout_fixture_contract',
      'inventory.metamorphic_variants',
      'inventory.property_cases',
      'inventory.trade_context',
      'inventory.merchant_rules',
      'inventory.noise_lines',
      'inventory.confidence_calibration',
      'qa.threshold_gate',
    ],
  ),
  _QaShard(
    id: 'catalog-contracts-001',
    description: 'Catalog schema, alias, pack, and scale contracts.',
    suites: [
      'inventory.catalog_schema',
      'inventory.catalog_coverage',
      'inventory.alias_conflicts',
      'inventory.pack_lifecycle',
      'inventory.pack_health_score',
      'inventory.scalability',
      'qa.threshold_gate',
    ],
  ),
];
