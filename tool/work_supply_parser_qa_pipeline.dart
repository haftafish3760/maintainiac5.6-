import 'dart:convert';
import 'dart:io';

import 'work_supply_catalog_blueprint_generator.dart';
import 'work_supply_catalog_blueprint_validate.dart';
import 'work_supply_parser_qa_pipeline_artifacts.dart';
import 'work_supply_parser_qa_generate_fixtures.dart';

const _usage =
    'dart run tool/work_supply_parser_qa_pipeline.dart '
    '[--trade plumbing] [--scope residential] [--tier core] '
    '[--locale en-US] [--locales en-US,es-US] [--limit 500] '
    '[--fixture-run-limit 50] [--execute] [--resume] '
    '[--run-fixtures]';

Future<void> main(List<String> args) async {
  final exit = await runWorkSupplyParserQaPipeline(
    args,
    stdout: stdout,
    stderr: stderr,
  );
  if (exit != 0) exitCode = exit;
}

Future<int> runWorkSupplyParserQaPipeline(
  List<String> args, {
  required IOSink stdout,
  required IOSink stderr,
}) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return 0;
  }
  final options = _PipelineOptions.parse(args);
  if (options.limit <= 0) {
    stderr.writeln('--limit must be greater than zero.');
    return 64;
  }
  final unsupported = _unsupportedCells(options);
  if (unsupported.isNotEmpty) {
    stderr.writeln(
      'Unsupported parser QA matrix cells: ${unsupported.join(', ')}.',
    );
    return 65;
  }
  if (options.locales.length > 1) {
    return _runMultiLocalePipeline(
      options: options,
      stdout: stdout,
      stderr: stderr,
    );
  }

  final blueprintOutput = '${options.outputRoot}/blueprints';
  final fixtureOutput = '${options.outputRoot}/fixtures';
  final reportOutput = '${options.outputRoot}/reports';
  final pipelineReportOutput = '${options.outputRoot}/pipeline_reports';
  final blueprintPath =
      '$blueprintOutput/work_supply_catalog/${options.trade}/'
      '${options.scope}/${options.tier}/${options.locale}/item_blueprints.json';
  final fixturePath =
      '$fixtureOutput/work_supply_parser/${options.trade}/'
      '${options.scope}/${options.tier}/${options.locale}/generated_fixtures.json';

  final steps = <Map<String, Object?>>[
    _step(
      name: 'generate_catalog_blueprints',
      command: [
        'dart',
        'run',
        'tool/work_supply_catalog_blueprint_generator.dart',
        '--trade',
        options.trade,
        '--scope',
        options.scope,
        '--tier',
        options.tier,
        '--locale',
        options.locale,
        '--limit',
        '${options.limit}',
        '--output-dir',
        blueprintOutput,
      ],
      willExecute:
          options.execute && !_existsWhenResuming(options, blueprintPath),
    ),
    _step(
      name: 'validate_catalog_blueprints',
      command: [
        'dart',
        'run',
        'tool/work_supply_catalog_blueprint_validate.dart',
        '--input',
        blueprintPath,
      ],
      willExecute: options.execute,
    ),
    _step(
      name: 'generate_parser_fixtures',
      command: [
        'dart',
        'run',
        'tool/work_supply_parser_qa_generate_fixtures.dart',
        '--trade',
        options.trade,
        '--scope',
        options.scope,
        '--tier',
        options.tier,
        '--locale',
        options.locale,
        '--limit',
        '${options.limit}',
        '--output-dir',
        fixtureOutput,
      ],
      willExecute:
          options.execute && !_existsWhenResuming(options, fixturePath),
    ),
    _step(
      name: 'run_generated_parser_fixtures',
      command: [
        'flutter',
        'test',
        'test/work_supply_parser_generated_fixture_runner_test.dart',
        '--dart-define=PARSER_QA_GENERATED_FIXTURE_PATH=$fixturePath',
        '--dart-define=PARSER_QA_GENERATED_FIXTURE_MAX_CASES=${options.fixtureRunLimit}',
        '--dart-define=PARSER_QA_GENERATED_REPORT_DIR=$reportOutput',
        '--reporter',
        'compact',
      ],
      willExecute: options.execute && options.runFixtures,
    ),
  ];

  var failed = false;
  var reusedBlueprints = false;
  var reusedFixtures = false;
  if (options.execute) {
    final execution = await _executeLocalGenerationSteps(
      options: options,
      stdout: stdout,
      stderr: stderr,
      blueprintOutput: blueprintOutput,
      fixtureOutput: fixtureOutput,
      blueprintPath: blueprintPath,
      fixturePath: fixturePath,
    );
    failed = execution.failed;
    reusedBlueprints = execution.reusedBlueprints;
    reusedFixtures = execution.reusedFixtures;
    if (!failed && options.runFixtures) {
      final command = (steps.last['command'] as List).cast<String>();
      final result = await Process.run(
        command.first,
        command.skip(1).toList(),
        runInShell: Platform.isWindows,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      failed = result.exitCode != 0;
    }
  }

  final summary = {
    'schemaVersion': 1,
    'pipeline': 'work_supply_parser_qa_pipeline',
    'trade': options.trade,
    'marketScope': options.scope,
    'tier': options.tier,
    'localePackId': options.locale,
    'limit': options.limit,
    'fixtureRunLimit': options.fixtureRunLimit,
    'dryRun': !options.execute,
    'resume': options.resume,
    'runFixtures': options.runFixtures,
    'reusedBlueprints': reusedBlueprints,
    'reusedFixtures': reusedFixtures,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'blueprintPath': blueprintPath,
    'fixturePath': fixturePath,
    'reportOutput': reportOutput,
    'steps': steps,
  };
  final artifact = writePipelineSummary(
    outputDirectory: pipelineReportOutput,
    summary: summary,
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE_ARTIFACT '
    'json=${artifact.timestampedJsonPath} latestJson=${artifact.latestJsonPath}',
  );
  return failed ? 1 : 0;
}

Future<int> _runMultiLocalePipeline({
  required _PipelineOptions options,
  required IOSink stdout,
  required IOSink stderr,
}) async {
  final results = <Map<String, Object?>>[];
  var failed = false;
  for (final locale in options.locales) {
    final localeOutput = _matrixOutputRoot(options, locale);
    final args = [
      if (options.execute) '--execute',
      if (options.resume) '--resume',
      if (options.runFixtures) '--run-fixtures',
      '--trade',
      options.trade,
      '--scope',
      options.scope,
      '--tier',
      options.tier,
      '--locale',
      locale,
      '--limit',
      '${options.limit}',
      '--fixture-run-limit',
      '${options.fixtureRunLimit}',
      '--output-root',
      localeOutput,
    ];
    final exit = await runWorkSupplyParserQaPipeline(
      args,
      stdout: stdout,
      stderr: stderr,
    );
    results.add({
      'localePackId': locale,
      'exitCode': exit,
      'outputRoot': localeOutput,
      'latestPipelineSummary':
          '$localeOutput/pipeline_reports/latest_pipeline_summary.json',
    });
    if (exit != 0) failed = true;
  }
  final summary = {
    'schemaVersion': 1,
    'pipeline': 'work_supply_parser_qa_pipeline_multi_locale',
    'trade': options.trade,
    'marketScope': options.scope,
    'tier': options.tier,
    'localePackIds': options.locales,
    'limit': options.limit,
    'fixtureRunLimit': options.fixtureRunLimit,
    'dryRun': !options.execute,
    'resume': options.resume,
    'runFixtures': options.runFixtures,
    'liveServicesAllowed': false,
    'writesProductionCatalog': false,
    'firebaseWritesAllowed': false,
    'results': results,
  };
  final artifact = writePipelineSummary(
    outputDirectory: '${options.outputRoot}/pipeline_reports',
    summary: summary,
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE_MULTI_LOCALE '
    '${const JsonEncoder.withIndent('  ').convert(summary)}',
  );
  stdout.writeln(
    'QA_ECONOMICAL_PIPELINE_ARTIFACT '
    'json=${artifact.timestampedJsonPath} latestJson=${artifact.latestJsonPath}',
  );
  return failed ? 1 : 0;
}

String _matrixOutputRoot(_PipelineOptions options, String locale) {
  return '${options.outputRoot}/${options.trade}/${options.scope}/'
      '${options.tier}/$locale';
}

Future<_PipelineExecution> _executeLocalGenerationSteps({
  required _PipelineOptions options,
  required IOSink stdout,
  required IOSink stderr,
  required String blueprintOutput,
  required String fixtureOutput,
  required String blueprintPath,
  required String fixturePath,
}) async {
  var reusedBlueprints = false;
  var reusedFixtures = false;
  if (options.resume && File(blueprintPath).existsSync()) {
    reusedBlueprints = true;
    stdout.writeln('QA_PIPELINE_RESUME reusedBlueprints=$blueprintPath');
  } else {
    final blueprintExit = await runWorkSupplyCatalogBlueprintGenerator(
      [
        '--trade',
        options.trade,
        '--scope',
        options.scope,
        '--tier',
        options.tier,
        '--locale',
        options.locale,
        '--limit',
        '${options.limit}',
        '--output-dir',
        blueprintOutput,
      ],
      stdout: stdout,
      stderr: stderr,
    );
    if (blueprintExit != 0) {
      return _PipelineExecution(failed: true);
    }
  }
  final validateExit = await runWorkSupplyCatalogBlueprintValidator(
    ['--input', blueprintPath],
    stdout: stdout,
    stderr: stderr,
  );
  if (validateExit != 0) {
    return _PipelineExecution(failed: true, reusedBlueprints: reusedBlueprints);
  }
  if (options.resume && File(fixturePath).existsSync()) {
    reusedFixtures = true;
    stdout.writeln('QA_PIPELINE_RESUME reusedFixtures=$fixturePath');
  } else {
    final fixtureExit = await runWorkSupplyParserFixtureGenerator(
      [
        '--trade',
        options.trade,
        '--scope',
        options.scope,
        '--tier',
        options.tier,
        '--locale',
        options.locale,
        '--limit',
        '${options.limit}',
        '--output-dir',
        fixtureOutput,
      ],
      stdout: stdout,
      stderr: stderr,
    );
    if (fixtureExit != 0) {
      return _PipelineExecution(
        failed: true,
        reusedBlueprints: reusedBlueprints,
      );
    }
  }
  return _PipelineExecution(
    failed: false,
    reusedBlueprints: reusedBlueprints,
    reusedFixtures: reusedFixtures,
  );
}

bool _existsWhenResuming(_PipelineOptions options, String path) {
  return options.resume && File(path).existsSync();
}

List<String> _unsupportedCells(_PipelineOptions options) {
  final cells = <String>[];
  for (final locale in options.locales) {
    final supportedCell =
        (options.trade == 'plumbing' &&
            (options.tier == 'core' ||
                options.tier == 'standard' ||
                options.tier == 'professional' ||
                options.tier == 'complete')) ||
        (options.trade == 'electrical' &&
            (options.tier == 'core' ||
                options.tier == 'standard' ||
                options.tier == 'professional' ||
                options.tier == 'complete')) ||
        (options.trade == 'hvac' &&
            (options.tier == 'core' ||
                options.tier == 'standard' ||
                options.tier == 'professional' ||
                options.tier == 'complete'));
    final supportedLocale = const {'en-US', 'es-US'}.contains(locale);
    if (!supportedCell || options.scope != 'residential' || !supportedLocale) {
      cells.add('${options.trade}/${options.scope}/${options.tier}/$locale');
    }
  }
  return cells;
}

class _PipelineExecution {
  const _PipelineExecution({
    required this.failed,
    this.reusedBlueprints = false,
    this.reusedFixtures = false,
  });

  final bool failed;
  final bool reusedBlueprints;
  final bool reusedFixtures;
}

Map<String, Object?> _step({
  required String name,
  required List<String> command,
  required bool willExecute,
}) {
  return {'name': name, 'command': command, 'willExecute': willExecute};
}

class _PipelineOptions {
  const _PipelineOptions({
    required this.trade,
    required this.scope,
    required this.tier,
    required this.locale,
    required this.locales,
    required this.limit,
    required this.fixtureRunLimit,
    required this.outputRoot,
    required this.execute,
    required this.resume,
    required this.runFixtures,
  });

  final String trade;
  final String scope;
  final String tier;
  final String locale;
  final List<String> locales;
  final int limit;
  final int fixtureRunLimit;
  final String outputRoot;
  final bool execute;
  final bool resume;
  final bool runFixtures;

  static _PipelineOptions parse(List<String> args) {
    final values = <String, String>{};
    final flags = <String>{};
    for (var index = 0; index < args.length; index++) {
      final arg = args[index];
      if (!arg.startsWith('--')) continue;
      final keyValue = arg.substring(2).split('=');
      if (keyValue.length == 2) {
        values[keyValue[0]] = keyValue[1];
      } else if (index + 1 < args.length && !args[index + 1].startsWith('--')) {
        values[keyValue[0]] = args[++index];
      } else {
        flags.add(keyValue[0]);
      }
    }
    return _PipelineOptions(
      trade: (values['trade'] ?? 'plumbing').toLowerCase(),
      scope: (values['scope'] ?? 'residential').toLowerCase(),
      tier: (values['tier'] ?? 'core').toLowerCase(),
      locale: values['locale'] ?? _parseLocales(values).first,
      locales: _parseLocales(values),
      limit: int.tryParse(values['limit'] ?? '') ?? 500,
      fixtureRunLimit:
          int.tryParse(values['fixture-run-limit'] ?? '') ??
          int.tryParse(values['limit'] ?? '') ??
          500,
      outputRoot: values['output-root'] ?? 'build/parser_qa_pipeline',
      execute: flags.contains('execute'),
      resume: flags.contains('resume'),
      runFixtures: flags.contains('run-fixtures'),
    );
  }

  static List<String> _parseLocales(Map<String, String> values) {
    final csv = values['locales'] ?? values['locale'] ?? 'en-US';
    final locales = csv
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
    return locales.isEmpty ? const ['en-US'] : locales;
  }
}
