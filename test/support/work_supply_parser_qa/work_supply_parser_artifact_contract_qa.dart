import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserArtifactContractSuite extends QaSuite {
  const WorkSupplyParserArtifactContractSuite()
    : super('inventory.artifact_contract');

  static const _scannedFiles = [
    '.gitignore',
    'test/support/qa_harness/qa_harness.dart',
    'test/qa_report_artifact_test.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _contracts = [
    _ArtifactContract(
      name: 'build_output_ignored',
      path: '.gitignore',
      tokens: ['/build/'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'timestamped_json_report',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['timestampedJsonPath', 'latestJsonPath'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'latest_summary_report',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['latestSummaryPath', 'toSummary'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'pack_health_artifacts',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['timestampedPackHealthJsonPath', 'latestPackHealthJsonPath'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'run_config_serialized',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['runConfig', 'QA_RUN_CONFIG'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'slow_suite_serialized',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['slowestSuites', 'QA_SLOW_SUITE'],
      required: true,
      category: QaFailureTriage.performance,
    ),
    _ArtifactContract(
      name: 'triage_groups_serialized',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['failuresByTriageCategory', 'QA_TRIAGE_GROUP'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'artifact_redaction_test',
      path: 'test/qa_report_artifact_test.dart',
      tokens: [
        '[REDACTED_RECEIPT_ID]',
        '[REDACTED_CARD_LIKE_NUMBER]',
        '[REDACTED_CARD_LAST4]',
        '[REDACTED_PRIVATE_FIELD]',
        '[REDACTED_PRIVATE_VALUE]',
        '[REDACTED_PHONE]',
      ],
      required: true,
      category: QaFailureTriage.privacy,
    ),
    _ArtifactContract(
      name: 'pack_health_test_coverage',
      path: 'test/qa_report_artifact_test.dart',
      tokens: ['packHealth', 'readinessLabel'],
      required: true,
      category: QaFailureTriage.governance,
    ),
    _ArtifactContract(
      name: 'artifact_layout_documented',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: [
        'build/parser_qa_reports/',
        'latest_work_supply_inventory_parser.json',
        'latest_work_supply_inventory_parser.txt',
      ],
      required: true,
      category: QaFailureTriage.governance,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in _scannedFiles) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_artifact_contract_file:$path',
            message: 'Artifact contract scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the artifact contract suite if report files move.',
            metadata: const {'triageCategory': QaFailureTriage.schema},
          ),
        );
        continue;
      }
      sources[path] = file.readAsStringSync();
    }

    final present = <String>[];
    for (final contract in _contracts) {
      final source = sources[contract.path] ?? '';
      if (contract.isPresentIn(source)) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_artifact_contract:${contract.name}',
          message: contract.required
              ? 'Required QA artifact contract is missing.'
              : 'Recommended QA artifact contract is missing.',
          severity: contract.required ? QaSeverity.error : QaSeverity.warning,
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep report artifacts reproducible, redacted, and ignored before scaling parser QA.',
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
        'filesScanned': sources.keys.toList()..sort(),
      },
    );
  }
}

class _ArtifactContract {
  const _ArtifactContract({
    required this.name,
    required this.path,
    required this.tokens,
    required this.category,
    this.required = false,
  });

  final String name;
  final String path;
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
