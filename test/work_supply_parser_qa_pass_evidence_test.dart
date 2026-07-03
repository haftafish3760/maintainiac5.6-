import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_pass_evidence.dart';

void main() {
  test('pass evidence writes durable local-only record', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_pass_evidence_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    final artifact = File('${root.path}/artifact.json')
      ..writeAsStringSync('{"ok":true}');
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaPassEvidence(
      ['--pass', '334', '--label', 'unit-test', '--artifact', artifact.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_PASS_EVIDENCE'));
    final latest = File(
      '${root.path}/build/parser_qa_pass_evidence/latest_pass_evidence.json',
    );
    expect(latest.existsSync(), isTrue);
    final record = jsonDecode(latest.readAsStringSync()) as Map;
    expect(record['pass'], '334');
    expect(record['label'], 'unit-test');
    expect(record['artifactExists'], isTrue);
    expect(record['liveServicesAllowed'], isFalse);
    expect(record['firebaseWritesAllowed'], isFalse);
    expect(record['ocrCameraExpensesTouched'], isFalse);
  });

  test('pass evidence requires pass and label', () {
    final stderr = _MemorySink();

    final exit = runWorkSupplyParserQaPassEvidence(
      const [],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 64);
    expect(stderr.content, contains('--pass and --label are required'));
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
