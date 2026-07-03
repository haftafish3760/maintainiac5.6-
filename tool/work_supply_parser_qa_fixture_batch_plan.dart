import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_fixture_batch_plan.dart '
    '[--trades plumbing,electrical,hvac] [--tiers core,standard] '
    '[--locales en-US,es-US] [--limit 500] '
    '[--output build/parser_qa_pipeline/fixture_batch_plan.json]';

Future<void> main(List<String> args) async {
  final exit = runWorkSupplyParserQaFixtureBatchPlan(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

int runWorkSupplyParserQaFixtureBatchPlan(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final trades = _csv(_value(args, 'trades', 'plumbing,electrical,hvac'));
  final tiers = _csv(_value(args, 'tiers', 'core,standard'));
  final locales = _csv(_value(args, 'locales', 'en-US,es-US'));
  final limit = int.tryParse(_value(args, 'limit', '500')) ?? 500;
  if (trades.isEmpty || tiers.isEmpty || locales.isEmpty || limit <= 0) {
    stderr.writeln('--trades, --tiers, --locales, and --limit must be valid.');
    return 64;
  }
  final cells = [
    for (final trade in trades)
      for (final tier in tiers)
        for (final locale in locales)
          {
            'cellId': '$trade.residential.$tier.$locale.fixtures',
            'trade': trade,
            'scope': 'residential',
            'tier': tier,
            'locale': locale,
            'limit': limit,
            'generateFixturesCommand': [
              'dart',
              'run',
              'tool/work_supply_parser_qa_generate_fixtures.dart',
              '--trade',
              trade,
              '--scope',
              'residential',
              '--tier',
              tier,
              '--locale',
              locale,
              '--limit',
              '$limit',
            ],
            'runParserCommand': [
              'flutter',
              'test',
              'test/work_supply_parser_generated_fixture_runner_test.dart',
              '--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=$limit',
            ],
          },
  ];
  final summary = {
    'schemaVersion': 1,
    'report': 'work_supply_parser_qa_fixture_batch_plan',
    'cellCount': cells.length,
    'cells': cells,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'ocrCameraExpensesTouched': false,
  };
  final output = _value(
    args,
    'output',
    'build/parser_qa_pipeline/fixture_batch_plan.json',
  );
  final file = File(output)..parent.createSync(recursive: true);
  file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(summary));
  stdout.writeln(
    'QA_FIXTURE_BATCH_PLAN ${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln('QA_FIXTURE_BATCH_PLAN_ARTIFACT json=$output');
  return 0;
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
