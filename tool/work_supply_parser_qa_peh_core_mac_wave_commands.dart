import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_peh_core_mac_wave_commands.dart '
    '[--output build/parser_qa_pipeline/peh_core_mac_wave_commands.json] '
    '[--max-cases 25] [--chunk-size 25] [--min-pass-rate 0.90] '
    '[--timeout-ms 900000] [--stale-report-timeout-ms 240000]';

const _locales = ['en-US', 'es-US'];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPehCoreMacWaveCommands(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPehCoreMacWaveCommands(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }

  final maxCases = int.tryParse(_value(args, 'max-cases', '25')) ?? 25;
  final chunkSize = int.tryParse(_value(args, 'chunk-size', '25')) ?? 25;
  final minPassRate =
      double.tryParse(_value(args, 'min-pass-rate', '0.90')) ?? 0.90;
  final timeoutMs = int.tryParse(_value(args, 'timeout-ms', '900000')) ?? 900000;
  final staleReportTimeoutMs =
      int.tryParse(_value(args, 'stale-report-timeout-ms', '240000')) ?? 240000;
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/peh_core_mac_wave_commands.json',
  );

  if (maxCases <= 0 ||
      chunkSize <= 0 ||
      timeoutMs <= 0 ||
      staleReportTimeoutMs <= 0 ||
      minPassRate <= 0 ||
      minPassRate > 1) {
    stderr.writeln(
      '--max-cases, --chunk-size, --timeout-ms, and '
      '--stale-report-timeout-ms must be positive, and '
      '--min-pass-rate must be greater than 0 and at most 1.',
    );
    return 64;
  }

  final measurementCommands = [
    for (final trade in ['electrical', 'hvac'])
      for (final locale in _locales)
        {
          'trade': trade,
          'localePackId': locale,
          'command': [
            'dart',
            'run',
            'tool/work_supply_parser_qa_run_generated_fixtures.dart',
            '--fixture',
            'build/parser_qa_generated/work_supply_parser/$trade/residential/core/$locale/generated_fixtures.json',
            '--max-cases',
            '$maxCases',
            '--chunk-size',
            '$chunkSize',
            '--min-pass-rate',
            minPassRate.toStringAsFixed(2),
            '--timeout-ms',
            '$timeoutMs',
            '--stale-report-timeout-ms',
            '$staleReportTimeoutMs',
            '--report-dir',
            'build/parser_qa_pipeline/mac_peh_core_measurement_$maxCases/$trade/residential/core/$locale/reports',
          ],
        },
  ];

  final rollups = [
    for (final trade in ['electrical', 'hvac'])
      {
        'trade': trade,
        'command': [
          'dart',
          'run',
          'tool/work_supply_parser_qa_generated_run_status.dart',
          '--report-root',
          'build/parser_qa_pipeline/mac_peh_core_measurement_$maxCases',
          '--trades',
          trade,
          '--scopes',
          'residential',
          '--tiers',
          'core',
          '--locales',
          _locales.join(','),
          '--require-complete',
          '--min-checked-per-cell',
          '$maxCases',
          '--min-pass-rate',
          minPassRate.toStringAsFixed(2),
          '--output',
          'build/parser_qa_pipeline/mac_${trade}_core_generated_run_status_$maxCases.json',
        ],
      },
  ];

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_peh_core_mac_wave_commands',
    'maxCases': maxCases,
    'chunkSize': chunkSize,
    'minPassRate': minPassRate,
    'timeoutMs': timeoutMs,
    'staleReportTimeoutMs': staleReportTimeoutMs,
    'measurementCommandCount': measurementCommands.length,
    'rollupCommandCount': rollups.length,
    'measurementCommands': measurementCommands,
    'rollupCommands': rollups,
    'plumbingFocusedRuntimeCommand': [
      'flutter',
      'test',
      'test/work_supply_plumbing_receipt_parser_test.dart',
      '--plain-name',
      'plumbing receipt parser handles Menards PVC sanitary tee line',
    ],
    'generatedAtIso': DateTime.now().toUtc().toIso8601String(),
  };

  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_PEH_CORE_MAC_WAVE_COMMANDS '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_PEH_CORE_MAC_WAVE_COMMANDS_ARTIFACT json=${file.path}');
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
