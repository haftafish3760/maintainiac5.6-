import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_item_identity_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';

const _identityStoreTimeout = Timeout(Duration(minutes: 2));

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'work_supply_item_identity_store_test_',
    );
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test(
    'links an existing product barcode to an inventory item package',
    () async {
      final store = await WorkSupplyItemIdentityStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;

      final alias = await store.linkBarcodeToItem(
        barcodeValue: '0 12345-67890 5',
        barcodeFormat: 'upcA',
        item: item,
        packageLabel: 'Box of 25',
        purchaseType: 'box',
        unitsPerPackage: 25,
        merchantName: 'Local supply house',
      );

      final saved = store.aliasForBarcode('012345678905');

      expect(alias.barcodeNormalized, '012345678905');
      expect(saved, isNotNull);
      expect(saved!.itemId, item.id);
      expect(saved.itemName, item.name);
      expect(saved.itemPath, item.path);
      expect(saved.packageLabel, 'Box of 25');
      expect(saved.unitsPerPackage, 25);
      expect(saved.merchantName, 'Local supply house');
    },
    timeout: _identityStoreTimeout,
  );

  test(
    'barcode lookup normalizes spaces, hyphens, and case',
    () async {
      final store = await WorkSupplyItemIdentityStore.create();
      final item = searchWorkSupplies('romex 14/2').first;

      await store.linkBarcodeToItem(
        barcodeValue: 'qr-work-14-2-nmb',
        barcodeFormat: 'qr',
        item: item,
        packageLabel: '250 ft roll',
        purchaseType: 'roll',
        unitsPerPackage: 250,
        unit: 'foot',
      );

      final saved = store.aliasForBarcode(' QR WORK 14 2 nmb ');

      expect(saved, isNotNull);
      expect(saved!.barcodeNormalized, 'QRWORK142NMB');
      expect(saved.unit, 'foot');
      expect(saved.purchaseType, 'roll');
    },
    timeout: _identityStoreTimeout,
  );

  test('allows multiple barcodes for the same item', () async {
    final store = await WorkSupplyItemIdentityStore.create();
    final item = searchWorkSupplies('pvc primer').first;

    await store.linkBarcodeToItem(
      barcodeValue: '111111111111',
      item: item,
      packageLabel: '8 oz can',
      purchaseType: 'can',
      unit: 'ounce',
    );
    await store.linkBarcodeToItem(
      barcodeValue: '222222222222',
      item: item,
      packageLabel: '16 oz can',
      purchaseType: 'can',
      unitsPerPackage: 16,
      unit: 'ounce',
    );

    final aliases = store.aliasesForItem(item.id);

    expect(aliases, hasLength(2));
    expect(
      aliases.map((alias) => alias.packageLabel),
      containsAll(['8 oz can', '16 oz can']),
    );
  }, timeout: _identityStoreTimeout);

  test(
    'builds trusted parser identity IDs from saved aliases',
    () async {
      final store = await WorkSupplyItemIdentityStore.create();
      final item = searchWorkSupplies(
        '3/4 in Push-Fit Coupling',
      ).firstWhere((candidate) => candidate.trade == 'Plumbing');

      await store.linkBarcodeToItem(
        barcodeValue: '0 88843-21000 9',
        barcodeFormat: 'upcA',
        item: item,
        merchantName: 'User linked Lowe\'s package',
      );

      final trustedIds = trustedWorkSupplyItemIdentityIdsFromAliases(
        store.loadAliases(),
      );
      final match = matchReceiptLineToCatalog(
        'LOWES 088843210009 PUSH COUP',
        trustedItemIdentityIds: trustedIds,
        tradeScope: 'Plumbing',
        maxCandidates: 1,
      );

      expect(trustedIds['088843210009'], item.id);
      expect(match, isNotNull);
      expect(match!.item.id, item.id);
      expect(match.source, ReceiptMatchSource.trustedItemIdentity);
    },
    timeout: _identityStoreTimeout,
  );

  test(
    'saving the same normalized barcode updates instead of duplicating',
    () async {
      final store = await WorkSupplyItemIdentityStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;

      final first = await store.linkBarcodeToItem(
        barcodeValue: '0-12345-67890-5',
        item: item,
        packageLabel: 'Each',
      );
      final second = await store.linkBarcodeToItem(
        barcodeValue: '012345678905',
        item: item,
        packageLabel: 'Contractor pack of 10',
        unitsPerPackage: 10,
      );

      final aliases = store.loadAliases();

      expect(aliases, hasLength(1));
      expect(second.id, first.id);
      expect(aliases.single.packageLabel, 'Contractor pack of 10');
      expect(aliases.single.unitsPerPackage, 10);
    },
    timeout: _identityStoreTimeout,
  );

  test(
    'deletes a barcode alias without touching the item itself',
    () async {
      final store = await WorkSupplyItemIdentityStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;

      await store.linkBarcodeToItem(
        barcodeValue: '012345678905',
        item: item,
        packageLabel: 'Each',
      );

      await store.deleteAlias('0 12345-67890 5');

      expect(store.aliasForBarcode('012345678905'), isNull);
      expect(store.aliasesForItem(item.id), isEmpty);
    },
    timeout: _identityStoreTimeout,
  );
}
