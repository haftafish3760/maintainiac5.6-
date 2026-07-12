import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_receipt_parser.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_runtime_loader.dart';

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
