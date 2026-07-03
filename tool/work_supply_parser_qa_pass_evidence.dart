import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_pass_evidence.dart '
    '--pass 333 --label release-one-commands '
    '[--artifact build/parser_qa_pipeline/release_one_commands.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaPassEvidence(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaPassEvidence(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final pass = _value(args, 'pass', '');
  final label = _value(args, 'label', '');
  if (pass.isEmpty || label.isEmpty) {
    stderr.writeln('--pass and --label are required.');
    return 64;
  }
  final artifact = _value(args, 'artifact', '');
  final now = DateTime.now().toLocal();
  final record = {
    'schemaVersion': 1,
    'pass': pass,
    'label': label,
    'localTime': _timeOnly(now),
    'timestamp': now.toIso8601String(),
    'artifact': artifact,
    'artifactExists': artifact.isNotEmpty ? File(artifact).existsSync() : false,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  final root = Directory('build/parser_qa_pass_evidence')
    ..createSync(recursive: true);
  final output = File('${root.path}/pass_$pass.json');
  output.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(record));
  File(
    '${root.path}/latest_pass_evidence.json',
  ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(record));
  stdout.writeln(
    'QA_PASS_EVIDENCE ${const JsonEncoder.withIndent('  ').convert(record)}',
  );
  stdout.writeln('QA_PASS_EVIDENCE_ARTIFACT json=${output.path}');
  return 0;
}

String _timeOnly(DateTime value) {
  String two(int number) => number.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}:${two(value.second)}';
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
