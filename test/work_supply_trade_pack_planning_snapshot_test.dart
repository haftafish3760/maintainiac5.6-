import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('trade pack planning snapshot prints every trade and scope lane', () {
    for (final trade in workSupplyTrades) {
      for (final scope in WorkSupplyMarketScopes.all) {
        final options = buildWorkSupplyTradePackOptionsForScope(
          trade.name,
          marketScope: scope,
        );
        final core = _option(options, WorkSupplyTradePackTier.core);
        final standard = _option(options, WorkSupplyTradePackTier.expanded);
        final professional = _option(
          options,
          WorkSupplyTradePackTier.professional,
        );
        final complete = _option(options, WorkSupplyTradePackTier.full);

        // ignore: avoid_print
        print(
          [
            'TRADE_PACK_PLANNING',
            'trade="${trade.name}"',
            'scope=${scope.name}',
            'core=${core.itemCount}',
            'standard=${standard.itemCount}',
            'professional=${professional.itemCount}',
            'complete=${complete.itemCount}',
            'coreOnDevice=${core.estimatedOnDeviceSizeLabel}',
            'completeOnDevice=${complete.estimatedOnDeviceSizeLabel}',
            'coreDownload=${core.estimatedDownloadSizeLabel}',
            'completeDownload=${complete.estimatedDownloadSizeLabel}',
          ].join(' '),
        );

        expect(complete.itemCount, greaterThanOrEqualTo(core.itemCount));
        expect(complete.estimatedUncompressedBytes, greaterThanOrEqualTo(0));
      }
    }
  });
}

WorkSupplyTradePackOption _option(
  List<WorkSupplyTradePackOption> options,
  WorkSupplyTradePackTier tier,
) {
  return options.firstWhere((option) => option.tier == tier);
}
