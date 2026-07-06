import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_release_one_commands.dart '
    '[--output build/parser_qa_pipeline/release_one_commands.json] '
    '[--limit 500] [--fixture-run-limit 50] '
    '[--fixture-run-timeout-ms 900000] '
    '[--fixture-run-stale-report-timeout-ms 300000] '
    '[--min-generated-checked-per-cell 500]';

const _trades = ['plumbing', 'electrical', 'hvac'];
const _tiers = ['core', 'standard', 'professional', 'complete'];
const _priorityTiers = {'core', 'standard'};
const _locales = ['en-US', 'es-US'];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaReleaseOneCommands(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaReleaseOneCommands(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final limit = int.tryParse(_value(args, 'limit', '500')) ?? 500;
  final fixtureRunLimit =
      int.tryParse(_value(args, 'fixture-run-limit', '50')) ?? 50;
  final fixtureRunTimeoutMs =
      int.tryParse(_value(args, 'fixture-run-timeout-ms', '900000')) ?? 900000;
  final fixtureRunStaleReportTimeoutMs =
      int.tryParse(
        _value(args, 'fixture-run-stale-report-timeout-ms', '300000'),
      ) ??
      300000;
  final minGeneratedCheckedPerCell =
      int.tryParse(_value(args, 'min-generated-checked-per-cell', '500')) ??
      500;
  if (limit <= 0 ||
      fixtureRunLimit <= 0 ||
      fixtureRunTimeoutMs <= 0 ||
      fixtureRunStaleReportTimeoutMs <= 0 ||
      minGeneratedCheckedPerCell <= 0) {
    stderr.writeln(
      '--limit, --fixture-run-limit, and '
      '--fixture-run-timeout-ms, --fixture-run-stale-report-timeout-ms, and '
      '--min-generated-checked-per-cell must be positive.',
    );
    return 64;
  }
  final commands = [
    for (final trade in _trades)
      for (final tier in _tiers)
        for (final locale in _locales)
          {
            'cellId': '$trade.residential.$tier.$locale',
            'trade': trade,
            'marketScope': 'residential',
            'tier': tier,
            'localePackId': locale,
            'priorityCell': _priorityTiers.contains(tier),
            'command': [
              'dart',
              'run',
              'tool/work_supply_parser_qa_pipeline.dart',
              '--trade',
              trade,
              '--scope',
              'residential',
              '--tier',
              tier,
              '--locale',
              locale,
              '--limit',
              '$limit',
              '--fixture-run-limit',
              '$fixtureRunLimit',
              '--fixture-run-timeout-ms',
              '$fixtureRunTimeoutMs',
              '--fixture-run-stale-report-timeout-ms',
              '$fixtureRunStaleReportTimeoutMs',
              '--resume',
            ],
            'executeFlagRequired': true,
            'runFixturesFlagOptional': true,
            'liveServicesAllowed': false,
            'writesProductionCatalog': false,
            'firebaseWritesAllowed': false,
            'ocrCameraExpensesTouched': false,
          },
  ];
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_release_one_commands',
    'cellCount': commands.length,
    'priorityCellCount': commands
        .where((command) => command['priorityCell'] == true)
        .length,
    'limit': limit,
    'fixtureRunLimit': fixtureRunLimit,
    'fixtureRunTimeoutMs': fixtureRunTimeoutMs,
    'fixtureRunStaleReportTimeoutMs': fixtureRunStaleReportTimeoutMs,
    'minGeneratedCheckedPerCell': minGeneratedCheckedPerCell,
    'generatedFixtureStatusCommand': [
      'dart',
      'run',
      'tool/work_supply_parser_qa_generated_run_status.dart',
      '--report-root',
      'build/parser_qa_background_queue/release-one-priority-generated/cells',
      '--trades',
      _trades.join(','),
      '--scopes',
      'residential',
      '--tiers',
      'core,standard',
      '--locales',
      _locales.join(','),
      '--require-complete',
      '--min-checked-per-cell',
      '$minGeneratedCheckedPerCell',
      '--output',
      'build/parser_qa_pipeline/release_one_generated_run_status.json',
    ],
    'executionPolicy':
        'Commands are dry-run/safe by default; --execute must be added deliberately.',
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'commands': commands,
  };
  final json = const JsonEncoder.withIndent('  ').convert(summary);
  final output = _value(args, 'output', '');
  if (output.isNotEmpty) {
    final file = File(output)..parent.createSync(recursive: true);
    file.writeAsStringSync(json, flush: true);
  }
  stdout.writeln('QA_RELEASE_ONE_COMMANDS $json');
  return 0;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
