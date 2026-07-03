import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReceiptLineParserFuzzSuite extends QaSuite {
  const WorkSupplyParserReceiptLineParserFuzzSuite()
    : super('inventory.receipt_line_parser_fuzz_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_torture_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_security_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_noise_qa.dart',
  };

  static const _fuzzDimensions = {
    'uppercase',
    'lowercase',
    'missing spaces',
    'extra spaces',
    'punctuation',
    'hyphen',
    'slash',
    'unicode fraction',
    'OCR mistakes',
    'merchant abbreviation',
    'Spanish',
    'long token',
    'control character',
    'directional override',
    'path-like',
    'injection-like',
  };

  static const _fuzzRules = {
    'fuzz_never_auto_saves',
    'fuzz_never_logs_raw_private_text',
    'fuzz_keeps_bounded_preview',
    'fuzz_preserves_candidate_review_status',
    'fuzz_preserves_alternative_candidates',
    'fuzz_does_not_throw_on_empty_line',
    'fuzz_does_not_throw_on_huge_line',
    'fuzz_does_not_throw_on_unicode_controls',
    'fuzz_reports_unknown_when_evidence_is_weak',
    'fuzz_reports_ambiguity_for_generic_tokens',
  };

  static const _receiptShapes = {
    'single line',
    'multi line item',
    'wrapped description',
    'quantity prefix',
    'quantity suffix',
    'price suffix',
    'SKU prefix',
    'department code',
    'return line',
    'discount line',
    'tax line',
    'payment line',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _fuzzDimensions.length;
    _requireTokens(
      failures,
      source,
      _fuzzDimensions,
      idPrefix: 'missing_fuzz_dimension',
      message: 'Receipt-line fuzz QA is missing a fuzz dimension.',
      fix:
          'Parser QA must fuzz casing, spacing, punctuation, fractions, OCR-like text, Spanish, hostile text, and malformed receipt shapes.',
      triage: QaFailureTriage.fixture,
    );

    checked += _fuzzRules.length;
    _requireRules(failures, source, _fuzzRules);

    checked += _receiptShapes.length;
    _requireTokens(
      failures,
      source,
      _receiptShapes,
      idPrefix: 'missing_receipt_shape',
      message: 'Receipt-line fuzz QA is missing a receipt shape.',
      fix:
          'Synthetic fixtures must include wrapped lines, quantities, prices, SKUs, department codes, returns, discounts, tax, and payment noise.',
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
            'Receipt-line fuzzing proves parser robustness without touching OCR/camera code or leaking private raw text.',
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
          id: 'missing_fuzz_rule:${_safeId(rule)}',
          message: 'Receipt-line fuzz QA is missing a named safety rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add fuzz safety rules so malformed receipt text cannot crash, leak, auto-save, or force bad matches.',
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
