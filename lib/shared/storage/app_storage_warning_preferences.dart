import 'package:hive/hive.dart';

import 'app_storage_guard.dart';

enum AppStorageWarningPreference { always, below500Mb, never }

class AppStorageWarningSnapshot {
  const AppStorageWarningSnapshot({
    required this.preference,
    required this.revision,
    required this.updatedAtUtc,
  });

  factory AppStorageWarningSnapshot.defaults() => AppStorageWarningSnapshot(
    preference: AppStorageWarningPreference.always,
    revision: 0,
    updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );

  factory AppStorageWarningSnapshot.fromMap(Map<dynamic, dynamic> map) {
    final preferences = AppStorageWarningPreference.values.where(
      (value) => value.name == map['preference'],
    );
    final revision = map['revision'];
    final updatedAt = DateTime.tryParse(map['updatedAtUtc']?.toString() ?? '');
    if (preferences.length != 1 ||
        revision is! int ||
        revision < 1 ||
        updatedAt == null) {
      throw const FormatException('Storage warning preference is corrupt.');
    }
    return AppStorageWarningSnapshot(
      preference: preferences.single,
      revision: revision,
      updatedAtUtc: updatedAt.toUtc(),
    );
  }

  final AppStorageWarningPreference preference;
  final int revision;
  final DateTime updatedAtUtc;

  bool shouldShow(AppStorageLevel level) => switch (preference) {
    AppStorageWarningPreference.always =>
      level == AppStorageLevel.yellow ||
          level == AppStorageLevel.orange ||
          level == AppStorageLevel.red,
    AppStorageWarningPreference.below500Mb =>
      level == AppStorageLevel.orange || level == AppStorageLevel.red,
    AppStorageWarningPreference.never => false,
  };

  Map<String, Object?> toMap() => {
    'preference': preference.name,
    'revision': revision,
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
  };
}

typedef AppStorageWarningStorageCheck = Future<AppStorageCheck> Function();

class AppStorageWarningPreferenceStore {
  AppStorageWarningPreferenceStore._(
    this._box, {
    AppStorageWarningStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  AppStorageWarningPreferenceStore.memory({
    AppStorageWarningStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static const boxName = 'maintainiac_storage_warning_preferences';
  static const _key = 'device';

  static Future<AppStorageWarningPreferenceStore> create({
    AppStorageWarningStorageCheck? storageCheck,
  }) async => AppStorageWarningPreferenceStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final AppStorageWarningStorageCheck _storageCheck;
  Map<String, Object?>? _memory;
  Future<void> _writeTail = Future<void>.value();

  AppStorageWarningSnapshot get snapshot {
    final value = _box?.get(_key) ?? _memory;
    if (value is! Map) return AppStorageWarningSnapshot.defaults();
    try {
      return AppStorageWarningSnapshot.fromMap(value);
    } on FormatException {
      return AppStorageWarningSnapshot.defaults();
    }
  }

  Future<AppStorageWarningSnapshot> save(
    AppStorageWarningPreference preference, {
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final check = await _storageCheck();
    if (!check.hasEnoughSpace) throw StateError(check.blockingMessage());
    final previous = snapshot;
    final requested = (nowUtc ?? DateTime.now()).toUtc();
    final updatedAt = requested.isAfter(previous.updatedAtUtc)
        ? requested
        : previous.updatedAtUtc.add(const Duration(microseconds: 1));
    final updated = AppStorageWarningSnapshot(
      preference: preference,
      revision: previous.revision + 1,
      updatedAtUtc: updatedAt,
    );
    final map = Map<String, Object?>.unmodifiable(updated.toMap());
    if (_box == null) {
      _memory = map;
    } else {
      await _box.put(_key, map);
    }
    return updated;
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}
