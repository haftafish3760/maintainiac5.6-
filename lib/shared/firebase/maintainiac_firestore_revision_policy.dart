enum MaintainiacFirestoreRevisionAction { write, noOp, conflict }

class MaintainiacFirestoreRevisionDecision {
  const MaintainiacFirestoreRevisionDecision(
    this.action, {
    this.localRevision,
    this.remoteRevision,
  });

  final MaintainiacFirestoreRevisionAction action;
  final int? localRevision;
  final int? remoteRevision;
}

class MaintainiacFirestoreRevisionPolicy {
  const MaintainiacFirestoreRevisionPolicy._();

  static bool isRevisioned(Map<String, Object?> document) =>
      document['localRevision'] is int && document['recordState'] is String;

  static MaintainiacFirestoreRevisionDecision decide({
    required Map<String, Object?> incoming,
    Map<String, Object?>? existing,
  }) {
    if (!isRevisioned(incoming) || existing == null) {
      return const MaintainiacFirestoreRevisionDecision(
        MaintainiacFirestoreRevisionAction.write,
      );
    }
    final localRevision = incoming['localRevision'] as int;
    final remoteValue = existing['localRevision'];
    if (remoteValue is! int) {
      return MaintainiacFirestoreRevisionDecision(
        MaintainiacFirestoreRevisionAction.conflict,
        localRevision: localRevision,
      );
    }
    if (localRevision > remoteValue) {
      return MaintainiacFirestoreRevisionDecision(
        MaintainiacFirestoreRevisionAction.write,
        localRevision: localRevision,
        remoteRevision: remoteValue,
      );
    }
    if (localRevision == remoteValue && _deepEquals(incoming, existing)) {
      return MaintainiacFirestoreRevisionDecision(
        MaintainiacFirestoreRevisionAction.noOp,
        localRevision: localRevision,
        remoteRevision: remoteValue,
      );
    }
    return MaintainiacFirestoreRevisionDecision(
      MaintainiacFirestoreRevisionAction.conflict,
      localRevision: localRevision,
      remoteRevision: remoteValue,
    );
  }

  static bool _deepEquals(Object? left, Object? right) {
    if (identical(left, right) || left == right) return true;
    if (left is List && right is List) {
      if (left.length != right.length) return false;
      for (var index = 0; index < left.length; index += 1) {
        if (!_deepEquals(left[index], right[index])) return false;
      }
      return true;
    }
    if (left is Map && right is Map) {
      if (left.length != right.length) return false;
      for (final entry in left.entries) {
        if (!right.containsKey(entry.key) ||
            !_deepEquals(entry.value, right[entry.key])) {
          return false;
        }
      }
      return true;
    }
    return false;
  }
}

class MaintainiacFirestoreRevisionConflict implements Exception {
  const MaintainiacFirestoreRevisionConflict({
    required this.path,
    this.localRevision,
    this.remoteRevision,
  });

  final String path;
  final int? localRevision;
  final int? remoteRevision;

  @override
  String toString() =>
      'Cloud record conflict at $path '
      '(local revision ${localRevision ?? 'unknown'}, '
      'remote revision ${remoteRevision ?? 'unknown'}).';
}
