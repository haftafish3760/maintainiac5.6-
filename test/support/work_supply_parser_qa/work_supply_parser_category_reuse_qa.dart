import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCategoryReuseSuite extends QaSuite {
  const WorkSupplyParserCategoryReuseSuite()
    : super('inventory.category_reuse_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _sharedHarnessPath = 'test/support/qa_harness/qa_harness.dart';
  static const _presetPath = 'test/support/qa_harness/qa_suite_presets.dart';
  static const _thresholdPath =
      'test/support/qa_harness/qa_threshold_gate.dart';
  static const _baselinePath = 'test/support/qa_harness/qa_baseline_diff.dart';
  static const _domainAdapterPath =
      'test/support/parser_qa_platform/parser_qa_domain_adapter.dart';

  static const _reuseDocTokens = [
    'Maintenance',
    'estimates',
    'jobs',
    'invoices',
    'fleet inventory',
    'future catalog categories',
    'reuse the same core report/result/redaction/suite runner',
    'Do not duplicate the whole harness',
  ];

  static const _sharedHarnessTokens = [
    'class QaHarness',
    'class QaSuite',
    'class QaReport',
    'class QaRunConfig',
    'class QaRedactor',
    'writeQaReport',
    'QA_RUN_CONFIG',
    'latestJsonPath',
    'latestSummaryPath',
    'QA_ADMIN_HEALTH',
  ];

  static const _sharedInfrastructure = [
    _SharedFileContract(
      name: 'preset_selection',
      path: _presetPath,
      tokens: ['qaSuiteFilterFrom', "case 'quick'", "case 'fixtures'"],
    ),
    _SharedFileContract(
      name: 'threshold_gate',
      path: _thresholdPath,
      tokens: ['runQaHarnessWithThresholdGate', 'QaThresholdGateSuite'],
    ),
    _SharedFileContract(
      name: 'baseline_diff',
      path: _baselinePath,
      tokens: ['appendQaBaselineDiff', 'QaBaselineDiffSuite'],
    ),
    _SharedFileContract(
      name: 'domain_adapter',
      path: _domainAdapterPath,
      tokens: [
        'class ParserQaDomainAdapter',
        'workSupplyParserDomainAdapter',
        'maintenanceParserDomainAdapter',
        'forbiddenBoundaryTokens',
        'supportedResultUses',
      ],
    ),
    _SharedFileContract(
      name: 'entrypoint_command_artifacts',
      path: _entryPath,
      tokens: ['PARSER_QA_BASELINE', 'QA_ARTIFACT'],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final plan = _read(_planPath, failures);
    final sharedHarness = _read(_sharedHarnessPath, failures);
    final present = <String>[];
    var checked = 0;

    checked += _reuseDocTokens.length;
    final missingDocs = [
      for (final token in _reuseDocTokens)
        if (!_containsContractToken(plan, token)) token,
    ];
    if (missingDocs.isEmpty) {
      present.add('category_reuse_docs');
    } else {
      failures.add(
        _failure(
          id: 'missing_category_reuse_docs',
          message: 'Harness reuse policy is not fully documented.',
          expected: _reuseDocTokens.join(' + '),
          actual: 'missing ${missingDocs.join(' + ')}',
        ),
      );
    }

    checked += _sharedHarnessTokens.length;
    for (final token in _sharedHarnessTokens) {
      if (_containsContractToken(sharedHarness, token)) {
        present.add('shared:$token');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_shared_harness_token:$token',
          message: 'Shared QA harness is missing reusable infrastructure.',
          expected: token,
          actual: 'not found',
        ),
      );
    }

    checked += _sharedInfrastructure.length;
    for (final contract in _sharedInfrastructure) {
      final source = _read(contract.path, failures);
      final missing = [
        for (final token in contract.tokens)
          if (!_containsContractToken(source, token)) token,
      ];
      if (missing.isEmpty) {
        present.add('infrastructure:${contract.name}');
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_shared_infrastructure:${contract.name}',
          message: 'Reusable QA support file is missing expected behavior.',
          expected: contract.tokens.join(' + '),
          actual: 'missing ${missing.join(' + ')}',
        ),
      );
    }

    checked++;
    if (_hasDomainImport(sharedHarness)) {
      failures.add(
        _failure(
          id: 'shared_harness_imports_domain_code',
          message: 'Shared QA harness must stay category-agnostic.',
          expected: 'no maintaniac screen/data imports in shared harness',
          actual: 'domain import found',
        ),
      );
    } else {
      present.add('shared_harness_category_agnostic');
    }

    return timer.finish(
      suite: name,
      checked: checked + 4,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'sharedHarness': _sharedHarnessPath,
        'documentedReuseTargets': [
          'maintenance',
          'estimates',
          'jobs',
          'invoices',
          'fleet inventory',
          'future catalog categories',
        ],
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      expected: expected,
      actual: actual,
      suggestedFix:
          'Keep the QA runner generic and add category-specific suites on top.',
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      _failure(
        id: 'missing_category_reuse_scan_file:$path',
        message: 'Category-reuse contract scan file is missing.',
        expected: path,
        actual: 'not found',
      ),
    );
    return '';
  }

  bool _hasDomainImport(String source) {
    return source
        .split('\n')
        .where((line) => line.trimLeft().startsWith('import '))
        .any((line) => line.contains('package:maintaniac/screens/'));
  }
}

class _SharedFileContract {
  const _SharedFileContract({
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
