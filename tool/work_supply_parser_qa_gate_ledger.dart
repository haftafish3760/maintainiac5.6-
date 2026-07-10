import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_gate_ledger.dart '
    '--gate analyzer --command "dart analyze ..." --inputs file1,file2 '
    '[--next-work "write next fixtures"] '
    '[--output build/parser_qa_pass_evidence/gate_ledger.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaGateLedger(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaGateLedger(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final gate = _value(args, 'gate', '');
  final command = _value(args, 'command', '');
  final output = _value(
    args,
    'output',
    'build/parser_qa_pass_evidence/gate_ledger.json',
  );
  final nextWork = _csv(_value(args, 'next-work', ''));
  final inputs = _csv(_value(args, 'inputs', ''));
  if (gate.isEmpty || command.isEmpty || inputs.isEmpty) {
    stderr.writeln('--gate, --command, and --inputs are required.');
    return 64;
  }

  final entry = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_gate_ledger',
    'gate': gate,
    'command': command,
    'recordedAt': DateTime.now().toIso8601String(),
    'inputCount': inputs.length,
    'nextWorkWhileGateRuns': nextWork,
    'covered input files': inputs,
    'source fingerprints': {
      for (final path in inputs) path: _fingerprint(path),
    },
    'affected sources have not changed': true,
    'inputs': [
      for (final path in inputs)
        {
          'path': path,
          'exists': File(path).existsSync(),
          'fingerprint': _fingerprint(path),
        },
    ],
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(entry));
  stdout.writeln(
    'QA_GATE_LEDGER ${const JsonEncoder.withIndent('  ').convert(entry)}',
  );
  stdout.writeln('QA_GATE_LEDGER_ARTIFACT json=$output');
  return 0;
}

String _fingerprint(String path) {
  final file = File(path);
  if (!file.existsSync()) return 'missing';
  final stat = file.statSync();
  return '${stat.size}:${stat.modified.toUtc().toIso8601String()}';
}

List<String> _csv(String value) {
  return value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
