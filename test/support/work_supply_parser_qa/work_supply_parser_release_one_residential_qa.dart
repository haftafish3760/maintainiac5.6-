import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneResidentialSuite extends QaSuite {
  const WorkSupplyParserReleaseOneResidentialSuite()
    : super('inventory.release_one_residential_contract');

  static const _sourcePaths = {
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_progress_memory.md',
    'test/support/work_supply_parser_qa/work_supply_parser_service_truck_core_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_spanish_release_one_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_release_one_pack_balance_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_catalog_batch_manifest_qa.dart',
    'test/support/work_supply_parser_qa/work_supply_parser_generated_fixture_cell_qa.dart',
  };

  static const _primaryReleaseOneTrades = {'plumbing', 'electrical', 'hvac'};

  static const _releaseOneSupportSignals = {
    'fasteners only as normal overlap/support items',
    'not a separate release-one trade pack',
    'service-trade fasteners',
  };

  static const _releaseOneLocales = {
    'en-US',
    'es-US',
    'Spanish',
    'English',
    'locale pack',
  };

  static const _releaseOneTiers = {
    'core',
    'standard',
    'professional',
    'complete',
  };

  static const _serviceTruckSignals = {
    'service truck',
    'everyday',
    'most common',
    'normal residential',
    'Lowe',
    'Home Depot',
    'Ace',
    'Menards',
    'Ferguson',
    'Grainger',
    'Walmart',
    'True Value',
    'local supply house',
    'regional supplier',
    'generic hardware store',
    'unknown merchant',
    'counter sale',
  };

  static const _releaseGates = {
    'core_comes_before_standard',
    'standard_comes_before_professional',
    'professional_comes_before_complete',
    'english_before_spanish_only_when_required_by_release_order',
    'spanish_is_non_negotiable_for_us_release',
    'residential_before_light_industrial',
    'residential_before_commercial',
    'no_special_order_appliance_bloat_in_core',
    'service_truck_core_before_obscure_items',
    'all_new_items_get_fixture_pairs',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _readSources();
    var checked = 0;

    checked += _primaryReleaseOneTrades.length;
    _requireTokens(
      failures,
      source,
      _primaryReleaseOneTrades,
      idPrefix: 'missing_release_trade',
      message: 'Release-one residential contract is missing a trade.',
      fix:
          'Release one must prioritize residential plumbing, electrical, and HVAC.',
      triage: QaFailureTriage.governance,
    );

    checked += _releaseOneSupportSignals.length;
    _requireTokens(
      failures,
      source,
      _releaseOneSupportSignals,
      idPrefix: 'missing_release_support_signal',
      message:
          'Release-one residential contract is missing support-item scope.',
      fix:
          'Normal service-trade fasteners belong inside the top-three trade packs, not as a separate release-one trade drift.',
      triage: QaFailureTriage.governance,
    );

    checked += _releaseOneLocales.length;
    _requireTokens(
      failures,
      source,
      _releaseOneLocales,
      idPrefix: 'missing_release_locale',
      message: 'Release-one residential contract is missing locale coverage.',
      fix:
          'United States residential release must include English and Spanish parser-pack coverage.',
      triage: QaFailureTriage.locale,
    );

    checked += _releaseOneTiers.length;
    _requireTokens(
      failures,
      source,
      _releaseOneTiers,
      idPrefix: 'missing_release_tier',
      message: 'Release-one residential contract is missing a pack tier.',
      fix:
          'Residential release planning must cover core, standard, professional, and complete tiers.',
      triage: QaFailureTriage.governance,
    );

    checked += _serviceTruckSignals.length;
    _requireTokens(
      failures,
      source,
      _serviceTruckSignals,
      idPrefix: 'missing_service_truck_signal',
      message:
          'Release-one residential QA is missing real-world store/service-truck signals.',
      fix:
          'Core/standard packs must bias toward service-truck and major-store stocked items before obscure or special-order catalog expansion.',
      triage: QaFailureTriage.fixture,
    );

    checked += _releaseGates.length;
    _requireReleaseGates(failures, source);

    checked += 5;
    _requireNoDriftBoundaries(source, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'sourceFiles': _sourcePaths.length,
        'contract':
            'Release one is residential first, top three trades, English plus US Spanish, and fixture-paired before expansion.',
      },
    );
  }

  void _requireReleaseGates(List<QaFailure> failures, String source) {
    final lower = _normalizeContractText(source);
    for (final gate in _releaseGates) {
      if (lower.contains(_normalizeContractText(gate))) continue;
      failures.add(
        _failure(
          id: 'missing_release_gate:${_safeId(gate)}',
          message: 'Release-one residential QA is missing a named gate.',
          expected: gate,
          actual: 'not found',
          fix:
              'Add named release gates so catalog generation cannot drift into low-priority scopes before residential coverage is ready.',
          triage: QaFailureTriage.governance,
        ),
      );
    }
  }

  void _requireNoDriftBoundaries(String source, List<QaFailure> failures) {
    const tokens = {
      'No OCR',
      'No camera',
      'No Expenses',
      'No live Firebase',
      'inventory parser',
    };
    final lower = _normalizeContractText(source);
    for (final token in tokens) {
      if (lower.contains(_normalizeContractText(token))) continue;
      failures.add(
        _failure(
          id: 'missing_release_boundary:${_safeId(token)}',
          message: 'Release-one residential QA is missing a drift boundary.',
          expected: token,
          actual: 'not found',
          fix:
              'Keep release-one inventory parser work isolated from OCR, camera, Expenses, UI/UX, and live Firebase writes.',
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
