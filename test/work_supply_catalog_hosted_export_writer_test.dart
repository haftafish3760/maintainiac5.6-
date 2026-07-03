import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';

void main() {
  test(
    'hosted catalog export writes manifest and gzipped chunks',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'maintainiac_catalog_export_test_',
      );
      addTearDown(() async {
        if (await base.exists()) await base.delete(recursive: true);
      });

      final result = await WorkSupplyHostedCatalogExportWriter(
        baseDirectory: base,
      ).writeHostedCatalogPack(generatedAt: DateTime.utc(2026, 6, 23, 12));

      expect(await File(result.manifestPath).exists(), isTrue);
      expect(result.chunkPaths, hasLength(result.manifest.chunkCount));
      expect(result.files, hasLength(result.manifest.chunkCount + 1));
      for (final path in result.chunkPaths) {
        expect(path, endsWith('.json.gz'));
        expect(await File(path).exists(), isTrue);
        expect(await File(path).length(), greaterThan(0));
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'hosted catalog export manifest stays Firestore lightweight',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'maintainiac_catalog_manifest_test_',
      );
      addTearDown(() async {
        if (await base.exists()) await base.delete(recursive: true);
      });

      final result = await WorkSupplyHostedCatalogExportWriter(
        baseDirectory: base,
      ).writeHostedCatalogPack(generatedAt: DateTime.utc(2026, 6, 23, 12));
      final manifestText = await File(result.manifestPath).readAsString();
      final manifest = jsonDecode(manifestText) as Map<String, dynamic>;
      final chunks = manifest['chunks']! as List<dynamic>;

      expect(manifest['firestoreManifestReadCount'], 1);
      expect(manifest['firestoreItemDocumentReadCount'], 0);
      expect(manifest['deliveryMode'], 'manifest_storage_chunks');
      expect(manifest.containsKey('items'), isFalse);
      expect(chunks, hasLength(result.manifest.chunkCount));
      expect(
        chunks.every(
          (chunk) => !(chunk as Map<String, dynamic>).containsKey('items'),
        ),
        isTrue,
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'hosted catalog export chunks match manifest checksums',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'maintainiac_catalog_checksum_test_',
      );
      addTearDown(() async {
        if (await base.exists()) await base.delete(recursive: true);
      });

      final result = await WorkSupplyHostedCatalogExportWriter(
        baseDirectory: base,
      ).writeHostedCatalogPack(generatedAt: DateTime.utc(2026, 6, 23, 12));
      final firstChunk = result.manifest.chunks.first;
      final chunkFile = File(
        '${result.directoryPath}/${firstChunk.storagePath}',
      );
      final gzipBytes = await chunkFile.readAsBytes();
      final jsonBytes = gzip.decode(gzipBytes);
      final decoded =
          jsonDecode(utf8.decode(jsonBytes)) as Map<String, dynamic>;

      expect(sha256.convert(jsonBytes).toString(), firstChunk.sha256);
      expect(decoded['schemaVersion'], workSupplyCatalogPackSchemaVersion);
      expect(decoded['packId'], result.manifest.packId);
      expect(decoded['packVersion'], result.manifest.packVersion);
      expect(decoded['items'], isA<List<dynamic>>());
      expect(decoded['items'], hasLength(firstChunk.itemCount));
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'hosted catalog export is deterministic for the same generated time',
    () async {
      final base = await Directory.systemTemp.createTemp(
        'maintainiac_catalog_deterministic_test_',
      );
      addTearDown(() async {
        if (await base.exists()) await base.delete(recursive: true);
      });

      final writer = WorkSupplyHostedCatalogExportWriter(baseDirectory: base);
      final first = await writer.writeHostedCatalogPack(
        generatedAt: DateTime.utc(2026, 6, 23, 12),
      );
      final second = await writer.writeHostedCatalogPack(
        generatedAt: DateTime.utc(2026, 6, 23, 12),
      );

      expect(first.manifest.toMap(), second.manifest.toMap());
      expect(
        first.manifest.chunks.map((chunk) => chunk.sha256),
        orderedEquals(second.manifest.chunks.map((chunk) => chunk.sha256)),
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test('chunk payload hashes match hosted manifest helper output', () {
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final payloads = buildWorkSupplyHostedCatalogChunkPayloads();
    final payloadHashes = {
      for (final payload in payloads)
        payload.manifest.chunkId: payload.sha256Hex,
    };

    expect(payloads, hasLength(manifest.chunkCount));
    for (final chunk in manifest.chunks) {
      expect(payloadHashes[chunk.chunkId], chunk.sha256);
    }
  });
}
