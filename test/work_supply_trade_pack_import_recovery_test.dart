import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';

void main() {
  test(
    'import validator rejects missing chunks without partial success',
    () async {
      final pack = await _writeSamplePack();
      addTearDown(pack.delete);

      File('${pack.directory.path}/${pack.storagePath}').deleteSync();

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(pack.directory);

      expect(result.isReady, isFalse);
      expect(result.status, WorkSupplyTradePackValidationStatus.missingChunk);
      expect(result.checkedChunkCount, 0);
      expect(result.issues.single, contains(pack.storagePath));
    },
  );

  test('import validator rejects corrupt gzip chunks', () async {
    final pack = await _writeSamplePack();
    addTearDown(pack.delete);

    File(
      '${pack.directory.path}/${pack.storagePath}',
    ).writeAsStringSync('not a gzip payload');

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(pack.directory);

    expect(result.isReady, isFalse);
    expect(result.status, WorkSupplyTradePackValidationStatus.unreadableChunk);
    expect(result.checkedChunkCount, 0);
    expect(result.issues.single, contains(pack.chunkId));
  });

  test('import validator rejects checksum-mismatched chunks', () async {
    final pack = await _writeSamplePack();
    addTearDown(pack.delete);

    final chunkFile = File('${pack.directory.path}/${pack.storagePath}');
    final decoded =
        jsonDecode(utf8.decode(gzip.decode(chunkFile.readAsBytesSync())))
            as Map;
    decoded['packVersion'] = 'tampered-after-manifest';
    chunkFile.writeAsBytesSync(gzip.encode(utf8.encode(jsonEncode(decoded))));

    final result = await const WorkSupplyTradePackImportValidator()
        .validateDirectory(pack.directory);

    expect(result.isReady, isFalse);
    expect(result.status, WorkSupplyTradePackValidationStatus.checksumMismatch);
    expect(result.checkedChunkCount, 0);
    expect(result.issues.single, contains(pack.chunkId));
  });

  test(
    'import validator rejects unsafe chunk paths before reading disk',
    () async {
      final pack = await _writeSamplePack();
      addTearDown(pack.delete);

      final manifestFile = File('${pack.directory.path}/manifest.json');
      final manifest = jsonDecode(manifestFile.readAsStringSync()) as Map;
      final chunks = manifest['chunks'] as List;
      final firstChunk = Map<String, Object?>.from(chunks.first as Map);
      firstChunk['storagePath'] = '../escape.json.gz';
      chunks[0] = firstChunk;
      manifestFile.writeAsStringSync(jsonEncode(manifest));

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(pack.directory);

      expect(result.isReady, isFalse);
      expect(
        result.status,
        WorkSupplyTradePackValidationStatus.invalidChunkPath,
      );
      expect(result.checkedChunkCount, 0);
      expect(result.issues.single, contains('unsafe'));
    },
  );
}

Future<_PackFixture> _writeSamplePack() async {
  final base = await Directory.systemTemp.createTemp(
    'maintainiac_trade_pack_recovery_',
  );
  const chunkId = 'plumbing_residential_core_001';
  const storagePath = 'packs/plumbing/residential/core/$chunkId.json.gz';
  final payload = {
    'schemaVersion': 3,
    'packId': 'maintainiac.work-supplies.plumbing.residential.core',
    'packVersion': 'test-recovery',
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': 'en-US',
    'countryCodes': ['US'],
    'items': [
      {
        'canonicalKey': 'plumbing|fittings|pex|90 elbows|1/2 in',
        'id': 'TEST-PEX-90',
        'name': '1/2 in PEX 90 Elbow',
        'searchTerms': ['pex', '90', 'elbow'],
        'aliases': [
          {'value': 'PEX 90', 'normalized': 'pex 90', 'source': 'test'},
        ],
      },
    ],
  };
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final chunkFile = File('${base.path}/$storagePath');
  await chunkFile.parent.create(recursive: true);
  await chunkFile.writeAsBytes(gzip.encode(jsonBytes), flush: true);
  final manifest = {
    'schemaVersion': 1,
    'packId': 'maintainiac.work-supplies.plumbing.residential.core',
    'packVersion': 'test-recovery',
    'generatedAtIso': '2026-06-27T12:00:00.000Z',
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': 'en-US',
    'countryCodes': ['US'],
    'displayName': 'Plumbing Residential Core',
    'itemCount': 1,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': 0,
    'estimatedUncompressedBytes': jsonBytes.length,
    'estimatedCompressedBytes': await chunkFile.length(),
    'chunks': [
      {
        'chunkId': chunkId,
        'itemCount': 1,
        'storagePath': storagePath,
        'contentEncoding': 'gzip',
        'uncompressedByteSize': jsonBytes.length,
        'estimatedCompressedByteSize': await chunkFile.length(),
        'sha256': sha256.convert(jsonBytes).toString(),
      },
    ],
  };
  await File(
    '${base.path}/manifest.json',
  ).writeAsString(jsonEncode(manifest), flush: true);
  return _PackFixture(
    directory: base,
    chunkId: chunkId,
    storagePath: storagePath,
  );
}

class _PackFixture {
  const _PackFixture({
    required this.directory,
    required this.chunkId,
    required this.storagePath,
  });

  final Directory directory;
  final String chunkId;
  final String storagePath;

  Future<void> delete() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
