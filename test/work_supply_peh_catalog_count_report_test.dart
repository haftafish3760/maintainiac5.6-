import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('reports PEH residential trade pack counts', () {
    const trades = ['Plumbing', 'Electrical', 'HVAC'];
    final report = <String, Object?>{
      'schema': 'maintainiac.work_supply.peh_catalog_count_report.v1',
      'scope': WorkSupplyMarketScope.residential.id,
      'trades': [for (final trade in trades) _tradeCountReport(trade)],
    };

    // ignore: avoid_print
    print('PEH_CATALOG_COUNT_REPORT ${jsonEncode(report)}');

    for (final tradeReport in report['trades']! as List<Object?>) {
      final trade = tradeReport! as Map<String, Object?>;
      final tiers = trade['tiers']! as Map<String, Object?>;
      final core = tiers['core']! as int;
      final standard = tiers['standard']! as int;
      final professional = tiers['professional']! as int;
      final complete = tiers['complete']! as int;

      expect(core, greaterThan(0), reason: '${trade['trade']} core is empty');
      expect(
        standard,
        greaterThanOrEqualTo(core),
        reason: '${trade['trade']} standard must include core',
      );
      expect(
        professional,
        greaterThanOrEqualTo(standard),
        reason: '${trade['trade']} professional must include standard',
      );
      expect(
        complete,
        greaterThanOrEqualTo(professional),
        reason: '${trade['trade']} complete must include professional',
      );
    }
  });
}

Map<String, Object?> _tradeCountReport(String trade) {
  final options = buildWorkSupplyTradePackOptionsForScope(
    trade,
    marketScope: WorkSupplyMarketScope.residential,
  );
  return {
    'trade': trade,
    'tiers': {for (final option in options) option.tier.id: option.itemCount},
    'downloadSize': {
      for (final option in options)
        option.tier.id: option.estimatedDownloadSizeLabel,
    },
    'onDeviceSize': {
      for (final option in options)
        option.tier.id: option.estimatedOnDeviceSizeLabel,
    },
  };
}
