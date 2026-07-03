import 'dart:convert';
import 'dart:io';

import '../test/support/parser_qa_platform/parser_qa_failure_digest.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_failure_digest.dart '
    '[--summary build/parser_qa_batch_waves/.../summary.json] '
    '[--output build/parser_qa_batch_waves/.../failure_digest.json]';

const _governedReportFields = [
  'failedCellCount',
  'failedCells',
  'failurePreview',
  'transcriptPath',
  'suggestedFixCategory',
  '[REDACTED_RECEIPT_ID]',
  'Expected:',
  'Actual:',
  'Some tests failed',
];

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaFailureDigest(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaFailureDigest(
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
    '${summaryFile.parent.path}/failure_digest.json',
  );
  try {
    final digest = buildParserQaFailureDigest(
      ParserQaFailureDigestOptions(
        summaryPath: summaryPath,
        outputPath: output,
        reportName: 'work_supply_parser_qa_failure_digest',
      ),
    );
    final json = const JsonEncoder.withIndent('  ').convert(digest);
    stdout.writeln('QA_FAILURE_DIGEST $json');
    stdout.writeln('QA_FAILURE_DIGEST_ARTIFACT json=$output');
    return (digest['failedCellCount'] as int) == 0 ? 0 : 1;
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
