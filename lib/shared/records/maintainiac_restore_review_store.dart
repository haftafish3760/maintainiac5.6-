import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_durable_record_store.dart';

enum MaintainiacRestoreReviewType { conflict, corrupt }

enum MaintainiacRestoreReviewState { pending, resolved }

enum MaintainiacRestoreResolution { keepLocal, applyRemote }

typedef MaintainiacRestoreReviewStorageCheck =
    Future<AppStorageCheck> Function({required int operationBytes});

class MaintainiacRestoreReviewRecord {
  const MaintainiacRestoreReviewRecord({
    required this.accountScopeId,
    required this.record,
    required this.schemaVersion,
    required this.contentSha256,
  });

  final String accountScopeId;
  final MaintainiacDurableRecord record;
  final int schemaVersion;
  final String contentSha256;
}

class MaintainiacRestoreReviewIssue {
  const MaintainiacRestoreReviewIssue({
    required this.id,
    required this.type,
    required this.state,
    required this.accountScopeId,
    required this.module,
    required this.recordId,
    required this.remote,
    required this.local,
    required this.firstDetectedAtUtc,
    required this.updatedAtUtc,
    required this.revision,
    this.resolution,
  });

  factory MaintainiacRestoreReviewIssue.fromMap(Map<dynamic, dynamic> map) {
    final type = _enumValue(MaintainiacRestoreReviewType.values, map['type']);
    final state = _enumValue(
      MaintainiacRestoreReviewState.values,
      map['state'],
    );
    final resolution = map['resolution'] == null
        ? null
        : _enumValue(MaintainiacRestoreResolution.values, map['resolution']);
    final issue = MaintainiacRestoreReviewIssue(
      id: _requiredHash(map, 'id'),
      type: type,
      state: state,
      accountScopeId: _requiredToken(map, 'accountScopeId'),
      module: _requiredToken(map, 'module'),
      recordId: _requiredToken(map, 'recordId'),
      remote: _envelopeFromMap(_requiredMap(map, 'remote')),
      local: map['local'] == null
          ? null
          : _envelopeFromMap(_requiredMap(map, 'local')),
      firstDetectedAtUtc: _requiredDate(map, 'firstDetectedAtUtc'),
      updatedAtUtc: _requiredDate(map, 'updatedAtUtc'),
      revision: _requiredPositiveInt(map, 'revision'),
      resolution: resolution,
    );
    issue.validate();
    return issue;
  }

  final String id;
  final MaintainiacRestoreReviewType type;
  final MaintainiacRestoreReviewState state;
  final String accountScopeId;
  final String module;
  final String recordId;
  final MaintainiacRestoreReviewRecord remote;
  final MaintainiacRestoreReviewRecord? local;
  final DateTime firstDetectedAtUtc;
  final DateTime updatedAtUtc;
  final int revision;
  final MaintainiacRestoreResolution? resolution;

  void validate() {
    if (!_hash(id) ||
        !_token(accountScopeId) ||
        !_token(module) ||
        !_token(recordId) ||
        remote.accountScopeId != accountScopeId ||
        remote.record.module != module ||
        remote.record.id != recordId ||
        remote.schemaVersion < 1 ||
        !_hash(remote.contentSha256) ||
        (type == MaintainiacRestoreReviewType.conflict && local == null) ||
        (local != null &&
            (local!.accountScopeId != accountScopeId ||
                local!.record.module != module ||
                local!.record.id != recordId ||
                local!.schemaVersion < 1 ||
                !_hash(local!.contentSha256))) ||
        updatedAtUtc.isBefore(firstDetectedAtUtc) ||
        revision < 1 ||
        (state == MaintainiacRestoreReviewState.pending &&
            resolution != null) ||
        (state == MaintainiacRestoreReviewState.resolved &&
            resolution == null)) {
      throw const FormatException('Restore review issue is corrupt.');
    }
  }

  MaintainiacRestoreReviewIssue changed({
    required MaintainiacRestoreReviewState state,
    required DateTime nowUtc,
    MaintainiacRestoreResolution? resolution,
  }) => MaintainiacRestoreReviewIssue(
    id: id,
    type: type,
    state: state,
    accountScopeId: accountScopeId,
    module: module,
    recordId: recordId,
    remote: remote,
    local: local,
    firstDetectedAtUtc: firstDetectedAtUtc,
    updatedAtUtc: nowUtc.toUtc().isAfter(updatedAtUtc)
        ? nowUtc.toUtc()
        : updatedAtUtc.add(const Duration(microseconds: 1)),
    revision: revision + 1,
    resolution: resolution,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'type': type.name,
    'state': state.name,
    'accountScopeId': accountScopeId,
    'module': module,
    'recordId': recordId,
    'remote': _envelopeToMap(remote),
    'local': local == null ? null : _envelopeToMap(local!),
    'firstDetectedAtUtc': firstDetectedAtUtc.toIso8601String(),
    'updatedAtUtc': updatedAtUtc.toIso8601String(),
    'revision': revision,
    'resolution': resolution?.name,
  };
}

class MaintainiacRestoreReviewStore {
  MaintainiacRestoreReviewStore._(
    this._box, {
    MaintainiacRestoreReviewStorageCheck? storageCheck,
  }) : _storageCheck = storageCheck ?? _defaultStorageCheck;

  MaintainiacRestoreReviewStore.memory({
    MaintainiacRestoreReviewStorageCheck? storageCheck,
  }) : _box = null,
       _storageCheck = storageCheck ?? _defaultStorageCheck;

  static Future<MaintainiacRestoreReviewStore> create(
    String boxName, {
    MaintainiacRestoreReviewStorageCheck? storageCheck,
  }) async => MaintainiacRestoreReviewStore._(
    await Hive.openBox<dynamic>(boxName),
    storageCheck: storageCheck,
  );

  final Box<dynamic>? _box;
  final MaintainiacRestoreReviewStorageCheck _storageCheck;
  final _memory = <String, Map<String, Object?>>{};
  Future<void> _writeTail = Future<void>.value();

  MaintainiacRestoreReviewIssue? issueById(String id) {
    if (!_hash(id)) return null;
    final value = _box?.get(id) ?? _memory[id];
    return value is Map ? MaintainiacRestoreReviewIssue.fromMap(value) : null;
  }

  List<MaintainiacRestoreReviewIssue> pendingFor(String accountScopeId) {
    if (!_token(accountScopeId)) return const [];
    final values = _box?.values ?? _memory.values;
    final issues =
        values
            .whereType<Map>()
            .map(MaintainiacRestoreReviewIssue.fromMap)
            .where(
              (issue) =>
                  issue.accountScopeId == accountScopeId &&
                  issue.state == MaintainiacRestoreReviewState.pending,
            )
            .toList()
          ..sort(
            (left, right) => right.updatedAtUtc.compareTo(left.updatedAtUtc),
          );
    return List.unmodifiable(issues);
  }

  Future<MaintainiacRestoreReviewIssue> record({
    required MaintainiacRestoreReviewType type,
    required MaintainiacRestoreReviewRecord remote,
    MaintainiacRestoreReviewRecord? local,
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final now = (nowUtc ?? DateTime.now()).toUtc();
    final id = _issueId(type, remote, local);
    final existing = issueById(id);
    if (existing?.state == MaintainiacRestoreReviewState.pending) {
      return existing!;
    }
    final issue =
        existing?.changed(
          state: MaintainiacRestoreReviewState.pending,
          nowUtc: now,
        ) ??
        MaintainiacRestoreReviewIssue(
          id: id,
          type: type,
          state: MaintainiacRestoreReviewState.pending,
          accountScopeId: remote.accountScopeId,
          module: remote.record.module,
          recordId: remote.record.id,
          remote: remote,
          local: local,
          firstDetectedAtUtc: now,
          updatedAtUtc: now,
          revision: 1,
        );
    issue.validate();
    await _put(issue);
    return issue;
  });

  Future<MaintainiacRestoreReviewIssue> resolve(
    String id,
    MaintainiacRestoreResolution resolution, {
    DateTime? nowUtc,
  }) => _enqueue(() async {
    final current = issueById(id);
    if (current == null ||
        current.state != MaintainiacRestoreReviewState.pending) {
      throw StateError('Restore review issue is not pending.');
    }
    final resolved = current.changed(
      state: MaintainiacRestoreReviewState.resolved,
      nowUtc: nowUtc ?? DateTime.now(),
      resolution: resolution,
    );
    await _put(resolved);
    return resolved;
  });

  Future<void> _put(MaintainiacRestoreReviewIssue issue) async {
    final value = issue.toMap();
    final bytes = utf8.encode(jsonEncode(value)).length;
    final check = await _storageCheck(operationBytes: bytes);
    if (!check.hasEnoughSpace) throw StateError(check.blockingMessage());
    if (_box == null) {
      _memory[issue.id] = value;
    } else {
      await _box.put(issue.id, value);
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

String _issueId(
  MaintainiacRestoreReviewType type,
  MaintainiacRestoreReviewRecord remote,
  MaintainiacRestoreReviewRecord? local,
) => sha256
    .convert(
      utf8.encode(
        '${type.name}\u0000${remote.accountScopeId}\u0000'
        '${remote.record.module}\u0000${remote.record.id}\u0000'
        '${remote.contentSha256}\u0000${local?.contentSha256 ?? '-'}',
      ),
    )
    .toString();

Map<String, Object?> _envelopeToMap(MaintainiacRestoreReviewRecord value) => {
  'accountScopeId': value.accountScopeId,
  'record': value.record.toMap(),
  'schemaVersion': value.schemaVersion,
  'contentSha256': value.contentSha256,
};

MaintainiacRestoreReviewRecord _envelopeFromMap(Map<dynamic, dynamic> map) =>
    MaintainiacRestoreReviewRecord(
      accountScopeId: _requiredToken(map, 'accountScopeId'),
      record: MaintainiacDurableRecord.fromMap(_requiredMap(map, 'record')),
      schemaVersion: _requiredPositiveInt(map, 'schemaVersion'),
      contentSha256: _requiredHash(map, 'contentSha256'),
    );

T _enumValue<T extends Enum>(List<T> values, Object? raw) {
  final matches = values.where((value) => value.name == raw);
  if (matches.length != 1) throw const FormatException('Invalid review value.');
  return matches.single;
}

Map<dynamic, dynamic> _requiredMap(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! Map) throw FormatException('Review issue has invalid $key.');
  return value;
}

String _requiredToken(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || !_token(value)) {
    throw FormatException('Review issue has invalid $key.');
  }
  return value;
}

String _requiredHash(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! String || !_hash(value)) {
    throw FormatException('Review issue has invalid $key.');
  }
  return value;
}

int _requiredPositiveInt(Map<dynamic, dynamic> map, String key) {
  final value = map[key];
  if (value is! int || value < 1) {
    throw FormatException('Review issue has invalid $key.');
  }
  return value;
}

DateTime _requiredDate(Map<dynamic, dynamic> map, String key) {
  final value = DateTime.tryParse(map[key]?.toString() ?? '');
  if (value == null) throw FormatException('Review issue has invalid $key.');
  return value.toUtc();
}

bool _token(String value) => RegExp(r'^[A-Za-z0-9_.-]{1,160}$').hasMatch(value);
bool _hash(String value) => RegExp(r'^[a-f0-9]{64}$').hasMatch(value);
