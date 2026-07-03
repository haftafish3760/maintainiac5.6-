import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_import_validator.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_export.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';

void main() {
  group('inventory parser current-phase mirror and export behavior', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'work_supply_mirror_export_behavior_',
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('hosted catalog mirror stays manifest plus storage chunks', () async {
      final directory = await _syntheticHostedCatalogDirectory(
        base: tempDirectory,
        itemCount: 2,
      );

      final result = await const WorkSupplyHostedCatalogImportValidator()
          .validateDirectory(directory);

      expect(result.isReady, isTrue);
      expect(result.manifest, isNotNull);
      expect(result.manifest!.isFirestoreReadSafe, isTrue);
      expect(result.manifest!.firestoreManifestReadCount, lessThanOrEqualTo(2));
      expect(result.manifest!.firestoreItemDocumentReadCount, 0);
      expect(result.checkedItemCount, 2);
      expect(result.toHealthMap()['firestoreItemDocumentReadCount'], 0);
      expect(
        result.manifest!.toMap()['deliveryMode'],
        'manifest_storage_chunks',
      );
    });

    test(
      'hosted catalog validator rejects per-item Firestore mirror shape',
      () async {
        final directory = await _syntheticHostedCatalogDirectory(
          base: tempDirectory,
          firestoreItemDocumentReadCount: 1,
        );

        final result = await const WorkSupplyHostedCatalogImportValidator()
            .validateDirectory(directory);

        expect(
          result.status,
          WorkSupplyHostedCatalogValidationStatus.unsafeFirestoreShape,
        );
        expect(result.issues.single, contains('Firestore read safe'));
        expect(result.toHealthMap()['firestoreItemDocumentReadCount'], 1);
      },
    );

    test(
      'Hive inventory transactions preserve receipt source and export fields',
      () async {
        Hive.init(tempDirectory.path);
        final store = await WorkSupplyInventoryStore.create();
        final item = _item('Plumbing', 'PEX Test Elbow');

        await store.addStock(
          WorkSupplyInventoryRecord(
            item: item,
            onHand: 5,
            threshold: 1,
            lastUnitCost: 2.25,
            storageArea: 'Truck 24',
            storageDetail: 'Bin A',
            receiptLinked: true,
            packagesPurchased: 1,
            unitsPerPackage: 5,
            lineSubtotal: 10,
            taxRate: .07,
            markupRate: .2,
            sourceReceiptId: 'RCP-7788',
            sourceReceiptLineId: 'RCP-7788-L3',
            sourceMerchantName: 'LOWES',
            jobNumber: 'JOB-42',
            jobName: 'Kitchen rough-in',
            loggedAt: DateTime.utc(2026, 7, 2, 13),
          ),
        );

        final snapshot = store.buildExportSnapshot(
          exportedAt: DateTime.utc(2026, 7, 2, 14),
        );
        final record = snapshot.inventoryRecords.single;
        final transaction = snapshot.transactions.single;
        final inventoryCsv = snapshot.toInventoryCsv();
        final transactionCsv = snapshot.toTransactionsCsv();
        final manifest = snapshot.toManifest();

        expect(record.sourceReceiptId, 'RCP-7788');
        expect(record.sourceReceiptLineId, 'RCP-7788-L3');
        expect(transaction.sourceReceiptId, 'RCP-7788');
        expect(transaction.sourceReceiptLineId, 'RCP-7788-L3');
        expect(transaction.jobNumber, 'JOB-42');
        expect(transaction.jobName, 'Kitchen rough-in');
        expect(inventoryCsv, contains('source_receipt_line_id'));
        expect(inventoryCsv, contains('RCP-7788-L3'));
        expect(transactionCsv, contains('source_receipt_line_id'));
        expect(transactionCsv, contains('replaces_transaction_id'));
        expect(transactionCsv, contains('reversed_transaction_id'));
        expect(transactionCsv, contains('JOB-42'));
        expect(manifest['transactionCount'], 1);
        expect(
          manifest['files'],
          contains('work_supply_inventory_transactions.csv'),
        );
      },
    );

    test('export serialization does not mutate source inventory records', () {
      final item = _item('Electrical', 'Test Conduit Coupling');
      final record = WorkSupplyInventoryRecord(
        id: 'INV-1',
        item: item,
        onHand: 3,
        threshold: 1,
        lastUnitCost: 4,
        storageArea: 'Truck 25',
        storageDetail: 'Drawer 2',
        receiptLinked: true,
        sourceReceiptId: 'RCP-IMMUTABLE',
        sourceReceiptLineId: 'RCP-IMMUTABLE-L1',
        sourceMerchantName: 'Home Depot',
      );
      final snapshot = WorkSupplyInventoryExportSnapshot(
        exportedAt: DateTime.utc(2026, 7, 2),
        inventoryRecords: [record],
        stockEvents: const [],
      );

      final before = [
        record.id,
        record.onHand,
        record.storageArea,
        record.sourceReceiptLineId,
      ];
      final csv = snapshot.toInventoryCsv();
      final after = [
        record.id,
        record.onHand,
        record.storageArea,
        record.sourceReceiptLineId,
      ];

      expect(csv, contains('RCP-IMMUTABLE-L1'));
      expect(after, before);
    });
  });
}

WorkSupplyItem _item(String trade, String name) {
  return WorkSupplyItem(
    id: 'TEST-${trade.toUpperCase()}-${name.toUpperCase().replaceAll(' ', '-')}',
    name: name,
    trade: trade,
    category: trade == 'HVAC' ? 'Filters' : 'Fittings',
    system: trade == 'Electrical'
        ? 'PVC Conduit'
        : trade == 'HVAC'
        ? 'Airflow'
        : 'PEX',
    itemType: trade == 'HVAC' ? 'Pleated Filter' : 'Coupling',
    variant: trade == 'HVAC' ? '20 x 25 x 1' : '1/2 in',
    unit: 'each',
    aliases: [name.toLowerCase(), 'test parser alias'],
  );
}

Future<Directory> _syntheticHostedCatalogDirectory({
  required Directory base,
  int itemCount = 1,
  int firestoreItemDocumentReadCount = 0,
}) async {
  final directory = Directory(
    '${base.path}/synthetic_hosted_catalog_${itemCount}_$firestoreItemDocumentReadCount',
  );
  await directory.create(recursive: true);
  final items = [
    for (var index = 0; index < itemCount; index++)
      {
        'canonicalKey': 'synthetic.item.$index',
        'id': 'SYN-$index',
        'name': 'Synthetic Item $index',
        'trade': index.isEven ? 'Plumbing' : 'HVAC',
        'category': 'Synthetic',
        'system': 'Parser QA',
        'itemType': 'Mirror Test',
        'variant': '$index',
        'unit': 'each',
        'searchTerms': ['synthetic', 'item', '$index'],
        'aliases': [
          {
            'value': 'synthetic item $index',
            'normalized': 'synthetic item $index',
          },
        ],
      },
  ];
  final payload = {
    'schemaVersion': workSupplyCatalogPackSchemaVersion,
    'items': items,
  };
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final gzipBytes = gzip.encode(jsonBytes);
  const storagePrefix = 'catalog-packs/work-supplies';
  const storagePath = '$storagePrefix/synthetic_0001.json.gz';
  final chunkFile = File('${directory.path}/$storagePath');
  await chunkFile.parent.create(recursive: true);
  await chunkFile.writeAsBytes(gzipBytes, flush: true);
  final manifest = {
    'schemaVersion': 1,
    'packId': 'synthetic-hosted-catalog',
    'packVersion': '2026.07.02',
    'generatedAtIso': '2026-07-02T12:00:00.000Z',
    'manifestDocumentPath': 'parserCatalog/workSupplies',
    'storagePrefix': storagePrefix,
    'itemCount': itemCount,
    'tradeCount': 2,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': firestoreItemDocumentReadCount,
    'estimatedCompressedBytes': gzipBytes.length,
    'chunks': [
      {
        'chunkId': 'synthetic_0001',
        'tradeName': 'Mixed',
        'itemCount': itemCount,
        'storagePath': storagePath,
        'contentEncoding': 'gzip',
        'uncompressedByteSize': jsonBytes.length,
        'estimatedCompressedByteSize': gzipBytes.length,
        'sha256': sha256.convert(jsonBytes).toString(),
      },
    ],
  };
  await File(
    '${directory.path}/manifest.json',
  ).writeAsString(jsonEncode(manifest), flush: true);
  return directory;
}
