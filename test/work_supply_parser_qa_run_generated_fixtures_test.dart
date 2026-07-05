import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_run_generated_fixtures.dart';

void main() {
  test('generated fixture wrapper builds the local-only runner command', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_generated_fixture_runner_',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = File('${root.path}/generated_fixtures.json')
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert([
          {
            'id': 'plumbing_residential_core_en_US_wax_ring_00001',
            'caseType': 'clear_match',
            'rawLine': 'LOWES TOILET WAX RING 4.98',
            'expectedTrade': 'Plumbing',
            'expectedNameContains': 'wax ring',
            'tradeScope': 'Plumbing',
          },
        ]),
      );

    late String executable;
    late List<String> arguments;
    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = await runGeneratedParserFixtures(
      [
        '--fixture',
        fixture.path,
        '--max-cases',
        '1',
        '--timeout-ms',
        '12345',
        '--report-dir',
        '${root.path}/reports',
      ],
      stdout: stdout,
      stderr: stderr,
      processRunner:
          (String command, List<String> args, {bool runInShell = false}) async {
            executable = command;
            arguments = args;
            return ProcessResult(
              42,
              0,
              'flutter progress spam\n'
                  'QA_GENERATED_FIXTURE_RUN checked=1 failures=0 parserCalls=3',
              '',
            );
          },
    );

    expect(exit, 0, reason: stderr.content);
    expect(executable, 'flutter');
    expect(arguments, contains('test'));
    expect(
      arguments,
      contains('test/work_supply_parser_generated_fixture_runner_test.dart'),
    );
    expect(
      arguments,
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=1'),
    );
    expect(stdout.content, contains('timeoutMs=12345'));
    expect(
      arguments,
      contains(
        '--dart-define=PARSER_QA_GENERATED_REPORT_DIR=${root.path}/reports/chunks/001',
      ),
    );
    expect(stdout.content, contains('QA_GENERATED_FIXTURE_RUN_WRAPPER'));
    expect(stdout.content, contains('runner=flutter-test'));
    expect(stdout.content, contains('QA_GENERATED_FIXTURE_RUN_CHUNK'));
    expect(stdout.content, contains('parserCalls=3'));
    expect(stdout.content, contains('QA_GENERATED_FIXTURE_RUN_AGGREGATE'));
    expect(stdout.content, isNot(contains('flutter progress spam')));
  });

  test('generated fixture wrapper times out hung child process', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_generated_fixture_runner_timeout_',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = File('${root.path}/generated_fixtures.json')
      ..writeAsStringSync('[]');

    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = await runGeneratedParserFixtures(
      [
        '--fixture',
        fixture.path,
        '--timeout-ms',
        '1',
        '--report-dir',
        '${root.path}/reports',
      ],
      stdout: stdout,
      stderr: stderr,
      processRunner:
          (String command, List<String> args, {bool runInShell = false}) async {
            await Future<void>.delayed(const Duration(milliseconds: 5));
            return ProcessResult(45, 124, '', 'timeout');
          },
    );

    expect(exit, 124);
    expect(stdout.content, contains('timeoutMs=1'));
  });

  test(
    'generated fixture wrapper verbose mode passes through full output',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_generated_fixture_runner_verbose_',
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = File('${root.path}/generated_fixtures.json')
        ..writeAsStringSync('[]');

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runGeneratedParserFixtures(
        ['--fixture', fixture.path, '--verbose'],
        stdout: stdout,
        stderr: stderr,
        processRunner:
            (
              String command,
              List<String> args, {
              bool runInShell = false,
            }) async {
              return ProcessResult(
                44,
                0,
                'flutter progress spam\nQA_GENERATED_FIXTURE_RUN checked=0',
                '',
              );
            },
      );

      expect(exit, 0, reason: stderr.content);
      expect(stdout.content, contains('outputMode=verbose'));
      expect(stdout.content, contains('flutter progress spam'));
    },
  );

  test('generated fixture wrapper can target one fixture id', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_generated_fixture_runner_filter_',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = File('${root.path}/generated_fixtures.json')
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert([
          {
            'id': 'skip_me',
            'caseType': 'clear_match',
            'rawLine': 'LOWES PEX CRIMP RING 3.25',
            'expectedTrade': 'Plumbing',
            'expectedNameContains': 'pex',
            'tradeScope': 'Plumbing',
          },
          {
            'id': 'run_me',
            'caseType': 'clear_match',
            'rawLine': 'LOWES TOILET WAX RING 4.98',
            'expectedTrade': 'Plumbing',
            'expectedNameContains': 'wax ring',
            'tradeScope': 'Plumbing',
          },
        ]),
      );

    late List<String> arguments;
    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = await runGeneratedParserFixtures(
      [
        '--fixture',
        fixture.path,
        '--fixture-ids',
        'run_me',
        '--report-dir',
        '${root.path}/reports',
      ],
      stdout: stdout,
      stderr: stderr,
      processRunner:
          (String command, List<String> args, {bool runInShell = false}) async {
            arguments = args;
            return ProcessResult(
              43,
              0,
              'QA_GENERATED_FIXTURE_RUN checked=1 failures=0 parserCalls=2',
              '',
            );
          },
    );

    expect(exit, 0, reason: stderr.content);
    expect(
      arguments,
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_IDS=run_me'),
    );
  });

  test('generated fixture wrapper chunks large runs surgically', () async {
    final root = await Directory.systemTemp.createTemp(
      'maintainiac_generated_fixture_runner_chunks_',
    );
    addTearDown(() => root.delete(recursive: true));
    final fixture = File('${root.path}/generated_fixtures.json')
      ..writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert([
          for (var index = 0; index < 5; index++)
            {
              'id': 'fixture_$index',
              'caseType': 'clear_match',
              'rawLine': 'LOWES TOILET WAX RING 4.98',
              'expectedTrade': 'Plumbing',
              'expectedNameContains': 'wax ring',
              'tradeScope': 'Plumbing',
            },
        ]),
      );

    final calls = <List<String>>[];
    final stdout = _MemorySink();
    final stderr = _MemorySink();
    final exit = await runGeneratedParserFixtures(
      [
        '--fixture',
        fixture.path,
        '--max-cases',
        '5',
        '--chunk-size',
        '2',
        '--report-dir',
        '${root.path}/reports',
      ],
      stdout: stdout,
      stderr: stderr,
      processRunner:
          (String command, List<String> args, {bool runInShell = false}) async {
            calls.add(args);
            return ProcessResult(
              44 + calls.length,
              0,
              'QA_GENERATED_FIXTURE_RUN checked=2 failures=0 warmupMs=1 parserCalls=4',
              '',
            );
          },
    );

    expect(exit, 0, reason: stderr.content);
    expect(calls, hasLength(3));
    expect(
      calls[0],
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_START_INDEX=0'),
    );
    expect(
      calls[1],
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_START_INDEX=2'),
    );
    expect(
      calls[2],
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_START_INDEX=4'),
    );
    expect(
      calls[0],
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=2'),
    );
    expect(
      calls[2],
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=1'),
    );
    expect(
      calls.join('\n'),
      isNot(contains('PARSER_QA_GENERATED_FIXTURE_IDS')),
    );
    expect(stdout.content, contains('chunkSize=2 chunks=3'));
    expect(stdout.content, contains('completedChunks=3 plannedChunks=3'));
    expect(stdout.content, contains('parserCalls=4'));
  });

  test(
    'generated fixture wrapper preserves parser call counts in aggregate',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_generated_fixture_runner_parser_calls_',
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = File('${root.path}/generated_fixtures.json')
        ..writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert([
            {
              'id': 'fixture_1',
              'caseType': 'clear_match',
              'rawLine': 'LOWES TOILET WAX RING 4.98',
              'expectedTrade': 'Plumbing',
              'expectedNameContains': 'wax ring',
              'tradeScope': 'Plumbing',
            },
            {
              'id': 'fixture_2',
              'caseType': 'clear_match',
              'rawLine': 'LOWES NM-B 12/2 25FT',
              'expectedTrade': 'Electrical',
              'expectedNameContains': 'wire',
              'tradeScope': 'Electrical',
            },
          ]),
        );

      var callIndex = 0;
      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runGeneratedParserFixtures(
        [
          '--fixture',
          fixture.path,
          '--max-cases',
          '2',
          '--chunk-size',
          '1',
          '--report-dir',
          '${root.path}/reports',
        ],
        stdout: stdout,
        stderr: stderr,
        processRunner:
            (
              String command,
              List<String> args, {
              bool runInShell = false,
            }) async {
              callIndex++;
              final reportDirArg = args.firstWhere(
                (arg) => arg.startsWith(
                  '--dart-define=PARSER_QA_GENERATED_REPORT_DIR=',
                ),
              );
              final reportDir = reportDirArg.split('=').last;
              Directory(reportDir).createSync(recursive: true);
              File(
                '$reportDir/latest_generated_fixture_run.json',
              ).writeAsStringSync(
                const JsonEncoder.withIndent('  ').convert({
                  'checked': 1,
                  'failureCount': 0,
                  'warmupMs': 1,
                  'parserCalls': callIndex + 10,
                }),
              );
              return ProcessResult(50 + callIndex, 0, '', '');
            },
      );

      final aggregate =
          jsonDecode(
                File(
                  '${root.path}/reports/latest_generated_fixture_run.json',
                ).readAsStringSync(),
              )
              as Map;

      expect(exit, 0, reason: stderr.content);
      expect(aggregate['checked'], 2);
      expect(aggregate['failureCount'], 0);
      expect(aggregate['parserCalls'], 23);
      expect(
        (aggregate['chunkReports'] as List).map(
          (chunk) => (chunk as Map)['parserCalls'],
        ),
        [11, 12],
      );
    },
  );

  test(
    'generated fixture wrapper fails green child output with failures',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_generated_fixture_runner_reported_failure_',
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = File('${root.path}/generated_fixtures.json')
        ..writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert([
            {
              'id': 'fixture_1',
              'caseType': 'clear_match',
              'rawLine': 'LOWES TOILET WAX RING 4.98',
              'expectedTrade': 'Plumbing',
              'expectedNameContains': 'wax ring',
              'tradeScope': 'Plumbing',
            },
          ]),
        );

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runGeneratedParserFixtures(
        [
          '--fixture',
          fixture.path,
          '--max-cases',
          '1',
          '--report-dir',
          '${root.path}/reports',
        ],
        stdout: stdout,
        stderr: stderr,
        processRunner:
            (
              String command,
              List<String> args, {
              bool runInShell = false,
            }) async {
              return ProcessResult(
                60,
                0,
                'QA_GENERATED_FIXTURE_RUN checked=1 failures=1 parserCalls=2',
                '',
              );
            },
      );

      expect(exit, 1);
      expect(stdout.content, contains('failures=1'));
    },
  );

  test(
    'generated fixture wrapper fails checked runs without parser calls',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_generated_fixture_runner_zero_parser_calls_',
      );
      addTearDown(() => root.delete(recursive: true));
      final fixture = File('${root.path}/generated_fixtures.json')
        ..writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert([
            {
              'id': 'fixture_1',
              'caseType': 'clear_match',
              'rawLine': 'LOWES TOILET WAX RING 4.98',
              'expectedTrade': 'Plumbing',
              'expectedNameContains': 'wax ring',
              'tradeScope': 'Plumbing',
            },
          ]),
        );

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runGeneratedParserFixtures(
        [
          '--fixture',
          fixture.path,
          '--max-cases',
          '1',
          '--report-dir',
          '${root.path}/reports',
        ],
        stdout: stdout,
        stderr: stderr,
        processRunner:
            (
              String command,
              List<String> args, {
              bool runInShell = false,
            }) async {
              return ProcessResult(
                61,
                0,
                'QA_GENERATED_FIXTURE_RUN checked=1 failures=0 parserCalls=0',
                '',
              );
            },
      );

      expect(exit, 1);
      expect(stdout.content, contains('parserCalls=0'));
    },
  );
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  String get content => _buffer.toString();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
