import 'package:hive/hive.dart';

import '../storage/app_storage_guard.dart';
import 'maintainiac_durable_payload.dart';
import 'maintainiac_hive_write_serialization.dart';
import 'maintainiac_record_ordering.dart';

part 'maintainiac_record_draft_store.dart';

/// The one lifecycle vocabulary used by durable Maintainiac records.
enum MaintainiacRecordState {
  active,
  deleted;

  static MaintainiacRecordState fromName(String? value) {
    return MaintainiacRecordState.values.firstWhere(
      (state) => state.name == value?.trim().toLowerCase(),
      orElse: () => MaintainiacRecordState.active,
    );
  }
}

enum MaintainiacStoredRecordKind { confirmed, draft }

class MaintainiacStoredRecordIntegrityIssue {
  const MaintainiacStoredRecordIntegrityIssue({
    required this.storageKey,
    required this.kind,
  });

  final String storageKey;
  final MaintainiacStoredRecordKind kind;
}

/// Immutable, local-first lifecycle metadata shared by record modules.
class MaintainiacRecordLifecycle {
  MaintainiacRecordLifecycle({
    required DateTime createdAt,
    required DateTime updatedAt,
    this.revision = 1,
    this.state = MaintainiacRecordState.active,
    DateTime? deletedAt,
    List<String> auditEvents = const [],
  }) : createdAt = createdAt.toUtc(),
       updatedAt = updatedAt.toUtc(),
       deletedAt = deletedAt?.toUtc(),
       auditEvents = List.unmodifiable(List<String>.from(auditEvents)) {
    _validate();
  }

  factory MaintainiacRecordLifecycle.fromMap(Map<dynamic, dynamic> map) {
    final createdAt = _date(map['createdAt']);
    final updatedAt = _date(map['updatedAt']);
    final revision = map['revision'];
    final stateName = map['state'];
    final states = MaintainiacRecordState.values.where(
      (state) => state.name == stateName,
    );
    final deletedValue = map['deletedAt'];
    final deletedAt = _date(deletedValue);
    final auditValues = map['auditEvents'];
    if (createdAt == null ||
        updatedAt == null ||
        revision is! int ||
        states.length != 1 ||
        (deletedValue != null && deletedAt == null) ||
        auditValues is! List ||
        auditValues.any((event) => event is! String)) {
      throw const FormatException('Record lifecycle is corrupt.');
    }
    try {
      return MaintainiacRecordLifecycle(
        createdAt: createdAt,
        updatedAt: updatedAt,
        revision: revision,
        state: states.single,
        deletedAt: deletedAt,
        auditEvents: auditValues.cast<String>(),
      );
    } on ArgumentError {
      throw const FormatException('Record lifecycle is inconsistent.');
    }
  }

  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final MaintainiacRecordState state;
  final DateTime? deletedAt;
  final List<String> auditEvents;

  bool get isActive => state == MaintainiacRecordState.active;
  bool get isDeleted => state == MaintainiacRecordState.deleted;

  MaintainiacRecordLifecycle saved(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: state,
      deletedAt: deletedAt,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  /// Advances a recoverable draft without treating each autosave as a user
  /// audit event. Confirmed record changes continue to use [saved].
  MaintainiacRecordLifecycle checkpointed(DateTime now) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: state,
      deletedAt: deletedAt,
      auditEvents: auditEvents,
    );
  }

  MaintainiacRecordLifecycle deleted(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: MaintainiacRecordState.deleted,
      deletedAt: time,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  MaintainiacRecordLifecycle restored(DateTime now, {required String event}) {
    final time = _nextLifecycleTime(now);
    return MaintainiacRecordLifecycle(
      createdAt: createdAt,
      updatedAt: time,
      revision: revision + 1,
      state: MaintainiacRecordState.active,
      auditEvents: [...auditEvents, _event(time, event)],
    );
  }

  // A device clock can move backward or emit the same timestamp for separate
  // edits. Keep every lifecycle mutation strictly ordered so a newer draft
  // cannot be mistaken for the checkpoint that a confirmed record may remove.
  DateTime _nextLifecycleTime(DateTime requested) =>
      requested.isAfter(updatedAt)
      ? requested
      : updatedAt.add(const Duration(microseconds: 1));

  Map<String, dynamic> toMap() => {
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'revision': revision,
    'state': state.name,
    'deletedAt': deletedAt?.toIso8601String(),
    'auditEvents': auditEvents,
  };

  static String _event(DateTime time, String event) =>
      '${time.toIso8601String()} ${event.trim()}';

  void _validate() {
    if (revision < 1 || updatedAt.isBefore(createdAt)) {
      throw ArgumentError('Record lifecycle ordering is invalid.');
    }
    if ((state == MaintainiacRecordState.deleted && deletedAt == null) ||
        (state == MaintainiacRecordState.active && deletedAt != null) ||
        (deletedAt != null &&
            (deletedAt!.isBefore(createdAt) ||
                deletedAt!.isAfter(updatedAt)))) {
      throw ArgumentError('Record deletion lifecycle is invalid.');
    }
    if (auditEvents.any((event) => event.trim().isEmpty)) {
      throw ArgumentError('Record audit events cannot be empty.');
    }
  }
}

/// A shared local checkpoint for work that is not yet a confirmed record.
/// Screens save a checkpoint on meaningful edits and remove it only after the
/// confirmed record has been written successfully.
class MaintainiacRecordDraft {
  MaintainiacRecordDraft({
    required this.module,
    required this.id,
    required Map<String, dynamic> payload,
    required this.lifecycle,
  }) : payload = _freezeDraftPayload(payload);

  factory MaintainiacRecordDraft.fromMap(Map<dynamic, dynamic> map) {
    final module = map['module'];
    final id = map['id'];
    final payload = map['payload'];
    final lifecycleMap = map['lifecycle'];
    if (module is! String ||
        id is! String ||
        !_hasValidDurableDraftKey(module, id) ||
        payload is! Map ||
        lifecycleMap is! Map) {
      throw const FormatException('Draft record is corrupt.');
    }
    final createdAt = _date(lifecycleMap['createdAt']);
    final updatedAt = _date(lifecycleMap['updatedAt']);
    final revision = _int(lifecycleMap['revision']);
    final stateName = lifecycleMap['state'];
    final deletedAt = _date(lifecycleMap['deletedAt']);
    final state = MaintainiacRecordState.values.where(
      (state) => state.name == stateName,
    );
    if (createdAt == null ||
        updatedAt == null ||
        updatedAt.isBefore(createdAt) ||
        revision == null ||
        revision < 1 ||
        state.length != 1) {
      throw const FormatException('Draft lifecycle is corrupt.');
    }
    final recordState = state.single;
    if ((recordState == MaintainiacRecordState.deleted && deletedAt == null) ||
        (recordState == MaintainiacRecordState.active && deletedAt != null) ||
        (deletedAt != null &&
            (deletedAt.isBefore(createdAt) || deletedAt.isAfter(updatedAt)))) {
      throw const FormatException('Draft lifecycle is inconsistent.');
    }
    try {
      return MaintainiacRecordDraft(
        module: module,
        id: id,
        payload: Map<String, dynamic>.from(payload),
        lifecycle: MaintainiacRecordLifecycle(
          createdAt: createdAt,
          updatedAt: updatedAt,
          revision: revision,
          state: recordState,
          deletedAt: deletedAt,
          auditEvents:
              (lifecycleMap['auditEvents'] as List?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const [],
        ),
      );
    } on ArgumentError {
      throw const FormatException('Draft payload is corrupt.');
    }
  }

  final String module;
  final String id;
  final Map<String, dynamic> payload;
  final MaintainiacRecordLifecycle lifecycle;

  String get storageKey => '$module:$id';

  Map<String, dynamic> toMap() => {
    'module': module,
    'id': id,
    'payload': payload,
    'lifecycle': lifecycle.toMap(),
  };
}

DateTime? _date(Object? value) =>
    value is DateTime ? value : DateTime.tryParse(value?.toString() ?? '');

bool _hasValidDurableDraftKey(String module, String id) =>
    module.trim().isNotEmpty &&
    id.trim().isNotEmpty &&
    module == module.trim() &&
    id == id.trim() &&
    !module.contains(':') &&
    !id.contains(':');

int? _int(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '');

Map<String, dynamic> _freezeDraftPayload(Map<String, dynamic> payload) {
  return MaintainiacDurablePayload.freeze(payload);
}
