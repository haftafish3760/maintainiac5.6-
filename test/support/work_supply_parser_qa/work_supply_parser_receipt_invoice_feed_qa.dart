import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptInvoiceFeedSuite extends QaSuite {
  const WorkSupplyParserReceiptInvoiceFeedSuite()
    : super('inventory.receipt_invoice_feed_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_invoice_feed_qa.dart',
    'docs/inventory_parser_qa_master_coverage_matrix.md',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_job_context_bridge_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_category_inference_qa.dart',
  };

  static const _feedTargets = {
    'receipt',
    'inventory',
    'draft estimate',
    'estimate',
    'active job',
    'invoice',
    'job material',
    'billable material',
    'trade section',
    'category of work',
    'grand total',
    'customer approval',
  };

  static const _feedRules = {
    'receipt_feed_creates_review_candidate_not_write',
    'estimate_feed_keeps_source_estimate_unchanged',
    'invoice_feed_keeps_source_invoice_unchanged',
    'job_feed_keeps_source_job_unchanged',
    'accepted_candidate_creates_destination_record',
    'rejected_candidate_leaves_all_sources_unchanged',
    'mixed_trade_receipt_routes_by_section',
    'ambiguous_trade_requires_review',
    'destination_change_requires_new_review',
    'source_line_reference_is_preserved',
    'source_hash_is_preserved',
    'feed_action_is_audited',
  };

  static const _sectionCases = {
    'plumbing section',
    'electrical section',
    'HVAC section',
    'fastener section',
    'mixed remodel',
    'service call',
    'renovation',
    'material only',
    'labor plus material',
    'taxable material',
    'non-taxable material',
    'markup material',
  };

  static const _sourceMutationGuards = {
    'no source mutation',
    'immutable source',
    'candidate copy',
    'review-only',
    'warnings',
    'missing fields',
    'confidence reasons',
    'ranked candidates',
    'audit trail',
    'rollback',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _feedTargets.length;
    _requireTokens(
      failures,
      source,
      _feedTargets,
      idPrefix: 'missing_feed_target',
      message: 'Receipt/invoice feed QA is missing a workflow target.',
      fix:
          'Parser output must be able to feed review candidates into inventory, draft estimates, estimates, active jobs, invoices, job materials, billable material, and trade sections.',
      triage: QaFailureTriage.category,
    );

    checked += _feedRules.length;
    _requireRules(failures, source, _feedRules);

    checked += _sectionCases.length;
    _requireTokens(
      failures,
      source,
      _sectionCases,
      idPrefix: 'missing_feed_section_case',
      message: 'Receipt/invoice feed QA is missing a job/estimate section case.',
      fix:
          'Add feed cases for plumbing, electrical, HVAC, fasteners, mixed remodels, service calls, renovations, material-only, labor/material, tax, and markup.',
      triage: QaFailureTriage.context,
    );

    checked += _sourceMutationGuards.length;
    _requireTokens(
      failures,
      source,
      _sourceMutationGuards,
      idPrefix: 'missing_feed_source_guard',
      message: 'Receipt/invoice feed QA is missing source mutation guard language.',
      fix:
          'Feeding parser candidates to workflows must preserve source references, create candidate copies, show warnings, keep ranked candidates, audit action, and support rollback.',
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
            'Receipt lines can feed inventory, estimates, active jobs, and invoices only through review candidates that preserve source identity and do not mutate originals.',
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
          id: 'missing_receipt_invoice_feed_rule:${_safeId(rule)}',
          message: 'Receipt/invoice feed QA is missing a named workflow rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit feed rules so parser candidates cannot silently mutate receipts, estimates, jobs, invoices, or destination ledgers.',
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
