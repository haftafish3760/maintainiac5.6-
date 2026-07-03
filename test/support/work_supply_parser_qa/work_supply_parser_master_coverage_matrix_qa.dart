import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserMasterCoverageMatrixSuite extends QaSuite {
  const WorkSupplyParserMasterCoverageMatrixSuite()
    : super('inventory.master_coverage_matrix_contract');

  static const _matrixPath =
      'docs/inventory_parser_qa_master_coverage_matrix.md';
  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _releaseGatePath = 'docs/release_100_percent_required_qa_gates.md';

  static const _requiredRequirements = {
    'Product normalization',
    'Merchant item aliases',
    'Merchant alias normalization',
    'Duplicate detection',
    'Category inference',
    'Receipt line item mapping',
    'Receipt line mapping detail',
    'Search and indexing',
    'Hive persistence',
    'Firestore mirror behavior',
    'Conflict handling',
    'Import/export safety',
    'Financial totals',
    'Feed receipts/invoices without mutating sources',
    'Duplicate financial guard',
    'Receipt to invoice/job feed',
    'Regression locks',
    'Differential regression',
    'Pack-version regression',
    'Security abuse',
    'Input attack surface',
    'Privacy and admin diagnostics',
    'Fleet and permissions',
    'Device and storage budgets',
    'Pack lifecycle and recovery',
    'Language pack separation',
    'Human correction learning',
  };

  static const _requiredSuites = {
    'inventory.product_normalization_contract',
    'inventory.vendor_sku_matrix_contract',
    'inventory.merchant_alias_normalization_contract',
    'inventory.duplicate_receipt_import_contract',
    'inventory.category_inference_contract',
    'inventory.receipt_source_immutability_contract',
    'inventory.receipt_line_mapping_contract',
    'inventory.search_indexing_contract',
    'inventory.hive_authority_contract',
    'inventory.hive_firestore_sync_contract',
    'inventory.conflict_graph',
    'inventory.import_export_safety_contract',
    'inventory.price_tax_allocation_contract',
    'inventory.financial_duplicate_guard_contract',
    'inventory.regression_lock_contract',
    'inventory.receipt_invoice_feed_contract',
    'inventory.differential_regression_contract',
    'inventory.pack_version_regression_contract',
    'inventory.security_privacy',
    'inventory.input_attack_surface_contract',
    'inventory.admin_privacy_rollup_contract',
    'inventory.fleet_permission_context_contract',
    'inventory.device_budget_matrix_contract',
    'inventory.pack_integrity_recovery_contract',
    'inventory.language_pack_separation_contract',
    'inventory.human_correction_learning_contract',
  };

  static const _hardRules = {
    'Hive is always the inventory source of truth',
    'Firebase and Firestore are mirror-only for inventory',
    'Parser candidates are review-only',
    'Search and parser text input are hostile input surfaces',
    'Financial totals must not be duplicated',
    'Source records from receipts, invoices, estimates, and jobs must not be mutated',
  };

  static const _matrixColumns = {
    'Requirement',
    'Status',
    'Primary Suite',
    'Supporting Suites',
    'Focused Rerun',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final matrix = _read(_matrixPath);
    final progress = _read(_progressPath);
    final releaseGate = _read(_releaseGatePath);
    var checked = 0;

    checked += _matrixColumns.length;
    for (final column in _matrixColumns) {
      if (matrix.contains(column)) continue;
      failures.add(
        _failure(
          id: 'missing_matrix_column:${_safeId(column)}',
          message: 'Inventory parser QA master matrix is missing a column.',
          expected: column,
          actual: 'not found in $_matrixPath',
          fix:
              'Keep requirement, status, suite, supporting-suite, and focused-rerun evidence visible in the master matrix.',
          triage: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredRequirements.length;
    for (final requirement in _requiredRequirements) {
      if (matrix.contains(requirement)) continue;
      failures.add(
        _failure(
          id: 'missing_matrix_requirement:${_safeId(requirement)}',
          message: 'Inventory parser QA master matrix is missing a required row.',
          expected: requirement,
          actual: 'not found in $_matrixPath',
          fix:
              'Add the missing requirement row so QA coverage cannot drift or rely on memory.',
          triage: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredSuites.length * 2;
    for (final suite in _requiredSuites) {
      if (!matrix.contains(suite)) {
        failures.add(
          _failure(
            id: 'missing_matrix_suite:${_safeId(suite)}',
            message: 'Master matrix is missing a primary/supporting suite mapping.',
            expected: suite,
            actual: 'not found in $_matrixPath',
            fix:
                'Map every required QA area to a concrete suite before claiming coverage.',
            triage: QaFailureTriage.governance,
          ),
        );
      }
      if (!progress.contains(suite)) {
        failures.add(
          _failure(
            id: 'missing_progress_suite:${_safeId(suite)}',
            message: 'Progress memory is missing focused rerun tracking for a required suite.',
            expected: suite,
            actual: 'not found in $_progressPath',
            fix:
                'Add focused rerun tracking to progress memory so completed work is not lost or rerun broadly.',
            triage: QaFailureTriage.governance,
          ),
        );
      }
    }

    checked += _hardRules.length;
    for (final rule in _hardRules) {
      if (matrix.contains(rule)) continue;
      failures.add(
        _failure(
          id: 'missing_matrix_hard_rule:${_safeId(rule)}',
          message: 'Master matrix is missing a non-negotiable inventory rule.',
          expected: rule,
          actual: 'not found in $_matrixPath',
          fix:
              'Keep hard safety/source-of-truth rules in the matrix so they are visible before release.',
          triage: QaFailureTriage.governance,
        ),
      );
    }

    checked += 4;
    for (final releaseToken in const {
      'Master Coverage Matrix',
      'Golden Regression Corpus',
      'Differential Regression',
      'Security Abuse',
    }) {
      if (releaseGate.contains(releaseToken)) continue;
      failures.add(
        _failure(
          id: 'missing_release_gate_link:${_safeId(releaseToken)}',
          message: 'App-wide release QA gate doc is missing a required gate.',
          expected: releaseToken,
          actual: 'not found in $_releaseGatePath',
          fix:
              'The inventory matrix must remain tied to the release-wide 100 percent QA standard.',
          triage: QaFailureTriage.governance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'matrixPath': _matrixPath,
        'progressPath': _progressPath,
        'releaseGatePath': _releaseGatePath,
        'contract':
            'The master matrix is the authoritative inventory parser QA checklist and must map every required area to concrete suites and rerun commands.',
      },
    );
  }

  String _read(String path) {
    final file = File(path);
    if (!file.existsSync()) return '';
    return file.readAsStringSync();
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String triage,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': triage},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
