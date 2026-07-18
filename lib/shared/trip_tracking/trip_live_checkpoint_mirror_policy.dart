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
    'checkpointRequiresDeviceMatch': true,
    'checkpointRequiresDayKeyMatch': true,
    'checkpointRequiresMonotonicLocalRevision': true,
    'authenticationAloneAuthorizesCheckpointMirror': false,
    'hiveRemainsOperationalSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteBackupCanOverrideLocalDay': false,
    'remoteBackupCanDeleteLocalData': false,
    'mirrorCanConfirmOdometer': false,
    'mirrorCanCreateStop': false,
    'mirrorCanEndTripAutomatically': false,
    'odometerIsGlobalTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'mirrorCanApplyCalibration': false,
    'mirrorCanCreateCalibrationProof': false,
    'mirrorCanCreateOfficialMileage': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
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

class TripLiveCheckpointMirrorSummaryValidation {
  const TripLiveCheckpointMirrorSummaryValidation._({
    required this.isRenderable,
    required this.reasons,
  });

  factory TripLiveCheckpointMirrorSummaryValidation.fromSummary(
    Map<String, Object?> summary,
  ) {
    final reasons = <String>[];
    if (summary['schemaVersion'] != 1) {
      reasons.add('unsupported_schema_version');
    }
    if (_safeStatus(summary['status']) == null) {
      reasons.add('invalid_checkpoint_mirror_status');
    }
    if (_safeReason(summary['reasonCode']?.toString() ?? '') !=
        summary['reasonCode']) {
      reasons.add('invalid_checkpoint_mirror_reason');
    }
    for (final key in const [
      'mayMirrorLiveCheckpoint',
      'localCheckpointRequiredBeforeBackup',
      'syncAttemptRequiredBeforeBackup',
      'reservationRequiredBeforeUpload',
      'checkpointRequiresDeviceMatch',
      'checkpointRequiresDayKeyMatch',
      'checkpointRequiresMonotonicLocalRevision',
      'authenticationAloneAuthorizesCheckpointMirror',
      'hiveRemainsOperationalSourceOfTruth',
      'firestoreMirrorOnly',
      'remoteBackupCanOverrideLocalDay',
      'remoteBackupCanDeleteLocalData',
      'mirrorCanConfirmOdometer',
      'mirrorCanCreateStop',
      'mirrorCanEndTripAutomatically',
      'odometerIsGlobalTruth',
      'mirrorCanApplyCalibration',
      'mirrorCanCreateCalibrationProof',
      'mirrorCanCreateOfficialMileage',
      'calibrationRequiresTrustedGpsWindow',
      'poorGpsDaysExcludedFromCalibration',
      'backupFailureCanStopGpsTracking',
      'backupFailureCanDropCurrentCheckpoint',
      'mapboxCanCreateCheckpoint',
      'payloadContainsRawGps',
      'payloadContainsPreciseLocation',
      'payloadContainsRouteGeometry',
      'payloadContainsMapboxData',
      'tokensIncluded',
    ]) {
      if (summary[key] is! bool) reasons.add('${key}_not_bool');
    }
    if (summary['localCheckpointRequiredBeforeBackup'] != true ||
        summary['syncAttemptRequiredBeforeBackup'] != true ||
        summary['reservationRequiredBeforeUpload'] != true ||
        summary['checkpointRequiresDeviceMatch'] != true ||
        summary['checkpointRequiresDayKeyMatch'] != true ||
        summary['checkpointRequiresMonotonicLocalRevision'] != true ||
        summary['authenticationAloneAuthorizesCheckpointMirror'] != false) {
      reasons.add('checkpoint_upload_boundary_missing');
    }
    if (summary['hiveRemainsOperationalSourceOfTruth'] != true ||
        summary['firestoreMirrorOnly'] != true ||
        summary['remoteBackupCanOverrideLocalDay'] != false ||
        summary['remoteBackupCanDeleteLocalData'] != false ||
        summary['backupFailureCanStopGpsTracking'] != false ||
        summary['backupFailureCanDropCurrentCheckpoint'] != false) {
      reasons.add('checkpoint_local_truth_boundary_missing');
    }
    if (summary['odometerIsGlobalTruth'] != true ||
        summary['physicalOdometerRequiredForOfficialMileage'] != true ||
        summary['confirmedOdometerOverridesExternalMileage'] != true ||
        summary['externalMileageCannotBecomeGlobalTruth'] != true ||
        summary['gpsDistanceCanOnlyAdviseMileageReview'] != true ||
        summary['mapMatchingCanOnlyAdviseMileageReview'] != true ||
        summary['optimizationCannotChangeOfficialMileage'] != true ||
        summary['mirrorCanConfirmOdometer'] != false ||
        summary['mirrorCanCreateStop'] != false ||
        summary['mirrorCanEndTripAutomatically'] != false ||
        summary['mirrorCanApplyCalibration'] != false ||
        summary['mirrorCanCreateCalibrationProof'] != false ||
        summary['mirrorCanCreateOfficialMileage'] != false ||
        summary['calibrationRequiresTrustedGpsWindow'] != true ||
        summary['poorGpsDaysExcludedFromCalibration'] != true ||
        summary['mapboxCanCreateCheckpoint'] != false) {
      reasons.add('checkpoint_claims_trip_authority');
    }
    if (summary['payloadContainsRawGps'] != false ||
        summary['payloadContainsPreciseLocation'] != false ||
        summary['payloadContainsRouteGeometry'] != false ||
        summary['payloadContainsMapboxData'] != false ||
        summary['tokensIncluded'] != false ||
        summary.values.any(_looksSensitive)) {
      reasons.add('summary_contains_sensitive_checkpoint_material');
    }

    return TripLiveCheckpointMirrorSummaryValidation._(
      isRenderable: reasons.isEmpty,
      reasons: List.unmodifiable(reasons),
    );
  }

  final bool isRenderable;
  final List<String> reasons;
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
    'deviceIdMatchesLocalRecord': true,
    'tripDayKeyValidated': true,
    'localRevisionMonotonic': true,
    'canOverrideLocalDaytimeData': false,
    'canDeleteLocalData': false,
    'odometerIsGlobalTruth': true,
    'odometerRemainsOfficialMileageTruth': true,
    'physicalOdometerRequiredForOfficialMileage': true,
    'confirmedOdometerOverridesExternalMileage': true,
    'externalMileageCannotBecomeGlobalTruth': true,
    'gpsDistanceCanOnlyAdviseMileageReview': true,
    'mapMatchingCanOnlyAdviseMileageReview': true,
    'optimizationCannotChangeOfficialMileage': true,
    'mirrorCanApplyCalibration': false,
    'mirrorCanCreateCalibrationProof': false,
    'mirrorCanCreateOfficialMileage': false,
    'calibrationRequiresTrustedGpsWindow': true,
    'poorGpsDaysExcludedFromCalibration': true,
    'poorGpsCalibrationDaysCanUploadAsCalibrationProof': false,
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
      payload['deviceIdMatchesLocalRecord'] == true &&
      payload['tripDayKeyValidated'] == true &&
      payload['localRevisionMonotonic'] == true &&
      payload['ownerValidatedBeforeMirror'] == true &&
      payload['canOverrideLocalDaytimeData'] == false &&
      payload['canDeleteLocalData'] == false &&
      payload['odometerIsGlobalTruth'] == true &&
      payload['odometerRemainsOfficialMileageTruth'] == true &&
      payload['calibrationCanUploadAsOfficialMileage'] == false &&
      payload['poorGpsCalibrationDaysCanUploadAsCalibrationProof'] == false &&
      _safeTripDayKey(payload['tripDayKey']) &&
      _safeDistance(payload['distanceMiles']);
}

TripLiveCheckpointMirrorStatus? _safeStatus(Object? value) {
  if (value is! String) return null;
  for (final status in TripLiveCheckpointMirrorStatus.values) {
    if (status.name == value) return status;
  }
  return null;
}

bool _looksSensitive(Object? value) {
  if (value is! String) return false;
  final clean = value.trim();
  return clean.startsWith('pk.') ||
      clean.startsWith('sk.') ||
      RegExp(r'-?\d{1,3}\.\d{4,}\s*,\s*-?\d{1,3}\.\d{4,}').hasMatch(clean);
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
