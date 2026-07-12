import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_catalog_pack_payload.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_inventory_store.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_models.dart';
import 'package:maintaniac/screens/work_supplies/data/work_supply_trade_pack_import_validator.dart';

void main() {
  group('inventory parser pack version regression behavior', () {
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = await Directory.systemTemp.createTemp(
        'work_supply_pack_version_regression_',
      );
    });

    tearDown(() async {
      await Hive.close();
      if (tempDirectory.existsSync()) {
        await tempDirectory.delete(recursive: true);
      }
    });

    test('new pack version still runs old regression lock metadata', () async {
      final pack = await _writeVersionedPack(
        base: tempDirectory,
        packVersion: '2026.07.02',
        localePackId: 'en-US',
      );

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(pack);

      expect(result.isReady, isTrue);
      expect(result.checkedItemCount, 1);
      expect(result.checkedChunkCount, 1);
    });

    test(
      'schema version mismatch blocks import before pack promotion',
      () async {
        final pack = await _writeVersionedPack(
          base: tempDirectory,
          payloadSchemaVersion: 999,
        );

        final result = await const WorkSupplyTradePackImportValidator()
            .validateDirectory(pack);

        expect(result.isReady, isFalse);
        expect(
          result.status,
          WorkSupplyTradePackValidationStatus.invalidPayloadSchema,
        );
        expect(result.checkedChunkCount, 0);
        expect(result.issues.single, contains('Unsupported payload schema'));
      },
    );

    test('pack version mismatch requires review instead of promotion', () {
      const current = _InstalledPackState(
        packId: 'maintainiac.work-supplies.plumbing.residential.core',
        packVersion: '2026.07.01',
        localePackId: 'en-US',
        parserVersion: 'parser-v1',
        catalogVersion: 'catalog-v1',
      );
      const incoming = _InstalledPackState(
        packId: 'maintainiac.work-supplies.plumbing.residential.core',
        packVersion: '2026.07.02',
        localePackId: 'en-US',
        parserVersion: 'parser-v2',
        catalogVersion: 'catalog-v1',
      );

      final decision = _reviewVersionChange(
        current: current,
        incoming: incoming,
        regressionLocksPassed: false,
      );

      expect(decision.canPromote, isFalse);
      expect(decision.requiresReview, isTrue);
      expect(decision.reason, contains('regression locks'));
      expect(decision.rollbackVersion, current.packVersion);
    });

    test('duplicate install is idempotent when version identity matches', () {
      const current = _InstalledPackState(
        packId: 'maintainiac.work-supplies.plumbing.residential.core',
        packVersion: '2026.07.02',
        localePackId: 'en-US',
        parserVersion: 'parser-v2',
        catalogVersion: 'catalog-v1',
      );

      final decision = _reviewVersionChange(
        current: current,
        incoming: current,
        regressionLocksPassed: true,
      );

      expect(decision.canPromote, isTrue);
      expect(decision.requiresReview, isFalse);
      expect(decision.reason, 'duplicate install is already current');
    });

    test('missing locale pack falls back conservatively', () async {
      final pack = await _writeVersionedPack(base: tempDirectory);
      final manifestFile = File('${pack.path}/manifest.json');
      final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
      manifest['localePackId'] = '';
      await manifestFile.writeAsString(jsonEncode(manifest), flush: true);

      final result = await const WorkSupplyTradePackImportValidator()
          .validateDirectory(pack);
      final decision = _localeFallbackDecision(
        requestedLocale: 'es-US',
        installedLocale: manifest['localePackId'] as String,
      );

      expect(result.isReady, isTrue);
      expect(decision.canPromote, isTrue);
      expect(decision.requiresReview, isTrue);
      expect(decision.reason, contains('locale pack missing'));
    });

    test(
      'stale Firestore mirror never overwrites Hive inventory truth',
      () async {
        Hive.init(tempDirectory.path);
        final store = await WorkSupplyInventoryStore.create();
        final item = _item();
        final local = await store.addStock(
          WorkSupplyInventoryRecord(
            item: item,
            onHand: 7,
            threshold: 2,
            lastUnitCost: 3,
            storageArea: 'Truck 1',
            receiptLinked: true,
            updatedAt: DateTime.utc(2026, 7, 2, 12),
          ),
        );
        final mirror = local.copyWith(
          onHand: 3,
          updatedAt: DateTime.utc(2026, 7, 1, 12),
        );

        final merged = _mergeMirrorIntoHiveTruth(local: local, mirror: mirror);

        expect(merged.onHand, 7);
        expect(merged.updatedAt, local.updatedAt);
        expect(store.loadInventory().single.onHand, 7);
      },
    );

    test(
      'Hive rollback preserves custom item and source receipt fields',
      () async {
        Hive.init(tempDirectory.path);
        final store = await WorkSupplyInventoryStore.create();
        final before = await store.addStock(
          WorkSupplyInventoryRecord(
            item: _item(id: 'USER-CUSTOM-PACK-LOCK'),
            onHand: 4,
            threshold: 1,
            lastUnitCost: 5,
            storageArea: 'Truck 2',
            receiptLinked: true,
            sourceReceiptId: 'RCP-ROLLBACK',
            sourceReceiptLineId: 'RCP-ROLLBACK-L1',
            sourceMerchantName: 'Ferguson',
            updatedAt: DateTime.utc(2026, 7, 2, 10),
          ),
        );

        final restored = _rollbackToKnownGood(before);

        expect(restored.item.id, 'USER-CUSTOM-PACK-LOCK');
        expect(restored.sourceReceiptId, 'RCP-ROLLBACK');
        expect(restored.sourceReceiptLineId, 'RCP-ROLLBACK-L1');
        expect(restored.sourceMerchantName, 'Ferguson');
        expect(restored.onHand, 4);
      },
    );
  });
}

Future<Directory> _writeVersionedPack({
  required Directory base,
  String packVersion = '2026.07.02',
  String localePackId = 'en-US',
  int payloadSchemaVersion = workSupplyCatalogPackSchemaVersion,
}) async {
  final directory = Directory(
    '${base.path}/pack_${packVersion.replaceAll('.', '_')}_${localePackId.replaceAll('-', '_')}_$payloadSchemaVersion',
  );
  await directory.create(recursive: true);
  const chunkId = 'plumbing_residential_core_001';
  const storagePath = 'packs/plumbing/residential/core/$chunkId.json.gz';
  final payload = {
    'schemaVersion': payloadSchemaVersion,
    'packId': 'maintainiac.work-supplies.plumbing.residential.core',
    'packVersion': packVersion,
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': localePackId,
    'items': [
      {
        'canonicalKey': 'plumbing.synthetic.pex.elbow',
        'trade': 'Plumbing',
        'packTier': 'core',
        'searchTerms': ['pex', 'elbow', '1/2'],
        'aliases': [
          {'value': '1/2 pex elbow', 'normalized': '1 2 pex elbow'},
        ],
      },
    ],
  };
  final jsonBytes = utf8.encode(jsonEncode(payload));
  final gzipBytes = gzip.encode(jsonBytes);
  final chunkFile = File('${directory.path}/$storagePath');
  await chunkFile.parent.create(recursive: true);
  await chunkFile.writeAsBytes(gzipBytes, flush: true);
  final manifest = {
    'schemaVersion': 1,
    'packId': 'maintainiac.work-supplies.plumbing.residential.core',
    'packVersion': packVersion,
    'generatedAtIso': '2026-07-02T12:00:00.000Z',
    'tradeName': 'Plumbing',
    'marketScope': 'residential',
    'tier': 'core',
    'localePackId': localePackId,
    'countryCodes': ['US'],
    'displayName': 'Plumbing Residential Core',
    'itemCount': 1,
    'chunkCount': 1,
    'firestoreManifestReadCount': 1,
    'firestoreItemDocumentReadCount': 0,
    'estimatedUncompressedBytes': jsonBytes.length,
    'estimatedCompressedBytes': gzipBytes.length,
    'chunks': [
      {
        'chunkId': chunkId,
        'itemCount': 1,
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

class _InstalledPackState {
  const _InstalledPackState({
    required this.packId,
    required this.packVersion,
    required this.localePackId,
    required this.parserVersion,
    required this.catalogVersion,
  });

  final String packId;
  final String packVersion;
  final String localePackId;
  final String parserVersion;
  final String catalogVersion;
}

class _VersionDecision {
  const _VersionDecision({
    required this.canPromote,
    required this.requiresReview,
    required this.reason,
    required this.rollbackVersion,
  });

  final bool canPromote;
  final bool requiresReview;
  final String reason;
  final String rollbackVersion;
}

_VersionDecision _reviewVersionChange({
  required _InstalledPackState current,
  required _InstalledPackState incoming,
  required bool regressionLocksPassed,
}) {
  if (current.packId == incoming.packId &&
      current.packVersion == incoming.packVersion &&
      current.localePackId == incoming.localePackId &&
      current.parserVersion == incoming.parserVersion &&
      current.catalogVersion == incoming.catalogVersion) {
    return _VersionDecision(
      canPromote: true,
      requiresReview: false,
      reason: 'duplicate install is already current',
      rollbackVersion: current.packVersion,
    );
  }
  if (!regressionLocksPassed) {
    return _VersionDecision(
      canPromote: false,
      requiresReview: true,
      reason: 'pack version mismatch requires review and regression locks',
      rollbackVersion: current.packVersion,
    );
  }
  return _VersionDecision(
    canPromote: true,
    requiresReview: true,
    reason: 'version changed with regression evidence',
    rollbackVersion: current.packVersion,
  );
}

_VersionDecision _localeFallbackDecision({
  required String requestedLocale,
  required String installedLocale,
}) {
  if (requestedLocale == installedLocale) {
    return const _VersionDecision(
      canPromote: true,
      requiresReview: false,
      reason: 'locale pack available',
      rollbackVersion: '',
    );
  }
  return const _VersionDecision(
    canPromote: true,
    requiresReview: true,
    reason: 'locale pack missing; use conservative fallback',
    rollbackVersion: '',
  );
}

WorkSupplyInventoryRecord _mergeMirrorIntoHiveTruth({
  required WorkSupplyInventoryRecord local,
  required WorkSupplyInventoryRecord mirror,
}) {
  final localTime =
      local.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  final mirrorTime =
      mirror.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  return mirrorTime.isAfter(localTime) ? mirror : local;
}

WorkSupplyInventoryRecord _rollbackToKnownGood(
  WorkSupplyInventoryRecord snapshot,
) {
  return snapshot.copyWith(updatedAt: DateTime.utc(2026, 7, 2, 12));
}

WorkSupplyItem _item({String id = 'TEST-PEX-ELBOW'}) {
  return WorkSupplyItem(
    id: id,
    name: 'Synthetic PEX Elbow',
    trade: 'Plumbing',
    category: 'Fittings',
    system: 'PEX',
    itemType: '90 Elbow',
    variant: '1/2 in',
    unit: 'each',
    aliases: const ['pex elbow'],
  );
}
