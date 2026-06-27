import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'work_supply_catalog.dart';
import 'work_supply_catalog_audit.dart';
import 'work_supply_models.dart';

class WorkSupplyHostedCatalogManifest {
  const WorkSupplyHostedCatalogManifest({
    required this.schemaVersion,
    required this.packId,
    required this.packVersion,
    required this.generatedAtIso,
    required this.manifestDocumentPath,
    required this.storagePrefix,
    required this.itemCount,
    required this.tradeCount,
    required this.chunkCount,
    required this.firestoreManifestReadCount,
    required this.firestoreItemDocumentReadCount,
    required this.estimatedCompressedBytes,
    required this.chunks,
  });

  final int schemaVersion;
  final String packId;
  final String packVersion;
  final String generatedAtIso;
  final String manifestDocumentPath;
  final String storagePrefix;
  final int itemCount;
  final int tradeCount;
  final int chunkCount;
  final int firestoreManifestReadCount;
  final int firestoreItemDocumentReadCount;
  final int estimatedCompressedBytes;
  final List<WorkSupplyHostedCatalogChunkManifest> chunks;

  bool get isFirestoreReadSafe =>
      firestoreManifestReadCount <= 2 && firestoreItemDocumentReadCount == 0;

  Map<String, Object?> toMap() {
    return {
      'schemaVersion': schemaVersion,
      'packId': packId,
      'packVersion': packVersion,
      'generatedAtIso': generatedAtIso,
      'manifestDocumentPath': manifestDocumentPath,
      'storagePrefix': storagePrefix,
      'itemCount': itemCount,
      'tradeCount': tradeCount,
      'chunkCount': chunkCount,
      'firestoreManifestReadCount': firestoreManifestReadCount,
      'firestoreItemDocumentReadCount': firestoreItemDocumentReadCount,
      'estimatedCompressedBytes': estimatedCompressedBytes,
      'deliveryMode': 'manifest_storage_chunks',
      'chunks': [for (final chunk in chunks) chunk.toMap()],
    };
  }

  factory WorkSupplyHostedCatalogManifest.fromMap(Map<dynamic, dynamic> map) {
    final chunks = (map['chunks'] as List? ?? const [])
        .whereType<Map>()
        .map(WorkSupplyHostedCatalogChunkManifest.fromMap)
        .toList(growable: false);
    return WorkSupplyHostedCatalogManifest(
      schemaVersion: _intFromMap(map, 'schemaVersion'),
      packId: _stringFromMap(map, 'packId'),
      packVersion: _stringFromMap(map, 'packVersion'),
      generatedAtIso: _stringFromMap(map, 'generatedAtIso'),
      manifestDocumentPath: _stringFromMap(map, 'manifestDocumentPath'),
      storagePrefix: _stringFromMap(map, 'storagePrefix'),
      itemCount: _intFromMap(map, 'itemCount'),
      tradeCount: _intFromMap(map, 'tradeCount'),
      chunkCount: _intFromMap(map, 'chunkCount'),
      firestoreManifestReadCount: _intFromMap(
        map,
        'firestoreManifestReadCount',
      ),
      firestoreItemDocumentReadCount: _intFromMap(
        map,
        'firestoreItemDocumentReadCount',
      ),
      estimatedCompressedBytes: _intFromMap(map, 'estimatedCompressedBytes'),
      chunks: chunks,
    );
  }
}

class WorkSupplyHostedCatalogChunkManifest {
  const WorkSupplyHostedCatalogChunkManifest({
    required this.chunkId,
    required this.tradeName,
    required this.itemCount,
    required this.storagePath,
    required this.contentEncoding,
    required this.uncompressedByteSize,
    required this.estimatedCompressedByteSize,
    required this.sha256,
  });

  final String chunkId;
  final String tradeName;
  final int itemCount;
  final String storagePath;
  final String contentEncoding;
  final int uncompressedByteSize;
  final int estimatedCompressedByteSize;
  final String sha256;

  Map<String, Object?> toMap() {
    return {
      'chunkId': chunkId,
      'tradeName': tradeName,
      'itemCount': itemCount,
      'storagePath': storagePath,
      'contentEncoding': contentEncoding,
      'uncompressedByteSize': uncompressedByteSize,
      'estimatedCompressedByteSize': estimatedCompressedByteSize,
      'sha256': sha256,
    };
  }

  factory WorkSupplyHostedCatalogChunkManifest.fromMap(
    Map<dynamic, dynamic> map,
  ) {
    return WorkSupplyHostedCatalogChunkManifest(
      chunkId: _stringFromMap(map, 'chunkId'),
      tradeName: _stringFromMap(map, 'tradeName'),
      itemCount: _intFromMap(map, 'itemCount'),
      storagePath: _stringFromMap(map, 'storagePath'),
      contentEncoding: _stringFromMap(map, 'contentEncoding'),
      uncompressedByteSize: _intFromMap(map, 'uncompressedByteSize'),
      estimatedCompressedByteSize: _intFromMap(
        map,
        'estimatedCompressedByteSize',
      ),
      sha256: _stringFromMap(map, 'sha256'),
    );
  }
}

class WorkSupplyHostedCatalogChunkPayload {
  const WorkSupplyHostedCatalogChunkPayload({
    required this.manifest,
    required this.jsonBytes,
  });

  final WorkSupplyHostedCatalogChunkManifest manifest;
  final List<int> jsonBytes;

  String get sha256Hex => sha256.convert(jsonBytes).toString();
}

WorkSupplyHostedCatalogManifest buildWorkSupplyHostedCatalogManifest({
  Iterable<WorkSupplyItem>? items,
  DateTime? generatedAt,
}) {
  final audit = auditWorkSupplyCatalog(items: items);
  final catalogItems = (items ?? workSupplyCatalogItems).toList();
  final chunkItemsById = _chunkItemsById(catalogItems, audit.deliveryPlan);
  final chunks = [
    for (final plan in audit.deliveryPlan.chunks)
      _chunkManifestFor(
        plan,
        chunkItemsById[plan.chunkId] ?? const <WorkSupplyItem>[],
      ),
  ];

  return WorkSupplyHostedCatalogManifest(
    schemaVersion: 1,
    packId: audit.deliveryPlan.packId,
    packVersion: audit.deliveryPlan.packVersion,
    generatedAtIso: (generatedAt ?? DateTime.now().toUtc()).toIso8601String(),
    manifestDocumentPath: audit.deliveryPlan.manifestDocumentPath,
    storagePrefix: audit.deliveryPlan.storagePrefix,
    itemCount: audit.itemCount,
    tradeCount: audit.tradeCount,
    chunkCount: audit.deliveryPlan.chunkCount,
    firestoreManifestReadCount: audit.deliveryPlan.firestoreManifestReadCount,
    firestoreItemDocumentReadCount:
        audit.deliveryPlan.firestoreItemDocumentReadCount,
    estimatedCompressedBytes: audit.deliveryPlan.estimatedCompressedBytes,
    chunks: List.unmodifiable(chunks),
  );
}

List<WorkSupplyHostedCatalogChunkPayload>
buildWorkSupplyHostedCatalogChunkPayloads({Iterable<WorkSupplyItem>? items}) {
  final audit = auditWorkSupplyCatalog(items: items);
  final catalogItems = (items ?? workSupplyCatalogItems).toList();
  final chunkItemsById = _chunkItemsById(catalogItems, audit.deliveryPlan);
  return [
    for (final plan in audit.deliveryPlan.chunks)
      _chunkPayloadForPlan(
        plan,
        chunkItemsById[plan.chunkId] ?? const <WorkSupplyItem>[],
      ),
  ];
}

Map<String, List<WorkSupplyItem>> _chunkItemsById(
  List<WorkSupplyItem> catalogItems,
  WorkSupplyCatalogDeliveryPlan deliveryPlan,
) {
  final tradeItems = <String, List<WorkSupplyItem>>{};
  for (final item in catalogItems) {
    tradeItems.putIfAbsent(item.trade, () => []).add(item);
  }
  final output = <String, List<WorkSupplyItem>>{};
  for (final plan in deliveryPlan.chunks) {
    final items = tradeItems[plan.tradeName] ?? const <WorkSupplyItem>[];
    final chunkIndex = int.tryParse(plan.chunkId.split('_').last) ?? 1;
    final start = (chunkIndex - 1) * workSupplyCatalogTargetChunkItemCount;
    final end = (start + workSupplyCatalogTargetChunkItemCount).clamp(
      0,
      items.length,
    );
    output[plan.chunkId] = items.sublist(start, end);
  }
  return output;
}

WorkSupplyHostedCatalogChunkManifest _chunkManifestFor(
  WorkSupplyCatalogChunkPlan plan,
  List<WorkSupplyItem> items,
) {
  return _chunkPayloadForPlan(plan, items).manifest;
}

WorkSupplyHostedCatalogChunkPayload _chunkPayloadForPlan(
  WorkSupplyCatalogChunkPlan plan,
  List<WorkSupplyItem> items,
) {
  final payload = _chunkPayloadFor(items);
  final encoded = utf8.encode(jsonEncode(payload));
  return WorkSupplyHostedCatalogChunkPayload(
    manifest: WorkSupplyHostedCatalogChunkManifest(
      chunkId: plan.chunkId,
      tradeName: plan.tradeName,
      itemCount: items.length,
      storagePath: plan.storagePath,
      contentEncoding: 'gzip',
      uncompressedByteSize: encoded.length,
      estimatedCompressedByteSize: plan.estimatedCompressedBytes,
      sha256: sha256.convert(encoded).toString(),
    ),
    jsonBytes: encoded,
  );
}

Map<String, Object?> _chunkPayloadFor(List<WorkSupplyItem> items) {
  return {
    'schemaVersion': 1,
    'packId': workSupplyCatalogPackId,
    'packVersion': workSupplyCatalogPackVersion,
    'items': [
      for (final item in items)
        {
          'id': item.id,
          'name': item.name,
          'trade': item.trade,
          'category': item.category,
          'system': item.system,
          'itemType': item.itemType,
          'variant': item.variant,
          'unit': item.unit,
          'aliases': item.aliases,
        },
    ],
  };
}

String _stringFromMap(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is String) return value;
  return '';
}

int _intFromMap(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is int) return value;
  if (value is num) return value.toInt();
  return 0;
}
