import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_audit.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_hosted_manifest.dart';

void main() {
  test(
    'hosted catalog manifest uses one Firestore manifest and Storage chunks',
    () {
      final manifest = buildWorkSupplyHostedCatalogManifest(
        generatedAt: DateTime.utc(2026, 6, 23, 12),
      );

      expect(manifest.schemaVersion, 1);
      expect(manifest.packId, workSupplyCatalogPackId);
      expect(manifest.packVersion, workSupplyCatalogPackVersion);
      expect(
        manifest.manifestDocumentPath,
        workSupplyCatalogManifestDocumentPath,
      );
      expect(manifest.storagePrefix, workSupplyCatalogStoragePrefix);
      expect(manifest.itemCount, workSupplyCatalogItems.length);
      expect(manifest.tradeCount, workSupplyTrades.length);
      expect(manifest.firestoreManifestReadCount, 1);
      expect(manifest.firestoreItemDocumentReadCount, 0);
      expect(manifest.isFirestoreReadSafe, isTrue);
      expect(manifest.chunkCount, manifest.chunks.length);
      expect(manifest.chunks.length, greaterThan(1));
      expect(
        manifest.chunks.every(
          (chunk) =>
              chunk.storagePath.startsWith(workSupplyCatalogStoragePrefix),
        ),
        isTrue,
      );
      expect(
        manifest.chunks.every(
          (chunk) => chunk.storagePath.endsWith('.json.gz'),
        ),
        isTrue,
      );
    },
  );

  test('hosted catalog manifest chunks carry integrity metadata', () {
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );

    expect(
      manifest.chunks.every((chunk) => chunk.contentEncoding == 'gzip'),
      isTrue,
    );
    expect(
      manifest.chunks.every(
        (chunk) => RegExp(r'^[a-f0-9]{64}$').hasMatch(chunk.sha256),
      ),
      isTrue,
    );
    expect(
      manifest.chunks.every((chunk) => chunk.uncompressedByteSize > 0),
      isTrue,
    );
    expect(
      manifest.chunks.every((chunk) => chunk.estimatedCompressedByteSize > 0),
      isTrue,
    );
    expect(
      manifest.chunks.every(
        (chunk) => chunk.itemCount <= workSupplyCatalogMaxChunkItemCount,
      ),
      isTrue,
    );
  });

  test('hosted catalog manifest map is command-center and upload ready', () {
    final manifest = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final map = manifest.toMap();

    expect(map['deliveryMode'], 'manifest_storage_chunks');
    expect(map['firestoreItemDocumentReadCount'], 0);
    expect(map['chunks'], isA<List<Object?>>());
    final chunks = map['chunks']! as List<Object?>;
    expect(chunks, hasLength(manifest.chunkCount));
    final firstChunk = chunks.first! as Map<String, Object?>;
    expect(firstChunk['storagePath'], contains('.json.gz'));
    expect(firstChunk['sha256'], isA<String>());
    expect(firstChunk.containsKey('items'), isFalse);
  });

  test('hosted catalog manifest is deterministic for the same pack data', () {
    final first = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );
    final second = buildWorkSupplyHostedCatalogManifest(
      generatedAt: DateTime.utc(2026, 6, 23, 12),
    );

    expect(first.toMap(), second.toMap());
    expect(
      first.chunks.map((chunk) => chunk.sha256),
      orderedEquals(second.chunks.map((chunk) => chunk.sha256)),
    );
  });
}
