import 'dart:convert';
import 'dart:io';

import 'work_supply_parser_qa_background_queue.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_batch_wave.dart '
    '[--execute] [--wave-id residential-core-wave-001] '
    '[--previous-wave-id residential-core-wave-000] '
    '[--qa-layer merchant-abbreviation-v1] [--trades plumbing] '
    '[--tiers core] [--locales en-US,es-US] [--limit 500] '
    '[--fixture-run-limit 25] [--fixture-run-timeout-ms 1500000] '
    '[--fixture-run-stale-report-timeout-ms 300000]';

Future<void> main(List<String> args) async {
  final exit = await runWorkSupplyParserQaBatchWave(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runWorkSupplyParserQaBatchWave(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _WaveOptions.parse(args);
  if (options.limit <= 0 || options.fixtureRunLimit <= 0) {
    stderr.writeln(
      '--limit and --fixture-run-limit must be greater than zero.',
    );
    return 64;
  }

  final waveDir = Directory('${options.outputRoot}/${options.waveId}')
    ..createSync(recursive: true);
  final accumulated = _accumulatedWaveIds(options);
  final queueId = '${options.waveId}_${options.qaLayer}'.replaceAll(
    RegExp(r'[^a-zA-Z0-9_]+'),
    '_',
  );
  final queueArgs = [
    if (options.execute) '--execute',
    if (!options.resume) '--no-resume',
    if (options.continueOnFailure) '--continue-on-failure',
    '--trades',
    options.trades.join(','),
    '--scopes',
    options.scopes.join(','),
    '--tiers',
    options.tiers.join(','),
    '--locales',
    options.locales.join(','),
    '--limit',
    '${options.limit}',
    '--fixture-run-limit',
    '${options.fixtureRunLimit}',
    '--fixture-run-timeout-ms',
    '${options.fixtureRunTimeoutMs}',
    '--fixture-run-stale-report-timeout-ms',
    '${options.fixtureRunStaleReportTimeoutMs}',
    '--queue-id',
    queueId,
    '--output-root',
    '${waveDir.path}/queue',
  ];

  final plan = {
    'schemaVersion': 1,
    'tool': 'work_supply_parser_qa_batch_wave',
    'waveId': options.waveId,
    'previousWaveId': options.previousWaveId,
    'accumulatedWaveIds': accumulated,
    'qaLayer': options.qaLayer,
    'batchPolicy':
        'generate current wave coverage, run the current QA layer against '
        'the accumulated wave set, and do not rerun already-passed prior '
        'layers unless their rules or expected outputs changed',
    'dryRun': !options.execute,
    'resume': options.resume,
    'trades': options.trades,
    'marketScopes': options.scopes,
    'tiers': options.tiers,
    'localePackIds': options.locales,
    'limit': options.limit,
    'fixtureRunLimit': options.fixtureRunLimit,
    'fixtureRunTimeoutMs': options.fixtureRunTimeoutMs,
    'fixtureRunStaleReportTimeoutMs': options.fixtureRunStaleReportTimeoutMs,
    'queueArgs': queueArgs,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'ocrCameraExpensesTouched': false,
    'firebaseWritesAllowed': false,
  };
  final planPath = '${waveDir.path}/wave_plan.json';
  File(planPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(plan),
    flush: true,
  );

  final queueExit = await runWorkSupplyParserQaBackgroundQueue(
    queueArgs,
    stdout: stdout,
    stderr: stderr,
  );
  final summary = {
    ...plan,
    'queueExitCode': queueExit,
    'queueSummaryPath': '${waveDir.path}/queue/$queueId/summary.json',
    'wavePlanPath': planPath,
  };
  final summaryPath = '${waveDir.path}/wave_summary.json';
  File(summaryPath).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  File('${options.outputRoot}/latest_wave_summary.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(summary),
      flush: true,
    );

  stdout.writeln('QA_BATCH_WAVE_SUMMARY $summaryPath');
  return queueExit;
}

List<String> _accumulatedWaveIds(_WaveOptions options) {
  final ids = <String>[
    if (options.previousWaveId.isNotEmpty) options.previousWaveId,
    options.waveId,
  ];
  return ids.toSet().toList(growable: false);
}

class _WaveOptions {
  const _WaveOptions({
    required this.waveId,
    required this.previousWaveId,
    required this.qaLayer,
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.limit,
    required this.fixtureRunLimit,
    required this.fixtureRunTimeoutMs,
    required this.fixtureRunStaleReportTimeoutMs,
    required this.outputRoot,
    required this.execute,
    required this.resume,
    required this.continueOnFailure,
  });

  final String waveId;
  final String previousWaveId;
  final String qaLayer;
  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final int limit;
  final int fixtureRunLimit;
  final int fixtureRunTimeoutMs;
  final int fixtureRunStaleReportTimeoutMs;
  final String outputRoot;
  final bool execute;
  final bool resume;
  final bool continueOnFailure;

  static _WaveOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      if (!arg.startsWith('--')) continue;
      final key = arg.substring(2);
      if (i + 1 < args.length && !args[i + 1].startsWith('--')) {
        values[key] = args[++i];
      } else {
        flags.add(key);
      }
    }
    final now = DateTime.now().toUtc().toIso8601String();
    return _WaveOptions(
      waveId:
          values['wave-id'] ?? now.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_'),
      previousWaveId: values['previous-wave-id'] ?? '',
      qaLayer: values['qa-layer'] ?? 'generated-fixture-first-round',
      trades: _csv(values['trades'] ?? 'plumbing'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core'),
      locales: _csv(values['locales'] ?? 'en-US,es-US', lowerCase: false),
      limit: int.tryParse(values['limit'] ?? '') ?? 500,
      fixtureRunLimit: int.tryParse(values['fixture-run-limit'] ?? '') ?? 25,
      fixtureRunTimeoutMs:
          int.tryParse(values['fixture-run-timeout-ms'] ?? '') ?? 1500000,
      fixtureRunStaleReportTimeoutMs:
          int.tryParse(values['fixture-run-stale-report-timeout-ms'] ?? '') ??
          300000,
      outputRoot: values['output-root'] ?? 'build/parser_qa_batch_waves',
      execute: flags.contains('execute'),
      resume: !flags.contains('no-resume'),
      continueOnFailure: flags.contains('continue-on-failure'),
    );
  }
}

List<String> _csv(String value, {bool lowerCase = true}) {
  return value
      .split(',')
      .map((entry) => lowerCase ? entry.trim().toLowerCase() : entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}
