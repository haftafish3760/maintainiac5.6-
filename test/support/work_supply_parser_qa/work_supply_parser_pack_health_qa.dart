import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackHealthSuite extends QaSuite {
  const WorkSupplyParserPackHealthSuite()
    : super('inventory.pack_health_score');

  static const _scannedFiles = [
    'lib/screens/work_supplies/data/work_supply_catalog_audit.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_catalog_coverage_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_fixture_coverage_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_impact_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_scalability_qa.dart',
    'test/support/qa_harness/qa_baseline_diff.dart',
    'test/support/qa_harness/qa_harness.dart',
  ];

  static const _contracts = [
    _HealthContract(
      name: 'pack_item_count',
      tokens: ['itemCount'],
      category: QaFailureTriage.schema,
      required: true,
    ),
    _HealthContract(
      name: 'trade_count',
      tokens: ['tradeCount'],
      category: QaFailureTriage.category,
      required: true,
    ),
    _HealthContract(
      name: 'market_scope_tier_matrix',
      tokens: ['scopeTierCounts', 'tradeScopeTierCounts'],
      category: QaFailureTriage.category,
      required: true,
    ),
    _HealthContract(
      name: 'alias_coverage',
      tokens: ['aliasCoverage', 'itemsWithAliases'],
      category: QaFailureTriage.alias,
      required: true,
    ),
    _HealthContract(
      name: 'parser_term_coverage',
      tokens: ['parserTermCoverage', 'itemsWithParserTerms'],
      category: QaFailureTriage.parserEngine,
      required: true,
    ),
    _HealthContract(
      name: 'missing_metadata_count',
      tokens: ['incompleteItemCount', '_missingCoreFields'],
      category: QaFailureTriage.schema,
      required: true,
    ),
    _HealthContract(
      name: 'duplicate_id_risk',
      tokens: ['duplicateIdCount', 'duplicateIds'],
      category: QaFailureTriage.conflict,
      required: true,
    ),
    _HealthContract(
      name: 'alias_conflict_risk',
      tokens: ['WorkSupplyAliasConflictSuite', 'generic_alias'],
      category: QaFailureTriage.conflict,
      required: true,
    ),
    _HealthContract(
      name: 'dangerous_word_ambiguity_risk',
      tokens: ['WorkSupplyDangerousWordSuite', 'forced_confident_generic'],
      category: QaFailureTriage.reviewSafety,
      required: true,
    ),
    _HealthContract(
      name: 'fixture_coverage',
      tokens: ['caseTypes', 'riskTags', 'merchants'],
      category: QaFailureTriage.fixture,
      required: true,
    ),
    _HealthContract(
      name: 'baseline_regression_count',
      tokens: ['failures_increased', 'severity_increased', 'baseline'],
      category: QaFailureTriage.baseline,
      required: true,
    ),
    _HealthContract(
      name: 'performance_cost',
      tokens: ['checksPerSecond', 'slowestSuites'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _HealthContract(
      name: 'estimated_pack_size',
      tokens: ['estimatedPackedBytes', 'estimatedCompressedBytes'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _HealthContract(
      name: 'release_readiness_label',
      tokens: ['readinessLabel', 'parserReadinessLabel'],
      category: QaFailureTriage.governance,
    ),
    _HealthContract(
      name: 'health_score_output',
      tokens: ['healthScore', 'parserReadinessScore', 'coverageScore'],
      category: QaFailureTriage.governance,
    ),
    _HealthContract(
      name: 'pack_health_report_artifact',
      tokens: ['packHealth', 'QA_PACK_HEALTH', 'latestPackHealthJsonPath'],
      category: QaFailureTriage.governance,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sourceByPath = <String, String>{};

    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_pack_health_scan_file:$path',
            message: 'Pack health scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the pack health suite if the audited source moved.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }

    final source = sourceByPath.values.join('\n');
    final present = <String>[];
    final missingRequired = <String>[];
    final missingRecommended = <String>[];

    for (final contract in _contracts) {
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      if (contract.required) {
        missingRequired.add(contract.name);
      } else {
        missingRecommended.add(contract.name);
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_pack_health_contract:${contract.name}',
          message: contract.required
              ? 'Required pack health dimension is missing.'
              : 'Recommended pack health dimension is not represented yet.',
          severity: contract.required ? QaSeverity.error : QaSeverity.warning,
          expected: contract.name,
          actual: 'not found',
          suggestedFix:
              'Add this dimension to the pack health report before release readiness claims.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _contracts.length + _scannedFiles.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'missingRequiredContracts': missingRequired,
        'missingRecommendedContracts': missingRecommended,
        'filesScanned': sourceByPath.keys.toList()..sort(),
      },
    );
  }
}

class _HealthContract {
  const _HealthContract({
    required this.name,
    required this.tokens,
    required this.category,
    this.required = false,
  });

  final String name;
  final List<String> tokens;
  final String category;
  final bool required;

  bool isPresentIn(String source) {
    return tokens.every((token) => _containsContractToken(source, token));
  }
}

bool _containsContractToken(String source, String token) {
  return _normalizeContractText(source).contains(_normalizeContractText(token));
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
