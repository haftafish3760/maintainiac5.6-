import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_generate_fixtures.dart';

void main() {
  test(
    'HVAC Core fixtures exclude non-Core duct stock and enforce tier',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_hvac_core_',
      );
      addTearDown(() => output.delete(recursive: true));

      final exit = await runWorkSupplyParserFixtureGenerator(
        [
          '--trade',
          'hvac',
          '--scope',
          'residential',
          '--tier',
          'core',
          '--locale',
          'en-US',
          '--limit',
          '100',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final fixtureFile = File(
        '${output.path}/work_supply_parser/hvac/residential/core/'
        'en-US/generated_fixtures.json',
      );
      final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
      expect(fixtures, hasLength(100));
      expect(
        fixtures.every((entry) => entry['expectedPackTier'] == 'core'),
        isTrue,
      );
      final ids = fixtures.map((entry) => entry['id'].toString()).join(' ');
      expect(ids, isNot(contains('flex_duct')));
      expect(ids, isNot(contains('start_collar')));
      final humidifierCases = fixtures.where(
        (entry) => entry['id'].toString().contains('humidifier_water_panel'),
      );
      expect(humidifierCases, isNotEmpty);
      expect(
        humidifierCases.every(
          (entry) => entry['expectedNameContains'] == 'Humidifier',
        ),
        isTrue,
      );
    },
  );
}

class _MemorySink implements IOSink {
  final _buffer = StringBuffer();

  @override
  void write(Object? object) => _buffer.write(object);

  @override
  void writeln([Object? object = '']) => _buffer.writeln(object);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
