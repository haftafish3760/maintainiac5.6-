import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_base_bundle_policy.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_delivery_policy.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('base bundle policy keeps only residential PEH Core packs bundled', () {
    final policy = workSupplyTradePackBaseBundlePolicy;

    expect(policy.bundledTradeNames, {'Plumbing', 'Electrical', 'HVAC'});
    expect(policy.bundledTier, WorkSupplyTradePackTier.core);
    expect(policy.bundledMarketScope, WorkSupplyMarketScope.residential);

    final plumbingCore = _option('Plumbing', WorkSupplyTradePackTier.core);
    final electricalStandard = _option(
      'Electrical',
      WorkSupplyTradePackTier.expanded,
    );
    final hvacCommercialCore = _option(
      'HVAC',
      WorkSupplyTradePackTier.core,
      scope: WorkSupplyMarketScope.commercial,
    );

    expect(policy.isBundled(plumbingCore), isTrue);
    expect(policy.isOptional(electricalStandard), isTrue);
    expect(policy.isOptional(hvacCommercialCore), isTrue);
  });

  test(
    'base bundle policy does not claim current compiled catalog savings',
    () {
      final policy = workSupplyTradePackBaseBundlePolicy.toMap();

      expect(policy['baseInstallMode'], 'bundled_peh_core_assets');
      expect(policy['runtimeCatalogInjectionRequired'], isTrue);
      expect(policy['currentCompiledCatalogIsNotStorageProof'], isTrue);
      final optional = policy['optionalTierDelivery']! as Map<String, Object?>;
      expect(optional['localDownload'], 'free_offline_pack');
      expect(optional['firebaseWritesRequired'], isFalse);
    },
  );

  test('delivery metadata carries the same base-install policy', () {
    final delivery = workSupplyTradePackDeliveryPolicy.toMap();
    final baseInstall = delivery['baseInstall']! as Map<String, Object?>;

    expect(baseInstall['baseInstallMode'], 'bundled_peh_core_assets');
    expect(baseInstall['bundledTier'], 'core');
    expect(baseInstall['runtimeCatalogInjectionRequired'], isTrue);
  });
}

WorkSupplyTradePackOption _option(
  String trade,
  WorkSupplyTradePackTier tier, {
  WorkSupplyMarketScope scope = WorkSupplyMarketScope.residential,
}) {
  return WorkSupplyTradePackOption(
    tradeName: trade,
    marketScope: scope,
    tier: tier,
    itemCount: 1,
    estimatedRawBytes: 1,
    estimatedCompressedBytes: 1,
    storagePath: 'local/$trade/${tier.id}',
  );
}
