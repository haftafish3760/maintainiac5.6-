import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_gate_should_run.dart '
    '--ledger build/parser_qa_pass_evidence/gate_ledger.json '
    '--inputs file1,file2';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaGateShouldRun(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaGateShouldRun(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final ledgerPath = _value(
    args,
    'ledger',
    'build/parser_qa_pass_evidence/gate_ledger.json',
  );
  final inputs = _csv(_value(args, 'inputs', ''));
  if (inputs.isEmpty) {
    stderr.writeln('--inputs is required.');
    return 64;
  }
  final ledgerFile = File(ledgerPath);
  if (!ledgerFile.existsSync()) {
    stdout.writeln(
      'QA_GATE_SHOULD_RUN ${jsonEncode({'shouldRun': true, 'reason': 'missing_ledger', 'ledger': ledgerPath})}',
    );
    return 2;
  }

  final ledger =
      jsonDecode(ledgerFile.readAsStringSync()) as Map<String, Object?>;
  final previous = <String, String>{
    for (final item in (ledger['inputs'] as List? ?? const []))
      if (item is Map && item['path'] != null)
        '${item['path']}': '${item['fingerprint']}',
  };
  final changed = <String>[];
  final uncovered = <String>[];
  for (final input in inputs) {
    final oldFingerprint = previous[input];
    if (oldFingerprint == null) {
      uncovered.add(input);
      continue;
    }
    final current = _fingerprint(input);
    if (current != oldFingerprint) changed.add(input);
  }
  final shouldRun = changed.isNotEmpty || uncovered.isNotEmpty;
  final result = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_gate_should_run',
    'shouldRun': shouldRun,
    'reason': shouldRun ? 'changed_or_uncovered_inputs' : 'covered_unchanged',
    'covered input files': previous.keys.toList()..sort(),
    'source fingerprints': previous,
    'affected sources have not changed': !shouldRun,
    'changedInputs': changed,
    'uncoveredInputs': uncovered,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  stdout.writeln(
    'QA_GATE_SHOULD_RUN ${const JsonEncoder.withIndent('  ').convert(result)}',
  );
  return shouldRun ? 1 : 0;
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
