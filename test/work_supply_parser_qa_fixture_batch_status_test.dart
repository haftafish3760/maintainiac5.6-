import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_fixture_batch_status.dart';

void main() {
  test('fixture batch status reports generated and missing fixtures', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_fixture_status_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);
    _writeJson('build/parser_qa_pipeline/fixture_batch_plan.json', {
      'cells': [
        {
          'cellId': 'plumbing.residential.core.en-US.fixtures',
          'trade': 'plumbing',
          'scope': 'residential',
          'tier': 'core',
          'locale': 'en-US',
        },
        {
          'cellId': 'hvac.residential.core.es-US.fixtures',
          'trade': 'hvac',
          'scope': 'residential',
          'tier': 'core',
          'locale': 'es-US',
        },
      ],
    });
    File(
        'build/parser_qa_generated/work_supply_parser/plumbing/residential/core/en-US/generated_fixtures.json',
      )
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('[]');

    final exit = runWorkSupplyParserQaFixtureBatchStatus(
      const [],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final status = _readJson(
      'build/parser_qa_pipeline/fixture_batch_status.json',
    );
    expect(status['cellCount'], 2);
    expect(status['generatedFixtureCount'], 1);
    expect(status['missingFixtureCount'], 1);
    expect(status['liveServicesAllowed'], isFalse);
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
