import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserBarcodeInventoryIdentitySuite extends QaSuite {
  const WorkSupplyParserBarcodeInventoryIdentitySuite()
    : super('inventory.barcode_inventory_identity_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_item_metadata_depth_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_vendor_sku_matrix_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_workflow_routing_qa.dart',
  };

  static const _identityTokens = {
    'barcode',
    'UPC',
    'GTIN',
    'user item id',
    'internal item id',
    'vehicle location',
    'bin number',
    'drawer',
    'truck',
    'fleet',
  };

  static const _identityRules = {
    'user_item_id_does_not_replace_stable_catalog_id',
    'barcode_can_link_to_canonical_item',
    'barcode_collision_requires_review',
    'barcode_mapping_requires_user_confirmation',
    'unknown_barcode_stays_review_only',
    'barcode_evidence_never_bypasses_conflict_rules',
    'user_scanned_barcode_maps_to_private_inventory_memory_first',
    'barcode_receipt_disagreement_requires_review',
    'barcode_can_boost_confidence_only_with_corroborating_evidence',
    'vehicle_location_is_user_inventory_metadata',
    'bin_drawer_location_is_not_parser_identity',
    'fleet_vehicle_inventory_is_separate_from_catalog',
    'same_catalog_item_can_exist_on_multiple_vehicles',
    'user_custom_item_keeps_source_metadata',
    'barcode_scan_can_create_review_candidate',
    'barcode_missing_does_not_block_receipt_parser',
  };

  static const _inventoryDestinations = {
    'on hand',
    'out of stock',
    'purchased not in stock',
    'job staging',
    'vehicle inventory',
    'shop inventory',
    'employee',
    'permission',
    'owner',
    'review-only',
    'private local inventory memory',
    'reviewed correction workflow',
  };

  static const _provenanceTokens = {
    'licensed',
    'reviewed public',
    'manual',
    'synthetic provenance',
    'source confidence',
    'version metadata',
    'retailer database scraping is forbidden',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _identityTokens.length;
    _requireTokens(
      failures,
      source,
      _identityTokens,
      idPrefix: 'missing_barcode_identity_token',
      message: 'Barcode/inventory identity QA is missing identity vocabulary.',
      fix:
          'Catalog QA must plan for barcode, UPC/GTIN, user item IDs, vehicle/bin/drawer locations, trucks, and fleet inventory.',
      triage: QaFailureTriage.schema,
    );

    checked += _identityRules.length;
    _requireRules(failures, source, _identityRules);

    checked += _inventoryDestinations.length;
    _requireTokens(
      failures,
      source,
      _inventoryDestinations,
      idPrefix: 'missing_inventory_destination',
      message:
          'Barcode/inventory identity QA is missing inventory destinations.',
      fix:
          'Parser output must distinguish catalog identity from user inventory placement, stock status, job staging, vehicles, employees, and permissions.',
      triage: QaFailureTriage.category,
    );

    checked += _provenanceTokens.length;
    _requireTokens(
      failures,
      source,
      _provenanceTokens,
      idPrefix: 'missing_barcode_provenance_token',
      message: 'Barcode/vendor identity QA is missing source-provenance gates.',
      fix:
          'Barcode, UPC, GTIN, and vendor SKU evidence must require licensed/public/manual/synthetic provenance, source confidence, and no retailer scraping.',
      triage: QaFailureTriage.governance,
    );

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Barcode/user inventory metadata augments canonical catalog identity without replacing parser-safe item IDs or review gates.',
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
          id: 'missing_barcode_identity_rule:${_safeId(rule)}',
          message: 'Barcode/inventory identity QA is missing a named rule.',
          expected: rule,
          actual: 'not found',
          fix:
              'Add identity rules before catalog items are used for barcode scans, vehicle bins, fleets, or user-created IDs.',
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
