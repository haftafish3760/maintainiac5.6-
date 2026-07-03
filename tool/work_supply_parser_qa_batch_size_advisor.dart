import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_batch_size_advisor.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_batch_size_advisor.dart '
    '[--duration-report build/parser_qa_batch_waves/.../duration_report.json] '
    '[--current-fixture-run-limit 25] [--target-cell-ms 300000] '
    '[--min-completed-cells 6] '
    '[--output build/parser_qa_batch_waves/.../batch_size_advice.json]';

const _governedReportFields = [
  'recommendedFixtureRunLimit',
  'targetCellMs',
  'minCompletedCells',
  'slowestDurationMs',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaBatchSizeAdvisor(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaBatchSizeAdvisor(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    stdout.writeln('Governed fields: ${_governedReportFields.join(', ')}');
    return 0;
  }
  final durationReportPath = _value(args, 'duration-report', '');
  if (durationReportPath.isEmpty) {
    stderr.writeln('--duration-report is required.');
    return 64;
  }
  final reportFile = File(durationReportPath);
  final currentLimit = _intValue(args, 'current-fixture-run-limit', 25);
  final targetCellMs = _intValue(args, 'target-cell-ms', 300000);
  final minCompletedCells = _intValue(args, 'min-completed-cells', 6);
  if (currentLimit <= 0 || targetCellMs <= 0 || minCompletedCells <= 0) {
    stderr.writeln(
      '--current-fixture-run-limit, --target-cell-ms, and '
      '--min-completed-cells must be positive.',
    );
    return 64;
  }
  final output = _value(
    args,
    'output',
    '${reportFile.parent.path}/batch_size_advice.json',
  );
  try {
    final advice = buildParserQaBatchSizeAdvice(
      ParserQaBatchSizeAdvisorOptions(
        durationReportPath: durationReportPath,
        outputPath: output,
        reportName: 'work_supply_parser_qa_batch_size_advisor',
        currentLimit: currentLimit,
        targetCellMs: targetCellMs,
        minCompletedCells: minCompletedCells,
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(advice);
    stdout.writeln('QA_BATCH_SIZE_ADVICE $json');
    stdout.writeln('QA_BATCH_SIZE_ADVICE_ARTIFACT json=$output');
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

int _intValue(List<String> args, String key, int fallback) {
  return int.tryParse(_value(args, key, '$fallback')) ?? fallback;
}
