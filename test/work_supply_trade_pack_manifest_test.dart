import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_export_writer.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_manifest.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_tiers.dart';

void main() {
  test('trade pack manifest keeps Firestore reads bundled', () {
    final plumbing = buildWorkSupplyTradePackOptions(
      'Plumbing',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.full);
    final manifest = buildWorkSupplyTradePackManifest(
      plumbing,
      generatedAt: DateTime.utc(2026, 6, 27, 12),
    );
    final map = manifest.toMap();

    expect(manifest.isFirestoreReadSafe, isTrue);
    expect(manifest.firestoreManifestReadCount, 1);
    expect(manifest.firestoreItemDocumentReadCount, 0);
    expect(manifest.itemCount, plumbing.itemCount);
    expect(manifest.chunkCount, manifest.chunks.length);
    expect(manifest.estimatedUncompressedBytes, greaterThan(0));
    expect(
      manifest.estimatedUncompressedBytes,
      greaterThan(manifest.estimatedCompressedBytes),
    );
    expect(map.containsKey('items'), isFalse);
    expect(
      map['estimatedUncompressedBytes'],
      manifest.estimatedUncompressedBytes,
    );
    expect(map['deliveryMode'], 'trade_pack_manifest_storage_chunks');
    final deliveryPolicy = map['deliveryPolicy'] as Map;
    expect(deliveryPolicy['deliveryModes'], contains('local_gzip_pack'));
    expect(deliveryPolicy['deliveryModes'], contains('cloud_catalog_query'));
    final cloudFallback = deliveryPolicy['cloudFallback'] as Map;
    expect(cloudFallback['requiresInternet'], isTrue);
    expect(cloudFallback['requiresSubscription'], isTrue);
    expect(
      cloudFallback['targetCatalogReadsPerUserPerDay'],
      lessThanOrEqualTo(100),
    );
    expect(
      manifest.chunks.every((chunk) => chunk.storagePath.endsWith('.json.gz')),
      isTrue,
    );
  });

  test('scoped trade pack manifest carries scope and on-device size', () {
    final residentialCore = buildWorkSupplyTradePackOptionsForScope(
      'Plumbing',
      marketScope: WorkSupplyMarketScope.residential,
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
    final manifest = buildWorkSupplyTradePackManifest(
      residentialCore,
      generatedAt: DateTime.utc(2026, 6, 27, 12),
    );
    final firstChunk = manifest.chunks.first;

    expect(manifest.marketScope, WorkSupplyMarketScope.residential);
    expect(manifest.itemCount, residentialCore.itemCount);
    expect(manifest.toMap()['marketScope'], 'residential');
    expect(manifest.toMap()['localePackId'], workSupplyDefaultLocalePackId);
    expect(manifest.toMap()['countryCodes'], workSupplyDefaultCountryCodes);
    expect(manifest.packId, contains('.residential.core'));
    expect(firstChunk.storagePath, contains('/plumbing/residential/core/'));
    expect(firstChunk.uncompressedByteSize, greaterThan(0));
    expect(
      manifest.estimatedUncompressedBytes,
      greaterThan(manifest.estimatedCompressedBytes),
    );
  });

  test('trade pack chunks carry only selected tier items', () {
    final core = buildWorkSupplyTradePackOptions(
      'Plumbing',
    ).firstWhere((option) => option.tier == WorkSupplyTradePackTier.core);
    final payloads = buildWorkSupplyTradePackChunkPayloads(core);
    final itemCount = payloads.fold<int>(
      0,
      (sum, payload) => sum + payload.manifest.itemCount,
    );

    expect(itemCount, core.itemCount);
    expect(
      payloads.every(
        (payload) =>
            payload.manifest.itemCount <=
            workSupplyTradePackTargetChunkItemCount,
      ),
      isTrue,
    );
    expect(
      payloads.every((payload) => payload.sha256Hex == payload.manifest.sha256),
      isTrue,
    );
  });

  test('trade pack export writes manifest and gzipped chunks', () async {
    final base = await Directory.systemTemp.createTemp(
      'maintainiac_trade_pack_export_test_',
    );
    addTearDown(() async {
      if (await base.exists()) await base.delete(recursive: true);
    });
    final option = buildWorkSupplyTradePackOptions(
      'Electrical',
    ).firstWhere((candidate) => candidate.tier == WorkSupplyTradePackTier.full);

    final result = await WorkSupplyTradePackExportWriter(baseDirectory: base)
        .writeTradePack(
          option: option,
          generatedAt: DateTime.utc(2026, 6, 27, 12),
        );
    final manifestText = await File(result.manifestPath).readAsString();
    final manifestMap = jsonDecode(manifestText) as Map<String, dynamic>;
    final firstChunk = result.manifest.chunks.first;
    final chunkBytes = await File(
      '${result.directoryPath}/${firstChunk.storagePath}',
    ).readAsBytes();
    final jsonBytes = gzip.decode(chunkBytes);

    expect(result.files, hasLength(result.manifest.chunkCount + 1));
    expect(result.chunkPaths, hasLength(result.manifest.chunkCount));
    expect(manifestMap.containsKey('items'), isFalse);
    expect(sha256.convert(jsonBytes).toString(), firstChunk.sha256);
    expect(await File(result.chunkPaths.first).length(), greaterThan(0));
  });

  test('full trades catalog manifest remains chunked and read-safe', () {
    final option = buildFullWorkSupplyTradePackOption();
    final manifest = buildWorkSupplyTradePackManifest(
      option,
      generatedAt: DateTime.utc(2026, 6, 27, 12),
    );

    expect(manifest.tradeName, workSupplyFullTradesCatalogName);
    expect(manifest.itemCount, option.itemCount);
    expect(manifest.chunkCount, greaterThan(1));
    expect(manifest.isFirestoreReadSafe, isTrue);
    expect(
      manifest.chunks.every(
        (chunk) => chunk.storagePath.contains('/full-trades-catalog/complete/'),
      ),
      isTrue,
    );
  });
}
