import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_registry_snapshot.dart';

void main() {
  test('registry snapshot records suites and artifact presence locally', () {
    final root = Directory.systemTemp.createTempSync('maintainiac_registry_');
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    final registry =
        File('test/support/work_supply_parser_qa/work_supply_parser_qa.dart')
          ..parent.createSync(recursive: true)
          ..writeAsStringSync('const suites = [AlphaSuite(), BetaSuite()];');
    expect(registry.existsSync(), isTrue);

    final exit = runWorkSupplyParserQaRegistrySnapshot(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final summary = _readJson(
      'build/parser_qa_pass_evidence/registry_snapshot.json',
    );
    expect(summary['registeredSuiteCount'], 2);
    expect(summary['registeredSuites'].toString(), contains('AlphaSuite'));
    expect(summary['liveServicesAllowed'], isFalse);
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
