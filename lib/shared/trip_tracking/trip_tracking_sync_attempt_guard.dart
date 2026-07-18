import '../firebase/hosted_usage_limits.dart';
import 'trip_tracking_settings_store.dart';
import 'trip_tracking_sync_policy.dart';

enum TripTrackingSyncAccountTier { free, paid }

enum TripTrackingSyncSourceKind {
  liveTrip,
  reviewedMileage,
  stopReview,
  dashboardSummary,
}

enum TripTrackingSyncAttemptStatus {
  ready,
  blockedInvalidSource,
  blockedInvalidOwner,
  blockedNetwork,
  blockedQuota,
  blockedUnverifiedUsage,
  blockedStorage,
}

class TripTrackingSyncSourceRecord {
  const TripTrackingSyncSourceRecord({
    required this.schemaVersion,
    required this.recordId,
    required this.ownerUid,
    required this.deviceId,
    required this.kind,
    required this.updatedAtUtc,
    required this.localRevision,
    required this.localPersisted,
    this.tripDayKey,
    this.distanceMiles,
  });

  final int schemaVersion;
  final String recordId;
  final String ownerUid;
  final String deviceId;
  final TripTrackingSyncSourceKind kind;
  final DateTime updatedAtUtc;
  final int localRevision;
  final bool localPersisted;
  final String? tripDayKey;
  final double? distanceMiles;

  bool get hasValidShape => hasValidShapeAt(receivedAtUtc: null);

  bool hasValidShapeAt({DateTime? receivedAtUtc}) =>
      schemaVersion == 1 &&
      _safeIdentifier(recordId, maxLength: 96) &&
      _safeIdentifier(ownerUid, maxLength: 96) &&
      _safeIdentifier(deviceId, maxLength: 96) &&
      localRevision > 0 &&
      localPersisted &&
      !updatedAtUtc.toUtc().isBefore(_minimumAcceptedTimestampUtc) &&
      !updatedAtUtc.toUtc().isAfter(_maximumAcceptedTimestampUtc) &&
      _safeSourceFreshness(updatedAtUtc, receivedAtUtc) &&
      _safeTripDayKey(tripDayKey) &&
      _safeDistance(distanceMiles);

  bool ownedBy(String authenticatedUid) =>
      _safeIdentifier(authenticatedUid, maxLength: 96) &&
      authenticatedUid == ownerUid;

  Map<String, Object?> toSafeSyncMirrorPayload() {
    return {
      'schemaVersion': schemaVersion,
      'recordId': recordId,
      'ownerUid': ownerUid,
      'deviceId': deviceId,
      'kind': kind.name,
      'updatedAtUtc': updatedAtUtc.toUtc().toIso8601String(),
      'localRevision': localRevision,
      'tripDayKey': tripDayKey,
      'distanceMiles': distanceMiles,
      'localPersisted': localPersisted,
      'canonicalSource': 'hive',
      'firestoreRole': 'mirror',
      'canOverrideLocalDaytimeData': false,
      'canDeleteLocalData': false,
      'odometerRemainsOfficialMileageTruth': true,
    };
  }
}

class TripTrackingSyncAttemptRequest {
  const TripTrackingSyncAttemptRequest({
    required this.accountTier,
    required this.authenticatedUid,
    required this.source,
    required this.networkPolicy,
    required this.wifiAvailable,
    required this.mobileDataAvailable,
    required this.syncsUsedInWindow,
    required this.storageAvailableForSmallRecordWrite,
    this.receivedAtUtc,
  });

  final TripTrackingSyncAccountTier accountTier;
  final String authenticatedUid;
  final TripTrackingSyncSourceRecord source;
  final TripTrackingBackupNetworkPolicy networkPolicy;
  final bool? wifiAvailable;
  final bool? mobileDataAvailable;
  final int? syncsUsedInWindow;
  final bool storageAvailableForSmallRecordWrite;
  final DateTime? receivedAtUtc;
}

class TripTrackingSyncAttemptGuard {
  const TripTrackingSyncAttemptGuard._();

  static TripTrackingSyncAttemptDecision evaluate(
    TripTrackingSyncAttemptRequest request,
  ) {
    final sourceValid = request.source.hasValidShapeAt(
      receivedAtUtc: request.receivedAtUtc,
    );
    final ownerValid = request.source.ownedBy(request.authenticatedUid);
    final syncDecision = TripTrackingBackupSyncPolicy.evaluate(
      networkPolicy: request.networkPolicy,
      wifiAvailable: request.wifiAvailable,
      mobileDataAvailable: request.mobileDataAvailable,
      syncsUsedInWindow: request.accountTier == TripTrackingSyncAccountTier.free
          ? request.syncsUsedInWindow
          : 0,
    );
    final status = _statusFor(
      request: request,
      sourceValid: sourceValid,
      ownerValid: ownerValid,
      syncDecision: syncDecision,
    );

    return TripTrackingSyncAttemptDecision(
      status: status,
      accountTier: request.accountTier,
      sourceValid: sourceValid,
      ownerValid: ownerValid,
      syncDecision: syncDecision,
      freeSyncsRemainingBeforeAttempt:
          request.accountTier == TripTrackingSyncAccountTier.free
          ? syncDecision.freeSyncsRemaining
          : null,
      mirrorPayload: status == TripTrackingSyncAttemptStatus.ready
          ? request.source.toSafeSyncMirrorPayload()
          : const <String, Object?>{},
    );
  }

  static TripTrackingSyncAttemptStatus _statusFor({
    required TripTrackingSyncAttemptRequest request,
    required bool sourceValid,
    required bool ownerValid,
    required TripTrackingBackupSyncDecision syncDecision,
  }) {
    if (!sourceValid) return TripTrackingSyncAttemptStatus.blockedInvalidSource;
    if (!ownerValid) return TripTrackingSyncAttemptStatus.blockedInvalidOwner;
    if (!request.storageAvailableForSmallRecordWrite) {
      return TripTrackingSyncAttemptStatus.blockedStorage;
    }
    if (!syncDecision.networkAllowed) {
      return TripTrackingSyncAttemptStatus.blockedNetwork;
    }
    if (request.accountTier == TripTrackingSyncAccountTier.paid) {
      return TripTrackingSyncAttemptStatus.ready;
    }
    if (syncDecision.reasonCode == 'free_sync_limit_unknown' ||
        syncDecision.reasonCode == 'free_sync_limit_invalid') {
      return TripTrackingSyncAttemptStatus.blockedUnverifiedUsage;
    }
    if (!syncDecision.freeSyncAllowed ||
        syncDecision.freeSyncsRemaining == null ||
        syncDecision.freeSyncsRemaining! <= 0) {
      return TripTrackingSyncAttemptStatus.blockedQuota;
    }
    return TripTrackingSyncAttemptStatus.ready;
  }
}

class TripTrackingSyncAttemptDecision {
  const TripTrackingSyncAttemptDecision({
    required this.status,
    required this.accountTier,
    required this.sourceValid,
    required this.ownerValid,
    required this.syncDecision,
    required this.freeSyncsRemainingBeforeAttempt,
    required this.mirrorPayload,
  });

  final TripTrackingSyncAttemptStatus status;
  final TripTrackingSyncAccountTier accountTier;
  final bool sourceValid;
  final bool ownerValid;
  final TripTrackingBackupSyncDecision syncDecision;
  final int? freeSyncsRemainingBeforeAttempt;
  final Map<String, Object?> mirrorPayload;

  bool get mayUploadMirror => status == TripTrackingSyncAttemptStatus.ready;

  bool get mustReserveFreeAttemptBeforeUpload =>
      mayUploadMirror && accountTier == TripTrackingSyncAccountTier.free;

  bool get consumesFreeAttempt =>
      mustReserveFreeAttemptBeforeUpload &&
      (freeSyncsRemainingBeforeAttempt ?? 0) > 0;

  String get userFacingReason {
    return switch (status) {
      TripTrackingSyncAttemptStatus.ready => 'Trip backup is ready.',
      TripTrackingSyncAttemptStatus.blockedInvalidSource =>
        'Trip backup is waiting for a valid local trip record.',
      TripTrackingSyncAttemptStatus.blockedInvalidOwner =>
        'Trip backup is waiting for account ownership verification.',
      TripTrackingSyncAttemptStatus.blockedNetwork =>
        syncDecision.userFacingReason,
      TripTrackingSyncAttemptStatus.blockedQuota =>
        'Free backup sync limit reached for this 24-hour window.',
      TripTrackingSyncAttemptStatus.blockedUnverifiedUsage =>
        'Free backup sync usage could not be verified.',
      TripTrackingSyncAttemptStatus.blockedStorage =>
        'Trip backup is waiting for safe local storage.',
    };
  }

  Map<String, Object?> toSafeSummary() {
    return {
      'schemaVersion': 1,
      'status': status.name,
      'accountTier': accountTier.name,
      'sourceValid': sourceValid,
      'ownerValid': ownerValid,
      'mayUploadMirror': mayUploadMirror,
      'mustReserveFreeAttemptBeforeUpload': mustReserveFreeAttemptBeforeUpload,
      'consumesFreeAttempt': consumesFreeAttempt,
      'freePlanSyncLimit': HostedUsageLimits.freeUserSyncsPer24HourWindow,
      'freeSyncsRemainingBeforeAttempt': freeSyncsRemainingBeforeAttempt,
      'networkDecision': syncDecision.toSafeSummary(),
      'hiveRemainsOperationalSourceOfTruth': true,
      'firestoreMirrorOnly': true,
      'remoteBackupCanOverrideLocalDay': false,
      'remoteBackupCanPurgeLocalRecordsSilently': false,
      'syncAttemptCanDeleteLocalData': false,
      'odometerRemainsOfficialMileageTruth': true,
      'mapboxCanReplaceOdometer': false,
      'validatedBeforeUpload': true,
      'authorizationCheckedAfterAuthentication': true,
      'tokensIncluded': false,
      'preciseLocationIncluded': false,
      'rawTripRecordsIncluded': false,
    };
  }
}

final DateTime _minimumAcceptedTimestampUtc = DateTime.utc(2020);
final DateTime _maximumAcceptedTimestampUtc = DateTime.utc(2100);
final RegExp _safeIdPattern = RegExp(r'^[A-Za-z0-9_.-]+$');
final RegExp _dayKeyPattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

bool _safeIdentifier(String value, {required int maxLength}) {
  final clean = value.trim();
  if (clean.isEmpty ||
      clean != value ||
      clean.length > maxLength ||
      clean.contains(':') ||
      !_safeIdPattern.hasMatch(clean)) {
    return false;
  }
  final lower = clean.toLowerCase();
  return !lower.contains('token') &&
      !lower.contains('secret') &&
      !lower.startsWith('pk.') &&
      !lower.startsWith('sk.');
}

bool _safeTripDayKey(String? value) {
  if (value == null) return true;
  if (!_dayKeyPattern.hasMatch(value)) return false;
  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(5, 7));
  final day = int.parse(value.substring(8, 10));
  final parsed = DateTime.utc(year, month, day);
  return parsed.year == year && parsed.month == month && parsed.day == day;
}

bool _safeDistance(double? value) {
  if (value == null) return true;
  return value.isFinite && value >= 0 && value <= 2500;
}

bool _safeSourceFreshness(DateTime updatedAtUtc, DateTime? receivedAtUtc) {
  final received = receivedAtUtc?.toUtc();
  if (received == null) return true;
  final updated = updatedAtUtc.toUtc();
  if (updated.isAfter(received.add(const Duration(minutes: 2)))) return false;
  if (updated.isBefore(received.subtract(const Duration(days: 31)))) {
    return false;
  }
  return true;
}
