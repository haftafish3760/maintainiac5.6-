import 'dart:convert';
import 'dart:io';

import 'work_supply_parser_qa_pipeline.dart';
import 'work_supply_parser_qa_pipeline_artifacts.dart';
import 'work_supply_parser_qa_pipeline_status.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_matrix_pipeline.dart '
    '[--trades plumbing,electrical,hvac] [--scopes residential] '
    '[--tiers core] [--locales en-US,es-US] [--limit 500] '
    '[--fixture-run-limit 50] [--fixture-run-timeout-ms 900000] '
    '[--output-root build/parser_qa_pipeline] [--execute] [--resume] '
    '[--run-fixtures] [--status-gate] [--first-round]';

Future<void> main(List<String> args) async {
  final exit = await runWorkSupplyParserQaMatrixPipeline(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runWorkSupplyParserQaMatrixPipeline(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _MatrixOptions.parse(args);
  if (options.limit <= 0) {
    stderr.writeln('--limit must be greater than zero.');
    return 64;
  }
  final results = <Map<String, Object?>>[];
  var failed = false;
  for (final trade in options.trades) {
    for (final scope in options.scopes) {
      for (final tier in options.tiers) {
        final pipelineOutputRoot = options.locales.length == 1
            ? _cellOutputRoot(
                options.outputRoot,
                trade,
                scope,
                tier,
                options.locales.single,
              )
            : options.outputRoot;
        final pipelineArgs = [
          if (options.execute) '--execute',
          if (options.resume) '--resume',
          if (options.runFixtures) '--run-fixtures',
          '--trade',
          trade,
          '--scope',
          scope,
          '--tier',
          tier,
          '--locales',
          options.locales.join(','),
          '--limit',
          '${options.limit}',
          '--fixture-run-limit',
          '${options.fixtureRunLimit}',
          '--fixture-run-timeout-ms',
          '${options.fixtureRunTimeoutMs}',
          '--output-root',
          pipelineOutputRoot,
        ];
        final exit = await runWorkSupplyParserQaPipeline(
          pipelineArgs,
          stdout: stdout,
          stderr: stderr,
        );
        results.add({
          'trade': trade,
          'marketScope': scope,
          'tier': tier,
          'localePackIds': options.locales,
          'outputRoot': pipelineOutputRoot,
          'exitCode': exit,
        });
        if (exit != 0) failed = true;
      }
    }
  }
  int? statusGateExitCode;
  if (options.statusGate) {
    statusGateExitCode = runWorkSupplyParserQaPipelineStatus(
      [
        '--output-root',
        options.outputRoot,
        '--report-dir',
        '${options.outputRoot}/status_reports',
        '--trades',
        options.trades.join(','),
        '--scopes',
        options.scopes.join(','),
        '--tiers',
        options.tiers.join(','),
        '--locales',
        options.locales.join(','),
        '--require-complete',
      ],
      stdout: stdout,
      stderr: stderr,
    );
    if (statusGateExitCode != 0) failed = true;
  }
  final summary = {
    'schemaVersion': 1,
    'pipeline': 'work_supply_parser_qa_matrix_pipeline',
    'trades': options.trades,
    'marketScopes': options.scopes,
    'tiers': options.tiers,
    'localePackIds': options.locales,
    'limit': options.limit,
    'fixtureRunLimit': options.fixtureRunLimit,
    'fixtureRunTimeoutMs': options.fixtureRunTimeoutMs,
    'dryRun': !options.execute,
    'resume': options.resume,
    'firstRound': options.firstRound,
    'runFixtures': options.runFixtures,
    'statusGate': options.statusGate,
    'statusGateExitCode': ?statusGateExitCode,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'results': results,
  };
  final artifact = writePipelineSummary(
    outputDirectory: '${options.outputRoot}/matrix_reports',
    summary: summary,
  );
  stdout.writeln(
    'QA_ECONOMICAL_MATRIX_PIPELINE '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_ECONOMICAL_MATRIX_PIPELINE_ARTIFACT '
    'json=${artifact.timestampedJsonPath} latestJson=${artifact.latestJsonPath}',
  );
  return failed ? 1 : 0;
}

class _MatrixOptions {
  const _MatrixOptions({
    required this.trades,
    required this.scopes,
    required this.tiers,
    required this.locales,
    required this.limit,
    required this.fixtureRunLimit,
    required this.fixtureRunTimeoutMs,
    required this.outputRoot,
    required this.execute,
    required this.resume,
    required this.firstRound,
    required this.runFixtures,
    required this.statusGate,
  });

  final List<String> trades;
  final List<String> scopes;
  final List<String> tiers;
  final List<String> locales;
  final int limit;
  final int fixtureRunLimit;
  final int fixtureRunTimeoutMs;
  final String outputRoot;
  final bool execute;
  final bool resume;
  final bool firstRound;
  final bool runFixtures;
  final bool statusGate;

  static _MatrixOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final key = arg.substring(2);
      if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[key] = args[++index];
      } else {
        flags.add(key);
      }
    }
    final firstRound = flags.contains('first-round');
    final limit = int.tryParse(values['limit'] ?? '') ?? 500;
    return _MatrixOptions(
      trades: _csv(values['trades'] ?? 'plumbing,electrical,hvac'),
      scopes: _csv(values['scopes'] ?? 'residential'),
      tiers: _csv(values['tiers'] ?? 'core'),
      locales: _csv(values['locales'] ?? 'en-US,es-US', lowerCase: false),
      limit: limit,
      fixtureRunLimit:
          int.tryParse(values['fixture-run-limit'] ?? '') ??
          (firstRound ? 25 : limit),
      fixtureRunTimeoutMs:
          int.tryParse(values['fixture-run-timeout-ms'] ?? '') ?? 900000,
      outputRoot: values['output-root'] ?? 'build/parser_qa_pipeline',
      execute: flags.contains('execute'),
      resume: flags.contains('resume'),
      firstRound: firstRound,
      runFixtures: flags.contains('run-fixtures') || firstRound,
      statusGate: flags.contains('status-gate') || firstRound,
    );
  }

  static List<String> _csv(String value, {bool lowerCase = true}) {
    return value
        .split(',')
        .map((entry) => lowerCase ? entry.trim().toLowerCase() : entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }
}

String _cellOutputRoot(
  String outputRoot,
  String trade,
  String scope,
  String tier,
  String locale,
) {
  return '$outputRoot/$trade/$scope/$tier/$locale';
}
