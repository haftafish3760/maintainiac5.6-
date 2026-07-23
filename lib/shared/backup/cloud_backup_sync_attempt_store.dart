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
    final attempts = _storedAttempts(key);
    return List.unmodifiable(
      attempts
          // A clock that moves backward must not make a recorded attempt
          // disappear and accidentally grant an extra local sync. Future
          // timestamps remain consumed until they age out naturally.
          .where((attempt) => !attempt.isBefore(cutoff))
          .toSet()
          .toList()
        ..sort(),
    );
  }

  Future<void> recordAttempt(String scope, {required DateTime at}) {
    return _enqueue(() async {
      final key = _validatedScope(scope);
      await _ensureStorage();
      final existing = _storedAttempts(key);
      final latest = existing.isEmpty
          ? null
          : existing.reduce(
              (current, value) => value.isAfter(current) ? value : current,
            );
      final requested = at.toUtc();
      final effective = latest != null && !requested.isAfter(latest)
          ? latest.add(const Duration(microseconds: 1))
          : requested;
      final cutoff = effective.subtract(const Duration(hours: 24));
      final next = [
        ...existing.where((value) => !value.isBefore(cutoff)),
        effective,
      ]..sort();
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
    if (!RegExp(r'^[A-Za-z0-9_.-]{1,256}$').hasMatch(scope)) {
      throw ArgumentError.value(scope, 'scope', 'requires a stable safe scope');
    }
    return scope;
  }

  List<DateTime> _storedAttempts(String key) {
    final values = _box?.get(key) ?? _memory[key] ?? const <DateTime>[];
    if (values is! Iterable) {
      throw StateError('Stored sync-attempt evidence is corrupt.');
    }
    final parsed = <DateTime>[];
    for (final value in values) {
      final timestamp = value is DateTime
          ? value.toUtc()
          : DateTime.tryParse(value.toString())?.toUtc();
      if (timestamp == null) {
        throw StateError('Stored sync-attempt evidence is corrupt.');
      }
      parsed.add(timestamp);
    }
    if (parsed.length > 100 || parsed.toSet().length != parsed.length) {
      throw StateError('Stored sync-attempt evidence is corrupt.');
    }
    return parsed;
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
