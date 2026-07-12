import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_manifest.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('plumbing direct pack tiers keep core and standard intentional', () {
    final plumbing = workSupplyCatalogItems
        .where((item) => item.trade == 'Plumbing')
        .toList(growable: false);
    final tierCounts = <WorkSupplyPackTier, int>{};
    final fittingTierCounts = <WorkSupplyPackTier, int>{};

    for (final item in plumbing) {
      tierCounts.update(item.packTier, (count) => count + 1, ifAbsent: () => 1);
      if (item.category == 'Fittings') {
        fittingTierCounts.update(
          item.packTier,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final core = tierCounts[WorkSupplyPackTier.core] ?? 0;
    final standard = tierCounts[WorkSupplyPackTier.standard] ?? 0;
    final professional = tierCounts[WorkSupplyPackTier.professional] ?? 0;
    final complete = tierCounts[WorkSupplyPackTier.complete] ?? 0;
    final standardFittings =
        fittingTierCounts[WorkSupplyPackTier.standard] ?? 0;

    expect(plumbing.length, greaterThanOrEqualTo(12000));
    expect(core, inInclusiveRange(1000, 1400));
    expect(standard, inInclusiveRange(650, 1000));
    expect(professional, greaterThan(10000));
    expect(complete, inInclusiveRange(100, 250));
    expect(standardFittings, lessThan(1200));
  });

  test('plumbing scoped packs are classified by install tier', () {
    _expectScopedPackDistribution('Plumbing', 'PLUMBING_PACK_DISTRIBUTION');
  });
}

void _expectScopedPackDistribution(String trade, String logPrefix) {
  for (final scope in WorkSupplyMarketScopes.all) {
    final options = buildWorkSupplyTradePackOptionsForScope(
      trade,
      marketScope: scope,
    );
    final core = _option(options, WorkSupplyTradePackTier.core);
    final standard = _option(options, WorkSupplyTradePackTier.expanded);
    final professional = _option(options, WorkSupplyTradePackTier.professional);
    final complete = _option(options, WorkSupplyTradePackTier.full);

    // ignore: avoid_print
    print(
      [
        logPrefix,
        'scope=${scope.name}',
        'core=${core.itemCount}',
        'standard=${standard.itemCount}',
        'professional=${professional.itemCount}',
        'complete=${complete.itemCount}',
        'coreOnDevice=${core.estimatedOnDeviceSizeLabel}',
        'completeOnDevice=${complete.estimatedOnDeviceSizeLabel}',
      ].join(' '),
    );

    expect(core.itemCount, greaterThan(0));
    expect(standard.itemCount, greaterThanOrEqualTo(core.itemCount));
    expect(professional.itemCount, greaterThanOrEqualTo(standard.itemCount));
    expect(complete.itemCount, greaterThanOrEqualTo(professional.itemCount));
    expect(core.estimatedUncompressedBytes, greaterThan(0));
    expect(complete.estimatedUncompressedBytes, greaterThan(0));
    _expectPlumbingScopeContract(scope, core, standard, professional, complete);
  }
}

void _expectPlumbingScopeContract(
  WorkSupplyMarketScope scope,
  WorkSupplyTradePackOption core,
  WorkSupplyTradePackOption standard,
  WorkSupplyTradePackOption professional,
  WorkSupplyTradePackOption complete,
) {
  switch (scope) {
    case WorkSupplyMarketScope.residential:
      expect(core.itemCount, inInclusiveRange(1000, 1400));
      expect(standard.itemCount, inInclusiveRange(1600, 2200));
      expect(complete.itemCount, greaterThanOrEqualTo(11000));
    case WorkSupplyMarketScope.lightIndustrial:
      expect(core.itemCount, greaterThanOrEqualTo(250));
      expect(complete.itemCount, greaterThanOrEqualTo(5500));
    case WorkSupplyMarketScope.commercial:
      expect(core.itemCount, greaterThanOrEqualTo(100));
      expect(complete.itemCount, greaterThanOrEqualTo(5000));
  }

  for (final option in [core, standard, professional, complete]) {
    final manifest = buildWorkSupplyTradePackManifest(
      option,
      generatedAt: DateTime.utc(2026, 6, 29, 12),
    );
    final actualGzipBytes = _actualGzipBytes(option);
    expect(manifest.marketScope, scope);
    expect(manifest.itemCount, option.itemCount);
    expect(manifest.chunkCount, greaterThan(0));
    expect(manifest.estimatedCompressedBytes, greaterThan(0));
    expect(actualGzipBytes, greaterThan(0));
    expect(actualGzipBytes, lessThan(manifest.estimatedUncompressedBytes));
    expect(manifest.estimatedCompressedBytes, actualGzipBytes);
    expect(
      manifest.estimatedUncompressedBytes,
      greaterThan(manifest.estimatedCompressedBytes),
    );
    expect(manifest.estimatedUncompressedBytes, lessThan(150 * 1024 * 1024));
    expect(
      manifest.chunks.every(
        (chunk) => chunk.storagePath.contains('/plumbing/${scope.id}/'),
      ),
      isTrue,
    );
    expect(
      manifest.chunks.every((chunk) => chunk.contentEncoding == 'gzip'),
      isTrue,
    );
  }
}

int _actualGzipBytes(WorkSupplyTradePackOption option) {
  return buildWorkSupplyTradePackChunkPayloads(
    option,
  ).fold<int>(0, (sum, payload) => sum + gzip.encode(payload.jsonBytes).length);
}

WorkSupplyTradePackOption _option(
  List<WorkSupplyTradePackOption> options,
  WorkSupplyTradePackTier tier,
) {
  return options.firstWhere((option) => option.tier == tier);
}
