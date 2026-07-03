import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_evidence_summary.dart '
    '[--output build/parser_qa_pass_evidence/evidence_summary.json]';

const _defaultArtifacts = {
  'releaseOneCommands': 'build/parser_qa_pipeline/release_one_commands.json',
  'fixtureReadinessRollup':
      'build/parser_qa_pipeline/fixture_readiness_rollup.json',
  'queueWatchdog':
      'build/parser_qa_batch_waves/residential_all_tiers_wave_001/queue_watchdog.json',
  'latestPassEvidence':
      'build/parser_qa_pass_evidence/latest_pass_evidence.json',
  'latestHarnessReport':
      'build/parser_qa_reports/latest_work_supply_inventory_parser.json',
};

const _safetyFields = {
  'liveServicesAllowed',
  'writesProductionCatalog',
  'firebaseWritesAllowed',
  'ocrCameraExpensesTouched',
};

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaEvidenceSummary(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaEvidenceSummary(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final artifacts = <Map<String, Object?>>[];
  final missing = <String>[];
  final unsafe = <String>[];

  for (final entry in _defaultArtifacts.entries) {
    final file = File(entry.value);
    if (!file.existsSync()) {
      missing.add(entry.key);
      artifacts.add({'name': entry.key, 'path': entry.value, 'exists': false});
      continue;
    }
    final decoded = jsonDecode(file.readAsStringSync());
    final map = decoded is Map ? decoded.cast<String, Object?>() : const {};
    for (final field in _safetyFields) {
      if (map.containsKey(field) && map[field] != false) {
        unsafe.add('${entry.key}:$field=${map[field]}');
      }
    }
    if (map.containsKey('healthy') && map['healthy'] != true) {
      unsafe.add('${entry.key}:healthy=${map['healthy']}');
    }
    artifacts.add({
      'name': entry.key,
      'path': entry.value,
      'exists': true,
      if (map.containsKey('pass')) 'pass': map['pass'],
      if (map.containsKey('label')) 'label': map['label'],
      if (map.containsKey('cellCount')) 'cellCount': map['cellCount'],
      if (map.containsKey('totalCells')) 'totalCells': map['totalCells'],
      if (map.containsKey('generatedFixtureCount'))
        'generatedFixtureCount': map['generatedFixtureCount'],
      if (map.containsKey('readyForParserExecution'))
        'readyForParserExecution': map['readyForParserExecution'],
      if (map.containsKey('healthy')) 'healthy': map['healthy'],
      if (map.containsKey('findings')) 'findings': map['findings'],
      if (map.containsKey('checked')) 'checked': map['checked'],
      if (map.containsKey('actualFailureCount'))
        'actualFailureCount': map['actualFailureCount'],
    });
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_evidence_summary',
    'artifactCount': artifacts.length,
    'missingArtifactNames': missing,
    'unsafeFindings': unsafe,
    'ready': missing.isEmpty && unsafe.isEmpty,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'artifacts': artifacts,
  };
  final output = _value(
    args,
    'output',
    'build/parser_qa_pass_evidence/evidence_summary.json',
  );
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
    'QA_EVIDENCE_SUMMARY ${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_EVIDENCE_SUMMARY_ARTIFACT json=$output');
  return unsafe.isEmpty ? 0 : 1;
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
