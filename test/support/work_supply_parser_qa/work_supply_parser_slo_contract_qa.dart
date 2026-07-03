import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSloContractSuite extends QaSuite {
  const WorkSupplyParserSloContractSuite()
    : super('inventory.slo_metrics_contract');

  static const _planPath = 'docs/inventory_parser_qa_harness_plan.md';
  static const _accuracyPath =
      'test/support/work_supply_parser_qa/work_supply_parser_accuracy_budget_qa.dart';
  static const _confidencePath =
      'test/support/work_supply_parser_qa/work_supply_parser_confidence_qa.dart';
  static const _thresholdPath =
      'test/support/qa_harness/qa_threshold_gate.dart';
  static const _adminPath =
      'test/support/work_supply_parser_qa/work_supply_parser_admin_report_contract_qa.dart';
  static const _telemetryPath =
      'test/support/work_supply_parser_qa/work_supply_parser_telemetry_qa.dart';

  static const _contracts = [
    _SloContract(
      name: 'slo_docs',
      path: _planPath,
      tokens: [
        'Parser SLO and quality metrics',
        'top-1 clear-match accuracy',
        'false-confident rate',
        'receipt-noise false-positive rate',
        'review/unknown rate',
        'runtime budget',
        'Command One/admin visibility',
      ],
    ),
    _SloContract(
      name: 'accuracy_budgets',
      path: _accuracyPath,
      tokens: [
        'top1AccuracyBudget',
        'top3AccuracyBudget',
        'falseConfidentRateBudget',
        'noiseFalsePositiveRateBudget',
        'generatedFamilyAccuracyBudget',
      ],
    ),
    _SloContract(
      name: 'confidence_bands',
      path: _confidencePath,
      tokens: [
        'Good/Review/Poor confidence bands',
        'receipt noise should stay poor/unknown',
        'risky or ambiguous lines must not cross the Good threshold',
      ],
    ),
    _SloContract(
      name: 'runtime_thresholds',
      path: _thresholdPath,
      tokens: [
        'max_duration_ms',
        'max_suite_duration_ms',
        'min_suite_checks_per_second',
        'actualFailures',
      ],
    ),
    _SloContract(
      name: 'admin_visibility',
      path: _adminPath,
      tokens: [
        'QA_ADMIN_HEALTH',
        'triage_rollup',
        'slow_suite_rollup',
        'pack_health_rollup',
      ],
    ),
    _SloContract(
      name: 'telemetry_cost_privacy',
      path: _telemetryPath,
      tokens: [
        'failure_device_bucket',
        'read_budget',
        'no_raw_receipt_content',
        'no_live_hosted_writes',
      ],
    ),
  ];

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final present = <String>[];
    var checked = 0;

    for (final contract in _contracts) {
      checked += contract.tokens.length;
      final source = _read(contract.path, failures);
      final missing = [
        for (final token in contract.tokens)
          if (!source.contains(token)) token,
      ];
      if (missing.isEmpty) {
        present.add(contract.name);
        continue;
      }
      failures.add(
        QaFailure(
          suite: name,
          id: 'missing_slo_contract:${contract.name}',
          message: 'Parser SLO/quality metrics contract is incomplete.',
          expected: '${contract.path}: ${contract.tokens.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          suggestedFix:
              'Define measurable parser quality, safety, cost, and runtime targets before release gating.',
          metadata: const {'triageCategory': QaFailureTriage.governance},
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked + _contracts.length,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'presentContracts': present,
        'contractCount': _contracts.length,
        'parserCalls': 0,
      },
    );
  }

  String _read(String path, List<QaFailure> failures) {
    final file = File(path);
    if (file.existsSync()) return file.readAsStringSync();
    failures.add(
      QaFailure(
        suite: name,
        id: 'missing_slo_scan_file:$path',
        message: 'SLO contract scan file is missing.',
        expected: path,
        actual: 'not found',
        suggestedFix: 'Update this suite if SLO contract files move.',
        metadata: const {'triageCategory': QaFailureTriage.schema},
      ),
    );
    return '';
  }
}

class _SloContract {
  const _SloContract({
    required this.name,
    required this.path,
    required this.tokens,
  });

  final String name;
  final String path;
  final List<String> tokens;
}
