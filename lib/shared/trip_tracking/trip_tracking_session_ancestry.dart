// odometerIsGlobalTruth: true.
part of 'trip_tracking_session_store.dart';

/// Coordinate-free lineage for an explicitly approved split or merge.
/// It records ancestry only; it cannot split distance or confirm mileage.
enum TripTrackingSessionAncestryKind { splitChild, mergeResult }

class TripTrackingSessionAncestry {
  const TripTrackingSessionAncestry.splitChild({required this.parentSessionId})
    : kind = TripTrackingSessionAncestryKind.splitChild,
      sourceSessionIds = const [];

  TripTrackingSessionAncestry.mergeResult({
    required Iterable<String> sourceSessionIds,
  }) : sourceSessionIds = List.unmodifiable(sourceSessionIds),
       kind = TripTrackingSessionAncestryKind.mergeResult,
       parentSessionId = null;

  final TripTrackingSessionAncestryKind kind;
  final String? parentSessionId;
  final List<String> sourceSessionIds;

  bool isValidFor(String sessionId) {
    if (!_isSafeStoreIdentifierValue(sessionId)) return false;
    switch (kind) {
      case TripTrackingSessionAncestryKind.splitChild:
        return _isSafeStoreIdentifierValue(parentSessionId) &&
            parentSessionId != sessionId &&
            sourceSessionIds.isEmpty;
      case TripTrackingSessionAncestryKind.mergeResult:
        return parentSessionId == null &&
            sourceSessionIds.length >= 2 &&
            sourceSessionIds.length <= 32 &&
            sourceSessionIds.every(
              (id) => _isSafeStoreIdentifierValue(id) && id != sessionId,
            ) &&
            sourceSessionIds.toSet().length == sourceSessionIds.length;
    }
  }

  Map<String, Object?> toMap() => {
    'schemaVersion': 1,
    'kind': kind.name,
    if (parentSessionId != null) 'parentSessionId': parentSessionId,
    if (sourceSessionIds.isNotEmpty) 'sourceSessionIds': sourceSessionIds,
    'canChangeMileage': false,
    'requiresUserApproval': true,
  };

  static TripTrackingSessionAncestry? tryFromMap(
    Map<dynamic, dynamic> map, {
    required String sessionId,
  }) {
    if (map['schemaVersion'] != 1) return null;
    final kinds = TripTrackingSessionAncestryKind.values.where(
      (value) => value.name == map['kind'],
    );
    if (kinds.isEmpty) return null;
    final kind = kinds.first;
    final TripTrackingSessionAncestry ancestry;
    switch (kind) {
      case TripTrackingSessionAncestryKind.splitChild:
        if (map['parentSessionId'] is! String ||
            (map['sourceSessionIds'] is Iterable &&
                (map['sourceSessionIds'] as Iterable).isNotEmpty)) {
          return null;
        }
        ancestry = TripTrackingSessionAncestry.splitChild(
          parentSessionId: map['parentSessionId'] as String,
        );
        break;
      case TripTrackingSessionAncestryKind.mergeResult:
        final rawSources = map['sourceSessionIds'];
        if (map['parentSessionId'] != null ||
            rawSources is! List ||
            rawSources.any((value) => value is! String)) {
          return null;
        }
        ancestry = TripTrackingSessionAncestry.mergeResult(
          sourceSessionIds: rawSources.cast<String>().toList(),
        );
        break;
    }
    return ancestry.isValidFor(sessionId) ? ancestry : null;
  }
}
