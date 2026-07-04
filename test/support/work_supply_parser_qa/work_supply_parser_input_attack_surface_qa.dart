import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserInputAttackSurfaceSuite extends QaSuite {
  const WorkSupplyParserInputAttackSurfaceSuite()
    : super('inventory.input_attack_surface_contract');

  static const _sourcePaths = {
    'docs/inventory_parser_qa_master_coverage_matrix.md',
    'docs/release_100_percent_required_qa_gates.md',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_source_immutability_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_search_indexing_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_import_export_safety_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_parser_fuzz_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_barcode_inventory_identity_qa.dart',
    'test/work_supply_parser_input_attack_surface_behavior_test.dart',
    'lib/shared/data_export/csv_writer.dart',
  };

  static const _inputSurfaces = {
    'search bar',
    'receipt line',
    'custom item name',
    'alias',
    'merchant name',
    'SKU',
    'UPC',
    'GTIN',
    'barcode',
    'bin number',
    'drawer',
    'vehicle location',
    'import file',
    'admin filter',
    'diagnostic filter',
  };

  static const _sourceModalities = {
    'photo_ocr_text_after_extraction',
    'uploaded_pdf_text_after_extraction',
    'emailed_receipt_text_after_extraction',
    'manual_pasted_receipt_text',
    'invoice_style_material_line_text',
    'quote_style_material_line_text',
    'packing_slip_material_list_text',
    'counter_sale_material_receipt_text',
    'generic_unknown_merchant_receipt_text',
    'local_regional_supplier_receipt_text',
  };

  static const _hostileInputs = {
    'SQL injection',
    'NoSQL injection',
    'path traversal',
    'script tag',
    'command-looking text',
    'regex backtracking',
    'CSV formula injection',
    'malformed JSON',
    'malformed CSV',
    'huge input',
    'repeated tokens',
    'long token',
    'null byte',
    'control character',
    'unicode override',
    'emoji',
    'right-to-left override',
    'HTML entity',
    'URL',
    'file path',
    'environment variable',
  };

  static const _securityRules = {
    'all_user_text_input_is_hostile',
    'input_attack_never_executes_code',
    'input_attack_never_changes_file_path',
    'input_attack_never_changes_query_shape',
    'input_attack_never_creates_confident_match',
    'input_attack_never_auto_saves',
    'input_attack_never_logs_private_text',
    'input_attack_is_bounded_for_runtime',
    'input_attack_is_bounded_for_memory',
    'input_attack_keeps_review_status',
    'input_attack_returns_warning_or_unknown',
    'input_attack_preserves_raw_evidence_safely',
    'input_attack_redacts_reports',
    'input_attack_has_regression_fixture',
    'input_attack_has_focused_rerun',
    'input_attack_source_modality_is_hostile_text',
    'input_attack_source_modality_never_implies_truth',
    'input_attack_unknown_source_uses_generic_pipeline',
  };

  static const _protectedDestinations = {
    'Hive',
    'Firestore',
    'Firebase',
    'inventory',
    'estimate',
    'invoice',
    'active job',
    'admin report',
    'diagnostic report',
    'export',
    'import',
    'search index',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _inputSurfaces.length;
    _requireTokens(
      failures,
      source,
      _inputSurfaces,
      idPrefix: 'missing_input_surface',
      message: 'Input attack surface QA is missing a user-controlled input.',
      fix:
          'Every text, import, barcode, search, alias, merchant, location, and admin filter input must be treated as hostile.',
      triage: QaFailureTriage.security,
    );

    checked += _hostileInputs.length;
    _requireTokens(
      failures,
      source,
      _hostileInputs,
      idPrefix: 'missing_hostile_input',
      message: 'Input attack surface QA is missing hostile payload coverage.',
      fix:
          'Add hostile fixtures for injection-like strings, paths, scripts, regex traps, malformed data, huge/repeated input, Unicode controls, and private-looking values.',
      triage: QaFailureTriage.security,
    );

    checked += _sourceModalities.length;
    _requireTokens(
      failures,
      source,
      _sourceModalities,
      idPrefix: 'missing_hostile_source_modality',
      message: 'Input attack surface QA is missing a receipt/source modality.',
      fix:
          'Every extracted text source must be treated as hostile parser input: OCR text, PDF text, emailed text, pasted text, invoice/quote/packing-slip text, counter-sale text, unknown merchants, and local suppliers.',
      triage: QaFailureTriage.security,
    );

    checked += _securityRules.length;
    _requireRules(failures, source, _securityRules);

    checked += _protectedDestinations.length;
    _requireTokens(
      failures,
      source,
      _protectedDestinations,
      idPrefix: 'missing_protected_destination',
      message: 'Input attack surface QA is missing a protected destination.',
      fix:
          'Hostile input tests must prove parser/search/import text cannot corrupt Hive, mirrors, inventory workflows, admin reports, exports, imports, or indexes.',
      triage: QaFailureTriage.security,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Every inventory parser/search/import/admin text surface is hostile input and must be bounded, redacted, review-only, and unable to mutate protected destinations.',
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
          id: 'missing_input_attack_rule:${_safeId(rule)}',
          message: 'Input attack surface QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add explicit hostile-input rules before any user-controlled text can feed parser, search, import, export, admin, sync, or storage code.',
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
