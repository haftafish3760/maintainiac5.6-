import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/inventory_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_runtime_loader.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('loaded-catalog entry point restricts matching to its pack', () {
    final item = _pvcSchedule40Coupling();
    final parser = InventoryParser(catalogItems: [item]);

    final match = parser.matchReceiptLine(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );

    expect(match, isNotNull);
    expect(match!.item.id, item.id);
  });

  test('empty loaded-catalog entry point does not use the full catalog', () {
    final parser = InventoryParser(catalogItems: const []);

    final match = parser.matchReceiptLine(
      'HD 3/4 PVC SCH40 COUPLING',
      tradeScope: 'Plumbing',
    );

    expect(match, isNull);
  });

  test(
    'multiple validated local packs merge without duplicate catalog rows',
    () {
      final item = _pvcSchedule40Coupling();
      final pack = WorkSupplyTradePackRuntimeLoadResult(
        status: WorkSupplyTradePackRuntimeLoadStatus.ready,
        items: [item],
        issues: const [],
      );
      final parser = InventoryParser.fromLoadedTradePacks([pack, pack]);

      final match = parser.matchReceiptLine(
        'HD 3/4 PVC SCH40 COUPLING',
        tradeScope: 'Plumbing',
      );

      expect(parser.catalogItems, hasLength(1));
      expect(match?.item.id, item.id);
    },
  );

  test(
    'installed local pack directories build an offline parser',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_inventory_parser_hvac_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final option = buildWorkSupplyTradePackOptionsForScope(
        'HVAC',
        marketScope: WorkSupplyMarketScope.residential,
      ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
      final fileSet = await WorkSupplyTradePackExportWriter(
        baseDirectory: root,
      ).writeTradePack(option: option);

      final parser = await InventoryParser.fromInstalledPackDirectories([
        Directory(fileSet.directoryPath),
      ]);
      final match = parser.matchReceiptLine(
        'SUPPLY 45/5 MFD DUAL RUN CAP',
        tradeScope: 'HVAC',
      );

      expect(parser.catalogItems, hasLength(option.itemCount));
      expect(match, isNotNull);
      expect(match!.item.trade, 'HVAC');
      expect(match.item.name.toLowerCase(), contains('capacitor'));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'invalid installed pack directory cannot create an offline parser',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'maintainiac_invalid_inventory_pack_',
      );
      addTearDown(() async {
        if (await directory.exists()) await directory.delete(recursive: true);
      });

      await expectLater(
        InventoryParser.fromInstalledPackDirectories([directory]),
        throwsA(isA<StateError>()),
      );
    },
  );
}

WorkSupplyItem _pvcSchedule40Coupling() => workSupplyCatalogItems.firstWhere(
  (item) =>
      item.trade == 'Plumbing' &&
      item.name.startsWith('3/4') &&
      item.name.toLowerCase().contains('pvc schedule 40 coupling'),
);
