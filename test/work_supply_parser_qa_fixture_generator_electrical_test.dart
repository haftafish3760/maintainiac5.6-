import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_generate_fixtures.dart';

void main() {
  test('fixture generator supports electrical professional spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_electrical_professional_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'electrical',
        '--scope',
        'residential',
        '--tier',
        'professional',
        '--locale',
        'es-US',
        '--limit',
        '24',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final fixtureFile = File(
      '${output.path}/work_supply_parser/electrical/residential/'
      'professional/es-US/generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(24));
    expect(fixtures.toString(), contains('BREAKER 2P'));
    expect(fixtures.toString(), contains('GROUND ROD'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator supports electrical complete spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_electrical_complete_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'electrical',
        '--scope',
        'residential',
        '--tier',
        'complete',
        '--locale',
        'es-US',
        '--limit',
        '28',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final fixtureFile = File(
      '${output.path}/work_supply_parser/electrical/residential/complete/'
      'es-US/generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(28));
    expect(fixtures.toString(), contains('CAJA WP'));
    expect(fixtures.toString(), contains('CUERPO LB'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
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
