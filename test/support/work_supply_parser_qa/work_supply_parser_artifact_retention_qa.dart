import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserArtifactRetentionSuite extends QaSuite {
  const WorkSupplyParserArtifactRetentionSuite()
    : super('inventory.artifact_retention_contract');

  static const _scannedFiles = [
    '.gitignore',
    'test/support/qa_harness/qa_harness.dart',
    'test/support/qa_harness/qa_report_retention.dart',
    'tool/work_supply_parser_qa_prune_reports.dart',
    'test/qa_report_artifact_test.dart',
    'test/qa_report_retention_test.dart',
    'test/qa_report_prune_tool_test.dart',
    'docs/inventory_parser_qa_harness_plan.md',
  ];

  static const _contracts = [
    _ArtifactRetentionContract(
      name: 'generated_reports_under_ignored_build',
      path: '.gitignore',
      tokens: ['/build/'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'default_report_directory',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ["outputDirectory = 'build/parser_qa_reports'"],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'timestamped_and_latest_json',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['timestampedJsonPath', 'latestJsonPath', r'_$stamp.json'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'latest_summary_alias',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: ['latestSummaryPath', "latest_\${report.domain}.txt"],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'pack_health_retention_pair',
      path: 'test/support/qa_harness/qa_harness.dart',
      tokens: [
        'timestampedPackHealthJsonPath',
        'latestPackHealthJsonPath',
        r'_pack_health_$stamp.json',
      ],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'artifact_test_cleans_temp_dir',
      path: 'test/qa_report_artifact_test.dart',
      tokens: ['Directory.systemTemp.createTemp', 'addTearDown', 'deleteSync'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'artifact_test_distinct_latest_and_timestamped',
      path: 'test/qa_report_artifact_test.dart',
      tokens: [
        'artifact.timestampedJsonPath',
        'artifact.latestJsonPath',
        'isNot',
      ],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_helper_keeps_latest_aliases',
      path: 'test/support/qa_harness/qa_report_retention.dart',
      tokens: [
        'pruneQaReportArtifacts',
        'latest_\$domain.json',
        'latest_\$domain.txt',
        'latest_\${domain}_pack_health.json',
      ],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_helper_dry_run_and_domain_scoped',
      path: 'test/support/qa_harness/qa_report_retention.dart',
      tokens: ['dryRun', 'keepLatestTimestamped', '_matchingFiles'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_cli_dry_run_default',
      path: 'tool/work_supply_parser_qa_prune_reports.dart',
      tokens: [
        'work_supply_parser_qa_prune_reports.dart',
        'pruneQaReportArtifacts',
        'dryRun: !options.execute',
        'QA_RETENTION_SUMMARY',
      ],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_test_preserves_aliases_and_dry_run',
      path: 'test/qa_report_retention_test.dart',
      tokens: ['preserves latest aliases', 'dry-runs safely', 'deletedCount'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_test_selected_domain_only',
      path: 'test/qa_report_retention_test.dart',
      tokens: ['selected domain', 'maintenance_parser', 'throwsArgumentError'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'retention_cli_test_dry_run_and_execute',
      path: 'test/qa_report_prune_tool_test.dart',
      tokens: ['dry-runs by default', '--execute', 'maintenance_parser'],
      category: QaFailureTriage.governance,
    ),
    _ArtifactRetentionContract(
      name: 'artifact_layout_documented',
      path: 'docs/inventory_parser_qa_harness_plan.md',
      tokens: ['timestamped report', 'latest alias', 'ignored by Git'],
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
            id: 'missing_artifact_retention_file:$path',
            message: 'Artifact retention scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update this suite if the QA report artifact files move.',
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
      final normalizedSource = _normalizeContractText(source);
      if (contract.tokens.every(
        (token) => normalizedSource.contains(_normalizeContractText(token)),
      )) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_artifact_retention_contract:${contract.name}',
          message: 'QA artifact retention/hygiene contract is missing.',
          severity: QaSeverity.error,
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep timestamped reports, latest aliases, temp cleanup, and ignored local output intact.',
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

class _ArtifactRetentionContract {
  const _ArtifactRetentionContract({
    required this.name,
    required this.path,
    required this.tokens,
    required this.category,
  });

  final String name;
  final String path;
  final List<String> tokens;
  final String category;
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
