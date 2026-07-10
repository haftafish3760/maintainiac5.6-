import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_gate_ledger.dart';
import '../tool/work_supply_parser_qa_gate_should_run.dart';

void main() {
  test('gate ledger records covered files without running a gate', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_gate_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    File('a.dart').writeAsStringSync('void main() {}');
    final stdout = _MemorySink();

    final exit = runWorkSupplyParserQaGateLedger(
      const [
        '--gate',
        'analyzer',
        '--command',
        'dart analyze a.dart',
        '--inputs',
        'a.dart,missing.dart',
        '--next-work',
        'write more fixtures,prepare next catalog batch',
      ],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_GATE_LEDGER'));
    final ledger = _readJson('build/parser_qa_pass_evidence/gate_ledger.json');
    expect(ledger['gate'], 'analyzer');
    expect(ledger['inputCount'], 2);
    expect(ledger['nextWorkWhileGateRuns'].toString(), contains('fixtures'));
    expect(ledger['liveServicesAllowed'], isFalse);
    expect(ledger['inputs'].toString(), contains('missing'));
  });

  test('gate ledger requires gate, command, and inputs', () {
    final exit = runWorkSupplyParserQaGateLedger(
      const ['--gate', 'analyzer'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 64);
  });

  test('gate should-run checker skips unchanged covered inputs', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_gate_skip_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    File('a.dart').writeAsStringSync('void main() {}');
    runWorkSupplyParserQaGateLedger(
      const [
        '--gate',
        'analyzer',
        '--command',
        'dart analyze a.dart',
        '--inputs',
        'a.dart',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    final exit = runWorkSupplyParserQaGateShouldRun(
      const ['--inputs', 'a.dart'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
  });

  test('gate should-run checker requests rerun for changed inputs', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_gate_run_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    File('a.dart').writeAsStringSync('void main() {}');
    runWorkSupplyParserQaGateLedger(
      const [
        '--gate',
        'analyzer',
        '--command',
        'dart analyze a.dart',
        '--inputs',
        'a.dart',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );
    File('a.dart').writeAsStringSync('void main() { print(1); }');

    final exit = runWorkSupplyParserQaGateShouldRun(
      const ['--inputs', 'a.dart'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 1);
  });
}

Map<String, Object?> _readJson(String path) {
  return jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
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
