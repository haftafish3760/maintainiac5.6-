import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptSourceImmutabilitySuite extends QaSuite {
  const WorkSupplyParserReceiptSourceImmutabilitySuite()
    : super('inventory.receipt_source_immutability_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_result_contract_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_price_tax_allocation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_duplicate_receipt_import_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_review_safety_qa.dart',
  };

  static const _sourceTokens = {
    'raw evidence',
    'source line',
    'receipt line',
    'line item',
    'parser candidate',
    'review status',
    'suggested action',
    'warnings',
    'missing fields',
    'confidence reasons',
    'invoice',
    'estimate',
    'active job',
  };

  static const _sourceAdapterModalities = {
    'photo-assisted OCR text after extraction',
    'uploaded PDF text after extraction',
    'emailed receipt text after extraction',
    'manual pasted receipt text',
    'invoice-style material line text',
    'quote-style material line text',
    'packing-slip-like material list text',
    'counter-sale material receipt text',
    'generic unknown merchant receipt text',
    'local or regional supplier receipt text',
  };

  static const _immutabilityRules = {
    'parser_never_mutates_receipt_source',
    'parser_never_mutates_invoice_source',
    'parser_never_mutates_estimate_source',
    'parser_never_mutates_job_source',
    'parser_output_is_candidate_copy',
    'receipt_source_hash_is_stable',
    'candidate_keeps_raw_evidence_reference',
    'financial_totals_do_not_change_source_total',
    'review_acceptance_creates_new_destination_record',
    'review_rejection_leaves_sources_unchanged',
  };

  static const _sourceAdapterRules = {
    'source_adapter_extracts_text_before_parser',
    'parser_core_does_not_run_ocr',
    'parser_core_does_not_read_pdf_files',
    'parser_core_does_not_fetch_email',
    'parser_core_does_not_open_camera',
    'parser_core_accepts_plain_text_from_any_adapter',
    'source_type_is_evidence_not_truth',
    'unknown_source_uses_generic_receipt_pipeline',
    'source_modality_must_not_auto_confirm_candidate',
    'source_fingerprint_preserved_across_review',
  };

  static const _destinationMappings = {
    'add to inventory',
    'add to estimate',
    'add to draft estimate',
    'add to active job',
    'add to invoice',
    'job material',
    'billable material',
    'expense category',
    'tax/reporting category',
    'default markup',
  };

  static const _financialSafetyTokens = {
    'subtotal',
    'sales tax',
    'total',
    'unit price',
    'extended price',
    'quantity',
    'pack quantity',
    'discount',
    'return',
    'math mismatch',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _sourceTokens.length;
    _requireTokens(
      failures,
      source,
      _sourceTokens,
      idPrefix: 'missing_source_token',
      message: 'Receipt/source immutability QA is missing parser source/result vocabulary.',
      fix:
          'Parser QA must explicitly track raw evidence, source lines, candidates, review status, suggested action, warnings, missing fields, and confidence reasons.',
      triage: QaFailureTriage.schema,
    );

    checked += _sourceAdapterModalities.length;
    _requireTokens(
      failures,
      source,
      _sourceAdapterModalities,
      idPrefix: 'missing_source_adapter_modality',
      message: 'Receipt/source immutability QA is missing a parser source modality.',
      fix:
          'Parser QA must treat photo/OCR, PDF, email, manual paste, invoice, quote, packing slip, counter-sale, unknown merchant, and regional supplier text as adapter-fed plain text sources.',
      triage: QaFailureTriage.schema,
    );

    checked += _immutabilityRules.length;
    _requireRules(failures, source, _immutabilityRules);

    checked += _sourceAdapterRules.length;
    _requireRules(failures, source, _sourceAdapterRules);

    checked += _destinationMappings.length;
    _requireTokens(
      failures,
      source,
      _destinationMappings,
      idPrefix: 'missing_destination_mapping',
      message: 'Receipt/source immutability QA is missing workflow destination coverage.',
      fix:
          'Parser candidates must feed inventory, estimates, draft estimates, active jobs, invoices, job materials, billable materials, expense/tax categories, and markup without mutating sources.',
      triage: QaFailureTriage.category,
    );

    checked += _financialSafetyTokens.length;
    _requireTokens(
      failures,
      source,
      _financialSafetyTokens,
      idPrefix: 'missing_financial_source_safety',
      message: 'Receipt/source immutability QA is missing financial total safety.',
      fix:
          'Financial parsing must preserve source totals while attaching quantity, tax, discount, return, pack, and mismatch evidence to review candidates.',
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
            'Receipt, invoice, estimate, job, OCR-text, PDF-text, email-text, pasted-text, and supplier-material sources are immutable plain-text inputs; parser output is a review-only candidate copy with financial evidence attached.',
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
          id: 'missing_source_immutability_rule:${_safeId(rule)}',
          message: 'Receipt/source immutability QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit source immutability rules before parser output feeds inventory, estimates, active jobs, or invoices.',
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
