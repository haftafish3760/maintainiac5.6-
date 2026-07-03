import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserProductNormalizationSuite extends QaSuite {
  const WorkSupplyParserProductNormalizationSuite()
    : super('inventory.product_normalization_contract');

  static const _sourcePaths = {
    'test/support/work_supply_parser_qa/work_supply_parser_product_normalization_qa.dart',
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_metamorphic_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_property_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_item_metadata_depth_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_receipt_line_parser_fuzz_qa.dart',
  };

  static const _normalizationAxes = {
    'size normalization',
    'unit normalization',
    'material normalization',
    'brand normalization',
    'shape normalization',
    'connection normalization',
    'pack quantity normalization',
    'trade normalization',
    'locale normalization',
    'merchant normalization',
    'SKU normalization',
    'UPC normalization',
    'GTIN normalization',
  };

  static const _sizeUnitCases = {
    '1/2',
    '1/2 in',
    '.5',
    '0.5 inch',
    'half inch',
    '½',
    '3/4',
    'ninety',
    '90 degree',
    '90 deg',
    '10 pack',
    '10PK',
    '10 ct',
  };

  static const _normalizationRules = {
    'normalization_preserves_raw_evidence',
    'normalization_is_deterministic',
    'normalization_is_locale_aware',
    'normalization_is_merchant_aware',
    'normalization_does_not_create_confident_match_by_itself',
    'normalization_keeps_conflicting_tokens_visible',
    'normalization_maps_unicode_fractions',
    'normalization_maps_spelled_sizes',
    'normalization_maps_pack_counts',
    'normalization_maps_abbreviated_units',
    'normalization_keeps_unknown_tokens_for_review',
    'normalization_outputs_explainable_tokens',
  };

  static const _dangerousNormalizationInputs = {
    'PVC',
    'pipe',
    'wire',
    'box',
    'adapter',
    'coupling',
    'filter',
    'tape',
    'black',
    'white',
    'cement',
    'primer',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _normalizationAxes.length;
    _requireTokens(
      failures,
      source,
      _normalizationAxes,
      idPrefix: 'missing_normalization_axis',
      message: 'Product normalization QA is missing a normalization axis.',
      fix:
          'Add explicit normalization QA for size, unit, material, brand, shape, connection, pack quantity, trade, locale, merchant, SKU, UPC, and GTIN.',
      triage: QaFailureTriage.normalization,
    );

    checked += _sizeUnitCases.length;
    _requireTokens(
      failures,
      source,
      _sizeUnitCases,
      idPrefix: 'missing_size_unit_case',
      message: 'Product normalization QA is missing a real receipt size/unit form.',
      fix:
          'Normalization fixtures must include fractions, decimals, spelled sizes, Unicode fractions, degree words, abbreviations, pack counts, and count forms.',
      triage: QaFailureTriage.normalization,
    );

    checked += _normalizationRules.length;
    _requireRules(failures, source, _normalizationRules);

    checked += _dangerousNormalizationInputs.length;
    _requireDangerousInputs(failures, source);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Normalization converts messy evidence into explainable tokens while preserving raw evidence and never creating certainty by itself.',
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
          id: 'missing_product_normalization_rule:${_safeId(rule)}',
          message: 'Product normalization QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add deterministic, explainable, locale/merchant-aware normalization rules before parser matching relies on normalized tokens.',
          triage: QaFailureTriage.normalization,
        ),
      );
    }
  }

  void _requireDangerousInputs(
    List<QaFailure> failures,
    String source,
  ) {
    final lower = source.toLowerCase();
    for (final input in _dangerousNormalizationInputs) {
      final hasInput = lower.contains(input.toLowerCase());
      final hasSafety =
          lower.contains('dangerous') ||
          lower.contains('ambiguous') ||
          lower.contains('needs review') ||
          lower.contains('not confident');
      if (hasInput && hasSafety) continue;
      failures.add(
        _failure(
          id: 'missing_dangerous_normalization_case:${_safeId(input)}',
          message:
              'Product normalization QA is missing a dangerous generic token guard.',
          expected: input,
          actual: 'not covered with ambiguity/review safety language',
          fix:
              'Generic normalized terms like PVC, pipe, wire, box, tape, and filter must not create confident matches without corroborating evidence.',
          triage: QaFailureTriage.conflict,
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
