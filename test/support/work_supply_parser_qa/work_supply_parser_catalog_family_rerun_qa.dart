import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserCatalogFamilyRerunSuite extends QaSuite {
  const WorkSupplyParserCatalogFamilyRerunSuite()
    : super('inventory.catalog_family_rerun_contract');

  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';

  static const _familyRoutes = {
    'plumbing_pex': [
      'PEX',
      'work_supply_plumbing_core_receipt_parser_test.dart',
      'work_supply_plumbing_collision_receipt_parser_test.dart',
      'inventory.item_metadata_depth',
    ],
    'plumbing_pvc_dwv': [
      'PVC',
      'DWV',
      'work_supply_plumbing_bulk_receipt_parser_test.dart',
      'inventory.conflict_graph',
    ],
    'plumbing_valves_supply': [
      'valve',
      'angle stop',
      'work_supply_plumbing_merchant_receipt_parser_test.dart',
      'inventory.vendor_readiness',
    ],
    'plumbing_fasteners_supports': [
      'fastener',
      'hanger',
      'support',
      'work_supply_service_fastener_receipt_parser_test.dart',
    ],
    'electrical_wire_cable': [
      'wire',
      'cable',
      'NM-B',
      'inventory.trade_context',
    ],
    'electrical_boxes_devices': [
      'box',
      'device',
      'outlet',
      'inventory.dangerous_words',
    ],
    'electrical_conduit_fittings': [
      'conduit',
      'EMT',
      'PVC conduit',
      'inventory.conflict_graph',
    ],
    'electrical_breakers_panels': [
      'breaker',
      'panel',
      'disconnect',
      'inventory.vendor_readiness',
    ],
    'hvac_filters_airflow': [
      'filter',
      'airflow',
      'register',
      'inventory.dangerous_words',
    ],
    'hvac_controls_electrical': [
      'capacitor',
      'contactor',
      'thermostat',
      'inventory.trade_context',
    ],
    'hvac_condensate_drain': [
      'condensate',
      'PVC',
      'pump',
      'inventory.conflict_graph',
    ],
    'hvac_tape_duct_fasteners': [
      'foil tape',
      'duct',
      'sheet metal screw',
      'work_supply_service_fastener_receipt_parser_test.dart',
    ],
    'spanish_plumbing_core': [
      'es-US',
      'codo',
      'valvula',
      'work_supply_plumbing_spanish_receipt_parser_test.dart',
    ],
    'spanish_priority_trades': [
      'es-US',
      'spanish',
      'work_supply_priority_trades_spanish_receipt_parser_test.dart',
      'inventory.spanish_release_one',
    ],
  };

  static const _requiredRouteFields = {
    'familyId',
    'trade',
    'riskTerms',
    'focusedTests',
    'fixtureCells',
    'avoidBroadRerun',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final progress = _read(_progressPath);
    var checked = 0;

    checked += _requiredRouteFields.length;
    for (final field in _requiredRouteFields) {
      if (progress.contains(field)) continue;
      failures.add(
        _failure(
          id: 'missing_family_route_field:$field',
          message: 'Catalog family rerun map is missing a required field.',
          expected: field,
          actual: 'not found in $_progressPath',
          fix:
              'Each family route needs id, trade, risks, focused tests, fixture cells, and broad-rerun avoidance guidance.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _familyRoutes.length;
    for (final entry in _familyRoutes.entries) {
      final missing = [
        entry.key,
        ...entry.value,
      ].where((token) => !progress.contains(token)).toList();
      if (missing.isEmpty) continue;
      failures.add(
        _failure(
          id: 'missing_family_rerun_route:${entry.key}',
          message: 'Progress memory is missing a focused family rerun route.',
          expected: '${entry.key}: ${entry.value.join(' + ')}',
          actual: 'missing ${missing.join(' + ')}',
          fix:
              'Add a surgical rerun route for this item family so one family failure does not trigger broad catalog reruns.',
          category: QaFailureTriage.performance,
        ),
      );
    }

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'progressPath': _progressPath,
        'familyRouteCount': _familyRoutes.length,
        'contract':
            'Priority residential trade item families must have focused rerun routes tied to fixture cells and family-specific tests.',
      },
    );
  }

  QaFailure _failure({
    required String id,
    required String message,
    required String expected,
    required String actual,
    required String fix,
    required String category,
  }) {
    return QaFailure(
      suite: name,
      id: id,
      message: message,
      severity: QaSeverity.warning,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: {'triageCategory': category},
    );
  }
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}
