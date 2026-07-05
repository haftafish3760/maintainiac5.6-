import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_generate_fixtures.dart';

void main() {
  test(
    'fixture generator writes synthetic English batch and manifest',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_en_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runWorkSupplyParserFixtureGenerator(
        [
          '--trade',
          'plumbing',
          '--scope',
          'residential',
          '--tier',
          'core',
          '--locale',
          'en-US',
          '--limit',
          '24',
          '--output-dir',
          output.path,
        ],
        stdout: stdout,
        stderr: stderr,
      );

      expect(exit, 0, reason: stderr.content);
      expect(stdout.content, contains('QA_GENERATED_FIXTURES'));

      final generatedRoot = Directory(
        '${output.path}/work_supply_parser/plumbing/residential/core/en-US',
      );
      final fixtures =
          jsonDecode(
                File(
                  '${generatedRoot.path}/generated_fixtures.json',
                ).readAsStringSync(),
              )
              as List;
      final manifest =
          jsonDecode(
                File('${generatedRoot.path}/manifest.json').readAsStringSync(),
              )
              as Map;

      expect(fixtures, hasLength(24));
      expect(manifest['generatedCount'], 24);
      expect(manifest['parserCalls'], 0);
      expect(manifest['liveServicesAllowed'], isFalse);
      expect(manifest['generationSeed'], contains('fixture-generator-v1'));
      expect(manifest['riskTags'].toString(), contains('generated_batch'));
      expect(_riskTags(manifest), containsAll(_sourceModalityRiskTags));
      expect(fixtures.first['sourceType'], 'synthetic');
      expect(fixtures.first['reviewStatus'], 'generated-not-release-approved');
      expect(fixtures.any((entry) => entry['expectUnknown'] == true), isTrue);
    },
  );

  test('fixture generator writes Spanish locale cases separately', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_es_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      ['--locale', 'es-US', '--limit', '12', '--output-dir', output.path],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final fixtureFile = File(
      '${output.path}/work_supply_parser/plumbing/residential/core/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(12));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
    expect(
      fixtures.map((entry) => entry['rawLine'].toString()).join(' '),
      contains('CODO'),
    );
  });

  test('fixture generator supports top residential core trades', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_trades_',
    );
    addTearDown(() => output.delete(recursive: true));

    for (final trade in ['plumbing', 'electrical', 'hvac']) {
      for (final locale in ['en-US', 'es-US']) {
        final exit = await runWorkSupplyParserFixtureGenerator(
          [
            '--trade',
            trade,
            '--scope',
            'residential',
            '--tier',
            'core',
            '--locale',
            locale,
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
          '${output.path}/work_supply_parser/$trade/residential/core/$locale/'
          'generated_fixtures.json',
        );
        final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
        expect(fixtures, hasLength(24));
        expect(fixtures.first['sourceType'], 'synthetic');
        expect(fixtures.any((entry) => entry['expectUnknown'] == true), isTrue);
      }
    }
  });

  test('fixture generator covers release-one Core service families', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_core_service_families_',
    );
    addTearDown(() => output.delete(recursive: true));

    const expectedFixtureSlugs = {
      'plumbing': [
        'toilet_fill_valve',
        'lavatory_p_trap',
        'water_softener_salt',
        'well_pressure_switch',
      ],
      'electrical': [
        'gfci_receptacle',
        'single_pole_breaker',
        'lever_connector',
        'anti_short_bushing',
      ],
      'hvac': [
        'dual_run_capacitor',
        'hvac_contactor',
        'condensate_pump',
        'flame_sensor',
        'humidifier_water_panel',
      ],
    };

    for (final entry in expectedFixtureSlugs.entries) {
      final exit = await runWorkSupplyParserFixtureGenerator(
        [
          '--trade',
          entry.key,
          '--scope',
          'residential',
          '--tier',
          'core',
          '--locale',
          'en-US',
          '--limit',
          '140',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0, reason: entry.key);
      final fixtureFile = File(
        '${output.path}/work_supply_parser/${entry.key}/residential/core/'
        'en-US/generated_fixtures.json',
      );
      final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
      final ids = fixtures
          .map((entry) => (entry as Map)['id'].toString())
          .join(' ');

      for (final slug in entry.value) {
        expect(
          ids,
          contains(slug),
          reason: '${entry.key} Core generated fixtures must exercise $slug.',
        );
      }
    }
  });

  test('fixture generator rejects unsafe empty batches', () async {
    final stderr = _MemorySink();
    final exit = await runWorkSupplyParserFixtureGenerator(
      ['--limit', '0'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 64);
    expect(stderr.content, contains('--limit must be greater than zero'));
  });

  test('fixture generator supports plumbing standard tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_standard_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'plumbing',
        '--scope',
        'residential',
        '--tier',
        'standard',
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
      '${output.path}/work_supply_parser/plumbing/residential/standard/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(28));
    expect(_fixtureIds(fixtures), contains('perno_sanitario'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator supports electrical standard spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_electrical_standard_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'electrical',
        '--scope',
        'residential',
        '--tier',
        'standard',
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
      '${output.path}/work_supply_parser/electrical/residential/standard/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(28));
    expect(_fixtureIds(fixtures), contains('receptaculo_gfci'));
    expect(_fixtureIds(fixtures), contains('abrazadera_tierra'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator supports hvac standard spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_hvac_standard_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'hvac',
        '--scope',
        'residential',
        '--tier',
        'standard',
        '--locale',
        'es-US',
        '--limit',
        '22',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    final fixtureFile = File(
      '${output.path}/work_supply_parser/hvac/residential/standard/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(22));
    expect(fixtures.toString(), contains('BOMBA COND'));
    expect(fixtures.toString(), contains('DUCTO FLEX'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator supports hvac professional spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_hvac_professional_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'hvac',
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
      '${output.path}/work_supply_parser/hvac/residential/professional/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(24));
    expect(fixtures.toString(), contains('SENSOR FLAMA'));
    expect(fixtures.toString(), contains('AISLAMIENTO LINEA'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator supports hvac complete spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_hvac_complete_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'hvac',
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
      '${output.path}/work_supply_parser/hvac/residential/complete/es-US/'
      'generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(28));
    expect(fixtures.toString(), contains('SWITCH FLOTADOR'));
    expect(fixtures.toString(), contains('TARJETA DESCONGELAR'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test(
    'fixture generator supports plumbing professional spanish tier',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_professional_',
      );
      addTearDown(() => output.delete(recursive: true));

      final exit = await runWorkSupplyParserFixtureGenerator(
        [
          '--trade',
          'plumbing',
          '--scope',
          'residential',
          '--tier',
          'professional',
          '--locale',
          'es-US',
          '--limit',
          '18',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final fixtureFile = File(
        '${output.path}/work_supply_parser/plumbing/residential/professional/'
        'es-US/generated_fixtures.json',
      );
      final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
      expect(fixtures, hasLength(18));
      expect(fixtures.toString(), contains('TRAMPA P'));
      expect(fixtures.toString(), contains('MANGUERA LAVANDERIA'));
      expect(
        fixtures.every((entry) => entry['localePackId'] == 'es-US'),
        isTrue,
      );
    },
  );

  test('fixture generator supports plumbing complete spanish tier', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_complete_',
    );
    addTearDown(() => output.delete(recursive: true));

    final exit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        'plumbing',
        '--scope',
        'residential',
        '--tier',
        'complete',
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
      '${output.path}/work_supply_parser/plumbing/residential/complete/'
      'es-US/generated_fixtures.json',
    );
    final fixtures = jsonDecode(fixtureFile.readAsStringSync()) as List;
    expect(fixtures, hasLength(24));
    expect(fixtures.toString(), contains('TAPON CLEANOUT'));
    expect(fixtures.toString(), contains('VALVULA PRV'));
    expect(fixtures.every((entry) => entry['localePackId'] == 'es-US'), isTrue);
  });

  test('fixture generator rejects unsupported tier cells', () async {
    final stderr = _MemorySink();
    final exit = await runWorkSupplyParserFixtureGenerator(
      ['--trade', 'garage', '--scope', 'residential', '--tier', 'standard'],
      stdout: _MemorySink(),
      stderr: stderr,
    );

    expect(exit, 65);
    expect(stderr.content, contains('trade=garage'));
    expect(stderr.content, contains('tier=standard'));
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

const _sourceModalityRiskTags = {
  'photo_ocr_text_after_extraction',
  'uploaded_pdf_text_after_extraction',
  'emailed_receipt_text_after_extraction',
  'manual_pasted_receipt_text',
  'invoice_style_material_line_text',
  'quote_style_material_line_text',
  'packing_slip_material_list_text',
  'counter_sale_material_receipt_text',
  'generic_unknown_merchant_receipt_text',
  'local_regional_supplier_receipt_text',
};

Set<String> _riskTags(Map manifest) {
  final raw = manifest['riskTags'];
  if (raw is! List) return const {};
  return raw.map((value) => value.toString()).toSet();
}

String _fixtureIds(List fixtures) {
  return fixtures.map((entry) => (entry as Map)['id'].toString()).join(' ');
}
