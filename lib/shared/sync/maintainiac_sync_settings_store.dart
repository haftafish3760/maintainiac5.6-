import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import '../records/maintainiac_hive_write_serialization.dart';
import 'maintainiac_sync_settings.dart';

typedef MaintainiacSyncSettingsStorageCheck =
    Future<AppStorageCheck> Function();

class MaintainiacSyncSettingsSnapshot {
  const MaintainiacSyncSettingsSnapshot({
    required this.settings,
    required this.updatedAtUtc,
    required this.revision,
  });

  factory MaintainiacSyncSettingsSnapshot.disabled() =>
      MaintainiacSyncSettingsSnapshot(
        settings: MaintainiacSyncSettings.disabled(),
        updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        revision: 0,
      );

  factory MaintainiacSyncSettingsSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final settingsMap = map['settings'];
    final updatedAt = DateTime.tryParse(map['updatedAtUtc']?.toString() ?? '');
    final revision = map['revision'];
    if (settingsMap is! Map ||
        updatedAt == null ||
        revision is! int ||
        revision < 1) {
      throw const FormatException('Sync settings snapshot is corrupt.');
    }
    return MaintainiacSyncSettingsSnapshot(
      settings: MaintainiacSyncSettings.fromMap(settingsMap),
      updatedAtUtc: updatedAt.toUtc(),
      revision: revision,
    );
  }

  final MaintainiacSyncSettings settings;
  final DateTime updatedAtUtc;
  final int revision;

  Map<String, Object?> toMap() => {
    'settings': settings.toMap(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
    'revision': revision,
  };
}

class MaintainiacSyncSettingsStore {
  MaintainiacSyncSettingsStore._(
    this._box, {
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacSyncSettingsStore.memory({
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static const boxName = 'maintainiac_sync_settings';

  static Future<MaintainiacSyncSettingsStore> create({
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) async => MaintainiacSyncSettingsStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacSyncSettingsStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacSyncSettings settingsFor(String module) =>
      snapshotFor(module).settings;

  MaintainiacSyncSettingsSnapshot snapshotFor(String module) {
    if (!_validModule(module)) {
      return MaintainiacSyncSettingsSnapshot.disabled();
    }
    final value = _box?.get(module) ?? _memory[module];
    if (value is! Map) {
      return MaintainiacSyncSettingsSnapshot.disabled();
    }
    try {
      return MaintainiacSyncSettingsSnapshot.fromMap(value);
    } on FormatException {
      try {
        return MaintainiacSyncSettingsSnapshot(
          settings: MaintainiacSyncSettings.fromMap(value),
          updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
          revision: 0,
        );
      } on FormatException {
        return MaintainiacSyncSettingsSnapshot.disabled();
      }
    }
  }

  Future<MaintainiacSyncSettings> save(
    String module,
    MaintainiacSyncSettings settings, {
    DateTime? nowUtc,
  }) => _enqueue(() async {
    if (!_validModule(module)) {
      throw ArgumentError.value(module, 'module', 'Invalid sync module.');
    }
    final check = await _storageCheck();
    if (!check.hasEnoughSpace) throw StateError(check.blockingMessage());
    final previous = snapshotFor(module);
    final requested = (nowUtc ?? DateTime.now()).toUtc();
    final updatedAt = requested.isAfter(previous.updatedAtUtc)
        ? requested
        : previous.updatedAtUtc.add(const Duration(microseconds: 1));
    final snapshot = MaintainiacSyncSettingsSnapshot(
      settings: settings,
      updatedAtUtc: updatedAt,
      revision: previous.revision + 1,
    );
    final map = Map<String, Object?>.unmodifiable(snapshot.toMap());
    if (_box == null) {
      _memory[module] = map;
    } else {
      await _box.put(module, map);
    }
    return settingsFor(module);
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final box = _box;
    if (box != null) {
      return MaintainiacHiveWriteSerialization.enqueue(box.name, operation);
    }
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

bool _validModule(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(value);
