import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseManifestSuite extends QaSuite {
  const WorkSupplyParserReleaseManifestSuite()
    : super('inventory.release_manifest');

  static const _scannedFiles = [
    'docs/inventory_parser_qa_harness_plan.md',
    'test/work_supply_parser_qa_harness_test.dart',
    'test/support/qa_harness/qa_harness.dart',
    'test/support/qa_harness/qa_threshold_gate.dart',
    'test/support/qa_harness/qa_baseline_diff.dart',
    'test/support/qa_harness/qa_suite_presets.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_shard_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_signoff_qa.dart',
    'test/work_supply_parser_qa_shard_runner_test.dart',
    'test/work_supply_parser_qa_release_signoff_test.dart',
    'tool/work_supply_parser_qa_shard_runner.dart',
    'tool/work_supply_parser_qa_release_signoff.dart',
  ];

  static const _contracts = [
    _ReleaseContract(
      name: 'release_profile',
      tokens: ['PARSER_QA_PROFILE', 'release'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'strict_mode',
      tokens: ['PARSER_QA_STRICT', 'strict'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'zero_failure_release_budget',
      tokens: ['maxActualFailures: 0', 'maxWarningFailures: 0'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'baseline_diff',
      tokens: ['PARSER_QA_BASELINE', 'appendQaBaselineDiff'],
      category: QaFailureTriage.baseline,
      required: true,
    ),
    _ReleaseContract(
      name: 'pack_health_artifact',
      tokens: ['QA_PACK_HEALTH', 'latestPackHealthJsonPath'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'slow_suite_reporting',
      tokens: ['QA_SLOW_SUITE', 'slowestSuites'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ReleaseContract(
      name: 'release_shard_metadata',
      tokens: [
        'PARSER_QA_SHARD_ID',
        'PARSER_QA_TIMEOUT_BUDGET_MS',
        'PARSER_QA_RESUME_FROM',
      ],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ReleaseContract(
      name: 'release_shard_runner',
      tokens: ['QA_SHARD_SUMMARY', 'summary.json', 'transcriptPath'],
      category: QaFailureTriage.performance,
      required: true,
    ),
    _ReleaseContract(
      name: 'release_signoff',
      tokens: [
        'QA_RELEASE_SIGNOFF',
        'missing_expected_shard',
        'stale_shard',
        'dry_run_not_release_signoff',
      ],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'quick_preset',
      tokens: ["case 'quick'", 'inventory.security_privacy'],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'fixtures_preset',
      tokens: ["case 'fixtures'", 'inventory.golden_fixtures'],
      category: QaFailureTriage.fixture,
      required: true,
    ),
    _ReleaseContract(
      name: 'catalog_preset',
      tokens: ["case 'catalog'", 'inventory.catalog_schema'],
      category: QaFailureTriage.schema,
      required: true,
    ),
    _ReleaseContract(
      name: 'known_debt_section',
      tokens: [
        'Current Known QA Debt',
        'threshold-clean as of harness Pass 91',
        'inventory.runtime_measurement',
      ],
      category: QaFailureTriage.governance,
      required: true,
    ),
    _ReleaseContract(
      name: 'release_one_priority',
      tokens: ['Release one focuses', 'US English and US Spanish'],
      category: QaFailureTriage.locale,
      required: true,
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
            id: 'missing_release_manifest_scan_file:$path',
            message: 'Release manifest scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if release-gate docs or harness files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sourceByPath[path] = file.readAsStringSync();
    }

    final source = sourceByPath.values.join('\n');
    final present = <String>[];
    for (final contract in _contracts) {
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_release_manifest_contract:${contract.name}',
          message: contract.required
              ? 'Required release manifest contract is missing.'
              : 'Recommended release manifest contract is missing.',
          severity: contract.required ? QaSeverity.error : QaSeverity.warning,
          expected: contract.tokens.join(' + '),
          actual: 'not found',
          suggestedFix:
              'Make release readiness auditable before claiming parser packs are release-ready.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: _scannedFiles.length + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'filesScanned': sourceByPath.keys.toList()..sort(),
      },
    );
  }
}

class _ReleaseContract {
  const _ReleaseContract({
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
    final normalizedSource = _normalizeContractText(source);
    return tokens.every(
      (token) => normalizedSource.contains(_normalizeContractText(token)),
    );
  }
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
