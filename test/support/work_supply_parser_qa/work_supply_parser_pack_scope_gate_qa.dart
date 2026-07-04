import 'dart:io';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserPackScopeGateSuite extends QaSuite {
  const WorkSupplyParserPackScopeGateSuite()
    : super('inventory.pack_scope_gate_contract');

  static const _tradePackRoadmapPath =
      'docs/materials_trade_pack_pass_roadmap.md';
  static const _catalogContractPath =
      'docs/materials_catalog_intelligence_contract.md';
  static const _localizationRoadmapPath =
      'docs/materials_parser_localization_roadmap.md';
  static const _progressPath = 'docs/inventory_parser_qa_progress_memory.md';
  static const _tiersPath =
      'lib/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';
  static const _manifestPath =
      'lib/screens/work_supplies/data/work_supply_trade_pack_manifest.dart';
  static const _distributionTestPath =
      'test/work_supply_trade_pack_distribution_test.dart';
  static const _planningSnapshotTestPath =
      'test/work_supply_trade_pack_planning_snapshot_test.dart';

  static const _requiredScopes = {
    'residential',
    'lightIndustrial',
    'commercial',
  };

  static const _requiredTiers = {
    'core',
    'standard',
    'professional',
    'complete',
  };

  static const _priorityTradeTokens = {
    'Plumbing',
    'Electrical',
    'HVAC',
    'Garage Doors and Openers',
    'Shared Fasteners',
  };

  static const _requiredPackGateTokens = {
    'Core <= Standard <= Professional <= Complete',
    'residential core is plausible',
    'compressed and uncompressed/on-device sizes',
    'parser tests cover common receipt abbreviations',
    'neighbor families',
    'import/export manifest validation passes',
    'analyzer passes',
  };

  static const _requiredSizeTokens = {
    'Preferred max: about 150 MB',
    'Hard review threshold: about 210 MB',
    'pack-size',
    'storage',
    'cloud fallback',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final roadmap = _read(_tradePackRoadmapPath);
    final contract = _read(_catalogContractPath);
    final localization = _read(_localizationRoadmapPath);
    final progress = _read(_progressPath);
    final tierSource = _read(_tiersPath);
    final manifestSource = _read(_manifestPath);
    final distributionTest = _read(_distributionTestPath);
    final planningTest = _read(_planningSnapshotTestPath);
    final combinedDocs = '$roadmap\n$contract\n$localization\n$progress';
    final combinedCode =
        '$tierSource\n$manifestSource\n$distributionTest\n$planningTest';
    final normalizedDocs = _normalizeContractText(combinedDocs);
    final normalizedCode = _normalizeContractText(combinedCode);
    final normalizedRoadmap = _normalizeContractText(roadmap);
    final normalizedContract = _normalizeContractText(contract);
    final normalizedProgress = _normalizeContractText(progress);
    var checked = 0;

    checked += _requiredScopes.length;
    for (final scope in _requiredScopes) {
      final normalizedScope = _normalizeContractText(scope);
      if (normalizedDocs.contains(normalizedScope) &&
          normalizedCode.contains(normalizedScope)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_scope_gate:$scope',
          message:
              'Inventory pack scope is not governed in both docs and code/tests.',
          expected: scope,
          actual: 'missing from docs or code/test sources',
          fix:
              'Keep residential, lightIndustrial, and commercial separated so residential packs do not silently bloat.',
          category: QaFailureTriage.category,
        ),
      );
    }

    checked += _requiredTiers.length;
    for (final tier in _requiredTiers) {
      final normalizedTier = _normalizeContractText(tier);
      if (normalizedDocs.contains(normalizedTier) &&
          normalizedCode.contains(normalizedTier)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_tier_gate:$tier',
          message:
              'Inventory pack tier is not governed in both docs and code/tests.',
          expected: tier,
          actual: 'missing from docs or code/test sources',
          fix:
              'Core, Standard, Professional, and Complete must remain explicit and monotonic.',
          category: QaFailureTriage.category,
        ),
      );
    }

    checked += _priorityTradeTokens.length;
    for (final trade in _priorityTradeTokens) {
      if (normalizedDocs.contains(_normalizeContractText(trade))) continue;
      failures.add(
        _failure(
          id: 'missing_priority_trade:${_safeId(trade)}',
          message:
              'Priority release trade is missing from pack gate documentation.',
          expected: trade,
          actual: 'not found in inventory docs',
          fix:
              'Keep priority trades visible so release-one work stays focused on service inventory.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredPackGateTokens.length;
    for (final token in _requiredPackGateTokens) {
      if (normalizedRoadmap.contains(_normalizeContractText(token))) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_pack_gate:${_safeId(token)}',
          message:
              'Trade-pack done gate is missing a required release condition.',
          expected: token,
          actual: 'not found in $_tradePackRoadmapPath',
          fix:
              'A trade cannot be called done until scope, tier, size, parser, neighbor, import/export, and analyzer gates are explicit.',
          category: QaFailureTriage.governance,
        ),
      );
    }

    checked += _requiredSizeTokens.length;
    for (final token in _requiredSizeTokens) {
      final normalizedToken = _normalizeContractText(token);
      if (normalizedContract.contains(normalizedToken) ||
          normalizedProgress.contains(normalizedToken)) {
        continue;
      }
      failures.add(
        _failure(
          id: 'missing_pack_size_policy:${_safeId(token)}',
          message: 'Inventory pack size/storage policy is missing.',
          expected: token,
          actual: 'not found in catalog contract or progress memory',
          fix:
              'Pack generation must preserve storage budgets, local mode, and cloud fallback boundaries.',
          category: QaFailureTriage.performance,
        ),
      );
    }

    checked += 6;
    _checkScopeTierImplementation(combinedCode, failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'tradePackRoadmapPath': _tradePackRoadmapPath,
        'catalogContractPath': _catalogContractPath,
        'localizationRoadmapPath': _localizationRoadmapPath,
        'contract':
            'Inventory trade packs must stay separated by market scope and tier, prove monotonic pack membership, expose size/storage expectations, and keep priority residential service trades visible before item expansion.',
      },
    );
  }

  void _checkScopeTierImplementation(
    String source,
    List<QaFailure> failures,
  ) {
    const implementationTokens = {
      'WorkSupplyPackTier',
      'WorkSupplyMarketScope',
      'core',
      'standard',
      'professional',
      'complete',
    };
    for (final token in implementationTokens) {
      if (source.contains(token)) continue;
      failures.add(
        _failure(
          id: 'missing_scope_tier_implementation:${_safeId(token)}',
          message:
              'Scope/tier implementation token is missing from code/tests.',
          expected: token,
          actual: 'not found',
          fix:
              'Pack gate QA must inspect real scope/tier implementation, not only documentation.',
          category: QaFailureTriage.schema,
        ),
      );
    }
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

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _read(String path) {
  final file = File(path);
  if (!file.existsSync()) return '';
  return file.readAsStringSync();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}
