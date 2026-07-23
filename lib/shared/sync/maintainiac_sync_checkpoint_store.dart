import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import '../records/maintainiac_hive_write_serialization.dart';
import 'maintainiac_sync_settings.dart';

enum MaintainiacSyncAttemptState { idle, running, succeeded, failed, cancelled }

typedef MaintainiacSyncCheckpointStorageCheck =
    Future<AppStorageCheck> Function();

class MaintainiacSyncCheckpoint {
  const MaintainiacSyncCheckpoint({
    required this.module,
    required this.state,
    required this.revision,
    this.activeAttemptId,
    this.trigger,
    this.lastAttemptAtUtc,
    this.lastSuccessfulAtUtc,
    this.updatedAtUtc,
    this.reservationId,
    this.lastError,
  });

  factory MaintainiacSyncCheckpoint.idle(String module) =>
      MaintainiacSyncCheckpoint(
        module: module,
        state: MaintainiacSyncAttemptState.idle,
        revision: 0,
      );

  factory MaintainiacSyncCheckpoint.fromMap(Map<dynamic, dynamic> map) {
    final module = map['module'];
    final state = MaintainiacSyncAttemptState.values.where(
      (value) => value.name == map['state'],
    );
    final triggerName = map['trigger'];
    final trigger = triggerName == null
        ? const <MaintainiacSyncTrigger>[]
        : MaintainiacSyncTrigger.values.where(
            (value) => value.name == triggerName,
          );
    final checkpoint = MaintainiacSyncCheckpoint(
      module: module is String ? module : '',
      state: state.length == 1
          ? state.single
          : MaintainiacSyncAttemptState.idle,
      revision: map['revision'] is int ? map['revision'] as int : -1,
      activeAttemptId: _optionalString(map, 'activeAttemptId'),
      trigger: trigger.length == 1 ? trigger.single : null,
      lastAttemptAtUtc: _optionalDate(map, 'lastAttemptAtUtc'),
      lastSuccessfulAtUtc: _optionalDate(map, 'lastSuccessfulAtUtc'),
      updatedAtUtc: _optionalDate(map, 'updatedAtUtc'),
      reservationId: _optionalString(map, 'reservationId'),
      lastError: _optionalString(map, 'lastError'),
    );
    checkpoint.validate();
    return checkpoint;
  }

  final String module;
  final MaintainiacSyncAttemptState state;
  final int revision;
  final String? activeAttemptId;
  final MaintainiacSyncTrigger? trigger;
  final DateTime? lastAttemptAtUtc;
  final DateTime? lastSuccessfulAtUtc;
  final DateTime? updatedAtUtc;
  final String? reservationId;
  final String? lastError;

  void validate() {
    final idle = state == MaintainiacSyncAttemptState.idle;
    final attempted = state != MaintainiacSyncAttemptState.idle;
    if (!_validToken(module, 80) ||
        revision < 0 ||
        (idle &&
            (revision != 0 ||
                activeAttemptId != null ||
                trigger != null ||
                lastAttemptAtUtc != null ||
                lastSuccessfulAtUtc != null ||
                updatedAtUtc != null ||
                reservationId != null ||
                lastError != null)) ||
        (attempted &&
            (revision < 1 ||
                trigger == null ||
                lastAttemptAtUtc == null ||
                updatedAtUtc == null)) ||
        (state == MaintainiacSyncAttemptState.running) !=
            (activeAttemptId != null) ||
        (activeAttemptId != null && !_validToken(activeAttemptId!, 160)) ||
        (reservationId != null && !_validToken(reservationId!, 160)) ||
        (lastError != null &&
            (lastError!.trim().isEmpty || lastError!.length > 500)) ||
        (lastAttemptAtUtc != null &&
            updatedAtUtc != null &&
            updatedAtUtc!.isBefore(lastAttemptAtUtc!)) ||
        (lastSuccessfulAtUtc != null &&
            updatedAtUtc != null &&
            lastSuccessfulAtUtc!.isAfter(updatedAtUtc!))) {
      throw const FormatException('Sync checkpoint is corrupt.');
    }
  }

  Map<String, Object?> toMap() => {
    'module': module,
    'state': state.name,
    'revision': revision,
    'activeAttemptId': activeAttemptId,
    'trigger': trigger?.name,
    'lastAttemptAtUtc': lastAttemptAtUtc?.toIso8601String(),
    'lastSuccessfulAtUtc': lastSuccessfulAtUtc?.toIso8601String(),
    'updatedAtUtc': updatedAtUtc?.toIso8601String(),
    'reservationId': reservationId,
    'lastError': lastError,
  };
}

class MaintainiacSyncCheckpointStore {
  MaintainiacSyncCheckpointStore._(
    this._box, {
    MaintainiacSyncCheckpointStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacSyncCheckpointStore.memory({
    MaintainiacSyncCheckpointStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static Future<MaintainiacSyncCheckpointStore> create(
    String boxName, {
    MaintainiacSyncCheckpointStorageCheck? storageCheck,
  }) async => MaintainiacSyncCheckpointStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacSyncCheckpointStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacSyncCheckpoint checkpointFor(String module) {
    if (!_validToken(module, 80)) return MaintainiacSyncCheckpoint.idle(module);
    final value = _box?.get(module) ?? _memory[module];
    if (value is! Map) return MaintainiacSyncCheckpoint.idle(module);
    try {
      return MaintainiacSyncCheckpoint.fromMap(value);
    } on FormatException catch (error) {
      throw StateError('Stored sync checkpoint is corrupt: $error');
    }
  }

  Future<MaintainiacSyncCheckpoint> begin({
    required String module,
    required String attemptId,
    required MaintainiacSyncTrigger trigger,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final current = checkpointFor(module);
    if (!_validToken(module, 80) || !_validToken(attemptId, 160)) {
      throw ArgumentError('Invalid sync checkpoint identity.');
    }
    if (current.state == MaintainiacSyncAttemptState.running) {
      if (current.activeAttemptId == attemptId) return current;
      throw StateError('Another sync attempt is already running.');
    }
    await _ensureSpace();
    final now = _nextTime(current, nowUtc);
    final updated = MaintainiacSyncCheckpoint(
      module: module,
      state: MaintainiacSyncAttemptState.running,
      revision: current.revision + 1,
      activeAttemptId: attemptId,
      trigger: trigger,
      lastAttemptAtUtc: now,
      lastSuccessfulAtUtc: current.lastSuccessfulAtUtc,
      updatedAtUtc: now,
    );
    await _put(updated);
    return updated;
  });

  Future<MaintainiacSyncCheckpoint> finish({
    required String module,
    required String attemptId,
    required MaintainiacSyncAttemptState state,
    String? reservationId,
    String? error,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final current = checkpointFor(module);
    if (current.state != MaintainiacSyncAttemptState.running ||
        current.activeAttemptId != attemptId ||
        !{
          MaintainiacSyncAttemptState.succeeded,
          MaintainiacSyncAttemptState.failed,
          MaintainiacSyncAttemptState.cancelled,
        }.contains(state) ||
        (reservationId != null && !_validToken(reservationId, 160)) ||
        (error != null && (error.trim().isEmpty || error.length > 500)) ||
        (state == MaintainiacSyncAttemptState.succeeded && error != null) ||
        (state == MaintainiacSyncAttemptState.failed && error == null)) {
      throw StateError('Sync checkpoint completion is invalid.');
    }
    await _ensureSpace();
    final now = _nextTime(current, nowUtc);
    final updated = MaintainiacSyncCheckpoint(
      module: module,
      state: state,
      revision: current.revision + 1,
      trigger: current.trigger,
      lastAttemptAtUtc: current.lastAttemptAtUtc,
      lastSuccessfulAtUtc: state == MaintainiacSyncAttemptState.succeeded
          ? now
          : current.lastSuccessfulAtUtc,
      updatedAtUtc: now,
      reservationId: reservationId,
      lastError: error,
    );
    await _put(updated);
    return updated;
  });

  Future<MaintainiacSyncCheckpoint> recoverInterrupted(
    String module, {
    DateTime? nowUtc,
  }) async {
    final current = checkpointFor(module);
    if (current.state != MaintainiacSyncAttemptState.running ||
        current.activeAttemptId == null) {
      return current;
    }
    return finish(
      module: module,
      attemptId: current.activeAttemptId!,
      state: MaintainiacSyncAttemptState.failed,
      error: 'Sync was interrupted before completion.',
      nowUtc: nowUtc,
    );
  }

  Future<void> _ensureSpace() async {
    final check = await _storageCheck();
    if (!check.hasEnoughSpace) throw StateError(check.blockingMessage());
  }

  Future<void> _put(MaintainiacSyncCheckpoint checkpoint) async {
    final map = Map<String, Object?>.unmodifiable(checkpoint.toMap());
    if (_box == null) {
      _memory[checkpoint.module] = map;
    } else {
      await _box.put(checkpoint.module, map);
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final box = _box;
    if (box != null) {
      return MaintainiacHiveWriteSerialization.enqueue(box.name, operation);
    }
    final next = _writeTail.then((_) => operation());
    _writeTail = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  static DateTime _nextTime(
    MaintainiacSyncCheckpoint current,
    DateTime? requested,
  ) {
    final next = (requested ?? DateTime.now()).toUtc();
    final previous = current.updatedAtUtc;
    return previous == null || next.isAfter(previous)
        ? next
        : previous.add(const Duration(microseconds: 1));
  }

  static Future<AppStorageCheck> _defaultStorageCheck() =>
      AppStorageGuard.check(AppStoragePurpose.smallRecordWrite);
}

bool _validToken(String value, int maximumLength) =>
    value.isNotEmpty &&
    value.length <= maximumLength &&
    RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(value);

String? _optionalString(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is String) return value;
  throw const FormatException('Sync checkpoint field type is invalid.');
}

DateTime? _optionalDate(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw const FormatException('Sync checkpoint date type is invalid.');
  }
  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    throw const FormatException('Sync checkpoint date is invalid.');
  }
  return parsed.toUtc();
}
