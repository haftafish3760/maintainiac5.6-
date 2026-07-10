import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_fixture_batch_plan.dart';

void main() {
  test('fixture batch plan creates residential trade tier locale cells', () {
    final root = Directory.systemTemp.createTempSync(
      'maintainiac_fixture_plan_',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final previous = Directory.current;
    Directory.current = root;
    addTearDown(() => Directory.current = previous);

    final exit = runWorkSupplyParserQaFixtureBatchPlan(
      const [
        '--trades',
        'plumbing,hvac',
        '--tiers',
        'core',
        '--locales',
        'en-US,es-US',
        '--limit',
        '250',
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final plan = _readJson('build/parser_qa_pipeline/fixture_batch_plan.json');
    expect(plan['cellCount'], 4);
    expect(plan['liveServicesAllowed'], isFalse);
    expect(
      plan['cells'].toString(),
      contains('plumbing.residential.core.en-US'),
    );
    expect(
      plan['cells'].toString(),
      contains('work_supply_parser_qa_generate_fixtures.dart'),
    );
  });

  test('fixture batch plan rejects invalid limits', () {
    final exit = runWorkSupplyParserQaFixtureBatchPlan(
      const ['--limit', '0'],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 64);
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
