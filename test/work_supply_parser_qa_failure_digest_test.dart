import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_failure_digest.dart';

void main() {
  test('failure digest passes when summary has no failed cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_failure_digest_clean_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final transcript = File('${root.path}/pass.txt')
      ..writeAsStringSync('exitCode=0\n--- stdout ---\n');
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'ok-cell',
              'exitCode': 0,
              'transcriptPath': transcript.path,
            },
          ],
        }),
      );
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaFailureDigest(
      ['--summary', summary.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('"failedCellCount": 0'));
  });

  test('failure digest extracts preview from failed transcript', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_failure_digest_failed_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final transcript = File('${root.path}/fail.txt')
      ..writeAsStringSync(
        [
          'exitCode=1',
          '--dart-define=PARSER_QA_GENERATED_FIXTURE_PATH=build/parser_qa_generated/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json',
          'Expected: matching plumbing item',
          'Actual: null',
          'plumbing_residential_core_en_US_pvc_elbow_00012: expected match, got null',
          'Some tests failed.',
        ].join('\n'),
      );
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'plumbing_residential_core_en_US',
              'trade': 'plumbing',
              'marketScope': 'residential',
              'tier': 'core',
              'localePackId': 'en-US',
              'exitCode': 1,
              'transcriptPath': transcript.path,
            },
          ],
        }),
      );
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaFailureDigest(
      ['--summary', summary.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 1);
    expect(stdout.content, contains('"failedCellCount": 1'));
    expect(stdout.content, contains('Expected: matching plumbing item'));
    expect(stdout.content, contains('Actual: null'));
    expect(
      stdout.content,
      contains('"strategy": "rerun_failed_generated_fixture_ids"'),
    );
    expect(
      stdout.content,
      contains(
        'dart run tool/work_supply_parser_qa_run_generated_fixtures.dart',
      ),
    );
    expect(
      stdout.content,
      contains('plumbing_residential_core_en_US_pvc_elbow_00012'),
    );
  });
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
