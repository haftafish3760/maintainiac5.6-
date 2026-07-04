import 'dart:convert';
import 'dart:io';

const _usage =
    'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart '
    '--fixture build/.../generated_fixtures.json '
    '[--max-cases 1000] [--fixture-ids id1,id2] '
    '[--report-dir build/parser_qa_reports/generated_fixtures] '
    '[--verbose]';

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
    'fixture=${options.fixturePath} maxCases=${options.maxCases} '
    'outputMode=${options.verbose ? 'verbose' : 'summary'}',
  );
  final runProcess = processRunner ?? Process.run;
  final result = await runProcess('flutter', [
    'test',
    ...command,
  ], runInShell: Platform.isWindows);
  final output = '${result.stdout}';
  final errorOutput = '${result.stderr}';
  if (options.verbose) {
    stdout.write(output);
    stderr.write(errorOutput);
  } else {
    final summary = _summarizeFlutterOutput(
      output,
      reportDir: options.reportDir,
    );
    stdout.writeln(summary);
    if (result.exitCode != 0) {
      stdout.writeln(_tail(output, maxChars: 2400));
      if (errorOutput.trim().isNotEmpty) {
        stderr.writeln(_tail(errorOutput, maxChars: 2400));
      }
    }
  }
  return result.exitCode;
}

class _FixtureRunnerOptions {
  const _FixtureRunnerOptions({
    required this.fixturePath,
    required this.maxCases,
    required this.reportDir,
    required this.fixtureIds,
    required this.verbose,
  });

  final String fixturePath;
  final int maxCases;
  final String reportDir;
  final Set<String> fixtureIds;
  final bool verbose;

  static _FixtureRunnerOptions parse(List<String> args) {
    return _FixtureRunnerOptions(
      fixturePath: _valueAfter(args, '--fixture') ?? '',
      maxCases: int.tryParse(_valueAfter(args, '--max-cases') ?? '') ?? 1000,
      reportDir:
          _valueAfter(args, '--report-dir') ??
          'build/parser_qa_reports/generated_fixtures',
      fixtureIds: _csvSet(_valueAfter(args, '--fixture-ids') ?? ''),
      verbose: args.contains('--verbose'),
    );
  }
}

String _summarizeFlutterOutput(String output, {required String reportDir}) {
  final report = File('$reportDir/latest_generated_fixture_run.json');
  if (report.existsSync()) {
    try {
      final json =
          jsonDecode(report.readAsStringSync()) as Map<String, dynamic>;
      return 'QA_GENERATED_FIXTURE_RUN_SUMMARY '
          'checked=${json['checked']} '
          'failures=${json['failureCount']} '
          'warmupMs=${json['warmupMs']} '
          'report=${report.path}';
    } catch (_) {
      // Fall back to the runner line below; corrupt report JSON is handled by
      // the failing exit code and preserved report artifact.
    }
  }
  final line = output
      .split(RegExp(r'\r?\n'))
      .lastWhere(
        (entry) => entry.startsWith('QA_GENERATED_FIXTURE_RUN '),
        orElse: () => '',
      )
      .trim();
  if (line.isNotEmpty) return line;
  return 'QA_GENERATED_FIXTURE_RUN_SUMMARY report=$reportDir '
      'status=completed_without_summary_line';
}

String _tail(String value, {required int maxChars}) {
  final trimmed = value.trim();
  if (trimmed.length <= maxChars) return trimmed;
  return '... output truncated ...\n'
      '${trimmed.substring(trimmed.length - maxChars)}';
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
