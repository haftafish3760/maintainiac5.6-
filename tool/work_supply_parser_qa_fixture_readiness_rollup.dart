import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_fixture_readiness_rollup.dart '
    '[--statuses build/parser_qa_pipeline/fixture_batch_status.json,'
    'build/parser_qa_pipeline/fixture_batch_status_professional_complete.json] '
    '[--output build/parser_qa_pipeline/fixture_readiness_rollup.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaFixtureReadinessRollup(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaFixtureReadinessRollup(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final statusPaths = _csv(
    _value(
      args,
      'statuses',
      'build/parser_qa_pipeline/fixture_batch_status.json,'
          'build/parser_qa_pipeline/fixture_batch_status_professional_complete.json',
    ),
  );
  if (statusPaths.isEmpty) {
    stderr.writeln('--statuses must include at least one status file.');
    return 64;
  }

  final statusReports = <Map<String, Object?>>[];
  final missingStatusFiles = <String>[];
  final missingFixtureCells = <String>[];
  final unsafeFindings = <String>[];
  var totalCells = 0;
  var generatedCells = 0;

  for (final path in statusPaths) {
    final file = File(path);
    if (!file.existsSync()) {
      missingStatusFiles.add(path);
      continue;
    }
    final json = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    final cells = (json['cells'] as List? ?? const [])
        .whereType<Map>()
        .cast<Map<String, Object?>>()
        .toList(growable: false);
    totalCells += cells.length;
    generatedCells += cells
        .where((cell) => cell['fixtureExists'] == true)
        .length;
    for (final cell in cells) {
      if (cell['fixtureExists'] != true) {
        missingFixtureCells.add(cell['cellId']?.toString() ?? 'unknown_cell');
      }
    }
    for (final field in const [
      'liveServicesAllowed',
      'writesProductionCatalog',
      'firebaseWritesAllowed',
      'ocrCameraExpensesTouched',
    ]) {
      if (json[field] == true) unsafeFindings.add('$path:$field');
    }
    statusReports.add({
      'path': path,
      'cellCount': cells.length,
      'generatedFixtureCount': cells
          .where((cell) => cell['fixtureExists'] == true)
          .length,
      'missingFixtureCount': cells
          .where((cell) => cell['fixtureExists'] != true)
          .length,
    });
  }

  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_fixture_readiness_rollup',
    'statusFileCount': statusPaths.length,
    'totalCells': totalCells,
    'generatedFixtureCount': generatedCells,
    'missingFixtureCount': missingFixtureCells.length,
    'missingStatusFiles': missingStatusFiles,
    'missingFixtureCells': missingFixtureCells,
    'readyForParserExecution':
        missingStatusFiles.isEmpty &&
        missingFixtureCells.isEmpty &&
        unsafeFindings.isEmpty,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
    'unsafeFindings': unsafeFindings,
    'statusReports': statusReports,
  };
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/fixture_readiness_rollup.json',
  );
  final outputFile = File(output)..parent.createSync(recursive: true);
  outputFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(summary),
    flush: true,
  );
  stdout.writeln(
    'QA_FIXTURE_READINESS_ROLLUP '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_FIXTURE_READINESS_ROLLUP_ARTIFACT json=$output');
  return summary['readyForParserExecution'] == true ? 0 : 2;
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
