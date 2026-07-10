import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserDuplicateReceiptImportSuite extends QaSuite {
  const WorkSupplyParserDuplicateReceiptImportSuite()
    : super('inventory.duplicate_receipt_import_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_duplicate_receipt_import_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_review_safety_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_admin_privacy_rollup_qa.dart',
  };

  static const _duplicateSignals = {
    'receipt number',
    'merchant',
    'transaction date',
    'transaction time',
    'line count',
    'line total',
    'subtotal',
    'tax',
    'total',
    'payment method',
  };

  static const _duplicateRules = {
    'duplicate_receipt_does_not_double_add_inventory',
    'duplicate_receipt_does_not_double_add_job_materials',
    'duplicate_receipt_returns_existing_review_candidate',
    'same_receipt_can_be_attached_to_multiple_workflows_with_review',
    'partial_receipt_import_warns_on_missing_lines',
    'edited_receipt_import_creates_new_review_version',
    'return_receipt_offsets_original_candidate',
    'duplicate_detection_does_not_store_card_data',
    'duplicate_detection_uses_redacted_fingerprint',
    'duplicate_detection_is_local_first',
  };

  static const _workflowTokens = {
    'inventory',
    'active job',
    'estimate',
    'invoice',
    'job material',
    'purchased not in stock',
    'review status',
    'suggested action',
    'warnings',
    'version',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _duplicateSignals.length;
    _requireTokens(
      failures,
      source,
      _duplicateSignals,
      idPrefix: 'missing_duplicate_signal',
      message: 'Duplicate receipt import QA is missing duplicate signals.',
      fix:
          'Duplicate detection needs merchant, receipt/transaction metadata, line counts, totals, tax, and payment-shape signals without private card data.',
      triage: QaFailureTriage.schema,
    );

    checked += _duplicateRules.length;
    _requireRules(failures, source, _duplicateRules);

    checked += _workflowTokens.length;
    _requireTokens(
      failures,
      source,
      _workflowTokens,
      idPrefix: 'missing_duplicate_workflow',
      message: 'Duplicate receipt import QA is missing workflow coverage.',
      fix:
          'Duplicate receipt handling must be safe for inventory, active jobs, estimates, invoices, purchased-not-in-stock, review status, and versioning.',
      triage: QaFailureTriage.reviewSafety,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'A repeated receipt import must never silently duplicate inventory, job material, estimate, or invoice costs.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = _normalizeContractText(source);
    for (final rule in rules) {
      if (lower.contains(_normalizeContractText(rule))) continue;
      failures.add(
        _failure(
          id: 'missing_duplicate_receipt_rule:${_safeId(rule)}',
          message: 'Duplicate receipt import QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add duplicate receipt import rules before parser output can write into inventory/job/estimate workflows.',
          triage: QaFailureTriage.reviewSafety,
        ),
      );
    }
  }

  void _requireTokens(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
    required String triage,
  }) {
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: '$idPrefix:${_safeId(token)}',
          message: message,
          expected: token,
          actual: 'not found',
          fix: fix,
          triage: triage,
        ),
      );
    }
  }

  String _readSources() {
    final buffer = StringBuffer();
    for (final path in _sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}
