import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';

void main() {
  test('validator accepts parser-ready trade pack', () async {
    final pack = await _writePackFixture();
    addTearDown(() async {
      if (await pack.exists()) await pack.delete(recursive: true);
    });

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(pack);

    expect(result.isReady, isTrue);
    expect(result.checkedChunkCount, 1);
    expect(result.checkedItemCount, 1);
    expect(result.issues, isEmpty);
  });

  test('validator rejects per-item Firestore shaped manifest', () async {
    final pack = await _writePackFixture(firestoreItemDocumentReadCount: 2000);
    addTearDown(() async {
      if (await pack.exists()) await pack.delete(recursive: true);
    });

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(pack);

    expect(
      result.status,
      WorkSupplyTradePackValidationStatus.unsafeFirestoreShape,
    );
    expect(result.issues.single, contains('per-item Firestore reads'));
  });
}

Future<Directory> _writePackFixture({
  int firestoreItemDocumentReadCount = 0,
}) async {
  final directory = await Directory.systemTemp.createTemp(
    'maintainiac_trade_pack_validator_test_',
  );
  final payloadJson = jsonEncode({
    'schemaVersion': workSupplyCatalogPackSchemaVersion,
    'items': [
      {
        'canonicalKey': 'plumbing|fittings|elbow',
        'id': 'plumbing-elbow',
        'name': 'PVC Elbow',
        'trade': 'Plumbing',
        'category': 'Fittings',
        'system': 'PVC',
        'itemType': 'Elbow',
        'variant': '3/4 in',
        'unit': 'each',
        'searchTerms': ['pvc', 'elbow'],
        'aliases': [
          {'value': 'PVC Elbow', 'normalized': 'pvc elbow', 'source': 'test'},
        ],
        'merchantAliases': [],
        'barcodeAliases': [],
        'merchantSkuAliases': [],
        'packageHints': ['unit:each'],
      },
    ],
  });
  final payloadBytes = utf8.encode(payloadJson);
  final compressed = gzip.encode(payloadBytes);
  final chunkPath = 'chunks/plumbing_core_0001.json.gz';
  final chunkFile = File('${directory.path}/$chunkPath');
  await chunkFile.parent.create(recursive: true);
  await chunkFile.writeAsBytes(compressed);
  final manifest = {
    'schemaVersion': 1,
    'packId': 'plumbing_core_test',
    'packVersion': 'test',
    'generatedAtIso': DateTime.utc(2026, 6, 27, 12).toIso8601String(),
    'tradeName': 'Plumbing',
    'tier': 'core',
    'displayName': 'Plumbing Core Test',
    'itemCount': 1,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': firestoreItemDocumentReadCount,
    'estimatedCompressedBytes': compressed.length,
    'chunks': [
      {
        'chunkId': 'plumbing_core_0001',
        'itemCount': 1,
        'storagePath': chunkPath,
        'contentEncoding': 'gzip',
        'uncompressedByteSize': payloadBytes.length,
        'estimatedCompressedByteSize': compressed.length,
        'sha256': sha256.convert(payloadBytes).toString(),
      },
    ],
  };
  await File('${directory.path}/manifest.json').writeAsString(
    jsonEncode(manifest),
  );
  return directory;
}
