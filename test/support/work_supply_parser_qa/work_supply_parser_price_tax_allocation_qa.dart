import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPriceTaxAllocationSuite extends QaSuite {
  const WorkSupplyParserPriceTaxAllocationSuite()
    : super('inventory.price_tax_allocation_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_math_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_torture_qa.dart',
  };

  static const _priceEvidenceTokens = {
    'unit price',
    'extended price',
    'quantity',
    'pack quantity',
    'contractor pack',
    'line subtotal',
    'discount',
    'coupon',
    'return',
    'negative quantity',
    'tax',
    'sales tax',
    'total',
  };

  static const _allocationRules = {
    'tax_per_item_allocation',
    'discount_per_item_allocation',
    'return_line_not_inventory_add',
    'void_line_not_inventory_add',
    'line_total_beats_unit_guess',
    'pack_count_divides_cost',
    'quantity_multiplier_preserved',
    'receipt_total_is_noise',
    'sales_tax_is_not_item',
    'confidence_warns_on_math_mismatch',
  };

  static const _workflowTokens = {
    'estimate',
    'active job',
    'invoice',
    'inventory',
    'job material',
    'billable material',
    'default markup',
    'default unit cost',
    'tax/reporting category',
    'review-only',
  };

  static const _dangerousMathLines = {
    'SUBTOTAL 52.40',
    'SALES TAX 3.46',
    'TOTAL 55.86',
    'RET 1/2 PEX ELL -2.99',
    'DISC 10% PVC PIPE',
    '2PK WAX RING 8.98',
    '10CT WIRE NUT 4.98',
    'QTY 4 1/2 CPVC CPLG 1.29',
    'CARD **** 1234',
    'BALANCE DUE 0.00',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _priceEvidenceTokens.length;
    _requireTokens(
      failures,
      source,
      _priceEvidenceTokens,
      idPrefix: 'missing_price_evidence',
      message: 'Price/tax parser evidence coverage is incomplete.',
      fix:
          'Parser QA must prove quantity, unit price, extended price, pack quantity, returns, discounts, tax, and totals are handled separately from item identity.',
      triage: QaFailureTriage.schema,
    );

    checked += _allocationRules.length;
    _requireRules(failures, source, _allocationRules);

    checked += _workflowTokens.length;
    _requireTokens(
      failures,
      source,
      _workflowTokens,
      idPrefix: 'missing_workflow_price_token',
      message: 'Price/tax parser contract is missing workflow routing coverage.',
      fix:
          'Price/tax evidence must travel with review-only parser candidates into inventory, estimates, active jobs, and invoices without auto-saving.',
      triage: QaFailureTriage.governance,
    );

    checked += _dangerousMathLines.length;
    _requireDangerousLineCoverage(failures, source);

    checked += 5;
    _requirePrivacyAndSafety(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Receipt math is evidence attached to a candidate, not proof of item identity and never a reason to auto-save.',
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
          id: 'missing_allocation_rule:${_safeId(rule)}',
          message: 'Price/tax QA is missing a named allocation rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit allocation rules so tax, discounts, returns, and pack math do not corrupt inventory/job costs.',
          triage: QaFailureTriage.economics,
        ),
      );
    }
  }

  void _requireDangerousLineCoverage(
    List<QaFailure> failures,
    String source,
  ) {
    final lower = _normalizeContractText(source);
    for (final line in _dangerousMathLines) {
      final requiredTokens = line
          .toLowerCase()
          .split(RegExp(r'[^a-z0-9/]+'))
          .where((token) => token.length > 2)
          .take(2)
          .toList(growable: false);
      if (requiredTokens.every(lower.contains)) continue;
      failures.add(
        _failure(
          id: 'missing_math_torture_line:${_safeId(line)}',
          message: 'Price/tax torture corpus is missing a receipt math case.',
          expected: line,
          actual: 'not represented',
          fix:
              'Add synthetic receipt fixtures for totals, sales tax, returns, discounts, pack counts, quantities, and payment lines.',
          triage: QaFailureTriage.fixture,
        ),
      );
    }
  }

  void _requirePrivacyAndSafety(String source, List<QaFailure> failures) {
    const tokens = {
      'card',
      'redact',
      'no raw receipt',
      'privacy',
      'review',
    };
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: 'missing_price_privacy_safety:${_safeId(token)}',
          message: 'Price/tax diagnostics are missing a privacy/safety guard.',
          expected: token,
          actual: 'not found',
          fix:
              'Price/tax reports must redact payment/customer data and keep all workflow writes review-only.',
          triage: QaFailureTriage.security,
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
