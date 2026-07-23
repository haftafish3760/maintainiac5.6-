import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_restore_contract.dart';

typedef MaintainiacRestoreStorageCheck =
    Future<AppStorageCheck> Function({required int operationBytes});

class MaintainiacRestoreSession {
  MaintainiacRestoreSession({
    required this.id,
    required this.accountScopeId,
    required this.deviceId,
    required this.authorizationId,
    required this.mode,
    required this.state,
    required this.storagePlan,
    required this.totalItems,
    required this.completedItems,
    required this.completedBytes,
    required this.createdAtUtc,
    required this.updatedAtUtc,
    required this.revision,
    this.cursor,
    this.failureReason,
  });

  factory MaintainiacRestoreSession.fromMap(Map<dynamic, dynamic> map) {
    final mode = MaintainiacRestoreMode.values.where(
      (value) => value.name == map['mode'],
    );
    final state = MaintainiacRestoreSessionState.values.where(
      (value) => value.name == map['state'],
    );
    final created = DateTime.tryParse(map['createdAtUtc']?.toString() ?? '');
    final updated = DateTime.tryParse(map['updatedAtUtc']?.toString() ?? '');
    if (mode.length != 1 ||
        state.length != 1 ||
        created == null ||
        updated == null) {
      throw const FormatException('Restore session lifecycle is corrupt.');
    }
    final session = MaintainiacRestoreSession(
      id: _requiredToken(map, 'id'),
      accountScopeId: _requiredToken(map, 'accountScopeId'),
      deviceId: _requiredToken(map, 'deviceId'),
      authorizationId: _requiredToken(map, 'authorizationId'),
      mode: mode.single,
      state: state.single,
      storagePlan: MaintainiacRestoreStoragePlan.fromMap(
        _requiredMap(map, 'storagePlan'),
      ),
      totalItems: _requiredNonNegativeInt(map, 'totalItems'),
      completedItems: _requiredNonNegativeInt(map, 'completedItems'),
      completedBytes: _requiredNonNegativeInt(map, 'completedBytes'),
      createdAtUtc: created.toUtc(),
      updatedAtUtc: updated.toUtc(),
      revision: _requiredPositiveInt(map, 'revision'),
      cursor: map['cursor'] as String?,
      failureReason: map['failureReason'] as String?,
    );
    session.validate();
    return session;
  }

  final String id;
  final String accountScopeId;
  final String deviceId;
  final String authorizationId;
  final MaintainiacRestoreMode mode;
  final MaintainiacRestoreSessionState state;
  final MaintainiacRestoreStoragePlan storagePlan;
  final int totalItems;
  final int completedItems;
  final int completedBytes;
  final DateTime createdAtUtc;
  final DateTime updatedAtUtc;
  final int revision;
  final String? cursor;
  final String? failureReason;

  int get transferBytes => storagePlan.transferBytesFor(mode);

  void validate() {
    if (!_validToken(id) ||
        !_validToken(accountScopeId) ||
        !_validToken(deviceId) ||
        !_validToken(authorizationId) ||
        completedItems > totalItems ||
        completedBytes > transferBytes ||
        updatedAtUtc.isBefore(createdAtUtc) ||
        revision < 1 ||
        (cursor != null && cursor!.trim().isEmpty) ||
        (failureReason != null && failureReason!.trim().isEmpty)) {
      throw const FormatException('Restore session is corrupt.');
    }
  }

  MaintainiacRestoreSession changed({
    required MaintainiacRestoreSessionState state,
    required DateTime nowUtc,
    int? completedItems,
    int? completedBytes,
    String? cursor,
    String? failureReason,
    bool clearFailure = false,
  }) => MaintainiacRestoreSession(
    id: id,
    accountScopeId: accountScopeId,
    deviceId: deviceId,
    authorizationId: authorizationId,
    mode: mode,
    state: state,
    storagePlan: storagePlan,
    totalItems: totalItems,
    completedItems: completedItems ?? this.completedItems,
    completedBytes: completedBytes ?? this.completedBytes,
    createdAtUtc: createdAtUtc,
    updatedAtUtc: _nextTime(nowUtc),
    revision: revision + 1,
    cursor: cursor ?? this.cursor,
    failureReason: clearFailure ? null : failureReason ?? this.failureReason,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'accountScopeId': accountScopeId,
    'deviceId': deviceId,
    'authorizationId': authorizationId,
    'mode': mode.name,
    'state': state.name,
    'storagePlan': storagePlan.toMap(),
    'totalItems': totalItems,
    'completedItems': completedItems,
    'completedBytes': completedBytes,
    'createdAtUtc': createdAtUtc.toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
    'revision': revision,
    'cursor': cursor,
    'failureReason': failureReason,
  };

  DateTime _nextTime(DateTime requested) {
    final utc = requested.toUtc();
    return utc.isAfter(updatedAtUtc)
        ? utc
        : updatedAtUtc.add(const Duration(microseconds: 1));
  }
}

class MaintainiacRestoreSessionStore {
  MaintainiacRestoreSessionStore._(
    this._box, {
    MaintainiacRestoreStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacRestoreSessionStore.memory({
    MaintainiacRestoreStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static Future<MaintainiacRestoreSessionStore> create(
    String boxName, {
    MaintainiacRestoreStorageCheck? storageCheck,
  }) async => MaintainiacRestoreSessionStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacRestoreStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacRestoreSession? sessionById(String id) {
    if (!_validToken(id)) return null;
    final value = _box?.get(id) ?? _memory[id];
    return value is Map ? MaintainiacRestoreSession.fromMap(value) : null;
  }

  List<MaintainiacRestoreSession> sessionsForAccount(String accountScopeId) {
    if (!_validToken(accountScopeId)) return const [];
    final values = _box?.values ?? _memory.values;
    final sessions = values
        .whereType<Map>()
        .map(MaintainiacRestoreSession.fromMap)
        .where((session) => session.accountScopeId == accountScopeId)
        .toList();
    sessions.sort((a, b) => b.updatedAtUtc.compareTo(a.updatedAtUtc));
    return List.unmodifiable(sessions);
  }

  Future<MaintainiacRestoreSession> prepare({
    required String id,
    required String accountScopeId,
    required String deviceId,
    required String authorizationId,
    required MaintainiacRestoreMode mode,
    required MaintainiacRestoreStoragePlan storagePlan,
    required int totalItems,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    if (sessionById(id) != null) {
      throw StateError('Restore session already exists.');
    }
    final check = await _storageCheck(
      operationBytes: storagePlan.operationBytesFor(mode),
    );
    if (!check.hasEnoughSpace || !storagePlan.canFit(mode)) {
      throw StateError(check.blockingMessage());
    }
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final session = MaintainiacRestoreSession(
      id: id,
      accountScopeId: accountScopeId,
      deviceId: deviceId,
      authorizationId: authorizationId,
      mode: mode,
      state: MaintainiacRestoreSessionState.prepared,
      storagePlan: storagePlan,
      totalItems: totalItems,
      completedItems: 0,
      completedBytes: 0,
      createdAtUtc: now,
      updatedAtUtc: now,
      revision: 1,
    );
    session.validate();
    await _put(session);
    return session;
  });

  Future<MaintainiacRestoreSession> start(String id, {DateTime? nowUtc}) =>
      _transition(
        id,
        allowed: const {
          MaintainiacRestoreSessionState.prepared,
          MaintainiacRestoreSessionState.paused,
          MaintainiacRestoreSessionState.failed,
        },
        next: MaintainiacRestoreSessionState.running,
        nowUtc: nowUtc,
        clearFailure: true,
      );

  Future<MaintainiacRestoreSession> updateProgress({
    required String id,
    required int completedItems,
    required int completedBytes,
    required String cursor,
    int? expectedRevision,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final current = _requiredSession(id);
    if (current.state != MaintainiacRestoreSessionState.running ||
        (expectedRevision != null && current.revision != expectedRevision) ||
        completedItems < current.completedItems ||
        completedItems > current.totalItems ||
        completedBytes < current.completedBytes ||
        completedBytes > current.transferBytes ||
        cursor.trim().isEmpty) {
      throw StateError('Restore progress is invalid or out of order.');
    }
    final updated = current.changed(
      state: current.state,
      nowUtc: nowUtc ?? DateTime.now(),
      completedItems: completedItems,
      completedBytes: completedBytes,
      cursor: cursor.trim(),
    );
    await _put(updated);
    return updated;
  });

  Future<MaintainiacRestoreSession> pause(String id, {DateTime? nowUtc}) =>
      _transition(
        id,
        allowed: const {MaintainiacRestoreSessionState.running},
        next: MaintainiacRestoreSessionState.paused,
        nowUtc: nowUtc,
      );

  Future<MaintainiacRestoreSession> fail(
    String id,
    String reason, {
    int? expectedRevision,
    DateTime? nowUtc,
  }) => _transition(
    id,
    allowed: const {
      MaintainiacRestoreSessionState.prepared,
      MaintainiacRestoreSessionState.running,
      MaintainiacRestoreSessionState.paused,
      MaintainiacRestoreSessionState.failed,
    },
    next: MaintainiacRestoreSessionState.failed,
    nowUtc: nowUtc,
    expectedRevision: expectedRevision,
    failureReason: reason.trim(),
  );

  Future<MaintainiacRestoreSession> cancel(String id, {DateTime? nowUtc}) =>
      _transition(
        id,
        allowed: const {
          MaintainiacRestoreSessionState.prepared,
          MaintainiacRestoreSessionState.running,
          MaintainiacRestoreSessionState.paused,
          MaintainiacRestoreSessionState.failed,
        },
        next: MaintainiacRestoreSessionState.cancelled,
        nowUtc: nowUtc,
      );

  Future<MaintainiacRestoreSession> complete(String id, {DateTime? nowUtc}) =>
      _enqueue(() async {
        final current = _requiredSession(id);
        if (current.state != MaintainiacRestoreSessionState.running ||
            current.completedItems != current.totalItems ||
            current.completedBytes != current.transferBytes) {
          throw StateError('Restore cannot complete before all planned data.');
        }
        final updated = current.changed(
          state: MaintainiacRestoreSessionState.completed,
          nowUtc: nowUtc ?? DateTime.now(),
          clearFailure: true,
        );
        await _put(updated);
        return updated;
      });

  Future<MaintainiacRestoreSession> _transition(
    String id, {
    required Set<MaintainiacRestoreSessionState> allowed,
    required MaintainiacRestoreSessionState next,
    DateTime? nowUtc,
    int? expectedRevision,
    String? failureReason,
    bool clearFailure = false,
  }) => _enqueue(() async {
    final current = _requiredSession(id);
    if (!allowed.contains(current.state) ||
        (expectedRevision != null && current.revision != expectedRevision) ||
        (failureReason != null && failureReason.isEmpty)) {
      throw StateError('Restore session transition is invalid.');
    }
    final updated = current.changed(
      state: next,
      nowUtc: nowUtc ?? DateTime.now(),
      failureReason: failureReason,
      clearFailure: clearFailure,
    );
    await _put(updated);
    return updated;
  });

  MaintainiacRestoreSession _requiredSession(String id) {
    final session = sessionById(id);
    if (session == null) throw StateError('Restore session does not exist.');
    return session;
  }

  Future<void> _put(MaintainiacRestoreSession session) async {
    final value = session.toMap();
    if (_box == null) {
      _memory[session.id] = value;
    } else {
      await _box.put(session.id, value);
    }
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _writeTail.then((_) => operation());
    _writeTail = result.then<void>((_) {}, onError: (_) {});
    return result;
  }

  static Future<AppStorageCheck> _defaultStorageCheck({
    required int operationBytes,
  }) => AppStorageGuard.checkForBytes(
    operationBytes: operationBytes,
    purpose: AppStoragePurpose.restoreImport,
  );
}

bool _validToken(String value) =>
    RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(value);

String _requiredToken(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || !_validToken(value)) {
    throw FormatException('Restore session has invalid $key.');
  }
  return value;
}

Map<dynamic, dynamic> _requiredMap(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! Map) throw FormatException('Restore session has invalid $key.');
  return value;
}

int _requiredNonNegativeInt(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! int || value < 0) {
    throw FormatException('Restore session has invalid $key.');
  }
  return value;
}

int _requiredPositiveInt(Map<dynamic, dynamic> map, String key) {
  final value = _requiredNonNegativeInt(map, key);
  if (value < 1) throw FormatException('Restore session has invalid $key.');
  return value;
}
