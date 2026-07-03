import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptLineMappingSuite extends QaSuite {
  const WorkSupplyParserReceiptLineMappingSuite()
    : super('inventory.receipt_line_mapping_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_mapping_qa.dart',
    'docs/inventory_parser_qa_master_coverage_matrix.md',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_torture_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_parser_fuzz_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_financial_duplicate_guard_qa.dart',
  };

  static const _lineShapes = {
    'single line item',
    'wrapped line item',
    'multi line item',
    'quantity prefix',
    'quantity suffix',
    'unit price suffix',
    'extended price suffix',
    'SKU prefix',
    'department code prefix',
    'return line',
    'discount line',
    'tax line',
    'payment line',
    'subtotal line',
    'total line',
  };

  static const _mappingOutputs = {
    'source line id',
    'raw line',
    'normalized line',
    'item candidate',
    'quantity',
    'unit price',
    'extended price',
    'tax evidence',
    'discount evidence',
    'return evidence',
    'warnings',
    'review status',
    'ranked candidates',
    'destination action',
  };

  static const _mappingRules = {
    'receipt_line_mapping_preserves_source_line_id',
    'receipt_line_mapping_preserves_raw_line',
    'receipt_line_mapping_never_maps_totals_as_items',
    'receipt_line_mapping_never_maps_payment_as_item',
    'receipt_line_mapping_keeps_noise_lines_separate',
    'receipt_line_mapping_handles_wrapped_descriptions',
    'receipt_line_mapping_handles_quantity_and_price',
    'receipt_line_mapping_handles_returns_and_discounts',
    'receipt_line_mapping_requires_review_for_ambiguous_item',
    'receipt_line_mapping_does_not_duplicate_destination_records',
    'receipt_line_mapping_is_idempotent_for_same_receipt',
    'receipt_line_mapping_can_emit_unknown_item',
  };

  static const _noiseLines = {
    'subtotal',
    'sales tax',
    'total',
    'cash',
    'credit card',
    'auth code',
    'receipt number',
    'survey',
    'thank you',
    'store address',
    'return policy',
    'balance due',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _lineShapes.length;
    _requireTokens(
      failures,
      source,
      _lineShapes,
      idPrefix: 'missing_line_shape',
      message: 'Receipt line mapping QA is missing a receipt line shape.',
      fix:
          'Receipt mapping QA must cover single, wrapped, multi-line, quantity, price, SKU, department, return, discount, tax, payment, subtotal, and total lines.',
      triage: QaFailureTriage.fixture,
    );

    checked += _mappingOutputs.length;
    _requireTokens(
      failures,
      source,
      _mappingOutputs,
      idPrefix: 'missing_mapping_output',
      message: 'Receipt line mapping QA is missing parser output evidence.',
      fix:
          'Receipt line mapping must preserve source ids/raw lines and emit normalized line, candidates, quantities, prices, tax/discount/return evidence, warnings, review status, and destination actions.',
      triage: QaFailureTriage.schema,
    );

    checked += _mappingRules.length;
    _requireRules(failures, source, _mappingRules);

    checked += _noiseLines.length;
    _requireTokens(
      failures,
      source,
      _noiseLines,
      idPrefix: 'missing_noise_line',
      message: 'Receipt line mapping QA is missing noise line coverage.',
      fix:
          'Receipt mapping must keep subtotal, tax, total, payment, auth, survey, address, policy, and balance lines separate from inventory items.',
      triage: QaFailureTriage.fixture,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Receipt line mapping preserves source lines, separates noise from item candidates, attaches math evidence, and remains idempotent.',
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
          id: 'missing_receipt_line_mapping_rule:${_safeId(rule)}',
          message: 'Receipt line mapping QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit receipt line mapping rules before item candidates feed inventory, estimates, jobs, or invoices.',
          triage: QaFailureTriage.fixture,
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
