import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_fixture_batch_status.dart '
    '[--plan build/parser_qa_pipeline/fixture_batch_plan.json] '
    '[--output build/parser_qa_pipeline/fixture_batch_status.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaFixtureBatchStatus(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaFixtureBatchStatus(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final planPath = _value(
    args,
    'plan',
    'build/parser_qa_pipeline/fixture_batch_plan.json',
  );
  final planFile = File(planPath);
  if (!planFile.existsSync()) {
    stderr.writeln('Fixture batch plan not found: $planPath');
    return 66;
  }
  final plan = jsonDecode(planFile.readAsStringSync()) as Map<String, Object?>;
  final cells = (plan['cells'] as List? ?? const []).whereType<Map>();
  final statuses = [
    for (final cell in cells)
      {
        'cellId': cell['cellId'],
        'trade': cell['trade'],
        'scope': cell['scope'],
        'tier': cell['tier'],
        'locale': cell['locale'],
        'fixturePath': _fixturePath(cell),
        'fixtureExists': File(_fixturePath(cell)).existsSync(),
      },
  ];
  final ready = statuses.where((cell) => cell['fixtureExists'] == true).length;
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_fixture_batch_status',
    'plan': planPath,
    'cellCount': statuses.length,
    'generatedFixtureCount': ready,
    'missingFixtureCount': statuses.length - ready,
    'cells': statuses,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/fixture_batch_status.json',
  );
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
    'QA_FIXTURE_BATCH_STATUS ${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_FIXTURE_BATCH_STATUS_ARTIFACT json=$output');
  return 0;
}

String _fixturePath(Map<Object?, Object?> cell) {
  return [
    'build/parser_qa_generated/work_supply_parser',
    cell['trade'],
    cell['scope'],
    cell['tier'],
    cell['locale'],
    'generated_fixtures.json',
  ].join('/');
}

String _value(List<String> args, String key, String fallback) {
  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    if (arg == '--$key' && index + 1 < args.length) return args[index + 1];
    if (arg.startsWith('--$key=')) return arg.substring(key.length + 3);
  }
  return fallback;
}
