import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserVendorSkuMatrixSuite extends QaSuite {
  const WorkSupplyParserVendorSkuMatrixSuite()
    : super('inventory.vendor_sku_matrix_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_readiness_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_merchant_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_catalog_item_batch_generation_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_item_promotion_gate_qa.dart',
  };

  static const _vendorIdentityTokens = {
    'Home Depot SKU',
    'Lowe',
    'Menards SKU',
    'Ferguson code',
    'Grainger',
    'SupplyHouse',
    'Manufacturer part number',
    'UPC',
    'GTIN',
    'brand name',
    'private-label',
    'store-specific short name',
  };

  static const _skuBehaviorTokens = {
    'vendorSku',
    'manufacturerPartNumber',
    'upc',
    'gtin',
    'storeItemNumber',
    'brand',
    'privateLabel',
    'skuPattern',
    'part-number',
    'receipt short name',
    'vendor mappings',
  };

  static const _negativeSafetyTokens = {
    'not enough evidence',
    'conflict rule',
    'ranked candidates',
    'needs review',
    'false confident',
    'do not auto-save',
    'ambiguous',
    'cross-trade',
    'wrong brand',
    'wrong material',
  };

  static const _residentialTradeTokens = {
    'plumbing',
    'electrical',
    'hvac',
    'fastener',
    'residential',
    'core',
    'standard',
    'professional',
    'complete',
  };

  static const _vendorReadyRules = {
    'sku_only_must_not_guess_trade',
    'sku_plus_merchant_can_boost',
    'sku_plus_brand_can_boost',
    'sku_plus_size_can_finalize',
    'part_number_collision_requires_review',
    'upc_collision_requires_review',
    'private_label_maps_to_canonical_item',
    'store_short_name_maps_to_alias_evidence',
    'missing_vendor_map_does_not_fail_item',
    'vendor_map_is_versioned',
    'official_pack_mappings_require_licensed_or_public_source',
    'retailer_database_scraping_is_forbidden',
    'merchant_sku_mapping_requires_source_confidence',
    'barcode_receipt_disagreement_requires_review',
    'barcode_can_boost_confidence_only_with_corroborating_evidence',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _vendorIdentityTokens.length;
    _requireAnyTokenSet(
      failures,
      source,
      _vendorIdentityTokens,
      idPrefix: 'missing_vendor_identity',
      message: 'Vendor/SKU identity coverage is incomplete.',
      fix:
          'Inventory parser QA must prove major-store SKU, UPC/GTIN, brand, private-label, manufacturer part, and store-short-name support.',
    );

    checked += _skuBehaviorTokens.length;
    _requireAnyTokenSet(
      failures,
      source,
      _skuBehaviorTokens,
      idPrefix: 'missing_sku_behavior',
      message: 'Vendor/SKU parser behavior contract is incomplete.',
      fix:
          'Add SKU behavior requirements for merchant-aware boosts, part-number parsing, canonical mappings, and vendor-specific short names.',
    );

    checked += _negativeSafetyTokens.length;
    _requireAnyTokenSet(
      failures,
      source,
      _negativeSafetyTokens,
      idPrefix: 'missing_vendor_safety',
      message: 'Vendor/SKU safety rules do not prove conservative matching.',
      fix:
          'Vendor/SKU matches must still be review-only when brand, material, trade, UPC, or part-number evidence conflicts.',
    );

    checked += _residentialTradeTokens.length;
    _requireAnyTokenSet(
      failures,
      source,
      _residentialTradeTokens,
      idPrefix: 'missing_trade_pack_axis',
      message: 'Vendor/SKU QA is missing residential trade-pack axes.',
      fix:
          'Vendor/SKU tests must cover plumbing, electrical, HVAC, fasteners, and all release-one residential pack tiers.',
    );

    checked += _vendorReadyRules.length;
    _requireRuleNames(failures, source, _vendorReadyRules);

    checked += 6;
    _requireMatrixShape(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Vendor/SKU evidence can boost ranking, but never bypass ambiguity, review status, or conflict rules.',
      },
    );
  }

  void _requireRuleNames(
    List<QaFailure> failures,
    String source,
    Set<String> rules,
  ) {
    final lower = source.toLowerCase();
    for (final rule in rules) {
      if (lower.contains(rule.toLowerCase())) continue;
      failures.add(
        _failure(
          id: 'missing_vendor_rule:${_safeId(rule)}',
          message: 'Vendor/SKU matrix is missing a named safety rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add this rule to the vendor/SKU QA contract before bulk catalog promotion.',
        ),
      );
    }
  }

  void _requireMatrixShape(String source, List<QaFailure> failures) {
    const axes = {
      'merchantAxis': ['home depot', 'lowe', 'ace', 'ferguson', 'grainger'],
      'identifierAxis': ['sku', 'upc', 'gtin', 'part number', 'brand'],
      'tradeAxis': ['plumbing', 'electrical', 'hvac'],
      'tierAxis': ['core', 'standard', 'professional', 'complete'],
      'localeAxis': ['en-us', 'es-us', 'spanish'],
      'resultAxis': ['review', 'ranked', 'unknown', 'confidence'],
    };
    final lower = source.toLowerCase();
    for (final entry in axes.entries) {
      final missing = entry.value
          .where((token) => !lower.contains(token))
          .toList(growable: false);
      if (missing.isEmpty) continue;
      failures.add(
        _failure(
          id: 'missing_vendor_matrix_axis:${entry.key}',
          message: 'Vendor/SKU matrix is missing required axis coverage.',
          expected: entry.value.join(', '),
          actual: 'missing ${missing.join(', ')}',
          fix:
              'Vendor/SKU QA must prove merchant, identifier, trade, tier, locale, and parser-result axes.',
        ),
      );
    }
  }

  void _requireAnyTokenSet(
    List<QaFailure> failures,
    String source,
    Set<String> tokens, {
    required String idPrefix,
    required String message,
    required String fix,
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
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': QaFailureTriage.schema},
    );
  }
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
