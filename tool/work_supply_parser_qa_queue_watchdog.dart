import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_queue_watchdog.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_queue_watchdog.dart '
    '[--status build/parser_qa_batch_waves/.../latest_status.json] '
    '[--max-status-age-ms 900000] [--max-active-cell-ms 900000] '
    '[--output build/parser_qa_batch_waves/.../queue_watchdog.json]';

const _governedReportFields = [
  'statusAgeMs',
  'activeCellElapsedMs',
  'active_cell_stale',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaQueueWatchdog(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaQueueWatchdog(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    stdout.writeln('Governed fields: ${_governedReportFields.join(', ')}');
    return 0;
  }
  final statusPath = _value(args, 'status', '');
  if (statusPath.isEmpty) {
    stderr.writeln('--status is required.');
    return 64;
  }
  final statusFile = File(statusPath);
  final maxStatusAgeMs = _intValue(args, 'max-status-age-ms', 900000);
  final maxActiveCellMs = _intValue(args, 'max-active-cell-ms', 900000);
  if (maxStatusAgeMs <= 0 || maxActiveCellMs <= 0) {
    stderr.writeln(
      '--max-status-age-ms and --max-active-cell-ms must be positive.',
    );
    return 64;
  }
  final output = _value(
    args,
    'output',
    '${statusFile.parent.path}/queue_watchdog.json',
  );
  try {
    final report = buildParserQaQueueWatchdog(
      ParserQaQueueWatchdogOptions(
        statusPath: statusPath,
        outputPath: output,
        reportName: 'work_supply_parser_qa_queue_watchdog',
        maxStatusAgeMs: maxStatusAgeMs,
        maxActiveCellMs: maxActiveCellMs,
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(report);
    stdout.writeln('QA_QUEUE_WATCHDOG $json');
    stdout.writeln('QA_QUEUE_WATCHDOG_ARTIFACT json=$output');
    return report['healthy'] == true ? 0 : 1;
  } on FileSystemException catch (error) {
    stderr.writeln(error.message);
    return 66;
  }
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}

int _intValue(List<String> args, String key, int fallback) {
  return int.tryParse(_value(args, key, '$fallback')) ?? fallback;
}
