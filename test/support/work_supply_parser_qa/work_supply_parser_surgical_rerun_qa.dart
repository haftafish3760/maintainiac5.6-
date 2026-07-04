import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserSurgicalRerunSuite extends QaSuite {
  const WorkSupplyParserSurgicalRerunSuite()
    : super('inventory.surgical_rerun_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _harnessPath = 'test/work_supply_parser_qa_harness_test.dart';
  static const _runnerPath =
      'test/work_supply_parser_generated_fixture_runner_test.dart';
  static const _gatePath = 'tool/work_supply_parser_qa_gate_should_run.dart';
  static const _ledgerPath = 'tool/work_supply_parser_qa_gate_ledger.dart';

  static const _requiredFailureRoutes = {
    'inventory.generated_fixture_cell_contract':
        'PARSER_QA_GENERATED_FIXTURE_PATH=',
    'inventory.catalog_batch_memory_contract':
        'inventory.catalog_batch_memory_contract,qa.threshold_gate',
    'inventory.item_metadata_depth': 'inventory.item_metadata_depth',
    'inventory.vendor_readiness': 'inventory.vendor_readiness',
    'inventory.vendor_sku_matrix_contract':
        'inventory.vendor_sku_matrix_contract',
    'inventory.merchant_independence_contract':
        'inventory.merchant_independence_contract',
    'inventory.merchant_matrix_contract': 'inventory.merchant_matrix_contract',
    'inventory.release_one_scorecard_contract':
        'inventory.release_one_scorecard_contract',
    'inventory.real_receipt_validation_contract':
        'inventory.real_receipt_validation_contract',
    'inventory.fake_user_review_workflow':
        'inventory.fake_user_review_workflow',
    'inventory.parser_platform_contract': 'inventory.parser_platform_contract',
    'inventory.portability_contract': 'inventory.portability_contract',
    'inventory.barcode_inventory_identity_contract':
        'inventory.barcode_inventory_identity_contract',
    'inventory.human_correction_learning_contract':
        'inventory.human_correction_learning_contract',
    'inventory.confidence_calibration': 'inventory.confidence_calibration',
    'inventory.legal_safety_contract': 'inventory.legal_safety_contract',
    'inventory.service_truck_core_contract':
        'inventory.service_truck_core_contract',
    'inventory.release_one_pack_balance': 'inventory.release_one_pack_balance',
    'inventory.release_one_residential_contract':
        'inventory.release_one_residential_contract',
    'inventory.release_one_service_family_contract':
        'inventory.release_one_service_family_contract',
    'inventory.release_one_tier_role_contract':
        'inventory.release_one_tier_role_contract',
    'inventory.release_one_fastener_support_contract':
        'inventory.release_one_fastener_support_contract',
    'inventory.release_one_cell_manifest':
        'inventory.release_one_cell_manifest',
    'inventory.language_pack_separation_contract':
        'inventory.language_pack_separation_contract',
    'inventory.spanish_release_one': 'inventory.spanish_release_one',
    'inventory.standard_fixture_seed_contract':
        'inventory.standard_fixture_seed_contract',
    'inventory.hive_authority_contract': 'inventory.hive_authority_contract',
    'inventory.hive_firestore_sync_contract':
        'inventory.hive_firestore_sync_contract',
    'inventory.review_safety_contract': 'inventory.review_safety_contract',
    'inventory.receipt_source_immutability_contract':
        'inventory.receipt_source_immutability_contract',
    'inventory.fixture_coverage_matrix': 'inventory.fixture_coverage_matrix',
    'inventory.fixture_candidate_identity_contract':
        'inventory.fixture_candidate_identity_contract,qa.threshold_gate',
    'inventory.fixture_corpus_contract':
        'inventory.fixture_corpus_contract,qa.threshold_gate',
    'inventory.fixture_expectation_contract':
        'inventory.fixture_expectation_contract,qa.threshold_gate',
    'inventory.golden_fixtures': 'inventory.golden_fixtures,qa.threshold_gate',
    'repair_kit_fixture_lock':
        'inventory.fixture_coverage_matrix,inventory.accumulated_coverage_contract',
    'inventory.security_privacy': 'inventory.security_privacy',
    'inventory.boundary_guard': 'inventory.boundary_guard',
    'inventory.no_live_services_contract':
        'inventory.no_live_services_contract',
  };

  static const _requiredRunnerTokens = {
    'PARSER_QA_GENERATED_FIXTURE_PATH',
    'PARSER_QA_GENERATED_FIXTURE_MAX_CASES',
    'PARSER_QA_GENERATED_FIXTURE_IDS',
    'PARSER_QA_GENERATED_REPORT_DIR',
    'QA_GENERATED_FIXTURE_RUN',
    'latest_generated_fixture_run.json',
    'semanticTimingExcludesWarmup',
  };

  static const _requiredHarnessTokens = {
    'PARSER_QA_SUITES',
    'suiteFilter',
    'PARSER_QA_PRESET',
    'PARSER_QA_PROFILE',
    'PARSER_QA_MAX_FAILURES_PER_SUITE',
  };

  static const _requiredGateTokens = {
    'covered input files',
    'source fingerprints',
    'affected sources have not changed',
    'exitCode',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    final harness = _read(_harnessPath);
    final runner = _read(_runnerPath);
    final gate = '${_read(_gatePath)}\n${_read(_ledgerPath)}';
    var checked = 0;

    checked += _requiredFailureRoutes.length;
    for (final entry in _requiredFailureRoutes.entries) {
      if (progress.contains(entry.key) && progress.contains(entry.value)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_surgical_route:${entry.key}',
          message: 'Progress memory is missing a focused rerun route.',
          expected: '${entry.key} -> ${entry.value}',
          actual: 'route not found',
          fix:
              'Add the smallest rerun command for this suite so one failure does not trigger a full catalog rerun.',
          category: QaFailureTriage.performance,
        ),
      );
    }

    checked += _requiredRunnerTokens.length;
    for (final token in _requiredRunnerTokens) {
      if (runner.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_generated_runner_token:$token',
          message:
              'Generated fixture runner is missing a surgical rerun token.',
          expected: token,
          actual: 'not found in $_runnerPath',
          fix:
              'Keep generated fixture reruns targetable by exact fixture path and case limit.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredHarnessTokens.length;
    for (final token in _requiredHarnessTokens) {
      if (harness.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_harness_filter_token:$token',
          message:
              'Parser QA harness is missing focused suite filtering support.',
          expected: token,
          actual: 'not found in $_harnessPath',
          fix:
              'Focused suite filters are required to avoid rerunning completed test groups.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredGateTokens.length;
    for (final token in _requiredGateTokens) {
      if (gate.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_gate_skip_token:${_safeId(token)}',
          message:
              'Gate ledger/skip tooling is missing rerun-avoidance evidence.',
          expected: token,
          actual: 'not found in gate ledger tools',
          fix:
              'Track covered inputs and fingerprints so unchanged successful gates can be skipped safely.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'runnerPath': _runnerPath,
        'requiredRoutes': _requiredFailureRoutes.keys.toList()..sort(),
        'contract':
            'Every broad inventory QA failure must map to a focused rerun path so one bad item, fixture, or suite does not force a full-catalog rerun.',
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
