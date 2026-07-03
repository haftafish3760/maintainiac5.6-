import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserRuntimeProfileSuite extends QaSuite {
  const WorkSupplyParserRuntimeProfileSuite()
    : super('inventory.runtime_profile_contract');

  static const _parserCallSuites = [
    _RuntimeProfileTarget(
      suite: 'inventory.dangerous_words',
      path: 'test/support/work_supply_parser_qa/work_supply_parser_qa.dart',
      requiredTokens: [
        'matchReceiptLineToCatalog',
        'if (!context.isFullProfile)',
        'Full dangerous-word parser calls run in full/release profiles.',
      ],
    ),
    _RuntimeProfileTarget(
      suite: 'inventory.golden_fixtures',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_fixture_qa.dart',
      requiredTokens: [
        'matchReceiptLineToCatalog',
        'if (!context.isFullProfile)',
        'Full fixture parser assertions run in full/release profiles.',
      ],
    ),
    _RuntimeProfileTarget(
      suite: 'inventory.generated_cases',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_fixture_qa.dart',
      requiredTokens: [
        'matchReceiptLineToCatalog',
        'if (!context.isFullProfile)',
        'catalogConstructionSkipped',
        'Generated parser assertions run in full/release profiles.',
      ],
    ),
    _RuntimeProfileTarget(
      suite: 'inventory.metamorphic_variants',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart',
      requiredTokens: [
        'matchReceiptLineToCatalog',
        'if (!context.isFullProfile)',
        'Parser assertions run in full/release profiles.',
      ],
    ),
    _RuntimeProfileTarget(
      suite: 'inventory.property_cases',
      path:
          'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart',
      requiredTokens: [
        'matchReceiptLineToCatalog',
        'if (!context.isFullProfile)',
        "'parserCalls': 0",
      ],
    ),
  ];

  static const _profileDocs = [
    _RuntimeProfileDocContract('smoke_builds_not_parser_assertions', [
      'Smoke profile',
      'without running the most expensive semantic parser calls',
    ]),
    _RuntimeProfileDocContract('full_runs_semantic_assertions', [
      'Full profile',
      'semantic parser assertions',
    ]),
    _RuntimeProfileDocContract('release_strict_gate', [
      'Release profile plus strict mode',
      'Any accuracy, safety, privacy, or schema failure becomes a test failure',
    ]),
    _RuntimeProfileDocContract('surgical_suite_mode', [
      'PARSER_QA_SUITES',
      'surgical mode',
    ]),
    _RuntimeProfileDocContract('catalog_cold_load_amortization', [
      'catalog-backed suites',
      'amortize the cold catalog load',
      'contract-only suites stay surgical',
    ]),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sourceCache = <String, String>{};
    final presentTargets = <String>[];
    var checked = 0;

    for (final target in _parserCallSuites) {
      final source = _read(target.path, failures, sourceCache);
      checked += target.requiredTokens.length;
      final missing = [
        for (final token in target.requiredTokens)
          if (!source.contains(token)) token,
      ];
      if (missing.isEmpty) {
        presentTargets.add(target.suite);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_runtime_profile_guard:${target.suite}',
          message: 'Parser-call suite is missing its smoke/full profile guard.',
          severity: QaSeverity.error,
          expected: target.requiredTokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Keep smoke profile case-building only; run parser assertions in full/release profiles.',
          metadata: const {'triageCategory': QaFailureTriage.performance},
        ),
      );
    }

    final plan = _read(
      'docs/inventory_parser_qa_harness_plan.md',
      failures,
      sourceCache,
    );
    final presentDocs = <String>[];
    for (final doc in _profileDocs) {
      checked++;
      if (doc.isPresentIn(plan)) {
        presentDocs.add(doc.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_runtime_profile_doc:${doc.name}',
          message: 'Runtime profile contract is not documented.',
          severity: QaSeverity.warning,
          expected: doc.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Document which profile builds cases, runs semantic parser assertions, and gates release.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + sourceCache.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'parserCallSuitesGuarded': presentTargets,
        'presentDocs': presentDocs,
        'smokeParserAssertionsAllowed': false,
        'fullReleaseParserAssertionsAllowed': true,
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
          id: 'missing_runtime_profile_file:$path',
          message: 'Runtime profile contract scan file is missing.',
          expected: path,
          actual: 'not found',
          suggestedFix: 'Update this suite if runtime profile files move.',
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

class _RuntimeProfileTarget {
  const _RuntimeProfileTarget({
    required this.suite,
    required this.path,
    required this.requiredTokens,
  });

  final String suite;
  final String path;
  final List<String> requiredTokens;
}

class _RuntimeProfileDocContract {
  const _RuntimeProfileDocContract(this.name, this.tokens);

  final String name;
  final List<String> tokens;

  bool isPresentIn(String source) {
    return tokens.every(source.contains);
  }
}
