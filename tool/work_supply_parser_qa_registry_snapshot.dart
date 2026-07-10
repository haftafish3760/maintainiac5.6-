import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_registry_snapshot.dart '
    '[--output build/parser_qa_pass_evidence/registry_snapshot.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaRegistrySnapshot(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaRegistrySnapshot(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final registry = File(
    'test/support/work_supply_parser_qa/work_supply_parser_qa.dart',
  );
  final source = registry.existsSync() ? registry.readAsStringSync() : '';
  final suites = RegExp(
    r'([A-Za-z0-9]+Suite)\(\)',
  ).allMatches(source).map((match) => match.group(1)!).toSet().toList()..sort();
  final artifacts = {
    'latestHarnessReport':
        'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
    'latestPassEvidence':
        'build/parser_qa_pass_evidence/latest_pass_evidence.json',
    'evidenceSummary': 'build/parser_qa_pass_evidence/evidence_summary.json',
    'nextAction': 'build/parser_qa_pass_evidence/next_action.json',
    'gateLedger': 'build/parser_qa_pass_evidence/gate_ledger.json',
  };
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_registry_snapshot',
    'registeredSuiteCount': suites.length,
    'registeredSuites': suites,
    'artifactPresence': [
      for (final entry in artifacts.entries)
        {
          'name': entry.key,
          'path': entry.value,
          'exists': File(entry.value).existsSync(),
        },
    ],
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  final output = _value(
    args,
    'output',
    'build/parser_qa_pass_evidence/registry_snapshot.json',
  );
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
    'QA_REGISTRY_SNAPSHOT ${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_REGISTRY_SNAPSHOT_ARTIFACT json=$output');
  return registry.existsSync() ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
