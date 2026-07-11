import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

const _inventoryStoreTimeout = Timeout(Duration(minutes: 4));

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp(
      'work_supply_inventory_store_test_',
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
    'store starts empty until real inventory records are added',
    () async {
      final store = await WorkSupplyInventoryStore.create();

      expect(store.loadInventory(), isEmpty);
      expect(store.loadEvents(), isEmpty);
      expect(store.loadTransactions(), isEmpty);
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'purges obsolete seeded lab inventory records',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final recordsBox = Hive.box<dynamic>(
        WorkSupplyInventoryStore.recordsBoxName,
      );
      final eventsBox = Hive.box<dynamic>(
        WorkSupplyInventoryStore.eventsBoxName,
      );
      final transactionsBox = Hive.box<dynamic>(
        WorkSupplyInventoryStore.transactionsBoxName,
      );

      await recordsBox.put('seed-old-record', {'id': 'seed-old-record'});
      await eventsBox.put('evt-old-seed', {
        'id': 'evt-old-seed',
        'inventoryRecordId': 'seed-old-record',
        'note': 'Seeded demo inventory for the lab build.',
      });
      await transactionsBox.put('txn-old-seed', {
        'id': 'txn-old-seed',
        'inventoryRecordId': 'seed-old-record',
        'note': 'Seeded demo inventory for the lab build.',
      });

      final removed = await store.purgeObsoleteSeedInventoryRecords();

      expect(removed, 3);
      expect(recordsBox.containsKey('seed-old-record'), isFalse);
      expect(eventsBox.containsKey('evt-old-seed'), isFalse);
      expect(transactionsBox.containsKey('txn-old-seed'), isFalse);
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'adding stock merges matching inventory records and logs event',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;
      final before = await store.addStock(
        _stockRecord(
          item: item,
          onHand: 8,
          threshold: 2,
          storageArea: 'Work Truck 1 inventory',
        ),
      );

      await store.addStock(
        _stockRecord(
          item: item,
          onHand: 4,
          threshold: 2,
          lastUnitCost: 3.25,
          storageArea: before.storageArea,
          receiptLinked: true,
          packagesPurchased: 1,
          unitsPerPackage: 4,
          lineSubtotal: 13,
          taxRate: 0.05,
          businessUse: 'split',
          businessPercent: .5,
        ),
      );

      final after = store.loadInventory().firstWhere(
        (record) => record.item.id == item.id,
      );
      final latestEvent = store.loadEvents().first;
      final latestTransaction = store.loadTransactions().first;

      expect(after.id, before.id);
      expect(after.onHand, before.onHand + 4);
      expect(after.businessUse, 'split');
      expect(after.businessPercent, .5);
      expect(latestEvent.type, WorkSupplyStockEventType.stockAdded);
      expect(latestEvent.quantityBefore, before.onHand);
      expect(latestEvent.quantityAfter, after.onHand);
      expect(latestTransaction.type, WorkSupplyStockEventType.stockAdded);
      expect(latestTransaction.inventoryRecordId, before.id);
      expect(latestTransaction.quantityBefore, before.onHand);
      expect(latestTransaction.quantityAfter, after.onHand);
      expect(latestTransaction.packagesPurchased, 1);
      expect(latestTransaction.unitsPerPackage, 4);
      expect(latestTransaction.lineSubtotal, 13);
      expect(latestTransaction.businessUse, 'split');
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'merged purchases keep separate transaction history for last purchase views',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;

      await store.addStock(
        WorkSupplyInventoryRecord(
          item: item,
          onHand: 4,
          threshold: 2,
          lastUnitCost: 3.25,
          storageArea: 'Work Truck 1 inventory',
          receiptLinked: true,
          packagesPurchased: 1,
          unitsPerPackage: 4,
          lineSubtotal: 12,
          sourceMerchantName: 'Lowes',
          loggedAt: DateTime.utc(2026, 1, 5),
        ),
      );
      await store.addStock(
        WorkSupplyInventoryRecord(
          item: item,
          onHand: 10,
          threshold: 2,
          lastUnitCost: 2.95,
          storageArea: 'Work Truck 1 inventory',
          receiptLinked: true,
          packagesPurchased: 1,
          unitsPerPackage: 10,
          lineSubtotal: 25,
          sourceMerchantName: 'Home Depot',
          loggedAt: DateTime.utc(2026, 2, 5),
        ),
      );

      final records = store.loadInventory();
      final transactions = store.recentTransactionsForItem(item);

      expect(records, hasLength(1));
      expect(records.single.onHand, 14);
      expect(transactions, hasLength(2));
      expect(transactions.first.sourceMerchantName, 'Home Depot');
      expect(transactions.last.sourceMerchantName, 'Lowes');
      expect(
        transactions.map((entry) => entry.lineSubtotal),
        containsAll([12, 25]),
      );
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'marking out of stock preserves record and logs count adjustment',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final record = await store.addStock(
        _stockRecord(
          item: searchWorkSupplies('1/2 copper 90').first,
          onHand: 8,
          threshold: 2,
          storageArea: 'Work Truck 1 inventory',
        ),
      );

      await store.markOutOfStock(record);

      final updated = store.loadInventory().firstWhere(
        (candidate) => candidate.id == record.id,
      );
      final latestEvent = store.loadEvents().first;
      final latestTransaction = store.loadTransactions().first;

      expect(updated.onHand, 0);
      expect(latestEvent.type, WorkSupplyStockEventType.countAdjusted);
      expect(latestEvent.quantityBefore, record.onHand);
      expect(latestEvent.quantityAfter, 0);
      expect(latestTransaction.type, WorkSupplyStockEventType.countAdjusted);
      expect(latestTransaction.quantityBefore, record.onHand);
      expect(latestTransaction.quantityAfter, 0);
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'same item in different storage spots stays separated',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;

      await store.addStock(
        _stockRecord(
          item: item,
          onHand: 4,
          threshold: 2,
          lastUnitCost: 3.25,
          storageArea: 'Work Truck 1 inventory',
          storageDetail: 'Left drawer',
          receiptLinked: true,
        ),
      );
      await store.addStock(
        _stockRecord(
          item: item,
          onHand: 6,
          threshold: 2,
          lastUnitCost: 3.25,
          storageArea: 'Work Truck 1 inventory',
          storageDetail: 'Right drawer',
          receiptLinked: true,
        ),
      );

      final records = store.loadInventory();
      expect(records, hasLength(2));
      expect(
        records.map((record) => record.storageDetail),
        containsAll(['Left drawer', 'Right drawer']),
      );
    },
    timeout: _inventoryStoreTimeout,
  );

  test(
    'export snapshot writes inventory and stock event CSV from source records',
    () async {
      final store = await WorkSupplyInventoryStore.create();
      final item = searchWorkSupplies('1/2 copper 90').first;
      await store.addStock(
        _stockRecord(
          item: item,
          onHand: 4,
          threshold: 2,
          lastUnitCost: 3.25,
          storageArea: 'S25, truck box',
          storageDetail: 'Drawer 3',
          receiptLinked: true,
          packagesPurchased: 1,
          unitsPerPackage: 4,
          lineSubtotal: 13,
          taxRate: 0.05,
          businessUse: 'personal',
          businessPercent: 0,
          sourceMerchantName: 'Lowes',
        ),
      );

      final snapshot = store.buildExportSnapshot(
        exportedAt: DateTime.utc(2026, 1, 1, 12),
      );
      final inventoryCsv = snapshot.toInventoryCsv();
      final eventsCsv = snapshot.toStockEventsCsv();
      final transactionsCsv = snapshot.toTransactionsCsv();
      final manifest = snapshot.toManifest();

      expect(inventoryCsv, contains('record_id,item_id,item_name'));
      expect(inventoryCsv, contains('storage_detail'));
      expect(inventoryCsv, contains('Drawer 3'));
      expect(inventoryCsv, contains('business_use,business_percent'));
      expect(inventoryCsv, contains('personal,0'));
      expect(inventoryCsv, contains('source_merchant_name'));
      expect(inventoryCsv, contains('Lowes'));
      expect(inventoryCsv, contains('"S25, truck box"'));
      expect(eventsCsv, contains('event_id,inventory_record_id,item_id'));
      expect(eventsCsv, contains('stockAdded'));
      expect(
        transactionsCsv,
        contains('transaction_id,inventory_record_id,item_id'),
      );
      expect(transactionsCsv, contains('Lowes'));
      expect(transactionsCsv, contains('Drawer 3'));
      expect(manifest['inventoryRecordCount'], 1);
      expect(manifest['stockEventCount'], 1);
      expect(manifest['transactionCount'], 1);
      expect(
        manifest['files'].toString(),
        contains('work_supply_inventory_transactions.csv'),
      );
    },
    timeout: _inventoryStoreTimeout,
  );
}

WorkSupplyInventoryRecord _stockRecord({
  required WorkSupplyItem item,
  required double onHand,
  required double threshold,
  required String storageArea,
  String storageDetail = '',
  double lastUnitCost = 0,
  bool receiptLinked = true,
  double packagesPurchased = 1,
  double unitsPerPackage = 1,
  double lineSubtotal = 0,
  double taxRate = 0,
  String businessUse = 'business',
  double businessPercent = 1,
  String sourceMerchantName = '',
  DateTime? loggedAt,
}) {
  return WorkSupplyInventoryRecord(
    item: item,
    onHand: onHand,
    threshold: threshold,
    lastUnitCost: lastUnitCost,
    storageArea: storageArea,
    storageDetail: storageDetail,
    receiptLinked: receiptLinked,
    packagesPurchased: packagesPurchased,
    unitsPerPackage: unitsPerPackage,
    lineSubtotal: lineSubtotal,
    taxRate: taxRate,
    businessUse: businessUse,
    businessPercent: businessPercent,
    sourceMerchantName: sourceMerchantName,
    loggedAt: loggedAt,
  );
}
