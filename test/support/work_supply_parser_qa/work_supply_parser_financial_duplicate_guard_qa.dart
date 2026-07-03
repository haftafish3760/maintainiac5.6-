import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserFinancialDuplicateGuardSuite extends QaSuite {
  const WorkSupplyParserFinancialDuplicateGuardSuite()
    : super('inventory.financial_duplicate_guard_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_financial_duplicate_guard_qa.dart',
    'docs/inventory_parser_qa_master_coverage_matrix.md',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_duplicate_receipt_import_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
  };

  static const _financialFields = {
    'unit price',
    'extended price',
    'quantity',
    'pack quantity',
    'subtotal',
    'sales tax',
    'total',
    'discount',
    'coupon',
    'return',
    'void',
    'math mismatch',
  };

  static const _duplicateCostRules = {
    'same_receipt_line_cannot_create_duplicate_inventory_cost',
    'same_receipt_line_cannot_create_duplicate_job_cost',
    'same_receipt_line_cannot_create_duplicate_estimate_cost',
    'same_receipt_line_cannot_create_duplicate_invoice_cost',
    'same_receipt_total_cannot_be_allocated_twice',
    'same_tax_amount_cannot_be_allocated_twice',
    'return_line_offsets_not_adds_cost',
    'void_line_does_not_create_cost',
    'discount_line_reduces_cost_once',
    'pack_split_keeps_total_reconciliation',
    'quantity_change_requires_review',
    'financial_change_requires_new_review_version',
  };

  static const _destinationLedgers = {
    'inventory ledger',
    'job material ledger',
    'estimate material ledger',
    'invoice material ledger',
    'purchased not in stock',
    'vehicle inventory',
    'shop inventory',
    'audit trail',
    'review candidate',
    'approved destination record',
  };

  static const _reconciliationCases = {
    'receipt subtotal equals line totals',
    'receipt total equals subtotal plus tax',
    'line total equals quantity times unit price',
    'pack count divides line total',
    'discount applies once',
    'return is negative',
    'tax allocation sums back to receipt tax',
    'rounding remainder is tracked',
    'partial receipt warns',
    'duplicate receipt warns',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _financialFields.length;
    _requireTokens(
      failures,
      source,
      _financialFields,
      idPrefix: 'missing_financial_field',
      message: 'Financial duplicate guard QA is missing a financial field.',
      fix:
          'Financial QA must track unit/extended price, quantity, packs, subtotal, tax, total, discounts, returns, voids, and mismatch warnings.',
      triage: QaFailureTriage.economics,
    );

    checked += _duplicateCostRules.length;
    _requireRules(failures, source, _duplicateCostRules);

    checked += _destinationLedgers.length;
    _requireTokens(
      failures,
      source,
      _destinationLedgers,
      idPrefix: 'missing_destination_ledger',
      message: 'Financial duplicate guard QA is missing a destination ledger.',
      fix:
          'Cost writes must be tracked separately for inventory, jobs, estimates, invoices, vehicle/shop inventory, audit trail, review candidates, and approved records.',
      triage: QaFailureTriage.reviewSafety,
    );

    checked += _reconciliationCases.length;
    _requireTokens(
      failures,
      source,
      _reconciliationCases,
      idPrefix: 'missing_reconciliation_case',
      message: 'Financial duplicate guard QA is missing a reconciliation case.',
      fix:
          'Add reconciliation fixtures for subtotals, totals, tax allocation, line math, packs, discounts, returns, rounding, partial receipts, and duplicate receipts.',
      triage: QaFailureTriage.economics,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'A receipt line or total can feed multiple reviewed destinations, but it must never duplicate cost, tax, quantity, or inventory value silently.',
      },
    );
  }

  void _requireRules(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = source.toLowerCase();
    for (final rule in rules) {
      if (lower.contains(rule.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_financial_duplicate_rule:${_safeId(rule)}',
          message: 'Financial duplicate guard QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit duplicate-cost and reconciliation rules before parser output can feed inventory, jobs, estimates, or invoices.',
          triage: QaFailureTriage.economics,
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
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
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
