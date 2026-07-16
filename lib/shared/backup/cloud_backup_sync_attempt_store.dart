import 'package:hive_flutter/hive_flutter.dart';

import '../storage/app_storage_guard.dart';

typedef CloudBackupSyncAttemptStorageCheck = Future<AppStorageCheck> Function();

/// Device-local evidence of user-authorized backup attempts. It is advisory:
/// the server remains authoritative for account-wide limits across devices.
class CloudBackupSyncAttemptStore {
  CloudBackupSyncAttemptStore._(this._box, this._storageCheck);

  static const boxName = 'cloud_backup_sync_attempts_v1';

  final Box<dynamic>? _box;
  final CloudBackupSyncAttemptStorageCheck? _storageCheck;
  final _memory = <String, List<DateTime>>{};
  Future<void> _writeTail = Future<void>.value();

  static Future<CloudBackupSyncAttemptStore> create({
    CloudBackupSyncAttemptStorageCheck? storageCheck,
  }) async {
    return CloudBackupSyncAttemptStore._(
      await Hive.openBox<dynamic>(boxName),
      storageCheck ?? _defaultStorageCheck,
    );
  }

  CloudBackupSyncAttemptStore.memory({
    CloudBackupSyncAttemptStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck;

  List<DateTime> attemptsFor(String scope, {required DateTime now}) {
    final key = _validatedScope(scope);
    final cutoff = now.toUtc().subtract(const Duration(hours: 24));
    final values = _box?.get(key) ?? _memory[key] ?? const <DateTime>[];
    final attempts = values is List
        ? values
              .map((value) => DateTime.tryParse(value.toString())?.toUtc())
              .whereType<DateTime>()
        : values is Iterable<DateTime>
        ? values
        : const Iterable<DateTime>.empty();
    return List.unmodifiable(
      attempts
          .where(
            (attempt) =>
                !attempt.isBefore(cutoff) && !attempt.isAfter(now.toUtc()),
          )
          .toSet()
          .toList()
        ..sort(),
    );
  }

  Future<void> recordAttempt(String scope, {required DateTime at}) {
    return _enqueue(() async {
      final key = _validatedScope(scope);
      await _ensureStorage();
      final next = [...attemptsFor(key, now: at), at.toUtc()]..sort();
      final stored = next
          .map((value) => value.toIso8601String())
          .toSet()
          .toList();
      if (_box == null) {
        _memory[key] = next;
      } else {
        await _box.put(key, stored);
      }
    });
  }

  static String _validatedScope(String scope) {
    final clean = scope.trim();
    if (clean.isEmpty || clean != scope || clean.contains(':')) {
      throw ArgumentError.value(scope, 'scope', 'requires a stable safe scope');
    }
    return clean;
  }

  Future<void> _ensureStorage() async {
    final check = _storageCheck;
    if (check == null) return;
    final result = await check();
    if (!result.hasEnoughSpace) throw StateError(result.blockingMessage());
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (error, _) {});
    return result;
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}
