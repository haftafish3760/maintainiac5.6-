import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:maintaniac/shared/firebase/maintainiac_firestore_schema.dart';
import 'package:maintaniac/shared/firebase/maintainiac_hosted_cache.dart';

void main() {
  late Directory hiveDirectory;

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('hosted_cache_test_');
    Hive.init(hiveDirectory.path);
  });

  tearDown(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  test('caches hosted catalog manifests with long TTL and sha256', () async {
    final store = await MaintainiacHostedCacheStore.create();
    const path = 'catalogPacks/work_supply_residential_core/manifests/2026.06';
    const version = '2026.06';

    final record = await store.put(
      path: path,
      data: _safeCatalogManifestData(version),
      cachedAtUtc: DateTime.utc(2026, 6, 23, 13),
      version: version,
    );
    final lookup = store.lookup(
      path: path,
      nowUtc: DateTime.utc(2026, 6, 24, 13),
      version: version,
    );

    expect(record.sha256, matches(RegExp(r'^[a-f0-9]{64}$')));
    expect(record.expiresAtUtc, DateTime.utc(2026, 6, 30, 13));
    expect(lookup.status, MaintainiacHostedCacheStatus.hit);
    expect(lookup.shouldFetchFromFirebase, isFalse);
    expect(lookup.record!.sha256, record.sha256);
  });

  test(
    'returns stale records as usable while signaling refresh needed',
    () async {
      final store = await MaintainiacHostedCacheStore.create();
      final path = 'parserHealth/receipt_parser_v1';

      await store.put(
        path: path,
        data: const {
          'schema': 'parser_health_snapshot_v1',
          'healthLabel': 'healthy',
          'totalEventCount': 42,
        },
        cachedAtUtc: DateTime.utc(2026, 6, 23, 13),
      );

      final lookup = store.lookup(
        path: path,
        nowUtc: DateTime.utc(2026, 6, 23, 14),
      );

      expect(lookup.status, MaintainiacHostedCacheStatus.stale);
      expect(lookup.hasUsableRecord, isTrue);
      expect(lookup.shouldFetchFromFirebase, isTrue);
      expect(lookup.record!.data['healthLabel'], 'healthy');
    },
  );

  test('can treat stale records as misses for strict reads', () async {
    final store = await MaintainiacHostedCacheStore.create();
    const path = 'catalogHealth/pack_health';
    await store.put(
      path: path,
      data: const {
        'schema': 'catalog_health_event_v1',
        'event': 'catalogpackready',
      },
      cachedAtUtc: DateTime.utc(2026, 6, 1),
    );

    final lookup = store.lookup(
      path: path,
      nowUtc: DateTime.utc(2026, 6, 23),
      allowStale: false,
    );

    expect(lookup.status, MaintainiacHostedCacheStatus.miss);
    expect(lookup.hasUsableRecord, isFalse);
  });

  test('version mismatch forces a cache miss', () async {
    final store = await MaintainiacHostedCacheStore.create();
    const path = 'catalogPacks/work_supply_residential_core';
    await store.put(
      path: path,
      data: _safeCatalogPackData(),
      cachedAtUtc: DateTime.utc(2026, 6, 23, 13),
      version: '2026.06.old',
    );

    final lookup = store.lookup(
      path: path,
      nowUtc: DateTime.utc(2026, 6, 23, 14),
      version: '2026.06',
    );

    expect(lookup.status, MaintainiacHostedCacheStatus.miss);
  });

  test(
    'rejects private org data, receipt fields, and bad catalog shape',
    () async {
      final store = await MaintainiacHostedCacheStore.create();

      await expectLater(
        store.put(
          path: 'orgs/ORG-1/expenses/EXP-1',
          data: const {'schema': 'private_expense'},
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.put(
          path: 'parserHealth/receipt_parser_v1',
          data: const {
            'schema': 'parser_health_snapshot_v1',
            'rawReceiptText': 'PRIVATE STORE 99.99',
          },
        ),
        throwsArgumentError,
      );
      await expectLater(
        store.put(
          path: 'catalogPacks/bad_pack',
          data: const {
            'schema': 'catalog_pack_v1',
            'deliveryMode': 'item_documents',
            'firestoreItemDocumentReadCount': 12000,
          },
        ),
        throwsArgumentError,
      );
    },
  );

  test('clears expired records and keeps fresh records', () async {
    final store = await MaintainiacHostedCacheStore.create();
    await store.put(
      path: 'parserHealth/receipt_parser_v1',
      data: const {'schema': 'parser_health_snapshot_v1'},
      cachedAtUtc: DateTime.utc(2026, 6, 23, 13),
    );
    await store.put(
      path: '${MaintainiacFirestoreSchema.vendorRegistry}/shell',
      data: const {'schema': 'vendor_profile_v1', 'vendorId': 'shell'},
      cachedAtUtc: DateTime.utc(2026, 6, 23, 13),
    );

    await store.clearExpired(nowUtc: DateTime.utc(2026, 6, 24, 13));

    expect(
      store.lookup(path: 'parserHealth/receipt_parser_v1').status,
      MaintainiacHostedCacheStatus.miss,
    );
    expect(
      store
          .lookup(path: '${MaintainiacFirestoreSchema.vendorRegistry}/shell')
          .status,
      MaintainiacHostedCacheStatus.hit,
    );
  });

  test('sha256 fingerprint is stable regardless of map key order', () async {
    final store = await MaintainiacHostedCacheStore.create();
    final first = await store.put(
      path: 'catalogHealth/health_a',
      data: const {
        'schema': 'catalog_health_event_v1',
        'event': 'catalogpackready',
        'chunkCount': 4,
      },
      cachedAtUtc: DateTime.utc(2026, 6, 23),
    );
    final second = await store.put(
      path: 'catalogHealth/health_b',
      data: const {
        'chunkCount': 4,
        'event': 'catalogpackready',
        'schema': 'catalog_health_event_v1',
      },
      cachedAtUtc: DateTime.utc(2026, 6, 23),
    );

    expect(first.sha256, second.sha256);
  });

  test('treats a tampered persisted cache value as a cache miss', () async {
    final store = await MaintainiacHostedCacheStore.create();
    const path = 'vendorRegistry/tampered_vendor';
    await Hive.box<dynamic>(MaintainiacHostedCacheStore.boxName).put(
      'vendorRegistry_tampered_vendor',
      {
        'path': path,
        'data': const {'schema': 'vendor_profile_v1', 'vendorId': 'tampered'},
        'cachedAtUtc': '2026-07-16T12:00:00.000Z',
        'expiresAtUtc': '2026-08-16T12:00:00.000Z',
        'sha256':
            '0000000000000000000000000000000000000000000000000000000000000000',
      },
    );

    expect(
      store.lookup(path: path, nowUtc: DateTime.utc(2026, 7, 17)).status,
      MaintainiacHostedCacheStatus.miss,
    );
    expect(store.records, isEmpty);
  });
}

Map<String, Object?> _safeCatalogPackData() {
  return const {
    'schema': 'catalog_pack_v1',
    'packId': 'work_supply_residential_core',
    'packVersion': '2026.06',
    'deliveryMode': 'manifest_storage_chunks',
    'firestoreItemDocumentReadCount': 0,
    'storagePrefix': 'catalog-packs/work-supplies/2026.06',
  };
}

Map<String, Object?> _safeCatalogManifestData(String version) {
  return {
    'schema': 'catalog_manifest_v1',
    'packId': 'work_supply_residential_core',
    'packVersion': version,
    'deliveryMode': 'manifest_storage_chunks',
    'firestoreItemDocumentReadCount': 0,
    'chunks': const [
      {
        'chunkId': 'core-a',
        'storagePath': 'catalog-packs/work-supplies/2026.06/core-a.json',
        'sha256':
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      },
    ],
  };
}
