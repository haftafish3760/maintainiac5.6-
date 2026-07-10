enum MaintainiacConflictResolution {
  localWins,
  remoteWins,
  merged,
  needsReview,
}

class MaintainiacSyncConflictField {
  const MaintainiacSyncConflictField({
    required this.name,
    required this.localValue,
    required this.remoteValue,
    this.userConfirmed = false,
    this.financial = false,
  });

  final String name;
  final Object? localValue;
  final Object? remoteValue;
  final bool userConfirmed;
  final bool financial;

  bool get differs => localValue != remoteValue;

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'localValue': localValue,
      'remoteValue': remoteValue,
      'userConfirmed': userConfirmed,
      'financial': financial,
    };
  }
}

class MaintainiacSyncConflictCase {
  const MaintainiacSyncConflictCase({
    required this.id,
    required this.collection,
    required this.recordId,
    required this.fields,
    required this.resolution,
    required this.reason,
    this.auditId = '',
    this.writesMirrorOnly = true,
    this.mutatesLocalWithoutUser = false,
  });

  final String id;
  final String collection;
  final String recordId;
  final List<MaintainiacSyncConflictField> fields;
  final MaintainiacConflictResolution resolution;
  final String reason;
  final String auditId;
  final bool writesMirrorOnly;
  final bool mutatesLocalWithoutUser;

  List<String> validate() {
    final failures = <String>[];
    if (id.trim().isEmpty) failures.add('sync conflict missing id');
    if (collection.trim().isEmpty) failures.add('$id missing collection');
    if (recordId.trim().isEmpty) failures.add('$id missing record id');
    if (fields.isEmpty) failures.add('$id missing conflict fields');
    if (reason.trim().isEmpty) failures.add('$id missing reason');
    if (!writesMirrorOnly) {
      failures.add('$id conflict resolver must treat Firestore as mirror only');
    }
    if (mutatesLocalWithoutUser) {
      failures.add('$id must not mutate local source without user approval');
    }
    final changed = fields.where((field) => field.differs).toList();
    if (changed.isEmpty) failures.add('$id has no differing fields');
    if (changed.any((field) => field.financial || field.userConfirmed) &&
        resolution != MaintainiacConflictResolution.localWins &&
        resolution != MaintainiacConflictResolution.needsReview) {
      failures.add(
        '$id financial or user-confirmed conflicts cannot be remote-wins/auto-merged',
      );
    }
    if (fields.length == 1 &&
        changed.length == 1 &&
        resolution == MaintainiacConflictResolution.merged) {
      failures.add('$id same-field conflict cannot be marked merged');
    }
    if (resolution == MaintainiacConflictResolution.needsReview &&
        auditId.trim().isEmpty) {
      failures.add('$id review conflict needs audit id');
    }
    return failures;
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'collection': collection,
      'recordId': recordId,
      'fields': [for (final field in fields) field.toJson()],
      'resolution': resolution.name,
      'reason': reason,
      if (auditId.isNotEmpty) 'auditId': auditId,
      'writesMirrorOnly': writesMirrorOnly,
      'mutatesLocalWithoutUser': mutatesLocalWithoutUser,
    };
  }
}

class MaintainiacSyncConflictContract {
  const MaintainiacSyncConflictContract(this.conflicts);

  final List<MaintainiacSyncConflictCase> conflicts;

  List<String> validate() {
    final failures = <String>[];
    final ids = <String>{};
    if (conflicts.isEmpty) failures.add('sync conflict contract is empty');
    for (final conflict in conflicts) {
      if (!ids.add(conflict.id)) {
        failures.add('duplicate sync conflict id ${conflict.id}');
      }
      failures.addAll(conflict.validate());
    }
    return failures;
  }

  List<MaintainiacSyncConflictCase> reviewQueue() {
    return [
      for (final conflict in conflicts)
        if (conflict.resolution == MaintainiacConflictResolution.needsReview)
          conflict,
    ];
  }

  Map<String, Object?> toJson() {
    return {
      'conflictCount': conflicts.length,
      'reviewQueueCount': reviewQueue().length,
      'conflicts': [for (final conflict in conflicts) conflict.toJson()],
    };
  }
}
