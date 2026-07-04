import 'dart:io';

import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

import '../qa_harness/qa_harness.dart';

class WorkSupplyParserReleaseOneTierRoleSuite extends QaSuite {
  const WorkSupplyParserReleaseOneTierRoleSuite()
    : super('inventory.release_one_tier_role_contract');

  static const _contractSources = [
    'docs/materials_catalog_intelligence_contract.md',
    'docs/inventory_parser_qa_harness_plan.md',
    'docs/inventory_parser_qa_progress_memory.md',
  ];

  static const _requiredTierRoles = {
    'release one is residential-first',
    'core comes before standard',
    'standard comes before professional',
    'core and standard are priority one',
    'service truck',
    'everyday',
    'most common',
    'normal residential items',
    'no special order appliance bloat in core',
    'professional and complete later',
  };

  static const _requiredReleaseAxes = {
    'plumbing',
    'electrical',
    'hvac',
    'en-us',
    'es-us',
    'core',
    'standard',
    'residential',
  };

  static const _priorityTrades = {'Plumbing', 'Electrical', 'HVAC'};

  static const _releaseOneBloatTerms = {
    'complete toilet',
    'toilet bowl',
    'bath vanity',
    'vanity top',
    'kitchen sink',
    'bathroom sink',
    'pedestal sink',
    'bathtub',
    'shower door',
    'garbage disposal',
    '40 gal water heater',
    '50 gal water heater',
    'tankless water heater',
    'furnace',
    'air conditioner',
    'condenser unit',
    'air handler',
  };

  static const _releaseOneServicePartAllowTerms = {
    'adapter',
    'aerator',
    'cartridge',
    'connector',
    'coupling',
    'drain',
    'expansion tank',
    'fitting',
    'flange',
    'flapper',
    'flush valve',
    'fill valve',
    'gasket',
    'kit',
    'line',
    'nipple',
    'pan',
    'repair',
    'relief valve',
    'seal',
    'stem',
    'strap',
    'supply',
    'switch',
    'valve',
    'wax ring',
  };

  @override
  Future<QaSuiteResult> run(QaContext context) async {
    final timer = QaStopwatch.start();
    final failures = <QaFailure>[];
    final source = _normalizeContractText(_readContractSource());
    var checked = _requiredTierRoles.length + _requiredReleaseAxes.length;

    for (final role in _requiredTierRoles) {
      if (source.contains(_normalizeContractText(role))) continue;
      failures.add(
        _failure(
          id: 'missing_tier_role:${_safeId(role)}',
          message: 'Release-one Core/Standard tier role is not locked.',
          expected: role,
          actual: 'not found in QA contract docs',
          fix:
              'Document the tier role so Core stays everyday/service-truck focused and Standard expands common residential coverage without jumping to long-tail rows.',
        ),
      );
    }

    for (final axis in _requiredReleaseAxes) {
      if (source.contains(_normalizeContractText(axis))) continue;
      failures.add(
        _failure(
          id: 'missing_release_axis:$axis',
          message: 'Release-one QA contract is missing a priority axis.',
          expected: axis,
          actual: 'not found in QA contract docs',
          fix:
              'Keep release-one coverage explicit for US residential Plumbing, Electrical, HVAC, Core, Standard, English, and Spanish.',
        ),
      );
    }

    final coreBloatScan = _scanResidentialTierForBloat(WorkSupplyPackTier.core);
    checked += coreBloatScan.checked;
    failures.addAll(coreBloatScan.failures);

    final standardBloatScan = _scanResidentialTierForBloat(
      WorkSupplyPackTier.standard,
    );
    checked += standardBloatScan.checked;
    failures.addAll(standardBloatScan.failures);

    return timer.finish(
      suite: name,
      checked: checked,
      failures: failures,
      maxFailures: context.maxFailuresPerSuite,
      metrics: {
        'contractSources': _contractSources,
        'requiredTierRoles': _requiredTierRoles.toList()..sort(),
        'requiredReleaseAxes': _requiredReleaseAxes.toList()..sort(),
        'coreBloatScanCount': coreBloatScan.checked,
        'standardBloatScanCount': standardBloatScan.checked,
        'releaseOneBloatTerms': _releaseOneBloatTerms.toList()..sort(),
        'releaseOneServicePartAllowTerms':
            _releaseOneServicePartAllowTerms.toList()..sort(),
      },
    );
  }

  String _readContractSource() {
    final buffer = StringBuffer();
    for (final path in _contractSources) {
      final file = File(path);
      if (file.existsSync()) buffer.writeln(file.readAsStringSync());
    }
    return buffer.toString();
  }

  _TierBloatScan _scanResidentialTierForBloat(WorkSupplyPackTier tier) {
    final failures = <QaFailure>[];
    var checked = 0;
    for (final item in workSupplyCatalogItems) {
      if (!_priorityTrades.contains(item.trade)) continue;
      if (item.packTier != tier) continue;
      if (!item.marketScopes.contains(WorkSupplyMarketScope.residential)) {
        continue;
      }
      checked++;
      final haystack = [
        item.name,
        item.category,
        item.system,
        item.itemType,
        item.variant,
        ...item.aliases,
      ].join(' ').toLowerCase();
      final bloatTerm = _releaseOneBloatTerms
          .where((term) => haystack.contains(term))
          .cast<String?>()
          .firstWhere((term) => term != null, orElse: () => null);
      if (bloatTerm == null) continue;
      final allowedServicePart = _releaseOneServicePartAllowTerms.any(
        haystack.contains,
      );
      if (allowedServicePart) continue;
      failures.add(
        _failure(
          id: '${tier.name}_special_order_bloat:${item.id}',
          message:
              'Residential ${tier.name} appears to contain a full fixture/appliance row instead of a release-one service part.',
          expected:
              'Core/Standard rows stay service-focused; full fixtures/appliances move to later tiers unless they are repair/service parts.',
          actual: '${item.path} / ${item.name}; matched=$bloatTerm',
          fix:
              'Move the row out of release-one Core/Standard or add service-part wording if it truly is a repair/connector/valve/kit item.',
        ),
      );
    }
    return _TierBloatScan(checked: checked, failures: failures);
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
      severity: QaSeverity.error,
      expected: expected,
      actual: actual,
      suggestedFix: fix,
      metadata: const {'triageCategory': QaFailureTriage.governance},
    );
  }
}

String _normalizeContractText(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _safeId(String value) {
  return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
}

class _TierBloatScan {
  const _TierBloatScan({required this.checked, required this.failures});

  final int checked;
  final List<QaFailure> failures;
}
