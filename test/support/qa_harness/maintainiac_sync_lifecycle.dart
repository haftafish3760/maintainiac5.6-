import 'maintainiac_qa_environment.dart';

enum MaintainiacSyncRecordState { clean, dirty, syncing, synced, failed }

class MaintainiacSyncRecord {
  const MaintainiacSyncRecord({
    required this.id,
    required this.box,
    required this.payload,
    required this.state,
    this.retryCount = 0,
    this.lastError = '',
  });

  final String id;
  final String box;
  final Map<String, Object?> payload;
  final MaintainiacSyncRecordState state;
  final int retryCount;
  final String lastError;

  MaintainiacSyncRecord copyWith({
    Map<String, Object?>? payload,
    MaintainiacSyncRecordState? state,
    int? retryCount,
    String? lastError,
  }) {
    return MaintainiacSyncRecord(
      id: id,
      box: box,
      payload: Map.of(payload ?? this.payload),
      state: state ?? this.state,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'box': box,
      'payload': payload,
      'state': state.name,
      'retryCount': retryCount,
      if (lastError.isNotEmpty) 'lastError': lastError,
    };
  }
}

class MaintainiacSyncLifecycleProbe {
  MaintainiacSyncLifecycleProbe(this.env);

  final MaintainiacQaEnvironment env;
  final _records = <String, MaintainiacSyncRecord>{};

  List<MaintainiacSyncRecord> get records => List.unmodifiable(_records.values);

  MaintainiacSyncRecord localWrite({
    required String box,
    required String id,
    required Map<String, Object?> payload,
  }) {
    final localPayload = {...payload, 'dirty': true};
    env.hive.put(box, id, localPayload);
    final record = MaintainiacSyncRecord(
      id: id,
      box: box,
      payload: localPayload,
      state: MaintainiacSyncRecordState.dirty,
    );
    _records['$box/$id'] = record;
    return record;
  }

  MaintainiacSyncRecord markSyncing(String box, String id) {
    return _update(
      box,
      id,
      (record) => record.copyWith(state: MaintainiacSyncRecordState.syncing),
    );
  }

  MaintainiacSyncRecord markFailed(String box, String id, String error) {
    return _update(
      box,
      id,
      (record) => record.copyWith(
        state: MaintainiacSyncRecordState.failed,
        retryCount: record.retryCount + 1,
        lastError: error,
      ),
    );
  }

  MaintainiacSyncRecord mirrorSuccess({
    required String box,
    required String id,
    required String path,
  }) {
    return _update(box, id, (record) {
      final cleanPayload = {...record.payload, 'dirty': false};
      env.firestoreMirror.mirror(path, cleanPayload);
      return record.copyWith(
        payload: cleanPayload,
        state: MaintainiacSyncRecordState.synced,
        lastError: '',
      );
    });
  }

  List<MaintainiacSyncRecord> pendingRetryQueue() {
    return [
      for (final record in _records.values)
        if (record.state == MaintainiacSyncRecordState.dirty ||
            record.state == MaintainiacSyncRecordState.failed)
          record,
    ];
  }

  void assertLocalIsAuthority(String box, String id) {
    final record = _require(box, id);
    final local = env.hive.get(box, id);
    if (local == null) {
      throw StateError('Missing local source record $box/$id.');
    }
    if (local['dirty'] != record.payload['dirty']) {
      throw StateError('Local dirty flag differs from lifecycle record.');
    }
  }

  MaintainiacSyncRecord _update(
    String box,
    String id,
    MaintainiacSyncRecord Function(MaintainiacSyncRecord record) update,
  ) {
    final next = update(_require(box, id));
    _records['$box/$id'] = next;
    return next;
  }

  MaintainiacSyncRecord _require(String box, String id) {
    final record = _records['$box/$id'];
    if (record == null) {
      throw StateError('Unknown sync record $box/$id.');
    }
    return record;
  }
}
