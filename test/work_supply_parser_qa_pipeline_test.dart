import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../tool/work_supply_parser_qa_pipeline.dart';

void main() {
  test('economical pipeline dry-run plans every local step safely', () async {
    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaPipeline(
      ['--limit', '12'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE'));
    expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_ARTIFACT'));
    expect(stdout.content, contains('"dryRun": true'));
    expect(stdout.content, contains('"liveServicesAllowed": false'));
    expect(stdout.content, contains('"writesProductionCatalog": false'));
    expect(stdout.content, contains('generate_catalog_blueprints'));
    expect(stdout.content, contains('validate_catalog_blueprints'));
    expect(stdout.content, contains('generate_parser_fixtures'));
    expect(stdout.content, contains('run_generated_parser_fixtures'));
    expect(stdout.content, contains('"willExecute": false'));
  });

  test(
    'economical pipeline execute creates and validates local artifacts',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stdout = _MemorySink();
      final stderr = _MemorySink();
      final exit = await runWorkSupplyParserQaPipeline(
        ['--execute', '--limit', '10', '--output-root', output.path],
        stdout: stdout,
        stderr: stderr,
      );

      expect(exit, 0, reason: stderr.content);
      expect(stdout.content, contains('QA_CATALOG_BLUEPRINTS'));
      expect(stdout.content, contains('QA_CATALOG_BLUEPRINT_VALIDATION'));
      expect(stdout.content, contains('QA_GENERATED_FIXTURES'));
      expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_ARTIFACT'));
      expect(stdout.content, contains('"runFixtures": false'));

      final blueprintFile = File(
        '${output.path}/blueprints/work_supply_catalog/plumbing/residential/'
        'core/en-US/item_blueprints.json',
      );
      final fixtureFile = File(
        '${output.path}/fixtures/work_supply_parser/plumbing/residential/core/'
        'en-US/generated_fixtures.json',
      );
      expect(blueprintFile.existsSync(), isTrue);
      expect(fixtureFile.existsSync(), isTrue);
      final latestSummary = File(
        '${output.path}/pipeline_reports/latest_pipeline_summary.json',
      );
      expect(latestSummary.existsSync(), isTrue);
      final summary = jsonDecode(latestSummary.readAsStringSync()) as Map;
      expect(summary['liveServicesAllowed'], isFalse);
      expect(summary['writesProductionCatalog'], isFalse);
      expect(summary['dryRun'], isFalse);
      expect(summary['runFixtures'], isFalse);
    },
  );

  test('economical pipeline resume reuses existing local artifacts', () async {
    final output = await Directory.systemTemp.createTemp(
      'maintainiac_parser_pipeline_resume_',
    );
    addTearDown(() => output.delete(recursive: true));

    final firstExit = await runWorkSupplyParserQaPipeline(
      ['--execute', '--limit', '6', '--output-root', output.path],
      stdout: _MemorySink(),
      stderr: _MemorySink(),
    );
    expect(firstExit, 0);

    final stdout = _MemorySink();
    final secondExit = await runWorkSupplyParserQaPipeline(
      ['--execute', '--resume', '--limit', '6', '--output-root', output.path],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(secondExit, 0);
    expect(stdout.content, contains('QA_PIPELINE_RESUME reusedBlueprints='));
    expect(stdout.content, contains('QA_PIPELINE_RESUME reusedFixtures='));
    expect(stdout.content, contains('"resume": true'));
    expect(stdout.content, contains('"reusedBlueprints": true'));
    expect(stdout.content, contains('"reusedFixtures": true'));
    expect(stdout.content, contains('QA_CATALOG_BLUEPRINT_VALIDATION'));
  });

  test('economical pipeline can cap parser fixture runs separately', () async {
    final stdout = _MemorySink();
    final exit = await runWorkSupplyParserQaPipeline(
      ['--run-fixtures', '--limit', '500', '--fixture-run-limit', '25'],
      stdout: stdout,
      stderr: _MemorySink(),
    );

    expect(exit, 0);
    expect(stdout.content, contains('"limit": 500'));
    expect(stdout.content, contains('"fixtureRunLimit": 25'));
    expect(
      stdout.content,
      contains('--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=25'),
    );
  });

  test(
    'economical pipeline supports English and Spanish locales together',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_locales_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stdout = _MemorySink();
      final exit = await runWorkSupplyParserQaPipeline(
        [
          '--execute',
          '--locales',
          'en-US,es-US',
          '--limit',
          '5',
          '--output-root',
          output.path,
        ],
        stdout: stdout,
        stderr: _MemorySink(),
      );

      expect(exit, 0);
      expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_MULTI_LOCALE'));
      expect(stdout.content, contains('"localePackId": "en-US"'));
      expect(stdout.content, contains('"localePackId": "es-US"'));
      expect(stdout.content, contains('"localePackIds":'));
      expect(
        File(
          '${output.path}/plumbing/residential/core/en-US/pipeline_reports/'
          'latest_pipeline_summary.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${output.path}/plumbing/residential/core/es-US/pipeline_reports/'
          'latest_pipeline_summary.json',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          '${output.path}/pipeline_reports/latest_pipeline_summary.json',
        ).existsSync(),
        isTrue,
      );
    },
  );

  test(
    'economical pipeline plans release-one residential priority cells',
    () async {
      const trades = ['plumbing', 'electrical', 'hvac'];
      const tiers = ['core', 'standard'];
      const locales = ['en-US,es-US'];

      for (final trade in trades) {
        for (final tier in tiers) {
          final stdout = _MemorySink();
          final stderr = _MemorySink();
          final exit = await runWorkSupplyParserQaPipeline(
            [
              '--trade',
              trade,
              '--scope',
              'residential',
              '--tier',
              tier,
              '--locales',
              locales.single,
              '--limit',
              '25',
            ],
            stdout: stdout,
            stderr: stderr,
          );

          expect(
            exit,
            0,
            reason: '$trade residential $tier en-US/es-US should be planned.',
          );
          expect(stderr.content, isEmpty);
          expect(stdout.content, contains('QA_ECONOMICAL_PIPELINE_MULTI_LOCALE'));
          expect(stdout.content, contains('"trade": "$trade"'));
          expect(stdout.content, contains('"tier": "$tier"'));
          expect(stdout.content, contains('"localePackId": "en-US"'));
          expect(stdout.content, contains('"localePackId": "es-US"'));
          expect(stdout.content, contains('"liveServicesAllowed": false'));
          expect(stdout.content, contains('"firebaseWritesAllowed": false'));
          expect(stdout.content, contains('"dryRun": true'));
        }
      }
    },
  );

  test(
    'economical pipeline rejects unsupported cells before writing files',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_unsupported_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stderr = _MemorySink();
      final exit = await runWorkSupplyParserQaPipeline(
        [
          '--execute',
          '--trade',
          'garage',
          '--scope',
          'residential',
          '--tier',
          'standard',
          '--locale',
          'en-US',
          '--output-root',
          output.path,
        ],
        stdout: _MemorySink(),
        stderr: stderr,
      );

      expect(exit, 65);
      expect(stderr.content, contains('Unsupported parser QA matrix cells'));
      expect(stderr.content, contains('garage/residential/standard/en-US'));
      expect(Directory('${output.path}/blueprints').existsSync(), isFalse);
      expect(Directory('${output.path}/fixtures').existsSync(), isFalse);
    },
  );

  test(
    'economical pipeline rejects unsupported locales before multi-run',
    () async {
      final output = await Directory.systemTemp.createTemp(
        'maintainiac_parser_pipeline_bad_locale_',
      );
      addTearDown(() => output.delete(recursive: true));

      final stderr = _MemorySink();
      final exit = await runWorkSupplyParserQaPipeline(
        ['--execute', '--locales', 'en-US,fr-CA', '--output-root', output.path],
        stdout: _MemorySink(),
        stderr: stderr,
      );

      expect(exit, 65);
      expect(stderr.content, contains('plumbing/residential/core/fr-CA'));
      expect(Directory('${output.path}/plumbing').existsSync(), isFalse);
    },
  );
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
