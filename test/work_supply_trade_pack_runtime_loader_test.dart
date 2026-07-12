import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_runtime_loader.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('loads a validated local pack into immutable runtime items', () async {
    final pack = await _writePackFixture();
    addTearDown(() async {
      if (await pack.exists()) await pack.delete(recursive: true);
    });

    final result = await const WorkSupplyTradePackRuntimeLoader().loadDirectory(
      pack,
    );

    expect(result.isReady, isTrue);
    expect(result.items, hasLength(1));
    expect(result.items.single.id, 'plumbing-elbow');
    expect(result.items.single.aliases, contains('PVC Ell'));
    expect(result.items.single.intelligence.receiptPatterns, ['pvc ell']);

    final match = matchReceiptLineToCatalog(
      '3/4 PVC ELBOW',
      tradeScope: 'Plumbing',
      catalogItems: result.items,
    );
    expect(match, isNotNull);
    expect(match!.item.id, 'plumbing-elbow');
  });

  test('refuses a corrupted local pack before runtime decoding', () async {
    final pack = await _writePackFixture(corruptChunk: true);
    addTearDown(() async {
      if (await pack.exists()) await pack.delete(recursive: true);
    });

    final result = await const WorkSupplyTradePackRuntimeLoader().loadDirectory(
      pack,
    );

    expect(
      result.status,
      WorkSupplyTradePackRuntimeLoadStatus.validationFailed,
    );
    expect(result.items, isEmpty);
  });

  test(
    'loads the actual Residential Plumbing Core pack for offline receipt parsing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_plumbing_core_runtime_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final option = buildWorkSupplyTradePackOptionsForScope(
        'Plumbing',
        marketScope: WorkSupplyMarketScope.residential,
      ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
      final fileSet = await WorkSupplyTradePackExportWriter(
        baseDirectory: root,
      ).writeTradePack(option: option);

      final result = await const WorkSupplyTradePackRuntimeLoader()
          .loadDirectory(Directory(fileSet.directoryPath));

      expect(result.isReady, isTrue);
      expect(result.items, hasLength(option.itemCount));
      for (final entry in {
        'HD 3/4 PVC SCH40 COUPLING': 'pvc schedule 40 coupling',
        'LOWES SINK REPAIR KIT': 'sink repair kit',
        'TRACTOR SUPPLY 1HP SHALLOW WELL PUMP': 'well pump',
      }.entries) {
        final match = matchReceiptLineToCatalog(
          entry.key,
          tradeScope: 'Plumbing',
          catalogItems: result.items,
        );
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, 'Plumbing');
        expect(match.item.name.toLowerCase(), contains(entry.value));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'loads the actual Residential HVAC Core pack for offline receipt parsing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_hvac_core_runtime_test_',
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

      final result = await const WorkSupplyTradePackRuntimeLoader()
          .loadDirectory(Directory(fileSet.directoryPath));

      expect(result.isReady, isTrue);
      expect(result.items, hasLength(option.itemCount));
      for (final entry in {
        'SUPPLY 45/5 MFD DUAL RUN CAP': 'capacitor',
        'HD 16X20X1 PLEATED AIR FILTER': 'filter',
        'SUPPLY FLAME SENSOR UNIVERSAL': 'flame sensor',
      }.entries) {
        final match = matchReceiptLineToCatalog(
          entry.key,
          tradeScope: 'HVAC',
          catalogItems: result.items,
        );
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, 'HVAC');
        expect(match.item.name.toLowerCase(), contains(entry.value));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'loads the actual Residential Electrical Core pack for offline receipt parsing',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'maintainiac_electrical_core_runtime_test_',
      );
      addTearDown(() async {
        if (await root.exists()) await root.delete(recursive: true);
      });
      final option = buildWorkSupplyTradePackOptionsForScope(
        'Electrical',
        marketScope: WorkSupplyMarketScope.residential,
      ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
      final fileSet = await WorkSupplyTradePackExportWriter(
        baseDirectory: root,
      ).writeTradePack(option: option);

      final result = await const WorkSupplyTradePackRuntimeLoader()
          .loadDirectory(Directory(fileSet.directoryPath));

      expect(result.isReady, isTrue);
      expect(result.items, hasLength(option.itemCount));
      for (final entry in {
        'HD 12/2 NM-B W/G 250FT': 'nm-b',
        'LOWES 20A WR GFCI RECPT WHITE': 'gfci',
        'HD 20A 1P BRKR': 'breaker',
      }.entries) {
        final match = matchReceiptLineToCatalog(
          entry.key,
          tradeScope: 'Electrical',
          catalogItems: result.items,
        );
        expect(match, isNotNull, reason: entry.key);
        expect(match!.item.trade, 'Electrical');
        expect(match.item.name.toLowerCase(), contains(entry.value));
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<Directory> _writePackFixture({bool corruptChunk = false}) async {
  final directory = await Directory.systemTemp.createTemp(
    'maintainiac_trade_pack_runtime_loader_test_',
  );
  final payloadBytes = utf8.encode(
    jsonEncode({
      'schemaVersion': workSupplyCatalogPackSchemaVersion,
      'items': [
        {
          'canonicalKey': 'plumbing|fittings|elbow',
          'id': 'plumbing-elbow',
          'name': 'PVC Schedule 40 Elbow',
          'trade': 'Plumbing',
          'category': 'Fittings',
          'system': 'PVC',
          'itemType': 'Elbow',
          'variant': '3/4 in',
          'unit': 'each',
          'marketScopes': ['residential'],
          'packTier': 'core',
          'parserPriority': 'everydayCore',
          'intelligence': {
            'receiptPatterns': ['pvc ell'],
            'vendorMappings': [],
            'classification': {},
          },
          'searchTerms': ['pvc', 'elbow'],
          'aliases': [
            {'value': 'PVC Ell', 'normalized': 'pvc ell', 'source': 'test'},
          ],
          'merchantAliases': [],
          'barcodeAliases': [],
          'merchantSkuAliases': [],
          'packageHints': ['unit:each'],
        },
      ],
    }),
  );
  final chunkPath = 'chunks/plumbing_core_0001.json.gz';
  final chunk = File('${directory.path}/$chunkPath');
  await chunk.parent.create(recursive: true);
  await chunk.writeAsBytes(gzip.encode(payloadBytes));
  if (corruptChunk) await chunk.writeAsBytes([0, 1, 2], flush: true);

  await File('${directory.path}/manifest.json').writeAsString(
    jsonEncode({
      'schemaVersion': 1,
      'packId': 'plumbing_core_test',
      'packVersion': 'test',
      'generatedAtIso': DateTime.utc(2026, 7, 12).toIso8601String(),
      'tradeName': 'Plumbing',
      'tier': 'core',
      'localePackId': 'en-US',
      'countryCodes': ['US'],
      'displayName': 'Plumbing Core Test',
      'itemCount': 1,
      'chunkCount': 1,
      'firestoreManifestReadCount': 1,
      'firestoreItemDocumentReadCount': 0,
      'estimatedUncompressedBytes': payloadBytes.length,
      'estimatedCompressedBytes': gzip.encode(payloadBytes).length,
      'chunks': [
        {
          'chunkId': 'plumbing_core_0001',
          'itemCount': 1,
          'storagePath': chunkPath,
          'contentEncoding': 'gzip',
          'uncompressedByteSize': payloadBytes.length,
          'estimatedCompressedByteSize': gzip.encode(payloadBytes).length,
          'sha256': sha256.convert(payloadBytes).toString(),
        },
      ],
    }),
  );
  return directory;
}
