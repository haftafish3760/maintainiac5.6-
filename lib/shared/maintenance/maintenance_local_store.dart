import 'dart:async';

import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';

typedef MaintenanceStorageCheck = Future<AppStorageCheck> Function();

class MaintenanceLocalSnapshot {
  const MaintenanceLocalSnapshot({
    required this.schemaVersion,
    required this.records,
    required this.events,
    required this.updatedAt,
  });

  static const currentSchemaVersion = 1;

  factory MaintenanceLocalSnapshot.empty() => MaintenanceLocalSnapshot(
    schemaVersion: currentSchemaVersion,
    records: const [],
    events: const [],
    updatedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  factory MaintenanceLocalSnapshot.fromMap(Map<dynamic, dynamic> source) {
    final schemaVersion = _safeInt(source['schemaVersion']);
    if (schemaVersion < 1 || schemaVersion > currentSchemaVersion) {
      throw const FormatException('Unsupported maintenance schema version.');
    }
    final records = _mapList(source['records']);
    final events = _mapList(source['events']);
    final updatedAt = DateTime.tryParse(
      '${source['updatedAt'] ?? ''}',
    )?.toUtc();
    if (updatedAt == null) {
      throw const FormatException('Maintenance snapshot timestamp is invalid.');
    }
    return MaintenanceLocalSnapshot(
      schemaVersion: schemaVersion,
      records: records,
      events: events,
      updatedAt: updatedAt,
    );
  }

  final int schemaVersion;
  final List<Map<String, Object?>> records;
  final List<Map<String, Object?>> events;
  final DateTime updatedAt;

  Map<String, Object?> toMap() => {
    'schemaVersion': schemaVersion,
    'records': [
      for (final record in records) Map<String, Object?>.from(record),
    ],
    'events': [for (final event in events) Map<String, Object?>.from(event)],
    'updatedAt': updatedAt.toUtc().toIso8601String(),
  };
}

class MaintenanceLocalReadResult {
  const MaintenanceLocalReadResult({
    required this.snapshot,
    required this.recoveredFromBackup,
    required this.primaryWasInvalid,
  });

  final MaintenanceLocalSnapshot snapshot;
  final bool recoveredFromBackup;
  final bool primaryWasInvalid;
}

/// Serialized local truth for finalized maintenance records and service events.
///
/// The store uses a last-known-good backup slot. A valid primary snapshot is
/// copied to backup before replacement, allowing recovery from a malformed or
/// partially migrated primary value. It has no cloud or parser dependency.
class MaintenanceLocalStore {
  MaintenanceLocalStore({
    required Box<dynamic> box,
    MaintenanceStorageCheck? storageCheck,
  }) : _box = box,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static const boxName = 'maintainiac_maintenance_records';
  static const primaryKey = 'snapshot';
  static const backupKey = 'snapshot_backup';

  final Box<dynamic> _box;
  final MaintenanceStorageCheck _storageCheck;
  Future<void> _writeTail = Future<void>.value();

  static Future<MaintenanceLocalStore> create({
    MaintenanceStorageCheck? storageCheck,
  }) async {
    return MaintenanceLocalStore(
      box: await Hive.openBox<dynamic>(boxName),
      storageCheck: storageCheck,
    );
  }

  Future<MaintenanceLocalReadResult> read() async {
    final primary = _decode(_box.get(primaryKey));
    if (primary != null) {
      return MaintenanceLocalReadResult(
        snapshot: primary,
        recoveredFromBackup: false,
        primaryWasInvalid: false,
      );
    }
    final hadPrimary = _box.containsKey(primaryKey);
    final backup = _decode(_box.get(backupKey));
    if (backup != null) {
      return MaintenanceLocalReadResult(
        snapshot: backup,
        recoveredFromBackup: true,
        primaryWasInvalid: hadPrimary,
      );
    }
    return MaintenanceLocalReadResult(
      snapshot: MaintenanceLocalSnapshot.empty(),
      recoveredFromBackup: false,
      primaryWasInvalid: hadPrimary,
    );
  }

  Future<void> write(MaintenanceLocalSnapshot snapshot) {
    if (snapshot.schemaVersion !=
        MaintenanceLocalSnapshot.currentSchemaVersion) {
      throw ArgumentError.value(
        snapshot.schemaVersion,
        'snapshot.schemaVersion',
        'must be the current maintenance schema version',
      );
    }
    return _enqueue(() async {
      final storage = await _storageCheck();
      if (!storage.hasEnoughSpace) {
        throw StateError(storage.blockingMessage());
      }
      final primary = _decode(_box.get(primaryKey));
      if (primary != null) {
        await _box.put(backupKey, primary.toMap());
      }
      await _box.put(primaryKey, snapshot.toMap());
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _writeTail;
    final release = Completer<void>();
    _writeTail = release.future;
    return previous.then((_) async {
      try {
        return await operation();
      } finally {
        release.complete();
      }
    });
  }

  MaintenanceLocalSnapshot? _decode(Object? value) {
    if (value is! Map) return null;
    try {
      return MaintenanceLocalSnapshot.fromMap(value);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

List<Map<String, Object?>> _mapList(Object? source) {
  if (source is! List) {
    throw const FormatException('Maintenance snapshot list is invalid.');
  }
  return [
    for (final item in source)
      if (item is Map)
        Map<String, Object?>.from(item)
      else
        throw const FormatException('Maintenance snapshot item is invalid.'),
  ];
}

int _safeInt(Object? value) {
  if (value is int) return value;
  return int.tryParse('$value') ?? 0;
}
