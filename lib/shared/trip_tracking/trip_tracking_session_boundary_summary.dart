import 'trip_tracking_session_store.dart';

extension TripTrackingSessionBoundarySummary on TripTrackingSessionRecord {
  Map<String, Object?> toBoundarySummary() => {
    'schemaVersion': _supportedBoundarySchemaVersion(schemaVersion),
    'recordType': 'activeSession',
    'hasSafeTripId': _isSafeStoreIdentifier(id),
    'hasSafeVehicleId': _isSafeStoreIdentifier(vehicleId),
    'profile': profile.name,
    'lifecycleState': lifecycleState.name,
    'healthState': healthState.name,
    'hasValidTimeline': hasValidTimeline && !updatedAt.isBefore(startedAt),
    'odometerBucket': _odometerBucket(startingOdometer),
    'engineSnapshotSchemaVersion': engineSnapshot.schemaVersion,
    'walkingReviewSuggested': engineSnapshot.walkingReviewSuggested,
    'advisoryCount': advisories.length > 24 ? 24 : advisories.length,
    'storedAsDurableCheckpoint': true,
    'hiveRemainsSourceOfTruth': true,
    'remoteDataCanOverrideLocalTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'mapsRequiredForTracking': false,
    'mapboxCanOverrideOdometer': false,
    'odometerRemainsCanonical': true,
    'preciseLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'rawEngineSnapshotIncluded': false,
    'rawAdvisoriesIncluded': false,
    'tokensIncluded': false,
    'canCreateOfficialMileage': false,
  };
}

extension TripTrackingReviewBoundarySummary on TripTrackingReviewRecord {
  Map<String, Object?> toBoundarySummary() => {
    'schemaVersion': _supportedBoundarySchemaVersion(schemaVersion),
    'recordType': 'review',
    'hasSafeTripId': _isSafeStoreIdentifier(id),
    'hasSafeVehicleId': _isSafeStoreIdentifier(vehicleId),
    'profile': profile.name,
    'hasValidTimeline':
        hasValidTimeline &&
        !finishedAt.isBefore(startedAt) &&
        estimatedEndingOdometer >= startingOdometer,
    'startingOdometerBucket': _odometerBucket(startingOdometer),
    'estimatedEndingOdometerBucket': _odometerBucket(estimatedEndingOdometer),
    'confirmedEndingOdometerBucket': _odometerBucket(confirmedEndingOdometer),
    'isOdometerConfirmed': isOdometerConfirmed,
    'needsWalkingReview': needsWalkingReview,
    'cloudSyncState': cloudSyncState.name,
    'cloudBackupScope': cloudBackupScope?.name ?? 'unbound',
    'hasCloudAccountBinding': _isSafeCloudToken(cloudAccountUid),
    'hasOrganizationBinding':
        cloudBackupScope == TripTrackingCloudBackupScope.organization &&
        _isSafeCloudToken(cloudOrganizationId),
    'hasCloudSyncError': _safeCloudSyncErrorPresent(cloudSyncError),
    'cloudSyncTimestampPresent': cloudSyncedAt != null,
    'hiveRemainsSourceOfTruth': true,
    'firestoreMirrorOnly': true,
    'remoteDataCanOverrideLocalTripLog': false,
    'remoteTotalsCanBecomeCanonical': false,
    'cloudMirrorCanDeleteLocalTripLog': false,
    'mapsRequiredForReview': false,
    'mapboxCanOverrideOdometer': false,
    'odometerRemainsCanonical': true,
    'authorizationRequiredBeforeCloudWrite': true,
    'authenticationImpliesAuthorization': false,
    'preciseLocationIncluded': false,
    'preciseTimestampIncluded': false,
    'accountIdIncluded': false,
    'organizationIdIncluded': false,
    'rawReviewIncluded': false,
    'tokensIncluded': false,
    'canOverrideOdometer': false,
  };
}

int _supportedBoundarySchemaVersion(int value) {
  return value >= 1 && value <= 1 ? value : 1;
}

String _odometerBucket(int? value) {
  if (value == null) return 'missing';
  if (value < 0) return 'invalid';
  if (value == 0) return 'zero';
  if (value < 1000) return 'under_1k';
  if (value < 10000) return '1k_10k';
  if (value < 100000) return '10k_100k';
  if (value < 1000000) return '100k_1m';
  return '1m_plus';
}

bool _isSafeStoreIdentifier(Object? value) {
  final clean = '${value ?? ''}'
      .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
      .trim();
  return clean.isNotEmpty && clean.length <= 160;
}

bool _isSafeCloudToken(Object? value) {
  final clean = _safeText(value, maxLength: 160);
  return clean != null && RegExp(r'^[A-Za-z0-9_.:-]+$').hasMatch(clean);
}

bool _safeCloudSyncErrorPresent(Object? value) {
  return _safeText(value, maxLength: 240) != null;
}

String? _safeText(Object? value, {required int maxLength}) {
  if (value == null) return null;
  final clean = '$value'.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ').trim();
  if (clean.isEmpty) return null;
  return clean.length > maxLength ? clean.substring(0, maxLength) : clean;
}
