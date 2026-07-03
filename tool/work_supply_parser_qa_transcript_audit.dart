import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_transcript_audit.dart '
    '[--summary build/parser_qa_batch_waves/.../summary.json] '
    '[--output build/parser_qa_batch_waves/.../transcript_audit.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaTranscriptAudit(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaTranscriptAudit(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final summaryPath = _value(args, 'summary', '');
  if (summaryPath.isEmpty) {
    stderr.writeln('--summary is required.');
    return 64;
  }
  final summaryFile = File(summaryPath);
  if (!summaryFile.existsSync()) {
    stderr.writeln('Summary not found: $summaryPath');
    return 66;
  }
  final output = _value(
    args,
    'output',
    '${summaryFile.parent.path}/transcript_audit.json',
  );
  final summary = jsonDecode(summaryFile.readAsStringSync()) as Map;
  final rows = <Map<String, Object?>>[];
  var failed = false;
  for (final result in summary['results'] as List? ?? const []) {
    final row = result as Map;
    final transcriptPath = row['transcriptPath'].toString();
    final transcript = File(transcriptPath);
    final text = transcript.existsSync() ? transcript.readAsStringSync() : '';
    final checks = {
      'exists': transcript.existsSync(),
      'hasCommand': text.contains('command='),
      'hasExitCode': text.contains('exitCode=${row['exitCode']}'),
      'hasStdout': text.contains('--- stdout ---'),
      'hasStderr': text.contains('--- stderr ---'),
      'hasLocalOnlySummary': text.contains('liveServicesAllowed') &&
          text.contains('writesProductionCatalog'),
    };
    final ok = checks.values.every((value) => value);
    if (!ok) failed = true;
    rows.add({
      'cellId': row['cellId'],
      'transcriptPath': transcriptPath,
      'exitCode': row['exitCode'],
      'ok': ok,
      'checks': checks,
    });
  }
  final report = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_transcript_audit',
    'summaryPath': summaryPath,
    'checkedTranscriptCount': rows.length,
    'failedTranscriptCount': rows.where((row) => row['ok'] != true).length,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'rows': rows,
  };
  final json = const JsonEncoder.withIndent('  ').convert(report);
  File(output)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(json, flush: true);
  stdout.writeln('QA_TRANSCRIPT_AUDIT $json');
  stdout.writeln('QA_TRANSCRIPT_AUDIT_ARTIFACT json=$output');
  return failed ? 1 : 0;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
