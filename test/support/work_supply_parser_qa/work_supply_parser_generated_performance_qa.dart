import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserGeneratedPerformanceSuite extends QaSuite {
  const WorkSupplyParserGeneratedPerformanceSuite()
    : super('inventory.generated_fixture_performance_contract');

  static const _contracts = [
    _GeneratedPerformanceContract(
      name: 'runner_artifact_fields',
      path: 'test/work_supply_parser_generated_fixture_runner_test.dart',
      tokens: [
        'latest_generated_fixture_run.json',
        'warmupMs',
        'semanticTimingExcludesWarmup',
        'slowestCases',
        'parserCalls',
      ],
    ),
    _GeneratedPerformanceContract(
      name: 'runner_knobs',
      path: 'tool/work_supply_parser_qa_run_generated_fixtures.dart',
      tokens: ['--fixture', '--max-cases', '--fixture-ids', '--report-dir'],
    ),
    _GeneratedPerformanceContract(
      name: 'runner_local_only',
      path: 'test/work_supply_parser_generated_fixture_runner_test.dart',
      tokens: ['liveServicesAllowed', 'build/parser_qa_reports'],
    ),
    _GeneratedPerformanceContract(
      name: 'runner_wrapper_status',
      path: 'tool/work_supply_parser_qa_run_generated_fixtures.dart',
      tokens: [
        'QA_GENERATED_FIXTURE_RUN_WRAPPER',
        'runner=flutter-test',
        'parser_core_not_yet_extracted_for_dart_cli',
      ],
    ),
    _GeneratedPerformanceContract(
      name: 'docs_generated_performance_artifact',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: [
        'latest_generated_fixture_run.json',
        '--report-dir',
        'parser_core_not_yet_extracted_for_dart_cli',
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final cache = <String, String>{};
    final present = <String>[];
    var checked = 0;

    for (final contract in _contracts) {
      final source = _read(contract.path, failures, cache);
      checked += contract.tokens.length;
      final missing = [
        for (final token in contract.tokens)
          if (!_containsContractToken(source, token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_generated_performance_contract:${contract.name}',
          message:
              'Generated fixture performance artifact contract is missing.',
          severity: QaSeverity.error,
          expected: contract.tokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep generated batch reports reproducible, local-only, and useful for slow-family triage.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + cache.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'parserCallsInSmoke': 0,
        'artifactOnlyContract': true,
        'filesScanned': cache.keys.toList()..sort(),
      },
    );
  }

  String _read(
    String path,
    List<QaFailure> failures,
    Map<String, String> cache,
  ) {
    final cached = cache[path];
    if (cached != null) return cached;
    final file = File(path);
    if (!file.existsSync()) {
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_generated_performance_file:$path',
          message: 'Generated performance contract scan file is missing.',
          expected: path,
          actual: 'not found',
          suggestedFix:
              'Update this suite if generated fixture runner files move.',
          metadata: const {'triageCategory': QaFailureTriage.schema},
        ),
      );
      cache[path] = '';
      return '';
    }
    final source = file.readAsStringSync();
    cache[path] = source;
    return source;
  }
}

class _GeneratedPerformanceContract {
  const _GeneratedPerformanceContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
