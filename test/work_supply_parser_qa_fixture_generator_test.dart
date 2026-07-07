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
      expect(manifest['ocrCameraExpensesTouched'], isFalse);
      expect(manifest['generationSeed'], contains('fixture-generator-v1'));
      expect(manifest['riskTags'].toString(), contains('generated_batch'));
      expect(_riskTags(manifest), containsAll(_sourceModalityRiskTags));
      expect(fixtures.first['sourceType'], 'synthetic');
      expect(fixtures.first['reviewStatus'], 'generated-not-release-approved');
      expect(fixtures.any((entry) => entry['expectUnknown'] == true), isTrue);
      final ambiguous = fixtures.cast<Map>().firstWhere(
        (entry) => entry['caseType'] == 'ambiguous_review',
      );
      expect(
        ambiguous['tradeScope'],
        isEmpty,
        reason:
            'Ambiguous dangerous-word fixtures must stay unscoped so the '
            'parser cannot become confident from an injected trade context.',
      );
    },
  );

  test(
    'fixture generator covers merchant-agnostic release-one families',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_merchant_families_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '170',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      final generatedRoot = Directory(
        '${output.path}/work_supply_parser/plumbing/residential/core/en-US',
      );
      final manifest =
          jsonDecode(
                File('${generatedRoot.path}/manifest.json').readAsStringSync(),
              )
              as Map;
      final merchants = (manifest['merchants'] as List)
          .map((entry) => entry.toString())
          .toSet();
      final tags = _riskTags(manifest);

      expect(
        merchants,
        containsAll({
          'Tractor Supply',
          'Northern Tool',
          'Electrical Supply House',
          'HVAC Supply House',
          'Plumbing Supply House',
          'Regional Supplier',
          'Counter Sale',
          'Local Hardware',
          'unknown',
        }),
      );
      expect(
        tags,
        containsAll({
          'tractor_supply_style',
          'northern_tool_style',
          'electrical_supply_house_style',
          'hvac_supply_house_style',
          'plumbing_supply_house_style',
          'regional_supplier_style',
          'counter_sale_style',
          'local_hardware_style',
          'unknown_merchant_style',
        }),
      );
      expect(tags, contains('supply_house'));
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

  test('fixture generator can isolate one Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_family_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '64',
        '--include-risk-tags',
        'tubular',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(64));
    expect(manifest['includeRiskTags'], ['tubular']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('lavatory_p_trap'));
    expect(ids, contains('tubular_tailpiece'));
    expect(ids, contains('tubular_extension_tube'));
    expect(ids, contains('slip_joint_nut_washer'));
    expect(ids, contains('beveled_washer_pack'));
    expect(ids, contains('basket_strainer'));
    expect(ids, contains('brass_j_bend'));
    expect(ids, contains('flanged_tailpiece'));
    expect(_riskTags(manifest), contains('tubular'));
    expect(_riskTags(manifest), isNot(contains('water_treatment')));
  });

  test('fixture generator can isolate CPVC Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_cpvc_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '30',
        '--include-risk-tags',
        'cpvc',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(30));
    expect(manifest['includeRiskTags'], ['cpvc']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('cpvc_elbow'));
    expect(ids, contains('cpvc_coupling'));
    expect(ids, contains('cpvc_adapter'));
    expect(ids, contains('cpvc_tee'));
    expect(ids, contains('cpvc_reducer_bushing'));
    expect(_riskTags(manifest), contains('cpvc'));
    expect(_riskTags(manifest), isNot(contains('tubular')));
  });

  test(
    'fixture generator can isolate legacy repair Plumbing Core family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_legacy_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '25',
          '--include-risk-tags',
          'legacy_repair',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(25));
      expect(manifest['includeRiskTags'], ['legacy_repair']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('compression_trap_adapter'));
      expect(ids, contains('desanco_adapter'));
      expect(ids, contains('marvel_adapter'));
      expect(ids, contains('wall_bend_adapter'));
      expect(ids, contains('trap_arm_adapter'));
      expect(_riskTags(manifest), contains('legacy_repair'));
      expect(_riskTags(manifest), isNot(contains('cpvc')));
    },
  );

  test('fixture generator can isolate copper Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_copper_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '42',
        '--include-risk-tags',
        'copper',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(42));
    expect(manifest['includeRiskTags'], ['copper']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('copper_elbow'));
    expect(ids, contains('copper_coupling'));
    expect(ids, contains('copper_repair_coupling'));
    expect(ids, contains('copper_adapter'));
    expect(ids, contains('copper_tee'));
    expect(ids, contains('copper_dielectric_union'));
    expect(ids, contains('copper_bell_hanger'));
    expect(_riskTags(manifest), contains('copper'));
    expect(_riskTags(manifest), isNot(contains('legacy_repair')));
  });

  test(
    'fixture generator can isolate PVC pressure Plumbing Core family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_pvc_pressure_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '42',
          '--include-risk-tags',
          'pvc_pressure',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(42));
      expect(manifest['includeRiskTags'], ['pvc_pressure']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('pvc_schedule_40_elbow'));
      expect(ids, contains('pvc_schedule_40_adapter'));
      expect(ids, contains('pvc_schedule_40_tee'));
      expect(ids, contains('pvc_schedule_40_reducer_bushing'));
      expect(ids, contains('pvc_schedule_40_reducing_coupling'));
      expect(_riskTags(manifest), contains('pvc_pressure'));
      expect(_riskTags(manifest), isNot(contains('copper')));
    },
  );

  test('fixture generator can isolate PEX Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_pex_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '77',
        '--include-risk-tags',
        'pex',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(77));
    expect(manifest['includeRiskTags'], ['pex']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('pex_crimp_elbow'));
    expect(ids, contains('pex_coupling'));
    expect(ids, contains('pex_transition_coupling'));
    expect(ids, contains('pex_male_adapter'));
    expect(ids, contains('pex_female_adapter'));
    expect(ids, contains('pex_tee'));
    expect(ids, contains('pex_drop_ear_elbow'));
    expect(ids, contains('pex_crimp_ring'));
    expect(ids, contains('pex_clamp_ring'));
    expect(ids, contains('pex_crimp_tool'));
    expect(ids, contains('pex_cinch_tool'));
    expect(_riskTags(manifest), contains('pex'));
    expect(_riskTags(manifest), isNot(contains('pvc_pressure')));
  });

  test('fixture generator can isolate PVC DWV Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_pvc_dwv_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '95',
        '--include-risk-tags',
        'pvc_dwv',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(95));
    expect(manifest['includeRiskTags'], ['pvc_dwv']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('pvc_dwv_90_elbow'));
    expect(ids, contains('pvc_dwv_45_elbow'));
    expect(ids, contains('pvc_dwv_wye'));
    expect(ids, contains('pvc_dwv_sanitary_tee'));
    expect(ids, contains('pvc_dwv_reducing_sanitary_tee'));
    expect(ids, contains('pvc_dwv_coupling'));
    expect(ids, contains('pvc_dwv_reducing_coupling'));
    expect(ids, contains('pvc_dwv_trap_adapter'));
    expect(ids, contains('pvc_dwv_cleanout'));
    expect(ids, contains('pvc_dwv_test_tee'));
    expect(ids, contains('cleanout_access_plug'));
    expect(ids, contains('cleanout_access_cover'));
    expect(_riskTags(manifest), contains('pvc_dwv'));
    expect(_riskTags(manifest), isNot(contains('pex')));
  });

  test(
    'fixture generator can isolate sump discharge Plumbing Core family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_sump_discharge_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '8',
          '--include-risk-tags',
          'sump_discharge',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(8));
      expect(manifest['includeRiskTags'], ['sump_discharge']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('sump_discharge_hose_kit'));
      expect(ids, contains('sump_rubber_coupling'));
      expect(ids, contains('sump_pvc_adapter'));
      expect(ids, contains('sump_barbed_adapter'));
      expect(_riskTags(manifest), contains('sump_discharge'));
      expect(_riskTags(manifest), isNot(contains('pvc_dwv')));
    },
  );

  test('fixture generator can isolate brass Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_brass_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '26',
        '--include-risk-tags',
        'brass_fittings',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(26));
    expect(manifest['includeRiskTags'], ['brass_fittings']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('brass_male_adapter'));
    expect(ids, contains('brass_female_adapter'));
    expect(ids, contains('brass_bushing'));
    expect(ids, contains('brass_compression_adapter'));
    expect(ids, contains('brass_compression_union'));
    expect(ids, contains('brass_flare_fitting'));
    expect(ids, contains('brass_barb_fitting'));
    expect(_riskTags(manifest), contains('brass_fittings'));
    expect(_riskTags(manifest), isNot(contains('sump_discharge')));
  });

  test(
    'fixture generator can isolate pipe supports Plumbing Core family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_pipe_support_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '26',
          '--include-risk-tags',
          'pipe_supports',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(26));
      expect(manifest['includeRiskTags'], ['pipe_supports']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('pipe_support_strap'));
      expect(ids, contains('pipe_support_split_ring'));
      expect(ids, contains('pipe_support_bell_hanger'));
      expect(ids, contains('pipe_support_stud_guard'));
      expect(ids, contains('pipe_support_insulation'));
      expect(_riskTags(manifest), contains('pipe_supports'));
      expect(_riskTags(manifest), isNot(contains('brass_fittings')));
    },
  );

  test('fixture generator can isolate valve Plumbing Core family', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_fixture_generator_plumbing_valve_filter_',
    );
    addTearDown(() => output.delete(recursive: true));

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
        '43',
        '--include-risk-tags',
        'general_valves',
        '--output-dir',
        output.path,
      ],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );

    expect(exit, 0);
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

    expect(fixtures, hasLength(43));
    expect(manifest['includeRiskTags'], ['general_valves']);
    final ids = _fixtureIds(fixtures);
    expect(ids, contains('general_pvc_ball_valve'));
    expect(ids, contains('general_threaded_ball_valve'));
    expect(ids, contains('general_ball_valve'));
    expect(ids, contains('general_gate_valve'));
    expect(ids, contains('general_check_valve'));
    expect(ids, contains('general_pressure_reducing_valve'));
    expect(ids, contains('general_hose_bibb'));
    expect(ids, contains('general_frost_free_sillcock'));
    expect(ids, contains('general_vacuum_breaker'));
    expect(ids, contains('general_hose_bibb_repair'));
    expect(_riskTags(manifest), contains('general_valves'));
    expect(_riskTags(manifest), isNot(contains('pipe_supports')));
  });

  test(
    'fixture generator can isolate water heater Plumbing Core family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_water_heater_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '56',
          '--include-risk-tags',
          'water_heater_service',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(56));
      expect(manifest['includeRiskTags'], ['water_heater_service']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('water_heater_connector'));
      expect(ids, contains('water_heater_element'));
      expect(ids, contains('water_heater_thermostat'));
      expect(ids, contains('water_heater_anode_rod'));
      expect(ids, contains('water_heater_drain_pan'));
      expect(ids, contains('water_heater_strap'));
      expect(ids, contains('water_heater_expansion_tank'));
      expect(ids, contains('water_heater_tpr_valve'));
      expect(ids, contains('water_heater_drain_valve'));
      expect(ids, contains('water_heater_dielectric'));
      expect(ids, contains('water_heater_service_fitting'));
      expect(ids, contains('water_heater_install_accessory'));
      expect(_riskTags(manifest), contains('water_heater_service'));
      expect(_riskTags(manifest), isNot(contains('general_valves')));
    },
  );

  test(
    'fixture generator can isolate service consumables and tools family',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_fixture_generator_plumbing_service_tools_filter_',
      );
      addTearDown(() => output.delete(recursive: true));

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
          '77',
          '--include-risk-tags',
          'service_consumables_tools',
          '--output-dir',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: _MemorySink(),
      );

      expect(exit, 0);
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

      expect(fixtures, hasLength(77));
      expect(manifest['includeRiskTags'], ['service_consumables_tools']);
      final ids = _fixtureIds(fixtures);
      expect(ids, contains('service_thread_sealant'));
      expect(ids, contains('service_pipe_joint_compound'));
      expect(ids, contains('service_ptfe_tape'));
      expect(ids, contains('service_pvc_cement'));
      expect(ids, contains('service_pvc_primer'));
      expect(ids, contains('service_plumber_putty'));
      expect(ids, contains('service_pipe_j_hook'));
      expect(ids, contains('service_pex_tool'));
      expect(ids, contains('service_press_jaw'));
      expect(ids, contains('service_pipe_cutter'));
      expect(ids, contains('service_deburr_reamer'));
      expect(ids, contains('service_wrench'));
      expect(ids, contains('service_auger_snake'));
      expect(ids, contains('service_hole_saw'));
      expect(ids, contains('service_recip_blade'));
      expect(_riskTags(manifest), contains('service_consumables_tools'));
      expect(_riskTags(manifest), isNot(contains('water_heater_service')));
    },
  );

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
