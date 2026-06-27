import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'maintainiac_firestore_schema.dart';
import 'maintainiac_firestore_upload_queue.dart';

enum MaintainiacHostedCacheStatus { hit, stale, miss }

class MaintainiacHostedCachePolicy {
  const MaintainiacHostedCachePolicy._();

  static const maxCachedDocumentBytes = 768 * 1024;
  static const maxCachedRecords = 400;
  static const defaultTtl = Duration(hours: 12);
  static const catalogPackTtl = Duration(days: 7);
  static const vendorRegistryTtl = Duration(days: 30);
  static const parserHealthTtl = Duration(minutes: 30);
  static const catalogHealthTtl = Duration(hours: 6);

  static const cacheableTopLevelCollections = <String>{
    MaintainiacFirestoreSchema.catalogPacks,
    MaintainiacFirestoreSchema.vendorRegistry,
    MaintainiacFirestoreSchema.parserHealth,
    MaintainiacFirestoreSchema.catalogHealth,
  };

  static Duration ttlForPath(String path) {
    final collection = _topLevelCollection(path);
    return switch (collection) {
      MaintainiacFirestoreSchema.catalogPacks => catalogPackTtl,
      MaintainiacFirestoreSchema.vendorRegistry => vendorRegistryTtl,
      MaintainiacFirestoreSchema.parserHealth => parserHealthTtl,
      MaintainiacFirestoreSchema.catalogHealth => catalogHealthTtl,
      _ => defaultTtl,
    };
  }

  static void validateCacheable({
    required String path,
    required Map<String, Object?> data,
  }) {
    _validatePath(path);
    _validateDocumentSize(path, data);
    _validateNoSensitiveKeys(data);
    _validateCatalogShape(path, data);
  }

  static void _validatePath(String path) {
    final clean = path.trim();
    if (clean.isEmpty ||
        clean.startsWith('/') ||
        clean.endsWith('/') ||
        clean.contains('//') ||
        clean.contains('..')) {
      throw ArgumentError.value(path, 'path', 'Unsafe hosted cache path.');
    }
    final parts = clean.split('/');
    if (parts.length.isOdd) {
      throw ArgumentError.value(path, 'path', 'Cache path must be a document.');
    }
    if (!cacheableTopLevelCollections.contains(parts.first)) {
      throw ArgumentError.value(
        path,
        'path',
        'This cache is only for shared hosted metadata, not private org data.',
      );
    }
  }

  static void _validateDocumentSize(String path, Map<String, Object?> data) {
    final bytes = utf8.encode(jsonEncode(data)).length;
    if (bytes > maxCachedDocumentBytes) {
      throw ArgumentError.value(
        bytes,
        path,
        'Hosted cache document is too large.',
      );
    }
  }

  static void _validateNoSensitiveKeys(Object? value, [String parent = '']) {
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        if (MaintainiacFirestoreUploadPolicy.blockedSensitiveKeys.contains(
          key,
        )) {
          throw ArgumentError.value(
            key,
            parent,
            'Sensitive field is not allowed in hosted cache.',
          );
        }
        _validateNoSensitiveKeys(entry.value, key);
      }
    } else if (value is Iterable) {
      for (final item in value) {
        _validateNoSensitiveKeys(item, parent);
      }
    }
  }

  static void _validateCatalogShape(String path, Map<String, Object?> data) {
    if (!path.startsWith('${MaintainiacFirestoreSchema.catalogPacks}/')) return;
    if (data['firestoreItemDocumentReadCount'] != null &&
        data['firestoreItemDocumentReadCount'] != 0) {
      throw ArgumentError.value(
        data['firestoreItemDocumentReadCount'],
        path,
        'Cached catalog metadata must not depend on item-document reads.',
      );
    }
    if (data['deliveryMode'] != null &&
        data['deliveryMode'] != 'manifest_storage_chunks') {
      throw ArgumentError.value(
        data['deliveryMode'],
        path,
        'Cached catalog metadata must point to Storage chunks.',
      );
    }
  }
}

class MaintainiacHostedCacheRecord {
  const MaintainiacHostedCacheRecord({
    required this.path,
    required this.data,
    required this.cachedAtUtc,
    required this.expiresAtUtc,
    required this.sha256,
    this.version,
  });

  factory MaintainiacHostedCacheRecord.fromStored(Object? value) {
    if (value is! Map) return MaintainiacHostedCacheRecord.empty;
    final data = value['data'];
    return MaintainiacHostedCacheRecord(
      path: value['path']?.toString() ?? '',
      data: data is Map ? Map<String, Object?>.from(data) : const {},
      cachedAtUtc:
          DateTime.tryParse(value['cachedAtUtc']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAtUtc:
          DateTime.tryParse(value['expiresAtUtc']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      sha256: value['sha256']?.toString() ?? '',
      version: _nullableString(value['version']),
    );
  }

  static final empty = MaintainiacHostedCacheRecord(
    path: '',
    data: const {},
    cachedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    expiresAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    sha256: '',
  );

  final String path;
  final Map<String, Object?> data;
  final DateTime cachedAtUtc;
  final DateTime expiresAtUtc;
  final String sha256;
  final String? version;

  bool get isEmpty => path.isEmpty || data.isEmpty || sha256.isEmpty;

  bool isFreshAt(DateTime nowUtc) => !isEmpty && nowUtc.isBefore(expiresAtUtc);

  bool matchesVersion(String? requestedVersion) {
    final wanted = requestedVersion?.trim();
    if (wanted == null || wanted.isEmpty) return true;
    return version == wanted;
  }

  Map<String, Object?> toMap() {
    return {
      'path': path,
      'data': data,
      'cachedAtUtc': cachedAtUtc.toUtc().toIso8601String(),
      'expiresAtUtc': expiresAtUtc.toUtc().toIso8601String(),
      'sha256': sha256,
      if (version != null) 'version': version,
    };
  }
}

class MaintainiacHostedCacheLookup {
  const MaintainiacHostedCacheLookup({required this.status, this.record});

  final MaintainiacHostedCacheStatus status;
  final MaintainiacHostedCacheRecord? record;

  bool get hasUsableRecord => record != null && !record!.isEmpty;
  bool get shouldFetchFromFirebase =>
      status != MaintainiacHostedCacheStatus.hit;
}

class MaintainiacHostedCacheStore {
  MaintainiacHostedCacheStore._(this._box);

  static const boxName = 'maintainiac_hosted_metadata_cache';

  final Box<dynamic> _box;

  static Future<MaintainiacHostedCacheStore> create() async {
    final box = await Hive.openBox<dynamic>(boxName);
    return MaintainiacHostedCacheStore._(box);
  }

  List<MaintainiacHostedCacheRecord> get records {
    final loaded = <MaintainiacHostedCacheRecord>[];
    for (final value in _box.values) {
      final record = MaintainiacHostedCacheRecord.fromStored(value);
      if (!record.isEmpty) loaded.add(record);
    }
    loaded.sort((a, b) => a.cachedAtUtc.compareTo(b.cachedAtUtc));
    return List.unmodifiable(loaded);
  }

  Future<MaintainiacHostedCacheRecord> put({
    required String path,
    required Map<String, Object?> data,
    DateTime? cachedAtUtc,
    Duration? ttl,
    String? version,
  }) async {
    MaintainiacHostedCachePolicy.validateCacheable(path: path, data: data);
    final cachedAt = (cachedAtUtc ?? DateTime.now().toUtc()).toUtc();
    final selectedTtl = ttl ?? MaintainiacHostedCachePolicy.ttlForPath(path);
    final record = MaintainiacHostedCacheRecord(
      path: path.trim(),
      data: Map<String, Object?>.unmodifiable(data),
      cachedAtUtc: cachedAt,
      expiresAtUtc: cachedAt.add(selectedTtl),
      sha256: _sha256For(data),
      version: _nullableString(version),
    );
    await _box.put(_keyFor(path), record.toMap());
    await _trimOldestIfNeeded();
    return record;
  }

  MaintainiacHostedCacheLookup lookup({
    required String path,
    DateTime? nowUtc,
    String? version,
    bool allowStale = true,
  }) {
    MaintainiacHostedCachePolicy.validateCacheable(
      path: path,
      data: const {'schema': 'cache_lookup_probe'},
    );
    final record = MaintainiacHostedCacheRecord.fromStored(
      _box.get(_keyFor(path)),
    );
    if (record.isEmpty || !record.matchesVersion(version)) {
      return const MaintainiacHostedCacheLookup(
        status: MaintainiacHostedCacheStatus.miss,
      );
    }
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    if (record.isFreshAt(now)) {
      return MaintainiacHostedCacheLookup(
        status: MaintainiacHostedCacheStatus.hit,
        record: record,
      );
    }
    return MaintainiacHostedCacheLookup(
      status: allowStale
          ? MaintainiacHostedCacheStatus.stale
          : MaintainiacHostedCacheStatus.miss,
      record: allowStale ? record : null,
    );
  }

  Future<void> invalidate(String path) => _box.delete(_keyFor(path));

  Future<void> clearExpired({DateTime? nowUtc}) async {
    final now = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    for (final record in records) {
      if (!record.isFreshAt(now)) {
        await _box.delete(_keyFor(record.path));
      }
    }
  }

  Future<void> clearAll() => _box.clear();

  Future<void> _trimOldestIfNeeded() async {
    final extraCount =
        records.length - MaintainiacHostedCachePolicy.maxCachedRecords;
    if (extraCount <= 0) return;
    for (final record in records.take(extraCount)) {
      await _box.delete(_keyFor(record.path));
    }
  }
}

String _topLevelCollection(String path) => path.trim().split('/').first;

String _keyFor(String path) {
  return path.trim().replaceAll(RegExp(r'[^A-Za-z0-9_.-]+'), '_');
}

String _sha256For(Map<String, Object?> data) {
  final encoded = utf8.encode(jsonEncode(_canonicalize(data)));
  return sha256.convert(encoded).toString();
}

Object? _canonicalize(Object? value) {
  if (value is Map) {
    final sortedKeys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in sortedKeys) key: _canonicalize(value[key])};
  }
  if (value is Iterable) {
    return [for (final item in value) _canonicalize(item)];
  }
  return value;
}

String? _nullableString(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return text;
}
