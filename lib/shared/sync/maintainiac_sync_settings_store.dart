import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_sync_settings.dart';

typedef MaintainiacSyncSettingsStorageCheck =
    Future<AppStorageCheck> Function();

class MaintainiacSyncSettingsStore {
  MaintainiacSyncSettingsStore._(
    this._box, {
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacSyncSettingsStore.memory({
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static Future<MaintainiacSyncSettingsStore> create(
    String boxName, {
    MaintainiacSyncSettingsStorageCheck? storageCheck,
  }) async => MaintainiacSyncSettingsStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacSyncSettingsStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacSyncSettings settingsFor(String module) {
    if (!_validModule(module)) return MaintainiacSyncSettings.disabled();
    final value = _box?.get(module) ?? _memory[module];
    if (value is! Map) return MaintainiacSyncSettings.disabled();
    try {
      return MaintainiacSyncSettings.fromMap(value);
    } on FormatException {
      return MaintainiacSyncSettings.disabled();
    }
  }

  Future<MaintainiacSyncSettings> save(
    String module,
    MaintainiacSyncSettings settings,
  ) => _enqueue(() async {
    if (!_validModule(module)) {
      throw ArgumentError.value(module, 'module', 'Invalid sync module.');
    }
    final check = await _storageCheck();
    if (!check.hasEnoughSpace) throw StateError(check.blockingMessage());
    final map = Map<String, Object?>.unmodifiable(settings.toMap());
    if (_box == null) {
      _memory[module] = map;
    } else {
      await _box.put(module, map);
    }
    return settingsFor(module);
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

bool _validModule(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{1,80}$').hasMatch(value);
