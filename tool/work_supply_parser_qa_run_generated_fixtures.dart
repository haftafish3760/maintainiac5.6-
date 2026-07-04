import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart '
    '--fixture build/.../generated_fixtures.json '
    '[--max-cases 1000] [--fixture-ids id1,id2] '
    '[--report-dir build/parser_qa_reports/generated_fixtures]';

Future<void> main(List<String> args) async {
  final exit = await runGeneratedParserFixtures(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runGeneratedParserFixtures(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
  Future<ProcessResult> Function(
    String executable,
    List<String> arguments, {
    bool runInShell,
  })?
  processRunner,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _FixtureRunnerOptions.parse(args);
  if (options.fixturePath.trim().isEmpty) {
    stderr.writeln('--fixture is required.');
    return 64;
  }
  if (options.maxCases <= 0) {
    stderr.writeln('--max-cases must be greater than zero.');
    return 64;
  }
  if (!File(options.fixturePath).existsSync()) {
    stderr.writeln('Generated fixture file not found: ${options.fixturePath}');
    return 66;
  }

  final command = [
    'test/work_supply_parser_generated_fixture_runner_test.dart',
    '--dart-define=PARSER_QA_GENERATED_FIXTURE_PATH=${options.fixturePath}',
    '--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=${options.maxCases}',
    '--dart-define=PARSER_QA_GENERATED_REPORT_DIR=${options.reportDir}',
    if (options.fixtureIds.isNotEmpty)
      '--dart-define=PARSER_QA_GENERATED_FIXTURE_IDS=${options.fixtureIds.join(',')}',
    '--reporter',
    'compact',
  ];
  stdout.writeln(
    'QA_GENERATED_FIXTURE_RUN_WRAPPER runner=flutter-test '
    'reason=parser_core_not_yet_extracted_for_dart_cli '
    'fixture=${options.fixturePath} maxCases=${options.maxCases}',
  );
  final runProcess = processRunner ?? Process.run;
  final result = await runProcess('flutter', [
    'test',
    ...command,
  ], runInShell: Platform.isWindows);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  return result.exitCode;
}

class _FixtureRunnerOptions {
  const _FixtureRunnerOptions({
    required this.fixturePath,
    required this.maxCases,
    required this.reportDir,
    required this.fixtureIds,
  });

  final String fixturePath;
  final int maxCases;
  final String reportDir;
  final Set<String> fixtureIds;

  static _FixtureRunnerOptions parse(List<String> args) {
    return _FixtureRunnerOptions(
      fixturePath: _valueAfter(args, '--fixture') ?? '',
      maxCases: int.tryParse(_valueAfter(args, '--max-cases') ?? '') ?? 1000,
      reportDir:
          _valueAfter(args, '--report-dir') ??
          'build/parser_qa_reports/generated_fixtures',
      fixtureIds: _csvSet(_valueAfter(args, '--fixture-ids') ?? ''),
    );
  }
}

Set<String> _csvSet(String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toSet();
}

String? _valueAfter(List<String> args, String flag) {
  final index = args.indexOf(flag);
  if (index == -1 || index + 1 >= args.length) return null;
  return args[index + 1];
}
