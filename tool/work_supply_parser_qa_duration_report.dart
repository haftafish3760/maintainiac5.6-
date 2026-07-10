import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_duration_report.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_duration_report.dart '
    '[--summary build/parser_qa_batch_waves/.../summary.json|latest_status.json] '
    '[--output build/parser_qa_batch_waves/.../duration_report.json]';

const _governedReportFields = [
  'totalDurationMs',
  'averageDurationMs',
  'slowestCells',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaDurationReport(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaDurationReport(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    stdout.writeln('Governed fields: ${_governedReportFields.join(', ')}');
    return 0;
  }
  final summaryPath = _value(args, 'summary', '');
  if (summaryPath.isEmpty) {
    stderr.writeln('--summary is required.');
    return 64;
  }
  final summaryFile = File(summaryPath);
  final output = _value(
    args,
    'output',
    '${summaryFile.parent.path}/duration_report.json',
  );
  try {
    final report = buildParserQaDurationReport(
      ParserQaDurationReportOptions(
        summaryPath: summaryPath,
        outputPath: output,
        reportName: 'work_supply_parser_qa_duration_report',
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(report);
    stdout.writeln('QA_DURATION_REPORT $json');
    stdout.writeln('QA_DURATION_REPORT_ARTIFACT json=$output');
    return 0;
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
