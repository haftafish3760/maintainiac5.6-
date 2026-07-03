import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserProfileMatrixSuite extends QaSuite {
  const WorkSupplyParserProfileMatrixSuite()
    : super('inventory.profile_matrix');

  static const _harnessPath = 'test/support/qa_harness/qa_harness.dart';
  static const _thresholdPath =
      'test/support/qa_harness/qa_threshold_gate.dart';
  static const _entryPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';

  static const _contracts = [
    _ProfileContract(
      name: 'smoke_profile_budget',
      path: _harnessPath,
      tokens: [
        "case 'smoke'",
        'maxCriticalFailures: 0',
        'maxDurationMs: 120000',
      ],
      category: QaFailureTriage.performance,
    ),
    _ProfileContract(
      name: 'full_profile_budget',
      path: _harnessPath,
      tokens: [
        "case 'full'",
        'maxErrorFailures: 0',
        'maxWarningFailures: 250',
        'maxDurationMs: 600000',
      ],
      category: QaFailureTriage.performance,
    ),
    _ProfileContract(
      name: 'release_profile_zero_budget',
      path: _harnessPath,
      tokens: [
        "case 'release'",
        'maxActualFailures: 0',
        'maxErrorFailures: 0',
        'maxWarningFailures: 0',
      ],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'release_profile_is_full',
      path: _harnessPath,
      tokens: ["profile == 'full' || profile == 'release'"],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'release_profile_strict_severity',
      path: _thresholdPath,
      tokens: ['context.isReleaseProfile', 'QaSeverity.critical'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'threshold_gate_auto_append',
      path: _thresholdPath,
      tokens: ['context.suiteFilter.isEmpty', 'QaThresholdGateSuite.suiteName'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'entrypoint_profile_env',
      path: _entryPath,
      tokens: ['PARSER_QA_PROFILE', 'QaThresholds.forProfile(profile)'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'entrypoint_strict_env',
      path: _entryPath,
      tokens: ['PARSER_QA_STRICT', 'expect(report.failures, isEmpty'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'profile_docs_smoke',
      path: _planPath,
      tokens: ['Smoke profile', '`smoke`: no critical failures'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'profile_docs_full',
      path: _planPath,
      tokens: ['Full profile', '`full`: no critical or error failures'],
      category: QaFailureTriage.governance,
    ),
    _ProfileContract(
      name: 'profile_docs_release',
      path: _planPath,
      tokens: [
        'Release profile plus strict mode',
        '`release`: zero actual failures',
      ],
      category: QaFailureTriage.governance,
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final sources = <String, String>{};
    for (final path in {_harnessPath, _thresholdPath, _entryPath, _planPath}) {
      final file = File(path);
      if (!file.existsSync()) {
        failures.add(
          QaFailure(
            suite: name,
            id: 'missing_profile_matrix_file:$path',
            message: 'Profile matrix scan file is missing.',
            expected: path,
            actual: 'not found',
            suggestedFix:
                'Update the profile matrix suite if harness files move.',
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
          id: 'missing_profile_matrix_contract:${contract.name}',
          message: 'Profile/release-gate contract is missing.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'not found',
          suggestedFix:
              'Keep smoke/full/release profile behavior explicit before release-gating parser packs.',
          metadata: {'triageCategory': contract.category},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: sources.length + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'profiles': const ['smoke', 'full', 'release'],
      },
    );
  }
}

class _ProfileContract {
  const _ProfileContract({
    required this.name,
    required this.path,
    required this.tokens,
    required this.category,
  });

  final String name;
  final String path;
  final List<String> tokens;
  final String category;

  bool isPresentIn(String source) {
    return tokens.every(source.contains);
  }
}
