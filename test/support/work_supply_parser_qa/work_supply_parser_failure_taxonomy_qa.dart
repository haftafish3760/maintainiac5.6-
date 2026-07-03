import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFailureTaxonomySuite extends QaSuite {
  const WorkSupplyParserFailureTaxonomySuite()
    : super('inventory.failure_taxonomy_contract');

  static const _harnessPath = 'test/support/qa_harness/qa_harness.dart';
  static const _triageTestPath = 'test/qa_failure_triage_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _requiredCategories = [
    QaFailureTriage.schema,
    QaFailureTriage.alias,
    QaFailureTriage.merchantRule,
    QaFailureTriage.conflict,
    QaFailureTriage.normalization,
    QaFailureTriage.category,
    QaFailureTriage.unit,
    QaFailureTriage.quantity,
    QaFailureTriage.confidence,
    QaFailureTriage.context,
    QaFailureTriage.parserEngine,
    QaFailureTriage.privacy,
    QaFailureTriage.security,
    QaFailureTriage.performance,
    QaFailureTriage.governance,
    QaFailureTriage.reviewSafety,
    QaFailureTriage.fixture,
    QaFailureTriage.economics,
    QaFailureTriage.locale,
    QaFailureTriage.baseline,
    QaFailureTriage.unknown,
  ];

  static const _reportContracts = [
    _FailureTaxonomyContract(
      name: 'failure_json_triage_field',
      path: _harnessPath,
      tokens: ['triageCategory', 'toJson'],
    ),
    _FailureTaxonomyContract(
      name: 'grouped_json_triage_rollup',
      path: _harnessPath,
      tokens: ['failuresByTriageCategory', 'redactor.value'],
    ),
    _FailureTaxonomyContract(
      name: 'summary_triage_rollup',
      path: _harnessPath,
      tokens: ['QA_TRIAGE_GROUP', 'triage='],
    ),
    _FailureTaxonomyContract(
      name: 'explicit_metadata_override',
      path: _harnessPath,
      tokens: ["metadata['triageCategory']", 'explicit.isNotEmpty'],
    ),
    _FailureTaxonomyContract(
      name: 'unit_test_triage_serialization',
      path: _triageTestPath,
      tokens: [
        'qa failures expose triage category in json and summary',
        'explicit triage category metadata wins over classifier',
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in {_harnessPath, _triageTestPath, _planPath}) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_failure_taxonomy_file:$path',
            message: 'Failure taxonomy scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix: 'Update this suite if taxonomy files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sources[path] = file.readAsStringSync();
    }

    final harness = sources[_harnessPath] ?? '';
    final plan = sources[_planPath] ?? '';
    final presentCategories = <String>[];
    for (final category in _requiredCategories) {
      final constToken = "'$category'";
      final docToken = category.replaceAll('_', ' ');
      final hasCode = harness.contains(constToken);
      final hasDoc = plan.toLowerCase().contains(docToken);
      if (hasCode && hasDoc) {
        presentCategories.add(category);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_failure_taxonomy_category:$category',
          message: 'Failure triage category is missing from code or docs.',
          severity: QaSeverity.error,
          expected: '$constToken and docs phrase "$docToken"',
          actual: 'code=$hasCode docs=$hasDoc',
          suggestedFix:
              'Keep the failure taxonomy complete so QA reports stay actionable at scale.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    final presentContracts = <String>[];
    for (final contract in _reportContracts) {
      final source = sources[contract.path] ?? '';
      final missing = [
        for (final token in contract.tokens)
          if (!source.contains(token)) token,
      ];
      if (missing.isEmpty) {
        presentContracts.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_failure_taxonomy_contract:${contract.name}',
          message: 'Failure taxonomy reporting contract is missing.',
          severity: QaSeverity.error,
          expected: contract.tokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Ensure failures are classified, grouped, serialized, summarized, and unit-tested.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _requiredCategories.length + _reportContracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'categoryCount': _requiredCategories.length,
        'presentCategories': presentCategories,
        'presentContracts': presentContracts,
      },
    );
  }
}

class _FailureTaxonomyContract {
  const _FailureTaxonomyContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
