import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_transcript_audit.dart';

void main() {
  test('transcript audit accepts complete local-only transcript evidence', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_transcript_audit_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final transcript = File('${root.path}/cell_transcript.txt')
      ..writeAsStringSync(
        [
          'command=dart run tool/work_supply_parser_qa_matrix_pipeline.dart',
          'exitCode=0',
          '--- stdout ---',
          'liveServicesAllowed false',
          'writesProductionCatalog false',
          '--- stderr ---',
        ].join('\n'),
      );
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'plumbing_residential_core_en_US',
              'exitCode': 0,
              'transcriptPath': transcript.path,
            },
          ],
        }),
      );
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaTranscriptAudit(
      ['--summary', summary.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_TRANSCRIPT_AUDIT'));
    expect(stdout.content, contains('"checkedTranscriptCount": 1'));
    expect(stdout.content, contains('"failedTranscriptCount": 0'));
  });

  test('transcript audit rejects missing transcript evidence', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_transcript_audit_missing_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final summary = File('${root.path}/summary.json')
      ..writeAsStringSync(
        jsonEncode({
          'results': [
            {
              'cellId': 'missing',
              'exitCode': 0,
              'transcriptPath': '${root.path}/missing.txt',
            },
          ],
        }),
      );

    final exit = runWorkSupplyParserQaTranscriptAudit(
      ['--summary', summary.path],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
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
