import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserJobContextBridgeSuite extends QaSuite {
  const WorkSupplyParserJobContextBridgeSuite()
    : super('inventory.job_context_bridge_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_estimate_section_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_context_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_result_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_category_inference_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_invoice_feed_qa.dart',
  };

  static const _workflowTargets = {
    'inventory',
    'estimate',
    'draft estimate',
    'active job',
    'invoice',
    'job material',
    'billable material',
    'category of work',
    'trade section',
    'grand total',
  };

  static const _contextBoostInputs = {
    'selected job type',
    'enabled trade packs',
    'active plumbing estimate section',
    'active electrical estimate section',
    'active HVAC estimate section',
    'vehicle inventory',
    'previous corrections',
    'merchant type',
    'user business type',
    'mixed remodel',
  };

  static const _bridgeRules = {
    'context_boost_changes_ranking_not_truth',
    'mixed_trade_job_keeps_ambiguity_visible',
    'estimate_section_routes_candidate',
    'job_material_output_is_review_only',
    'inventory_add_is_review_only',
    'invoice_output_waits_for_user_approval',
    'workflow_action_is_suggested_not_executed',
    'candidate_keeps_raw_evidence',
    'candidate_keeps_confidence_reasons',
    'candidate_keeps_missing_fields',
  };

  static const _badBridgeOutcomes = {
    'auto-save',
    'silent job write',
    'silent invoice write',
    'silent inventory write',
    'hide ambiguity',
    'drop alternate candidates',
    'overwrite user correction',
    'cross-trade forced match',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _workflowTargets.length;
    _requireTokens(
      failures,
      source,
      _workflowTargets,
      idPrefix: 'missing_workflow_target',
      message: 'Job/estimate bridge QA is missing workflow target coverage.',
      fix:
          'Parser candidates must be able to route to inventory, draft estimates, active jobs, invoices, and trade sections without forcing writes.',
      triage: QaFailureTriage.governance,
    );

    checked += _contextBoostInputs.length;
    _requireTokens(
      failures,
      source,
      _contextBoostInputs,
      idPrefix: 'missing_context_input',
      message: 'Job/estimate bridge QA is missing context input coverage.',
      fix:
          'Context scoring must include job type, enabled packs, estimate section, vehicle inventory, merchant type, business type, and correction memory.',
      triage: QaFailureTriage.context,
    );

    checked += _bridgeRules.length;
    _requireRules(failures, source, _bridgeRules);

    checked += _badBridgeOutcomes.length;
    _requireBadOutcomeGuards(failures, source);

    checked += 4;
    _requireReviewOnlyShape(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Inventory parser output can suggest inventory/job/estimate/invoice routing, but all writes remain review-only.',
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
          id: 'missing_job_context_rule:${_safeId(rule)}',
          message: 'Job/estimate bridge QA is missing a named parser rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add this rule to keep workflow routing explainable, review-only, and safe for mixed-trade jobs.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireBadOutcomeGuards(List<QaFailure> failures, String source) {
    final lower = source.toLowerCase();
    for (final outcome in _badBridgeOutcomes) {
      if (lower.contains(outcome.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_bad_outcome_guard:${_safeId(outcome)}',
          message: 'Job/estimate bridge QA is missing a forbidden outcome.',
          expected: outcome,
          actual: 'not found',
          fix:
              'QA must explicitly forbid silent writes, hidden ambiguity, dropped alternates, and forced cross-trade matches.',
          triage: QaFailureTriage.reviewSafety,
        ),
      );
    }
  }

  void _requireReviewOnlyShape(String source, List<QaFailure> failures) {
    const tokens = {
      'InventoryParseCandidate',
      'review status',
      'suggested action',
      'warnings',
    };
    final lower = source.toLowerCase();
    for (final token in tokens) {
      if (lower.contains(token.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_bridge_result_shape:${_safeId(token)}',
          message: 'Job/estimate bridge QA is missing parser result shape.',
          expected: token,
          actual: 'not found',
          fix:
              'Bridge output must use structured parser candidates with review status, suggested action, warnings, and preserved evidence.',
          triage: QaFailureTriage.schema,
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
