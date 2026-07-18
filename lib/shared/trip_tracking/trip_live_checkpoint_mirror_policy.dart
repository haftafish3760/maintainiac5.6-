import 'trip_live_checkpoint_durability_policy.dart';
import 'trip_tracking_sync_attempt_guard.dart';

enum TripLiveCheckpointMirrorStatus {
  ready,
  blockedDurability,
  blockedSyncAttempt,
  blockedPayloadShape,
}

class TripLiveCheckpointMirrorDecision {
  const TripLiveCheckpointMirrorDecision({
    required this.status,
    required this.reasonCode,
    required this.payload,
  });

  final TripLiveCheckpointMirrorStatus status;
  final String reasonCode;
  final Map<String, Object?> payload;

  bool get mayMirrorLiveCheckpoint =>
      status == TripLiveCheckpointMirrorStatus.ready;

  Map<String, Object?> toSafeDashboardMap() => {
    'schemaVersion': 1,
    'status': status.name,
    'reasonCode': _safeReason(reasonCode),
    'mayMirrorLiveCheckpoint': mayMirrorLiveCheckpoint,
    'localCheckpointRequiredBeforeBackup': true,
    'syncAttemptRequiredBeforeBackup': true,
    'reservationRequiredBeforeUpload': true,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanDeleteLocalData': false,
    'mirrorCanConfirmOdometer': false,
    'mirrorCanCreateStop': false,
    'mirrorCanEndTripAutomatically': false,
    'backupFailureCanStopGpsTracking': false,
    'backupFailureCanDropCurrentCheckpoint': false,
    'mapboxCanCreateCheckpoint': false,
    'payloadContainsRawGps': false,
    'payloadContainsPreciseLocation': false,
    'payloadContainsRouteGeometry': false,
    'payloadContainsMapboxData': false,
    'tokensIncluded': false,
  };
}

class TripLiveCheckpointMirrorPolicy {
  const TripLiveCheckpointMirrorPolicy._();

  static TripLiveCheckpointMirrorDecision evaluate({
    required TripLiveCheckpointDurabilityDecision durability,
    required TripTrackingSyncAttemptDecision syncAttempt,
  }) {
    if (durability.status ==
            TripLiveCheckpointDurabilityStatus.blockedInvalidCheckpoint ||
        durability.shouldWriteLocalCheckpointNow ||
        !durability.mayUploadBackupMirror) {
      return _decision(
        status: TripLiveCheckpointMirrorStatus.blockedDurability,
        reasonCode: 'live_checkpoint_durability_not_ready',
      );
    }
    if (!syncAttempt.mayUploadMirror || syncAttempt.mirrorPayload.isEmpty) {
      return _decision(
        status: TripLiveCheckpointMirrorStatus.blockedSyncAttempt,
        reasonCode: 'live_checkpoint_sync_attempt_not_ready',
      );
    }
    if (!_payloadShapeSafe(syncAttempt.mirrorPayload)) {
      return _decision(
        status: TripLiveCheckpointMirrorStatus.blockedPayloadShape,
        reasonCode: 'live_checkpoint_payload_shape_rejected',
      );
    }
    return _decision(
      status: TripLiveCheckpointMirrorStatus.ready,
      reasonCode: 'live_checkpoint_mirror_ready',
      payload: _payloadFor(syncAttempt.mirrorPayload),
    );
  }
}

TripLiveCheckpointMirrorDecision _decision({
  required TripLiveCheckpointMirrorStatus status,
  required String reasonCode,
  Map<String, Object?> payload = const <String, Object?>{},
}) {
  return TripLiveCheckpointMirrorDecision(
    status: status,
    reasonCode: _safeReason(reasonCode),
    payload: Map.unmodifiable(payload),
  );
}

Map<String, Object?> _payloadFor(Map<String, Object?> source) {
  return {
    'schemaVersion': 1,
    'schema': 'trip_live_checkpoint_mirror_v1',
    'recordId': source['recordId'],
    'kind': source['kind'],
    'updatedAtUtc': source['updatedAtUtc'],
    'localRevision': source['localRevision'],
    'tripDayKey': source['tripDayKey'],
    'distanceMiles': source['distanceMiles'],
    'localPersisted': true,
    'canonicalSource': 'hive',
    'firestoreRole': 'mirror_after_local_write',
    'canOverrideLocalDaytimeData': false,
    'canDeleteLocalData': false,
    'odometerRemainsOfficialMileageTruth': true,
    'rawGpsIncluded': false,
    'preciseLocationIncluded': false,
    'routeGeometryIncluded': false,
    'mapboxDataIncluded': false,
    'tokensIncluded': false,
  };
}

bool _payloadShapeSafe(Map<String, Object?> payload) {
  return payload['schemaVersion'] == 1 &&
      _safeIdentifier(payload['recordId'], maxLength: 96) &&
      _safeKnownKind(payload['kind']) &&
      payload['updatedAtUtc'] is String &&
      payload['localRevision'] is int &&
      (payload['localRevision'] as int) > 0 &&
      payload['localPersisted'] == true &&
      payload['canonicalSource'] == 'hive' &&
      payload['firestoreRole'] == 'mirror' &&
      payload['canOverrideLocalDaytimeData'] == false &&
      payload['canDeleteLocalData'] == false &&
      payload['odometerRemainsOfficialMileageTruth'] == true &&
      _safeTripDayKey(payload['tripDayKey']) &&
      _safeDistance(payload['distanceMiles']);
}

bool _safeKnownKind(Object? value) {
  return value == TripTrackingSyncSourceKind.liveTrip.name ||
      value == TripTrackingSyncSourceKind.reviewedMileage.name ||
      value == TripTrackingSyncSourceKind.stopReview.name ||
      value == TripTrackingSyncSourceKind.dashboardSummary.name;
}

bool _safeIdentifier(Object? value, {required int maxLength}) {
  if (value is! String) return false;
  final clean = value.trim();
  if (clean.isEmpty ||
      clean != value ||
      clean.length > maxLength ||
      clean.contains(':')) {
    return false;
  }
  return RegExp(r'^[A-Za-z0-9_.-]+$').hasMatch(clean);
}

bool _safeTripDayKey(Object? value) {
  if (value == null) return true;
  return value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value);
}

bool _safeDistance(Object? value) {
  if (value == null) return true;
  if (value is! num || !value.isFinite) return false;
  return value >= 0 && value <= 2500;
}

String _safeReason(String value) {
  return switch (value.trim()) {
    'live_checkpoint_durability_not_ready' =>
      'live_checkpoint_durability_not_ready',
    'live_checkpoint_sync_attempt_not_ready' =>
      'live_checkpoint_sync_attempt_not_ready',
    'live_checkpoint_payload_shape_rejected' =>
      'live_checkpoint_payload_shape_rejected',
    'live_checkpoint_mirror_ready' => 'live_checkpoint_mirror_ready',
    _ => 'live_checkpoint_payload_shape_rejected',
  };
}
