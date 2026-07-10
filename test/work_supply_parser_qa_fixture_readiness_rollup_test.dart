import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_fixture_readiness_rollup.dart';

void main() {
  test('fixture readiness rollup requires all status cells to exist', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_fixture_readiness_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/core_status.json', {
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
      'cells': [
        {'cellId': 'plumbing.residential.core.en-US', 'fixtureExists': true},
        {'cellId': 'plumbing.residential.core.es-US', 'fixtureExists': true},
      ],
    });
    _writeJson('build/parser_qa_pipeline/pro_status.json', {
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': false,
      'ocrCameraExpensesTouched': false,
      'cells': [
        {
          'cellId': 'plumbing.residential.professional.en-US',
          'fixtureExists': false,
        },
      ],
    });

    final exit = runWorkSupplyParserQaFixtureReadinessRollup(
      const [
        '--statuses',
        'build/parser_qa_pipeline/core_status.json,build/parser_qa_pipeline/pro_status.json',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 2);
    final rollup = _readJson(
      'build/parser_qa_pipeline/fixture_readiness_rollup.json',
    );
    expect(rollup['totalCells'], 3);
    expect(rollup['generatedFixtureCount'], 2);
    expect(rollup['missingFixtureCount'], 1);
    expect(rollup['readyForParserExecution'], isFalse);
  });

  test('fixture readiness rollup blocks unsafe status flags', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_fixture_readiness_unsafe_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/status.json', {
      'liveServicesAllowed': false,
      'writesProductionCatalog': false,
      'firebaseWritesAllowed': true,
      'ocrCameraExpensesTouched': false,
      'cells': [
        {'cellId': 'hvac.residential.core.en-US', 'fixtureExists': true},
      ],
    });

    final exit = runWorkSupplyParserQaFixtureReadinessRollup(
      const ['--statuses', 'build/parser_qa_pipeline/status.json'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 2);
    final rollup = _readJson(
      'build/parser_qa_pipeline/fixture_readiness_rollup.json',
    );
    expect(rollup['readyForParserExecution'], isFalse);
    expect(
      rollup['unsafeFindings'].toString(),
      contains('firebaseWritesAllowed'),
    );
  });
}

void _writeJson(String path, Map<String, Object?> value) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(jsonEncode(value));
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
