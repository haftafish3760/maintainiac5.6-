import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_run_intelligence.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_run_intelligence_report.dart '
    '[--root build/parser_qa_batch_waves] [--wave-id pass245] '
    '[--output build/parser_qa_batch_waves/pass245/run_intelligence_report.json]';

const _governedReportFields = [
  'remainingCellCount',
  'nextActions',
  'recommendedFixtureRunLimit',
  'run_intelligence_report.txt',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaRunIntelligenceReport(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaRunIntelligenceReport(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    stdout.writeln('Governed fields: ${_governedReportFields.join(', ')}');
    return 0;
  }
  final root = _value(args, 'root', 'build/parser_qa_batch_waves');
  final waveId = _value(args, 'wave-id', '');
  if (waveId.isEmpty) {
    stderr.writeln('--wave-id is required.');
    return 64;
  }

  final output = _value(
    args,
    'output',
    '$root/$waveId/run_intelligence_report.json',
  );
  try {
    final result = buildParserQaRunIntelligenceReport(
      ParserQaRunIntelligenceOptions(
        root: root,
        waveId: waveId,
        output: output,
        reportName: 'work_supply_parser_qa_run_intelligence_report',
        consolePrefix: 'QA_RUN_INTELLIGENCE_REPORT',
        artifactPrefix: 'QA_RUN_INTELLIGENCE_REPORT_ARTIFACT',
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(result.report);
    stdout.writeln('QA_RUN_INTELLIGENCE_REPORT $json');
    stdout.writeln(
      'QA_RUN_INTELLIGENCE_REPORT_ARTIFACT '
      'json=${result.outputPath} text=${result.textOutputPath}',
    );
    return result.exitCode;
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
